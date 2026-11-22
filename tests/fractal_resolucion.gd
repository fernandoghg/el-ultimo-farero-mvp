extends "res://tests/fractal_tres_rotores.gd"

const SOLUTION := [2, 0, 1]
var completions: Array[int] = [0]


func fixture(supplied: bool = false) -> Node3D:
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	prototype = scene.get_node("FractalRotor")
	prototype.supply_available = supplied
	prototype.confirmation_duration = 1.2
	prototype.circuit_completed.connect(func(): completions[0] += 1)
	root.add_child(scene)
	scene.get_node("Player").position = Vector3(-3, 0.01, 3)
	return scene


func discard(scene: Node3D) -> void:
	for key in prototype.ACTIONS:
		action(key, false)
	scene.queue_free()
	await frames(2)


func configure(target: Array) -> void:
	for i in range(3):
		var pair: Node = prototype.pairs[i]
		for attempt in range(3):
			if pair.state == target[i]:
				break
			pair.rotate_once(0.02)
			while pair.turning:
				await frames(1)
	check(states() == target, "Could not reach test configuration")


func assert_topology() -> void:
	for i in range(3):
		var pair: Node = prototype.pairs[i]
		var large: Node3D = pair.large.get_node("Circuit")
		var small: Node3D = pair.small.get_node("Circuit")
		check(pair.target_terminal == SOLUTION[i] and large.target_terminal == SOLUTION[i], "Wrong symbol/target mapping")
		check(small.target_terminal == -1 and not small.get_node("Target").visible, "Small model reveals target")
		check(large.get_node("Target").position.is_equal_approx(large.terminals[SOLUTION[i]].position), "Target is not attached to its fixed terminal")
		check(large.terminals.size() == 3 and small.terminals.size() == 3, "Wrong terminal count")
		check((large.get_node("Target/Crystal").material_override != null) == large.target_receives_energy(), "Crystal lighting differs from existing logical receipt")
		for circuit: Node3D in [small, large]:
			check(circuit.get_node("Path").get_child_count() == 1, "Energy path duplicated visually")
			var receiving: int = circuit.receiving_terminal()
			for terminal in range(3):
				check(circuit.terminals[terminal].get_node("Receiving").visible == (receiving == terminal), "Receipt indicator differs from logical route")
			check(circuit.get_node("Path").rotation.is_equal_approx(Vector3(0, 0, pair.angle)), "Route and rotor animation not synchronized")


