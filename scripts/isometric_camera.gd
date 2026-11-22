extends Camera3D

@export var target: Node3D
@export var follow_speed: float = 8.0
@export var turn_duration: float = 0.45

var yaw: float = deg_to_rad(45.0)
var _focus: Vector3
var _turn: Tween
var controls_suspended: bool = false
var blocked_actions: Array[StringName] = []
const ORBIT_DISTANCE: float = 14.142136
const FOLLOW_SETTLE_DISTANCE: float = 0.0025


func _ready() -> void:
	# Update before the player so movement uses the same orientation shown by the camera.
	process_physics_priority = -10
	_focus = target.global_position
	_update_transform()


func _unhandled_input(event: InputEvent) -> void:
	if controls_suspended:
		return
	if event.is_action_pressed("camera_left") and &"camera_left" not in blocked_actions:
		request_turn(1.0)
	elif event.is_action_pressed("camera_right") and &"camera_right" not in blocked_actions:
		request_turn(-1.0)


func request_turn(direction: float) -> void:
	# No queue: ignore repeated presses during the short transition.
	if controls_suspended or is_turning():
		return
	_turn = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_turn.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_turn.tween_property(self, "yaw", yaw + direction * PI / 2.0, turn_duration)


func is_turning() -> bool:
	return _turn != null and _turn.is_running()


func _physics_process(delta: float) -> void:
	_focus = _focus.lerp(target.global_position, 1.0 - exp(-follow_speed * delta))
	# Finish the subpixel translation tail without changing orbital turns.
	if _focus.distance_squared_to(target.global_position) < FOLLOW_SETTLE_DISTANCE * FOLLOW_SETTLE_DISTANCE:
		_focus = target.global_position
	_update_transform()


func _update_transform() -> void:
	rotation = Vector3(deg_to_rad(-35.264), yaw, 0.0)
	global_position = _focus + Vector3(sin(yaw) * ORBIT_DISTANCE, 10.0, cos(yaw) * ORBIT_DISTANCE)
