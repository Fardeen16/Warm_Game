class_name GameUI
extends RefCounted
## Shared look for menus and screens: frost-white text and outlined buttons that fill white
## when hovered.


static func label(text: String, font: Font, size: int, color: Color = GameFonts.FROST) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


static func button(text: String, width: float = 250.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 54)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", GameFonts.label(7))
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", GameFonts.FROST)
	b.add_theme_color_override("font_hover_color", Color(0.05, 0.07, 0.1))
	b.add_theme_color_override("font_pressed_color", Color(0.05, 0.07, 0.1))
	b.add_theme_color_override("font_focus_color", GameFonts.FROST)
	b.add_theme_stylebox_override("normal", _box(Color(0.0, 0.0, 0.0, 0.25), Color(GameFonts.FROST, 0.7)))
	b.add_theme_stylebox_override("hover", _box(Color(GameFonts.FROST, 0.92), GameFonts.FROST))
	b.add_theme_stylebox_override("pressed", _box(Color(GameFonts.FROST, 0.75), GameFonts.FROST))
	b.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), Color(GameFonts.FROST, 0.9)))
	return b


static func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_content_margin_all(10)
	return box
