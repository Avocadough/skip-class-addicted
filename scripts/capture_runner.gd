extends Node


func _ready() -> void:
	var target := "menu"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--target="):
			target = argument.trim_prefix("--target=")
	var scene_path := "res://game/main_menu.tscn"
	if target.begins_with("level"):
		var level_number := target.trim_prefix("level")
		scene_path = "res://game/levels/level_%02d.tscn" % int(level_number)
	var instance := (load(scene_path) as PackedScene).instantiate()
	add_child(instance)
	for frame in 20:
		await get_tree().process_frame
	var output_dir := ProjectSettings.globalize_path("res://qa-output")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png(output_dir.path_join("%s.png" % target))
	if result == OK:
		print("CAPTURE_OK: %s" % output_dir.path_join("%s.png" % target))
		get_tree().quit(0)
	else:
		push_error("Could not save capture: %s" % result)
		get_tree().quit(1)
