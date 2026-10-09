@tool
class_name SnowStorm
extends Node3D
## Night snow storm covering the play area: diagonal snowfall in three flake sizes on a wind
## that shifts direction every few minutes, drifting volumetric snow clouds and distance haze.
## Every value can be tweaked live in the inspector, in the editor or while the game runs.

const CLOUD_SHADER := preload("res://shaders/snow_clouds.gdshader")

@export_group("Storm")
## 0 = light flurry, 1 = full blizzard. Scales flakes, wind, haze and clouds together.
@export_range(0.0, 1.0, 0.01) var intensity: float = 0.75
## Total number of flakes at full intensity. Changing this restarts the snowfall.
@export_range(1000, 150000, 1000) var max_flakes: int = 100000
## Downward speed of medium flakes (m/s). Small flakes fall a bit faster, large ones slower.
@export_range(0.5, 15.0, 0.1) var fall_speed: float = 3.0
@export var snow_color: Color = Color(0.85, 0.88, 0.94, 0.9)

@export_group("Flake Sizes")
## Size in meters of each flake class.
@export_range(0.005, 0.3, 0.005) var small_size: float = 0.025
@export_range(0.005, 0.3, 0.005) var medium_size: float = 0.05
@export_range(0.005, 0.5, 0.005) var large_size: float = 0.1
## How common each class is, relative to the others.
@export_range(0.0, 1.0, 0.01) var small_share: float = 0.6
@export_range(0.0, 1.0, 0.01) var medium_share: float = 0.3
@export_range(0.0, 1.0, 0.01) var large_share: float = 0.1

@export_group("Wind")
## Starting horizontal wind direction (x, z).
@export var wind_direction: Vector2 = Vector2(1.0, 0.4)
## Wind speed at full intensity (m/s). Around fall speed / intensity gives a ~45 degree slant.
@export_range(0.0, 30.0, 0.1) var wind_strength: float = 5.0
## Let the wind turn to a new direction every few minutes (only while the game runs).
@export var shifting_wind: bool = true
## Seconds between direction changes, picked at random in this range.
@export_range(10.0, 900.0, 1.0) var shift_interval_min: float = 120.0
@export_range(10.0, 900.0, 1.0) var shift_interval_max: float = 240.0
## Seconds the wind takes to swing round to its new direction.
@export_range(1.0, 120.0, 0.5) var shift_duration: float = 15.0
## Largest turn in one change (degrees).
@export_range(0.0, 180.0, 1.0) var max_shift_angle: float = 120.0
## How much the wind speed varies in gusts (0 = steady).
@export_range(0.0, 1.0, 0.01) var gustiness: float = 0.5
## How fast gusts come and go.
@export_range(0.01, 2.0, 0.01) var gust_frequency: float = 0.25
## Random spread of flake directions (degrees).
@export_range(0.0, 45.0, 0.5) var flake_spread: float = 8.0

@export_group("Area")
## Width/depth of the snowing area, centered on this node. Keep it a bit larger than the map.
@export_range(5.0, 150.0, 1.0) var area_size: float = 50.0
## Height where flakes spawn.
@export_range(5.0, 60.0, 1.0) var area_height: float = 15.0

@export_group("Snow Clouds")
@export var clouds_enabled: bool = true
## Cloud density at intensity 0 and 1.
@export_range(0.0, 2.0, 0.01) var cloud_density_calm: float = 0.05
@export_range(0.0, 2.0, 0.01) var cloud_density_storm: float = 1.2
## Color the clouds glow with, so they read as white at night.
@export var cloud_color: Color = Color(0.7, 0.75, 0.85)
@export_range(0.0, 4.0, 0.01) var cloud_glow: float = 0.8
## Higher = clouds broken into separate patches, lower = one solid mass.
@export_range(0.0, 1.0, 0.01) var cloud_coverage: float = 0.5
## Size of the cloud patches in meters.
@export_range(2.0, 100.0, 0.5) var cloud_scale: float = 12.0
@export_range(1.0, 40.0, 0.5) var cloud_height: float = 8.0
## How fast the clouds move with the main wind.
@export_range(0.0, 2.0, 0.01) var cloud_speed: float = 0.6

