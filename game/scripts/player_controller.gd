class_name SkipClassPlayer
extends CharacterBody2D

signal interact_requested
signal item_use_requested
signal noise_emitted(world_position: Vector2, radius: float)

enum PlayerState { IDLE, WALK, RUN, JUMP, CROUCH, HIDE, CAUGHT, DISABLED }

const WALK_SPEED := 155.0
const RUN_SPEED := 245.0
const CROUCH_SPEED := 82.0
const JUMP_VELOCITY := -430.0
const GRAVITY := 1200.0

var state := PlayerState.IDLE
var is_hidden := false
var is_crouching := false
var controls_enabled := true
var facing := 1.0
var _noise_cooldown := 0.0
var _virtual: Dictionary = {}
var _was_on_floor := false


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 18.0
	capsule.height = 68.0
	shape.position = Vector2(0, -34)
	shape.shape = capsule
	add_child(shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_noise_cooldown = maxf(0.0, _noise_cooldown - delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if not controls_enabled or is_hidden:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		if is_hidden:
			state = PlayerState.HIDE
		move_and_slide()
		return

	var axis := Input.get_axis("move_left", "move_right")
	axis += float(_virtual.get("move_right", false)) - float(_virtual.get("move_left", false))
	axis = clampf(axis, -1.0, 1.0)
	is_crouching = Input.is_action_pressed("crouch") or bool(_virtual.get("crouch", false))
	var running := (Input.is_action_pressed("run") or bool(_virtual.get("run", false))) and not is_crouching
	var speed := CROUCH_SPEED if is_crouching else (RUN_SPEED if running else WALK_SPEED)
	velocity.x = move_toward(velocity.x, axis * speed, 1300.0 * delta)
	if absf(axis) > 0.01:
		facing = signf(axis)

	if _just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY
		AudioManager.play_sfx("jump")
		noise_emitted.emit(global_position, 105.0)

	if _just_pressed("interact"):
		interact_requested.emit()
	if _just_pressed("use_item"):
		item_use_requested.emit()
	if Input.is_action_just_pressed("slot_1"):
		GameState.select_slot(0)
	elif Input.is_action_just_pressed("slot_2"):
		GameState.select_slot(1)
	elif Input.is_action_just_pressed("slot_3"):
		GameState.select_slot(2)

	move_and_slide()
	if is_on_floor() and not _was_on_floor and velocity.y >= 0.0:
		noise_emitted.emit(global_position, 145.0)
	_was_on_floor = is_on_floor()

	if not is_on_floor():
		state = PlayerState.JUMP
	elif is_crouching:
		state = PlayerState.CROUCH
	elif absf(velocity.x) < 8.0:
		state = PlayerState.IDLE
	elif running:
		state = PlayerState.RUN
		if _noise_cooldown <= 0.0:
			noise_emitted.emit(global_position, 265.0)
			_noise_cooldown = 0.42
	else:
		state = PlayerState.WALK
	queue_redraw()


func _draw() -> void:
	var alpha := 0.42 if is_hidden else 1.0
	var crouch_offset := 15.0 if is_crouching else 0.0
	var uniform := Color(0.93, 0.96, 1.0, alpha)
	var shorts := Color(0.12, 0.23, 0.42, alpha)
	var skin := Color(0.79, 0.56, 0.38, alpha)
	var hair := Color(0.10, 0.07, 0.06, alpha)
	var outline := Color(0.04, 0.06, 0.11, alpha)
	draw_circle(Vector2(0, -72 + crouch_offset), 16, outline)
	draw_circle(Vector2(0, -72 + crouch_offset), 13, skin)
	draw_arc(Vector2(0, -76 + crouch_offset), 13, PI, TAU, 18, hair, 7)
	draw_rect(Rect2(-16, -58 + crouch_offset, 32, 35), outline)
	draw_rect(Rect2(-13, -55 + crouch_offset, 26, 29), uniform)
	draw_rect(Rect2(-13, -29 + crouch_offset, 26, 17), shorts)
	draw_line(Vector2(-8, -12 + crouch_offset), Vector2(-10, 0), outline, 8)
	draw_line(Vector2(8, -12 + crouch_offset), Vector2(10, 0), outline, 8)
	draw_line(Vector2(13 * facing, -49 + crouch_offset), Vector2(24 * facing, -34 + crouch_offset), skin, 7)
	draw_circle(Vector2(7 * facing, -72 + crouch_offset), 2.2, Color("141821"))
	if state == PlayerState.RUN:
		draw_line(Vector2(-22 * facing, -52), Vector2(-34 * facing, -52), Color("72e0d1aa"), 4)


func set_hidden(value: bool) -> void:
	is_hidden = value
	if value:
		velocity = Vector2.ZERO
	queue_redraw()


func set_caught() -> void:
	controls_enabled = false
	state = PlayerState.CAUGHT
	velocity = Vector2.ZERO
	queue_redraw()


func set_virtual_action(action: String, pressed: bool) -> void:
	_virtual[action] = pressed


func _just_pressed(action: String) -> bool:
	if Input.is_action_just_pressed(action):
		return true
	var key := "%s_just" % action
	if bool(_virtual.get(key, false)):
		_virtual[key] = false
		return true
	return false


func virtual_tap(action: String) -> void:
	_virtual["%s_just" % action] = true
