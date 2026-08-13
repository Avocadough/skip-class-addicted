extends Node


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var level_number := 1
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			level_number = int(argument.trim_prefix("--level="))
	var scene := load("res://game/levels/level_%02d.tscn" % level_number) as PackedScene
	var level = scene.instantiate()
	add_child(level)
	await get_tree().process_frame
	await get_tree().process_frame
	level.hud.hide_message()
	level.player.controls_enabled = false
	GameState.level_active = true
	level.player.position.x = float(level.level_data.width) * 0.38
	for frame in 25:
		await get_tree().process_frame
	var output := ProjectSettings.globalize_path("res://qa-output/gameplay-level-%d.png" % level_number)
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var result := get_viewport().get_texture().get_image().save_png(output)
	if result == OK:
		print("GAMEPLAY_CAPTURE_OK: %s" % output)
		get_tree().quit(0)
	else:
		push_error("Capture failed")
		get_tree().quit(1)
