extends CanvasLayer
## Crosshair, interaction prompt with a hold-progress bar, and the fade to black when the
## player crawls into shelter.

@export var player: NodePath

var _prompt: Label
var _progress: ProgressBar
var _fade: ColorRect


func _ready() -> void:
	var crosshair := ColorRect.new()
	crosshair.color = Color(1, 1, 1, 0.6)
	crosshair.size = Vector2(4, 4)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position -= crosshair.size * 0.5
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crosshair)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.position.y -= 120
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)

	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	box.add_child(_prompt)

	_progress = ProgressBar.new()
	_progress.custom_minimum_size = Vector2(220, 8)
	_progress.max_value = 1.0
	_progress.show_percentage = false
	box.add_child(_progress)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)

	_show_prompt("", -1.0)
	var p := get_node_or_null(player)
	if p:
		p.interaction_changed.connect(_show_prompt)
		p.entering_shelter.connect(_fade_out)


func _show_prompt(text: String, progress: float) -> void:
	_prompt.text = text
	_prompt.visible = text != ""
	_progress.visible = progress >= 0.0
	_progress.value = maxf(progress, 0.0)


func _fade_out(duration: float) -> void:
	# Black for the last part of the crawl, as you squeeze into the dark.
	var tween := create_tween()
	tween.tween_interval(duration * 0.45)
	tween.tween_property(_fade, "modulate:a", 1.0, duration * 0.55)
