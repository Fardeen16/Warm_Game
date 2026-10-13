extends Node3D
## Scene 3: you crawl out of the carcass and the rescue helicopter comes down out of the storm.
## You're out in the cold again, so you can still freeze to death while you wait (FreezeEffect).
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
## Where the game returns after the credits (the start menu).
@export_file("*.tscn") var restart_scene: String = "res://scenes/main.tscn"
## The credits that roll after the helicopter leaves.
@export var credits_by: String = "Fardeen & Faizan"
@export var credits_dedication: String = "Abdul Rahman"
## Photo shown under the names (jpg or png). Leave the file out and the credits skip it.
@export_file("*.jpg", "*.jpeg", "*.png") var credits_photo: String = "res://assets/ui/credits/us_photo.jpg"
## Photo shown between "dedicated to" and the name. Leave the file out to skip it.
@export_file("*.jpg", "*.jpeg", "*.png") var dedication_photo: String = "res://assets/ui/credits/dedication_photo.jpg"
## Seconds each credits page stays up.
@export var credits_hold: float = 5.5

@onready var _heli: Helicopter = $Helicopter
@onready var _player: Player = $Player
@onready var _storm: SnowStorm = $SnowStorm
@onready var _bison: Node3D = $BisonCarcass
@onready var _rope_grab: RopeGrab = $RopeGrab
@onready var _captions: Captions = $Captions
@onready var _cutscene_camera: Camera3D = $CutsceneCamera
@onready var _hands: Node3D = $Player/Head/Camera3D/Hands
@onready var _freeze: FreezeEffect = $FreezeEffect

var _start: Vector3
var _base_wind := 0.0
var _base_intensity := 0.0
var _hovering := false
var _flying_off := false
var _ended := false
var _time := 0.0
var _fade: ColorRect
var _layer: CanvasLayer


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
	# Any key or click skips to the end of the credits.
	if _ended and (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		_back_to_menu()


func _on_rope_grabbed() -> void:
	# Saved: the cold stops and the frost slowly clears.
	_freeze.enabled = false
	create_tween().tween_property(_freeze, "exposure", 0.0, 6.0)
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
	await _roll_credits()
	_back_to_menu()


func _roll_credits() -> void:
	# Page 1: who made it.
	var page := _credits_page()
	page.add_child(_credit_text("A GAME BY", GameFonts.label(8), 18, GameFonts.FROST_DIM))
	page.add_child(_credit_text(credits_by, GameFonts.title(4), 58, GameFonts.FROST))
	var photo := _load_photo(credits_photo)
	if photo:
		page.add_child(_spacer(18))
		page.add_child(_framed(photo, 260.0))
	await _show_page(page)

	# Page 2: the dedication, with their photo between the two lines.
	page = _credits_page()
	page.add_child(_credit_text("dedicated to", GameFonts.title_italic(), 30, GameFonts.FROST_DIM))
	var dedicated := _load_photo(dedication_photo)
	if dedicated:
		page.add_child(_spacer(8))
		page.add_child(_framed(dedicated, 280.0))
		page.add_child(_spacer(8))
	page.add_child(_credit_text(credits_dedication, GameFonts.title(6), 72, GameFonts.FROST))
	await _show_page(page)


## A photo in a thin frost-white frame, scaled to the given height.
func _framed(photo: Texture2D, height: float) -> Control:
	var frame := PanelContainer.new()
	var border := StyleBoxFlat.new()
	border.bg_color = Color(GameFonts.FROST, 0.9)
	border.set_content_margin_all(6)
	frame.add_theme_stylebox_override("panel", border)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var picture := TextureRect.new()
	picture.texture = photo
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var aspect := float(photo.get_width()) / photo.get_height()
	picture.custom_minimum_size = Vector2(height * aspect, height)
	frame.add_child(picture)
	return frame


func _spacer(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	return gap


func _credits_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_CENTER)
	page.grow_horizontal = Control.GROW_DIRECTION_BOTH
	page.grow_vertical = Control.GROW_DIRECTION_BOTH
	page.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_theme_constant_override("separation", 10)
	page.modulate.a = 0.0
	_layer.add_child(page)
	return page


func _show_page(page: Control) -> void:
	var tween := create_tween()
	tween.tween_property(page, "modulate:a", 1.0, 1.5)
	tween.tween_interval(credits_hold)
	tween.tween_property(page, "modulate:a", 0.0, 1.5)
	await tween.finished
	page.queue_free()


func _credit_text(text: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _load_photo(file: String) -> Texture2D:
	for path in [file, file.get_basename() + ".png", file.get_basename() + ".jpeg"]:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


func _back_to_menu() -> void:
	if not is_inside_tree():
		return
	GameIntro.skip_menu = false
	get_tree().change_scene_to_file(restart_scene)


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

	_layer = layer
