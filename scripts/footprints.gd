class_name Footprints
extends Node3D
## Leaves shoe prints in the snow as the parent CharacterBody3D walks: alternating left and
## right feet, both feet on landing from a jump. Prints are decals pressed into whatever ground
## is below, and the storm slowly fills them back in.

## Distance between one footprint and the next (m).
@export_range(0.2, 2.0, 0.05) var step_length: float = 0.8
## Sideways distance of each foot from the body's center (m).
@export_range(0.0, 0.4, 0.01) var foot_spacing: float = 0.12
## Print width and length (m).
@export var print_size: Vector2 = Vector2(0.12, 0.3)
## Oldest prints are removed past this many.
@export_range(10, 1000, 10) var max_prints: int = 120
## Seconds before the snow starts filling a print in, and until it is gone.
@export var fill_start: float = 30.0
@export var fill_time: float = 120.0
@export var print_color: Color = Color(0.45, 0.5, 0.63, 0.85)

var _body: CharacterBody3D
var _distance := 0.0
var _left_next := true
var _was_on_floor := true
var _prints: Array[Decal] = []
var _textures := {}


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	_build_textures()


func _physics_process(delta: float) -> void:
	if _body == null:
		return
	var on_floor := _body.is_on_floor()
	if on_floor and not _was_on_floor:
		# Landing: both feet at once.
		_place_print(true)
		_place_print(false)
		_distance = 0.0
	elif on_floor:
		_distance += Vector2(_body.velocity.x, _body.velocity.z).length() * delta
		if _distance >= step_length:
			_distance -= step_length
			_place_print(_left_next)
			_left_next = not _left_next
	_was_on_floor = on_floor
	_fade_prints()


func _place_print(left: bool) -> void:
	var yaw := Basis(Vector3.UP, _body.global_rotation.y)
	var side := yaw.x * (-foot_spacing if left else foot_spacing)
	var decal := Decal.new()
	decal.top_level = true
	decal.size = Vector3(print_size.x, 0.6, print_size.y)
	decal.texture_albedo = _textures["albedo_left" if left else "albedo_right"]
	decal.texture_normal = _textures["normal_left" if left else "normal_right"]
	decal.modulate = print_color
	decal.normal_fade = 0.3
	decal.set_meta("born", Time.get_ticks_msec() / 1000.0)
	add_child(decal)
	# Slight random turn so the trail doesn't look stamped.
	decal.global_transform = Transform3D(yaw.rotated(Vector3.UP, randf_range(-0.08, 0.08)), _body.global_position + side + Vector3.UP * 0.1)
	_prints.append(decal)
	if _prints.size() > max_prints:
		_prints.pop_front().queue_free()


func _fade_prints() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	while not _prints.is_empty() and now - float(_prints[0].get_meta("born")) > fill_start + fill_time:
		_prints.pop_front().queue_free()
	for decal in _prints:
		var age := now - float(decal.get_meta("born"))
		decal.modulate.a = print_color.a * (1.0 - clampf((age - fill_start) / fill_time, 0.0, 1.0))


## Draws a boot sole: rounded forefoot leaning to the big-toe side, narrow arch, round heel,
## with tread lugs. Depth becomes a normal map so the print looks pressed in.
func _build_textures() -> void:
	const W := 48
	const H := 128
	var albedo := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var height := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for py in H:
		for px in W:
			var u := (px + 0.5) / W * 2.0 - 1.0
			var v := (py + 0.5) / H
			var fore := pow((u + 0.08) / 0.92, 2.0) + pow((v - 0.3) / 0.29, 2.0)
			var heel := pow(u / 0.8, 2.0) + pow((v - 0.82) / 0.17, 2.0)
			var arch := pow((u + 0.04) / 0.74, 2.0) + pow((v - 0.6) / 0.24, 2.0)
			var shape := minf(minf(fore, heel), arch)
			var inside := smoothstep(1.0, 0.75, shape)
			# Tread: horizontal lugs across the sole, chunkier on the heel.
			var lug := 1.0 if fmod(v * (14.0 if v < 0.65 else 9.0), 1.0) < 0.45 else 0.0
			var depth := inside * (1.0 - lug * 0.35)
			albedo.set_pixel(px, py, Color(1, 1, 1, inside * (0.85 + lug * 0.15)))
			var g := 1.0 - depth
			height.set_pixel(px, py, Color(g, g, g, 1.0))

	for side in ["right", "left"]:
		var side_albedo := albedo.duplicate() as Image
		var side_normal := height.duplicate() as Image
		# The left shoe is the mirror image of the right (mirror the depth, not the normals).
		if side == "left":
			side_albedo.flip_x()
			side_normal.flip_x()
		side_normal.bump_map_to_normal_map(6.0)
		_textures["albedo_" + side] = ImageTexture.create_from_image(side_albedo)
		_textures["normal_" + side] = ImageTexture.create_from_image(side_normal)
