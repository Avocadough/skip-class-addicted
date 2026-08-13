extends Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("111a30")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-465, -288)
	panel.custom_minimum_size = Vector2(930, 576)
	panel.add_theme_stylebox_override("panel", UIFactory.panel(Color("17233ced"), 16))
	add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var title := Label.new()
	title.text = "เครดิต • CREDITS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.style_label(title, 40, Color("ffe08a"))
	content.add_child(title)

	var status := Label.new()
	status.text = "หนีเรียนสำเร็จ — DEMO COMPLETE" if GameState.demo_completed else "เสพติดการโดดเรียน – Skip class addicted"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.style_label(status, 21, Color("72e0d1"))
	content.add_child(status)

	var body := Label.new()
	body.text = "ทีมพัฒนา • GROUP 19\nกษิเดช สุขศีล  663380252-6\nภูริณัฐ ศรีไตรรัตน์  663380531-2\nณภัตร ช้อยกิ่ง  663380262-3\nสาขาวิทยาการคอมพิวเตอร์\n\nรายวิชา CP410844 • ภาคเรียน 1/2569\n\nสร้างด้วย Godot Engine 4.7.1\nฐานโครงการ: computingkku/2D-Platformer-Starter-Kit (MIT)\nฟอนต์ Kodchasan: Google Fonts / SIL Open Font License\nภาพฉาก ตัวละคร UI และเสียงสังเคราะห์: สร้างใหม่สำหรับโครงการนี้\n\nSource & gameplay: github.com/Avocadough/skip-class-addicted"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIFactory.style_label(body, 18, Color.WHITE)
	content.add_child(body)

	var back := Button.new()
	back.text = "กลับเมนู • BACK TO MENU"
	UIFactory.style_button(back)
	back.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		get_tree().change_scene_to_file("res://game/main_menu.tscn")
	)
	content.add_child(back)
