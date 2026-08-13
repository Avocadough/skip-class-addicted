class_name GameHUD
extends CanvasLayer

signal intro_closed
signal dialogue_answered(choice: int)

var _timer: Label
var _suspicion: ProgressBar
var _objective: Label
var _slots: Array[Button] = []
var _prompt: Label
var _overlay: PanelContainer
var _overlay_title: Label
var _overlay_body: Label
var _overlay_buttons: HBoxContainer
var _player: SkipClassPlayer
var _paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	GameState.timer_changed.connect(_on_timer_changed)
	GameState.suspicion_changed.connect(_on_suspicion_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.objective_changed.connect(_on_objective_changed)
	_on_timer_changed(GameState.timer_remaining)
	_on_suspicion_changed(GameState.suspicion)
	_on_inventory_changed(GameState.inventory, GameState.selected_slot)
	_on_objective_changed(GameState.objective)


func bind_player(player: SkipClassPlayer) -> void:
	_player = player
	_build_touch_controls()


func set_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.visible = not text.is_empty()


func show_intro(title: String, body: String) -> void:
	_show_overlay(title, body)
	_add_overlay_button("เริ่มด่าน • START", func() -> void:
		_hide_overlay()
		intro_closed.emit()
	)


func show_dialogue(speaker: String, body: String, choices: Array[String]) -> void:
	_show_overlay(speaker, body)
	for index in choices.size():
		var choice_index := index
		_add_overlay_button(choices[index], func() -> void:
			_hide_overlay()
			dialogue_answered.emit(choice_index)
		)


func show_message(title: String, body: String) -> void:
	_show_overlay(title, body)


func hide_message() -> void:
	_hide_overlay()


func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_top = 16
	top.offset_right = -20
	top.offset_bottom = 82
	top.add_theme_constant_override("separation", 16)
	root.add_child(top)

	_timer = Label.new()
	_timer.custom_minimum_size = Vector2(175, 56)
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer.add_theme_stylebox_override("normal", UIFactory.panel(Color("18233bdd"), 10))
	UIFactory.style_label(_timer, 30, Color("ffe08a"))
	top.add_child(_timer)

	var suspicion_box := VBoxContainer.new()
	suspicion_box.custom_minimum_size = Vector2(320, 55)
	var suspicion_label := Label.new()
	suspicion_label.text = "ความสงสัย • SUSPICION"
	UIFactory.style_label(suspicion_label, 15, Color("f3a6b6"))
	suspicion_box.add_child(suspicion_label)
	_suspicion = ProgressBar.new()
	_suspicion.max_value = 100
	_suspicion.show_percentage = true
	_suspicion.custom_minimum_size.y = 27
	suspicion_box.add_child(_suspicion)
	top.add_child(suspicion_box)

	_objective = Label.new()
	_objective.custom_minimum_size = Vector2(330, 62)
	_objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.clip_text = true
	UIFactory.style_label(_objective, 18, Color.WHITE)
	top.add_child(_objective)

	var slots := HBoxContainer.new()
	slots.set_anchors_preset(Control.PRESET_TOP_LEFT)
	slots.position = Vector2(600, 92)
	slots.size = Vector2(420, 50)
	slots.add_theme_constant_override("separation", 7)
	root.add_child(slots)
	for index in 3:
		var button := Button.new()
		button.text = "%d  —" % (index + 1)
		button.custom_minimum_size = Vector2(132, 46)
		UIFactory.style_button(button, Color("34435d"), 15)
		var slot := index
		button.pressed.connect(func() -> void: GameState.select_slot(slot))
		slots.add_child(button)
		_slots.append(button)

	var pause_button := Button.new()
	pause_button.text = "Ⅱ"
	pause_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	pause_button.position = Vector2(1068, 92)
	pause_button.custom_minimum_size = Vector2(46, 46)
	UIFactory.style_button(pause_button, Color("34435d"), 19)
	pause_button.pressed.connect(_toggle_pause)
	root.add_child(pause_button)

	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-300, -125)
	_prompt.custom_minimum_size = Vector2(600, 52)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.add_theme_stylebox_override("normal", UIFactory.panel(Color("101626dd"), 8))
	UIFactory.style_label(_prompt, 19, Color("ffe08a"))
	_prompt.visible = false
	root.add_child(_prompt)

	_overlay = PanelContainer.new()
	_overlay.set_anchors_preset(Control.PRESET_CENTER)
	_overlay.position = Vector2(-365, -205)
	_overlay.custom_minimum_size = Vector2(730, 410)
	_overlay.add_theme_stylebox_override("panel", UIFactory.panel(Color("10182cf5"), 16))
	_overlay.visible = false
	root.add_child(_overlay)
	var overlay_content := VBoxContainer.new()
	overlay_content.add_theme_constant_override("separation", 18)
	_overlay.add_child(overlay_content)
	_overlay_title = Label.new()
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.style_label(_overlay_title, 34, Color("ffe08a"))
	overlay_content.add_child(_overlay_title)
	_overlay_body = Label.new()
	_overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_overlay_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIFactory.style_label(_overlay_body, 20, Color.WHITE)
	overlay_content.add_child(_overlay_body)
	_overlay_buttons = HBoxContainer.new()
	_overlay_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_overlay_buttons.add_theme_constant_override("separation", 12)
	overlay_content.add_child(_overlay_buttons)


