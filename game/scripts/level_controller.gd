class_name SkipClassLevel
extends Node2D

const LEVELS := {
	1: {
		"title": "ด่าน 1 • ทางเดินอาคารเรียน",
		"subtitle": "HALLWAY — หลบครูเวรและใช้ตู้เป็นที่ซ่อน",
		"time": 60.0,
		"width": 2450.0,
		"objective": "ผ่านทางเดินและไปถึงบันได EXIT",
		"intro": "ครูเวรกำลังเดินตรวจ! กด E เพื่อเข้า/ออกตู้ และกด Space ซ้ำเพื่อ Double Jump\nย่อด้วย S จะถูกมองเห็นยากขึ้น — วิ่งเร็วแต่ครูได้ยิน",
	},
	2: {
		"title": "ด่าน 2 • โรงอาหาร",
		"subtitle": "CAFETERIA — ใช้เสียงและขนมล่อหัวหน้าห้อง",
		"time": 75.0,
		"width": 2850.0,
		"objective": "หาเหรียญ ซื้อขนม แล้วผ่านประตูโรงอาหาร",
		"intro": "เก็บเหรียญ 10 บาท → กด E ที่ตู้ขายขนม → กด Q เพื่อโยนขนมล่อ NPC\nหรือย่อเดินตามเส้นทางเงียบด้านล่าง",
	},
	3: {
		"title": "ด่าน 3 • ห้องสมุด",
		"subtitle": "LIBRARY — หลบ CCTV ใช้ข้ออ้าง และหากุญแจ",
		"time": 90.0,
		"width": 3150.0,
		"objective": "หา Homework ผ่านหัวหน้าห้อง แล้วใช้ Storage Key เปิด EXIT",
		"intro": "หลบลำแสง CCTV เก็บการบ้านปลอมและตอบคำถามให้ถูก\nจากนั้นค้นหากุญแจห้องเก็บของเพื่อเปิดทางออก",
	},
}
const WORLD_PROP_SCRIPT: Script = preload("res://game/scripts/world_prop.gd")

@export_range(1, 3) var level_index := 1

var level_data: Dictionary
var player: SkipClassPlayer
var hud: GameHUD
var guards: Array[SchoolGuard] = []
var interactables: Array[Dictionary] = []
var _nearest: Dictionary = {}
var _dialogue_done := false
var _dialogue_open := false
var _ending := false
var _world_width := 2450.0
var _camera: Camera2D
var _active_hide_spot: Dictionary = {}
var _dialogue_triggered := false


func _ready() -> void:
	level_data = LEVELS[level_index]
	_world_width = level_data.width
	GameState.start_level(level_index, level_data.time, level_data.objective)
	_build_world()
	_build_player()
	_build_level_content()
	_build_hud()
	GameState.caught.connect(_on_caught)
	GameState.level_completed.connect(_on_level_completed)
	AudioManager.start_music()
	hud.show_intro(level_data.title, "%s\n\n%s" % [level_data.subtitle, level_data.intro])
	player.controls_enabled = false
	call_deferred("_capture_if_requested")


func _process(delta: float) -> void:
	GameState.tick(delta)
	_update_interaction_prompt()
	if player.global_position.y > 780.0:
		GameState.catch_player("ตกจากทางเดิน! กลับมาเริ่มใหม่")
	if level_index == 3 and not _dialogue_done and not _dialogue_triggered and player.global_position.x > 1390.0 and not _dialogue_open:
		_open_dialogue()


