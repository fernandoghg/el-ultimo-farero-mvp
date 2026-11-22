extends CharacterBody3D

@export var speed: float = 4.0
@export var camera: Camera3D

var controls_suspended: bool = false
var blocked_actions: Array[StringName] = []


func _strength(action: StringName) -> float:
	return 0.0 if controls_suspended or action in blocked_actions else Input.get_action_strength(action)


func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if controls_suspended:
		input_direction = Vector2.ZERO
	elif not blocked_actions.is_empty():
		input_direction = Vector2(_strength("move_right") - _strength("move_left"), _strength("move_back") - _strength("move_forward")).limit_length()
	var right := camera.global_basis.x
	var back := camera.global_basis.z
	right.y = 0.0
	back.y = 0.0
	var direction := right.normalized() * input_direction.x + back.normalized() * input_direction.y
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	move_and_slide()