@export_group("Haze")
@export var world_environment: NodePath
## When off, the WorldEnvironment fog is left alone.
@export var control_fog: bool = true
## Distance haze at intensity 0 and 1.
@export_range(0.0, 0.3, 0.001) var haze_density_calm: float = 0.01
@export_range(0.0, 0.3, 0.001) var haze_density_storm: float = 0.04
@export var haze_color: Color = Color(0.42, 0.46, 0.53)

# Relative fall speed of the small, medium and large flakes.
const SIZE_FALL_MULT: Array[float] = [1.15, 1.0, 0.75]

var _layers: Array[Dictionary] = []
var _draw_mat: StandardMaterial3D
var _cloud_volume: FogVolume
var _cloud_mat: ShaderMaterial
var _cloud_offset := Vector3.ZERO
var _gust_noise := FastNoiseLite.new()
var _time := 0.0
var _rng := RandomNumberGenerator.new()
# Current wind angle and the swing in progress, in radians on the x/z plane.
var _wind_angle := 0.0
var _shift_from := 0.0
var _shift_to := 0.0
var _shift_progress := 1.0
var _next_shift_time := 0.0
var _set_direction := Vector2.ZERO


func _ready() -> void:
	_gust_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_gust_noise.frequency = 1.0
	_build_draw_material()
	for size_class in 3:
		_layers.append(_build_layer(size_class))
	_rng.randomize()
	_schedule_next_shift()
	_build_clouds()
	_update_storm(0.0)


func _process(delta: float) -> void:
	_update_storm(delta)


func _build_draw_material() -> void:
	# Soft round flake.
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var flake_tex := GradientTexture2D.new()
	flake_tex.gradient = gradient
	flake_tex.fill = GradientTexture2D.FILL_RADIAL
	flake_tex.fill_from = Vector2(0.5, 0.5)
	flake_tex.fill_to = Vector2(0.5, 0.0)
	flake_tex.width = 32
	flake_tex.height = 32

	_draw_mat = StandardMaterial3D.new()
	_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_draw_mat.albedo_texture = flake_tex


func _build_layer(size_class: int) -> Dictionary:
	var process_mat := ParticleProcessMaterial.new()
	process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_mat.gravity = Vector3.ZERO
	process_mat.scale_min = 0.8
	process_mat.scale_max = 1.2

	var quad := QuadMesh.new()
	quad.material = _draw_mat

	var particles := GPUParticles3D.new()
	particles.name = "Snow%d" % size_class
	particles.local_coords = false
	particles.process_material = process_mat
	particles.draw_pass_1 = quad
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(Vector3(-200, -100, -200), Vector3(400, 200, 400))
	particles.seed = size_class + 1
	add_child(particles, false, Node.INTERNAL_MODE_FRONT)

	return {
		"size_class": size_class,
		"particles": particles,
		"process_mat": process_mat,
		"quad": quad,
	}


func _build_clouds() -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.04
	noise.fractal_octaves = 4
	var noise_tex := NoiseTexture3D.new()
	noise_tex.width = 64
	noise_tex.height = 64
	noise_tex.depth = 64
	noise_tex.seamless = true
	noise_tex.noise = noise

	_cloud_mat = ShaderMaterial.new()
	_cloud_mat.shader = CLOUD_SHADER
	_cloud_mat.set_shader_parameter("noise_tex", noise_tex)

	_cloud_volume = FogVolume.new()
	_cloud_volume.name = "SnowClouds"
	_cloud_volume.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	_cloud_volume.material = _cloud_mat
	add_child(_cloud_volume, false, Node.INTERNAL_MODE_FRONT)


func _schedule_next_shift() -> void:
	_next_shift_time = _time + _rng.randf_range(shift_interval_min, maxf(shift_interval_min, shift_interval_max))


