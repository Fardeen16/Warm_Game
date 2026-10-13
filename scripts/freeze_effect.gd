class_name FreezeEffect
extends CanvasLayer
## Freezing to death out in the storm. Over time_to_death seconds the view frosts over from
## the edges, then darkens, then the player starts blinking as they fight to keep their eyes
## open, until they black out and die. Stops once the player starts crawling into shelter.

signal died

const OVERLAY_SHADER := preload("res://shaders/freeze_overlay.gdshader")

@export var player: NodePath
@export var enabled: bool = true
## Seconds out in the cold before the player dies.
@export_range(10.0, 600.0, 1.0) var time_to_death: float = 90.0
## How frozen the player is, 0 to 1. Set it higher to test the late stages.
@export_range(0.0, 1.0, 0.01) var exposure: float = 0.0

@export_group("Stages")
## Exposure range over which the frost creeps in.
@export var frost_range: Vector2 = Vector2(0.0, 0.5)
## Exposure range over which the view darkens.
@export var darkness_range: Vector2 = Vector2(0.3, 0.95)
## Exposure at which blinking starts.
@export_range(0.0, 1.0, 0.01) var blink_start: float = 0.65
## Seconds between blinks, from the first blinks to the last.
@export var blink_interval: Vector2 = Vector2(4.0, 1.2)
## Seconds the eyes stay shut per blink, from the first blinks to the last.
@export var blink_hold: Vector2 = Vector2(0.3, 0.8)

var _overlay: ColorRect
var _material: ShaderMaterial
var _death_screen: DeathScreen
var _blink := 0.0
var _blink_tween: Tween
var _next_blink := 0.0
var _final_close := 0.0
var _frozen_stopped := false
var _dead := false


func _ready() -> void:
	add_to_group("freeze_effect")
	layer = 10
	_build_overlay()
	_death_screen = DeathScreen.new()
	add_child(_death_screen)
	var p := get_node_or_null(player)
	if p and p.has_signal("entering_shelter"):
		p.entering_shelter.connect(func(_duration: float) -> void: _frozen_stopped = true)


func _process(delta: float) -> void:
	if enabled and not _frozen_stopped and not _dead:
		exposure = minf(exposure + delta / time_to_death, 1.0)
		if exposure >= 1.0:
			_final_close = minf(_final_close + delta / 1.5, 1.0)
			if _final_close >= 1.0:
				_die()
		elif exposure >= blink_start:
			_update_blinking(delta)

	var frost := _ramp(frost_range) * 0.9 + _ramp(Vector2(frost_range.y, 1.0)) * 0.1
	var darkness := _ramp(darkness_range) * 0.85
	# Heavy eyelids that droop lower the colder you get, plus the blinks on top.
	var droop := smoothstep(blink_start, 1.0, exposure) * 0.45
	var eyelids := droop + (1.0 - droop) * maxf(_blink, _final_close)
	if _dead:
		eyelids = 1.0

	_overlay.visible = exposure > 0.0 or _dead
	_material.set_shader_parameter("frost", frost)
	_material.set_shader_parameter("darkness", darkness)
	_material.set_shader_parameter("eyelids", eyelids)


func is_dead() -> bool:
	return _dead


func _ramp(range_: Vector2) -> float:
	return smoothstep(range_.x, range_.y, exposure)


func _update_blinking(delta: float) -> void:
	_next_blink -= delta
	if _next_blink > 0.0:
		return
	var t := inverse_lerp(blink_start, 1.0, exposure)
	_next_blink = lerpf(blink_interval.x, blink_interval.y, t) * randf_range(0.7, 1.3)
	if _blink_tween:
		_blink_tween.kill()
	# Eyes slam shut, stay closed, then struggle back open.
	_blink_tween = create_tween()
	_blink_tween.tween_property(self, "_blink", 1.0, 0.12)
	_blink_tween.tween_interval(lerpf(blink_hold.x, blink_hold.y, t))
	_blink_tween.tween_property(self, "_blink", 0.0, lerpf(0.3, 0.6, t)).set_ease(Tween.EASE_OUT)


func _die() -> void:
	_dead = true
	if _blink_tween:
		_blink_tween.kill()
	var p := get_node_or_null(player)
	if p and p.has_method("die"):
		p.die()
	_death_screen.show_death()
	died.emit()


func _build_overlay() -> void:
	var noise := FastNoiseLite.new()
	# Ridged noise gives thin branching veins, like ice crystals on glass.
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.012
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	noise.fractal_octaves = 5
	noise.fractal_gain = 0.6
	var frost_tex := NoiseTexture2D.new()
	frost_tex.width = 512
	frost_tex.height = 512
	frost_tex.seamless = true
	frost_tex.noise = noise

	_material = ShaderMaterial.new()
	_material.shader = OVERLAY_SHADER
	_material.set_shader_parameter("frost_tex", frost_tex)

	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.material = _material
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
