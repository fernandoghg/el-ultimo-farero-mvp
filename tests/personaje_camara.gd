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


func run() -> void:
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	var player: CharacterBody3D = scene.get_node("Player")
	var camera: Camera3D = scene.get_node("Camera")
	for action: String in ["move_forward", "move_back", "move_left", "move_right", "camera_left", "camera_right", "interact", "pause"]:
		check(InputMap.has_action(action), "Missing input action: " + action)
	player.position = Vector3(-2, 2, 2)
	await frames(90)
	check(player.is_on_floor() and absf(player.position.y) < 0.01, "Gravity/floor collision failed")
	for tick_rate: int in [30, 60, 120]:
		Engine.physics_ticks_per_second = tick_rate
		player.position = Vector3(-2, 0.01, 2)
		player.velocity = Vector3.ZERO
		await frames(3)
		var start := player.position
		Input.action_press("move_forward")
		await frames(tick_rate >> 1)
		Input.action_release("move_forward")
		check(absf(start.distance_to(player.position) - 2.0) < 0.16, "Movement depends on tick rate: %d" % tick_rate)
	Engine.physics_ticks_per_second = 60
	player.position = Vector3(-2, 0.01, 2)
	await frames(3)
	Input.action_press("move_forward")
	Input.action_press("move_right")
	await frames(2)
	check(absf(Vector2(player.velocity.x, player.velocity.z).length() - 4.0) < 0.01, "Diagonal speed is not normalized")
	Input.action_release("move_right")
	var initial_yaw: float = camera.yaw
	var turn_frames := ceili(camera.turn_duration * Engine.physics_ticks_per_second) + 4
	camera.request_turn(1.0)
	camera.request_turn(1.0)
	for index in range(turn_frames):
		await frames(1)
		var forward := -camera.global_basis.z
		forward.y = 0.0
		var horizontal := Vector3(player.velocity.x, 0, player.velocity.z)
		check(horizontal.normalized().dot(forward.normalized()) > 0.999, "Movement diverges from camera during turn")
		check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Projection changed")
	check(absf(camera.yaw - initial_yaw - PI / 2.0) < 0.001, "Repeated turn was queued or turn did not finish")
	Input.action_release("move_forward")
	camera.request_turn(-1.0)
	await frames(turn_frames)
	check(absf(camera.yaw - initial_yaw) < 0.001, "Opposite turn failed")
	check(absf(camera.rotation.x - deg_to_rad(-35.264)) < 0.001, "Camera inclination changed")
	player.position = Vector3(-4, 0.01, 4)
	await frames(100)
	var focus: Vector3 = camera.global_position - Vector3(sin(camera.yaw) * camera.ORBIT_DISTANCE, 10, cos(camera.yaw) * camera.ORBIT_DISTANCE)
	check(focus.distance_to(player.global_position) < 0.01, "Follow did not converge")
	Input.action_press("move_back")
	await frames(240)
	Input.action_release("move_back")
	check(player.is_on_floor() and absf(player.position.x) < 6 and absf(player.position.z) < 6, "Player escaped the floor boundary")
	# Approach each solid from -X using camera-relative D, then slide along its face.
	camera.yaw = 0.0
	await frames(2)
	for obstacle_name: String in ["Center", "PositiveX", "PositiveZ", "RaisedStep"]:
		var obstacle: MeshInstance3D = scene.get_node(obstacle_name)
		var box: BoxMesh = obstacle.mesh
		var shape: CollisionShape3D = obstacle.get_node("Body/CollisionShape3D")
		check((shape.shape as BoxShape3D).size.is_equal_approx(box.size), "Collider does not match mesh: " + obstacle_name)
		var face_x: float = obstacle.position.x - box.size.x / 2.0
		player.position = Vector3(face_x - 1.2, 0.01, obstacle.position.z)
		player.velocity = Vector3.ZERO
		await frames(3)
		Input.action_press("move_right")
		await frames(30)
		check(player.position.x < face_x - 0.28 and player.position.x > face_x - 0.33, "Obstacle did not block player: " + obstacle_name)
		check(player.is_on_wall() and player.is_on_floor(), "Missing wall/floor contact: " + obstacle_name)
		var slide_start := player.position
		Input.action_press("move_back")
		await frames(5)
		Input.action_release("move_back")
		Input.action_release("move_right")
		check(player.position.z > slide_start.z + 0.15, "Player cannot slide: " + obstacle_name)
		check(player.position.x < face_x - 0.28, "Player penetrated obstacle while sliding: " + obstacle_name)
	# Following must settle exactly, remain still, and resume smoothly. Exercise
	# several physics rates while keeping the existing exponential follow speed.
	player.set_physics_process(false)
	camera.set_physics_process(false)
	player.position = Vector3(3, 0.01, -1.5)
	for tick_rate: int in [30, 60, 120]:
		camera._focus = player.position + Vector3(0.1, 0, 0)
		camera._physics_process(1.0 / tick_rate)
		check(absf(camera._focus.distance_to(player.position) - 0.1 * exp(-8.0 / tick_rate)) < 0.00001, "Follow speed changed: %d" % tick_rate)
		for step in range(tick_rate * 2):
			camera._physics_process(1.0 / tick_rate)
		check(camera._focus == player.position, "Follow never settles exactly: %d" % tick_rate)
		var stable_position: Vector3 = camera.global_position
		for step in range(20):
			camera._physics_process(1.0 / tick_rate)
		check(camera.global_position == stable_position, "Stationary camera retains residual motion")
	# With zero elapsed time, only the authorized tiny correction may move it.
	camera._focus = player.position + Vector3(0.0026, 0, 0)
	camera._physics_process(0.0)
	check(camera._focus != player.position, "Settling triggered above the threshold")
	camera._focus = player.position + Vector3(0.0024, 0, 0)
	camera._update_transform()
	var before_settle: Vector3 = camera.global_position
	var before_yaw: float = camera.yaw
	camera._physics_process(0.0)
	check(camera._focus == player.position and camera.global_position.distance_to(before_settle) <= 0.0025, "Settling exceeded authorized displacement")
	check(camera.yaw == before_yaw, "Settling changed orbital yaw")
	player.position += Vector3(0.5, 0, 0)
	camera._physics_process(1.0 / 60.0)
	check(camera._focus.distance_to(player.position) > 0.4 and camera._focus.distance_to(player.position) < 0.5, "Camera no longer resumes smooth following")
	camera.set_physics_process(true)
	await frames(100)
	# Exercise both mapped Q/E actions through four orientations each.
	for turn_action: StringName in [&"camera_left", &"camera_right"]:
		var direction := 1.0 if turn_action == &"camera_left" else -1.0
		var cycle_start: float = camera.yaw
		var cycle_position: Vector3 = camera.global_position
		for orientation in range(4):
			var event := InputEventAction.new()
			event.action = turn_action
			event.pressed = true
			Input.parse_input_event(event)
			await frames(turn_frames)
			event = InputEventAction.new()
			event.action = turn_action
			event.pressed = false
			Input.parse_input_event(event)
			check(absf(camera.yaw - cycle_start - direction * (orientation + 1) * PI / 2.0) < 0.001, "Mapped quarter-turn changed")
			check(camera._focus == player.position and not camera.is_turning(), "Follow settling interferes with a completed turn")
		check(camera.global_position.distance_to(cycle_position) < 0.001, "Four mapped turns did not restore the camera orbit")
	print("personaje_camara: %d failures" % failures)
	quit(0 if failures == 0 else 1)
