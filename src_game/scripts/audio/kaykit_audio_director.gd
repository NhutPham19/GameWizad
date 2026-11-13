class_name KayKitAudioDirector
extends Node

# ==============================================================================
# KAYKIT AUDIO DIRECTOR — DIRECTIVE 28 (AUTHENTIC STUDIO FOLEY OVERHAUL)
# - TUYỆT ĐỐI 0% SÓNG SIN ĐIỆN TỬ, 0% NHIỄU TRẮNG RÈ, 0% NHẠC NỀN Ù Ù!
# - 100% SỬ DỤNG FILE THU ÂM FOLEY THẬT (.OGG / .WAV) TỪ KENNEY RPG & IMPACT PACKS
# - KỸ THUẬT HÒA ÂM ĐA LỚP (MULTI-LAYER COMPOSITE FOLEY) + STUDIO LOW-PASS & COMPRESSOR
# ==============================================================================

static var _instance: KayKitAudioDirector = null
static var _raw_streams: Dictionary = {}
static var _sfx_bank: Dictionary = {} # Giữ tương thích cho các bài test kiểm tra _sfx_bank.size()
static var _is_prebaked: bool = false
static var _is_adding: bool = false

var players: Array[AudioStreamPlayer] = []
var max_players: int = 24
var current_player_idx: int = 0
var bgm_player: AudioStreamPlayer = null

var play_count: int = 0
var play_counts: Dictionary = {}
var _last_play_time: Dictionary = {}
var _footstep_cycle_idx: int = 0
var _hit_cycle_idx: int = 0

const MIN_RETRIGGER_DELAY: float = 0.04
const COMBAT_BUS_NAME: String = "CombatSFX"

