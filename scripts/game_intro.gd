class_name GameIntro
extends Node3D
## Scene 1 flow. Opens on the start menu: a camera on the abandoned jeep (angled so it faces a
## little to the right) with the title and a Start Game button on the right. Start pans the camera
## into the player's eyes and the game begins. Walking up to the bison triggers a remark.
## After dying, R restarts straight into the game; after the credits the menu shows again.

## Skip the menu on reloads (restart after dying). Cleared by the credits.
static var skip_menu := false

## How close to the bison before the player comments on it (m).
@export var bison_remark_radius: float = 7.0
@export var bison_lines: PackedStringArray = [
	"Ohh... so they have this doodoo body of a bison.",
	"Can't even find a proper dead body, jeez.",
]
## Seconds for the camera to fly from the menu shot into the player's eyes.
@export var pan_time: float = 3.0

@onready var _player: Player = $Player
@onready var _menu_camera: Camera3D = $MenuCamera
@onready var _jeep: Node3D = $Jeep
@onready var _bison: Node3D = $BisonCarcass
@onready var _freeze: FreezeEffect = $FreezeEffect
@onready var _hud: CanvasLayer = $HUD
@onready var _captions: Captions = $Captions
@onready var _storm: Node3D = $SnowStorm

var _playing := false
var _remarked := false
var _menu: CanvasLayer


func _ready() -> void:
	# The storm is often hidden in the editor to save battery; always show it in the game.
	_storm.visible = true
	if skip_menu:
		_start_playing()
		return

	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_freeze.enabled = false
	_hud.visible = false
	_frame_jeep()
	_menu_camera.current = true
	_build_menu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_delta: float) -> void:
	if _playing and not _remarked and not _captions.is_speaking():
		var offset := _bison.global_position - _player.global_position
		if Vector2(offset.x, offset.z).length() < bison_remark_radius:
			_remarked = true
			_captions.say(bison_lines)


## Puts the menu camera at the jeep's front-right so its nose points to the right of the
## frame, with the jeep sitting left of center to leave room for the menu.
func _frame_jeep() -> void:
	var center := _jeep.global_position + Vector3.UP * 0.9
	var front := -_jeep.global_basis.x  # the model's nose points along its -X
	front = Vector3(front.x, 0.0, front.z).normalized()
	var right := front.cross(Vector3.UP)
	var angle := deg_to_rad(38.0)
	_menu_camera.global_position = center + (front * cos(angle) + right * sin(angle)) * 7.5 + Vector3.UP * 0.6
	_menu_camera.look_at(center)
	# Turn a little so the jeep sits in the left part of the screen.
	_menu_camera.rotate_object_local(Vector3.UP, deg_to_rad(-14.0))


func _on_start_pressed() -> void:
	skip_menu = true
	var fade := create_tween()
	fade.tween_property(_menu.get_child(0), "modulate:a", 0.0, 0.6)
	await fade.finished
	_menu.queue_free()

	# Fly from the menu shot into the player's eyes.
	var from := _menu_camera.global_transform
	var to := _player.camera.global_transform
	var pan := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan.tween_method(func(t: float) -> void: _menu_camera.global_transform = from.interpolate_with(to, t), 0.0, 1.0, pan_time)
	await pan.finished
	_start_playing()


func _start_playing() -> void:
	_playing = true
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_player.camera.current = true
	_freeze.enabled = true
	_hud.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_menu() -> void:
	_menu = CanvasLayer.new()
	_menu.layer = 40
	add_child(_menu)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(root)

	# Darken the right side so the text reads over the storm.
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.0, 0.01, 0.03, 0.0))
	gradient.set_color(1, Color(0.0, 0.01, 0.03, 0.78))
	var shade_tex := GradientTexture2D.new()
	shade_tex.gradient = gradient
	shade_tex.fill_from = Vector2(0.35, 0.0)
	shade_tex.fill_to = Vector2(1.0, 0.0)
	var shade := TextureRect.new()
	shade.texture = shade_tex
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.offset_right = -110
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	root.add_child(column)

	column.add_child(GameUI.label("A WINTER SURVIVAL STORY", GameFonts.label(6), 14, GameFonts.FROST_DIM))
	column.add_child(GameUI.label("STAYING", GameFonts.title(14), 64, GameFonts.FROST))
	column.add_child(GameUI.label("WARM", GameFonts.title(14), 64, GameFonts.FROST))

	var rule := ColorRect.new()
	rule.color = Color(GameFonts.FROST, 0.35)
	rule.custom_minimum_size = Vector2(220, 1)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(rule)
	column.add_child(GameUI.label("one night  ·  one storm  ·  one body to hide in", GameFonts.title_italic(), 17, GameFonts.FROST_DIM))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 46)
	column.add_child(gap)

	var start := GameUI.button("START GAME")
	start.pressed.connect(_on_start_pressed, CONNECT_ONE_SHOT)
	column.add_child(start)
	start.grab_focus.call_deferred()

	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 1.5)

