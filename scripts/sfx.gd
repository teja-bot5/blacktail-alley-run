class_name Sfx
extends Node
## All audio is synthesised at startup (no files, no licences): paw steps,
## jump, landing, fish pickup, hit, game over, rooftop ambience and a short
## looping tune (plucked pentatonic melody over a drone with soft hand drums).

const RATE := 22050
const LEVELS := [0.0, -9.0, -80.0]  # master volume steps: on, low, off (dB)
const LEVEL_NAMES := ["ON", "LOW", "OFF"]

var level := 0
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _loop_music: AudioStreamPlayer
var _loop_amb: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 11
	_streams.step = _make(0.05, func(t, i): return _noise() * exp(-t * 90.0) * 0.5, 600.0)
	_streams.jump = _make(0.18, func(t, i): return _noise() * sin(PI * t / 0.18) * 0.35, 1800.0)
	_streams.land = _make(0.14, func(t, i): return (sin(TAU * (95.0 - 260.0 * t) * t) * 0.8 + _noise() * 0.4) * exp(-t * 28.0) * 0.6, 900.0)
	_streams.fish = _make(0.2, func(t, i): return (sin(TAU * 1320.0 * t) * float(t < 0.07) + sin(TAU * 1760.0 * t) * float(t >= 0.07)) * exp(-fmod(t, 0.07) * 18.0) * 0.28, 0.0)
	_streams.hit = _make(0.28, func(t, i): return (signf(sin(TAU * (120.0 - 150.0 * t) * t)) * 0.4 + _noise() * 0.6) * exp(-t * 14.0) * 0.45, 1400.0)
	_streams.over = _make(0.9, func(t, i): return _over_tone(t), 0.0)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_loop_amb = AudioStreamPlayer.new()
	_loop_amb.stream = _ambience()
	_loop_amb.volume_db = -14.0
	add_child(_loop_amb)
	_loop_amb.play()
	# The tune takes a moment to synthesise: do it after the first frame.
	_loop_music = AudioStreamPlayer.new()
	_loop_music.volume_db = -10.0
	add_child(_loop_music)
	_build_music.call_deferred()


func play(name: String, vol_db := 0.0, pitch_jitter := 0.0) -> void:
	for p in _players:
		if not p.playing:
			p.stream = _streams[name]
			p.volume_db = vol_db
			p.pitch_scale = 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter)
			p.play()
			return


func cycle_level() -> String:
	level = (level + 1) % LEVELS.size()
	AudioServer.set_bus_volume_db(0, LEVELS[level])
	AudioServer.set_bus_mute(0, level == LEVELS.size() - 1)
	return LEVEL_NAMES[level]


# ---------------- Synthesis ----------------

func _noise() -> float:
	return _rng.randf_range(-1.0, 1.0)


## Render fn(t, i) into a 16-bit WAV, optionally one-pole low-passed at `cutoff` Hz.
func _make(seconds: float, fn: Callable, cutoff: float) -> AudioStreamWAV:
	var n := int(seconds * RATE)
	var a := 1.0 - exp(-TAU * cutoff / RATE) if cutoff > 0.0 else 1.0
	var y := 0.0
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		y += (fn.call(float(i) / RATE, i) - y) * a
		data.encode_s16(i * 2, int(clampf(y, -1.0, 1.0) * 32000.0))
	return _wav(data)


func _wav(data: PackedByteArray, loop := false) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = data.size() / 2
	return s


func _over_tone(t: float) -> float:
	var notes := [392.0, 330.0, 262.0]
	var k := mini(int(t / 0.3), 2)
	var lt := t - k * 0.3
	return (sin(TAU * notes[k] * lt) + 0.4 * sin(TAU * notes[k] * 2.0 * lt)) * exp(-lt * 6.0) * 0.3


## Soft wind (filtered noise) with a few distant bird chirps; ends cross-faded so it loops cleanly.
func _ambience() -> AudioStreamWAV:
	var n := 4 * RATE
	var buf := PackedFloat32Array()
	buf.resize(n)
	var y := 0.0
	for i in n:
		y += (_noise() - y) * 0.02
		buf[i] = y * 2.2
	for c in [0.7, 2.3, 3.1]:
		var start := int(c * RATE)
		for i in int(0.09 * RATE):
			var t := float(i) / RATE
			buf[start + i] += sin(TAU * (2600.0 + 9000.0 * t) * t) * sin(PI * t / 0.09) * 0.12
	var fade := int(0.3 * RATE)
	for i in fade:
		var k := float(i) / fade
		buf[i] = buf[i] * k + buf[n - fade + i] * (1.0 - k)
	return _wav(_pcm(buf, n - fade), true)


func _build_music() -> void:
	var bpm := 96.0
	var beat := 60.0 / bpm
	var n := int(16 * beat * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	# Drone on C and G.
	for i in n:
		var t := float(i) / RATE
		var swell := 0.75 + 0.25 * sin(TAU * t / (16 * beat))
		buf[i] = (sin(TAU * 130.81 * t) + 0.5 * sin(TAU * 196.0 * t) + 0.25 * sin(TAU * 261.63 * t)) * 0.08 * swell
	# Plucked pentatonic melody (Karplus-Strong).
	var scale := [261.63, 293.66, 329.63, 392.0, 440.0, 523.25]
	var melody := [0, 2, 3, 4, 3, 2, 0, -1, 1, 3, 4, 5, 4, 3, 1, -1]
	for b in 16:
		if melody[b] < 0:
			continue
		_pluck(buf, int(b * beat * RATE), scale[melody[b]], 0.9 * beat, 0.22)
		if b % 4 == 1:
			_pluck(buf, int((b + 0.5) * beat * RATE), scale[melody[b]] * 2.0, 0.4 * beat, 0.1)
	# Hand drums: low "dha" on 1 and 3, light "na" on the off-beats.
	for b in 16:
		var s := int(b * beat * RATE)
		var low := b % 4 == 0 or b % 4 == 2
		for i in int(0.18 * RATE):
			var t := float(i) / RATE
			var v := sin(TAU * (150.0 - 220.0 * t) * t) * exp(-t * 18.0) * 0.32 if low else sin(TAU * 620.0 * t) * exp(-t * 40.0) * 0.12
			if s + i < n:
				buf[s + i] += v
	_loop_music.stream = _wav(_pcm(buf, n), true)
	_loop_music.play()


func _pluck(buf: PackedFloat32Array, start: int, freq: float, seconds: float, amp: float) -> void:
	var period := int(RATE / freq)
	var ring := PackedFloat32Array()
	ring.resize(period)
	for i in period:
		ring[i] = _noise()
	var idx := 0
	for i in int(seconds * RATE):
		if start + i >= buf.size():
			return
		var nxt := (idx + 1) % period
		ring[idx] = (ring[idx] + ring[nxt]) * 0.497
		buf[start + i] += ring[idx] * amp
		idx = nxt


func _pcm(buf: PackedFloat32Array, n: int) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 30000.0))
	return data
