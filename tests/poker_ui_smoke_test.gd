extends SceneTree

func _init() -> void:
	var packed_scene: PackedScene = load("res://scenes/poker_test.tscn") as PackedScene
	if packed_scene == null:
		push_error("Could not load poker_test.tscn.")
		quit(1)
		return

	var scene: Node = packed_scene.instantiate()
	root.add_child(scene)
	call_deferred("_finish")

func _finish() -> void:
	await process_frame
	await process_frame
	var scene: Node = root.get_child(root.get_child_count() - 1)
	if scene.get_child_count() == 0:
		push_error("Poker test scene did not build any UI children.")
		quit(1)
		return
	var card_count: int = _count_card_views(scene)
	if card_count < 11:
		push_error("Poker test scene did not create enough card views.")
		quit(1)
		return
	print("Poker UI smoke test passed.")
	quit(0)

func _count_card_views(node: Node) -> int:
	var count: int = 0
	var script: Script = node.get_script() as Script
	if script != null and script.resource_path == "res://scenes/ui/card_view.gd":
		count += 1
	for child in node.get_children():
		count += _count_card_views(child)
	return count
