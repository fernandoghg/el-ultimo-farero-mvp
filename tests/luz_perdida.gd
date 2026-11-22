extends "res://tests/fractal_un_rotor.gd"

var completions: int = 0


func fixture() -> Node3D:
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.get_node("Player").set_physics_process(false)
	scene.get_node("Player").position = Vector3(4.8, 0.01, 3.5)
	completions = 0
	scene.get_node("LostLight").resolved.connect(func(): completions += 1)
	return scene


func blocker(scene: Node3D, location: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, 1.8, 0.4)
	collision.shape = box
	body.add_child(collision)
	scene.add_child(body)
	body.position = location
	return body


func discard(scene: Node3D) -> void:
	action("interact", false)
	scene.queue_free()
	await frames(3)


func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://build/lost-light-%s-%s.png" % [name, TranslationServer.get_locale()]) == OK, "Capture failed")


func run() -> void:
	root.size = Vector2i(1280, 720)
	var valid := 0
	for state in range(2):
		var scene := fixture()
		var puzzle: Node3D = scene.get_node("LostLight")
		await frames(4)
		check(not puzzle.solved and completions == 0, "Proximity resolved puzzle")
		if state == 1:
			puzzle.rotate_once()
		await frames(4)
		check(puzzle.orientation == state and puzzle.path.reflected, "Wrong orientation/reflection")
		check(puzzle.path.incoming_start.is_equal_approx(Vector3(1.8, 1.2, 3)), "Wrong source")
		check(puzzle.path.incoming_end.is_equal_approx(Vector3(3.8, 1.2, 3)), "Wrong mirror contact")
		var expected_z := 4.575 if state == 1 else 1.29
		check(absf(puzzle.path.outgoing_end.z - expected_z) < 0.002, "Ray missed receiver or inert wall")
		check(puzzle.solved == (state == 1) and completions == state, "Wrong validity")
		if puzzle.solved:
			valid += 1
		check(scene.get_node("Lighthouse").state == 0, "Puzzle activated lighthouse")
		check(not scene.get_node("FractalRotor").solved, "Puzzle solved fractal")
		await discard(scene)
	check(valid == 1, "Expected exactly one valid orientation among two")

	var scene := fixture()
	var puzzle: Node3D = scene.get_node("LostLight")
	var player: CharacterBody3D = scene.get_node("Player")
	var obstacle := blocker(scene, Vector3(3.8, 1.2, 3.9))
	await frames(4)
	var initial: Transform3D = puzzle.get_node("Reflector/Pivot").transform
	player.position = Vector3(-4, 0.01, 2)
	action("interact", true)
	await frames(3)
	player.position = Vector3(4.8, 0.01, 3.5)
	await frames(3)
	action("interact", true)
	await frames(3)
	check(puzzle.orientation == 0 and not puzzle.solved, "Inherited/out-of-range press turned reflector")
	action("interact", false)
	await tap("interact")
	check(puzzle.orientation == 1 and not puzzle.solved, "Obstacle did not block correct orientation")
	check(absf(puzzle.path.outgoing_end.z - 3.7) < 0.002, "Beam did not end at obstacle")
	action("interact", true)
	await frames(3)
	for repeat in range(5):
		action("interact", true)
		await frames(2)
	var echo := InputEventKey.new()
	echo.physical_keycode = KEY_I
	echo.pressed = true
	echo.echo = true
	Input.parse_input_event(echo)
	await frames(3)
	check(puzzle.orientation == 0 and puzzle.get_node("Reflector/Pivot").transform.is_equal_approx(initial), "Hold/echo repeated a turn or two-turn cycle failed")
	echo.pressed = false
	echo.echo = false
	Input.parse_input_event(echo)
	action("interact", false)
	await frames(2)
	player.controls_suspended = true
	await tap("interact")
	check(puzzle.orientation == 0, "Interaction escaped inspection suspension")
	player.controls_suspended = false
	player.blocked_actions.append(&"interact")
	await tap("interact")
	check(puzzle.orientation == 0, "Inherited context action escaped release protection")
	player.blocked_actions.clear()
	await tap("interact")
	player.position = Vector3(-4, 0.01, 2)
	await frames(4)
	player.position = Vector3(4.8, 0.01, 3.5)
	await frames(4)
	check(puzzle.orientation == 1 and not puzzle.solved, "State lost on leaving/returning")
	obstacle.queue_free()
	await frames(4)
	check(puzzle.solved and completions == 1, "Removing obstacle did not allow real reception")
	check(puzzle.get_node("Receiver/Pulse").visible, "Missing confirmation pulse")
	var accepted: Dictionary = puzzle.path.duplicate()
	blocker(scene, Vector3(3.8, 1.2, 3.9))
	for attempt in range(3):
		await tap("interact")
		puzzle.rotate_once()
	await frames(60)
	check(puzzle.orientation == 1 and puzzle.solved and completions == 1 and puzzle.path == accepted, "Solved assembly not latched or signal repeated")
	check(not puzzle.get_node("Receiver/Pulse").visible, "Confirmation did not finish")
	await discard(scene)

	# Both legs are physically queried; orientation and brightness alone cannot solve.
	scene = fixture()
	puzzle = scene.get_node("LostLight")
	obstacle = blocker(scene, Vector3(2.8, 1.2, 3))
	puzzle.rotate_once()
	await frames(4)
	check(not puzzle.solved and not puzzle.path.reflected and not puzzle.get_node("Beam/Outgoing").visible, "Incoming obstacle ignored")
	obstacle.queue_free()
	puzzle.get_node("Receiver").position.x += 1.0
	await frames(4)
	check(not puzzle.solved, "Correct state solved without receiver on route")
	puzzle.get_node("Receiver").position.x -= 1.0
	puzzle.get_node("Receiver").rotation.y = PI
	await frames(4)
	check(not puzzle.solved, "Receiver accepted its insensitive back face")
	puzzle.get_node("Receiver").rotation.y = 0
	puzzle.get_node("Receiver/Crystal").visible = false
	puzzle.get_node("Source/Crystal").visible = false
	await frames(4)
	check(puzzle.solved and completions == 1, "Logical reception depends on visible materials")
	await discard(scene)

	scene = fixture()
	puzzle = scene.get_node("LostLight")
	await frames(50)
	check(puzzle.orientation == 0 and not puzzle.solved, "New scene did not reset session")
	var english := TranslationServer.get_locale().begins_with("en")
	check(puzzle.clue.text == ("The Lost Light · Guide the light to the marked crystal" if english else "La luz perdida · Conduce la luz hasta el cristal marcado"), "Wrong localized clue")
	check(puzzle.prompt.text == ("Press I to orient the reflector" if english else "Pulsa I para orientar el reflector"), "Wrong localized interaction")
	check(puzzle.clue.get_minimum_size().x < 1280 and puzzle.prompt.get_minimum_size().x < 1280, "Localized prompt too wide")
	var camera: Camera3D = scene.get_node("Camera")
	for piece: String in ["Source/Crystal", "Reflector/Pivot/Plate", "Receiver/Crystal", "Inert"]:
		var mesh: MeshInstance3D = puzzle.get_node(piece)
		for corner in range(8):
			var world := mesh.to_global(mesh.get_aabb().get_endpoint(corner))
			check(not camera.is_position_behind(world) and Rect2(0, 0, 1280, 580).has_point(camera.unproject_position(world)), "Puzzle outside normal-camera view")
	await capture("initial")
	await tap("interact")
	await capture("solved")
	check(puzzle.solved and completions == 1, "Normal interaction failed")
	await discard(scene)
	print("Lost light: 2 orientations, 1 solution, collision paths, input, latch and localization; failures: %d" % failures)
	quit(1 if failures else 0)
