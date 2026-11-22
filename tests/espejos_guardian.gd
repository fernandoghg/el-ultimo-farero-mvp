extends "res://tests/fractal_un_rotor.gd"

const Geometry = preload("res://scripts/light_geometry.gd")
var completions: int = 0


func fixture() -> Node3D:
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.get_node("Player").set_physics_process(false)
	scene.get_node("Player").position = Vector3(-5.1, 0.01, 0.3)
	completions = 0
	scene.get_node("GuardianMirrors").resolved.connect(func(): completions += 1)
	return scene


func discard(scene: Node3D) -> void:
	action("interact", false)
	scene.queue_free()
	await frames(3)


func blocker(scene: Node3D, location: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.12, 1, 0.12)
	collision.shape = box
	body.add_child(collision)
	scene.add_child(body)
	body.position = location
	return body


func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://build")
	check(root.get_texture().get_image().save_png("res://build/guardian-%s-%s.png" % [name, TranslationServer.get_locale()]) == OK, "Capture failed")


func walk(player: CharacterBody3D, target: Vector3) -> void:
	for step in range(180):
		var difference := target - player.position
		difference.y = 0
		if difference.length() < 0.07:
			break
		var direction := difference.normalized()
		Input.action_press("move_right", maxf(0, direction.x))
		Input.action_press("move_left", maxf(0, -direction.x))
		Input.action_press("move_back", maxf(0, direction.z))
		Input.action_press("move_forward", maxf(0, -direction.z))
		await frames(1)
	for key in ["move_right", "move_left", "move_back", "move_forward"]:
		Input.action_release(key)
	check(Vector2(player.position.x - target.x, player.position.z - target.z).length() < 0.12, "Walking route blocked")
	check(player.is_on_floor(), "Walking route lost floor")


