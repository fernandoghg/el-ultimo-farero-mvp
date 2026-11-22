extends CanvasLayer

@onready var lighthouse: Node3D = $"../Lighthouse"
@onready var bridge: Node3D = $"../Bridge"
@onready var player: CharacterBody3D = $"../Player"
@onready var camera: Camera3D = $"../Camera"
@onready var replay: Button = $Card/Content/Actions/Replay
@onready var exit: Button = $Card/Content/Actions/Exit


func _ready() -> void:
	lighthouse.activated.connect(_hold_view)
	bridge.reconstructed.connect(_show_conclusion)
	replay.pressed.connect(_replay)
	exit.pressed.connect(_exit)


func _hold_view() -> void:
	# Let physics and the current camera turn settle during reconstruction.
	player.controls_suspended = true
	camera.controls_suspended = true


func _show_conclusion() -> void:
	if visible or lighthouse.state != lighthouse.State.ACTIVE or bridge.state != bridge.State.READY:
		return
	show()
	get_tree().paused = true
	replay.grab_focus()


func _replay() -> void:
	# The new introduction owns the pause and resumes play after a fresh Enter.
	var result := get_tree().reload_current_scene()
	if result != OK:
		push_error("Could not restart the adventure: %s" % error_string(result))


func _exit() -> void:
	get_tree().quit()