func _build_world() -> void:
	var background := ColorRect.new()
	background.color = _level_color("sky")
	background.position = Vector2(-300, -200)
	background.size = Vector2(_world_width + 600, 950)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var back_wall := ColorRect.new()
	back_wall.color = _level_color("wall")
	back_wall.position = Vector2(0, 90)
	back_wall.size = Vector2(_world_width, 430)
	background.add_child(back_wall)

	for index in int(_world_width / 260.0):
		_draw_window(background, Vector2(80 + index * 260, 155), index)
	_draw_school_sign(background)
	_add_static_rect(Vector2(_world_width * 0.5, 585), Vector2(_world_width, 130), _level_color("floor"), "พื้นทางเดิน")
	_add_static_rect(Vector2(-55, 320), Vector2(110, 650), Color("172238"), "กำแพงซ้าย")
	_add_static_rect(Vector2(_world_width + 55, 320), Vector2(110, 650), Color("172238"), "กำแพงขวา")
	_build_parallax_decor()


func _build_player() -> void:
	player = SkipClassPlayer.new()
	player.position = Vector2(105, 515)
	add_child(player)
	player.noise_emitted.connect(_on_player_noise)
	player.interact_requested.connect(_on_interact)
	player.item_use_requested.connect(_on_use_item)
	_camera = Camera2D.new()
	_camera.position = Vector2(160, -70)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 5.5
	_camera.limit_left = 0
	_camera.limit_right = int(_world_width)
	_camera.limit_top = 0
	_camera.limit_bottom = 648
	player.add_child(_camera)


func _build_level_content() -> void:
	match level_index:
		1:
			_build_hallway()
		2:
			_build_cafeteria()
		3:
			_build_library()


func _build_hud() -> void:
	hud = GameHUD.new()
	add_child(hud)
	hud.bind_player(player)
	hud.intro_closed.connect(func() -> void:
		player.controls_enabled = true
		GameState.begin_countdown()
	)
	hud.dialogue_answered.connect(_on_dialogue_answered)


func _build_hallway() -> void:
	_add_guard(790, 500, 1090, "ครูเวร", Color("73446f"))
	_add_guard(1740, 1490, 1960, "ครูฝ่ายปกครอง", Color("8b3a4b"))
	_add_hide_spot(Vector2(565, 520), "ตู้เก็บอุปกรณ์")
	_add_hide_spot(Vector2(1290, 520), "ตู้ล็อกเกอร์")
	_add_platform(Vector2(1060, 430), Vector2(260, 24), Color("3c5577"))
	_add_platform(Vector2(1280, 345), Vector2(180, 24), Color("3c5577"))
	_add_platform(Vector2(1460, 430), Vector2(220, 24), Color("3c5577"))
	_add_decor_table(Vector2(1060, 540), "โต๊ะการบ้าน")
	_add_exit(Vector2(2280, 510), "บันไดหนีเรียน", "")


func _build_cafeteria() -> void:
	_add_guard(1250, 1010, 1510, "หัวหน้าห้อง", Color("315a7d"))
	_add_guard(2210, 2010, 2450, "ครูโรงอาหาร", Color("73446f"))
	_add_pickup(Vector2(520, 510), "coin", "เหรียญ 10 บาท")
	_add_vending_machine(Vector2(900, 485))
	_add_hide_spot(Vector2(1640, 520), "เคาน์เตอร์อาหาร")
	for x in [390.0, 720.0, 1110.0, 1770.0, 2090.0]:
		_add_decor_table(Vector2(x, 540), "โต๊ะโรงอาหาร")
	_add_platform(Vector2(1820, 405), Vector2(300, 22), Color("4b6687"))
	_add_platform(Vector2(2110, 330), Vector2(220, 22), Color("4b6687"))
	_add_exit(Vector2(2700, 510), "ประตูหลังโรงอาหาร", "")


