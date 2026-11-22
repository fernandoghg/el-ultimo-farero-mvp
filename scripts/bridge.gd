extends Node3D

signal reconstructed

enum State { DESTROYED, REBUILDING, READY }

@export_range(0.1, 10.0, 0.1) var reconstruction_duration: float = 1.5

var state: State = State.DESTROYED

@onready var deck_collision: CollisionShape3D = $Deck/CollisionShape3D
@onready var entrance_collision: CollisionShape3D = $Gates/Entrance/CollisionShape3D
@onready var exit_collision: CollisionShape3D = $Gates/Exit/CollisionShape3D


func reconstruct() -> void:
	if state != State.DESTROYED:
		return
	state = State.REBUILDING
	var segments := $Segments.get_children()
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for segment: Node3D in segments:
		tween.tween_property(segment, "position:y", -0.2, maxf(reconstruction_duration, 0.1) / segments.size()).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_enable_deck)


func _enable_deck() -> void:
	deck_collision.set_deferred("disabled", false)
	# Deferred shape changes must reach the physics server before opening gates.
	# The second physics frame guarantees a complete step with a solid deck.
	await get_tree().physics_frame
	await get_tree().physics_frame
	entrance_collision.set_deferred("disabled", true)
	exit_collision.set_deferred("disabled", true)
	await get_tree().physics_frame
	$Gates.visible = false
	state = State.READY
	reconstructed.emit()