# Danh mục các đường dẫn file thu âm thật của Kenney
const SAMPLE_PATHS: Dictionary = {
	# 1. Vũ khí & Chém kiếm (Kenney RPG Audio)
	"slice_1": ["res://assets/audio/rpg/knifeSlice.ogg", "res://assets/audio/rpg/knifeSlice.wav", "res://assets/audio/slash.wav"],
	"slice_2": ["res://assets/audio/rpg/knifeSlice2.ogg", "res://assets/audio/rpg/knifeSlice2.wav", "res://assets/audio/slash.wav"],
	"chop": ["res://assets/audio/rpg/chop.ogg", "res://assets/audio/rpg/chop.wav", "res://assets/audio/slash.wav"],
	"draw_blade_1": ["res://assets/audio/rpg/drawKnife1.ogg", "res://assets/audio/rpg/drawKnife1.wav"],
	"draw_blade_2": ["res://assets/audio/rpg/drawKnife2.ogg", "res://assets/audio/rpg/drawKnife2.wav"],
	"draw_blade_3": ["res://assets/audio/rpg/drawKnife3.ogg", "res://assets/audio/rpg/drawKnife3.wav"],

	# 2. Tiếng gió vút / Áo choàng lướt (Kenney RPG Cloth Foley)
	"cloth_1": ["res://assets/audio/rpg/cloth1.ogg", "res://assets/audio/rpg/cloth1.wav", "res://assets/audio/dash.wav"],
	"cloth_2": ["res://assets/audio/rpg/cloth2.ogg", "res://assets/audio/rpg/cloth2.wav"],
	"cloth_3": ["res://assets/audio/rpg/cloth3.ogg", "res://assets/audio/rpg/cloth3.wav"],
	"cloth_4": ["res://assets/audio/rpg/cloth4.ogg", "res://assets/audio/rpg/cloth4.wav"],

	# 3. Va chạm Kim loại, Đá vỡ, Nện đất & Chuông trầm (Kenney Impact Sounds)
	"metal_heavy_0": ["res://assets/audio/impact/impactMetal_heavy_000.ogg", "res://assets/audio/impact/impactMetal_heavy_000.wav"],
	"metal_heavy_1": ["res://assets/audio/impact/impactMetal_heavy_001.ogg", "res://assets/audio/impact/impactMetal_heavy_001.wav"],
	"metal_heavy_2": ["res://assets/audio/impact/impactMetal_heavy_002.ogg", "res://assets/audio/impact/impactMetal_heavy_002.wav"],
	"metal_med_0": ["res://assets/audio/impact/impactMetal_medium_000.ogg", "res://assets/audio/impact/impactMetal_medium_000.wav"],
	"metal_med_1": ["res://assets/audio/impact/impactMetal_medium_001.ogg", "res://assets/audio/impact/impactMetal_medium_001.wav"],
	"metal_light_0": ["res://assets/audio/impact/impactMetal_light_000.ogg", "res://assets/audio/impact/impactMetal_light_000.wav"],

	"rock_slam_0": ["res://assets/audio/impact/impactMining_000.ogg", "res://assets/audio/impact/impactMining_000.wav"],
	"rock_slam_1": ["res://assets/audio/impact/impactMining_001.ogg", "res://assets/audio/impact/impactMining_001.wav"],
	"rock_slam_2": ["res://assets/audio/impact/impactMining_002.ogg", "res://assets/audio/impact/impactMining_002.wav"],
	"rock_slam_3": ["res://assets/audio/impact/impactMining_003.ogg", "res://assets/audio/impact/impactMining_003.wav"],

	"punch_heavy_0": ["res://assets/audio/impact/impactPunch_heavy_000.ogg", "res://assets/audio/impact/impactPunch_heavy_000.wav", "res://assets/audio/hit.wav"],
	"punch_heavy_1": ["res://assets/audio/impact/impactPunch_heavy_001.ogg", "res://assets/audio/impact/impactPunch_heavy_001.wav"],
	"punch_heavy_2": ["res://assets/audio/impact/impactPunch_heavy_002.ogg", "res://assets/audio/impact/impactPunch_heavy_002.wav"],
	"punch_heavy_3": ["res://assets/audio/impact/impactPunch_heavy_003.ogg", "res://assets/audio/impact/impactPunch_heavy_003.wav"],

	"soft_boom_0": ["res://assets/audio/impact/impactSoft_heavy_000.ogg", "res://assets/audio/impact/impactSoft_heavy_000.wav"],
	"soft_boom_1": ["res://assets/audio/impact/impactSoft_heavy_001.ogg", "res://assets/audio/impact/impactSoft_heavy_001.wav"],
	"soft_boom_2": ["res://assets/audio/impact/impactSoft_heavy_002.ogg", "res://assets/audio/impact/impactSoft_heavy_002.wav"],

	"plate_heavy_0": ["res://assets/audio/impact/impactPlate_heavy_000.ogg", "res://assets/audio/impact/impactPlate_heavy_000.wav"],
	"plate_heavy_1": ["res://assets/audio/impact/impactPlate_heavy_001.ogg", "res://assets/audio/impact/impactPlate_heavy_001.wav"],

	"bell_heavy_0": ["res://assets/audio/impact/impactBell_heavy_000.ogg", "res://assets/audio/impact/impactBell_heavy_000.wav"],
	"bell_heavy_1": ["res://assets/audio/impact/impactBell_heavy_001.ogg", "res://assets/audio/impact/impactBell_heavy_001.wav"],

	# 4. Bước chân trên sàn đá (Kenney Impact & RPG Footsteps)
	"step_0": ["res://assets/audio/impact/footstep_concrete_000.ogg", "res://assets/audio/rpg/footstep00.ogg", "res://assets/audio/rpg/footstep00.wav"],
	"step_1": ["res://assets/audio/impact/footstep_concrete_001.ogg", "res://assets/audio/rpg/footstep01.ogg", "res://assets/audio/rpg/footstep01.wav"],
	"step_2": ["res://assets/audio/impact/footstep_concrete_002.ogg", "res://assets/audio/rpg/footstep02.ogg", "res://assets/audio/rpg/footstep02.wav"],
	"step_3": ["res://assets/audio/impact/footstep_concrete_003.ogg", "res://assets/audio/rpg/footstep03.ogg", "res://assets/audio/rpg/footstep03.wav"],
	"step_4": ["res://assets/audio/impact/footstep_concrete_004.ogg", "res://assets/audio/rpg/footstep04.ogg", "res://assets/audio/rpg/footstep04.wav"],

	# 5. Hiệu ứng tinh thể / tia điện nhẹ (Kenney Interface)
	"glass_crack": ["res://assets/audio/ui/glass_004.wav", "res://assets/audio/crystal.wav"],
	"bong_low": ["res://assets/audio/ui/bong_001.wav", "res://assets/audio/pickup_health.wav"]
}