func _build_library() -> void:
	_add_guard(1040, 780, 1280, "บรรณารักษ์", Color("5e4b8b"))
	_add_guard(2030, 1840, 2210, "ครูห้องสมุด", Color("73446f"))
	_add_camera(Vector2(720, 125), 0.0)
	_add_camera(Vector2(2320, 125), 2.2)
	_add_pickup(Vector2(510, 510), "homework", "การบ้านปลอม")
	_add_pickup(Vector2(2520, 510), "storage_key", "Storage Key")
	_add_hide_spot(Vector2(430, 520), "โต๊ะอ่านหนังสือ")
	_add_hide_spot(Vector2(1720, 520), "ชั้นหนังสือ")
	for x in [700.0, 1450.0, 1760.0, 2350.0]:
		_add_bookshelf(Vector2(x, 500))
	_add_platform(Vector2(2380, 395), Vector2(330, 22), Color("5f5275"))
	_add_exit(Vector2(3010, 510), "ประตูห้องเก็บของ", "storage_key")


func _add_guard(x: float, left: float, right: float, role: String, color: Color) -> void:
	var guard := SchoolGuard.new()
	guard.position = Vector2(x, 515)
	add_child(guard)
	guard.configure(player, left, right, role, color)
	guards.append(guard)


func _add_camera(position_value: Vector2, phase: float) -> void:
	var camera := SecurityCamera.new()
	camera.position = position_value
	add_child(camera)
	camera.configure(player, phase)


func _add_static_rect(center: Vector2, size: Vector2, color: Color, label: String = "") -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([Vector2(-size.x / 2, -size.y / 2), Vector2(size.x / 2, -size.y / 2), Vector2(size.x / 2, size.y / 2), Vector2(-size.x / 2, size.y / 2)])
	polygon.color = color
	body.add_child(polygon)
	if not label.is_empty():
		body.set_meta("label", label)
	add_child(body)
	return body


func _add_platform(center: Vector2, size: Vector2, color: Color) -> void:
	_add_static_rect(center, size, color)


func _add_hide_spot(center: Vector2, label: String) -> void:
	var decor := Node2D.new()
	decor.position = center
	decor.set_script(WORLD_PROP_SCRIPT)
	decor.call("configure", "locker", label, Color("315a7d"))
	add_child(decor)
	interactables.append({"node": decor, "kind": "hide", "label": label, "radius": 115.0})


func _add_pickup(center: Vector2, item_id: String, label: String) -> void:
	var prop := Node2D.new()
	prop.position = center
	prop.set_script(WORLD_PROP_SCRIPT)
	prop.call("configure", item_id, label, Color("ffe08a"))
	add_child(prop)
	interactables.append({"node": prop, "kind": "pickup", "item": item_id, "label": label, "radius": 95.0})


func _add_vending_machine(center: Vector2) -> void:
	var prop := Node2D.new()
	prop.position = center
	prop.set_script(WORLD_PROP_SCRIPT)
	prop.call("configure", "vending", "ตู้ขายขนม", Color("d45555"))
	add_child(prop)
	interactables.append({"node": prop, "kind": "vending", "label": "ตู้ขายขนม", "radius": 120.0})


func _add_exit(center: Vector2, label: String, required_item: String) -> void:
	var prop := Node2D.new()
	prop.position = center
	prop.set_script(WORLD_PROP_SCRIPT)
	prop.call("configure", "exit", label, Color("35a879"))
	add_child(prop)
	interactables.append({"node": prop, "kind": "exit", "item": required_item, "label": label, "radius": 125.0})


func _add_decor_table(center: Vector2, label: String) -> void:
	var prop := Node2D.new()
	prop.position = center
	prop.set_script(WORLD_PROP_SCRIPT)
	prop.call("configure", "table", label, Color("8b633f"))
	add_child(prop)


func _add_bookshelf(center: Vector2) -> void:
	var prop := Node2D.new()
	prop.position = center
	prop.set_script(WORLD_PROP_SCRIPT)
	prop.call("configure", "bookshelf", "ชั้นหนังสือ", Color("735237"))
	add_child(prop)


