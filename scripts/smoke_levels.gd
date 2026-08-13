extends Node

var errors: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	for index in range(1, 4):
		var path := "res://game/levels/level_%02d.tscn" % index
		var scene := load(path) as PackedScene
		var instance := scene.instantiate()
		get_tree().root.add_child(instance)
		await get_tree().process_frame
		await get_tree().process_frame
		var player_found := false
		var hud_found := false
		for child in instance.get_children():
			if child is SkipClassPlayer:
				player_found = true
			elif child is GameHUD:
				hud_found = true
		if not player_found:
			errors.append("Level %d has no player" % index)
		if not hud_found:
			errors.append("Level %d has no HUD" % index)
		if index == 1 and instance.guards.size() < 2:
			errors.append("Hallway requires two guards")
		if index == 2 and not instance.interactables.any(func(item: Dictionary) -> bool: return item.get("kind") == "vending"):
			errors.append("Cafeteria requires vending puzzle")
		if index == 3 and not instance.interactables.any(func(item: Dictionary) -> bool: return item.get("item") == "storage_key"):
			errors.append("Library requires storage key")
		instance.queue_free()
		await get_tree().process_frame

	if errors.is_empty():
		print("LEVEL_SMOKE_OK: all three levels instantiated and core encounters are present")
		get_tree().quit(0)
	else:
		for error in errors:
			push_error(error)
		get_tree().quit(1)