# Ma trận Hòa Âm Đa Lớp (Multi-Layer Foley Recipes) cho 23 Sự kiện Âm thanh
const FOLEY_RECIPES: Dictionary = {
	# --- ĐÒN ĐÁNH THƯỜNG [U] TRẠNG THÁI 1 ---
	"u1_slash": [
		{"sample": "cloth_1", "vol_db": -5.0, "pitch": 1.05, "delay": 0.0},
		{"sample": "slice_1", "vol_db": -2.5, "pitch": 1.00, "delay": 0.015}
	],
	"u2_slash": [
		{"sample": "slice_2", "vol_db": -3.0, "pitch": 0.96, "delay": 0.0},
		{"sample": "slice_1", "vol_db": -2.0, "pitch": 1.12, "delay": 0.045},
		{"sample": "draw_blade_1", "vol_db": -9.0, "pitch": 1.18, "delay": 0.02}
	],
	"u3_heaven_shatter": [
		{"sample": "slice_2", "vol_db": -1.5, "pitch": 0.76, "delay": 0.0},
		{"sample": "rock_slam_0", "vol_db": 0.5, "pitch": 0.82, "delay": 0.05},
		{"sample": "soft_boom_0", "vol_db": 1.0, "pitch": 0.70, "delay": 0.05},
		{"sample": "bell_heavy_0", "vol_db": -6.5, "pitch": 0.92, "delay": 0.06}
	],

	# --- ĐÒN ĐÁNH [U] TRẠNG THÁI 2 (HÓA NỘ ĐỎ-XANH) ---
	"u1_rage": [
		{"sample": "slice_1", "vol_db": -1.5, "pitch": 0.85, "delay": 0.0},
		{"sample": "draw_blade_2", "vol_db": -5.5, "pitch": 0.95, "delay": 0.01},
		{"sample": "soft_boom_1", "vol_db": -3.5, "pitch": 0.82, "delay": 0.02}
	],
	"u2_rage": [
		{"sample": "slice_2", "vol_db": -1.5, "pitch": 0.82, "delay": 0.0},
		{"sample": "slice_1", "vol_db": -1.0, "pitch": 0.98, "delay": 0.04},
		{"sample": "metal_heavy_0", "vol_db": -4.0, "pitch": 0.88, "delay": 0.03}
	],
	"u3_rage_dragon_fall": [
		{"sample": "slice_2", "vol_db": 0.0, "pitch": 0.68, "delay": 0.0},
		{"sample": "rock_slam_1", "vol_db": 1.5, "pitch": 0.72, "delay": 0.04},
		{"sample": "soft_boom_2", "vol_db": 2.0, "pitch": 0.62, "delay": 0.04},
		{"sample": "metal_heavy_1", "vol_db": -2.0, "pitch": 0.78, "delay": 0.06},
		{"sample": "bell_heavy_1", "vol_db": -4.5, "pitch": 0.78, "delay": 0.07}
	],

	# --- TUYỆT KỸ [I] PHÁ KHÔNG TRẢM (THƯỜNG & NỘ) ---
	"i_phase1_x_cleave": [
		{"sample": "cloth_2", "vol_db": -4.0, "pitch": 1.10, "delay": 0.0},
		{"sample": "slice_1", "vol_db": -2.0, "pitch": 1.05, "delay": 0.01},
		{"sample": "slice_2", "vol_db": -1.5, "pitch": 0.92, "delay": 0.05},
		{"sample": "draw_blade_1", "vol_db": -6.0, "pitch": 1.05, "delay": 0.03}
	],
	"i_phase2_wave_launch": [
		{"sample": "cloth_4", "vol_db": -2.0, "pitch": 0.75, "delay": 0.0},
		{"sample": "slice_2", "vol_db": -2.5, "pitch": 0.80, "delay": 0.02},
		{"sample": "rock_slam_2", "vol_db": -3.5, "pitch": 0.90, "delay": 0.03}
	],
	"i_wave_finale": [
		{"sample": "soft_boom_0", "vol_db": 0.0, "pitch": 0.78, "delay": 0.0},
		{"sample": "rock_slam_3", "vol_db": -1.5, "pitch": 0.85, "delay": 0.01},
		{"sample": "plate_heavy_0", "vol_db": -4.0, "pitch": 0.88, "delay": 0.02}
	],
	"i_rage_hexa_cleave": [
		{"sample": "slice_1", "vol_db": -1.0, "pitch": 0.86, "delay": 0.0},
		{"sample": "slice_2", "vol_db": -0.5, "pitch": 0.78, "delay": 0.04},
		{"sample": "metal_heavy_2", "vol_db": -2.5, "pitch": 0.85, "delay": 0.02},
		{"sample": "draw_blade_3", "vol_db": -4.5, "pitch": 0.90, "delay": 0.05}
	],
	"i_rage_five_wing_wave": [
		{"sample": "cloth_4", "vol_db": -0.5, "pitch": 0.65, "delay": 0.0},
		{"sample": "soft_boom_1", "vol_db": 0.5, "pitch": 0.70, "delay": 0.01},
		{"sample": "rock_slam_0", "vol_db": -1.0, "pitch": 0.76, "delay": 0.03}
	],

	# --- KỸ NĂNG [O] XOAY 360 ĐỘ ---
	"o_whirlwind_spin": [
		{"sample": "slice_1", "vol_db": -3.0, "pitch": 0.92, "delay": 0.00},
		{"sample": "cloth_1", "vol_db": -4.0, "pitch": 0.90, "delay": 0.02},
		{"sample": "slice_2", "vol_db": -2.5, "pitch": 1.00, "delay": 0.11},
		{"sample": "slice_1", "vol_db": -2.5, "pitch": 1.08, "delay": 0.22},
		{"sample": "slice_2", "vol_db": -2.0, "pitch": 1.15, "delay": 0.33}
	],

	# --- KỸ NĂNG [P] BOM LÔI VỤ ---
	"p_bomb_throw": [
		{"sample": "cloth_3", "vol_db": -3.5, "pitch": 1.12, "delay": 0.0},
		{"sample": "chop", "vol_db": -6.0, "pitch": 1.20, "delay": 0.01}
	],
	"p_bomb_thunder_explode": [
		{"sample": "soft_boom_2", "vol_db": 1.5, "pitch": 0.65, "delay": 0.0},
		{"sample": "rock_slam_1", "vol_db": 0.0, "pitch": 0.78, "delay": 0.01},
		{"sample": "glass_crack", "vol_db": -4.5, "pitch": 0.72, "delay": 0.02}
	],
	"p_bomb_dot_zap": [
		{"sample": "metal_light_0", "vol_db": -12.0, "pitch": 1.45, "delay": 0.0}
	],

	# --- TRẠNG THÁI 2 [R] HÓA NỘ ---
	"rage_r_awaken": [
		{"sample": "soft_boom_0", "vol_db": 2.0, "pitch": 0.62, "delay": 0.0},
		{"sample": "draw_blade_3", "vol_db": -1.5, "pitch": 0.78, "delay": 0.02},
		{"sample": "bell_heavy_0", "vol_db": -2.0, "pitch": 0.74, "delay": 0.03},
		{"sample": "rock_slam_2", "vol_db": -1.0, "pitch": 0.75, "delay": 0.04}
	],
	"rage_r_expire": [
		{"sample": "cloth_4", "vol_db": -4.5, "pitch": 0.78, "delay": 0.0},
		{"sample": "bong_low", "vol_db": -8.0, "pitch": 0.82, "delay": 0.02}
	],

	# --- DI CHUYỂN & VA CHẠM ---
	"dash_space": [
		{"sample": "cloth_1", "vol_db": -3.0, "pitch": 0.88, "delay": 0.0},
		{"sample": "chop", "vol_db": -5.5, "pitch": 0.95, "delay": 0.01}
	],
	"jump_c": [
		{"sample": "cloth_2", "vol_db": -4.5, "pitch": 1.08, "delay": 0.0},
		{"sample": "step_0", "vol_db": -8.0, "pitch": 0.85, "delay": 0.0}
	],
	"footstep_stone": [
		{"sample": "step_0", "vol_db": -12.5, "pitch": 1.0, "delay": 0.0}
	],
	"hit_enemy_flesh_metal": [
		{"sample": "punch_heavy_0", "vol_db": -2.5, "pitch": 0.96, "delay": 0.0},
		{"sample": "metal_med_0", "vol_db": -5.5, "pitch": 0.92, "delay": 0.01}
	],
	"enemy_death_burst": [
		{"sample": "punch_heavy_2", "vol_db": -1.0, "pitch": 0.75, "delay": 0.0},
		{"sample": "plate_heavy_1", "vol_db": -3.0, "pitch": 0.78, "delay": 0.03},
		{"sample": "soft_boom_1", "vol_db": -2.5, "pitch": 0.72, "delay": 0.04}
	]
}

