extends Control

var _modal: PanelContainer
var _modal_title: Label
var _modal_body: Label
var _settings_box: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_menu()
	_build_modal()
	AudioManager.start_music()


func _build_background() -> void:
	var sky := ColorRect.new()
	sky.color = Color("111a30")
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sky)
	var school := ColorRect.new()
	school.color = Color("d8895b")
	school.set_anchors_preset(Control.PRESET_FULL_RECT)
	school.offset_left = 55
	school.offset_top = 170
	school.offset_right = -55
	school.offset_bottom = 90
	sky.add_child(school)
	for index in 7:
		var window := ColorRect.new()
		window.color = Color("8fd3e8")
		window.position = Vector2(95 + index * 145, 75)
		window.size = Vector2(86, 92)
		school.add_child(window)
	var ground := ColorRect.new()
	ground.color = Color("27334d")
	ground.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ground.offset_top = -100
	ground.offset_bottom = 0
	sky.add_child(ground)


func _build_menu() -> void:
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-280, -255)
	center.custom_minimum_size = Vector2(560, 510)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 12)
	add_child(center)

	var kicker := Label.new()
	kicker.text = "THAI SCHOOL STEALTH DEMO"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.style_label(kicker, 18, Color("72e0d1"))
	center.add_child(kicker)
	var title := Label.new()
	title.text = "เสพติดการโดดเรียน"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.style_label(title, 54, Color("ffe08a"))
	center.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Skip class addicted"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.style_label(subtitle, 27, Color.WHITE)
	center.add_child(subtitle)

	center.add_child(_spacer(12))
	center.add_child(_menu_button("เริ่มเดโม  •  START DEMO", _start_demo))
	center.add_child(_menu_button("วิธีเล่น  •  HOW TO PLAY", _show_how_to))
	center.add_child(_menu_button("ตั้งค่าเสียง  •  SETTINGS", _show_settings))
	center.add_child(_menu_button("เครดิต  •  CREDITS", _show_credits))

	var footer := Label.new()
	footer.text = "Demo 3 ด่าน • เวลาเล่น 3–5 นาที • แนะนำโหมดแนวนอน"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.style_label(footer, 16, Color("bed3e6"))
	center.add_child(footer)


func _build_modal() -> void:
	_modal = PanelContainer.new()
	_modal.add_theme_stylebox_override("panel", UIFactory.panel(Color("121b30ee"), 14))
	_modal.set_anchors_preset(Control.PRESET_CENTER)
	_modal.position = Vector2(-375, -235)
	_modal.custom_minimum_size = Vector2(750, 470)
	_modal.visible = false
	add_child(_modal)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	_modal.add_child(content)
	_modal_title = Label.new()
	_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.style_label(_modal_title, 34, Color("ffe08a"))
	content.add_child(_modal_title)
	_modal_body = Label.new()
	_modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_modal_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIFactory.style_label(_modal_body, 20, Color.WHITE)
	content.add_child(_modal_body)
	_settings_box = HBoxContainer.new()
	_settings_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_settings_box.add_theme_constant_override("separation", 18)
	_settings_box.visible = false
	content.add_child(_settings_box)
	var close := _menu_button("ปิด  •  CLOSE", func() -> void: _modal.visible = false)
	close.custom_minimum_size.x = 180
	content.add_child(close)


func _menu_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	UIFactory.style_button(button)
	button.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		callback.call()
	)
	return button


func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	return spacer


func _start_demo() -> void:
	GameState.reset_demo()
	get_tree().change_scene_to_file("res://game/levels/level_01.tscn")


func _show_how_to() -> void:
	_modal_title.text = "วิธีเล่น • HOW TO PLAY"
	_modal_body.text = "A/D หรือ ←/→  เดิน\nShift  วิ่ง (เร็วแต่มีเสียง)\nSpace  กระโดด\nS หรือ ↓  ย่อ/ซ่อน\nE  โต้ตอบ • Q  ใช้ไอเท็ม • 1–3  เลือกช่อง\n\nไปถึง EXIT ก่อนเวลาหมด อย่าให้ค่าความสงสัยเต็ม 100!\nบนมือถือใช้ปุ่มสัมผัสด้านล่างในโหมดแนวนอน"
	_settings_box.visible = false
	_modal.visible = true


func _show_settings() -> void:
	_modal_title.text = "ตั้งค่าเสียง • SETTINGS"
	_modal_body.text = "เสียงจะเริ่มหลังการกดครั้งแรก เพื่อรองรับ Web browser"
	_settings_box.visible = true
	for child in _settings_box.get_children():
		child.queue_free()
	var music := _menu_button("Music: %s" % ("ON" if GameState.music_enabled else "OFF"), func() -> void:
		GameState.set_audio_options(not GameState.music_enabled, GameState.sfx_enabled)
		_show_settings()
	)
	var sfx := _menu_button("SFX: %s" % ("ON" if GameState.sfx_enabled else "OFF"), func() -> void:
		GameState.set_audio_options(GameState.music_enabled, not GameState.sfx_enabled)
		_show_settings()
	)
	music.custom_minimum_size.x = 210
	sfx.custom_minimum_size.x = 210
	_settings_box.add_child(music)
	_settings_box.add_child(sfx)
	_modal.visible = true


func _show_credits() -> void:
	get_tree().change_scene_to_file("res://game/credits.tscn")
