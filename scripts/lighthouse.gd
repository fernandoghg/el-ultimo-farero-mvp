extends Node3D

signal activated

enum State { OFF, ACTIVE }

@export var player: Node3D
@export var interaction_radius: float = 2.0
@export var restoration: Node

var state: State = State.OFF
var _interact_held: bool = false
var _progress_remaining: float = 0.0
var _attempt_count: int = 0

@onready var prompt: Label = $InteractionUI/Prompt
@onready var beacon: MeshInstance3D = $Beacon
@onready var light: OmniLight3D = $Light


func _ready() -> void:
	_interact_held = Input.is_action_pressed("interact")
	_update_prompt()


func is_player_in_range() -> bool:
	return is_instance_valid(player) and global_position.distance_squared_to(player.global_position) <= interaction_radius * interaction_radius


func _physics_process(delta: float) -> void:
	_progress_remaining = maxf(0.0, _progress_remaining - delta)
	_update_prompt()


func _input(event: InputEvent) -> void:
	# Observe releases even when a UI control consumes the event later.
	if event.is_action_released("interact"):
		_interact_held = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or _interact_held:
		return
	_interact_held = true
	# Check the live position/state, never rely on the last displayed prompt.
	if state != State.OFF or not is_player_in_range():
		return
	var count := _restored_count()
	if count < 3:
		_attempt_count = count
		_progress_remaining = 2.0
		_update_prompt()
		get_viewport().set_input_as_handled()
		return
	_progress_remaining = 0.0
	state = State.ACTIVE
	light.visible = true
	var material := beacon.get_active_material(0).duplicate() as StandardMaterial3D
	material.albedo_color = Color(1.0, 0.85, 0.25)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.7, 0.15)
	beacon.material_override = material
	_update_prompt()
	activated.emit()
	get_viewport().set_input_as_handled()


func _restored_count() -> int:
	if not is_instance_valid(restoration) or not restoration.has_method("restored_count"):
		return 0
	return clampi(restoration.restored_count(), 0, 3)


func _update_prompt() -> void:
	prompt.visible = state == State.OFF and is_player_in_range()
	if _progress_remaining > 0.0:
		prompt.text = tr("LIGHTHOUSE_PROGRESS").format({"count": _attempt_count})
		return
	var events := InputMap.action_get_events("interact")
	var key_text := events[0].as_text() if not events.is_empty() else "I"
	# The binding is a physical key; remove engine-specific descriptive suffixes.
	if not events.is_empty() and events[0] is InputEventKey:
		key_text = OS.get_keycode_string((events[0] as InputEventKey).physical_keycode)
	prompt.text = tr("LIGHTHOUSE_INTERACT").format({"key": key_text})
