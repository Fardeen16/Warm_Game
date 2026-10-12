extends Node3D
## Scene 2: hiding inside the carcass in the dark. You're bleeding out: within time_limit
## seconds the screen fills with blood and you die, unless you tune the radio first. Once the
## radio is tuned, the call comes through and you crawl out to the next scene.

@export_range(10.0, 600.0, 1.0) var time_limit: float = 90.0
@export_file("*.tscn") var next_scene: String = "res://scenes/rescue.tscn"
## How far you can look around while lying here (degrees left/right, up/down).
@export var look_range: Vector2 = Vector2(6.0, 4.0)
@export var mouse_sensitivity: float = 0.002
## Where the radio's center sits in the right hand's own space: a little along the fingers
## and out from the palm, so the palm rests on the radio's right side (m).
@export var grip_center: Vector3 = Vector3(0.0, 0.05, 0.05)
## Flip which way up the radio sits in the hand if the thumb ends up behind it.
@export var grip_flip: bool = false

const OVERLAY_SHADER := preload("res://shaders/belly_overlay.gdshader")

@onready var _camera: Camera3D = $Camera3D
@onready var _radio: Radio = $Camera3D/Radio
@onready var _arms: FPArms = $Camera3D/Arms
@onready var _ambience: AudioStreamPlayer = $Ambience

var _elapsed := 0.0
var _dead := false
var _leaving := false
var _rest_rotation: Vector3
var _rest_position: Vector3
var _radio_rest: Transform3D
var _look := Vector2.ZERO
var _overlay_mat: ShaderMaterial
var _fade: ColorRect
var _hint: Label
var _death_screen: Control
var _ambience_playback: AudioStreamGeneratorPlayback
var _wind := 0.0
var _wind_time := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_rest_rotation = _camera.rotation
	_rest_position = _camera.position
	_radio_rest = _radio.transform
	_build_ui()
	_radio.knob_locked.connect(func(_i: int) -> void: _update_hint())
	_radio.solved.connect(_on_radio_solved)
	_update_hint()
	_start_ambience()
	# Fade in from the black of crawling inside.
	create_tween().tween_property(_fade, "modulate:a", 0.0, 2.0)


func _process(delta: float) -> void:
	if not _dead and not _radio.is_solved():
		_elapsed += delta
		if _elapsed >= time_limit:
			_die()
	var blood := clampf(_elapsed / time_limit, 0.0, 1.0)
	_overlay_mat.set_shader_parameter("blood", blood)
	_overlay_mat.set_shader_parameter("elapsed", _elapsed)
	_overlay_mat.set_shader_parameter("time_limit", time_limit)

	if not _leaving:
		# Shallow breathing, quicker as you weaken.
		var t := Time.get_ticks_msec() / 1000.0
		var breath := sin(t * lerpf(1.4, 2.6, blood))
		_camera.position = _rest_position + Vector3(0.0, breath * 0.006, 0.0)
		_camera.rotation = _rest_rotation + Vector3(deg_to_rad(_look.y), deg_to_rad(_look.x), breath * 0.004)
	_hold_radio()
	_feed_ambience()


## Keeps the radio where it was placed in the scene and moves the arm so the right hand wraps
## around its right side: palm on the side, fingers round the back, thumb across the front.
func _hold_radio() -> void:
	_radio.transform = _radio_rest
	var hand_in_arm := _arms.global_transform.affine_inverse() * _arms.bone_transform("hand.R")
	# Radio axes in the hand's space: its right side faces the palm (+Z of the hand), its top
	# runs across the hand.
	var right := Vector3(0, 0, -1)
	var up := Vector3(-1, 0, 0) if grip_flip else Vector3(1, 0, 0)
	var radio_in_hand := Transform3D(Basis(right, up, right.cross(up)), grip_center)
	_arms.transform = _radio_rest * (hand_in_arm * radio_in_hand).affine_inverse()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not _dead:
		_look.x = clampf(_look.x - rad_to_deg(event.relative.x * mouse_sensitivity), -look_range.x, look_range.x)
		_look.y = clampf(_look.y - rad_to_deg(event.relative.y * mouse_sensitivity), -look_range.y, look_range.y)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif _dead and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _update_hint() -> void:
	if _radio.is_solved():
		_hint.text = ""
	elif _radio.get_active_knob() == 0:
		_hint.text = "Tune the left knob    A / D  or  scroll"
	else:
		_hint.text = "Now the right knob    A / D  or  scroll"


func _on_radio_solved() -> void:
	_update_hint()
	await get_tree().create_timer(3.0).timeout
	if _dead:
		return
	# Crawl back out through the cut while everything fades.
	_leaving = true
	var tween := create_tween().set_parallel()
	tween.tween_property(_camera, "position", _camera.position + Vector3(0.0, 0.15, -0.6), 2.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_fade, "modulate:a", 1.0, 2.0)
	tween.tween_property(_ambience, "volume_db", -60.0, 2.5)
	await tween.finished
	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)


func _die() -> void:
	_dead = true
	_radio.enabled = false
	_hint.text = ""
	_death_screen.visible = true
	_death_screen.modulate.a = 0.0
	create_tween().tween_property(_death_screen, "modulate:a", 1.0, 2.0).set_delay(1.0)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_overlay_mat = ShaderMaterial.new()
	_overlay_mat.shader = OVERLAY_SHADER
	var overlay := ColorRect.new()
	overlay.material = _overlay_mat
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)

	_hint = Label.new()
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.position.y -= 60
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_color", Color(0.75, 0.6, 0.55, 0.8))
	layer.add_child(_hint)

	_death_screen = VBoxContainer.new()
	_death_screen.set_anchors_preset(Control.PRESET_CENTER)
	_death_screen.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_death_screen.grow_vertical = Control.GROW_DIRECTION_BOTH
	_death_screen.visible = false
	layer.add_child(_death_screen)
	var title := Label.new()
	title.text = "You didn't make it"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.75, 0.2, 0.18))
	_death_screen.add_child(title)
	var again := Label.new()
	again.text = "Press R to try again"
	again.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	again.add_theme_color_override("font_color", Color(0.55, 0.4, 0.4))
	_death_screen.add_child(again)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


## Muffled blizzard outside the carcass: low rumbling noise that swells with the gusts.
## Assign a stream to the Ambience node to use a real recording instead.
func _start_ambience() -> void:
	if _ambience.stream == null:
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = 22050.0
		generator.buffer_length = 0.2
		_ambience.stream = generator
		_ambience.play()
		_ambience_playback = _ambience.get_stream_playback()
	else:
		_ambience.play()


func _feed_ambience() -> void:
	if _ambience_playback == null:
		return
	for f in _ambience_playback.get_frames_available():
		_wind_time += 1.0 / 22050.0
		_wind = clampf(_wind * 0.998 + (randf() * 2.0 - 1.0) * 0.02, -1.0, 1.0)
		var swell := 0.55 + 0.45 * sin(_wind_time * 0.4) * sin(_wind_time * 0.13)
		_ambience_playback.push_frame(Vector2.ONE * _wind * swell * 0.8)
