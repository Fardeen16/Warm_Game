class_name Helicopter
extends Node3D
## Rescue helicopter (Huey model by Sami, CC BY 4.0). Spins its rotors, makes its own rotor
## noise in 3D (loud overhead, faint far away), and can lower a rope from the side door.
## The gunship weapons from the model are hidden.

## Main rotor turns per second.
@export_range(0.0, 10.0, 0.1) var rotor_speed: float = 5.0
## Rope length when fully lowered (m).
@export var rope_length: float = 16.0
## Where the rope hangs from, in the helicopter's space (the open side door).
@export var rope_anchor: Vector3 = Vector3(1.3, 1.6, 0.4)
## Assign a recorded rotor loop here to use it instead of the generated sound.
@export var rotor_sound: AudioStream

const TEXTURE := preload("res://assets/models/props/helicopter/Huey Texture 2.0.png")
const MIX_RATE := 22050.0

@onready var _model: Node3D = $Model
@onready var _audio: AudioStreamPlayer3D = $RotorSound
@onready var _rope: Node3D = $Rope

var rope_out := 0.0  # 0 = rope pulled up, 1 = fully lowered
var _rotor: Node3D
var _rear_rotor: Node3D
var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0
var _whine_phase := 0.0
var _lp := 0.0
var _rumble := 0.0


func _ready() -> void:
	var weapons := _model.find_child("Weapon Chassise", true, false)
	if weapons:
		weapons.visible = false
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = TEXTURE
	mat.roughness = 0.7
	for mesh: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = mat
	_rotor = _model.find_child("Rotor", true, false)
	_rear_rotor = _model.find_child("Rear Rotor", true, false)
	_rope.position = rope_anchor

	if rotor_sound:
		_audio.stream = rotor_sound
		_audio.play()
	else:
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = MIX_RATE
		generator.buffer_length = 0.25
		_audio.stream = generator
		_audio.play()
		_playback = _audio.get_stream_playback()


func _process(delta: float) -> void:
	if _rotor:
		_rotor.rotate_object_local(Vector3.BACK, rotor_speed * TAU * delta)
	if _rear_rotor:
		_rear_rotor.rotate_object_local(Vector3.RIGHT, rotor_speed * 4.5 * TAU * delta)
	_rope.visible = rope_out > 0.001
	_rope.scale = Vector3(1.0, maxf(rope_out, 0.001) * rope_length, 1.0)
	_feed_sound()


## World position of the bottom end of the rope.
func rope_end() -> Vector3:
	return to_global(rope_anchor + Vector3.DOWN * rope_out * rope_length)


## Rotor noise: a heavy blade "whup" twice per turn, a low rumble, rushing air and a faint
## turbine whine.
func _feed_sound() -> void:
	if _playback == null:
		return
	var blade_rate := rotor_speed * 2.0
	for f in _playback.get_frames_available():
		_phase = fmod(_phase + blade_rate / MIX_RATE, 1.0)
		_whine_phase = fmod(_whine_phase + 1500.0 / MIX_RATE, 1.0)
		var noise := randf() * 2.0 - 1.0
		_lp += 0.08 * (noise - _lp)
		_rumble += 0.01 * (noise - _rumble)
		var slap := exp(-_phase * 9.0)
		var s := _lp * slap * 2.2 + sin(_phase * TAU * 7.0) * slap * 0.45
		s += _rumble * 3.0 + noise * 0.05 + sin(_whine_phase * TAU) * 0.025
		_playback.push_frame(Vector2.ONE * clampf(s, -1.0, 1.0))