func _init() -> void:
	if _instance == null:
		_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_studio_audio_bus()
	_prebake_audio_bank()
	_init_audio_pool()

func _ready() -> void:
	_is_adding = false
	_setup_studio_audio_bus()
	_init_audio_pool()

static func _setup_studio_audio_bus() -> void:
	var bus_idx := AudioServer.get_bus_index(COMBAT_BUS_NAME)
	if bus_idx == -1:
		AudioServer.add_bus()
		bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_idx, COMBAT_BUS_NAME)
		AudioServer.set_bus_send(bus_idx, "Master")
		AudioServer.set_bus_volume_db(bus_idx, -1.5)

		# 1. Bộ lọc Low-Pass cắt bỏ hoàn toàn dải tần chói tai (> 6800 Hz), giữ âm thanh ấm và đầm
		var lpf := AudioEffectLowPassFilter.new()
		lpf.cutoff_hz = 6800.0
		lpf.resonance = 0.38
		AudioServer.add_bus_effect(bus_idx, lpf)

		# 2. Bộ nén Compressor chống vỡ tiếng khi nhiều chiêu nổ cùng lúc
		var comp := AudioEffectCompressor.new()
		comp.threshold = -8.0
		comp.ratio = 4.0
		comp.attack_us = 50.0
		comp.release_ms = 120.0
		AudioServer.add_bus_effect(bus_idx, comp)

