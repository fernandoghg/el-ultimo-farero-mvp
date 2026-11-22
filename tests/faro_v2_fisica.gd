extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(valid: bool, message: String) -> void:
	if not valid:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func press(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = pressed
	Input.parse_input_event(event)

func walk(player: CharacterBody3D, start: Vector3, direction: Vector3, count: int) -> void:
	player.position = start
	player.velocity = Vector3.ZERO
	await frames(3)
	for i in range(count):
		await physics_frame
		player.velocity = direction * 2.0 + Vector3(0, -0.5, 0)
		player.move_and_slide()
		await process_frame
	player.velocity = Vector3.ZERO

func run() -> void:
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	var player: CharacterBody3D = scene.get_node("Player")
	player.set_physics_process(false)
	var faro: Node3D = scene.get_node("Lighthouse")
	await frames(4)
	check(faro.interaction_radius == 2.0 and not faro.light.visible, "Radius changed or light initially on")
	var activations := [0]
	faro.activated.connect(func(): activations[0] += 1)
	# Four approaches with the actual character capsule: its center must stop at
	# least the half-width 0.55 plus the capsule radius 0.3 from the tower center.
	for direction: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		await walk(player, faro.position + direction * 1.35 + Vector3(0, 0.01, 0), -direction, 45)
		var offset := player.position - faro.position
		check(offset.dot(direction) >= 0.84 and player.is_on_floor(), "Character penetrated V2 base from " + str(direction))
		check(faro.is_player_in_range(), "Accessible blocked approach cannot interact")
		press(true)
		await frames(2)
		press(false)
		check(faro.state == 0 and activations[0] == 0, "Premature activation from accessible approach")
	# The new upper volume must block physics rays up to the roof, not just the
	# old baliza. The ray excludes the character and identifies the lighthouse body.
	for y in [0.2, 2.5, 3.3, 3.85]:
		var origin := faro.position + Vector3(-1.5, y, 0)
		var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3(3, 0, 0), 1, [player.get_rid()])
		var hit := scene.get_world_3d().direct_space_state.intersect_ray(query)
		check(hit.get("collider") == faro.get_node("Body"), "Lighthouse has uncovered solid volume at " + str(y))
	# Gap between monument end X=1.8 and tower edge X=2.45 is 0.65 for a 0.6
	# capsule. Test a real grounded traversal, rather than only measuring the gap.
	await walk(player, Vector3(2.125, 0.01, -5.25), Vector3.BACK, 65)
	check(player.position.z > -3.2 and player.is_on_floor(), "Monument-side corridor blocked by V2")
	await walk(player, Vector3(3.9, 0.01, -3), Vector3.RIGHT, 20)
	check(player.position.x > 4.5 and player.is_on_floor(), "Bridge approach blocked by V2")
	await preload("res://tests/circuit_fixture.gd").all(scene)
	player.position = faro.position + Vector3(1.2, 0.01, 0)
	await frames(3)
	var lens: MeshInstance3D = faro.get_node("Beacon")
	var lens_center := lens.to_global(lens.mesh.get_aabb().get_center())
	check(faro.light.global_position.distance_to(lens_center) < 0.001, "OmniLight not centered on V2 lens")
	press(true)
	await frames(3)
	press(false)
	check(faro.state == 1 and faro.light.visible and activations[0] == 1, "Aligned V2 lighthouse did not activate once")
	check(lens.get_active_material(0).emission_enabled, "V2 lens is not emissive after activation")
	await frames(120)
	check(scene.get_node("Bridge").state == 2, "V2 lighthouse did not complete bridge reconstruction")
	for i in range(3):
		press(true)
		await frames(2)
		press(false)
	check(activations[0] == 1, "V2 emitted repeated activation")
	print("faro_v2_fisica: four blocked approaches, upper volume, monument corridor, bridge approach, aligned lens/light, unique activation; %d failures" % failures)
	quit(1 if failures else 0)
