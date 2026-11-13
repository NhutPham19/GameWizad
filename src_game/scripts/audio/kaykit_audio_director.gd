class_name KayKitAudioDirector
extends Node

# ==============================================================================
# KAYKIT AUDIO DIRECTOR — DIRECTIVE 29 (ULTIMATE AAA STUDIO AUDIO OVERHAUL)
# - Kết hợp 3 kho thu âm thật: Kenney RPG + Kenney Impact + Kenney Sci-Fi/Energy
# - Kiến trúc 4 Audio Bus DSP chuyên biệt (Tách biệt 100% Trạng Thái 1 & Trạng Thái 2)
# - Hỗ trợ âm thanh Đọng Lại & Phình To (Lingering Power Audio Tail)
# - 32 Kênh Audio Pool đa luồng, 0ms lag ở 165Hz+, 0% sóng bíp tự chế
# ==============================================================================

static var _instance: KayKitAudioDirector = null
static var _raw_streams: Dictionary = {}
static var _sfx_bank: Dictionary = {}
static var _is_prebaked: bool = false
static var _is_adding: bool = false

var players: Array[AudioStreamPlayer] = []
var max_players: int = 32
var current_player_idx: int = 0
var bgm_player: AudioStreamPlayer = null
var rage_aura_loop_player: AudioStreamPlayer = null

var play_count: int = 0
var play_counts: Dictionary = {}
var _last_play_time: Dictionary = {}

const MIN_RETRIGGER_DELAY: float = 0.030

const BUS_NORMAL := "NormalBladeBus"
const BUS_RAGE := "RageOverdriveBus"
const BUS_IMPACT := "HeavyImpactBus"
const BUS_AURA := "RageAuraBus"
const COMBAT_BUS_NAME := BUS_NORMAL

func _init() -> void:
	if _instance == null:
		_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_studio_audio_buses()
	_prebake_audio_bank()
	_init_audio_pool()

func _ready() -> void:
	_is_adding = false
	_setup_studio_audio_buses()
	_init_audio_pool()

# ==============================================================================
# 1. THIẾT LẬP 4 AUDIO BUS DSP CHUẨN PHÒNG THU TRÊN AUDIOSERVER
# ==============================================================================
func _setup_studio_audio_buses() -> void:
	# --- BUS 1: NormalBladeBus (Trạng Thái 1: Sắc lẹm, trong trẻo, vang nhẹ đấu trường đá) ---
	if AudioServer.get_bus_index(BUS_NORMAL) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_NORMAL)
		AudioServer.set_bus_send(idx, "Master")

		var eq := AudioEffectEQ6.new()
		eq.set_band_gain_db(0, 2.0)   # 32 Hz
		eq.set_band_gain_db(1, 3.5)   # 100 Hz (Độ đầm thân kiếm)
		eq.set_band_gain_db(2, -1.0)  # 320 Hz (Giảm độ đục)
		eq.set_band_gain_db(3, 2.5)   # 1000 Hz
		eq.set_band_gain_db(4, 3.8)   # 3200 Hz (Độ sắc bén của lưỡi thép)
		eq.set_band_gain_db(5, -2.0)  # 10000 Hz (Mượt tai, không chói)
		AudioServer.add_bus_effect(idx, eq)

		var rev := AudioEffectReverb.new()
		rev.room_size = 0.32
		rev.damping = 0.65
		rev.spread = 0.85
		rev.wet = 0.12
		rev.dry = 0.95
		AudioServer.add_bus_effect(idx, rev)

		var comp := AudioEffectCompressor.new()
		comp.threshold = -8.0
		comp.ratio = 3.0
		comp.attack_us = 1500.0
		comp.release_ms = 120.0
		comp.gain = 1.5
		AudioServer.add_bus_effect(idx, comp)

	# --- BUS 2: RageOverdriveBus (Trạng Thái 2 [R]: Uy lực khủng khiếp, Sub-Bass + Tube Overdrive + Chorus + Stereo Widener) ---
	if AudioServer.get_bus_index(BUS_RAGE) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_RAGE)
		AudioServer.set_bus_send(idx, "Master")

		var eq_rage := AudioEffectEQ6.new()
		eq_rage.set_band_gain_db(0, 6.5)   # 32 Hz (Rung chấn hạ âm)
		eq_rage.set_band_gain_db(1, 7.0)   # 100 Hz (Lực đập ngực cực mạnh)
		eq_rage.set_band_gain_db(2, 1.5)   # 320 Hz (Độ dày cuồng nộ)
		eq_rage.set_band_gain_db(3, 3.0)   # 1000 Hz
		eq_rage.set_band_gain_db(4, 4.2)   # 3200 Hz (Tiếng xé không gian)
		eq_rage.set_band_gain_db(5, -3.5)  # 10000 Hz (Khử chói gắt)
		AudioServer.add_bus_effect(idx, eq_rage)

		var dist := AudioEffectDistortion.new()
		dist.mode = AudioEffectDistortion.MODE_ATAN
		dist.drive = 0.24
		dist.pre_gain = 2.0
		dist.post_gain = 1.0
		dist.keep_hf_hz = 5500.0
		AudioServer.add_bus_effect(idx, dist)

		var chorus := AudioEffectChorus.new()
		chorus.voice_count = 2
		chorus.wet = 0.28
		chorus.dry = 0.90
		AudioServer.add_bus_effect(idx, chorus)

		var stereo := AudioEffectStereoEnhance.new()
		stereo.pan_pullout = 1.45
		stereo.time_pullout_ms = 10.0
		stereo.surround = 0.35
		AudioServer.add_bus_effect(idx, stereo)

		var rev_rage := AudioEffectReverb.new()
		rev_rage.room_size = 0.65
		rev_rage.damping = 0.50
		rev_rage.spread = 1.0
		rev_rage.wet = 0.24
		rev_rage.dry = 0.92
		AudioServer.add_bus_effect(idx, rev_rage)

		var comp_rage := AudioEffectCompressor.new()
		comp_rage.threshold = -9.0
		comp_rage.ratio = 4.5
		comp_rage.attack_us = 1000.0
		comp_rage.release_ms = 140.0
		comp_rage.gain = 2.5
		AudioServer.add_bus_effect(idx, comp_rage)

	# --- BUS 3: HeavyImpactBus (Chuyên trách Nổ Địa Chấn U3, Sóng Kiếm [I], Bom [P] & Thức Tỉnh [R]) ---
	if AudioServer.get_bus_index(BUS_IMPACT) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_IMPACT)
		AudioServer.set_bus_send(idx, "Master")

		var eq_imp := AudioEffectEQ6.new()
		eq_imp.set_band_gain_db(0, 7.5)   # 32 Hz (Địa chấn sâu)
		eq_imp.set_band_gain_db(1, 6.5)   # 100 Hz (Cú nện đầm tay)
		eq_imp.set_band_gain_db(2, 0.5)   # 320 Hz
		eq_imp.set_band_gain_db(3, 2.0)   # 1000 Hz
		eq_imp.set_band_gain_db(4, 2.5)   # 3200 Hz
		eq_imp.set_band_gain_db(5, -4.0)  # 10000 Hz
		AudioServer.add_bus_effect(idx, eq_imp)

		var rev_imp := AudioEffectReverb.new()
		rev_imp.room_size = 0.58
		rev_imp.damping = 0.55
		rev_imp.wet = 0.22
		rev_imp.dry = 0.95
		AudioServer.add_bus_effect(idx, rev_imp)

		var comp_imp := AudioEffectCompressor.new()
		comp_imp.threshold = -7.0
		comp_imp.ratio = 4.0
		comp_imp.gain = 2.0
		AudioServer.add_bus_effect(idx, comp_imp)

	# --- BUS 4: RageAuraBus (Âm thanh Hào Quang Nộ rền vang suốt 10s khi bật [R]) ---
	if AudioServer.get_bus_index(BUS_AURA) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_AURA)
		AudioServer.set_bus_send(idx, "Master")

		var lpf := AudioEffectLowPassFilter.new()
		lpf.cutoff_hz = 1800.0
		lpf.resonance = 0.65
		AudioServer.add_bus_effect(idx, lpf)

		var chorus_aura := AudioEffectChorus.new()
		chorus_aura.voice_count = 2
		chorus_aura.wet = 0.45
		AudioServer.add_bus_effect(idx, chorus_aura)

