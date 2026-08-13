class_name UIFactory
extends RefCounted

const FONT_PATH := "res://Assets/Fonts/Kodchasan-Bold.ttf"


static func font() -> Font:
	return load(FONT_PATH) as Font


static func panel(color := Color("18233b"), radius := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("f3c969")
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


static func button_style(color: Color, hover: Color) -> Dictionary:
	var normal := panel(color, 8)
	normal.border_color = color.lightened(0.32)
	var over := panel(hover, 8)
	over.border_color = Color("fff0a8")
	var pressed := panel(color.darkened(0.18), 8)
	pressed.border_color = Color.WHITE
	return {"normal": normal, "hover": over, "pressed": pressed}


static func style_button(button: Button, color := Color("246b8e"), font_size := 22) -> void:
	var styles := button_style(color, color.lightened(0.12))
	button.add_theme_stylebox_override("normal", styles.normal)
	button.add_theme_stylebox_override("hover", styles.hover)
	button.add_theme_stylebox_override("pressed", styles.pressed)
	button.add_theme_stylebox_override("focus", styles.hover)
	button.add_theme_font_override("font", font())
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.custom_minimum_size = Vector2(260, 52)


static func style_label(label: Label, size := 24, color := Color.WHITE) -> void:
	label.add_theme_font_override("font", font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("101626"))
	label.add_theme_constant_override("outline_size", 5)
