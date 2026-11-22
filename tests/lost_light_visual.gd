extends "res://tests/luz_perdida.gd"


func synchronized(puzzle: Node3D) -> void:
	var visual: Node3D = puzzle.get_node("Reflector/Visual")
	check(absf(visual.assembly.rotation.y - puzzle.get_node("Reflector/Pivot").rotation.y) < 0.0001, "Visual differs from optical pivot")
	check(visual.assembly.position.is_equal_approx(Vector3(0, 1.2, 0)), "Visual pivot height changed")


func run() -> void:
	root.size = Vector2i(1280, 720)
	var scene := fixture()
	var puzzle: Node3D = scene.get_node("LostLight")
	var visual: Node3D = puzzle.get_node("Reflector/Visual")
	var pedestal: Node3D = visual.find_child("Pedestal", true, false)
	var fixed: Transform3D = pedestal.global_transform
	var obstacle := blocker(scene, Vector3(3.8, 1.2, 3.9))
	await frames(5)
	synchronized(puzzle)
	check(puzzle.orientation == 0 and not puzzle.solved, "Wrong initial gameplay state")
	check(not puzzle.get_node("Reflector/Pivot/Plate").visible, "Duplicate plate visible")
	check(puzzle.get_node_or_null("Reflector/Stand") == null and puzzle.get_node_or_null("Reflector/Post") == null, "Duplicate provisional pedestal")
	check(puzzle.get_node("Reflector").position == Vector3(3.8, 0, 3) and puzzle.interaction_radius == 1.25, "Placement/radius changed")
	var shape: CollisionShape3D = puzzle.get_node("Reflector/Body/Shape")
	check(shape.position == Vector3(0, 0.8, 0) and is_equal_approx(shape.shape.radius, 0.4) and is_equal_approx(shape.shape.height, 1.6), "Collider changed")
	var physical_count := scene.find_children("*", "CollisionShape3D", true, false).size()
	check(visual.find_children("*", "CollisionShape3D", true, false).is_empty(), "Art adds physics")

	# Logical response is immediate, while the mesh follows independently.
	await tap("interact")
	check(puzzle.orientation == 1 and puzzle.path.reflected and not puzzle.solved, "Logical turn/obstacle changed")
	check(is_equal_approx(puzzle.get_node("Reflector/Pivot").rotation.y, PI / 4.0), "Optical pivot waits for animation")
	check(visual.assembly.rotation.y > -PI / 4.0 and visual.assembly.rotation.y < PI / 4.0, "No intermediate visual turn")
	check(visual._turn != null and visual._turn.is_running(), "Missing brief tween")
	await frames(30)
	synchronized(puzzle)

	# Fresh presses during an unfinished turn retarget the mesh without a queue.
	for i in range(7):
		var previous: int = puzzle.orientation
		await tap("interact")
		check(puzzle.orientation == 1 - previous, "Successive input did not change only the existing state")
		check(pedestal.global_transform.is_equal_approx(fixed), "Pedestal rotates")
	await frames(30)
	synchronized(puzzle)
	check(puzzle.orientation == 0 and not puzzle.solved and completions == 0, "Successive inputs desynchronized gameplay")
	action("interact", true)
	await frames(3)
	var held_state: int = puzzle.orientation
	for repeat in range(8):
		action("interact", true)
		await frames(4)
	check(puzzle.orientation == held_state, "Held input repeated")
	action("interact", false)
	await frames(30)
	synchronized(puzzle)
	check(puzzle.orientation == 1 and not puzzle.solved, "Held press/obstacle state wrong")

	# Returning to an accessible position preserves the logical and visual state.
	scene.get_node("Player").position = Vector3(-2, 0.01, 2)
	await frames(5)
	scene.get_node("Player").position = Vector3(4.8, 0.01, 3.5)
	await frames(5)
	synchronized(puzzle)
	obstacle.queue_free()
	await frames(4)
	check(puzzle.solved and completions == 1 and scene.restored_count() == 1, "Real reception/progress changed")
	for attempt in range(4):
		await tap("interact")
		puzzle.rotate_once()
	await frames(30)
	synchronized(puzzle)
	check(puzzle.orientation == 1 and completions == 1, "Solved interaction restarted orientation")
	check(pedestal.global_transform.is_equal_approx(fixed), "Fixed base changed")
	check(scene.find_children("*", "CollisionShape3D", true, false).size() == physical_count - 1, "Unexpected physics changes")
	check(scene.get_node("Lighthouse").state == 0 and scene.get_node("Bridge").state == 0, "P1 alone activated lighthouse/bridge")
	check(not scene.get_node("GuardianMirrors").solved and not scene.get_node("FractalRotor").solved, "P1 altered other puzzles")
	await discard(scene)

	# A solution reached during the tween must not interrupt its final visual pose.
	scene = fixture()
	puzzle = scene.get_node("LostLight")
	visual = puzzle.get_node("Reflector/Visual")
	await frames(5)
	await tap("interact")
	check(puzzle.solved and completions == 1 and visual._turn.is_running(), "Resolution timing was changed by visuals")
	await frames(30)
	synchronized(puzzle)
	await discard(scene)
	if "--capture" in OS.get_cmdline_user_args():
		await capture_integrated()
	print("lost_light_visual: pivot mapping, smooth turn/retarget, held input, fixed pedestal, physics, session, unique resolution/progress; failures: %d" % failures)
	quit(1 if failures else 0)


func capture_integrated() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/p1-integration")
	for view in range(4):
		var scene := fixture()
		var puzzle: Node3D = scene.get_node("LostLight")
		var camera: Camera3D = scene.get_node("Camera")
		camera.yaw = PI / 4.0 + view * PI / 2.0
		await frames(60)
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://build/p1-integration/initial-view%d.png" % view) == OK, "Initial capture failed")
		await tap("interact")
		await frames(30)
		check(puzzle.solved, "Capture did not use real puzzle interaction")
		synchronized(puzzle)
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://build/p1-integration/solved-view%d.png" % view) == OK, "Solved capture failed")
		await discard(scene)
