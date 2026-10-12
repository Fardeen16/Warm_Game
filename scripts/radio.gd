class_name Radio
extends Node3D
## Handheld radio mini-game. Two knobs on top each clear one of two overlapping static noises
## when turned to their hidden frequency: left knob first, then right. The active knob's static
## fades as you get close; hold it there to lock it in. With both locked the static is gone,
## a call comes through and the green light comes on.
## Turn with A/D (or arrow keys) or the mouse wheel. Sounds are generated unless you assign
## your own streams (on StaticLeft / StaticRight, or lock_sound / solved_sound below).

signal knob_locked(index: int)
signal solved

@export var enabled: bool = true
## Degrees the knob turns per second with A/D or the arrow keys.
@export_range(5.0, 360.0, 1.0) var turn_speed: float = 60.0
## Degrees per mouse wheel notch.
@export_range(0.5, 30.0, 0.5) var scroll_step: float = 3.0
## Knobs turn between 0 and this many degrees.
@export_range(30.0, 340.0, 1.0) var knob_range: float = 300.0
## How close (degrees) counts as tuned in.
@export_range(1.0, 30.0, 0.5) var tolerance: float = 5.0
## Seconds to hold a knob on the frequency before it locks.
@export_range(0.0, 3.0, 0.1) var lock_time: float = 0.8
## Within this many degrees the static starts fading, so you can hear you're getting close.
@export_range(5.0, 180.0, 1.0) var hearing_range: float = 70.0

@export_group("Sounds")
## Leave empty to use the built-in generated sounds.
@export var lock_sound: AudioStream
@export var solved_sound: AudioStream

const MIX_RATE := 22050.0
const KNOB_OFF := Color(0.25, 0.25, 0.25)
const KNOB_ACTIVE := Color(1.0, 0.6, 0.2)
const LOCKED := Color(0.2, 1.0, 0.3)

@onready var _knobs: Array[Node3D] = [$Model/KnobLeft, $Model/KnobRight]
@onready var _statics: Array[AudioStreamPlayer] = [$StaticLeft, $StaticRight]
@onready var _sfx: AudioStreamPlayer = $Sfx
@onready var _led: MeshInstance3D = $Model/Led
@onready var _led_light: OmniLight3D = $LedLight

var _angles: Array[float] = [0.0, 0.0]
var _targets: Array[float] = [0.0, 0.0]
var _locked: Array[bool] = [false, false]
var _gains: Array[float] = [1.0, 1.0]
var _playbacks: Array = [null, null]
var _active := 0
var _hold := 0.0
var _is_solved := false
var _time := 0.0
var _pointer_mats: Array[StandardMaterial3D] = []
var _led_mat: StandardMaterial3D

# Noise generator state.
var _lp := 0.0
var _lp_slow := 0.0
var _pop := 0.0
var _brown := 0.0
var _whistle_phase := 0.0
var _hum_phase := 0.0


func _ready() -> void:
	for i in 2:
		# Hidden frequency, never too close to where the knob starts.
		_targets[i] = randf_range(knob_range * 0.2, knob_range * 0.9)
		if _statics[i].stream == null:
			var generator := AudioStreamGenerator.new()
			generator.mix_rate = MIX_RATE
			generator.buffer_length = 0.2
			_statics[i].stream = generator
			_statics[i].play()
			_playbacks[i] = _statics[i].get_stream_playback()
		else:
			_statics[i].play()
		var mat := StandardMaterial3D.new()
		mat.emission_enabled = true
		(_knobs[i].get_node("Pointer") as MeshInstance3D).material_override = mat
		_pointer_mats.append(mat)

	_led_mat = StandardMaterial3D.new()
	_led_mat.emission_enabled = true
	_led.material_override = _led_mat
	if lock_sound == null:
		lock_sound = _make_click()
	if solved_sound == null:
		solved_sound = _make_call()


