extends Node

var errors: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	for index in range(1, 4):
		var scene := load("res://game/levels/level_%02d.tscn" % index) as PackedScene
		var level = scene.instantiate()
		get_tree().root.add_child(level)
		await get_tree().process_frame
		await get_tree().process_frame
		level.hud.hide_message()
		level.player.controls_enabled = true
		GameState.begin_countdown()
		if index == 1:
			var hide_spot: Dictionary = level.interactables.filter(func(item: Dictionary) -> bool: return item.kind == "hide")[0]
			level.player.position.x = hide_spot.node.position.x
			await get_tree().process_frame
			level._update_interaction_prompt()
			var interact_press := InputEventAction.new()
			interact_press.action = "interact"
			interact_press.pressed = true
			Input.parse_input_event(interact_press)
			await get_tree().process_frame
			await get_tree().physics_frame
			interact_press.pressed = false
			Input.parse_input_event(interact_press)
			await get_tree().process_frame
			await get_tree().physics_frame
			if not level.player.is_hidden:
				errors.append("Level 1 enter-hide input failed")
			var jump_press := InputEventAction.new()
			jump_press.action = "jump"
			jump_press.pressed = true
			Input.parse_input_event(jump_press)
			await get_tree().process_frame
			await get_tree().physics_frame
			jump_press.pressed = false
			Input.parse_input_event(jump_press)
			if level.player.is_hidden:
				errors.append("Level 1 exit-hide input failed")
			level._nearest = level.interactables.filter(func(item: Dictionary) -> bool: return item.kind == "exit")[0]
		elif index == 2:
			level._nearest = level.interactables.filter(func(item: Dictionary) -> bool: return item.get("item") == "coin")[0]
			level._on_interact()
			level._nearest = level.interactables.filter(func(item: Dictionary) -> bool: return item.kind == "vending")[0]
			level._on_interact()
			if not GameState.has_item("snack"):
				errors.append("Level 2 vending transaction failed")
			level._on_use_item()
			if GameState.has_item("snack"):
				errors.append("Level 2 snack use failed")
			level._nearest = level.interactables.filter(func(item: Dictionary) -> bool: return item.kind == "exit")[0]
		else:
			level._nearest = level.interactables.filter(func(item: Dictionary) -> bool: return item.get("item") == "homework")[0]
			level._on_interact()
			level._dialogue_open = true
			level._on_dialogue_answered(0)
			if not level._dialogue_done:
				errors.append("Level 3 correct dialogue failed")
			level._nearest = level.interactables.filter(func(item: Dictionary) -> bool: return item.get("item") == "storage_key")[0]
			level._on_interact()
			level._nearest = level.interactables.filter(func(item: Dictionary) -> bool: return item.kind == "exit")[0]
		level._on_interact()
		if GameState.level_active:
			errors.append("Level %d did not complete at exit" % index)
		level.queue_free()
		await get_tree().process_frame

	if errors.is_empty():
		print("INTEGRATION_FLOW_OK: hide + vending/noise item + dialogue/key + all exits")
		get_tree().quit(0)
	else:
		for error in errors:
			push_error(error)
		get_tree().quit(1)
