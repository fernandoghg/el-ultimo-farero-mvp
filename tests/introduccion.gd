extends "res://tests/fractal_un_rotor.gd"


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func tap_key(code: Key) -> void:
	key(code, true)
	await frames(2)
	key(code, false)
	await frames(2)


func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	DirAccess.make_dir_recursive_absolute("res://build/mvp01")
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://build/mvp01/%s-%s-%dx%d.png" % [
		name, TranslationServer.get_locale(), image.get_width(), image.get_height(),
	]
	check(image.save_png(path) == OK, "Could not save " + path)


func check_restoration(scene: Node3D, player: CharacterBody3D) -> void:
	var p2: Node3D = scene.get_node("GuardianMirrors")
	for mirror: Node3D in p2.mirrors:
		player.position = mirror.position + Vector3(-0.8, 0.01, 0)
		await frames(4)
		await tap_key(KEY_I)
	check(p2.solved and scene.restored_count() == 2, "P2 did not resolve after the introduction")

	var p3: Node3D = scene.get_node("FractalRotor")
	player.position = Vector3(-3, 0.01, 3)
	await frames(4)
	await tap_key(KEY_I)
	check(p3.inspection_camera.current, "P3 did not open after the introduction")
	for turn in range(2):
		await tap_key(KEY_I)
		await frames(12)
	await tap_key(KEY_A)
	await tap_key(KEY_I)
	await frames(16)
	check(p3.solved and scene.restored_count() == 3, "P3 did not resolve after the introduction")
	await tap_key(KEY_ESCAPE)
	check(scene.get_node("Camera").current, "Esc did not return to exploration")

	var lighthouse: Node3D = scene.get_node("Lighthouse")
	var bridge: Node3D = scene.get_node("Bridge")
	check(lighthouse.state == lighthouse.State.OFF and bridge.state == 0, "Restoration skipped manual lighthouse activation")
	player.position = Vector3(3, 0.01, -1.5)
	await frames(4)
	await tap_key(KEY_I)
	await frames(100)
	check(lighthouse.state == lighthouse.State.ACTIVE and bridge.state == 2, "Lighthouse did not restore the bridge")


func run() -> void:
	var start: String = ProjectSettings.get_setting("application/run/main_scene")
	if change_scene_to_file(start) != OK:
		push_error("Project entry point did not load")
		quit(1)
		return
	await scene_changed
	await frames(4)
	var scene := current_scene
	var intro := scene.get_node("Introduction")
	var card: PanelContainer = intro.get_node("Card")
	var player: CharacterBody3D = scene.get_node("Player")
	var camera: Camera3D = scene.get_node("Camera")
	var p1: Node3D = scene.get_node("LostLight")
	var arguments := OS.get_cmdline_user_args()
	var language_option := arguments.find("--game-language")
	var english := language_option >= 0 and language_option + 1 < arguments.size() and arguments[language_option + 1] == "en"
	var title: Label = card.get_node("Content/Title")
	check(paused and card.is_visible_in_tree(), "New game did not show the modal introduction")
	check(title.tr(title.text) == ("The Last Lighthouse Keeper" if english else "El último farero"), "Wrong introduction language")
	for size in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900)]:
		root.size = size
		await frames(4)
		check(root.get_visible_rect().encloses(card.get_global_rect()), "Introduction exceeds the viewport at %s" % size)
		await capture("introduccion")
	root.size = Vector2i(1280, 720)

	# Test interaction in range, so a leaked I press would turn the reflector.
	player.position = Vector3(4.8, 0.01, 3.5)
	var position_before := player.position
	var yaw_before: float = camera.yaw
	var orientation_before: int = p1.orientation
	for code in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_Q, KEY_E, KEY_I, KEY_ESCAPE]:
		await tap_key(code)
	check(player.position.is_equal_approx(position_before), "Movement leaked through the introduction")
	check(is_equal_approx(camera.yaw, yaw_before) and not camera.is_turning(), "Camera rotation leaked through the introduction")
	check(p1.orientation == orientation_before, "Interaction leaked through the introduction")

	key(KEY_W, true)
	key(KEY_I, true)
	await tap_key(KEY_ENTER)
	check(paused and intro.continue_prompt.text == "INTRO_RELEASE_KEYS", "Enter accepted held gameplay controls")
	key(KEY_W, false)
	key(KEY_I, false)
	await tap_key(KEY_ENTER)
	check(not paused and not is_instance_valid(intro), "Enter did not resume the game and remove the introduction")
	await frames(20)
	check(p1.prompt.visible, "Existing P1 guidance did not return")
	await capture("exploracion")

	await tap_key(KEY_I)
	check(p1.orientation != orientation_before and p1.solved, "Fresh I press did not resolve P1 after continuing")
	await tap_key(KEY_Q)
	check(camera.is_turning(), "Q did not rotate the camera after continuing")
	await frames(34)
	await tap_key(KEY_E)
	check(camera.is_turning(), "E did not rotate the camera after continuing")
	await frames(34)
	check(is_equal_approx(camera.yaw, yaw_before), "Q and E did not rotate in opposite directions")
	for code in [KEY_W, KEY_A, KEY_S, KEY_D]:
		player.position = Vector3(0, 0.05, 0)
		await frames(4)
		position_before = player.position
		await tap_key(code)
		check(Vector2(player.position.x, player.position.z).distance_to(Vector2(position_before.x, position_before.z)) > 0.05, "Movement did not recover for %s" % OS.get_keycode_string(code))
	await check_restoration(scene, player)
	check(not scene.has_node("Introduction"), "The introduction reappeared during exploration")
	check(reload_current_scene() == OK, "Could not reload the new game")
	await scene_changed
	check(paused and current_scene.has_node("Introduction"), "Introduction did not appear in a new session")
	await tap_key(KEY_KP_ENTER)
	check(not paused, "Numpad Enter did not continue")
	print("introduccion: %d failures" % failures)
	quit(1 if failures else 0)
