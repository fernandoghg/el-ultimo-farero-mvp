extends "res://tests/fractal_un_rotor.gd"

var prototype: Node3D
var configurations: Dictionary = {}
var safe_area := Rect2(20, 20, 1240, 580)


func states() -> Array[int]:
	var result: Array[int] = []
	for pair in prototype.pairs:
		result.append(pair.state)
	return result


func mesh_bounds(camera: Camera3D, node: Node3D) -> Rect2:
	var rect := Rect2(camera.unproject_position(node.global_position), Vector2.ZERO)
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if not mesh.is_visible_in_tree():
			continue
		for corner in range(8):
			var point := mesh.to_global(mesh.get_aabb().get_endpoint(corner))
			check(not camera.is_position_behind(point), "Geometry behind camera")
			rect = rect.expand(camera.unproject_position(point))
	return rect


func verify_geometry() -> void:
	var camera: Camera3D = prototype.inspection_camera
	for pair in prototype.pairs:
		var small: Node3D = pair.small.get_node("Rotor")
		var large: Node3D = pair.large.get_node("Rotor")
		correspondence(small, large)
		if not pair.turning:
			var expected := Basis(Vector3(0, 0, 1), pair.state * TAU / 3.0)
			check(small.basis.is_equal_approx(expected) and large.basis.is_equal_approx(expected), "Visual orientation disagrees with independent state")
		var small_rect := mesh_bounds(camera, pair.small)
		var large_rect := mesh_bounds(camera, pair.large)
		check(safe_area.encloses(small_rect) and safe_area.encloses(large_rect), "Support/symbol/selection cropped or under UI")
		check(small_rect.size.x >= 55 and large_rect.size.x >= 100, "Module too small")
		for other in prototype.pairs:
			check(not small_rect.intersects(mesh_bounds(camera, other.large)), "Scales overlap in inspection")
	check(safe_area.encloses(mesh_bounds(camera, prototype.get_node("Monument"))), "Monument cropped")


func verify_selection(index: int) -> void:
	check(prototype.selected == index, "Wrong selected rotor")
	for i in range(3):
		var pair: Node = prototype.pairs[i]
		check(pair.small.get_node("Selection").visible == (i == index), "Small selection unclear")
		check(pair.large.get_node("Selection").visible == (i == index), "Large selection unclear")


func select(index: int) -> void:
	for attempt in range(3):
		if prototype.selected == index:
			break
		await tap(&"move_right")
	verify_selection(index)


func turn_selected() -> void:
	var before := states()
	var selected: int = prototype.selected
	var pair: Node = prototype.pairs[selected]
	var initial_angle: float = pair.angle
	var small_symbol: Transform3D = pair.small.get_node("Symbol").global_transform
	var large_symbol: Transform3D = pair.large.get_node("Symbol").global_transform
	action(&"interact", true)
	await frames(1)
	check(absf(pair.angle - initial_angle) > 0.001, "Turn did not react immediately")
	# Selection and repeated rotation during an accepted turn are discarded.
	if pair.turning:
		action(&"move_left", true)
	action(&"interact", true)
	while pair.turning:
		await frames(1)
		verify_geometry()
	check(not pair.turning, "Turn did not settle")
	check(pair.small.get_node("Symbol").global_transform.is_equal_approx(small_symbol), "Small identity rotated")
	check(pair.large.get_node("Symbol").global_transform.is_equal_approx(large_symbol), "Large identity rotated")
	check(prototype.selected == selected, "Selection changed during turn")
	for i in range(3):
		check(prototype.pairs[i].state == ((before[i] + 1) % 3 if i == selected else before[i]), "Rotor independence/cycle failed")
	await frames(3)
	check(pair.state == (before[selected] + 1) % 3, "Held press repeated after turn")
	action(&"interact", false)
	action(&"move_left", false)
	await frames(2)


func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://build")
	check(root.get_texture().get_image().save_png("res://build/three-rotors-%s.png" % name) == OK, "Capture failed")


