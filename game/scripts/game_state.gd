extends Node

signal timer_changed(seconds_left: float)
signal suspicion_changed(value: float)
signal inventory_changed(items: Array[String], selected_slot: int)
signal objective_changed(text: String)
signal caught(reason: String)
signal level_completed(level_index: int)

const MAX_SUSPICION := 100.0
const INVENTORY_SIZE := 3

var current_level := 0
var timer_remaining := 0.0
var suspicion := 0.0
var objective := ""
var inventory: Array[String] = []
var selected_slot := 0
var level_active := false
var demo_completed := false
var music_enabled := true
var sfx_enabled := true

var _detection_grace := 0.0
var _safe_time := 0.0
var _stealth_grace := 0.0


func _ready() -> void:
	_install_input_actions()
	load_options()


func reset_demo() -> void:
	current_level = 0
	demo_completed = false
	inventory.clear()
	selected_slot = 0
	suspicion = 0.0
	level_active = false
	inventory_changed.emit(inventory.duplicate(), selected_slot)
	suspicion_changed.emit(suspicion)


func start_level(level_index: int, time_limit: float, new_objective: String) -> void:
	current_level = level_index
	timer_remaining = time_limit
	suspicion = 0.0
	objective = new_objective
	inventory.clear()
	selected_slot = 0
	level_active = false
	_detection_grace = 0.0
	_safe_time = 0.0
	_stealth_grace = 0.0
	timer_changed.emit(timer_remaining)
	suspicion_changed.emit(suspicion)
	inventory_changed.emit(inventory.duplicate(), selected_slot)
	objective_changed.emit(objective)


func begin_countdown() -> void:
	level_active = true


func tick(delta: float) -> void:
	if not level_active:
		return
	timer_remaining = maxf(0.0, timer_remaining - delta)
	timer_changed.emit(timer_remaining)
	_detection_grace = maxf(0.0, _detection_grace - delta)
	_stealth_grace = maxf(0.0, _stealth_grace - delta)
	if _detection_grace <= 0.0:
		_safe_time += delta
		if _safe_time >= 0.3 and suspicion > 0.0:
			set_suspicion(suspicion - 30.0 * delta)
	else:
		_safe_time = 0.0
	if timer_remaining <= 0.0:
		catch_player("หมดเวลา! ครูล็อกประตูแล้ว")


func report_detection(amount: float) -> void:
	if not level_active or _stealth_grace > 0.0:
		return
	_detection_grace = 0.18
	_safe_time = 0.0
	set_suspicion(suspicion + amount)


func grant_stealth_grace(seconds: float) -> void:
	_stealth_grace = maxf(_stealth_grace, seconds)


func add_suspicion(amount: float) -> void:
	if level_active:
		set_suspicion(suspicion + amount)


func set_suspicion(value: float) -> void:
	suspicion = clampf(value, 0.0, MAX_SUSPICION)
	suspicion_changed.emit(suspicion)
	if suspicion >= MAX_SUSPICION:
		catch_player("โป๊ะแตก! ค่าความสงสัยเต็ม")


func set_objective(text: String) -> void:
	objective = text
	objective_changed.emit(objective)


func add_item(item_id: String) -> bool:
	if inventory.size() >= INVENTORY_SIZE or inventory.has(item_id):
		return false
	inventory.append(item_id)
	selected_slot = inventory.size() - 1
	inventory_changed.emit(inventory.duplicate(), selected_slot)
	return true


func has_item(item_id: String) -> bool:
	return inventory.has(item_id)


func consume_item(item_id: String) -> bool:
	var index := inventory.find(item_id)
	if index < 0:
		return false
	inventory.remove_at(index)
	selected_slot = clampi(selected_slot, 0, maxi(0, inventory.size() - 1))
	inventory_changed.emit(inventory.duplicate(), selected_slot)
	return true


func select_slot(index: int) -> void:
	selected_slot = clampi(index, 0, INVENTORY_SIZE - 1)
	inventory_changed.emit(inventory.duplicate(), selected_slot)


func selected_item() -> String:
	if selected_slot >= 0 and selected_slot < inventory.size():
		return inventory[selected_slot]
	return ""


func catch_player(reason: String) -> void:
	if not level_active:
		return
	level_active = false
	caught.emit(reason)


func complete_level() -> void:
	if not level_active:
		return
	level_active = false
	level_completed.emit(current_level)


func set_audio_options(music_on: bool, sfx_on: bool) -> void:
	music_enabled = music_on
	sfx_enabled = sfx_on
	AudioManager.apply_options()
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_enabled)
	config.set_value("audio", "sfx", sfx_enabled)
	config.save("user://options.cfg")


func load_options() -> void:
	var config := ConfigFile.new()
	if config.load("user://options.cfg") == OK:
		music_enabled = bool(config.get_value("audio", "music", true))
		sfx_enabled = bool(config.get_value("audio", "sfx", true))


func format_time() -> String:
	var whole := ceili(timer_remaining)
	return "%02d:%02d" % [int(whole / 60), whole % 60]


func item_display_name(item_id: String) -> String:
	return {
		"coin": "เหรียญ 10฿",
		"snack": "ขนม",
		"homework": "การบ้านปลอม",
		"storage_key": "กุญแจห้องเก็บของ",
	}.get(item_id, item_id)


func _install_input_actions() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_keys("run", [KEY_SHIFT])
	_add_keys("crouch", [KEY_S, KEY_DOWN])
	_add_keys("interact", [KEY_E])
	_add_keys("use_item", [KEY_Q])
	_add_keys("pause", [KEY_ESCAPE])
	_add_keys("slot_1", [KEY_1])
	_add_keys("slot_2", [KEY_2])
	_add_keys("slot_3", [KEY_3])


func _add_keys(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)
