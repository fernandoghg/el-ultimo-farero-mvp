extends Node3D

signal resolved

const Geometry = preload("res://scripts/light_geometry.gd")

@export var player: CharacterBody3D
@export var interaction_radius: float = 1.25
@export var beam_length: float = 4.0

var orientation: int = 0
var solved: bool = false
var path: Dictionary = {}
var _interact_held: bool = false
var _pending_turn: bool = false
var _confirmation_remaining: float = 0.0

@onready var prompt: Label = $UI/Prompt
@onready var clue: Label = $UI/Clue


func _ready() -> void:
	_interact_held = Input.is_action_pressed("interact")
	_update_orientation()
	_update_prompt()


func in_range() -> bool:
	return player.global_position.distance_to($Reflector.global_position) <= interaction_radius


func _input(event: InputEvent) -> void:
	if event.is_action_released("interact"):
		_interact_held = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or _interact_held:
		return
	_interact_held = true
	if player.controls_suspended or &"interact" in player.blocked_actions or not in_range():
		return
	get_viewport().set_input_as_handled()
	if not solved:
		_pending_turn = true


func rotate_once() -> void:
	if solved:
		return
	orientation = (orientation + 1) % 2
	_update_orientation()


func _update_orientation() -> void:
	# Plate normal is +X: -45 degrees sends +X towards -Z; +45 towards +Z.
	$Reflector/Pivot.rotation.y = -PI / 4.0 + orientation * PI / 2.0


func _physics_process(delta: float) -> void:
	if _pending_turn and not player.controls_suspended and &"interact" not in player.blocked_actions and in_range():
		rotate_once()
	_pending_turn = false
	if not solved:
		path = trace_beam()
		_draw_path()
		if path.receiver_hit:
			solved = true
			_confirmation_remaining = 0.8
			$Receiver/Crystal.material_override = $Source/Crystal.mesh.material
			resolved.emit()
	_confirmation_remaining = maxf(0.0, _confirmation_remaining - delta)
	$Receiver/Pulse.visible = _confirmation_remaining > 0.0
	$Receiver/Pulse.scale = Vector3.ONE * (1.0 + (1.0 - _confirmation_remaining / 0.8) * 0.6)
	_update_prompt()


func trace_beam() -> Dictionary:
	# Two finite queries, one mirror only. The avatar is not an optical obstacle.
	var source: Vector3 = $Source/Crystal.global_position
	var direction: Vector3 = $Source.global_basis.x.normalized()
	var excluded: Array[RID] = [player.get_rid(), $Source/Body.get_rid()]
	var first := _ray(source, source + direction * beam_length, excluded)
	var end: Vector3 = first.get("position", source + direction * beam_length)
	var result := {"incoming_start": source, "incoming_end": end, "reflected": false, "receiver_hit": false}
	if first.is_empty() or first.collider != $Reflector/Body:
		return result
	var reflection := Geometry.reflect($Reflector/Pivot, source, direction, beam_length)
	if reflection.is_empty():
		return result
	var contact: Vector3 = reflection.contact
	var reflected: Vector3 = reflection.direction
	excluded.append($Reflector/Body.get_rid())
	var second := _ray(contact + reflected * 0.02, contact + reflected * beam_length, excluded)
	result.incoming_end = contact
	result.reflected = true
	result.outgoing_start = contact
	result.outgoing_end = second.get("position", contact + reflected * beam_length)
	# Receiver has a fixed sensitive face towards -Z, independent of its material.
	if not second.is_empty() and second.collider == $Receiver/Body:
		var face: Vector3 = -$Receiver.global_basis.z.normalized()
		result.receiver_hit = reflected.dot(face) < -0.99 and (second.normal as Vector3).dot(face) > 0.99
	return result


func _ray(start: Vector3, end: Vector3, excluded: Array[RID]) -> Dictionary:
	return Geometry.ray(self, start, end, excluded)


func _draw_path() -> void:
	_segment($Beam/Incoming, path.incoming_start, path.incoming_end)
	$Beam/Outgoing.visible = path.reflected
	if path.reflected:
		_segment($Beam/Outgoing, path.outgoing_start, path.outgoing_end)
	$Beam/Impact.global_position = path.outgoing_end if path.reflected else path.incoming_end


func _segment(mesh: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	Geometry.segment(mesh, start, end)


func _update_prompt() -> void:
	prompt.visible = in_range() and not player.controls_suspended
	clue.visible = prompt.visible and not solved
	clue.text = tr("LOST_LIGHT_GUIDE")
	if not solved:
		prompt.text = tr("LOST_LIGHT_INTERACT")
	elif _confirmation_remaining > 0.0:
		prompt.text = tr("LOST_LIGHT_COMPLETE")
	else:
		prompt.text = tr("LOST_LIGHT_STABILIZED")
