class_name GameSettings
extends RefCounted
## Player settings that last between launches (saved in user://settings.cfg).
## Low graphics is for weaker laptops: lower 3D resolution, no shadows or glow, fewer flakes.

const PATH := "user://settings.cfg"

static var low_graphics := false
static var _loaded := false


static func load_settings() -> void:
	if _loaded:
		return
	_loaded = true
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		low_graphics = config.get_value("graphics", "low", false)


static func set_low_graphics(low: bool) -> void:
	low_graphics = low
	var config := ConfigFile.new()
	config.set_value("graphics", "low", low)
	config.save(PATH)


## True on the web build (and anywhere else running the lighter Compatibility renderer).
static func is_compatibility() -> bool:
	return RenderingServer.get_current_rendering_method() == "gl_compatibility"


## Applies the graphics setting to a scene. Every scene calls this when it starts.
static func apply(scene: Node) -> void:
	load_settings()
	if is_compatibility():
		_match_compatibility_look(scene)
	var viewport := scene.get_viewport()
	# FSR upscaling needs Forward+.
	var fsr := low_graphics and not is_compatibility()
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if fsr else Viewport.SCALING_3D_MODE_BILINEAR
	viewport.scaling_3d_scale = 0.7 if low_graphics else 1.0
	if not low_graphics:
		return
	for light: Light3D in scene.find_children("*", "Light3D", true, false):
		light.shadow_enabled = false
	for env_node: WorldEnvironment in scene.find_children("*", "WorldEnvironment", true, false):
		if env_node.environment:
			env_node.environment.glow_enabled = false
	for storm: SnowStorm in scene.find_children("*", "SnowStorm", true, false):
		storm.max_flakes = storm.max_flakes / 2
	for prints: Footprints in scene.find_children("*", "Footprints", true, false):
		prints.max_prints = prints.max_prints / 2


## The Compatibility renderer (used in browsers) lights scenes brighter and fogs them less, so
## darken the night and thicken the haze to keep the same cold, gloomy mood.
static func _match_compatibility_look(scene: Node) -> void:
	for light: Light3D in scene.find_children("*", "Light3D", true, false):
		if light is OmniLight3D:
			# Its cheaper 2-pass shadow mode isn't available here.
			(light as OmniLight3D).omni_shadow_mode = OmniLight3D.SHADOW_CUBE
		if light is DirectionalLight3D:
			light.light_energy *= 0.6
	for env_node: WorldEnvironment in scene.find_children("*", "WorldEnvironment", true, false):
		if env_node.environment:
			env_node.environment.ambient_light_energy *= 0.55
	for storm: SnowStorm in scene.find_children("*", "SnowStorm", true, false):
		storm.haze_density_calm *= 2.2
		storm.haze_density_storm *= 2.2
		storm.snow_color = storm.snow_color.darkened(0.25)
