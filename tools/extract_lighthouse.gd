extends SceneTree

# Explicit offline step after GLB import. Bundle mesh materials so gameplay does
# not depend on loading a PackedScene's internal subresources in a specific order.
func _initialize() -> void:
	var directory := "res://assets/lighthouse_tall" if "--tall" in OS.get_cmdline_user_args() else "res://assets/lighthouse"
	var source: PackedScene = load(directory + "/lighthouse.glb")
	if source == null:
		quit(1)
		return
	var model := source.instantiate()
	var count := 0
	for child in model.get_children():
		if child is MeshInstance3D and child.name in [&"TowerArt", &"LensArt"]:
			var mesh: ArrayMesh = child.mesh.duplicate(true)
			for surface in range(mesh.get_surface_count()):
				if mesh.surface_get_material(surface) == null:
					push_error("Missing GLB material: " + child.name)
					quit(1)
					return
			var target := "%s/%s.tres" % [directory, child.name]
			if ResourceSaver.save(mesh, target, ResourceSaver.FLAG_BUNDLE_RESOURCES) != OK:
				quit(1)
				return
			print("EXTRACTED ", child.name, " surfaces=", mesh.get_surface_count(), " bounds=", mesh.get_aabb())
			count += 1
	model.free()
	quit(0 if count == 2 else 1)
