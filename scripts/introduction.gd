extends CanvasLayer

const GAMEPLAY_ACTIONS: Array[StringName] = [
	&"move_forward", &"move_back", &"move_left", &"move_right",
	&"camera_left", &"camera_right", &"interact",
]

@onready var continue_prompt: Label = $Card/Content/Continue


func _ready() -> void:
	get_tree().paused = true


func _input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode != KEY_ENTER and event.keycode != KEY_KP_ENTER:
		return
	for action in GAMEPLAY_ACTIONS:
		if Input.is_action_pressed(action):
			continue_prompt.text = "INTRO_RELEASE_KEYS"
			return
	get_tree().paused = false
	queue_free()
