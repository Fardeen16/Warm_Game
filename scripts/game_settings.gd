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


## Applies the graphics setting to a scene. Every scene calls this when it starts.
static func apply(scene: Node) -> void:
	load_settings()
	var viewport := scene.get_viewport()
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if low_graphics else Viewport.SCALING_3D_MODE_BILINEAR
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
