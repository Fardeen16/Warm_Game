class_name Lantern
extends Node3D
## Handheld lantern. Burns with a soft wobble, then flickers and sputters harder as the
## player freezes (reads FreezeEffect's exposure), and goes out when they die.
## Swap the Model node for your own lantern; keep the Light node.

@export var light_energy: float = 1.6
## Material whose glow follows the flame (the lantern glass). Optional.
@export var glow_material: StandardMaterial3D
@export var glow_energy: float = 2.0
## Small flame mesh that shrinks as the light dims. Optional.
@export var flame: Node3D
## Exposure (0-1, from FreezeEffect) at which the flame starts flickering.
@export_range(0.0, 1.0, 0.01) var flicker_start: float = 0.6
## How fast it flickers once freezing sets in.
@export_range(1.0, 40.0, 0.5) var flicker_speed: float = 14.0
## Seconds for the flame to die out after the player dies.
@export_range(0.1, 5.0, 0.1) var die_out_time: float = 1.5

@onready var _light: OmniLight3D = $Light

var _noise := FastNoiseLite.new()
var _time := 0.0
var _sputter := 0.0
var _alive := 1.0


func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 1.0
	_noise.seed = randi()


func _process(delta: float) -> void:
	_time += delta
	var freeze := get_tree().get_first_node_in_group("freeze_effect")
	var exposure: float = freeze.exposure if freeze else 0.0
	var strength := smoothstep(flicker_start, 1.0, exposure)

	# A gentle wobble always, a wild flicker the colder it gets.
	var level := 1.0 + _noise.get_noise_1d(_time * 3.0) * 0.06
	level += _noise.get_noise_1d(_time * flicker_speed + 100.0) * strength * 0.8

	# Sputtering: the flame nearly goes out for a moment, more often near the end.
	if _sputter > 0.0:
		_sputter -= delta
		level *= 0.06
	elif randf() < strength * strength * delta * 4.0:
		_sputter = randf_range(0.05, 0.3)

	if freeze and freeze.is_dead():
		_alive = move_toward(_alive, 0.0, delta / die_out_time)
	level = maxf(level, 0.0) * _alive

	_light.light_energy = light_energy * level
	if glow_material:
		glow_material.emission_energy_multiplier = glow_energy * level
	if flame:
		flame.visible = level > 0.03
		flame.scale = Vector3.ONE * lerpf(0.5, 1.0, minf(level, 1.0))