func _build_touch_controls() -> void:
	if not DisplayServer.is_touchscreen_available() or _player == null:
		return
	var root := get_child(0) as Control
	var left_group := HBoxContainer.new()
	left_group.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	left_group.position = Vector2(20, -95)
	left_group.add_theme_constant_override("separation", 8)
	root.add_child(left_group)
	_add_hold_button(left_group, "◀", "move_left")
	_add_hold_button(left_group, "▶", "move_right")
	_add_hold_button(left_group, "วิ่ง", "run")
	var right_group := HBoxContainer.new()
	right_group.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	right_group.position = Vector2(-430, -95)
	right_group.add_theme_constant_override("separation", 8)
	root.add_child(right_group)
	_add_tap_button(right_group, "กระโดด", "jump")
	_add_hold_button(right_group, "ซ่อน", "crouch")
	_add_tap_button(right_group, "ใช้", "interact")
	_add_tap_button(right_group, "ของ", "use_item")


func _add_hold_button(parent: Control, text: String, action: String) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(82, 72)
	button.modulate.a = 0.82
	UIFactory.style_button(button, Color("245475"), 17)
	button.button_down.connect(func() -> void: _player.set_virtual_action(action, true))
	button.button_up.connect(func() -> void: _player.set_virtual_action(action, false))
	parent.add_child(button)


func _add_tap_button(parent: Control, text: String, action: String) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(82, 72)
	button.modulate.a = 0.82
	UIFactory.style_button(button, Color("73446f"), 17)
	button.pressed.connect(func() -> void: _player.virtual_tap(action))
	parent.add_child(button)


func _show_overlay(title: String, body: String) -> void:
	_overlay_title.text = title
	_overlay_body.text = body
	for child in _overlay_buttons.get_children():
		child.queue_free()
	_overlay.visible = true


func _hide_overlay() -> void:
	_overlay.visible = false


func _add_overlay_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 56)
	UIFactory.style_button(button, Color("246b8e"), 17)
	button.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		callback.call()
	)
	_overlay_buttons.add_child(button)


func _on_timer_changed(_seconds: float) -> void:
	_timer.text = "⏱  %s" % GameState.format_time()
	_timer.add_theme_color_override("font_color", Color("ff728b") if GameState.timer_remaining <= 15.0 else Color("ffe08a"))


func _on_suspicion_changed(value: float) -> void:
	_suspicion.value = value


func _on_inventory_changed(items: Array[String], selected: int) -> void:
	for index in _slots.size():
		var item_name := "—"
		if index < items.size():
			item_name = GameState.item_display_name(items[index])
		_slots[index].text = "%d  %s" % [index + 1, item_name]
		_slots[index].modulate = Color("ffe08a") if index == selected else Color.WHITE


func _on_objective_changed(text: String) -> void:
	_objective.text = "เป้าหมาย • OBJECTIVE\n%s" % text


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not _overlay.visible:
		_toggle_pause()


func _toggle_pause() -> void:
	if _overlay.visible and not _paused:
		return
	_paused = not _paused
	get_tree().paused = _paused
	if _paused:
		_show_overlay("หยุดเกม • PAUSED", "พักหายใจได้ แต่อย่าให้ครูเห็น!")
		_add_overlay_button("เล่นต่อ • RESUME", func() -> void:
			_paused = false
			get_tree().paused = false
			_hide_overlay()
		)
		_add_overlay_button("กลับเมนู • MENU", func() -> void:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://game/main_menu.tscn")
		)