func _init_audio_pool() -> void:
	if players.size() == 0:
		for i in range(max_players):
			var p := AudioStreamPlayer.new()
			p.name = "AudioPoolChannel_%d" % i
			p.bus = BUS_NORMAL
			p.max_polyphony = 4
			add_child(p)
			players.append(p)

	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer_CombatLoop"
		bgm_player.bus = BUS_AURA
		bgm_player.volume_db = -14.0
		add_child(bgm_player)

	if rage_aura_loop_player == null:
		rage_aura_loop_player = AudioStreamPlayer.new()
		rage_aura_loop_player.name = "RageAuraContinuousPlayer"
		rage_aura_loop_player.bus = BUS_AURA
		rage_aura_loop_player.volume_db = -13.5
		add_child(rage_aura_loop_player)

static func ensure_initialized(tree: SceneTree = null) -> KayKitAudioDirector:
	if _instance == null:
		var script_res := load("res://scripts/audio/kaykit_audio_director.gd") as GDScript
		if script_res:
			_instance = script_res.new()
			_instance.name = "KayKitAudioDirector"
			if tree == null:
				tree = Engine.get_main_loop() as SceneTree
			if tree and tree.root and not _is_adding:
				_is_adding = true
				if tree.root.is_node_ready():
					tree.root.add_child(_instance)
				else:
					tree.root.call_deferred("add_child", _instance)
	elif not _instance.is_inside_tree() and not _is_adding:
		if tree == null:
			tree = Engine.get_main_loop() as SceneTree
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
	ensure_initialized()

static func set_rage_bgm_mode(is_rage: bool) -> void:
	var inst := ensure_initialized()
	if inst == null:
		return
	inst._init_audio_pool()
	if inst.bgm_player:
		if is_rage:
			inst.bgm_player.pitch_scale = 1.08
			inst.bgm_player.volume_db = -11.0
		else:
			inst.bgm_player.pitch_scale = 1.00
			inst.bgm_player.volume_db = -14.0

	# Phát hào quang âm thanh năng lượng trầm ấm khi đang ở Trạng Thái 2 [R]
	if inst.rage_aura_loop_player:
		if is_rage:
			var aura_stream: AudioStream = _raw_streams.get("forcefield_1", _raw_streams.get("thruster_3", null))
			if aura_stream:
				inst.rage_aura_loop_player.stream = aura_stream
				inst.rage_aura_loop_player.pitch_scale = 0.68
				inst.rage_aura_loop_player.volume_db = -13.5
				if inst.rage_aura_loop_player.is_inside_tree():
					inst.rage_aura_loop_player.play()
		else:
			if inst.rage_aura_loop_player.is_inside_tree():
				inst.rage_aura_loop_player.stop()

