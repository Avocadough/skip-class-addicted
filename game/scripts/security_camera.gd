class_name SecurityCamera
extends Node2D

var player: SkipClassPlayer
var sweep_offset := 0.0
var range := 360.0
var _time := 0.0
var _detected := false


func configure(target_player: SkipClassPlayer, phase: float = 0.0) -> void:
	player = target_player
	sweep_offset = phase


func _process(delta: float) -> void:
	_time += delta
	_detected = _can_see_player()
	if _detected:
		GameState.report_detection(7.0 * delta)
	queue_redraw()


func _direction() -> Vector2:
	var angle := sin(_time * 0.85 + sweep_offset) * 0.82
	return Vector2(sin(angle), cos(angle)).normalized()


func _can_see_player() -> bool:
	if player == null or player.is_hidden or not GameState.level_active:
		return false
	var target := player.global_position + Vector2(0, -42)
	var offset := target - global_position
	if offset.length() > range or offset.y < 0.0:
		return false
	if player.is_crouching and offset.length() > 170.0:
		return false
	if _direction().dot(offset.normalized()) < cos(0.3):
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, target, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _draw() -> void:
	var direction := _direction()
	var perpendicular := direction.rotated(PI * 0.5)
	var width := 140.0
	var color := Color("ff315f55") if _detected else Color("ffe08a22")
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO, direction * range + perpendicular * width, direction * range - perpendicular * width]), color)
	draw_circle(Vector2.ZERO, 14, Color("111728"))
	draw_rect(Rect2(-20, -10, 32, 20), Color("64748b"))
	draw_circle(Vector2(11, 0), 6, Color("ff4d6d") if _detected else Color("72e0d1"))
	draw_line(Vector2(-8, -10), Vector2(-18, -25), Color("111728"), 6)
