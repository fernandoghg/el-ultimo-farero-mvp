extends "res://tests/introduccion.gd"

const MOVEMENT_KEYS: Array[Key] = [KEY_W, KEY_A, KEY_S, KEY_D]


func walk_to(player: CharacterBody3D, point: Vector2) -> void:
	# Steer with the same eight directions as WASD, without moving the body directly.
	var camera := player.get_viewport().get_camera_3d()
	var right := Vector2(camera.basis.x.x, camera.basis.x.z).normalized()
	var back := Vector2(camera.basis.z.x, camera.basis.z.z).normalized()
	var held: Array[Key] = []
	for step in range(240):
		var remaining := point - Vector2(player.position.x, player.position.z)
		if remaining.length() < 0.14:
			break
		var direction := Vector2(remaining.dot(right), remaining.dot(back))
		var angle := roundf(direction.angle() / (PI / 4.0)) * PI / 4.0
		var axis := Vector2.from_angle(angle).round()
		var next: Array[Key] = []
		if axis.y < 0:
			next.append(KEY_W)
		if axis.x < 0:
			next.append(KEY_A)
		if axis.y > 0:
			next.append(KEY_S)
		if axis.x > 0:
			next.append(KEY_D)
		for code in MOVEMENT_KEYS:
			if held.has(code) != next.has(code):
				key(code, next.has(code))
		held = next
		await frames(1)
	for code in held:
		key(code, false)
	await frames(2)
	check(Vector2(player.position.x, player.position.z).distance_to(point) < 0.20 and player.is_on_floor(),
		"Could not walk to %s, stopped at %s" % [point, player.position])


func play(scene: Node3D) -> void:
	var ending: CanvasLayer = scene.get_node("Ending")
	var player: CharacterBody3D = scene.get_node("Player")
	var camera: Camera3D = scene.get_node("Camera")
	var lighthouse: Node3D = scene.get_node("Lighthouse")
	var bridge: Node3D = scene.get_node("Bridge")
	await tap_key(KEY_ENTER)
	check(not paused and not ending.visible, "Intro did not give way to exploration")
	await walk_to(player, Vector2(-3, 3))
	await tap_key(KEY_I)
	check(not camera.current, "P3 did not open")
	for turn in range(2):
		await tap_key(KEY_I)
		await frames(16)
	await tap_key(KEY_A)
	await tap_key(KEY_I)
	await frames(16)
	await tap_key(KEY_ESCAPE)
	check(scene.circuit_is_restored(&"P3") and camera.current and not ending.visible, "P3 did not resolve or triggered the ending")
	await walk_to(player, Vector2(-5.3, 3))
	await walk_to(player, Vector2(-5.3, 1.2))
	await tap_key(KEY_I)
	await walk_to(player, Vector2(-5.12, 0.23))
	await tap_key(KEY_I)
	check(scene.circuit_is_restored(&"P2") and not ending.visible, "P2 did not resolve or triggered the ending")

	for point in [Vector2(-5.3, 2), Vector2(1.2, 2), Vector2(1.2, -1.55), Vector2(3, -1.55)]:
		await walk_to(player, point)
	await tap_key(KEY_I)
	check(lighthouse.is_player_in_range() and lighthouse._attempt_count == 2 and lighthouse._progress_remaining > 0.0,
		"Incomplete lighthouse attempt did not show progress")
	bridge.reconstructed.emit()
	check(not ending.visible and not paused and lighthouse.state == 0 and bridge.state == 0, "Incomplete attempt triggered the ending")

	for point in [Vector2(4.85, -1.55), Vector2(4.85, 3.4)]:
		await walk_to(player, point)
	await tap_key(KEY_I)
	check(scene.restored_count() == 3 and lighthouse.state == 0 and not ending.visible, "Third circuit did not resolve or auto-activated")
	await tap_key(KEY_I)
	check(lighthouse.state == 0 and not ending.visible, "Out-of-range press activated the lighthouse")
	for point in [Vector2(4.85, -1.55), Vector2(3, -1.55)]:
		await walk_to(player, point)
	await tap_key(KEY_I)
	check(lighthouse.state == lighthouse.State.ACTIVE and lighthouse.light.visible and lighthouse.beacon.material_override.emission_enabled,
		"Fresh in-range I did not illuminate the lighthouse")
	check(bridge.state == bridge.State.REBUILDING and not ending.visible and not paused, "Card appeared before reconstruction")
	for frame in range(160):
		if ending.visible:
			break
		await frames(1)
	check(ending.visible and paused and camera.current and not lighthouse.prompt.visible, "Ending was missing or conflicted with exploration")
	check(bridge.state == bridge.State.READY and not bridge.deck_collision.disabled and bridge.entrance_collision.disabled and bridge.exit_collision.disabled,
		"Ending appeared before the bridge was ready for traversal")


