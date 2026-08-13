extends SceneTree

const REQUIRED_FILES := [
	"res://game/main_menu.tscn",
	"res://game/levels/level_01.tscn",
	"res://game/levels/level_02.tscn",
	"res://game/levels/level_03.tscn",
	"res://game/credits.tscn",
	"res://game/scripts/game_state.gd",
	"res://game/scripts/player_controller.gd",
	"res://game/scripts/guard_ai.gd",
	"res://game/scripts/security_camera.gd",
	"res://game/scripts/game_hud.gd",
	"res://ASSET_CREDITS.md",
	"res://export_presets.cfg",
]


func _initialize() -> void:
	var errors: Array[String] = []
	var game_state = get_root().get_node_or_null("GameState")
	if game_state == null:
		game_state = load("res://game/scripts/game_state.gd").new()
	for path in REQUIRED_FILES:
		if not FileAccess.file_exists(path):
			errors.append("Missing required file: %s" % path)

	for scene_path in REQUIRED_FILES.filter(func(path: String) -> bool: return path.ends_with(".tscn")):
		var scene := load(scene_path) as PackedScene
		if scene == null:
			errors.append("Could not load scene: %s" % scene_path)
			continue
		var instance := scene.instantiate()
		if instance == null:
			errors.append("Could not instantiate scene: %s" % scene_path)
		else:
			instance.free()

	if game_state.MAX_SUSPICION != 100.0:
		errors.append("Suspicion maximum must be 100")
	if game_state.INVENTORY_SIZE != 3:
		errors.append("Inventory must contain three slots")
	game_state.inventory.clear()
	if not game_state.add_item("coin") or not game_state.has_item("coin"):
		errors.append("Inventory add/has contract failed")
	if not game_state.consume_item("coin") or game_state.has_item("coin"):
		errors.append("Inventory consume contract failed")
	game_state.start_level(1, 60.0, "test")
	game_state.begin_countdown()
	game_state.report_detection(35.0)
	if not is_equal_approx(game_state.suspicion, 35.0):
		errors.append("Suspicion increase contract failed")
	game_state.set_suspicion(140.0)
	if game_state.suspicion != 100.0:
		errors.append("Suspicion clamp contract failed")
	game_state.level_active = false

	if errors.is_empty():
		print("PROJECT_VALIDATION_OK: menu + 3 stealth levels + HUD + credits + inventory + suspicion")
		quit(0)
	else:
		for error in errors:
			push_error(error)
		quit(1)
