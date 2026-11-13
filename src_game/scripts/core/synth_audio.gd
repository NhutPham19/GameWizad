class_name SynthAudio
extends Node

# ==============================================================================
# SYNTH AUDIO (PURGED - DIRECTIVE 29)
# - TUYỆT ĐỐI 0% SÓNG ÂM TỰ CHẾ, 0% NOISE
# - NẠP TRỰC TIẾP FILE ÂM THANH THẬT TỪ KENNEY RPG & IMPACT & SCI-FI PACKS
# - TÍCH HỢP LIÊN THÔNG VỚI KAYKIT AUDIO DIRECTOR
# ==============================================================================

const KayKitAudioDirector = preload("res://scripts/audio/kaykit_audio_director.gd")

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

	var p_cast = "res://assets/audio/rpg/knifeSlice.ogg"
	if ResourceLoader.exists(p_cast):
		_audio_cache["cast"] = ResourceLoader.load(p_cast)
	elif ResourceLoader.exists("res://assets/audio/slash.wav"):
		_audio_cache["cast"] = ResourceLoader.load("res://assets/audio/slash.wav")

	var p_dash = "res://assets/audio/rpg/cloth1.ogg"
	if ResourceLoader.exists(p_dash):
		_audio_cache["dash"] = ResourceLoader.load(p_dash)
	elif ResourceLoader.exists("res://assets/audio/dash.wav"):
		_audio_cache["dash"] = ResourceLoader.load("res://assets/audio/dash.wav")

	var p_exp = "res://assets/audio/scifi/explosionCrunch_000.ogg"
	if ResourceLoader.exists(p_exp):
		_audio_cache["explosion"] = ResourceLoader.load(p_exp)
	elif ResourceLoader.exists("res://assets/audio/impact/impactSoft_heavy_000.ogg"):
		_audio_cache["explosion"] = ResourceLoader.load("res://assets/audio/impact/impactSoft_heavy_000.ogg")
	elif ResourceLoader.exists("res://assets/audio/hit.wav"):
		_audio_cache["explosion"] = ResourceLoader.load("res://assets/audio/hit.wav")

	var p_light = "res://assets/audio/impact/impactMetal_heavy_000.ogg"
	if ResourceLoader.exists(p_light):
		_audio_cache["lightning"] = ResourceLoader.load(p_light)

	var p_crys = "res://assets/audio/pickup_crystal.wav"
	if ResourceLoader.exists(p_crys):
		_audio_cache["pickup_crystal"] = ResourceLoader.load(p_crys)
	elif ResourceLoader.exists("res://assets/audio/ui/glass_004.wav"):
		_audio_cache["pickup_crystal"] = ResourceLoader.load("res://assets/audio/ui/glass_004.wav")
	elif ResourceLoader.exists("res://assets/audio/crystal.wav"):
		_audio_cache["pickup_crystal"] = ResourceLoader.load("res://assets/audio/crystal.wav")

	var p_hp = "res://assets/audio/pickup_health.wav"
	if ResourceLoader.exists(p_hp):
		_audio_cache["pickup_health"] = ResourceLoader.load(p_hp)
	elif ResourceLoader.exists("res://assets/audio/ui/bong_001.wav"):
		_audio_cache["pickup_health"] = ResourceLoader.load("res://assets/audio/ui/bong_001.wav")

	print("🎵 [SYNTH AUDIO PURGED] Preloaded %d authentic audio streams into cache (0%% synthetic sine/noise)." % _audio_cache.size())

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
	KayKitAudioDirector.play_sfx("u1_slash")

static func play_player_hit() -> void:
	KayKitAudioDirector.play_sfx("hit_enemy_flesh_metal")

static func play_cast() -> void:
	KayKitAudioDirector.play_sfx("u2_slash")

static func play_dash() -> void:
	KayKitAudioDirector.play_sfx("dash_space")

static func play_explosion() -> void:
	KayKitAudioDirector.play_sfx("p_bomb_thunder_explode")

static func play_lightning() -> void:
	KayKitAudioDirector.play_sfx("p_bomb_dot_zap")

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