func check_reset(scene: Node3D) -> void:
	var lighthouse: Node3D = scene.get_node("Lighthouse")
	var bridge: Node3D = scene.get_node("Bridge")
	check(scene.has_node("Introduction") and paused and not scene.get_node("Ending").visible, "Replay did not open a new introduction")
	check(scene.restored_count() == 0 and scene.get_node("LostLight").orientation == 0, "Replay retained P1 or circuit progress")
	for id: StringName in scene.CIRCUITS:
		check(not scene.get_node(scene.CIRCUITS[id]).solved, "Replay retained %s" % id)
	check(lighthouse.state == 0 and not lighthouse.light.visible and lighthouse.beacon.material_override == null, "Replay retained lighthouse state")
	check(bridge.state == 0 and bridge.deck_collision.disabled and not bridge.entrance_collision.disabled and not bridge.exit_collision.disabled,
		"Replay retained bridge state")
	check(not scene.get_node("Player").controls_suspended and not scene.get_node("Camera").controls_suspended, "Replay retained suspended controls")


func run() -> void:
	root.size = Vector2i(1280, 720)
	check(change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene")) == OK, "Entry point did not load")
	await scene_changed
	await play(current_scene)
	if failures:
		quit(1)
		return
	var ending: CanvasLayer = current_scene.get_node("Ending")
	var card: PanelContainer = ending.get_node("Card")
	var title: Label = card.get_node("Content/Title")
	var story: Label = card.get_node("Content/Story")
	var english := OS.get_cmdline_user_args().has("en")
	check(title.tr(title.text) == ("The light has returned" if english else "La luz ha regresado"), "Wrong ending title")
	check(story.tr(story.text).contains("Your first mission is complete" if english else "Tu primera misión ha terminado"), "Wrong ending story")
	check(ending.replay.tr(ending.replay.text) == ("Play again" if english else "Volver a jugar"), "Wrong Replay label")
	check(ending.exit.tr(ending.exit.text) == ("Quit" if english else "Salir"), "Wrong Exit label")
	check(ending.replay.has_focus(), "Replay did not receive initial focus")
	var player: Node3D = current_scene.get_node("Player")
	var camera := root.get_camera_3d()
	var position_before := player.position
	var camera_before := camera.transform
	var bridge: Node3D = current_scene.get_node("Bridge")
	var shows := [0]
	ending.visibility_changed.connect(func(): shows[0] += 1)
	for code in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_Q, KEY_E, KEY_I, KEY_ESCAPE]:
		await tap_key(code)
	bridge.reconstructed.emit()
	check(shows[0] == 0 and ending.visible, "Ending was duplicated or dismissed")
	check(player.position == position_before and camera.transform == camera_before, "Controls leaked into completed gameplay")
	for size in [Vector2i(960, 540), Vector2i(1600, 900), Vector2i(1280, 720)]:
		root.size = size
		await frames(4)
		check(root.get_visible_rect().encloses(card.get_global_rect()), "Ending exceeds viewport at %s" % size)
		var light: Node3D = current_scene.get_node("Lighthouse/Light")
		var lens := camera.unproject_position(light.global_position)
		check(root.get_visible_rect().has_point(lens) and not card.get_global_rect().has_point(lens), "Lens is outside the visible background")
	if OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute("res://build/mvp02")
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(image.get_size() == Vector2i(1280, 720), "Capture is not 1280x720")
		check(image.save_png("res://build/mvp02/desenlace-%s.png" % TranslationServer.get_locale()) == OK, "Could not save ending capture")

	if OS.get_cmdline_user_args().has("--check-exit"):
		await tap_key(KEY_RIGHT)
		check(ending.exit.has_focus(), "Keyboard did not focus Exit")
		if failures:
			quit(1)
			return
		print("Desenlace: %d failures before activating Exit" % failures)
		await tap_key(KEY_ENTER)
		check(false, "Exit did not quit the game")
	else:
		# Send both events without awaiting so scene_changed cannot be missed.
		var previous := current_scene.get_instance_id()
		key(KEY_ENTER, true)
		key(KEY_ENTER, false)
		for frame in range(30):
			await frames(1)
			if current_scene != null and current_scene.get_instance_id() != previous:
				break
		if current_scene == null or current_scene.get_instance_id() == previous:
			push_error("Replay did not replace the completed scene")
			quit(1)
			return
		check_reset(current_scene)
		await tap_key(KEY_ENTER)
		check(not paused and not current_scene.has_node("Introduction"), "Replayed intro did not resume exploration")
	print("Desenlace: %d failures" % failures)
	quit(1 if failures else 0)