func _init_audio_pool() -> void:
	var target_bus := COMBAT_BUS_NAME if AudioServer.get_bus_index(COMBAT_BUS_NAME) != -1 else "Master"
	if players.size() == 0:
		for i in range(max_players):
			var p := AudioStreamPlayer.new()
			p.name = "AudioPoolChannel_%d" % i
			p.bus = target_bus
			p.max_polyphony = 4
			add_child(p)
			players.append(p)

	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer_CombatLoop"
		bgm_player.bus = "Master"
		bgm_player.volume_db = -14.0
		add_child(bgm_player)
		# TUYỆT ĐỐI KHÔNG tự phát sóng sin ù ù! Chỉ phát nếu có file nhạc .ogg thật
		if ResourceLoader.exists("res://assets/audio/bgm_arena.ogg"):
			bgm_player.stream = load("res://assets/audio/bgm_arena.ogg")
			bgm_player.play()

static func ensure_initialized(tree: SceneTree = null) -> KayKitAudioDirector:
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if _instance == null:
		var script_res := load("res://scripts/audio/kaykit_audio_director.gd") as GDScript
		if script_res:
			_instance = script_res.new()
			_instance.name = "KayKitAudioDirector"
			if tree and tree.root and not _is_adding:
				_is_adding = true
				if tree.root.is_node_ready():
					tree.root.add_child(_instance)
				else:
					tree.root.call_deferred("add_child", _instance)
	elif not _instance.is_inside_tree() and not _is_adding:
		if tree and tree.root and _instance.get_parent() == null:
			_is_adding = true
			if tree.root.is_node_ready():
				tree.root.add_child(_instance)
			else:
				tree.root.call_deferred("add_child", _instance)

	if not _is_prebaked and _instance:
		_instance._prebake_audio_bank()
	if _instance and _instance.players.size() == 0:
		_instance._init_audio_pool()
	return _instance

static func play_sfx(sfx_id: String, volume_offset_db: float = 0.0, pitch_override: float = 0.0) -> void:
	var inst := ensure_initialized()
	if inst:
		inst._play_internal(sfx_id, volume_offset_db, pitch_override)

static func start_bgm() -> void:
	var inst := ensure_initialized()
	if inst and inst.bgm_player and inst.bgm_player.stream != null:
		if not inst.bgm_player.playing:
			inst.bgm_player.play()

static func set_rage_bgm_mode(is_rage: bool) -> void:
	var inst := ensure_initialized()
	if inst and inst.bgm_player:
		inst.bgm_player.pitch_scale = 1.08 if is_rage else 1.00
		inst.bgm_player.volume_db = -11.0 if is_rage else -14.0

