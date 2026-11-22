extends "res://tests/fractal_un_rotor.gd"

const Circuits = preload("res://tests/circuit_fixture.gd")
const ORDERS := [[&"P1", &"P2", &"P3"], [&"P1", &"P3", &"P2"], [&"P2", &"P1", &"P3"], [&"P2", &"P3", &"P1"], [&"P3", &"P1", &"P2"], [&"P3", &"P2", &"P1"]]
var activations: int = 0


func fixture() -> Node3D:
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.get_node("Player").set_physics_process(false)
	scene.get_node("Player").position = Vector3(3, 0.01, -1.5)
	activations = 0
	scene.get_node("Lighthouse").activated.connect(func(): activations += 1)
	return scene


func discard(scene: Node3D) -> void:
	for key in ["interact", "pause", "move_left", "move_right", "move_forward", "move_back", "camera_left", "camera_right"]:
		action(key, false)
	scene.queue_free()
	await frames(3)


func progress_text(count: int) -> String:
	return ("Circuits restored: %d of 3" if TranslationServer.get_locale().begins_with("en") else "Circuitos restaurados: %d de 3") % count


func capture_progress(count: int) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://build")
	check(root.get_texture().get_image().save_png("res://build/restoration-%d-%s.png" % [count, TranslationServer.get_locale()]) == OK, "Progress capture failed")


func repeat_signal(scene: Node3D, id: StringName) -> void:
	var source: Node = scene.get_node(scene.CIRCUITS[id])
	source.emit_signal("circuit_completed" if id == &"P3" else "resolved")


func run() -> void:
	root.size = Vector2i(1280, 720)
	# Credit is individual, idempotent and based on a real resolved controller.
	for id: StringName in [&"P1", &"P2", &"P3"]:
		var scene := fixture()
		await frames(3)
		check(scene.restored_count() == 0, "New game is not 0/3")
		repeat_signal(scene, id)
		check(scene.restored_count() == 0, "Premature signal credited an unsolved circuit")
		scene._record_circuit(&"unknown")
		check(not scene.circuit_is_restored(&"unknown"), "Unknown circuit credited")
		await Circuits.solve(scene, id)
		check(scene.restored_count() == 1 and scene.circuit_is_restored(id), "Individual circuit not recorded")
		for other: StringName in [&"P1", &"P2", &"P3"]:
			check(scene.circuit_is_restored(other) == (other == id), "Circuit identities mixed")
		check(scene.get_node("Lighthouse")._progress_remaining == 0.0, "Resolution showed a progress counter automatically")
		check(scene.get_node("Lighthouse").state == 0 and scene.get_node("Bridge").state == 0, "Individual resolution activated lighthouse/bridge")
		for attempt in range(3):
			repeat_signal(scene, id)
		check(scene.restored_count() == 1, "Repeated resolution counted twice")
		scene._ready()
		check(scene.restored_count() == 1, "Reconnecting reset session progress")
		var source: Node = scene.get_node(scene.CIRCUITS[id])
		var event: StringName = &"circuit_completed" if id == &"P3" else &"resolved"
		var connections: Array = source.get_signal_connection_list(event).filter(func(link): return link.callable.get_object() == scene)
		check(connections.size() == 1, "Duplicate circuit subscription")
		await discard(scene)

	var orders_checked := 0
	for order in ORDERS:
		var scene := fixture()
		var lighthouse: Node3D = scene.get_node("Lighthouse")
		var bridge: Node3D = scene.get_node("Bridge")
		var player: CharacterBody3D = scene.get_node("Player")
		await frames(50)
		check(lighthouse.restoration == scene and scene.restored_count() == 0, "Progress provider not wired or stale")
		check(lighthouse._progress_remaining == 0 and lighthouse.prompt.text != progress_text(0), "Counter is permanent before first attempt")
		for index in range(3):
			check(scene.restored_count() == index, "Wrong count before circuit")
			action("interact", true)
			await frames(2)
			check(lighthouse.state == 0 and activations == 0 and not lighthouse.light.visible, "Incomplete circuits activated lighthouse")
			check(bridge.state == 0 and bridge.deck_collision.disabled and not bridge.entrance_collision.disabled, "Premature bridge reconstruction")
			check(lighthouse.prompt.visible and lighthouse.prompt.text == progress_text(index), "Progress attempt is not localized/current")
			check(lighthouse.prompt.get_minimum_size().x < 1280, "Progress text exceeds viewport")
			if orders_checked == 0:
				await capture_progress(index)
			if orders_checked == 0 and index == 0:
				await frames(125)
				check(lighthouse._progress_remaining == 0 and lighthouse.prompt.text != progress_text(0), "Progress message did not expire")
				# Holding the key after expiry must not show it again.
				action("interact", true)
				await frames(2)
				check(lighthouse._progress_remaining == 0, "Held I repeated the failed attempt")
			await Circuits.solve(scene, order[index])
			check(scene.restored_count() == index + 1, "Resolution order affected count")
			for attempt in range(3):
				repeat_signal(scene, order[index])
			check(scene.restored_count() == index + 1, "Duplicate signal inflated count")
			action("interact", true)
			await frames(3)
			check(lighthouse.state == 0 and activations == 0 and bridge.state == 0, "Completion or held I activated automatically")
			action("interact", false)
			await frames(2)
		# Leaving range, camera turns and fresh-but-outside presses do not lose progress.
		player.position = Vector3(1, 0.01, 4)
		await tap("interact")
		scene.get_node("Camera").request_turn(1)
		await frames(35)
		check(scene.restored_count() == 3 and activations == 0, "Session progress lost or outside press activated")
		player.position = Vector3(3, 0.01, -1.5)
		await frames(3)
		check(scene.restored_count() == 3 and lighthouse.state == 0, "Third circuit auto-activated")
		var links: Array = lighthouse.get_signal_connection_list("activated").filter(func(link): return link.callable.get_object() == bridge and link.callable.get_method() == &"reconstruct")
		check(links.size() == 1, "Bridge reconstruction connected more than once")
		await tap("interact")
		check(lighthouse.state == 1 and activations == 1 and lighthouse.light.visible and not lighthouse.prompt.visible, "Fresh I with 3 circuits failed")
		check(bridge.state == 1, "Manual activation did not start bridge")
		for attempt in range(3):
			await tap("interact")
		for frame in range(120):
			if bridge.state == 2:
				break
			await frames(1)
		check(bridge.state == 2 and not bridge.deck_collision.disabled, "Bridge reconstruction failed")
		var poses: Array[Transform3D] = []
		for segment in bridge.get_node("Segments").get_children():
			poses.append(segment.transform)
		await tap("interact")
		for id: StringName in [&"P1", &"P2", &"P3"]:
			repeat_signal(scene, id)
		await frames(4)
		check(activations == 1 and scene.restored_count() == 3 and bridge.state == 2, "Activated state/signals repeated")
		for index in range(poses.size()):
			check(bridge.get_node("Segments").get_child(index).transform == poses[index], "Stable bridge kept moving")
		orders_checked += 1
		await discard(scene)

	var scene := fixture()
	await frames(3)
	check(scene.restored_count() == 0 and scene.get_node("Bridge").state == 0, "New scene inherited previous progress")
	scene.get_node("Lighthouse").restoration = null
	await tap("interact")
	check(activations == 0 and scene.get_node("Lighthouse").prompt.text == progress_text(0), "Missing provider bypassed requirement")
	await discard(scene)
	print("Restoration: %d orders, counts 0/1/2/3, no duplicate credit, manual unique activation and reconstruction, session reset, locale; failures: %d" % [orders_checked, failures])
	quit(1 if failures else 0)
