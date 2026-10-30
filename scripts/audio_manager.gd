extends Node

# Procedural Sound Synthesizer for THE GREAT GEM CAPER
# Generates zero-dependency 16-bit PCM sounds directly in memory.

var _sfx_players: Array[AudioStreamPlayer] = []
var _siren_player: AudioStreamPlayer = null
const MIX_RATE: int = 22050

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pre-allocate audio stream players for polyphony
	for i in range(8):
		var asp := AudioStreamPlayer.new()
		asp.bus = &"Master"
		add_child(asp)
		_sfx_players.append(asp)
	
	_siren_player = AudioStreamPlayer.new()
	_siren_player.bus = &"Master"
	add_child(_siren_player)

func _get_free_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]

func _create_wav(samples: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = samples
	return wav

func play_click() -> void:
	var duration: float = 0.05
	var num_samples: int = int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var t: float = float(i) / float(MIX_RATE)
		var env: float = 1.0 - (float(i) / float(num_samples))
		var val: float = sin(t * 1200.0 * TAU) * env * 0.4
		var sample_val: int = clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample_val)
	var player := _get_free_player()
	player.stream = _create_wav(bytes)
	player.play()

func play_beep(freq: float = 880.0, duration: float = 0.12) -> void:
	var num_samples: int = int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var t: float = float(i) / float(MIX_RATE)
		var env: float = 1.0 - (float(i) / float(num_samples))
		var val: float = sin(t * freq * TAU) * env * 0.35
		var sample_val: int = clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample_val)
	var player := _get_free_player()
	player.stream = _create_wav(bytes)
	player.play()

func play_terminal_hack() -> void:
	var duration: float = 0.28
	var num_samples: int = int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var t: float = float(i) / float(MIX_RATE)
		var freq: float = 800.0 + (sin(t * 80.0) * 400.0)
		var env: float = clampf(1.0 - (t / duration), 0.0, 1.0)
		var val: float = sin(t * freq * TAU) * env * 0.3
		var sample_val: int = clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample_val)
	var player := _get_free_player()
	player.stream = _create_wav(bytes)
	player.play()

func play_success() -> void:
	# Arpeggio chord C5 - E5 - G5 - C6
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.50]
	var note_dur: float = 0.10
	var total_dur: float = note_dur * notes.size() + 0.2
	var num_samples: int = int(MIX_RATE * total_dur)
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var t: float = float(i) / float(MIX_RATE)
		var note_idx: int = mini(int(t / note_dur), notes.size() - 1)
		var note_t: float = t - (note_idx * note_dur)
		var freq: float = notes[note_idx]
		var env: float = clampf(1.0 - (t / total_dur), 0.0, 1.0)
		var val: float = (sin(t * freq * TAU) + 0.2 * sin(t * freq * 2.0 * TAU)) * env * 0.35
		var sample_val: int = clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample_val)
	var player := _get_free_player()
	player.stream = _create_wav(bytes)
	player.play()

func play_buzzer() -> void:
	var duration: float = 0.35
	var num_samples: int = int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var t: float = float(i) / float(MIX_RATE)
		var env: float = 1.0 - (float(i) / float(num_samples))
		# Low buzz saw wave
		var wave: float = fmod(t * 130.0, 1.0) * 2.0 - 1.0
		var val: float = wave * env * 0.4
		var sample_val: int = clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample_val)
	var player := _get_free_player()
	player.stream = _create_wav(bytes)
	player.play()

func play_laser_zap() -> void:
	var duration: float = 0.25
	var num_samples: int = int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var t: float = float(i) / float(MIX_RATE)
		var frac: float = float(i) / float(num_samples)
		# Downward frequency sweep from 1400Hz to 200Hz
		var freq: float = lerpf(1400.0, 200.0, frac)
		var noise: float = (randf() * 2.0 - 1.0) * 0.2
		var val: float = (sin(t * freq * TAU) + noise) * (1.0 - frac) * 0.45
		var sample_val: int = clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample_val)
	var player := _get_free_player()
	player.stream = _create_wav(bytes)
	player.play()

func play_vault_open() -> void:
	var duration: float = 1.2
	var num_samples: int = int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var t: float = float(i) / float(MIX_RATE)
		var frac: float = float(i) / float(num_samples)
		# Heavy low rumble + rising mechanical whine
		var rumble: float = sin(t * 45.0 * TAU) * 0.35 + sin(t * 85.0 * TAU) * 0.2
		var whine: float = sin(t * (200.0 + frac * 400.0) * TAU) * 0.15
		var env: float = 1.0 - absf(frac - 0.5) * 0.8
		var val: float = (rumble + whine) * env * 0.5
		var sample_val: int = clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample_val)
	var player := _get_free_player()
	player.stream = _create_wav(bytes)
	player.play()

func play_gem_pickup() -> void:
	# Shimmering high sparkle
	var duration: float = 0.6
	var num_samples: int = int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var t: float = float(i) / float(MIX_RATE)
		var frac: float = float(i) / float(num_samples)
		var val: float = (sin(t * 1318.5 * TAU) + sin(t * 1760.0 * TAU) + sin(t * 2093.0 * TAU)) * (1.0 - frac) * 0.25
		var sample_val: int = clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample_val)
	var player := _get_free_player()
	player.stream = _create_wav(bytes)
	player.play()

func start_alarm_siren() -> void:
	if _siren_player.playing:
		return
	var duration: float = 1.6
	var num_samples: int = int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var t: float = float(i) / float(MIX_RATE)
		# Wailing siren pitch oscillating between 600Hz and 1000Hz
		var lfo: float = (sin(t * 1.25 * TAU) + 1.0) * 0.5
		var freq: float = lerpf(600.0, 1000.0, lfo)
		var val: float = sin(t * freq * TAU) * 0.28
		var sample_val: int = clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample_val)
	var wav := _create_wav(bytes)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	_siren_player.stream = wav
	_siren_player.play()

func stop_alarm_siren() -> void:
	if _siren_player:
		_siren_player.stop()
