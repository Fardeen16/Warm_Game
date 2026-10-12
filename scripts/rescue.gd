extends Node3D
## Scene 3: you crawl out of the carcass and the rescue helicopter comes down out of the storm.
## It starts far overhead and slowly descends, getting louder and whipping up the wind and snow.
## At hover height it lowers a rope; walk to it and press E to grab on. You're winched up as it
## climbs away, then a wide shot from high up watches it fly off.

## Where the helicopter hovers to drop the rope (keep it over open ground).
@export var hover_point: Vector3 = Vector3(-1.5, 17.0, 3.0)
## Height it appears at, and how far off to the side it starts.
@export var start_height: float = 140.0
@export var start_offset: Vector3 = Vector3(-35.0, 0.0, -45.0)
## Seconds to come down to hover height.
@export_range(3.0, 60.0, 0.5) var descent_time: float = 22.0
## How much stronger the wind gets right under the rotor (2.5 = three and a half times).
@export_range(0.0, 10.0, 0.1) var downwash: float = 2.5
## How hard the view shakes under the rotor (degrees). Your hands stay steady.
@export_range(0.0, 3.0, 0.05) var shake: float = 0.4
@export var arrival_lines: PackedStringArray = ["That sound... is that a chopper?"]
@export var rope_lines: PackedStringArray = ["The rope! I have to grab it."]
## Where "play again" goes.
@export_file("*.tscn") var restart_scene: String = "res://scenes/main.tscn"

@onready var _heli: Helicopter = $Helicopter
@onready var _player: Player = $Player
@onready var _storm: SnowStorm = $SnowStorm
@onready var _bison: Node3D = $BisonCarcass
@onready var _rope_grab: RopeGrab = $RopeGrab
@onready var _captions: Captions = $Captions
@onready var _cutscene_camera: Camera3D = $CutsceneCamera
@onready var _hands: Node3D = $Player/Head/Camera3D/Hands

var _start: Vector3
var _base_wind := 0.0
var _base_intensity := 0.0
var _hovering := false
var _flying_off := false
var _ended := false
var _time := 0.0
var _fade: ColorRect
var _end_screen: Control


func _ready() -> void:
	_build_ui()
	_base_wind = _storm.wind_strength
	_base_intensity = _storm.intensity

	# Stand just outside the cut, facing the clearing.
	var terrain := get_tree().get_first_node_in_group("snow_terrain")
	var spot := _bison.to_global(Vector3(-0.05, 0.0, -2.4))
	if terrain:
		spot.y = terrain.get_height(spot.x, spot.z)
	_player.global_position = spot
	_player.rotation.y = atan2(-(hover_point.x - spot.x), -(hover_point.z - spot.z))

	_start = hover_point + start_offset
	_start.y = start_height
	_heli.global_position = _start
	_face_heli_toward(hover_point)
	_rope_grab.helicopter = _heli
	_rope_grab.grabbed.connect(_on_rope_grabbed)

	var fade_in := create_tween()
	fade_in.tween_property(_fade, "modulate:a", 0.0, 2.0)
	_captions.say(arrival_lines)

	# Slow descent that eases off as it nears hover height.
	var descent := create_tween()
	descent.tween_property(_heli, "global_position", hover_point, descent_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await descent.finished
	_hovering = true

	# Long enough to just reach the snow below the door.
	var anchor := _heli.to_global(_heli.rope_anchor)
	var ground: float = terrain.get_height(anchor.x, anchor.z) if terrain else 0.0
	_heli.rope_length = anchor.y - ground - 0.1
	var drop := create_tween()
	drop.tween_property(_heli, "rope_out", 1.0, 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await drop.finished
	_rope_grab.enabled = true
	_captions.say(rope_lines)


func _process(delta: float) -> void:
	_time += delta
	# 0 far overhead, 1 at hover height.
	var closeness := 1.0 - clampf((_heli.global_position.y - hover_point.y) / (start_height - hover_point.y), 0.0, 1.0)
	if _flying_off:
		closeness = clampf(1.0 - (_heli.global_position.y - hover_point.y) / 40.0, 0.0, 1.0)
	_storm.wind_strength = _base_wind * (1.0 + downwash * closeness * closeness)
	_storm.intensity = lerpf(_base_intensity, 1.0, closeness)
	_heli.get_node("RotorSound").volume_db = lerpf(-5.0, 3.0, closeness)

	if _hovering:
		# Holding position in the gusts.
		_heli.global_position = hover_point + Vector3(sin(_time * 0.7) * 0.4, sin(_time * 1.1) * 0.3, cos(_time * 0.5) * 0.3)

	# Shake by turning the camera a touch: the world shakes, but your hands (attached to the
	# camera) stay steady in front of you.
	var amount := deg_to_rad(shake) * closeness * closeness
	_player.camera.rotation = Vector3(randf_range(-amount, amount), randf_range(-amount, amount), 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if _ended and event.is_action_pressed("restart"):
		get_tree().change_scene_to_file(restart_scene)


func _on_rope_grabbed() -> void:
	_hovering = false
	_flying_off = true
	_player.attach_to(_rope_grab)

	# Winch in while climbing away.
	var climb := create_tween().set_parallel()
	climb.tween_property(_heli, "rope_out", 0.25, 6.0).set_trans(Tween.TRANS_SINE)
	climb.tween_property(_heli, "global_position", _heli.global_position + Vector3(0.0, 14.0, 0.0), 6.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(4.5).timeout

	# Cut to a wide shot from high up as it flies off over the trees.
	var away := _heli.global_position + _heli.global_basis.z * 110.0 + Vector3(0.0, 30.0, 0.0)
	_cutscene_camera.global_position = _heli.global_position + Vector3(-20.0, 30.0, 18.0)
	# Thin the haze so it reads clearly from up here.
	create_tween().tween_property(_storm, "haze_density_storm", 0.025, 2.0)
	_cutscene_camera.look_at(_heli.global_position)
	_cutscene_camera.current = true
	_hands.visible = false
	var leave := create_tween()
	leave.tween_property(_heli, "global_position", away, 9.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var track := func(_v: Variant) -> void: _cutscene_camera.look_at(_heli.global_position)
	leave.parallel().tween_method(track, 0.0, 1.0, 9.0)
	await get_tree().create_timer(6.5).timeout

	var fade_out := create_tween()
	fade_out.tween_property(_fade, "modulate:a", 1.0, 2.5)
	await fade_out.finished
	_ended = true
	_end_screen.visible = true
	create_tween().tween_property(_end_screen, "modulate:a", 1.0, 1.5)


func _face_heli_toward(target: Vector3) -> void:
	var flat := Vector3(target.x, _heli.global_position.y, target.z)
	if flat.distance_to(_heli.global_position) > 0.1:
		# The model's nose points along +Z.
		_heli.look_at(flat, Vector3.UP, true)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)

	_end_screen = VBoxContainer.new()
	_end_screen.set_anchors_preset(Control.PRESET_CENTER)
	_end_screen.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_end_screen.grow_vertical = Control.GROW_DIRECTION_BOTH
	_end_screen.visible = false
	_end_screen.modulate.a = 0.0
	layer.add_child(_end_screen)
	var title := Label.new()
	title.text = "You made it out."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.8, 0.86, 0.95))
	_end_screen.add_child(title)
	var again := Label.new()
	again.text = "Press R to play again"
	again.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	again.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	_end_screen.add_child(again)
