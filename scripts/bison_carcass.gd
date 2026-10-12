@tool
class_name BisonCarcass
extends Node3D
## Dead wood bison lying on its side. Stand at its belly (CutZone) and hold E: the player
## kneels and slices it open with the knife, from the hind belly up to the neck. Then press E
## to crawl inside, which loads the inside_scene.
## The cut is a bloody gash painted onto the belly (a decal, no carving), with blood dripping
## out of it and a stain spreading in the snow below.
## Built from placeholder CSG shapes; swap the Body for a real model later.

signal opened
signal entered

## Toggle in the inspector to preview the opened carcass.
@export var is_cut_open: bool = false:
	set(value):
		is_cut_open = value
		_cut_progress = 1.0 if value else 0.0
		_update_cut()
## Seconds of holding E to cut it open.
@export_range(0.2, 20.0, 0.1) var cut_duration: float = 3.0
## Scene loaded once the player has crawled inside.
@export_file("*.tscn") var inside_scene: String = "res://scenes/inside_carcass.tscn"

## Where the cut runs along the body: from the hind belly (x) to just behind the front legs.
@export var cut_from_x: float = -0.775
@export var cut_to_x: float = 0.6
## Height of the cut on the belly.
@export var cut_height: float = 0.6

var _cut_progress := 0.0
var _gash: Decal
var _stain: Decal
var _drips: GPUParticles3D
var _player_in_reach: Node3D
var _entered := false

@onready var _entry_point: Marker3D = $EntryPoint
@onready var _hide_point: Marker3D = $HidePoint
@onready var _kneel_point: Marker3D = $KneelPoint


func _ready() -> void:
	add_to_group("interactable")
	_build_blood()
	var cut_zone: Area3D = $CutZone
	cut_zone.body_entered.connect(_on_cut_zone_body_entered)
	cut_zone.body_exited.connect(_on_cut_zone_body_exited)
	_update_cut()


func can_interact(player: Node3D) -> bool:
	return player == _player_in_reach and not _entered


func get_prompt() -> String:
	return "Press E to crawl inside" if is_cut_open else "Hold E to cut it open"


## Once it's open, stay kneeling at the opening, ready to crawl in.
func keep_kneeling() -> bool:
	return is_cut_open


func get_progress() -> float:
	return -1.0 if is_cut_open else _cut_progress


func interact(player: Node3D, delta: float, just_pressed: bool) -> void:
	if not is_cut_open:
		player.kneel_at(_kneel_point)
		# Only cut once the player is down on their knees at the belly.
		if player.is_kneeling():
			_cut_progress = minf(_cut_progress + delta / cut_duration, 1.0)
			_update_cut()
			if _cut_progress >= 1.0:
				is_cut_open = true
				opened.emit()
		player.show_cut(_cut_point())
	elif just_pressed and player.has_method("enter_shelter"):
		_entered = true
		player.enter_shelter(_entry_point, _hide_point, _on_player_inside)


## Where the knife is: the end of the cut so far, on the surface of the belly.
func _cut_point() -> Vector3:
	var x := lerpf(cut_from_x, cut_to_x, _cut_progress)
	return to_global(Vector3(x, cut_height, _belly_z(x)))


## The belly is rounded, so its surface sits further in toward the ends of the body.
func _belly_z(x: float) -> float:
	return -0.7 * sqrt(maxf(0.0, 1.0 - pow(x / 1.3, 2.0)))


func _on_player_inside() -> void:
	entered.emit()
	if inside_scene != "":
		get_tree().change_scene_to_file(inside_scene)


func _on_cut_zone_body_entered(body: Node3D) -> void:
	if body.has_method("enter_shelter"):
		_player_in_reach = body


func _on_cut_zone_body_exited(body: Node3D) -> void:
	if body == _player_in_reach:
		_player_in_reach = null


func _update_cut() -> void:
	if not is_node_ready() or _gash == null:
		return
	# The gash grows from the hind end toward the front legs.
	var length := (cut_to_x - cut_from_x) * maxf(_cut_progress, 0.001)
	var center_x := cut_from_x + length * 0.5
	_gash.visible = _cut_progress > 0.0
	_gash.size.x = length
	_gash.position.x = center_x
	_stain.visible = _cut_progress > 0.0
	_stain.modulate.a = smoothstep(0.0, 1.0, _cut_progress)
	_stain.size.x = maxf(length, 0.3) + 0.3
	_stain.position.x = center_x
	_drips.emitting = _cut_progress > 0.0
	_drips.amount_ratio = lerpf(0.3, 1.0, _cut_progress)
	_drips.position.x = center_x
	(_drips.process_material as ParticleProcessMaterial).emission_box_extents.x = length * 0.5