func _update_wind_angle(delta: float) -> void:
	# Editing wind_direction in the inspector snaps the wind to it.
	if wind_direction != _set_direction:
		_set_direction = wind_direction
		_wind_angle = wind_direction.angle()
		_shift_progress = 1.0
		_schedule_next_shift()

	if shifting_wind and not Engine.is_editor_hint() and _time >= _next_shift_time:
		_shift_from = _wind_angle
		_shift_to = _wind_angle + deg_to_rad(_rng.randf_range(-max_shift_angle, max_shift_angle))
		_shift_progress = 0.0
		_schedule_next_shift()

	if _shift_progress < 1.0:
		_shift_progress = minf(_shift_progress + delta / shift_duration, 1.0)
		_wind_angle = lerpf(_shift_from, _shift_to, smoothstep(0.0, 1.0, _shift_progress))


func _update_storm(delta: float) -> void:
	if _layers.is_empty():
		return
	_time += delta

	_update_wind_angle(delta)
	var base_wind := Vector3(cos(_wind_angle), 0.0, sin(_wind_angle)) * wind_strength * intensity
	var gust := 1.0 + gustiness * _gust_noise.get_noise_1d(_time * gust_frequency)
	var sizes: Array[float] = [small_size, medium_size, large_size]
	var size_shares: Array[float] = [small_share, medium_share, large_share]
	var size_total := small_share + medium_share + large_share

	for layer in _layers:
		var size_class: int = layer.size_class
		var particles: GPUParticles3D = layer.particles
		var process_mat: ParticleProcessMaterial = layer.process_mat

		var share := size_shares[size_class] / size_total if size_total > 0.0 else 0.0
		var amount := int(max_flakes * share)
		var fall := fall_speed * SIZE_FALL_MULT[size_class]
		var lifetime := area_height / fall
		var flake_velocity := base_wind * gust + Vector3.DOWN * fall

		# Amount and lifetime restart the particles, so only touch them when they change.
		if amount > 0 and particles.amount != amount:
			particles.amount = amount
		if not is_equal_approx(particles.lifetime, lifetime):
			particles.lifetime = lifetime
			particles.preprocess = lifetime
		particles.amount_ratio = intensity
		particles.emitting = amount > 0 and intensity > 0.0

		var speed := flake_velocity.length()
		process_mat.direction = flake_velocity / speed
		process_mat.spread = flake_spread
		process_mat.initial_velocity_min = speed * 0.85
		process_mat.initial_velocity_max = speed * 1.15
		process_mat.emission_box_extents = Vector3(area_size * 0.5, 0.5, area_size * 0.5)
		(layer.quad as QuadMesh).size = Vector2.ONE * sizes[size_class]

		# Spawn upwind and above the area so the flakes land across it.
		particles.global_position = global_position + Vector3.UP * area_height - base_wind * lifetime

	_draw_mat.albedo_color = snow_color

	_cloud_volume.visible = clouds_enabled
	_cloud_volume.size = Vector3(area_size * 2.0, cloud_height, area_size * 2.0)
	_cloud_volume.global_position = global_position + Vector3.UP * cloud_height * 0.5
	_cloud_offset += base_wind * cloud_speed * delta
	_cloud_mat.set_shader_parameter("density", lerpf(cloud_density_calm, cloud_density_storm, intensity))
	_cloud_mat.set_shader_parameter("emission", cloud_color * cloud_glow)
	_cloud_mat.set_shader_parameter("coverage", cloud_coverage)
	_cloud_mat.set_shader_parameter("noise_scale", 1.0 / cloud_scale)
	_cloud_mat.set_shader_parameter("offset", _cloud_offset)

	if control_fog:
		var env_node := get_node_or_null(world_environment) as WorldEnvironment
		if env_node and env_node.environment:
			var env := env_node.environment
			env.fog_enabled = true
			env.fog_density = lerpf(haze_density_calm, haze_density_storm, intensity)
			env.fog_light_color = haze_color
			env.volumetric_fog_enabled = clouds_enabled
