class_name SynthAudio
extends Node

# ==============================================================================
# SYNTH AUDIO - BỘ PHÁT ÂM THANH PROCEDURAL SFX TỔNG HỢP BẰNG CODE
# Task 5.2: Triệt tiêu 100% lag - Pre-baked Cache & 12 AudioStreamPlayer Pool
# ==============================================================================

static var _instance: SynthAudio = null
static var _audio_cache: Dictionary = {}
static var _is_prebaked: bool = false

var players: Array[AudioStreamPlayer] = []
var max_players: int = 12
var current_player_idx: int = 0

var sfx_cast: AudioStream:
	get: return _audio_cache.get("cast", null)
var sfx_dash: AudioStream:
	get: return _audio_cache.get("dash", null)
var sfx_explosion: AudioStream:
	get: return _audio_cache.get("explosion", null)
var sfx_lightning: AudioStream:
	get: return _audio_cache.get("lightning", null)
var sfx_crystal: AudioStream:
	get: return _audio_cache.get("pickup_crystal", null)
var sfx_health: AudioStream:
	get: return _audio_cache.get("pickup_health", null)

func _init() -> void:
	if not _instance:
		_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _is_prebaked:
		_prebake_cache()

func _ready() -> void:
	if players.size() == 0:
		for i in range(max_players):
			var p = AudioStreamPlayer.new()
			add_child(p)
			players.append(p)

static func _ensure_instance() -> SynthAudio:
	if not _instance:
		var script_res = load("res://scripts/core/synth_audio.gd") as GDScript
		_instance = script_res.new()
		var tree = Engine.get_main_loop() as SceneTree
		if tree and tree.root:
			if _instance.get_parent() == null:
				tree.root.call_deferred("add_child", _instance)
	if not _is_prebaked:
		_instance._prebake_cache()
	return _instance

func _prebake_cache() -> void:
	if _is_prebaked:
		return
	_is_prebaked = true
	_audio_cache["cast"] = _generate_tone(440.0, 660.0, 0.12, "sine")
	_audio_cache["dash"] = _generate_noise_whoosh(0.18)
	_audio_cache["explosion"] = _generate_explosion_boom(0.3)
	_audio_cache["lightning"] = _generate_tone(150.0, 80.0, 0.22, "saw")
	_audio_cache["pickup_crystal"] = _generate_chime([587.33, 880.0], 0.28)
	_audio_cache["pickup_health"] = _generate_chime([523.25, 659.25, 783.99], 0.24)
	print("🎵 [SYNTH AUDIO] Pre-baked 6 procedural waveform streams into cache.")

func _play(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not is_inside_tree() or players.size() == 0:
		if players.size() == 0 and is_inside_tree():
			for i in range(max_players):
				var p = AudioStreamPlayer.new()
				add_child(p)
				players.append(p)
		else:
			return
			
	var player = players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % max_players
	player.stream = stream
	player.volume_db = volume_db
	player.play()

static func play_slash() -> void:
	var inst = _ensure_instance()
	if inst and _audio_cache.has("cast"):
		inst._play(_audio_cache["cast"], -5.0)

static func play_player_hit() -> void:
	var inst = _ensure_instance()
	if inst and _audio_cache.has("explosion"):
		inst._play(_audio_cache["explosion"], -6.0)

static func play_cast() -> void:
	var inst = _ensure_instance()
	if inst and _audio_cache.has("cast"):
		inst._play(_audio_cache["cast"], -6.0)

static func play_dash() -> void:
	var inst = _ensure_instance()
	if inst and _audio_cache.has("dash"):
		inst._play(_audio_cache["dash"], -4.0)

static func play_explosion() -> void:
	var inst = _ensure_instance()
	if inst and _audio_cache.has("explosion"):
		inst._play(_audio_cache["explosion"], -2.0)

static func play_lightning() -> void:
	var inst = _ensure_instance()
	if inst and _audio_cache.has("lightning"):
		inst._play(_audio_cache["lightning"], -4.0)

static func play_crystal_pickup() -> void:
	var inst = _ensure_instance()
	if inst and _audio_cache.has("pickup_crystal"):
		inst._play(_audio_cache["pickup_crystal"], 0.0)

static func play_crystal() -> void:
	play_crystal_pickup()

static func play_health_pickup() -> void:
	var inst = _ensure_instance()
	if inst and _audio_cache.has("pickup_health"):
		inst._play(_audio_cache["pickup_health"], 0.0)

# ==============================================================================
# PROCEDURAL WAVEFORM GENERATORS (ONLY RUN ONCE AT INIT)
# ==============================================================================

func _generate_tone(start_freq: float, end_freq: float, duration: float, wave_type: String = "sine") -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)
		var freq = lerp(start_freq, end_freq, progress)
		var envelope = 1.0 - progress
		
		var sample_val := 0.0
		if wave_type == "sine":
			sample_val = sin(TAU * freq * t)
		elif wave_type == "saw":
			sample_val = (fmod(freq * t, 1.0) * 2.0 - 1.0)
		
		var val_16 = int(clamp(sample_val * envelope * 0.75, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, val_16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav

func _generate_noise_whoosh(duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)
	
	for i in range(num_samples):
		var progress = float(i) / float(num_samples)
		var envelope = sin(progress * PI)
		var noise = randf_range(-1.0, 1.0)
		var val_16 = int(clamp(noise * envelope * 0.45, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, val_16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav

func _generate_explosion_boom(duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)
		var envelope = exp(-progress * 7.0)
		var sub_bass = sin(TAU * 55.0 * t)
		var noise = randf_range(-0.5, 0.5)
		var sample_val = (sub_bass * 0.7 + noise * 0.3) * envelope
		var val_16 = int(clamp(sample_val * 0.85, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, val_16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav

func _generate_chime(notes: Array[float], duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)
		var envelope = exp(-progress * 5.0)
		
		var sample_val := 0.0
		for freq in notes:
			sample_val += sin(TAU * freq * t)
		sample_val = (sample_val / float(notes.size())) * envelope
		
		var val_16 = int(clamp(sample_val * 0.65, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, val_16)
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav
