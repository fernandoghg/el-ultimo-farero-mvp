extends RefCounted

# Tests prepare real circuits through their existing logic, never a gameplay bypass.
static func solve(scene: Node3D, id: StringName) -> void:
	var tree := scene.get_tree()
	if id == &"P1":
		var puzzle: Node3D = scene.get_node("LostLight")
		if not puzzle.solved:
			puzzle.rotate_once()
	elif id == &"P2":
		var puzzle: Node3D = scene.get_node("GuardianMirrors")
		if not puzzle.solved:
			for index in range(2):
				if puzzle.states[index] != 1:
					puzzle.rotate_once(index)
	elif id == &"P3":
		var puzzle: Node3D = scene.get_node("FractalRotor")
		if not puzzle.solved:
			var target := [2, 0, 1]
			for index in range(3):
				var pair: Node = puzzle.pairs[index]
				while pair.state != target[index]:
					pair.rotate_once(0.02)
					while pair.turning:
						await tree.physics_frame
						await tree.process_frame
	for frame in range(3):
		await tree.physics_frame
		await tree.process_frame


static func all(scene: Node3D) -> void:
	for id: StringName in [&"P1", &"P2", &"P3"]:
		await solve(scene, id)
