class_name DeathScreen
extends Control
## "YOU DIED" with a Retry button (R works too). Retry reloads the current scene, so you try
## again from the start of the part you died in. Add it hidden, then call show_death().

## Colour of the big title: frost white for freezing, blood red for bleeding out.
var title_color: Color = GameFonts.FROST
var _shown := false


func _init(color: Color = GameFonts.FROST) -> void:
	title_color = color
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _ready() -> void:
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 34)
	add_child(column)
	column.add_child(GameUI.label("YOU DIED", GameFonts.title(18), 80, title_color))
	var retry := GameUI.button("RETRY", 220.0)
	retry.pressed.connect(_retry)
	column.add_child(retry)


## Fades the screen in after a moment, frees the mouse and focuses Retry.
func show_death(delay: float = 1.0) -> void:
	_shown = true
	visible = true
	modulate.a = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 1.5)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var retry := find_children("*", "Button", true, false)[0] as Button
	retry.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if _shown and event.is_action_pressed("restart"):
		_retry()


func _retry() -> void:
	get_tree().reload_current_scene()
