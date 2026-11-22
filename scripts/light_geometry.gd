extends RefCounted

# Shared arithmetic only: puzzle controllers own their routes, state and completion.
static func ray(owner: Node3D, start: Vector3, end: Vector3, excluded: Array[RID]) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start, end, 1, excluded)
	return owner.get_world_3d().direct_space_state.intersect_ray(query)


static func reflect(pivot: Node3D, start: Vector3, direction: Vector3, length: float) -> Dictionary:
	var normal := pivot.global_basis.x.normalized()
	var denominator := direction.dot(normal)
	if absf(denominator) < 0.0001:
		return {}
	var distance := (pivot.global_position - start).dot(normal) / denominator
	if distance <= 0.0 or distance > length:
		return {}
	var contact := start + direction * distance
	var local := pivot.to_local(contact)
	# The conservative stand collider is not itself reflective.
	if absf(local.y) > 0.4 or absf(local.z) > 0.475:
		return {}
	return {"contact": contact, "direction": (direction - 2.0 * direction.dot(normal) * normal).normalized()}


static func segment(mesh: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var difference := end - start
	mesh.global_position = (start + end) * 0.5
	mesh.rotation.y = -atan2(difference.z, difference.x)
	mesh.scale.x = difference.length()
