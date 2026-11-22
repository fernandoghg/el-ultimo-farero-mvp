extends SceneTree

var failures: int = 0
var activation_count: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func settle() -> void:
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame


func interact(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = pressed
	Input.parse_input_event(event)


func run() -> void:
	print("locale before main: %s; args: %s; user args: %s; catalogs: %s" % [TranslationServer.get_locale(), OS.get_cmdline_args(), OS.get_cmdline_user_args(), TranslationServer.get_loaded_locales()])
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	var player: CharacterBody3D = scene.get_node("Player")
	player.set_physics_process(false)
	# Preserve the activation regression with the actual new prerequisite satisfied.
	await preload("res://tests/circuit_fixture.gd").all(scene)
	var lighthouse: Node3D = scene.get_node("Lighthouse")
	var prompt: Label = lighthouse.get_node("InteractionUI/Prompt")
	lighthouse.activated.connect(func() -> void: activation_count += 1)
	await settle()
	print("locale after main: %s; translation: %s; Label.text: %s" % [TranslationServer.get_locale(), TranslationServer.translate("LIGHTHOUSE_INTERACT"), prompt.text])
	# Independent expectation supplied by the test invocation, not the selection logic.
	var expected_locale := "en" if OS.get_cmdline_user_args().has("--expect-locale=en") else "es"
	check(TranslationServer.get_locale().begins_with(expected_locale), "Initial locale does not match selected language")
	var expected_text := "Press I to activate the lighthouse" if expected_locale == "en" else "Pulsa I para activar el faro"
	check(prompt.text == expected_text, "Initial Label text does not match selected language")
	check("es" in TranslationServer.get_loaded_locales() and "en" in TranslationServer.get_loaded_locales(), "Native catalogs not registered")
	check(lighthouse.state == lighthouse.State.OFF, "Lighthouse not initially off")
	check(not lighthouse.get_node("Light").visible, "Light initially on")
	check(is_equal_approx(lighthouse.interaction_radius, 2.0), "Unexpected default radius")
	player.position = lighthouse.position + Vector3(2.001, 0, 0)
	await settle()
	check(not lighthouse.is_player_in_range() and not prompt.visible, "Outside radius accepted")
	interact(true)
	await settle()
	check(lighthouse.state == lighthouse.State.OFF and activation_count == 0, "Outside press activated lighthouse")
	player.position = lighthouse.position + Vector3(2, 0, 0)
	await settle()
	check(lighthouse.is_player_in_range() and prompt.visible, "Exact radius should be inclusive")
	check(lighthouse.state == lighthouse.State.OFF, "Held key activated on entering")
	# A repeated pressed event without release is not a new press.
	interact(true)
	await settle()
	check(activation_count == 0, "Repeated held event activated lighthouse")
	interact(false)
	player.position = lighthouse.position + Vector3(1.999, 0, 0)
	await settle()
	check(lighthouse.is_player_in_range() and prompt.visible, "Inside radius rejected")
	lighthouse.interaction_radius = 1.0
	check(not lighthouse.is_player_in_range(), "Exported radius is not respected")
	lighthouse.interaction_radius = 2.0
	TranslationServer.set_locale("es")
	await settle()
	check(prompt.text == "Pulsa I para activar el faro", "Spanish translation incorrect")
	TranslationServer.set_locale("en")
	await settle()
	check(prompt.text == "Press I to activate the lighthouse", "English translation incorrect")
	check(prompt.visible, "Localized prompt is not visible in range")
	TranslationServer.set_locale("es")
	await settle()
	check(prompt.text == "Pulsa I para activar el faro" and prompt.visible, "Spanish restoration failed")
	print("runtime switch en/es and visible Label text: OK")
	# Position changes after prompt update must be rechecked at input time.
	player.position = lighthouse.position + Vector3(2.1, 0, 0)
	interact(true)
	await settle()
	check(activation_count == 0, "Stale prompt allowed outside interaction")
	interact(false)
	player.position = lighthouse.position + Vector3(1.5, 0, 0)
	await settle()
	# Keyboard autorepeat must not count as a fresh press.
	var echo_event := InputEventKey.new()
	echo_event.physical_keycode = KEY_I
	echo_event.pressed = true
	echo_event.echo = true
	Input.parse_input_event(echo_event)
	await settle()
	check(activation_count == 0, "Keyboard echo activated lighthouse")
	interact(true)
	await settle()
	check(lighthouse.state == lighthouse.State.ACTIVE and activation_count == 1, "Fresh in-range press did not activate exactly once")
	check(not prompt.visible and lighthouse.get_node("Light").visible, "Activation visuals/prompt incorrect")
	var material: StandardMaterial3D = lighthouse.get_node("Beacon").get_active_material(0)
	check(material.emission_enabled, "Active beacon is not emissive")
	for index in range(3):
		interact(false)
		interact(true)
		await settle()
	check(activation_count == 1 and not prompt.visible, "Activation or prompt repeated")
	interact(false)
	player.position = lighthouse.position + Vector3(4, 0, 0)
	await settle()
	player.position = lighthouse.position + Vector3(1.5, 0, 0)
	await settle()
	check(activation_count == 1 and lighthouse.state == lighthouse.State.ACTIVE and not prompt.visible, "Activation did not persist on leaving/reentering")
	# Test the real CharacterBody3D against the new solid tower.
	var camera: Camera3D = scene.get_node("Camera")
	camera.yaw = 0.0
	player.position = lighthouse.position + Vector3(-1.5, 0.01, 0)
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	await settle()
	Input.action_press("move_right")
	for index in range(30):
		await settle()
	Input.action_release("move_right")
	check(player.is_on_wall() and player.is_on_floor(), "Lighthouse did not block grounded player")
	check(player.position.x < lighthouse.position.x - 0.68, "Player penetrated the lighthouse")
	print("faro_interaccion: %d failures" % failures)
	quit(0 if failures == 0 else 1)