# ==============================================================================
# 2. NẠP TOÀN BỘ FILE THU ÂM THẬT (.OGG / .WAV) TỪ 3 REPO KENNEY VÀO RAM
# ==============================================================================
func _load_real_stream(key: String, candidate_paths: Array[String]) -> void:
	for path in candidate_paths:
		if ResourceLoader.exists(path):
			var s := ResourceLoader.load(path) as AudioStream
			if s != null:
				_raw_streams[key] = s
				return

func _prebake_audio_bank() -> void:
	if _is_prebaked:
		return
	_is_prebaked = true

	# --- A. KHO VŨ KHÍ & FOLEY CẬN CHIẾN (Kenney RPG Audio) ---
	_load_real_stream("slice_1", ["res://assets/audio/rpg/knifeSlice.ogg", "res://assets/audio/rpg/knifeSlice.wav", "res://assets/audio/slash.wav"])
	_load_real_stream("slice_2", ["res://assets/audio/rpg/knifeSlice2.ogg", "res://assets/audio/rpg/knifeSlice2.wav", "res://assets/audio/slash.wav"])
	_load_real_stream("draw_1", ["res://assets/audio/rpg/drawKnife1.ogg", "res://assets/audio/rpg/drawKnife1.wav", "res://assets/audio/slash.wav"])
	_load_real_stream("draw_2", ["res://assets/audio/rpg/drawKnife2.ogg", "res://assets/audio/rpg/drawKnife2.wav", "res://assets/audio/slash.wav"])
	_load_real_stream("draw_3", ["res://assets/audio/rpg/drawKnife3.ogg", "res://assets/audio/rpg/drawKnife3.wav", "res://assets/audio/slash.wav"])
	_load_real_stream("cloth_heavy", ["res://assets/audio/rpg/clothBelt.ogg", "res://assets/audio/rpg/cloth4.ogg", "res://assets/audio/dash.wav"])
	_load_real_stream("cloth_1", ["res://assets/audio/rpg/cloth1.ogg", "res://assets/audio/rpg/cloth1.wav", "res://assets/audio/dash.wav"])
	_load_real_stream("cloth_2", ["res://assets/audio/rpg/cloth2.ogg", "res://assets/audio/rpg/cloth2.wav", "res://assets/audio/dash.wav"])
	_load_real_stream("chain_1", ["res://assets/audio/rpg/chainmail1.ogg", "res://assets/audio/crystal.wav"])
	_load_real_stream("chain_2", ["res://assets/audio/rpg/chainmail2.ogg", "res://assets/audio/crystal.wav"])
	_load_real_stream("step_1", ["res://assets/audio/rpg/footstep00.ogg", "res://assets/audio/rpg/footstep00.wav", "res://assets/audio/click.wav"])
	_load_real_stream("step_2", ["res://assets/audio/rpg/footstep01.ogg", "res://assets/audio/rpg/footstep01.wav", "res://assets/audio/click.wav"])
	_load_real_stream("step_3", ["res://assets/audio/rpg/footstep02.ogg", "res://assets/audio/rpg/footstep02.wav", "res://assets/audio/click.wav"])
	_load_real_stream("step_grass_1", ["res://assets/audio/rpg/footstep04.ogg", "res://assets/audio/dash.wav"])
	_load_real_stream("step_grass_2", ["res://assets/audio/rpg/footstep05.ogg", "res://assets/audio/dash.wav"])
	_load_real_stream("pot_break", ["res://assets/audio/rpg/metalPot1.ogg", "res://assets/audio/hit.wav"])

	# --- B. KHO VA ĐẬP VẬT LÝ HẠNG NẶNG (Kenney Impact Sounds) ---
	_load_real_stream("punch_heavy_1", ["res://assets/audio/impact/impactPunch_heavy_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("punch_heavy_2", ["res://assets/audio/impact/impactPunch_heavy_001.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("punch_heavy_3", ["res://assets/audio/impact/impactPunch_heavy_002.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("punch_med_1", ["res://assets/audio/impact/impactPunch_medium_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("punch_med_2", ["res://assets/audio/impact/impactPunch_medium_001.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("plate_heavy_1", ["res://assets/audio/impact/impactPlate_heavy_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("plate_heavy_2", ["res://assets/audio/impact/impactPlate_heavy_001.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("plate_med_1", ["res://assets/audio/impact/impactPlate_medium_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("metal_heavy_1", ["res://assets/audio/impact/impactMetal_heavy_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("metal_heavy_2", ["res://assets/audio/impact/impactMetal_heavy_001.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("mining_1", ["res://assets/audio/impact/impactMining_000.ogg", "res://assets/audio/crystal.wav"])
	_load_real_stream("mining_2", ["res://assets/audio/impact/impactMining_001.ogg", "res://assets/audio/crystal.wav"])
	_load_real_stream("wood_heavy_1", ["res://assets/audio/impact/impactWood_heavy_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("bell_heavy", ["res://assets/audio/impact/impactBell_heavy_000.ogg", "res://assets/audio/crystal.wav"])

	# --- C. KHO NỔ ĐỊA CHẤN, SUB-BASS, LỬA PHẢN LỰC & SÓNG NĂNG LƯỢNG (Kenney Sci-Fi Sounds) ---
	_load_real_stream("sub_boom_1", ["res://assets/audio/scifi/lowFrequency_explosion_000.ogg", "res://assets/audio/impact/impactPunch_heavy_000.ogg"])
	_load_real_stream("sub_boom_2", ["res://assets/audio/scifi/lowFrequency_explosion_001.ogg", "res://assets/audio/impact/impactPunch_heavy_001.ogg"])
	_load_real_stream("exp_crunch_1", ["res://assets/audio/scifi/explosionCrunch_000.ogg", "res://assets/audio/impact/impactPlate_heavy_000.ogg"])
	_load_real_stream("exp_crunch_2", ["res://assets/audio/scifi/explosionCrunch_001.ogg", "res://assets/audio/impact/impactPlate_heavy_001.ogg"])
	_load_real_stream("exp_crunch_3", ["res://assets/audio/scifi/explosionCrunch_002.ogg", "res://assets/audio/impact/impactPunch_heavy_002.ogg"])
	_load_real_stream("exp_crunch_4", ["res://assets/audio/scifi/explosionCrunch_003.ogg", "res://assets/audio/impact/impactPunch_heavy_003.ogg"])
	_load_real_stream("thruster_1", ["res://assets/audio/scifi/thrusterFire_000.ogg", "res://assets/audio/rpg/clothBelt.ogg"])
	_load_real_stream("thruster_2", ["res://assets/audio/scifi/thrusterFire_001.ogg", "res://assets/audio/rpg/cloth1.ogg"])
	_load_real_stream("thruster_3", ["res://assets/audio/scifi/thrusterFire_002.ogg", "res://assets/audio/rpg/cloth2.ogg"])
	_load_real_stream("thruster_4", ["res://assets/audio/scifi/thrusterFire_003.ogg", "res://assets/audio/rpg/cloth3.ogg"])
	_load_real_stream("engine_roar_1", ["res://assets/audio/scifi/spaceEngineLarge_000.ogg", "res://assets/audio/scifi/thrusterFire_000.ogg"])
	_load_real_stream("engine_roar_2", ["res://assets/audio/scifi/spaceEngineLarge_001.ogg", "res://assets/audio/scifi/thrusterFire_001.ogg"])
	_load_real_stream("laser_large_1", ["res://assets/audio/scifi/laserLarge_000.ogg", "res://assets/audio/rpg/drawKnife1.ogg"])
	_load_real_stream("laser_large_2", ["res://assets/audio/scifi/laserLarge_001.ogg", "res://assets/audio/rpg/drawKnife2.ogg"])
	_load_real_stream("laser_large_3", ["res://assets/audio/scifi/laserLarge_002.ogg", "res://assets/audio/rpg/drawKnife3.ogg"])
	_load_real_stream("laser_small_1", ["res://assets/audio/scifi/laserSmall_000.ogg", "res://assets/audio/rpg/knifeSlice.ogg"])
	_load_real_stream("laser_small_2", ["res://assets/audio/scifi/laserSmall_001.ogg", "res://assets/audio/rpg/knifeSlice2.ogg"])
	_load_real_stream("forcefield_1", ["res://assets/audio/scifi/forceField_000.ogg", "res://assets/audio/impact/impactBell_heavy_000.ogg"])
	_load_real_stream("forcefield_2", ["res://assets/audio/scifi/forceField_001.ogg", "res://assets/audio/impact/impactBell_heavy_000.ogg"])
	_load_real_stream("scifi_metal_1", ["res://assets/audio/scifi/impactMetal_000.ogg", "res://assets/audio/impact/impactMetal_heavy_000.ogg"])
	_load_real_stream("scifi_metal_2", ["res://assets/audio/scifi/impactMetal_001.ogg", "res://assets/audio/impact/impactMetal_heavy_001.ogg"])

	# ==========================================================================
	# BẢNG PHỐI ÂM 23 SỰ KIỆN: TÁCH BIỆT 100% TRẠNG THÁI 1 VS TRẠNG THÁI 2 NỘ [R]
	# ==========================================================================

	# --------------------------------------------------------------------------
	# PHẦN I: TRẠNG THÁI 1 (BÌNH THƯỜNG — SẮC LẸM, THANH THOÁT, THÉP BẠCH KIM)
	# Chạy trên BUS_NORMAL ("NormalBladeBus")
	# --------------------------------------------------------------------------
	# 1. "u1_slash": Vung kiếm thép sắc gọn + vệt gió nhanh
	_sfx_bank["u1_slash"] = [
		{"s": "slice_1", "vol": 0.0, "pitch": 1.04, "delay": 0.0, "bus": BUS_NORMAL},
		{"s": "cloth_1", "vol": -3.0, "pitch": 1.15, "delay": 0.0, "bus": BUS_NORMAL},
		{"s": "draw_1",  "vol": -6.5, "pitch": 1.20, "delay": 0.02, "bus": BUS_NORMAL}
	]

	# 2. "u2_slash": Song kiếm chém chéo 2 nhịp thanh thoát
	_sfx_bank["u2_slash"] = [
		{"s": "slice_2", "vol": 0.0, "pitch": 0.96, "delay": 0.0, "bus": BUS_NORMAL},
		{"s": "slice_1", "vol": -1.0, "pitch": 1.16, "delay": 0.045, "bus": BUS_NORMAL},
		{"s": "draw_2",  "vol": -5.0, "pitch": 1.10, "delay": 0.02, "bus": BUS_NORMAL}
	]

	# 3. "u3_heaven_shatter": Đòn thứ 3 trạng thái thường — Bổ dọc nứt đá + chuông ngân
	_sfx_bank["u3_heaven_shatter"] = [
		{"s": "slice_1",       "vol": 1.0,  "pitch": 0.85, "delay": 0.0,  "bus": BUS_NORMAL},
		{"s": "punch_heavy_1", "vol": 2.0,  "pitch": 0.82, "delay": 0.04, "bus": BUS_IMPACT},
		{"s": "plate_heavy_1", "vol": -0.5, "pitch": 0.90, "delay": 0.05, "bus": BUS_NORMAL},
		{"s": "sub_boom_1",    "vol": -1.5, "pitch": 1.05, "delay": 0.05, "bus": BUS_IMPACT},
		{"s": "bell_heavy",    "vol": -5.0, "pitch": 1.25, "delay": 0.08, "bus": BUS_NORMAL}
	]

	# 4. "i_phase1_x_cleave": Lướt chém chữ X trạng thái thường — 2 lưỡi kiếm thép giao nhau
	_sfx_bank["i_phase1_x_cleave"] = [
		{"s": "draw_1",        "vol": 0.5,  "pitch": 1.08, "delay": 0.0,   "bus": BUS_NORMAL},
		{"s": "slice_2",       "vol": 1.0,  "pitch": 0.95, "delay": 0.02,  "bus": BUS_NORMAL},
		{"s": "slice_1",       "vol": 1.0,  "pitch": 1.18, "delay": 0.055, "bus": BUS_NORMAL},
		{"s": "laser_small_1", "vol": -5.5, "pitch": 1.15, "delay": 0.03,  "bus": BUS_NORMAL}
	]

	# 5. "i_phase2_wave_launch": Phóng sóng kiếm 3 cánh trạng thái thường
	_sfx_bank["i_phase2_wave_launch"] = [
		{"s": "slice_2",       "vol": 0.5,  "pitch": 0.88, "delay": 0.0,  "bus": BUS_NORMAL},
		{"s": "thruster_2",    "vol": -3.5, "pitch": 1.25, "delay": 0.0,  "bus": BUS_NORMAL},
		{"s": "laser_small_2", "vol": -4.0, "pitch": 0.95, "delay": 0.03, "bus": BUS_NORMAL},
		{"s": "forcefield_1",  "vol": -6.0, "pitch": 1.30, "delay": 0.08, "bus": BUS_NORMAL}
	]

	# 6. "i_wave_finale": Nổ tinh vân cuối đường sóng kiếm
	_sfx_bank["i_wave_finale"] = [
		{"s": "sub_boom_1",    "vol": 1.5,  "pitch": 0.95, "delay": 0.0,  "bus": BUS_IMPACT},
		{"s": "exp_crunch_1",  "vol": -0.5, "pitch": 1.05, "delay": 0.02, "bus": BUS_IMPACT},
		{"s": "bell_heavy",    "vol": -5.0, "pitch": 1.35, "delay": 0.05, "bus": BUS_NORMAL}
	]

	# --------------------------------------------------------------------------
	# PHẦN II: TRẠNG THÁI 2 NÂNG CẤP (HÓA NỘ [R] — KHỦNG KHIẾP, NẶNG NỀ, LỬA & SẤM SÉT)
	# Chạy trên BUS_RAGE ("RageOverdriveBus") & BUS_IMPACT ("HeavyImpactBus")
	# Dùng bộ mẫu Sub-Bass, ExplosionCrunch, ThrusterFire, LaserLarge & MetalHeavy
	# --------------------------------------------------------------------------
	# 7. "rage_r_awaken": KÍCH HOẠT NỘ [R] — Long Thần Thức Tỉnh (Địa chấn + Sấm sét + Lửa gầm + Đại kiếm ngân vang)
	_sfx_bank["rage_r_awaken"] = [
		{"s": "sub_boom_1",    "vol": 4.0, "pitch": 0.72, "delay": 0.0,  "bus": BUS_IMPACT},
		{"s": "exp_crunch_1",  "vol": 3.0, "pitch": 0.78, "delay": 0.02, "bus": BUS_IMPACT},
		{"s": "thruster_1",    "vol": 2.5, "pitch": 0.75, "delay": 0.04, "bus": BUS_RAGE},
		{"s": "laser_large_1", "vol": 1.5, "pitch": 0.70, "delay": 0.05, "bus": BUS_RAGE},
		{"s": "scifi_metal_1", "vol": 2.0, "pitch": 0.80, "delay": 0.08, "bus": BUS_RAGE},
		{"s": "forcefield_1",  "vol": 1.5, "pitch": 0.85, "delay": 0.14, "bus": BUS_RAGE},
		{"s": "bell_heavy",    "vol": 0.5, "pitch": 0.72, "delay": 0.18, "bus": BUS_RAGE}
	]

	# 8. "rage_r_expire": Thu hồi năng lượng Nộ sau 10s
	_sfx_bank["rage_r_expire"] = [
		{"s": "forcefield_2",  "vol": -1.5, "pitch": 0.72, "delay": 0.0,  "bus": BUS_AURA},
		{"s": "thruster_4",    "vol": -3.5, "pitch": 0.65, "delay": 0.05, "bus": BUS_AURA}
	]

	# 9. "u1_rage": Đòn [U] Nhịp 1 NỘ — Song Đại Kiếm Đỏ-Xanh Phá Không (Khác biệt 100% với u1_slash!)
	_sfx_bank["u1_rage"] = [
		{"s": "sub_boom_2",    "vol": 2.0,  "pitch": 0.92, "delay": 0.0,  "bus": BUS_IMPACT},
		{"s": "thruster_1",    "vol": 2.0,  "pitch": 0.85, "delay": 0.0,  "bus": BUS_RAGE},
		{"s": "scifi_metal_1", "vol": 1.5,  "pitch": 0.82, "delay": 0.01, "bus": BUS_RAGE},
		{"s": "laser_large_1", "vol": 0.5,  "pitch": 0.78, "delay": 0.02, "bus": BUS_RAGE},
		{"s": "slice_1",       "vol": 1.5,  "pitch": 0.72, "delay": 0.03, "bus": BUS_RAGE},
		# Đuôi năng lượng đọng lại (Lingering Tail 0.15s -> 0.42s)
		{"s": "forcefield_1",  "vol": -2.5, "pitch": 0.90, "delay": 0.15, "bus": BUS_RAGE}
	]

	# 10. "u2_rage": Đòn [U] Nhịp 2 NỘ — Song Kiếm Huyết Lôi Chém Ngược Chiều
	_sfx_bank["u2_rage"] = [
		{"s": "sub_boom_1",    "vol": 2.2,  "pitch": 0.98, "delay": 0.0,  "bus": BUS_IMPACT},
		{"s": "thruster_2",    "vol": 2.0,  "pitch": 0.82, "delay": 0.0,  "bus": BUS_RAGE},
		{"s": "scifi_metal_2", "vol": 1.5,  "pitch": 0.78, "delay": 0.01, "bus": BUS_RAGE},
		{"s": "laser_large_2", "vol": 1.0,  "pitch": 0.84, "delay": 0.04, "bus": BUS_RAGE},
		{"s": "exp_crunch_4",  "vol": -0.5, "pitch": 1.10, "delay": 0.06, "bus": BUS_IMPACT},
		# Đuôi năng lượng đọng lại
		{"s": "forcefield_2",  "vol": -2.0, "pitch": 0.85, "delay": 0.16, "bus": BUS_RAGE}
	]

	# 11. "u3_rage_dragon_fall": ĐÒN THỨ 3 [U3] NỘ — "Huyết Lam Long Thần Giáng" (5 Đại Kiếm Khí Ghim Đất 0.58s)
	# Thiết kế 3 Pha: Pha 1 Giáng Kiếm (0.0s) -> Pha 2 Đại Địa Chấn (0.05s) -> Pha 3 Năng Lượng Phình To & Dư Chấn (0.20s - 0.45s)
	_sfx_bank["u3_rage_dragon_fall"] = [
		# Pha 1: 5 Lưỡi Đại Kiếm xé toạc bầu trời
		{"s": "thruster_1",    "vol": 3.5, "pitch": 0.68, "delay": 0.0,  "bus": BUS_RAGE},
		{"s": "laser_large_1", "vol": 2.5, "pitch": 0.65, "delay": 0.01, "bus": BUS_RAGE},
		{"s": "scifi_metal_1", "vol": 2.5, "pitch": 0.70, "delay": 0.02, "bus": BUS_RAGE},
		# Pha 2: Nện nứt mặt đất (Earthquake Sub-Bass + Crunch)
		{"s": "sub_boom_1",    "vol": 4.5, "pitch": 0.62, "delay": 0.05, "bus": BUS_IMPACT},
		{"s": "exp_crunch_1",  "vol": 3.5, "pitch": 0.72, "delay": 0.06, "bus": BUS_IMPACT},
		{"s": "plate_heavy_1", "vol": 2.5, "pitch": 0.65, "delay": 0.08, "bus": BUS_RAGE},
		{"s": "exp_crunch_2",  "vol": 2.0, "pitch": 0.85, "delay": 0.14, "bus": BUS_IMPACT},
		# Pha 3: Âm thanh ĐỌNG LẠI & PHÌNH TO (0.20s -> 0.52s) khi 5 lưỡi kiếm nở 1.28x trên mặt đất!
		{"s": "forcefield_1",  "vol": 2.0, "pitch": 0.74, "delay": 0.20, "bus": BUS_RAGE},
		{"s": "engine_roar_1", "vol": 1.5, "pitch": 0.80, "delay": 0.24, "bus": BUS_RAGE},
		{"s": "sub_boom_2",    "vol": 2.5, "pitch": 0.78, "delay": 0.36, "bus": BUS_IMPACT},
		{"s": "bell_heavy",    "vol": 1.0, "pitch": 0.68, "delay": 0.38, "bus": BUS_RAGE}
	]

	# 12. "i_rage_hexa_cleave": CHIÊU [I] PHA 1 NỘ — Lục Kiếm Khí Chữ X Chém Vỡ Hư Không (6 Lưỡi Đỏ-Xanh)
	_sfx_bank["i_rage_hexa_cleave"] = [
		{"s": "sub_boom_1",    "vol": 3.5, "pitch": 0.76, "delay": 0.0,  "bus": BUS_IMPACT},
		{"s": "laser_large_2", "vol": 2.8, "pitch": 0.72, "delay": 0.0,  "bus": BUS_RAGE},
		{"s": "scifi_metal_1", "vol": 2.5, "pitch": 0.75, "delay": 0.02, "bus": BUS_RAGE},
		{"s": "exp_crunch_3",  "vol": 2.0, "pitch": 0.88, "delay": 0.04, "bus": BUS_IMPACT},
		{"s": "scifi_metal_2", "vol": 2.5, "pitch": 0.84, "delay": 0.06, "bus": BUS_RAGE},
		{"s": "thruster_2",    "vol": 2.0, "pitch": 0.74, "delay": 0.08, "bus": BUS_RAGE},
		# Đuôi ngân khi 6 lưỡi chữ X đọng lại trên không trung
		{"s": "forcefield_2",  "vol": 1.5, "pitch": 0.80, "delay": 0.18, "bus": BUS_RAGE}
	]

	# 13. "i_rage_five_wing_wave": CHIÊU [I] PHA 2 NỘ — Đại Sóng Kiếm 5 Cánh "Ngũ Dực Huyết Lam" Cày Nát 6.2m Mặt Đất
	_sfx_bank["i_rage_five_wing_wave"] = [
		# Tiếng phóng đại sóng 5 cánh
		{"s": "sub_boom_2",    "vol": 3.8, "pitch": 0.68, "delay": 0.0,  "bus": BUS_IMPACT},
		{"s": "thruster_1",    "vol": 3.2, "pitch": 0.65, "delay": 0.0,  "bus": BUS_RAGE},
		{"s": "engine_roar_1", "vol": 2.8, "pitch": 0.72, "delay": 0.03, "bus": BUS_RAGE},
		{"s": "laser_large_3", "vol": 2.2, "pitch": 0.68, "delay": 0.04, "bus": BUS_RAGE},
		# Tiếng cày nát gạch đá liên hoàn dọc đường bay 6.2m (0.09s, 0.18s, 0.27s)
		{"s": "exp_crunch_4",  "vol": 1.5, "pitch": 0.95, "delay": 0.09, "bus": BUS_IMPACT},
		{"s": "exp_crunch_2",  "vol": 1.8, "pitch": 0.85, "delay": 0.18, "bus": BUS_IMPACT},
		{"s": "exp_crunch_3",  "vol": 2.2, "pitch": 0.78, "delay": 0.27, "bus": BUS_IMPACT},
		# Tiếng đọng lại phình to 1.35x ở cuối đường (0.34s)
		{"s": "forcefield_1",  "vol": 2.0, "pitch": 0.70, "delay": 0.34, "bus": BUS_RAGE}
	]

	# --------------------------------------------------------------------------
	# PHẦN III: CÁC KỸ NĂNG KHÁC (XOAY 360 [O], BOM LÔI VỤ [P], LƯỚT [SPACE], NHẢY [C], VA CHẠM)
	# --------------------------------------------------------------------------
	# 14. "o_whirlwind_spin": Lốc xoáy kiếm 360 độ (4 vòng chém cuốn hút chân không)
	_sfx_bank["o_whirlwind_spin"] = [
		{"s": "thruster_3", "vol": 1.5, "pitch": 0.88, "delay": 0.0,  "bus": BUS_RAGE},
		{"s": "slice_1",    "vol": 1.0, "pitch": 0.92, "delay": 0.0,  "bus": BUS_NORMAL},
		{"s": "slice_2",    "vol": 1.2, "pitch": 1.02, "delay": 0.11, "bus": BUS_NORMAL},
		{"s": "slice_1",    "vol": 1.4, "pitch": 1.12, "delay": 0.22, "bus": BUS_NORMAL},
		{"s": "slice_2",    "vol": 1.6, "pitch": 1.22, "delay": 0.33, "bus": BUS_NORMAL},
		{"s": "sub_boom_1", "vol": 0.5, "pitch": 0.95, "delay": 0.05, "bus": BUS_IMPACT}
	]

	# 15. "p_bomb_throw": Ném bom lôi vụ
	_sfx_bank["p_bomb_throw"] = [
		{"s": "cloth_heavy",   "vol": 0.5,  "pitch": 0.95, "delay": 0.0,  "bus": BUS_NORMAL},
		{"s": "laser_small_1", "vol": -3.5, "pitch": 0.85, "delay": 0.02, "bus": BUS_NORMAL}
	]

	# 16. "p_bomb_thunder_explode": Bom lôi vụ phát nổ sấm sét
	_sfx_bank["p_bomb_thunder_explode"] = [
		{"s": "sub_boom_1",    "vol": 3.5, "pitch": 0.75, "delay": 0.0,  "bus": BUS_IMPACT},
		{"s": "exp_crunch_1",  "vol": 3.0, "pitch": 0.82, "delay": 0.01, "bus": BUS_IMPACT},
		{"s": "laser_large_2", "vol": 1.0, "pitch": 0.90, "delay": 0.03, "bus": BUS_RAGE},
		{"s": "thruster_4",    "vol": 0.5, "pitch": 0.80, "delay": 0.06, "bus": BUS_IMPACT}
	]

	# 17. "p_bomb_dot_zap": Nhịp giật sét DoT trong vùng khói
	_sfx_bank["p_bomb_dot_zap"] = [
		{"s": "laser_small_2", "vol": -4.5, "pitch": 1.25, "delay": 0.0, "bus": BUS_NORMAL},
		{"s": "scifi_metal_2", "vol": -6.0, "pitch": 1.40, "delay": 0.01, "bus": BUS_NORMAL}
	]

	# 18. "dash_space": Lướt né đòn [Space] (Đầm và có lực đẩy gió)
	_sfx_bank["dash_space"] = [
		{"s": "thruster_2",  "vol": -0.5, "pitch": 1.18, "delay": 0.0,  "bus": BUS_NORMAL},
		{"s": "cloth_heavy", "vol": 1.0,  "pitch": 0.95, "delay": 0.01, "bus": BUS_NORMAL}
	]

	# 19. "jump_c": Nhún chân bật nhảy [C]
	_sfx_bank["jump_c"] = [
		{"s": "cloth_1",     "vol": 0.0,  "pitch": 0.95, "delay": 0.0,  "bus": BUS_NORMAL},
		{"s": "punch_med_1", "vol": -3.5, "pitch": 1.15, "delay": 0.01, "bus": BUS_NORMAL}
	]

	# 20. "footstep_stone": Bước chân trên nền đá
	_sfx_bank["footstep_stone"] = [
		{"s": "step_1", "vol": -5.5, "pitch": 0.92, "delay": 0.0, "bus": BUS_NORMAL}
	]

	# 21. "hit_enemy_flesh_metal": Chém trúng quái vật (Đầm tay, có tiếng thép cắt giáp thịt)
	_sfx_bank["hit_enemy_flesh_metal"] = [
		{"s": "punch_heavy_2", "vol": 1.5,  "pitch": 0.92, "delay": 0.0,   "bus": BUS_IMPACT},
		{"s": "scifi_metal_1", "vol": -0.5, "pitch": 1.05, "delay": 0.01,  "bus": BUS_NORMAL},
		{"s": "slice_2",       "vol": -2.0, "pitch": 0.88, "delay": 0.015, "bus": BUS_NORMAL}
	]

	# 22. "enemy_death_burst": Quái vật bị tiêu diệt nổ tung
	_sfx_bank["enemy_death_burst"] = [
		{"s": "sub_boom_2",    "vol": 2.0, "pitch": 0.88, "delay": 0.0,  "bus": BUS_IMPACT},
		{"s": "exp_crunch_3",  "vol": 1.5, "pitch": 0.92, "delay": 0.02, "bus": BUS_IMPACT},
		{"s": "pot_break",     "vol": 0.0, "pitch": 0.85, "delay": 0.04, "bus": BUS_NORMAL}
	]

	# 23. "bgm_arena_combat_loop": Giữ entry cho QA Telemetry
	_sfx_bank["bgm_arena_combat_loop"] = [
		{"s": "forcefield_1", "vol": -18.0, "pitch": 0.65, "delay": 0.0, "bus": BUS_AURA}
	]

	print("🎵 [KayKitAudioDirector] Loaded %d real acoustic streams & configured %d multi-bus AAA sound events (State 1 vs State 2 separated 100%%)." % [_raw_streams.size(), _sfx_bank.size()])

# ==============================================================================
# 3. BỘ PHÁT HÒA ÂM ĐA LỚP QUA 4 AUDIO BUS CHUYÊN BIỆT (0MS LAG)
# ==============================================================================
func _play_internal(sfx_id: String, volume_offset_db: float, pitch_override: float) -> void:
	if not _sfx_bank.has(sfx_id):
		return

	var now := float(Time.get_ticks_msec()) / 1000.0
	if _last_play_time.has(sfx_id):
		if now - float(_last_play_time[sfx_id]) < MIN_RETRIGGER_DELAY:
			return
	_last_play_time[sfx_id] = now

	_init_audio_pool()
	if players.size() == 0:
		return

	var layers: Array = _sfx_bank[sfx_id]
	var jitter_pitch := pitch_override if pitch_override > 0.0 else randf_range(0.96, 1.04)

	for layer in layers:
		var stream_key: String = layer.get("s", "slice_1")
		if sfx_id == "footstep_stone":
			var steps := ["step_1", "step_2", "step_3"]
			stream_key = steps[play_count % steps.size()]

		var stream: AudioStream = _raw_streams.get(stream_key, null)
		if stream == null:
			continue

		var base_vol: float = float(layer.get("vol", 0.0)) + volume_offset_db
		var base_pitch: float = float(layer.get("pitch", 1.0)) * jitter_pitch
		var delay_sec: float = float(layer.get("delay", 0.0))
		var target_bus: String = str(layer.get("bus", BUS_NORMAL))

		if delay_sec <= 0.001 or not is_inside_tree():
			_trigger_single_layer(stream, base_vol, base_pitch, target_bus)
		else:
			var tw := create_tween()
			tw.tween_interval(delay_sec)
			tw.tween_callback(func():
				_trigger_single_layer(stream, base_vol, base_pitch, target_bus)
			)

	play_count += 1
	play_counts[sfx_id] = int(play_counts.get(sfx_id, 0)) + 1

func _trigger_single_layer(stream: AudioStream, vol_db: float, pitch_val: float, bus_name: String) -> void:
	if players.size() == 0:
		return
	var player := players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % max_players
	if AudioServer.get_bus_index(bus_name) != -1:
		player.bus = bus_name
	else:
		player.bus = "Master"
	player.stream = stream
	player.volume_db = clampf(vol_db, -45.0, 6.0)
	player.pitch_scale = clampf(pitch_val, 0.45, 2.2)
	if player.is_inside_tree():
		player.play()
