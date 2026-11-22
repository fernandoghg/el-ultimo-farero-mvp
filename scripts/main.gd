extends Node3D

const CIRCUITS := {&"P1": ^"LostLight", &"P2": ^"GuardianMirrors", &"P3": ^"FractalRotor"}
var _restored: Dictionary = {&"P1": false, &"P2": false, &"P3": false}


func _ready() -> void:
	for id: StringName in CIRCUITS:
		var circuit: Node = get_node(CIRCUITS[id])
		var event: StringName = &"circuit_completed" if id == &"P3" else &"resolved"
		var callback := _record_circuit.bind(id)
		if not circuit.is_connected(event, callback):
			circuit.connect(event, callback)


func _record_circuit(id: StringName) -> void:
	if id not in CIRCUITS or _restored[id]:
		return
	# Real controllers set solved before emitting. A premature signal is not progress.
	if get_node(CIRCUITS[id]).solved:
		_restored[id] = true


func circuit_is_restored(id: StringName) -> bool:
	return _restored.get(id, false)


func restored_count() -> int:
	return _restored.values().count(true)


func _enter_tree() -> void:
	# Engine --language is consumed before game scripts run. Use explicit user args.
	var locale := "es"
	var arguments := OS.get_cmdline_user_args()
	var option := arguments.find("--game-language")
	if option >= 0 and option + 1 < arguments.size():
		var requested := arguments[option + 1]
		if requested in ["es", "en"]:
			locale = requested
	TranslationServer.set_locale(locale)
