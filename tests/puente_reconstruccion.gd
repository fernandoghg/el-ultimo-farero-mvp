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


func floor_at(scene: Node3D, x: float) -> bool:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 0.1, -3), Vector3(x, -0.5, -3))
	return not scene.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


# Measure the visible shelves and their rims at the bridge centerline.
func terrain_edge_at_bridge(terrain_meshes: Array[MeshInstance3D], take_max: bool) -> float:
	var edge_x := -INF if take_max else INF
	for terrain in terrain_meshes:
		check(terrain.is_visible_in_tree(), "Bridge rim test must use the visible terrain")
		var faces := terrain.mesh.get_faces()
		for index in range(0, faces.size(), 3):
			for edge in range(3):
				var a := terrain.to_global(faces[index + edge])
				var b := terrain.to_global(faces[index + (edge + 1) % 3])
				if is_equal_approx(a.z, b.z):
					continue
				var fraction := (-3.0 - a.z) / (b.z - a.z)
				if fraction >= 0.0 and fraction <= 1.0:
					var point := a.lerp(b, fraction)
					if point.y >= -0.05:
						edge_x = maxf(edge_x, point.x) if take_max else minf(edge_x, point.x)
	return edge_x


func run() -> void:
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	# Bridge safety/activation remains covered after restoring the real three circuits.
	await preload("res://tests/circuit_fixture.gd").all(scene)
	var bridge: Node3D = scene.get_node("Bridge")
	var player: CharacterBody3D = scene.get_node("Player")
	var camera: Camera3D = scene.get_node("Camera")
	var lighthouse: Node3D = scene.get_node("Lighthouse")
	# Visual deck must meet the island edges without coplanar overlap or gaps.
	var ground: MeshInstance3D = scene.get_node("Ground")
	check(ground.mesh == null, "Old floor visual still duplicates the approved terrain")
	var floor_shape: CollisionShape3D = ground.get_node("Body/CollisionShape3D")
	var previous_end: float = floor_shape.global_position.x + (floor_shape.shape as BoxShape3D).size.x * 0.5
	var visual_edge := terrain_edge_at_bridge([
		scene.get_node("IslandArt/Cliff"), scene.get_node("IslandArt/GrassCap")
	], true)
	check(visual_edge <= previous_end + 0.00001, "Approved terrain overlaps bridge entrance")
	check(previous_end - visual_edge <= 0.035, "Terrain rim retreat exceeds the approved bevel width")
	print("Bridge entrance: visual_edge=", visual_edge, "; physical_edge=", previous_end)
	for segment: MeshInstance3D in bridge.get_node("Segments").get_children():
		var start_x := segment.global_position.x + segment.get_aabb().position.x
		check(absf(start_x - previous_end) < 0.00001, "Visual deck has overlapping faces or a gap")
		previous_end = segment.global_position.x + segment.get_aabb().end.x
	var landing_edge := terrain_edge_at_bridge([
		scene.get_node("ErodedRock/LandingCliff"), scene.get_node("IslandArt/LandingCap")
	], false)
	check(absf(previous_end - landing_edge) < 0.00001, "Visual deck overlaps destination or leaves a gap")
	print("Bridge exit: visual_edge=", landing_edge, "; deck_edge=", previous_end)
	camera.yaw = 0.0
	player.position = Vector3(4.8, 0.01, -3)
	await frames(3)
	check(is_equal_approx(bridge.reconstruction_duration, 1.5), "Default duration changed")
	check(bridge.state == bridge.State.DESTROYED and bridge.deck_collision.disabled, "Bridge not initially destroyed")
	check(not floor_at(scene, 9), "Destroyed deck has physical floor")
	Input.action_press("move_right")
	await frames(25)
	Input.action_release("move_right")
	check(player.position.x < 5.5 and player.is_on_floor(), "Initial gate does not protect entrance")
	player.position = Vector3(13, 0.01, -3)
	player.velocity = Vector3.ZERO
	await frames(3)
	Input.action_press("move_left")
	await frames(25)
	Input.action_release("move_left")
	check(player.position.x > 12.5 and player.is_on_floor(), "Initial gate does not protect destination")
	# Activate the real lighthouse through its existing input path.
	player.position = Vector3(4.5, 0.01, -3)
	player.velocity = Vector3.ZERO
	await frames(2)
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)
	await frames(1)
	event = InputEventAction.new()
	event.action = "interact"
	event.pressed = false
	Input.parse_input_event(event)
	check(bridge.state == bridge.State.REBUILDING, "Lighthouse did not start reconstruction")
	var elapsed := 1
	# Keep walking away from the lighthouse into the gate throughout construction.
	Input.action_press("move_right")
	for index in range(40):
		lighthouse.activated.emit()
		await frames(1)
		elapsed += 1
		check(bridge.deck_collision.disabled and not floor_at(scene, 9), "Intermediate bridge is traversable")
		check(player.position.x < 5.5 and player.position.y > -0.05, "Player entered incomplete bridge or fell")
	check(player.global_position.distance_to(lighthouse.global_position) > lighthouse.interaction_radius, "Player did not leave lighthouse range")
	check(bridge.get_node("Segments/Segment0").position.y > -0.21, "First segment did not rise")
	check(bridge.get_node("Segments/Segment5").position.y < -1.0, "Segments did not rise progressively")
	while bridge.state != bridge.State.READY and elapsed < 120:
		await frames(1)
		elapsed += 1
		if bridge.entrance_collision.disabled:
			check(floor_at(scene, 9), "Gate opened before physics floor was active")
		check(player.position.y > -0.05, "Player fell at opening transition")
	Input.action_release("move_right")
	check(bridge.state == bridge.State.READY, "Reconstruction did not finish")
	check(elapsed >= 88 and elapsed <= 100, "Repeated signals restarted or shortened reconstruction")
	check(not bridge.deck_collision.disabled and floor_at(scene, 9), "Final deck has no collision")
	check(bridge.entrance_collision.disabled and bridge.exit_collision.disabled, "Final gates still closed")
	for segment: Node3D in bridge.get_node("Segments").get_children():
		check(is_equal_approx(segment.position.y, -0.2), "Final segment not aligned")
	var final_transforms: Array[Transform3D] = []
	for segment: Node3D in bridge.get_node("Segments").get_children():
		final_transforms.append(segment.transform)
	lighthouse.activated.emit()
	await frames(3)
	check(bridge.state == bridge.State.READY, "Ready bridge restarted")
	# Actual CharacterBody3D crossings, with continuous floor contact checks.
	Input.action_press("move_right")
	for index in range(145):
		await frames(1)
		check(player.is_on_floor() and player.position.y > -0.05, "Outbound crossing lost floor")
	Input.action_release("move_right")
	check(player.position.x > 14, "Player did not reach destination")
	Input.action_press("move_left")
	for index in range(145):
		await frames(1)
		check(player.is_on_floor() and player.position.y > -0.05, "Return crossing lost floor")
	Input.action_release("move_left")
	check(player.position.x < 6, "Player did not return to first island")
	for index in range(final_transforms.size()):
		check(bridge.get_node("Segments").get_child(index).transform == final_transforms[index], "Completed segment kept moving")
	# Lateral rails, destination perimeter and unmodified parts of initial limit.
	for location: Vector3 in [Vector3(9, 0.01, -3), Vector3(15, 0.01, -3), Vector3(5, 0.01, 2)]:
		player.position = location
		player.velocity = Vector3.ZERO
		await frames(3)
		var action := "move_right" if location.z > 0 else "move_forward"
		Input.action_press(action)
		await frames(75)
		Input.action_release(action)
		check(player.is_on_wall() and player.is_on_floor() and player.position.y > -0.05, "Side protection failed at %s" % location)
	for action: String in ["move_forward", "move_back", "move_right", "move_left"]:
		player.position = Vector3(15, 0.01, -1)
		player.velocity = Vector3.ZERO
		await frames(3)
		Input.action_press(action)
		await frames(90)
		Input.action_release(action)
		check(player.is_on_floor() and player.is_on_wall(), "Destination perimeter failed: " + action)
	player.position = Vector3(9, 0.01, -3)
	player.velocity = Vector3.ZERO
	await frames(3)
	Input.action_press("move_back")
	await frames(45)
	Input.action_release("move_back")
	check(player.is_on_wall() and player.is_on_floor(), "South bridge rail failed")
	# Separate reusable instance proves duration is configurable without restarting main.
	var other: Node3D = load("res://scenes/bridge.tscn").instantiate()
	other.position = Vector3(50, 0, 0)
	other.reconstruction_duration = 0.3
	scene.add_child(other)
	other.reconstruct()
	await frames(25)
	check(other.state == other.State.READY, "Configured short duration ignored")
	print("puente_reconstruccion: %d failures" % failures)
	quit(0 if failures == 0 else 1)
