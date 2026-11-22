extends Node

signal settled

const STEP: float = TAU / 3.0

@export var small: Node3D
@export var large: Node3D
@export_range(0, 2) var target_terminal: int = 0
var state: int = 0
var turning: bool = false
var stabilized: bool = false
var powered: bool = false
var angle: float = 0.0:
	set(value):
		angle = value
		small.get_node("Rotor").rotation.z = value
		large.get_node("Rotor").rotation.z = value
		_refresh_circuits()


func _ready() -> void:
	large.get_node("Circuit").set_target(target_terminal)
	_refresh_circuits()


func set_powered(value: bool) -> void:
	powered = value
	_refresh_circuits()


func _refresh_circuits() -> void:
	var terminal := -1 if turning else state
	for support: Node3D in [small, large]:
		support.get_node("Circuit").route(terminal, angle, powered)


func target_receives_energy() -> bool:
	return not turning and large.get_node("Circuit").target_receives_energy()


func rotate_once(duration: float) -> void:
	if turning or stabilized:
		return
	turning = true
	state = (state + 1) % 3
	_refresh_circuits()
	var turn := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	turn.tween_property(self, "angle", angle + STEP, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	turn.tween_callback(_finish_turn)


func _finish_turn() -> void:
	# Normalize so three turns restore the exact local transform.
	angle = state * STEP
	turning = false
	_refresh_circuits()
	settled.emit()


func set_selected(value: bool) -> void:
	small.get_node("Selection").visible = value
	large.get_node("Selection").visible = value
