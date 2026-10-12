class_name Captions
extends CanvasLayer
## Dialogue captions at the bottom of the screen, on a PSX UI text box. Lines are typed out one
## at a time, held for a moment, then the next one appears. E, Space or a click skips ahead.
## Use: await captions.say(["First line", "Second line"])

signal finished

## Text box image from the PSX UI pack (any of the Skin0X-Cropped_Text-Block images).
@export var box_texture: Texture2D = preload("res://assets/ui/psx_ui/fullres_720p/Skin01-Cropped_Text-Block.png")
@export var text_color: Color = Color(0.92, 0.86, 0.8)
@export var font_size: int = 22
## How fast lines are typed out.
@export_range(5.0, 200.0, 1.0) var characters_per_second: float = 38.0
## Seconds a line stays on screen once fully typed.
@export_range(0.2, 10.0, 0.1) var hold_time: float = 2.2

var _box: TextureRect
var _label: Label
var _skip := false
var _speaking := false


func _ready() -> void:
	layer = 20
	_box = TextureRect.new()
	_box.texture = box_texture
	_box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_box.stretch_mode = TextureRect.STRETCH_SCALE
	_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_box.offset_left = -330
	_box.offset_right = 330
	_box.offset_top = -130
	_box.offset_bottom = -38
	_box.modulate.a = 0.0
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 36
	_label.offset_right = -36
	_label.offset_top = 14
	_label.offset_bottom = -14
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_box.add_child(_label)


func is_speaking() -> bool:
	return _speaking


## Shows the lines one after another; finishes (and emits finished) when the last one is gone.
func say(lines: PackedStringArray) -> void:
	_speaking = true
	await _fade(1.0)
	for line in lines:
		_skip = false
		_label.text = line
		_label.visible_ratio = 0.0
		var type_time := maxf(line.length() / characters_per_second, 0.01)
		while _label.visible_ratio < 1.0:
			if _skip:
				_label.visible_ratio = 1.0
				_skip = false
				break
			_label.visible_ratio = minf(_label.visible_ratio + get_process_delta_time() / type_time, 1.0)
			await get_tree().process_frame
		var held := 0.0
		while held < hold_time and not _skip:
			held += get_process_delta_time()
			await get_tree().process_frame
	await _fade(0.0)
	_speaking = false
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _speaking:
		return
	var pressed: bool = event.is_action_pressed("interact") or event.is_action_pressed("jump") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if pressed:
		_skip = true
		get_viewport().set_input_as_handled()


func _fade(to: float) -> void:
	var tween := create_tween()
	tween.tween_property(_box, "modulate:a", to, 0.3)
	await tween.finished
