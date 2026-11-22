extends Node3D
## Presentation only: the optical pivot remains the sole orientation authority.

@export var logical_pivot: Node3D
const TURN_DURATION: float = 0.35
var _last_target: float
var _initialized: bool = false
var _turn: Tween
@onready var assembly: Node3D = $Model.find_child("RotatingAssembly", true, false)


func _ready() -> void:
	# The puzzle initializes its pivot after its children are ready.
	call_deferred("_initialize_pose")


func _initialize_pose() -> void:
	if logical_pivot == null:
		return
	_last_target = logical_pivot.rotation.y
	assembly.rotation.y = _last_target
	_initialized = true


func _process(_delta: float) -> void:
	if not _initialized or not is_instance_valid(logical_pivot):
		return
	var target: float = logical_pivot.rotation.y
	if is_equal_approx(target, _last_target):
		return
	_last_target = target
	if _turn != null:
		_turn.kill()
	# Retarget from the current visual angle; never write back to gameplay.
	_turn = create_tween()
	_turn.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_turn.tween_property(assembly, "rotation:y", target, TURN_DURATION)