func _process(delta: float) -> void:
	_time += delta
	if enabled and not _is_solved:
		_turn(Input.get_axis("move_left", "move_right") * turn_speed * delta)
		if absf(_angles[_active] - _targets[_active]) <= tolerance:
			_hold += delta
			if _hold >= lock_time:
				_lock(_active)
		else:
			_hold = 0.0

	for i in 2:
		var target_gain := 0.0
		if not _locked[i] and enabled:
			var diff := absf(_angles[i] - _targets[i])
			target_gain = lerpf(0.1, 1.0, smoothstep(tolerance, hearing_range, diff))
		_gains[i] = move_toward(_gains[i], target_gain, delta * 2.0)
		if _playbacks[i] == null:
			_statics[i].volume_db = linear_to_db(maxf(_gains[i], 0.0001))
		else:
			_fill(i)
		_knobs[i].rotation.y = -deg_to_rad(_angles[i])
		_update_pointer(i)

	var led_on := LOCKED if _is_solved else Color(0.3, 0.02, 0.02)
	_led_mat.albedo_color = led_on
	_led_mat.emission = led_on
	_led_mat.emission_energy_multiplier = 3.0 if _is_solved else 0.4
	_led_light.visible = _is_solved


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_turn(scroll_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_turn(-scroll_step)


## Which knob you're tuning: 0 = left, 1 = right.
func get_active_knob() -> int:
	return _active


func is_solved() -> bool:
	return _is_solved


func _turn(amount: float) -> void:
	if not enabled or _is_solved or _locked[_active]:
		return
	_angles[_active] = clampf(_angles[_active] + amount, 0.0, knob_range)


func _lock(index: int) -> void:
	_locked[index] = true
	_angles[index] = _targets[index]
	_hold = 0.0
	_sfx.stream = lock_sound
	_sfx.play()
	# Move on before announcing the lock, so listeners see the new state.
	if index == 0:
		_active = 1
	else:
		_is_solved = true
	knob_locked.emit(index)
	if _is_solved:
		await get_tree().create_timer(0.5).timeout
		_sfx.stream = solved_sound
		_sfx.play()
		solved.emit()


func _update_pointer(i: int) -> void:
	var color := KNOB_OFF
	if _locked[i]:
		color = LOCKED
	elif i == _active and enabled:
		color = KNOB_ACTIVE * (0.7 + 0.3 * sin(_time * 4.0))
	_pointer_mats[i].albedo_color = color
	_pointer_mats[i].emission = color
	_pointer_mats[i].emission_energy_multiplier = 0.2 if color == KNOB_OFF else 1.5


## Streams the generated static: left is a harsh hiss with crackles, right is a rumbling buzz
## with a whistle that drops in pitch as the knob nears its frequency, like tuning a real radio.
func _fill(i: int) -> void:
	var playback: AudioStreamGeneratorPlayback = _playbacks[i]
	var frames := playback.get_frames_available()
	var gain := _gains[i]
	var whistle_freq := 90.0 + absf(_angles[1] - _targets[1]) * 14.0
	for f in frames:
		var s := 0.0
		if i == 0:
			var white := randf() * 2.0 - 1.0
			_lp += 0.6 * (white - _lp)
			_lp_slow += 0.05 * (_lp - _lp_slow)
			s = (_lp - _lp_slow) * 0.55
			if randf() < 0.0005:
				_pop = 0.7
			s += _pop * (randf() * 2.0 - 1.0)
			_pop *= 0.993
		else:
			_brown = clampf(_brown * 0.997 + (randf() * 2.0 - 1.0) * 0.05, -1.0, 1.0)
			_whistle_phase = fmod(_whistle_phase + TAU * whistle_freq / MIX_RATE, TAU)
			_hum_phase = fmod(_hum_phase + TAU * 60.0 / MIX_RATE, TAU * 100.0)
			var warble := 0.65 + 0.35 * sin(_hum_phase * 0.03)
			s = (_brown * 0.8 + sin(_whistle_phase) * 0.16 + signf(sin(_hum_phase)) * 0.03) * warble
		playback.push_frame(Vector2.ONE * s * gain * 0.6)


func _make_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(MIX_RATE)
	wav.data = data
	return wav


## Sharp mechanical click for a knob locking into place.
func _make_click() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	for n in int(MIX_RATE * 0.07):
		var t := n / MIX_RATE
		samples.append((randf() * 2.0 - 1.0) * exp(-t * 140.0) * 0.6 + sin(TAU * 1800.0 * t) * exp(-t * 70.0) * 0.4)
	return _make_wav(samples)


## The call coming through: squelch, three beeps, a rising chirp, squelch tail.
func _make_call() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var add_noise := func(seconds: float) -> void:
		for n in int(MIX_RATE * seconds):
			samples.append((randf() * 2.0 - 1.0) * 0.35 * (1.0 - n / (MIX_RATE * seconds)))
	var add_tone := func(seconds: float, from_hz: float, to_hz: float) -> void:
		var phase := 0.0
		for n in int(MIX_RATE * seconds):
			var k := n / (MIX_RATE * seconds)
			phase += TAU * lerpf(from_hz, to_hz, k) / MIX_RATE
			samples.append(sin(phase) * 0.45 * minf(1.0, minf(k, 1.0 - k) * 20.0))
	var add_silence := func(seconds: float) -> void:
		for n in int(MIX_RATE * seconds):
			samples.append(0.0)

	add_noise.call(0.18)
	for beep in 3:
		add_tone.call(0.1, 1200.0, 1200.0)
		add_silence.call(0.08)
	add_silence.call(0.1)
	add_tone.call(0.35, 700.0, 1150.0)
	add_noise.call(0.12)
	return _make_wav(samples)