func _update_interaction_prompt() -> void:
	if hud == null or _ending or _dialogue_open:
		return
	if player.is_hidden and not _active_hide_spot.is_empty():
		_nearest = _active_hide_spot
		hud.set_prompt("E / Space  ออกจากที่ซ่อน • %s" % _active_hide_spot.label)
		return
	_nearest = {}
	var nearest_distance := INF
	for item in interactables:
		var node := item.node as Node2D
		if not is_instance_valid(node) or not node.visible:
			continue
		var distance := player.global_position.distance_to(node.global_position)
		if distance <= float(item.radius) and distance < nearest_distance:
			_nearest = item
			nearest_distance = distance
	if _nearest.is_empty():
		hud.set_prompt("Q ใช้ %s" % GameState.item_display_name(GameState.selected_item()) if not GameState.selected_item().is_empty() else "")
		return
	var action := "ออกจากที่ซ่อน" if _nearest.kind == "hide" and player.is_hidden else "โต้ตอบ"
	hud.set_prompt("E  %s • %s" % [action, _nearest.label])


func _on_interact() -> void:
	if _ending:
		return
	if player.is_hidden:
		player.set_hidden(false)
		GameState.grant_stealth_grace(1.8)
		_active_hide_spot = {}
		AudioManager.play_sfx("door")
		return
	if _nearest.is_empty():
		return
	match String(_nearest.kind):
		"hide":
			_active_hide_spot = _nearest
			player.set_hidden(true)
			GameState.set_suspicion(maxf(0.0, GameState.suspicion - 45.0))
			AudioManager.play_sfx("door")
		"pickup":
			if GameState.add_item(_nearest.item):
				AudioManager.play_sfx("pickup")
				_nearest.node.visible = false
				if _nearest.item == "coin":
					GameState.set_objective("นำเหรียญไปซื้อขนมที่ตู้สีแดง")
				elif _nearest.item == "homework":
					GameState.set_objective("ใช้ Homework ตอบหัวหน้าห้อง แล้วหากุญแจ")
				elif _nearest.item == "storage_key":
					GameState.set_objective("นำ Storage Key ไปเปิดประตู EXIT")
		"vending":
			if GameState.consume_item("coin"):
				GameState.add_item("snack")
				AudioManager.play_sfx("pickup")
				GameState.set_objective("กด Q โยนขนมล่อ NPC แล้วไปที่ EXIT")
			else:
				hud.set_prompt("ต้องมีเหรียญ 10 บาทก่อน")
		"exit":
			var required := String(_nearest.get("item", ""))
			if level_index == 3 and not _dialogue_done:
				hud.set_prompt("ต้องผ่านหัวหน้าห้องก่อน")
			elif not required.is_empty() and not GameState.has_item(required):
				hud.set_prompt("ประตูล็อก — ต้องใช้ %s" % GameState.item_display_name(required))
			else:
				if not required.is_empty():
					GameState.consume_item(required)
				AudioManager.play_sfx("door")
				GameState.complete_level()


func _on_use_item() -> void:
	if GameState.selected_item() != "snack":
		return
	GameState.consume_item("snack")
	var target := player.global_position + Vector2(player.facing * 420.0, 0)
	for guard in guards:
		guard.hear_noise(target, 720.0)
	AudioManager.play_sfx("pickup")
	GameState.set_objective("NPC ถูกล่อแล้ว! รีบไปที่ EXIT")


func _on_player_noise(position_value: Vector2, radius: float) -> void:
	for guard in guards:
		guard.hear_noise(position_value, radius)


func _open_dialogue() -> void:
	_dialogue_triggered = true
	_dialogue_open = true
	player.controls_enabled = false
	player.clear_virtual_actions()
	player.velocity = Vector2.ZERO
	hud.show_dialogue("หัวหน้าห้องมายด์", "มายด์: น็อต! มาทำอะไรในห้องสมุดตอนเข้าเรียน?", ["ครูใช้ให้เอาการบ้านมาคืน", "มาหาที่งีบ เงียบดี"])