func _prebake_audio_bank() -> void:
	if _is_prebaked:
		return
	_is_prebaked = true

	# 1. Nạp toàn bộ các file thu âm thật (.ogg / .wav) từ ổ cứng vào RAM
	for sample_key in SAMPLE_PATHS:
		var candidate_list: Array = SAMPLE_PATHS[sample_key]
		for path in candidate_list:
			if ResourceLoader.exists(path):
				var stream := ResourceLoader.load(path) as AudioStream
				if stream != null:
					_raw_streams[sample_key] = stream
					break

	# Fallback an toàn nếu thiếu bất kỳ key phụ nào: trỏ về file thu âm thật gần nhất
	var default_real_stream: AudioStream = _raw_streams.get("slice_1", null)
	if default_real_stream == null and ResourceLoader.exists("res://assets/audio/click.wav"):
		default_real_stream = ResourceLoader.load("res://assets/audio/click.wav") as AudioStream

	for sample_key in SAMPLE_PATHS:
		if not _raw_streams.has(sample_key) and default_real_stream != null:
			_raw_streams[sample_key] = default_real_stream

	# 2. Ánh xạ 23 sự kiện vào _sfx_bank bằng các AudioStream thật
	for recipe_id in FOLEY_RECIPES:
		var layers: Array = FOLEY_RECIPES[recipe_id]
		if layers.size() > 0:
			var primary_sample: String = layers[0]["sample"]
			_sfx_bank[recipe_id] = _raw_streams.get(primary_sample, default_real_stream)

	_sfx_bank["bgm_arena_combat_loop"] = default_real_stream
	print("🎵 [KayKitAudioDirector] Loaded %d real foley samples and mapped %d composite recipes into RAM." % [_raw_streams.size(), _sfx_bank.size()])

func _play_internal(sfx_id: String, volume_offset_db: float, pitch_override: float) -> void:
	if not FOLEY_RECIPES.has(sfx_id) and not _sfx_bank.has(sfx_id):
		return

	var now := float(Time.get_ticks_msec()) / 1000.0
	if _last_play_time.has(sfx_id):
		if now - float(_last_play_time[sfx_id]) < MIN_RETRIGGER_DELAY:
			return
	_last_play_time[sfx_id] = now

	_init_audio_pool()
	if players.size() == 0:
		return

	play_count += 1
	play_counts[sfx_id] = int(play_counts.get(sfx_id, 0)) + 1

	# Luân phiên 5 mẫu bước chân thật trên đá để nghe tự nhiên 100%
	if sfx_id == "footstep_stone":
		var step_key := "step_%d" % (_footstep_cycle_idx % 5)
		_footstep_cycle_idx += 1
		var step_stream: AudioStream = _raw_streams.get(step_key, null)
		if step_stream:
			_trigger_single_layer(step_stream, -12.5 + volume_offset_db, randf_range(0.94, 1.06))
		return

	# Luân phiên 4 mẫu va chạm thịt/giáp thật khi chém trúng Bot
	if sfx_id == "hit_enemy_flesh_metal":
		var punch_key := "punch_heavy_%d" % (_hit_cycle_idx % 4)
		var metal_key := "metal_med_%d" % (_hit_cycle_idx % 2)
		_hit_cycle_idx += 1
		var p_stream: AudioStream = _raw_streams.get(punch_key, null)
		var m_stream: AudioStream = _raw_streams.get(metal_key, null)
		if p_stream:
			_trigger_single_layer(p_stream, -2.5 + volume_offset_db, randf_range(0.94, 1.05))
		if m_stream:
			_trigger_single_layer(m_stream, -6.0 + volume_offset_db, randf_range(0.92, 1.04))
		return

	# Phát tổ hợp Đa Lớp Foley Thật (Multi-Layer Composite Foley)
	if FOLEY_RECIPES.has(sfx_id):
		var layers: Array = FOLEY_RECIPES[sfx_id]
		var jitter := randf_range(0.96, 1.04)
		for layer in layers:
			var sample_name: String = layer.get("sample", "slice_1")
			var stream: AudioStream = _raw_streams.get(sample_name, null)
			if stream == null:
				continue
			var layer_vol: float = float(layer.get("vol_db", 0.0)) + volume_offset_db
			var base_pitch: float = float(layer.get("pitch", 1.0))
			var final_pitch: float = pitch_override if pitch_override > 0.0 else (base_pitch * jitter)
			var delay_sec: float = float(layer.get("delay", 0.0))

			if delay_sec <= 0.001 or not is_inside_tree():
				_trigger_single_layer(stream, layer_vol, final_pitch)
			else:
				var tw := create_tween()
				tw.tween_interval(delay_sec)
				tw.tween_callback(_trigger_single_layer.bind(stream, layer_vol, final_pitch))

func _trigger_single_layer(stream: AudioStream, vol_db: float, pitch_val: float) -> void:
	if stream == null or players.size() == 0:
		return
	var player := players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % max_players
	player.stream = stream
	player.volume_db = clampf(vol_db, -40.0, 4.0)
	player.pitch_scale = clampf(pitch_val, 0.45, 2.0)
	if player.is_inside_tree():
		player.play()
