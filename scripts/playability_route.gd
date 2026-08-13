extends Node

var errors: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_double_jump()
	var first_level := 1
	var last_level := 3
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			first_level = clampi(argument.trim_prefix("--level=").to_int(), 1, 3)
			last_level = first_level
	for level_index in range(first_level, last_level + 1):
		await _run_level(level_index)
	if errors.is_empty():
		print("PLAYABILITY_ROUTE_OK: double jump + real movement route completes all three levels" if first_level == 1 and last_level == 3 else "PLAYABILITY_ROUTE_OK: requested level route completes")
		get_tree().quit(0)
	else:
		for error in errors:
			push_error(error)
		get_tree().quit(1)


func _test_double_jump() -> void:
	var floor := StaticBody2D.new()
	floor.position = Vector2(0, 100)
	floor.collision_layer = 1
	var collision := CollisionShape2D.new()
	var floor_shape := RectangleShape2D.new()
	floor_shape.size = Vector2(500, 100)
	collision.shape = floor_shape
	floor.add_child(collision)
	add_child(floor)
	var test_player := SkipClassPlayer.new()
	test_player.position = Vector2(0, 50)
	add_child(test_player)
	for frame in 4:
		await get_tree().physics_frame
	test_player.virtual_tap("jump")
	await get_tree().physics_frame
	if test_player.jumps_remaining != 1 or test_player.velocity.y >= 0.0:
		errors.append("Double jump first jump failed")
	test_player.virtual_tap("jump")
	await get_tree().physics_frame
	if test_player.jumps_remaining != 0 or test_player.velocity.y >= 0.0:
		errors.append("Double jump second jump failed")
	var velocity_before_third := test_player.velocity.y
	test_player.virtual_tap("jump")
	await get_tree().physics_frame
	if test_player.jumps_remaining != 0 or test_player.velocity.y <= velocity_before_third:
		errors.append("Double jump allowed an unintended third jump")
	test_player.queue_free()
	floor.queue_free()
	await get_tree().process_frame


func _run_level(level_index: int) -> void:
	var level := (load("res://game/levels/level_%02d.tscn" % level_index) as PackedScene).instantiate()
	get_tree().root.add_child(level)
	await get_tree().process_frame
	await get_tree().physics_frame
	level.hud.hide_message()
	level.player.controls_enabled = true
	GameState.begin_countdown()
	var max_suspicion := 0.0
	var suspicion_tracker := func(value: float) -> void: max_suspicion = maxf(max_suspicion, value)
	GameState.suspicion_changed.connect(suspicion_tracker)
	var route_ok := true
	match level_index:
		1:
			route_ok = await _move_to(level, 560.0)
			if route_ok:
				await _tap(level.player, "interact")
				if not level.player.is_hidden:
					errors.append("Level 1 route could not enter locker")
				await _tap(level.player, "interact")
				if level.player.is_hidden:
					errors.append("Level 1 route could not exit locker")
				route_ok = await _move_to(level, 2270.0)
			if route_ok:
				await _tap(level.player, "interact")
		2:
			route_ok = await _move_to(level, 515.0)
			if route_ok:
				await _tap(level.player, "interact")
				route_ok = await _move_to(level, 895.0)
			if route_ok:
				await _tap(level.player, "interact")
				await _tap(level.player, "use_item")
				route_ok = await _move_to(level, 2690.0)
			if route_ok:
				await _tap(level.player, "interact")
		3:
			route_ok = await _move_to(level, 505.0)
			if route_ok:
				await _tap(level.player, "interact")
				route_ok = await _move_to(level, 1410.0)
			if route_ok and level._dialogue_open:
				level._on_dialogue_answered(0)
				level.hud.hide_message()
				await get_tree().process_frame
			elif route_ok:
				errors.append("Level 3 route did not open dialogue")
				route_ok = false
			if route_ok:
				route_ok = await _move_to(level, 2515.0)
			if route_ok:
				await _tap(level.player, "interact")
				route_ok = await _move_to(level, 3000.0)
			if route_ok:
				await _tap(level.player, "interact")
	if not route_ok:
		errors.append("Level %d route failed: x=%.1f time=%.1f suspicion=%.1f active=%s ending=%s" % [level_index, level.player.global_position.x, GameState.timer_remaining, GameState.suspicion, GameState.level_active, level._ending])
	elif GameState.level_active:
		errors.append("Level %d route reached the exit but did not complete" % level_index)
	else:
		print("ROUTE_LEVEL_%d_OK: %.1fs used, max suspicion %.1f" % [level_index, float(level.level_data.time) - GameState.timer_remaining, max_suspicion])
	if GameState.suspicion_changed.is_connected(suspicion_tracker):
		GameState.suspicion_changed.disconnect(suspicion_tracker)
	level.queue_free()
	await get_tree().process_frame


func _move_to(level: Node, target_x: float) -> bool:
	level.player.set_virtual_action("move_right", true)
	level.player.set_virtual_action("run", true)
	var frames := 0
	while level.player.global_position.x < target_x - 32.0 and frames < 1800:
		if not GameState.level_active or level._ending:
			level.player.set_virtual_action("move_right", false)
			level.player.set_virtual_action("run", false)
			return false
		await get_tree().physics_frame
		frames += 1
	level.player.set_virtual_action("move_right", false)
	level.player.set_virtual_action("run", false)
	for frame in 12:
		await get_tree().physics_frame
	return frames < 1800 and GameState.level_active and not level._ending


func _tap(player: SkipClassPlayer, action: String) -> void:
	player.virtual_tap(action)
	await get_tree().physics_frame
	await get_tree().process_frame