func _build_blood() -> void:
	var gash_size := Vector3(cut_to_x - cut_from_x, 0.6, 0.55)
	# Projects sideways onto the belly: the decal's down axis points into the body.
	_gash = Decal.new()
	_gash.size = gash_size
	_gash.position = Vector3((cut_from_x + cut_to_x) * 0.5, cut_height - 0.13, _belly_z(0.0))
	_gash.rotation_degrees = Vector3(-90, 0, 0)
	var gash_textures := _make_gash_textures()
	_gash.texture_albedo = gash_textures[0]
	_gash.texture_normal = gash_textures[1]
	_gash.normal_fade = 0.2
	add_child(_gash, false, Node.INTERNAL_MODE_FRONT)

	# Blood soaking into the snow under the belly.
	_stain = Decal.new()
	_stain.size = Vector3(gash_size.x + 0.3, 1.0, 0.9)
	_stain.position = Vector3(_gash.position.x, 0.2, -1.0)
	_stain.texture_albedo = _make_stain_texture()
	add_child(_stain, false, Node.INTERNAL_MODE_FRONT)

	# Drops running off the cut and falling into the snow.
	var drop_mat := StandardMaterial3D.new()
	drop_mat.albedo_color = Color(0.4, 0.02, 0.02)
	drop_mat.roughness = 0.2
	drop_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var drop := QuadMesh.new()
	drop.size = Vector2(0.012, 0.025)
	drop.material = drop_mat
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(0.5, 0.01, 0.02)
	process.gravity = Vector3(0, -6, 0)
	process.scale_min = 0.6
	process.scale_max = 1.4
	_drips = GPUParticles3D.new()
	_drips.amount = 40
	_drips.lifetime = 0.5
	_drips.process_material = process
	_drips.draw_pass_1 = drop
	_drips.position = Vector3(_gash.position.x, cut_height - 0.08, _belly_z(0.0) - 0.04)
	_drips.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_drips, false, Node.INTERNAL_MODE_FRONT)


## A long, ragged red gash near the top of the image with blood running down from it.
func _make_gash_textures() -> Array[Texture2D]:
	const W := 512
	const H := 192
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var noise := FastNoiseLite.new()
	noise.frequency = 0.03
	var deep := Color(0.12, 0.0, 0.0)
	var wet := Color(0.45, 0.02, 0.02)
	var albedo := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var height := Image.create(W, H, false, Image.FORMAT_RGBA8)
	height.fill(Color.WHITE)
	var centers := PackedFloat32Array()
	var tapers := PackedFloat32Array()

	# The gash: thick in the middle of the cut, tapering to points at both ends, with wet
	# blood smeared around it.
	for x in W:
		var taper := sin(float(x) / (W - 1) * PI)
		var half := (8.0 + noise.get_noise_1d(x) * 3.0) * pow(taper, 0.5)
		var center := H * 0.28 + noise.get_noise_1d(x + 500.0) * 6.0
		centers.append(center)
		tapers.append(taper)
		for y in range(maxi(0, int(center - half - 14.0)), mini(H, int(center + half + 14.0))):
			var d := absf(y - center)
			var gash := smoothstep(half + 2.0, half - 1.0, d)
			var smear := smoothstep(half + 12.0, half, d) * 0.6 * taper
			albedo.set_pixel(x, y, Color(wet.lerp(deep, gash), maxf(gash, smear)))
			var h := 1.0 - gash * 0.9
			height.set_pixel(x, y, Color(h, h, h, 1.0))

	# Blood running down from the gash, each run ending in a bead.
	for i in 26:
		var dx := rng.randi_range(6, W - 7)
		var w := rng.randf_range(1.0, 2.5)
		var top := centers[dx]
		var bottom := top + rng.randf_range(0.25, 0.95) * (H - top) * tapers[dx]
		for x in range(dx - 6, dx + 7):
			for y in range(int(top), mini(H, int(bottom + w + 3.0))):
				var run := smoothstep(w + 1.0, w - 0.5, absf(x - dx)) * (1.0 if y <= bottom else 0.0)
				var tip := smoothstep(w + 1.5, w * 0.5, Vector2(x - dx, y - bottom).length())
				var blood := maxf(run, tip)
				if blood > albedo.get_pixel(x, y).a:
					albedo.set_pixel(x, y, Color(wet, blood))

	# The decal shows the image bottom-up on the belly, so flip it to run the blood downward.
	albedo.flip_y()
	height.flip_y()
	height.bump_map_to_normal_map(4.0)
	return [ImageTexture.create_from_image(albedo), ImageTexture.create_from_image(height)]


## Blotchy dark red patch for the snow.
func _make_stain_texture() -> Texture2D:
	const S := 128
	var noise := FastNoiseLite.new()
	noise.frequency = 0.05
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	for y in S:
		for x in S:
			var d := Vector2(x - S * 0.5, y - S * 0.5).length() / (S * 0.5)
			var a := smoothstep(0.9, 0.3, d + noise.get_noise_2d(x, y) * 0.35)
			img.set_pixel(x, y, Color(0.35, 0.01, 0.01, a * 0.85))
	return ImageTexture.create_from_image(img)