func run() -> void:
	root.size = Vector2i(1280, 720)
	var valid := 0
	for first in range(2):
		for second in range(2):
			var scene := fixture()
			var puzzle: Node3D = scene.get_node("GuardianMirrors")
			await frames(3)
			check(not puzzle.solved and completions == 0, "Proximity resolved puzzle")
			if first:
				puzzle.rotate_once(0)
			if second:
				puzzle.rotate_once(1)
			await frames(4)
			check(puzzle.states == [first, second], "Wrong independent state pair")
			var expected: bool = first == 1 and second == 1
			check(puzzle.solved == expected and completions == (1 if expected else 0), "Wrong validity for pair %s" % [[first, second]])
			check(puzzle.path.reflections == (2 if first else 1), "Wrong mirror chain length")
			check(puzzle.get_node("Reflector2/Inlet").visible == bool(first), "Second mirror inlet does not follow reception")
			if first == 0:
				check(absf(puzzle.path.segments.back().end.z + 0.79) < 0.002, "Initial beam does not stop at inert wall cap")
			for index in range(puzzle.path.segments.size() - 1):
				check(puzzle.path.segments[index].end.is_equal_approx(puzzle.path.segments[index + 1].start), "Visible route is discontinuous")
			if expected:
				valid += 1
				check(puzzle.path.segments[0].end.is_equal_approx(Vector3(-4.5, 1.2, -0.3)), "Wrong first contact")
				check(puzzle.path.segments[1].end.is_equal_approx(Vector3(-4.5, 1.2, 1.2)), "Wrong second contact")
				check(absf(puzzle.path.segments[2].end.x - 0.375) < 0.002, "Wrong receiver face")
			check(scene.get_node("Lighthouse").state == 0 and not scene.get_node("LostLight").solved and not scene.get_node("FractalRotor").solved, "P2 changed other puzzles or lighthouse")
			await discard(scene)
	check(valid == 1, "Expected one solution among four pairs")
	# Neither mirror can be replaced by a missing collider or a graphic-only glow.
	for missing in range(2):
		var scene := fixture()
		var puzzle: Node3D = scene.get_node("GuardianMirrors")
		puzzle.mirrors[missing].get_node("Body/Shape").disabled = true
		puzzle.get_node("Receiver/Crystal").material_override = puzzle.get_node("Source/Crystal").mesh.material
		puzzle.rotate_once(0)
		puzzle.rotate_once(1)
		await frames(4)
		check(not puzzle.solved and completions == 0, "Missing mirror replaced by target brightness or correct tuple")
		puzzle.mirrors[missing].get_node("Body/Shape").disabled = false
		puzzle.get_node("Receiver/Crystal").visible = false
		puzzle.get_node("Source/Crystal").visible = false
		await frames(4)
		check(puzzle.solved and completions == 1, "Physical receipt depends on crystal visibility")
		await discard(scene)

	for location: Vector3 in [Vector3(-5.1, 1.2, -0.3), Vector3(-4.5, 1.2, 0.75), Vector3(-2.7, 1.2, 1.2)]:
		var scene := fixture()
		var puzzle: Node3D = scene.get_node("GuardianMirrors")
		var obstacle := blocker(scene, location)
		puzzle.rotate_once(0)
		puzzle.rotate_once(1)
		await frames(4)
		check(not puzzle.solved and completions == 0, "Obstacle ignored in beam leg")
		check(puzzle.path.segments.back().end.distance_to(location) < 0.1, "Beam not truncated at obstacle")
		obstacle.queue_free()
		await frames(4)
		check(puzzle.solved and completions == 1, "Removing blocker did not allow real receipt")
		await discard(scene)

	var scene := fixture()
	var puzzle: Node3D = scene.get_node("GuardianMirrors")
	var player: CharacterBody3D = scene.get_node("Player")
	await frames(4)
	var source: Vector3 = puzzle.get_node("Source/Crystal").global_position
	var target: Vector3 = puzzle.get_node("Receiver/Crystal").global_position
	var excluded: Array[RID] = [player.get_rid(), puzzle.get_node("Source/Body").get_rid()]
	for mirror in puzzle.mirrors:
		excluded.append(mirror.get_node("Body").get_rid())
	var direct := Geometry.ray(puzzle, source, target, excluded)
	check(not direct.is_empty() and direct.collider == puzzle.get_node("Wall/Body"), "Wall does not block direct source-receiver shortcut")
	var wall: MeshInstance3D = puzzle.get_node("Wall")
	check(wall.mesh.size.is_equal_approx(wall.get_node("Body/Shape").shape.size), "Wall mesh/collider mismatch")
	# Even an unobstructed shortcut must fail without the ordered pair of mirrors.
	puzzle.get_node("Wall/Body/Shape").disabled = true
	puzzle.beam_length = 8.0
	for mirror in puzzle.mirrors:
		mirror.get_node("Body/Shape").disabled = true
	var direction := (target - source).normalized()
	puzzle.get_node("Source").rotation.y = -atan2(direction.z, direction.x)
	await frames(4)
	check(not puzzle.solved and puzzle.path.reflections == 0, "Direct hit bypassed both mirrors")
	check(puzzle.path.segments.back().end.distance_to(target) < 0.3, "Shortcut fixture did not actually reach receiver")
	await discard(scene)

	# B is independently usable before it receives any light; holding I cannot turn A.
	scene = fixture()
	puzzle = scene.get_node("GuardianMirrors")
	player = scene.get_node("Player")
	player.position = Vector3(-5.25, 0.01, 1.2)
	await frames(4)
	check(puzzle.prompt.text == ("Press I to orient the mirror with two marks" if TranslationServer.get_locale().begins_with("en") else "Pulsa I para orientar el espejo de dos marcas"), "Second interaction not localized")
	var initial: Transform3D = puzzle.mirrors[1].get_node("Pivot").transform
	action("interact", true)
	await frames(3)
	check(puzzle.states == [0, 1] and not puzzle.solved, "B interaction changed A or solved without light")
	for repeat in range(4):
		action("interact", true)
		await frames(3)
	var echo := InputEventKey.new()
	echo.physical_keycode = KEY_I
	echo.pressed = true
	echo.echo = true
	Input.parse_input_event(echo)
	await frames(2)
	check(puzzle.states == [0, 1], "Physical keyboard echo repeated B")
	echo.pressed = false
	echo.echo = false
	Input.parse_input_event(echo)
	# Restore the held action after releasing the separate physical-key fixture.
	action("interact", false)
	await frames(2)
	action("interact", true)
	await frames(2)
	check(puzzle.states == [0, 0], "Fresh B press failed")
	player.position = Vector3(-5.1, 0.01, 0.3)
	action("interact", true)
	await frames(3)
	check(puzzle.states == [0, 0], "Held I repeated or crossed between mirrors")
	action("interact", false)
	await frames(2)
	player.position = Vector3(-5.25, 0.01, 1.2)
	await tap("interact")
	await tap("interact")
	check(puzzle.states == [0, 0] and puzzle.mirrors[1].get_node("Pivot").transform.is_equal_approx(initial), "B cannot reverse exactly")
	player.controls_suspended = true
	await tap("interact")
	check(puzzle.states == [0, 0], "Interaction escaped fractal inspection suspension")
	player.controls_suspended = false
	player.blocked_actions.append(&"interact")
	await tap("interact")
	check(puzzle.states == [0, 0], "Interaction escaped inherited context block")
	player.blocked_actions.clear()
	player.position = Vector3(2, 0.01, 2)
	action("interact", true)
	await frames(2)
	player.position = Vector3(-5.25, 0.01, 1.2)
	action("interact", true)
	await frames(2)
	check(puzzle.states == [0, 0], "Inherited press on entering range turned mirror")
	action("interact", false)
	await frames(2)
	await tap("interact")
	player.position = Vector3(-5.1, 0.01, 0.3)
	await frames(3)
	check(puzzle.states == [0, 1], "State lost on leaving and returning")
	await tap("interact")
	check(puzzle.solved and completions == 1 and puzzle.get_node("Receiver/Pulse").visible, "Normal solution/confirmation failed")
	var accepted: Dictionary = puzzle.path.duplicate(true)
	for index in range(2):
		player.position = puzzle.mirrors[index].position + Vector3(-0.8, 0.01, 0)
		await tap("interact")
		puzzle.rotate_once(index)
	await frames(60)
	check(puzzle.states == [1, 1] and puzzle.solved and completions == 1 and puzzle.path == accepted, "Resolution did not latch or signal repeated")
	check(not puzzle.get_node("Receiver/Pulse").visible, "Confirmation not brief")
	await discard(scene)

	# Reach both mirrors with real movement/collisions from the ordinary spawn.
	scene = fixture()
	puzzle = scene.get_node("GuardianMirrors")
	player = scene.get_node("Player")
	player.position = Vector3(-2, 0.01, 2)
	player.set_physics_process(true)
	var camera: Camera3D = scene.get_node("Camera")
	camera.yaw = 0
	await frames(4)
	for waypoint: Vector3 in [Vector3(-2, 0, 2.8), Vector3(-5.25, 0, 2.8), Vector3(-5.25, 0, 1.2)]:
		await walk(player, waypoint)
	check(puzzle.nearby_mirror() == 1, "B not reachable")
	await tap("interact")
	await walk(player, Vector3(-5.1, 0, 0.3))
	check(puzzle.nearby_mirror() == 0, "A not reachable")
	camera.yaw = PI / 4.0
	await frames(50)
	var english := TranslationServer.get_locale().begins_with("en")
	check(puzzle.prompt.text == ("Press I to orient the mirror with one mark" if english else "Pulsa I para orientar el espejo de una marca"), "Interaction not localized")
	check(puzzle.clue.text == ("The Guardian's Mirrors · Guide the light through both mirrors to the crystal" if english else "Los espejos del guardián · Guía la luz por ambos espejos hasta el cristal"), "Clue not localized")
	check(puzzle.clue.get_minimum_size().x < 1280, "Clue exceeds viewport")
	for piece: String in ["Source/Crystal", "Reflector/Pivot/Plate", "Reflector2/Pivot/Plate", "Receiver/Crystal", "Wall", "Wall/Cap"]:
		var mesh: MeshInstance3D = puzzle.get_node(piece)
		for corner in range(8):
			var world := mesh.to_global(mesh.get_aabb().get_endpoint(corner))
			check(not camera.is_position_behind(world) and Rect2(0, 0, 1280, 580).has_point(camera.unproject_position(world)), "P2 component outside 1280x720 view")
	await capture("before")
	await tap("interact")
	await capture("solved")
	check(puzzle.solved and completions == 1, "Walking interaction failed")
	check(puzzle.prompt.text == ("The Guardian's Mirrors · Receiver illuminated" if english else "Los espejos del guardián · Receptor iluminado"), "Confirmation not localized")
	camera.yaw = 0
	await frames(2)
	await walk(player, Vector3(-5.25, 0, 1.2))
	await walk(player, Vector3(-5.25, 0, 2.8))
	await walk(player, Vector3(-2, 0, 2.8))
	await discard(scene)
	print("Guardian mirrors: 4 configurations, 1 valid; ordered route, 3 blocked legs, input, walkability, latch, locale; failures: %d" % failures)
	quit(1 if failures else 0)