func capture_resolution(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://build")
	check(root.get_texture().get_image().save_png("res://build/fractal-resolution-%s.png" % name) == OK, "Resolution capture failed")


func run() -> void:
	root.size = Vector2i(1280, 720)
	var valid: int = 0
	# Every tuple is evaluated in a fresh real scene, independent of the latch.
	for ring in range(3):
		for bars in range(3):
			for dots in range(3):
				completions[0] = 0
				var scene := fixture()
				await frames(2)
				var target := [ring, bars, dots]
				await configure(target)
				check(not prototype.solved and completions[0] == 0, "Unpowered circuit resolved")
				for pair in prototype.pairs:
					check(pair.large.get_node("Circuit").receiving_terminal() == -1, "Unpowered receiver active")
				prototype.supply_available = true
				await frames(2)
				var expected: bool = target == SOLUTION
				check(prototype.solved == expected, "Wrong validity for tuple %s" % [target])
				check(completions[0] == (1 if expected else 0), "Wrong completion signal count")
				assert_topology()
				verify_geometry()
				if prototype.solved:
					valid += 1
				check(scene.get_node("Lighthouse").state == 0, "Resolution activated lighthouse")
				configurations[str(target)] = true
				await discard(scene)
	check(valid == 1 and configurations.size() == 27, "Expected exactly one valid configuration among 27")
	# A logically interrupted terminal or inlet must defeat the correct tuple.
	for break_inlet in [false, true]:
		completions[0] = 0
		var scene := fixture()
		await frames(2)
		await configure(SOLUTION)
		var circuit: Node3D = prototype.pairs[0].large.get_node("Circuit")
		if break_inlet:
			circuit.set_inlet_connected(false)
		else:
			circuit.set_terminal_connected(2, false)
		prototype.supply_available = true
		await frames(3)
		check(not prototype.solved and completions[0] == 0, "Tuple comparison bypassed broken logical connection")
		# Mesh visibility is irrelevant to a restored logical circuit.
		circuit.visible = false
		if break_inlet:
			circuit.set_inlet_connected(true)
		else:
			circuit.set_terminal_connected(2, true)
		await frames(3)
		check(prototype.solved and completions[0] == 1, "Rendering visibility affected logical connectivity")
		await discard(scene)
	# Autonomous supply is enabled in the actual scene and is reversible pre-solve.
	completions[0] = 0
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	prototype = scene.get_node("FractalRotor")
	prototype.circuit_completed.connect(func(): completions[0] += 1)
	root.add_child(scene)
	var player: CharacterBody3D = scene.get_node("Player")
	var camera: Camera3D = scene.get_node("Camera")
	player.position = Vector3(-3, 0.01, 3)
	await frames(3)
	check(prototype.supply_available and not prototype.solved, "Autonomous supply/startup wrong")
	check(prototype.clue.visible, "Initial objective hint missing near pedestal")
	await tap(&"interact")
	var clue_english: bool = TranslationServer.get_locale().begins_with("en")
	check(prototype.clue.visible and prototype.clue.text == ("Guide the light to the marked crystals" if clue_english else "Conduce la luz hasta los cristales marcados"), "Initial clue not localized")
	check(prototype.clue.get_minimum_size().x < 1240 and prototype.prompt.get_minimum_size().x < 1240, "Instructions exceed 1280x720")
	await capture_resolution("initial")
	await tap(&"interact")
	while prototype.turning:
		await frames(1)
	await select(2)
	var saved := states()
	var saved_selection: int = prototype.selected
	await tap(&"pause")
	await tap(&"interact")
	check(states() == saved and prototype.selected == saved_selection, "Pre-solve reentry lost state/selection")
	await tap(&"pause")
	prototype.supply_available = false
	await configure([1, 0, 1])
	prototype.supply_available = true
	await tap(&"interact")
	await select(0)
	var fixed_targets: Array[Transform3D] = []
	for pair in prototype.pairs:
		fixed_targets.append(pair.large.get_node("Circuit/Target").global_transform)
	prototype.turn_duration = 0.5
	prototype.confirmation_duration = 0.9
	var saved_position := player.position
	var saved_yaw: float = camera.yaw
	action(&"interact", true)
	await frames(2)
	check(states() == SOLUTION and prototype.turning, "Test missed final moving orientation")
	check(not prototype.solved and completions[0] == 0, "Resolved during animation")
	check(prototype.pairs[0].large.get_node("Circuit").receiving_terminal() == -1, "Moving route received energy")
	check(prototype.pairs[0].large.get_node("Circuit/Target/Crystal").material_override == null, "Moving route falsely lit target crystal")
	while prototype.turning:
		assert_topology()
		verify_geometry()
		await frames(1)
	await frames(2)
	check(prototype.solved and completions[0] == 1, "Settled complete circuit did not resolve once")
	check(prototype.pairs[0].large.get_node("Circuit/Target/Pulse").visible, "Target receipt pulse missing")
	check(prototype.mode == prototype.Mode.CONFIRMING, "Missing completion confirmation")
	var english: bool = TranslationServer.get_locale().begins_with("en")
	check(prototype.prompt.text == ("Circuit complete · The Echo of Infinity is stabilizing" if english else "Circuito completo · El eco del infinito se estabiliza"), "Completion text not localized")
	for i in range(3):
		check(prototype.pairs[i].stabilized, "Piece not stabilized")
		check(prototype.pairs[i].large.get_node("Circuit/Target").global_transform.is_equal_approx(fixed_targets[i]), "Target moved with rotor")
	await frames(12)
	for pair in prototype.pairs:
		check(pair.large.get_node("Circuit/Completion").visible, "Completion pulse missing")
	await capture_resolution("complete")
	action(&"move_forward", true)
	action(&"camera_right", true)
	await tap(&"move_right")
	check(prototype.selected == 0, "Selection changed after completion")
	for pair in prototype.pairs:
		pair.rotate_once(0.02)
	check(states() == SOLUTION and not prototype.turning, "Direct turn bypassed stabilization")
	while prototype._confirmation_remaining > 0.0:
		await frames(1)
	await frames(10)
	check(prototype.mode == prototype.Mode.EXPLORING and camera.current, "Completion did not close inspection")
	check(player.position.distance_to(saved_position) < 0.01 and is_equal_approx(camera.yaw, saved_yaw), "Completion changed player/normal camera")
	check(not player.controls_suspended and not camera.controls_suspended, "Completion left controls suspended")
	for pair in prototype.pairs:
		check(not pair.large.get_node("Circuit/Target/Pulse").visible, "Target pulse repeated or did not end")
		check(pair.large.get_node("Circuit/Target/Crystal").material_override != null, "Completed crystal did not remain lit")
	action(&"move_forward", false)
	action(&"camera_right", false)
	check(scene.get_node("Lighthouse").state == 0, "Completion/held I activated lighthouse")
	prototype.supply_available = false
	check(prototype.supply_available, "Completed circuit was not latched")
	action(&"interact", false)
	await tap(&"interact")
	check(prototype.mode == prototype.Mode.INSPECTING and prototype.solved, "Solved structure cannot be inspected")
	check(prototype.prompt.text == ("Structure stabilized · Esc: return to the game" if english else "Estructura estabilizada · Esc: volver al juego"), "Stabilized text not localized")
	await tap(&"interact")
	await tap(&"move_left")
	check(states() == SOLUTION and prototype.selected == 0 and completions[0] == 1, "Solved inspection changed or emitted twice")
	await tap(&"pause")
	# P3 alone is now insufficient; preserve the manual contract once P1/P2 also finish.
	var activations: Array[int] = [0]
	scene.get_node("Lighthouse").activated.connect(func(): activations[0] += 1)
	player.position = scene.get_node("Lighthouse").position + Vector3(0, 0.01, 1.5)
	await frames(4)
	await tap(&"interact")
	check(scene.restored_count() == 1 and scene.get_node("Lighthouse").state == 0 and activations[0] == 0, "P3 alone activated lighthouse")
	check(scene.get_node("Bridge").state == 0, "P3 alone rebuilt bridge")
	await preload("res://tests/circuit_fixture.gd").solve(scene, &"P1")
	await preload("res://tests/circuit_fixture.gd").solve(scene, &"P2")
	await tap(&"interact")
	check(scene.get_node("Lighthouse").state == 1 and activations[0] == 1, "New manual press no longer activates lighthouse")
	for frame in range(150):
		if scene.get_node("Bridge").state == 2:
			break
		await frames(1)
	check(scene.get_node("Bridge").state == 2, "Existing bridge reconstruction failed after puzzle")
	check(completions[0] == 1, "Lighthouse emitted puzzle completion again")
	await discard(scene)
	# Resolve outside inspection: no forced camera entry or second exit.
	completions[0] = 0
	scene = fixture()
	await frames(2)
	await configure([1, 0, 1])
	prototype.supply_available = true
	await tap(&"interact")
	prototype.turn_duration = 0.5
	action(&"interact", true)
	await frames(2)
	await tap(&"pause")
	while prototype.turning:
		await frames(1)
	check(prototype.solved and prototype.mode == prototype.Mode.EXPLORING and completions[0] == 1, "Outside completion changed context")
	while prototype._confirmation_remaining > 0.0:
		await frames(1)
	check(scene.get_node("Camera").current and not scene.get_node("Player").controls_suspended, "Outside completion stole camera/controls")
	await discard(scene)
	# Esc may dismiss confirmation immediately; it must not cause a delayed close.
	completions[0] = 0
	scene = fixture()
	await frames(2)
	await configure(SOLUTION)
	await tap(&"interact")
	prototype.supply_available = true
	await frames(2)
	await tap(&"pause")
	check(prototype.mode == prototype.Mode.EXPLORING, "Esc did not exit confirmation")
	while prototype._confirmation_remaining > 0.0:
		await frames(1)
	await tap(&"interact")
	check(prototype.mode == prototype.Mode.INSPECTING and completions[0] == 1, "Confirmation left a delayed transition")
	await discard(scene)
	# Completion while entry is waiting for Q/E cancels only the pending inspection.
	completions[0] = 0
	scene = fixture()
	await frames(2)
	await configure(SOLUTION)
	scene.get_node("Camera").request_turn(1.0)
	await tap(&"interact")
	check(prototype.mode == prototype.Mode.ENTERING, "Test did not enter camera wait")
	prototype.supply_available = true
	await frames(40)
	check(prototype.mode == prototype.Mode.EXPLORING and scene.get_node("Camera").current and completions[0] == 1, "Completion during camera wait caused late inspection")
	await discard(scene)
	print("fractal_resolucion: %d configurations, %d valid, %d failures" % [configurations.size(), valid, failures])
	quit(0 if failures == 0 else 1)