func _on_dialogue_answered(choice: int) -> void:
	if not _dialogue_open:
		return
	_dialogue_open = false
	_dialogue_done = choice == 0 and GameState.has_item("homework")
	if _dialogue_done:
		GameState.consume_item("homework")
		AudioManager.play_sfx("complete")
		GameState.set_objective("ข้ออ้างผ่านแล้ว — หา Storage Key และไป EXIT")
	else:
		_dialogue_triggered = false
		GameState.add_suspicion(20.0)
		player.position.x = 1270.0
		GameState.set_objective("ข้ออ้างยังไม่เนียน — หา Homework ก่อนกลับมา")
	player.controls_enabled = true


func _on_caught(reason: String) -> void:
	if _ending:
		return
	_ending = true
	player.set_caught()
	AudioManager.play_sfx("caught")
	hud.show_message("ถูกจับได้! • CAUGHT", "%s\n\nกำลังเริ่มด่านนี้ใหม่..." % reason)
	await get_tree().create_timer(1.7).timeout
	get_tree().reload_current_scene()


func _on_level_completed(completed_index: int) -> void:
	if completed_index != level_index or _ending:
		return
	_ending = true
	player.controls_enabled = false
	AudioManager.play_sfx("complete")
	var remaining := GameState.format_time()
	if level_index < 3:
		hud.show_message("ผ่านด่าน! • LEVEL COMPLETE", "เหลือเวลา %s\nกำลังไปด่านต่อไป..." % remaining)
		await get_tree().create_timer(1.6).timeout
		get_tree().change_scene_to_file("res://game/levels/level_%02d.tscn" % (level_index + 1))
	else:
		GameState.demo_completed = true
		hud.show_message("หนีเรียนสำเร็จ! • DEMO COMPLETE", "น็อตไปถึงทางออกก่อนระฆังดัง\nขอบคุณที่เล่นเดโม 3 ด่าน!")
		await get_tree().create_timer(2.4).timeout
		get_tree().change_scene_to_file("res://game/credits.tscn")


func _draw_window(parent: Control, at: Vector2, index: int) -> void:
	var window := ColorRect.new()
	window.color = Color("79c8db") if index % 2 == 0 else Color("a9dce5")
	window.position = at
	window.size = Vector2(125, 155)
	parent.add_child(window)
	var frame := ColorRect.new()
	frame.color = Color("263752")
	frame.position = Vector2(58, 0)
	frame.size = Vector2(9, 155)
	window.add_child(frame)


func _draw_school_sign(parent: Control) -> void:
	var sign := Label.new()
	sign.text = "โรงเรียนสาธิตขอนแก่น • DEMONSTRATION SCHOOL"
	sign.position = Vector2(330, 108)
	sign.size = Vector2(720, 45)
	UIFactory.style_label(sign, 22, Color("172238"))
	parent.add_child(sign)


func _build_parallax_decor() -> void:
	for x in range(180, int(_world_width), 420):
		var stripe := Polygon2D.new()
		stripe.polygon = PackedVector2Array([Vector2(x, 90), Vector2(x + 35, 90), Vector2(x + 215, 520), Vector2(x + 180, 520)])
		stripe.color = Color(1, 1, 1, 0.045)
		add_child(stripe)


func _level_color(kind: String) -> Color:
	var palettes := {
		1: {"sky": Color("15213b"), "wall": Color("e8c892"), "floor": Color("35445e")},
		2: {"sky": Color("18344a"), "wall": Color("efb76f"), "floor": Color("3b5363")},
		3: {"sky": Color("211b3b"), "wall": Color("c3a6c9"), "floor": Color("3c3555")},
	}
	return palettes[level_index][kind]


func _capture_if_requested() -> void:
	if not OS.has_feature("editor"):
		return
	var capture_path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_path = argument.trim_prefix("--capture=")
	if capture_path.is_empty():
		return
	for frame in 20:
		await get_tree().process_frame
	var absolute := ProjectSettings.globalize_path(capture_path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	get_viewport().get_texture().get_image().save_png(absolute)
