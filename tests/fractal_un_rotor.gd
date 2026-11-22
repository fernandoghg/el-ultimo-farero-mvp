extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func action(name: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	Input.parse_input_event(event)


func tap(name: StringName) -> void:
	action(name, true)
	await frames(2)
	action(name, false)
	await frames(2)


func bounds(camera: Camera3D, rotor: Node3D) -> Rect2:
	var rect := Rect2(camera.unproject_position(rotor.global_position), Vector2.ZERO)
	var meshes := rotor.get_children()
	meshes.append(rotor.get_parent().get_node("Notch"))
	for mesh: MeshInstance3D in meshes:
		var box := mesh.get_aabb()
		for i in range(8):
			var point := mesh.to_global(box.get_endpoint(i))
			check(not camera.is_position_behind(point), "Geometry behind inspection camera")
			rect = rect.expand(camera.unproject_position(point))
	return rect


func correspondence(small: Node3D, large: Node3D) -> void:
	var expected := Basis(Vector3(0, 0, 1), TAU / 3.0) * large.global_basis.orthonormalized()
	check(small.global_basis.orthonormalized().is_equal_approx(expected), "120-degree physical correspondence lost")


func run() -> void:
	root.size = Vector2i(1280, 720)
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	var prototype: Node3D = scene.get_node("FractalRotor")
	var player: CharacterBody3D = scene.get_node("Player")
	var camera: Camera3D = scene.get_node("Camera")
	var small: Node3D = prototype.get_node("SmallSupport/Ring/Rotor")
	var large: Node3D = prototype.get_node("LargeSupport/Ring/Rotor")
	var lighthouse: Node3D = scene.get_node("Lighthouse")
	player.position = Vector3(-3, 0.01, 3)
	await frames(4)
	var initial_small := small.transform
	var initial_large := large.transform
	correspondence(small, large)
	var locale := "en" if OS.get_cmdline_user_args().has("--game-language") else "es"
	check(prototype.prompt.text == ("Press I to examine the model" if locale == "en" else "Pulsa I para examinar el modelo"), "Entry prompt not localized")
	# A movement key held while opening must not move during or after inspection.
	action(&"move_left", true)
	action(&"interact", true)
	await frames(3)
	check(prototype.mode == prototype.Mode.INSPECTING and prototype.inspection_camera.current, "Inspection did not open")
	check(prototype.prompt.text == ("A/D: select \u00b7 I: rotate \u00b7 Esc: return to the game" if locale == "en" else "A/D: seleccionar \u00b7 I: girar \u00b7 Esc: volver al juego"), "Inspection instructions not localized")
	var fixed_position := player.position
	var saved_yaw: float = camera.yaw
	check(prototype.pairs[0].state == 0, "Opening press rotated the model")
	action(&"interact", true)
	await frames(15)
	check(prototype.pairs[0].state == 0, "Held/repeated opening press rotated model")
	check(player.position.distance_to(fixed_position) < 0.01, "Player moved while inspecting")
	action(&"interact", false)
	var echo := InputEventKey.new()
	echo.physical_keycode = KEY_I
	echo.pressed = true
	echo.echo = true
	Input.parse_input_event(echo)
	await frames(2)
	check(prototype.pairs[0].state == 0, "Keyboard autorepeat rotated rotor")
	var key_release := InputEventKey.new()
	key_release.physical_keycode = KEY_I
	key_release.pressed = false
	Input.parse_input_event(key_release)
	action(&"interact", false)
	await tap(&"camera_left")
	check(is_equal_approx(camera.yaw, saved_yaw), "Q rotated normal camera during inspection")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://build")
		var picture := root.get_texture().get_image()
		check(picture.save_png("res://build/rotor-inspection.png") == OK, "Inspection capture could not be saved")
	var sizes: Array[Rect2] = []
	for index in range(3):
		action(&"interact", true)
		await frames(3)
		check(prototype.pairs[0].state == (index + 1) % 3, "Wrong discrete state")
		check(absf(large.rotation.z - initial_large.basis.get_euler().z) > 0.01 or index > 0, "Large module did not react immediately")
		correspondence(small, large)
		action(&"interact", true)
		for frame in range(15):
			await frames(1)
			correspondence(small, large)
			var area := Rect2(20, 20, 1240, 580)
			check(area.encloses(bounds(prototype.inspection_camera, small)) and area.encloses(bounds(prototype.inspection_camera, large)), "Model/notch cropped during animation")
		check(prototype.pairs[0].state == (index + 1) % 3, "Held I repeated a turn")
		var small_rect := bounds(prototype.inspection_camera, small)
		var large_rect := bounds(prototype.inspection_camera, large)
		var usable := Rect2(20, 20, 1240, 580)
		check(usable.encloses(small_rect) and usable.encloses(large_rect), "Geometry cropped or under UI at 1280x720")
		check(not small_rect.intersects(large_rect), "The two scales overlap in inspection")
		check(small_rect.size.x > 55 and large_rect.size.x > 100, "Projected model too small")
		sizes.append(small_rect)
		action(&"interact", false)
		await frames(2)
	check(small.transform.is_equal_approx(initial_small) and large.transform.is_equal_approx(initial_large), "Three presses did not restore initial transforms")
	check(lighthouse.state == lighthouse.State.OFF, "Rotor input activated lighthouse")
	await tap(&"pause")
	check(prototype.mode == prototype.Mode.EXPLORING and camera.current, "Esc did not restore normal camera")
	await frames(12)
	check(player.position.distance_to(fixed_position) < 0.01, "Held movement inherited after exit")
	check(is_equal_approx(camera.yaw, saved_yaw), "Normal camera orientation changed")
	action(&"move_left", false)
	await frames(2)
	action(&"move_left", true)
	await frames(6)
	action(&"move_left", false)
	check(player.position.distance_to(fixed_position) > 0.15, "Movement did not resume after a new press")
	# Leave during a turn; it must complete, not duplicate or reset on reentry.
	await tap(&"interact")
	action(&"interact", true)
	await frames(2)
	await tap(&"pause")
	await frames(15)
	check(prototype.mode == prototype.Mode.EXPLORING and prototype.pairs[0].state == 1 and not prototype.turning, "Exit during turn cancelled/duplicated operation")
	action(&"interact", false)
	await tap(&"interact")
	check(prototype.pairs[0].state == 1 and prototype.mode == prototype.Mode.INSPECTING, "Reentry reset or rotated model")
	# Esc wins over I even when I was delivered first in the same update.
	action(&"interact", true)
	action(&"pause", true)
	await frames(2)
	check(prototype.mode == prototype.Mode.EXPLORING and prototype.pairs[0].state == 1, "Esc/I priority failed")
	action(&"interact", false)
	action(&"pause", false)
	await frames(2)
	# Wait for an already accepted camera turn before entering; Esc cancels wait.
	camera.request_turn(1.0)
	await tap(&"interact")
	check(prototype.mode == prototype.Mode.ENTERING, "Inspection did not wait for active normal-camera turn")
	await tap(&"pause")
	await frames(35)
	check(camera.current and prototype.mode == prototype.Mode.EXPLORING, "Cancelled entry opened inspection later")
	# Pedestal is a real solid, without changing bridge/faro collision geometry.
	camera.yaw = 0.0
	player.position = Vector3(-4.4, 0.01, 4.3)
	player.velocity = Vector3.ZERO
	await frames(3)
	action(&"move_right", true)
	await frames(30)
	action(&"move_right", false)
	check(player.is_on_wall() and player.is_on_floor() and player.position.x < -3.8, "Pedestal did not block grounded player")
	print("inspection small-model rectangles: ", sizes)
	print("fractal_un_rotor: %d failures" % failures)
	quit(0 if failures == 0 else 1)
