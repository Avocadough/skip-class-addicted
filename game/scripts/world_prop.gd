extends Node2D

var kind := ""
var label := ""
var color := Color.WHITE


func configure(prop_kind: String, display_label: String, display_color: Color) -> void:
	kind = prop_kind
	label = display_label
	color = display_color
	queue_redraw()


func _draw() -> void:
	var outline := Color("111728")
	match kind:
		"locker":
			draw_rect(Rect2(-43, -118, 86, 118), outline)
			draw_rect(Rect2(-38, -113, 76, 108), color)
			draw_line(Vector2(0, -110), Vector2(0, -5), outline, 5)
			draw_circle(Vector2(-9, -55), 3, Color("ffe08a"))
			draw_circle(Vector2(9, -55), 3, Color("ffe08a"))
		"coin":
			draw_circle(Vector2(0, -30), 18, outline)
			draw_circle(Vector2(0, -30), 14, color)
			draw_string(UIFactory.font(), Vector2(-10, -23), "10", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, outline)
		"homework":
			draw_rect(Rect2(-25, -45, 50, 38), outline)
			draw_rect(Rect2(-21, -41, 42, 30), Color("f7f1df"))
			draw_line(Vector2(-15, -32), Vector2(12, -32), Color("315a7d"), 3)
			draw_line(Vector2(-15, -23), Vector2(5, -23), Color("315a7d"), 3)
		"storage_key":
			draw_circle(Vector2(-10, -30), 12, outline, false, 6)
			draw_line(Vector2(1, -30), Vector2(28, -30), outline, 7)
			draw_line(Vector2(20, -30), Vector2(20, -18), outline, 6)
		"vending":
			draw_rect(Rect2(-50, -145, 100, 145), outline)
			draw_rect(Rect2(-44, -139, 88, 133), color)
			draw_rect(Rect2(-31, -119, 48, 65), Color("c7f0ef"))
			draw_rect(Rect2(24, -118, 11, 33), Color("ffe08a"))
			draw_rect(Rect2(-25, -32, 50, 15), outline)
		"exit":
			draw_rect(Rect2(-49, -138, 98, 138), outline)
			draw_rect(Rect2(-43, -132, 86, 132), color)
			draw_rect(Rect2(-30, -105, 60, 36), Color("d9f5e6"))
			draw_string(UIFactory.font(), Vector2(-22, -81), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("12352b"))
			draw_circle(Vector2(25, -55), 5, Color("ffe08a"))
		"table":
			draw_rect(Rect2(-65, -58, 130, 16), outline)
			draw_rect(Rect2(-60, -54, 120, 10), color)
			draw_line(Vector2(-48, -44), Vector2(-52, 0), outline, 9)
			draw_line(Vector2(48, -44), Vector2(52, 0), outline, 9)
		"bookshelf":
			draw_rect(Rect2(-58, -150, 116, 150), outline)
			draw_rect(Rect2(-52, -144, 104, 138), color)
			for row in 3:
				draw_rect(Rect2(-46, -133 + row * 43, 92, 30), Color("263752"))
				for book in 5:
					var colors := [Color("d45555"), Color("e0a64b"), Color("3aa17e"), Color("567bb4")]
					draw_rect(Rect2(-42 + book * 18, -128 + row * 43, 12, 25), colors[(book + row) % colors.size()])
