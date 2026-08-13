class_name SchoolGuard
extends CharacterBody2D

enum AIState { PATROL, INVESTIGATE, CHASE, RETURN }

var player: SkipClassPlayer
var patrol_left := 0.0
var patrol_right := 0.0
var role := "ครูเวร"
var uniform_color := Color("73446f")
var facing := -1.0
var state := AIState.PATROL
var vision_range := 310.0
var patrol_speed := 48.0
var chase_speed := 96.0
var _target_x := 0.0
var _last_seen := 0.0
var _alert_flash := 0.0


func configure(target_player: SkipClassPlayer, left: float, right: float, display_role: String, color: Color) -> void:
	player = target_player
	patrol_left = left
	patrol_right = right
	role = display_role
	uniform_color = color
	_target_x = left


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 17
	capsule.height = 70
	collision.position = Vector2(0, -35)
	collision.shape = capsule
	add_child(collision)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += 1200.0 * delta
	_alert_flash = maxf(0.0, _alert_flash - delta)
	var can_see := _can_see_player()
	if can_see:
		state = AIState.CHASE
		_last_seen = 0.5
		_target_x = player.global_position.x
		_alert_flash = 0.12
		GameState.report_detection(9.0 * delta)
	elif state == AIState.CHASE:
		_last_seen -= delta
		if _last_seen <= 0.0:
			state = AIState.INVESTIGATE
	elif state == AIState.INVESTIGATE and absf(global_position.x - _target_x) < 18.0:
		state = AIState.RETURN
	elif state == AIState.RETURN and global_position.x >= patrol_left and global_position.x <= patrol_right:
		state = AIState.PATROL

	var speed := patrol_speed
	if state == AIState.PATROL:
		if global_position.x <= patrol_left + 8.0:
			facing = 1.0
		elif global_position.x >= patrol_right - 8.0:
			facing = -1.0
		velocity.x = facing * patrol_speed
	elif state == AIState.CHASE or state == AIState.INVESTIGATE:
		facing = signf(_target_x - global_position.x) if absf(_target_x - global_position.x) > 3.0 else facing
		speed = chase_speed if state == AIState.CHASE else patrol_speed * 1.15
		velocity.x = facing * speed
	else:
		var middle := (patrol_left + patrol_right) * 0.5
		facing = signf(middle - global_position.x)
		velocity.x = facing * patrol_speed
	move_and_slide()
	if player and not player.is_hidden and global_position.distance_to(player.global_position) < 42.0:
		GameState.report_detection(20.0 * delta)
	queue_redraw()


func hear_noise(noise_position: Vector2, radius: float) -> void:
	if global_position.distance_to(noise_position) > radius or state == AIState.CHASE:
		return
	state = AIState.INVESTIGATE
	_target_x = noise_position.x
	_alert_flash = 0.35
	AudioManager.play_sfx("alert")


func _can_see_player() -> bool:
	if player == null or player.is_hidden or not GameState.level_active:
		return false
	var eye := global_position + Vector2(0, -52)
	var target := player.global_position + Vector2(0, -42)
	var offset := target - eye
	if offset.length() > vision_range or absf(offset.y) > 175.0:
		return false
	if player.is_crouching and offset.length() > 130.0:
		return false
	if signf(offset.x) != facing or absf(offset.x) < 1.0:
		return false
	var query := PhysicsRayQueryParameters2D.create(eye, target, 1)
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _draw() -> void:
	var cone_color := Color("ff4d6d24") if state != AIState.CHASE else Color("ff315f55")
	var start := Vector2(0, -50)
	draw_colored_polygon(PackedVector2Array([start, Vector2(facing * vision_range, -205), Vector2(facing * vision_range, 85)]), cone_color)
	var outline := Color("111728")
	draw_circle(Vector2(0, -72), 16, outline)
	draw_circle(Vector2(0, -72), 13, Color("b97a56"))
	draw_rect(Rect2(-17, -58, 34, 45), outline)
	draw_rect(Rect2(-14, -55, 28, 39), uniform_color)
	draw_line(Vector2(-9, -14), Vector2(-10, 0), outline, 8)
	draw_line(Vector2(9, -14), Vector2(10, 0), outline, 8)
	draw_circle(Vector2(7 * facing, -72), 2.2, outline)
	if state == AIState.CHASE or _alert_flash > 0.0:
		draw_string(UIFactory.font(), Vector2(-10, -100), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("ffe08a"))


func get_state_name() -> String:
	return AIState.keys()[state]
