extends Node3D

signal resolved

const Geometry = preload("res://scripts/light_geometry.gd")

@export var player: CharacterBody3D
@export var interaction_radius: float = 1.0
@export var beam_length: float = 6.0

var states: Array[int] = [0, 0]
var solved: bool = false
var path: Dictionary = {}
var _held: bool = false
var _pending: int = -1
var _confirmation: float = 0.0
var _inlet_pulse: float = 0.0
var _receiving: bool = false

@onready var mirrors: Array[Node3D] = [$Reflector, $Reflector2]
@onready var prompt: Label = $UI/Prompt
@onready var clue: Label = $UI/Clue


func _ready() -> void:
	_held = Input.is_action_pressed("interact")
	for index in range(2):
		_update_orientation(index)
	_update_prompt()


func nearby_mirror() -> int:
	var nearest := -1
	var distance := interaction_radius
	for index in range(2):
		var candidate := player.global_position.distance_to(mirrors[index].global_position)
		if candidate <= distance:
			nearest = index
			distance = candidate
	return nearest


func _input(event: InputEvent) -> void:
	if event.is_action_released("interact"):
		_held = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or _held:
		return
	_held = true
	if player.controls_suspended or &"interact" in player.blocked_actions:
		return
	var index := nearby_mirror()
	if index == -1:
		return
	# This puzzle's ranges do not overlap the other puzzles. Let their controllers observe this press
	# too, so their held-I guards survive walking from this puzzle to another.
	# Fractal inspection already consumes input before this callback.
	if not solved:
		_pending = index


func rotate_once(index: int) -> void:
	if solved or index < 0 or index >= 2:
		return
	states[index] = (states[index] + 1) % 2
	_update_orientation(index)


func _update_orientation(index: int) -> void:
	mirrors[index].get_node("Pivot").rotation.y = -PI / 4.0 + states[index] * PI / 2.0


func _physics_process(delta: float) -> void:
	if _pending != -1 and nearby_mirror() == _pending and not player.controls_suspended and &"interact" not in player.blocked_actions:
		rotate_once(_pending)
	_pending = -1
	if not solved:
		path = trace_beam()
		_draw_path()
		if path.receiver_hit:
			solved = true
			_confirmation = 0.8
			$Receiver/Crystal.material_override = $Source/Crystal.mesh.material
			resolved.emit()
	var receiving: bool = path.reflections == 2
	if receiving and not _receiving:
		_inlet_pulse = 0.3
	_receiving = receiving
	_inlet_pulse = maxf(0.0, _inlet_pulse - delta)
	$Reflector2/Inlet.visible = receiving
	$Reflector2/Inlet.scale = Vector3.ONE * (0.3 + _inlet_pulse)
	_confirmation = maxf(0.0, _confirmation - delta)
	$Receiver/Pulse.visible = _confirmation > 0.0
	$Receiver/Pulse.scale = Vector3.ONE * (1.0 + (1.0 - _confirmation / 0.8) * 0.6)
	_update_prompt()


func trace_beam() -> Dictionary:
	# Exactly three finite legs and the ordered pair of mirrors, never a bounce graph.
	var result := {"segments": [], "reflections": 0, "receiver_hit": false}
	var start: Vector3 = $Source/Crystal.global_position
	var direction: Vector3 = $Source.global_basis.x.normalized()
	var excluded: Array[RID] = [player.get_rid(), $Source/Body.get_rid()]
	for leg in range(3):
		var query_start := start if leg == 0 else start + direction * 0.02
		var hit := Geometry.ray(self, query_start, start + direction * beam_length, excluded)
		var end: Vector3 = hit.get("position", start + direction * beam_length)
		var segment := {"start": start, "end": end}
		result.segments.append(segment)
		if hit.is_empty():
			break
		if leg == 2:
			if hit.collider == $Receiver/Body:
				var face: Vector3 = -$Receiver.global_basis.z.normalized()
				result.receiver_hit = direction.dot(face) < -0.99 and (hit.normal as Vector3).dot(face) > 0.99
			break
		var mirror: Node3D = mirrors[leg]
		if hit.collider != mirror.get_node("Body"):
			break
		var reflection := Geometry.reflect(mirror.get_node("Pivot"), start, direction, beam_length)
		if reflection.is_empty():
			break
		segment.end = reflection.contact
		start = reflection.contact
		direction = reflection.direction
		excluded.append(mirror.get_node("Body").get_rid())
		result.reflections += 1
	return result


func _draw_path() -> void:
	for index in range(3):
		var mesh: MeshInstance3D = $Beam.get_child(index)
		mesh.visible = index < path.segments.size()
		if mesh.visible:
			Geometry.segment(mesh, path.segments[index].start, path.segments[index].end)
	$Beam/Impact.global_position = path.segments.back().end


func _update_prompt() -> void:
	var index := nearby_mirror()
	prompt.visible = index != -1 and not player.controls_suspended
	clue.visible = prompt.visible and not solved
	clue.text = tr("GUARDIAN_GUIDE")
	if solved:
		prompt.text = tr("GUARDIAN_COMPLETE" if _confirmation > 0.0 else "GUARDIAN_STABILIZED")
	else:
		prompt.text = tr("GUARDIAN_FIRST" if index == 0 else "GUARDIAN_SECOND")
