class_name StormAudio
extends AudioStreamPlayer
## Blizzard soundscape: a constant heavy wind (deep rumble plus a howl that surges and dips) and
## random gusts that rush past now and then. Gets louder and wilder with the SnowStorm's
## intensity and wind strength. Assign a recorded loop to `stream` to use that instead.

@export var storm: NodePath
## Seconds between gusts, picked at random in this range.
@export var gust_interval: Vector2 = Vector2(4.0, 11.0)
## How much louder a gust is than the steady wind.
@export_range(0.0, 3.0, 0.05) var gust_strength: float = 1.8

const MIX_RATE := 22050.0

var _playback: AudioStreamGeneratorPlayback
var _storm: SnowStorm
var _time := 0.0
var _rumble := 0.0
var _low := 0.0
var _band := 0.0
var _gust := 0.0
var _gust_target := 0.0
var _next_gust := 2.0
var _surge_noise := FastNoiseLite.new()


func _ready() -> void:
	_storm = get_node_or_null(storm) as SnowStorm
	_surge_noise.frequency = 0.25
	_surge_noise.seed = randi()
	if stream == null:
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = MIX_RATE
		generator.buffer_length = 0.25
		stream = generator
		play()
		_playback = get_stream_playback()
	else:
		play()


func _process(delta: float) -> void:
	# Fiercer storm, louder wind.
	var force := 1.0
	if _storm:
		# Square root so a much stronger storm is louder without blowing out the speakers.
		force = clampf(sqrt(_storm.intensity * _storm.wind_strength * _storm.storm_speed / 8.0), 0.4, 1.6)
	if _playback == null:
		return

	_next_gust -= delta
	if _next_gust <= 0.0:
		_next_gust = randf_range(gust_interval.x, gust_interval.y)
		_gust_target = randf_range(0.6, 1.0) * gust_strength

	for f in _playback.get_frames_available():
		var dt := 1.0 / MIX_RATE
		_time += dt
		# Gusts swell in fast and die away slowly.
		_gust = move_toward(_gust, _gust_target, dt * (1.5 if _gust < _gust_target else 0.4))
		if _gust >= _gust_target:
			_gust_target = 0.0
		var surge := 0.6 + 0.4 * _surge_noise.get_noise_1d(_time)

		var white := randf() * 2.0 - 1.0
		_rumble += 0.012 * (white - _rumble)
		# Howl: noise through a sweeping resonant filter (higher and sharper in a gust).
		var cutoff := 260.0 + 320.0 * surge + 700.0 * _gust
		var g := 2.0 * sin(PI * cutoff / MIX_RATE)
		var high := white - _low - 0.35 * _band
		_band += g * high
		_low += g * _band
		var s := _rumble * 4.0 * (0.7 + 0.3 * surge) + _band * 0.22 * (surge + _gust) + white * 0.03 * _gust
		_playback.push_frame(Vector2.ONE * clampf(s * force * 0.55, -1.0, 1.0))
