extends Node3D

signal circuit_completed

enum Mode { EXPLORING, ENTERING, INSPECTING, CONFIRMING }

const ACTIONS: Array[StringName] = [&"interact", &"pause", &"move_left", &"move_right", &"move_forward", &"move_back", &"camera_left", &"camera_right"]

@export var player: CharacterBody3D
@export var normal_camera: Camera3D
@export var interaction_radius: float = 1.6
@export var turn_duration: float = 0.15
@export var confirmation_duration: float = 0.9
@export var supply_available: bool = true:
	set(value):
		# Completion is latched for the session, like the future upstream puzzles.
		if solved:
			return
		supply_available = value
		if is_node_ready():
			_update_supply()

var mode: Mode = Mode.EXPLORING
var selected: int = 0
var solved: bool = false
var _confirmation_remaining: float = 0.0
var turning: bool:
	get:
		return pairs.any(func(pair: Node): return pair.turning)

var _held: Dictionary = {}
var _blocked: Array[StringName] = []
var _pending_interact: bool = false
var _pending_exit: bool = false
var _pending_left: bool = false
var _pending_right: bool = false

@onready var pairs: Array[Node] = [$Pairs/Ring, $Pairs/Bars, $Pairs/Dots]
@onready var inspection_camera: Camera3D = $InspectionCamera
@onready var prompt: Label = $UI/Prompt
@onready var clue: Label = $UI/Clue


func _ready() -> void:
	process_physics_priority = -20
	for action in ACTIONS:
		_held[action] = Input.is_action_pressed(action)
	inspection_camera.look_at(to_global(Vector3(-2, 3.2, 0)))
	for pair in pairs:
		pair.settled.connect(_evaluate_circuit)
	_update_supply()
	_update_selection()
	_update_prompt()


func in_range() -> bool:
	return player.global_position.distance_to($Pedestal.global_position) <= interaction_radius


func _input(event: InputEvent) -> void:
	for action in ACTIONS:
		if not event.is_action(action):
			continue
		var was_held: bool = _held.get(action, false)
		var pressed := event.is_action_pressed(action, true)
		var fresh := event.is_action_pressed(action) and not was_held
		_held[action] = pressed
		if event.is_action_released(action):
			_blocked.erase(action)
			_sync_blocks()
			return
		if action in _blocked:
			get_viewport().set_input_as_handled()
			return
		if mode != Mode.EXPLORING:
			get_viewport().set_input_as_handled()
			if fresh and action == &"pause":
				_pending_exit = true
			elif fresh and action == &"interact" and mode == Mode.INSPECTING and not turning and not solved:
				_pending_interact = true
			elif fresh and mode == Mode.INSPECTING and not turning and not solved:
				if action == &"move_left":
					_pending_left = true
				elif action == &"move_right":
					_pending_right = true
			return
		if action == &"interact" and in_range():
			get_viewport().set_input_as_handled()
			if fresh:
				_pending_interact = true
		return


func _physics_process(delta: float) -> void:
	if _pending_exit:
		_exit_inspection()
	elif mode == Mode.INSPECTING and not turning and not solved and (_pending_left or _pending_right):
		# Selection wins over I; A+D together performs neither operation.
		if _pending_left != _pending_right:
			selected = posmod(selected + (1 if _pending_right else -1), pairs.size())
			_update_selection()
	elif _pending_interact:
		if mode == Mode.EXPLORING and in_range():
			_enter_inspection()
		elif mode == Mode.INSPECTING and not turning and not solved:
			pairs[selected].rotate_once(turn_duration)
			_block_held()
	_pending_interact = false
	_pending_exit = false
	_pending_left = false
	_pending_right = false
	if mode == Mode.ENTERING and not normal_camera.is_turning():
		mode = Mode.CONFIRMING if _confirmation_remaining > 0.0 else Mode.INSPECTING
		inspection_camera.make_current()
	if _confirmation_remaining > 0.0:
		_confirmation_remaining = maxf(0.0, _confirmation_remaining - delta)
		var progress := 1.0 - _confirmation_remaining / confirmation_duration
		for pair in pairs:
			for support: Node3D in [pair.small, pair.large]:
				support.get_node("Circuit").show_completion(progress)
		if _confirmation_remaining == 0.0 and mode in [Mode.CONFIRMING, Mode.ENTERING]:
			_exit_inspection()
	_evaluate_circuit()
	_update_prompt()


func _block_held() -> void:
	for action in ACTIONS:
		if _held.get(action, false) or Input.is_action_pressed(action):
			if action not in _blocked:
				_blocked.append(action)
	_sync_blocks()


func _sync_blocks() -> void:
	player.blocked_actions.assign(_blocked)
	normal_camera.blocked_actions.assign(_blocked)


func _enter_inspection() -> void:
	mode = Mode.ENTERING
	player.controls_suspended = true
	normal_camera.controls_suspended = true
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	_block_held()


func _exit_inspection() -> void:
	if mode == Mode.EXPLORING:
		return
	mode = Mode.EXPLORING
	_block_held()
	player.controls_suspended = false
	normal_camera.controls_suspended = false
	normal_camera.make_current()


func _update_selection() -> void:
	for index in range(pairs.size()):
		pairs[index].set_selected(index == selected)


func _update_prompt() -> void:
	clue.visible = (mode != Mode.EXPLORING or in_range()) and not solved
	clue.text = tr("ROTOR_CLUE")
	prompt.visible = _confirmation_remaining > 0.0 or mode != Mode.EXPLORING or in_range()
	if _confirmation_remaining > 0.0:
		prompt.text = tr("ROTOR_COMPLETE")
	elif mode == Mode.EXPLORING:
		prompt.text = tr("ROTOR_INSPECT")
	else:
		prompt.text = tr("ROTOR_STABILIZED") if solved else tr("ROTOR_CONTROLS")


func _update_supply() -> void:
	for pair in pairs:
		pair.set_powered(supply_available)
	_evaluate_circuit()


func _evaluate_circuit() -> void:
	if solved or turning or not supply_available:
		return
	if not pairs.all(func(pair: Node): return pair.target_receives_energy()):
		return
	solved = true
	for pair in pairs:
		pair.stabilized = true
	confirmation_duration = maxf(confirmation_duration, 0.01)
	_confirmation_remaining = confirmation_duration
	if mode == Mode.INSPECTING:
		mode = Mode.CONFIRMING
		_block_held()
	elif mode == Mode.ENTERING:
		# Do not allow an entry waiting on Q/E to open after completion.
		_exit_inspection()
	circuit_completed.emit()
