extends Node3D

# Discrete local circuit: central inlet -> rotating outlet -> fixed terminal.
# Rendering is a consumer of this connectivity, never its detector.
var powered: bool = false
var inlet_connected: bool = true
var terminal_links: Array[bool] = [true, true, true]
var outlet: int = -1
var target_terminal: int = -1
var _goal_was_lit: bool = false
var _goal_pulse_remaining: float = 0.0
const GOAL_PULSE_DURATION: float = 0.35

@onready var terminals: Array[Node3D] = [$Terminal0, $Terminal1, $Terminal2]


func set_target(index: int) -> void:
	target_terminal = index
	$Target.visible = index >= 0
	if index >= 0:
		$Target.position = terminals[index].position


func route(index: int, angle: float, supply: bool) -> void:
	outlet = index
	powered = supply
	$Path.rotation.z = angle
	_refresh_visuals()


func receiving_terminal() -> int:
	if not powered or not inlet_connected or outlet < 0 or not terminal_links[outlet]:
		return -1
	return outlet


func target_receives_energy() -> bool:
	return target_terminal >= 0 and receiving_terminal() == target_terminal


func set_inlet_connected(value: bool) -> void:
	inlet_connected = value
	_refresh_visuals()


func set_terminal_connected(index: int, value: bool) -> void:
	terminal_links[index] = value
	_refresh_visuals()


func _refresh_visuals() -> void:
	$Source/Live.visible = powered and inlet_connected
	$Path.visible = powered and inlet_connected
	for index in range(terminals.size()):
		terminals[index].get_node("Receiving").visible = receiving_terminal() == index
	# Presentation only: consume the existing logical receipt, never alter it.
	var lit := target_receives_energy()
	$Target/Crystal.material_override = $Source/Live.mesh.material if lit else null
	if lit and not _goal_was_lit:
		_goal_pulse_remaining = GOAL_PULSE_DURATION
	elif not lit:
		_goal_pulse_remaining = 0.0
		$Target/Pulse.visible = false
	_goal_was_lit = lit


func _process(delta: float) -> void:
	_goal_pulse_remaining = maxf(0.0, _goal_pulse_remaining - delta)
	$Target/Pulse.visible = _goal_pulse_remaining > 0.0
	var progress := 1.0 - _goal_pulse_remaining / GOAL_PULSE_DURATION
	$Target/Pulse.scale = Vector3.ONE * (1.0 + progress * 0.5)


func show_completion(progress: float) -> void:
	$Completion.visible = progress > 0.0 and progress < 1.0
	$Completion.scale = Vector3.ONE * (0.4 + progress * 1.5)