func run() -> void:
	root.size = Vector2i(1280, 720)
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	# Isolate the reversible mechanism from the 4.3 completion latch.
	# The autonomous live-supply/solution contract has its own resolution suite.
	scene.get_node("FractalRotor").supply_available = false
	root.add_child(scene)
	prototype = scene.get_node("FractalRotor")
	var player: CharacterBody3D = scene.get_node("Player")
	var camera: Camera3D = scene.get_node("Camera")
	player.position = Vector3(-3, 0.01, 3)
	await frames(4)
	await tap(&"interact")
	check(prototype.mode == prototype.Mode.INSPECTING, "Entry failed")
	check(states() == [0, 0, 0], "Unexpected starting states")
	verify_selection(0)
	# Physical map is transported with the complete small support, not just angles.
	var small_root: Node3D = prototype.get_node("SmallSupport")
	var names := ["Ring", "Bars", "Dots"]
	var symbols := ["ring", "bars", "dots"]
	for i in range(3):
		var pair: Node = prototype.pairs[i]
		check(pair.name == names[i] and pair.small.name == names[i] and pair.large.name == names[i], "Wrong explicit pairing")
		var expected: Vector3 = Basis(Vector3(0, 0, 1), TAU / 3.0) * pair.large.position
		var actual: Vector3 = (pair.small.global_position - small_root.global_position) / small_root.scale.x
		check(actual.is_equal_approx(expected), "Module centers not physically transported by 120 degrees")
		check(pair.small.position.is_equal_approx(pair.large.position), "Local pair centers differ")
		for support: Node3D in [pair.small, pair.large]:
			check(support.get_node("Symbol/Identity").scene_file_path == "res://scenes/fractal_symbol_%s.tscn" % symbols[i], "Identity mismatch")
			var rotor: Node3D = support.get_node("Rotor")
			check(rotor.scene_file_path == "res://scenes/fractal_rotor_visual.tscn", "Rotors must share the same mechanism")
			var grip := rotor.get_node_or_null("IndexGrip") as MeshInstance3D
			check(grip != null and grip.mesh != null, "Missing orientation grip")
			if grip != null:
				for terminal in range(3):
					var circuit_terminal: Node3D = support.get_node("Circuit/Terminal%d" % terminal)
					var direction := Basis(Vector3.BACK, terminal * TAU / 3.0) * grip.position.normalized()
					check(direction.is_equal_approx(circuit_terminal.position.normalized()), "Grip does not point to the circuit terminal")
	check(prototype.pairs[0].large.position.x > 0 and prototype.pairs[1].large.position.x < 0 and prototype.pairs[2].large.position.y > 0, "Ring/right bars/left dots/crown map failed")
	verify_geometry()
	await capture("initial")
	var inspection_position := player.position
	var inspection_yaw: float = camera.yaw
	for key in [&"move_forward", &"move_back", &"camera_left", &"camera_right"]:
		await tap(key)
	check(player.position.distance_to(inspection_position) < 0.01, "W/S moved player in inspection")
	check(is_equal_approx(camera.yaw, inspection_yaw), "Q/E changed normal camera during inspection")
	# Both cyclic directions, held/repeated selection, and event priority.
	await tap(&"move_left")
	verify_selection(2)
	action(&"move_right", true)
	await frames(2)
	verify_selection(0)
	action(&"move_right", true)
	await frames(15)
	verify_selection(0)
	action(&"move_right", false)
	for index in [1, 2, 0]:
		await tap(&"move_right")
		verify_selection(index)
	action(&"interact", true)
	action(&"move_right", true)
	await frames(2)
	verify_selection(1)
	check(states() == [0, 0, 0], "Selection+I rotated a piece")
	action(&"interact", false)
	action(&"move_right", false)
	action(&"move_left", true)
	action(&"move_right", true)
	action(&"interact", true)
	await frames(3)
	verify_selection(1)
	check(states() == [0, 0, 0], "A+D+I performed an operation")
	for key in [&"move_left", &"move_right", &"interact"]:
		action(key, false)
	# Exhaustively reach all 27 tuples through actual input; no solution/enclaving.
	for ring in range(3):
		for bars in range(3):
			for dots in range(3):
				var target := [ring, bars, dots]
				for i in range(3):
					await select(i)
					for attempt in range(3):
						if prototype.pairs[i].state == target[i]:
							break
						await turn_selected()
				check(states() == target, "Tuple unreachable")
				configurations[str(states())] = true
				verify_geometry()
				check(scene.get_node("Lighthouse").state == 0, "Tuple activated lighthouse")
				check(prototype.mode == prototype.Mode.INSPECTING, "Tuple closed inspection")
	check(configurations.size() == 27, "Not all 27 configurations were checked")
	check(player.position.distance_to(inspection_position) < 0.01, "A/D selection moved player")
	# Every piece returns exactly after three turns, others stay unchanged.
	for i in range(3):
		await select(i)
		var before := states()
		var small_before: Transform3D = prototype.pairs[i].small.get_node("Rotor").transform
		var large_before: Transform3D = prototype.pairs[i].large.get_node("Rotor").transform
		for step in range(3):
			await turn_selected()
		check(states() == before, "Full cycle changed states")
		check(prototype.pairs[i].small.get_node("Rotor").transform.is_equal_approx(small_before), "Small cycle drift")
		check(prototype.pairs[i].large.get_node("Rotor").transform.is_equal_approx(large_before), "Large cycle drift")
		await capture("selected-%d" % i)
	# Held selection must not become movement on exit; preserve all states/selection.
	var saved := states()
	var saved_position := player.position
	var saved_yaw: float = camera.yaw
	action(&"move_left", true)
	await frames(2)
	var saved_selection: int = prototype.selected
	await tap(&"pause")
	await frames(15)
	check(player.position.distance_to(saved_position) < 0.01, "Held selection became movement")
	check(is_equal_approx(camera.yaw, saved_yaw), "Normal yaw changed")
	action(&"move_left", false)
	await tap(&"interact")
	check(states() == saved and prototype.selected == saved_selection, "Reentry lost session state")
	# Reopen while a turn is still busy, without cancelling, duplicating or queuing.
	prototype.turn_duration = 1.2
	var current: int = prototype.selected
	var destination: int = (prototype.pairs[current].state + 1) % 3
	action(&"interact", true)
	await frames(2)
	await tap(&"pause")
	action(&"interact", false)
	await tap(&"interact")
	check(prototype.turning, "Busy-reentry test missed active turn")
	action(&"move_right", true)
	action(&"interact", true)
	while prototype.turning:
		await frames(1)
	await frames(3)
	check(prototype.selected == current and prototype.pairs[current].state == destination and not prototype.turning, "Busy reentry queued or duplicated input")
	action(&"move_right", false)
	action(&"interact", false)
	await tap(&"pause")
	await capture("normal")
	print("fractal_tres_rotores: %d configurations, %d failures" % [configurations.size(), failures])
	quit(0 if failures == 0 else 1)
