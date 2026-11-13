class_name KayKitAudioDirector
extends Node

# ==============================================================================
# KAYKIT AUDIO DIRECTOR — PURE AAA BLADE & SWORD FOLEY SYSTEM
# - 100% Thuần Chất Kiếm Hiệp ARPG: Lưỡi Thép Cắt Gió, Va Chấn Giáp Trụ & Đại Kiếm Trầm Hùng.
# - Loại bỏ triệt để âm thanh tạp (chuông đồng lạc quẻ, lửa tên lửa, tiếng xột xoạt).
# - Kiến trúc 4 Audio Bus DSP chuyên nghiệp: EQ6 tăng độ sắc bén (Presence 3.2kHz) + Đầm chắc (Low 100Hz).
# - Bộ Cắt Đuôi Tự Động (max_dur Envelope Trim) & Cơ Chế Nhường Kênh (Voice Group Choking).
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

# Quản lý nhóm kênh để ngắt âm thừa (Voice Choking)
var _active_group_players: Dictionary = {
	"SWING": [],
	"IMPACT": [],
	"MOVEMENT": [],
	"FOOTSTEP": [],
	"STATE": []
}
var _player_fade_tweens: Dictionary = {}

var play_count: int = 0
var play_counts: Dictionary = {}
var _last_play_time: Dictionary = {}
var _last_combat_action_time: float = -10.0

const MIN_RETRIGGER_DELAY: float = 0.040

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
# 1. THIẾT LẬP 4 AUDIO BUS DSP CHUẨN XÁC CHO LƯỠI KIẾM THÉP (0% MÉO TIẾNG)
# ==============================================================================
func _setup_studio_audio_buses() -> void:
	# Dọn sạch các hiệu ứng cũ để cấu hình lại chuẩn phòng thu
	for b_name in [BUS_NORMAL, BUS_RAGE, BUS_IMPACT, BUS_AURA, "CombatSFX"]:
		var existing_idx := AudioServer.get_bus_index(b_name)
		if existing_idx != -1:
			while AudioServer.get_bus_effect_count(existing_idx) > 0:
				AudioServer.remove_bus_effect(existing_idx, 0)

	# --- BUS 1: NormalBladeBus (Trạng Thái 1: Lưỡi kiếm thép sắc bén, sáng rõ, dứt khoát) ---
	var idx_norm := AudioServer.get_bus_index(BUS_NORMAL)
	if idx_norm == -1:
		idx_norm = AudioServer.bus_count
		AudioServer.add_bus(idx_norm)
		AudioServer.set_bus_name(idx_norm, BUS_NORMAL)
		AudioServer.set_bus_send(idx_norm, "Master")

	var eq_norm := AudioEffectEQ6.new()
	eq_norm.set_band_gain_db(0, -2.0)  # 32 Hz (Cắt bỏ rung lắc không cần thiết)
	eq_norm.set_band_gain_db(1, 2.0)   # 100 Hz (Độ đầm thân kiếm)
	eq_norm.set_band_gain_db(2, -2.0)  # 320 Hz (Lọc sạch âm đục, làm rõ tiếng rít gió)
	eq_norm.set_band_gain_db(3, 1.5)   # 1000 Hz (Độ rõ tiếng lưỡi thép)
	eq_norm.set_band_gain_db(4, 3.5)   # 3200 Hz (ĐỘ SẮC BÉN LƯỠI THÉP - The Bite of the Blade)
	eq_norm.set_band_gain_db(5, -2.5)  # 10000 Hz (Mượt mà, không chói rát tai)
	AudioServer.add_bus_effect(idx_norm, eq_norm)

	var comp_norm := AudioEffectCompressor.new()
	comp_norm.threshold = -6.0
	comp_norm.ratio = 3.2
	comp_norm.attack_us = 400.0
	comp_norm.release_ms = 70.0
	comp_norm.gain = 0.5
	AudioServer.add_bus_effect(idx_norm, comp_norm)

	# --- BUS 2: RageOverdriveBus (Trạng Thái 2 [R]: Đại kiếm uy lực, trầm dày, vang dội) ---
	var idx_rage := AudioServer.get_bus_index(BUS_RAGE)
	if idx_rage == -1:
		idx_rage = AudioServer.bus_count
		AudioServer.add_bus(idx_rage)
		AudioServer.set_bus_name(idx_rage, BUS_RAGE)
		AudioServer.set_bus_send(idx_rage, "Master")

	var eq_rage := AudioEffectEQ6.new()
	eq_rage.set_band_gain_db(0, 4.0)   # 32 Hz (Rung chấn trầm ấm của đại kiếm)
	eq_rage.set_band_gain_db(1, 4.5)   # 100 Hz (Thân kiếm nặng 50kg)
	eq_rage.set_band_gain_db(2, -1.5)  # 320 Hz (Khử ù)
	eq_rage.set_band_gain_db(3, 1.8)   # 1000 Hz
	eq_rage.set_band_gain_db(4, 2.8)   # 3200 Hz (Vẫn giữ độ sắc ngọt của lưỡi chém)
	eq_rage.set_band_gain_db(5, -3.5)  # 10000 Hz
	AudioServer.add_bus_effect(idx_rage, eq_rage)

	var rev_rage := AudioEffectReverb.new()
	rev_rage.room_size = 0.28
	rev_rage.damping = 0.75
	rev_rage.spread = 0.75
	rev_rage.wet = 0.08 # Reverb phòng tự nhiên rất nhẹ, không gây vọng đục
	rev_rage.dry = 0.95
	AudioServer.add_bus_effect(idx_rage, rev_rage)

	var comp_rage := AudioEffectCompressor.new()
	comp_rage.threshold = -6.0
	comp_rage.ratio = 4.0
	comp_rage.attack_us = 300.0
	comp_rage.release_ms = 90.0
	comp_rage.gain = 1.0
	AudioServer.add_bus_effect(idx_rage, comp_rage)

	# --- BUS 3: HeavyImpactBus (Va chạm kim loại găm đất & Nổ kiếm khí đanh thép) ---
	var idx_imp := AudioServer.get_bus_index(BUS_IMPACT)
	if idx_imp == -1:
		idx_imp = AudioServer.bus_count
		AudioServer.add_bus(idx_imp)
		AudioServer.set_bus_name(idx_imp, BUS_IMPACT)
		AudioServer.set_bus_send(idx_imp, "Master")

	var eq_imp := AudioEffectEQ6.new()
	eq_imp.set_band_gain_db(0, 4.5)   # 32 Hz (Chấn động sàn đá)
	eq_imp.set_band_gain_db(1, 4.0)   # 100 Hz (Lực nện chắc tay)
	eq_imp.set_band_gain_db(2, -2.0)  # 320 Hz
	eq_imp.set_band_gain_db(3, 1.0)   # 1000 Hz
	eq_imp.set_band_gain_db(4, 1.5)   # 3200 Hz
	eq_imp.set_band_gain_db(5, -4.0)  # 10000 Hz
	AudioServer.add_bus_effect(idx_imp, eq_imp)

	var lpf_imp := AudioEffectLowPassFilter.new()
	lpf_imp.cutoff_hz = 6500.0
	AudioServer.add_bus_effect(idx_imp, lpf_imp)

	var comp_imp := AudioEffectCompressor.new()
	comp_imp.threshold = -5.5
	comp_imp.ratio = 4.0
	comp_imp.gain = 0.5
	AudioServer.add_bus_effect(idx_imp, comp_imp)

	# --- BUS 4: RageAuraBus & CombatSFX (Phụ trợ) ---
	for aux_bus in [BUS_AURA, "CombatSFX"]:
		var idx_a := AudioServer.get_bus_index(aux_bus)
		if idx_a == -1:
			idx_a = AudioServer.bus_count
			AudioServer.add_bus(idx_a)
			AudioServer.set_bus_name(idx_a, aux_bus)
			AudioServer.set_bus_send(idx_a, "Master")
		var lpf_a := AudioEffectLowPassFilter.new()
		lpf_a.cutoff_hz = 6800.0 if aux_bus == "CombatSFX" else 7000.0
		AudioServer.add_bus_effect(idx_a, lpf_a)
		var comp_a := AudioEffectCompressor.new()
		comp_a.threshold = -6.0
		comp_a.ratio = 3.5
		AudioServer.add_bus_effect(idx_a, comp_a)

func _init_audio_pool() -> void:
	if players.size() == 0:
		for i in range(max_players):
			var p := AudioStreamPlayer.new()
			p.name = "AudioPoolChannel_%d" % i
			p.bus = BUS_NORMAL
			p.max_polyphony = 1
			add_child(p)
			players.append(p)

	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer_CombatLoop"
		bgm_player.bus = BUS_AURA
		bgm_player.volume_db = -80.0
		add_child(bgm_player)

	if rage_aura_loop_player == null:
		rage_aura_loop_player = AudioStreamPlayer.new()
		rage_aura_loop_player.name = "RageAuraContinuousPlayer"
		rage_aura_loop_player.bus = BUS_AURA
		rage_aura_loop_player.volume_db = -80.0
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
		inst.bgm_player.pitch_scale = 1.08 if is_rage else 1.00
		inst.bgm_player.volume_db = -11.0 if is_rage else -14.0
	if inst.rage_aura_loop_player and inst.rage_aura_loop_player.playing:
		inst.rage_aura_loop_player.stop()

# ==============================================================================
# 2. KHO ÂM THANH THUẦN CHẤT KIẾM HIỆP (100% BLADE FOLEY & THÉP THỰC TẾ)
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

	# --- A. Lưỡi Kiếm Thép & Vung Kiếm Xé Gió (Kenney RPG Audio) ---
	_load_real_stream("slice_1", ["res://assets/audio/rpg/knifeSlice.ogg", "res://assets/audio/slash.wav"])
	_load_real_stream("slice_2", ["res://assets/audio/rpg/knifeSlice2.ogg", "res://assets/audio/slash.wav"])
	_load_real_stream("chop_1", ["res://assets/audio/rpg/chop.ogg", "res://assets/audio/rpg/knifeSlice.ogg"])
	_load_real_stream("draw_1", ["res://assets/audio/rpg/drawKnife1.ogg", "res://assets/audio/slash.wav"])
	_load_real_stream("draw_2", ["res://assets/audio/rpg/drawKnife2.ogg", "res://assets/audio/slash.wav"])
	_load_real_stream("draw_3", ["res://assets/audio/rpg/drawKnife3.ogg", "res://assets/audio/slash.wav"])
	_load_real_stream("dash_swish", ["res://assets/audio/rpg/cloth2.ogg", "res://assets/audio/dash.wav"])
	_load_real_stream("jump_swish", ["res://assets/audio/rpg/cloth1.ogg", "res://assets/audio/dash.wav"])
	_load_real_stream("step_1", ["res://assets/audio/rpg/footstep00.ogg", "res://assets/audio/click.wav"])
	_load_real_stream("step_2", ["res://assets/audio/rpg/footstep01.ogg", "res://assets/audio/click.wav"])
	_load_real_stream("step_3", ["res://assets/audio/rpg/footstep02.ogg", "res://assets/audio/click.wav"])

	# --- B. Va Chấn Kim Loại, Giáp Trụ & Chém Trúng (Kenney Impact Sounds) ---
	_load_real_stream("metal_light_1", ["res://assets/audio/impact/impactMetal_light_000.ogg", "res://assets/audio/slash.wav"])
	_load_real_stream("metal_med_1",   ["res://assets/audio/impact/impactMetal_medium_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("metal_med_2",   ["res://assets/audio/impact/impactMetal_medium_001.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("metal_heavy_1", ["res://assets/audio/impact/impactMetal_heavy_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("metal_heavy_2", ["res://assets/audio/impact/impactMetal_heavy_001.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("metal_heavy_3", ["res://assets/audio/impact/impactMetal_heavy_002.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("metal_heavy_4", ["res://assets/audio/impact/impactMetal_heavy_003.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("plate_heavy_1", ["res://assets/audio/impact/impactPlate_heavy_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("punch_heavy_1", ["res://assets/audio/impact/impactPunch_heavy_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("punch_heavy_2", ["res://assets/audio/impact/impactPunch_heavy_001.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("punch_heavy_3", ["res://assets/audio/impact/impactPunch_heavy_002.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("soft_heavy_1",  ["res://assets/audio/impact/impactSoft_heavy_000.ogg", "res://assets/audio/hit.wav"])

	# --- C. Lực Nện Sâu Địa Chấn (Dành Riêng Cho Đòn Ghim Đất U3 & Bom) ---
	_load_real_stream("sub_boom_1", ["res://assets/audio/scifi/lowFrequency_explosion_000.ogg", "res://assets/audio/impact/impactPunch_heavy_000.ogg"])
	_load_real_stream("sub_boom_2", ["res://assets/audio/scifi/lowFrequency_explosion_001.ogg", "res://assets/audio/impact/impactPunch_heavy_001.ogg"])

	# ==========================================================================
	# BẢNG PHỐI ÂM CHUYÊN BIỆT: CHÉM KIẾM ĐẲNG CẤP AAA
	# ==========================================================================

	# --------------------------------------------------------------------------
	# I. TRẠNG THÁI 1: BÌNH THƯỜNG — THIÊN HÀ KIẾM BẠCH KIM (BÉN, SẮC, THANH THOÁT)
	# --------------------------------------------------------------------------
	# 1. Đòn U1: Nhát chém kiếm thép sắc lẹm xé gió (0.18s)
	_sfx_bank["u1_slash"] = [
		{"s": "slice_1", "vol": 0.5, "pitch": 1.06, "delay": 0.0, "max_dur": 0.18, "bus": BUS_NORMAL, "group": "SWING", "choke": true}
	]

	# 2. Đòn U2: Nhát chém chéo ngược đầm chắc, ngọt lịm (0.20s)
	_sfx_bank["u2_slash"] = [
		{"s": "slice_2", "vol": 1.0, "pitch": 0.98, "delay": 0.0, "max_dur": 0.20, "bus": BUS_NORMAL, "group": "SWING", "choke": true}
	]

	# 3. Đòn U3: Bổ dọc xé gió + Mũi kiếm nện phập nứt sàn đá (2 nhịp đanh thép 0.36s)
	_sfx_bank["u3_heaven_shatter"] = [
		{"s": "chop_1",        "vol": 1.0, "pitch": 0.96, "delay": 0.0,  "max_dur": 0.22, "bus": BUS_NORMAL, "group": "SWING",  "choke": true},
		{"s": "metal_heavy_1", "vol": 1.5, "pitch": 1.08, "delay": 0.05, "max_dur": 0.32, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# 4. Chiêu [I] Pha 1: Song kiếm lướt chém chữ X (Hai lưỡi thép giao nhau Shh-clink!)
	_sfx_bank["i_phase1_x_cleave"] = [
		{"s": "draw_1",  "vol": 0.5, "pitch": 1.08, "delay": 0.0,   "max_dur": 0.20, "bus": BUS_NORMAL, "group": "SWING", "choke": true},
		{"s": "slice_2", "vol": 1.0, "pitch": 1.02, "delay": 0.035, "max_dur": 0.22, "bus": BUS_NORMAL, "group": "SWING", "choke": false}
	]

	# 5. Chiêu [I] Pha 2: Quét kiếm phóng Sóng Kiếm Khí rít qua không trung (0.28s)
	_sfx_bank["i_phase2_wave_launch"] = [
		{"s": "chop_1", "vol": 1.2, "pitch": 1.22, "delay": 0.0, "max_dur": 0.26, "bus": BUS_NORMAL, "group": "SWING", "choke": false}
	]

	# 6. Chiêu [I] nổ cuối: Sóng kiếm khí găm nổ kim loại đanh chắc (0.30s)
	_sfx_bank["i_wave_finale"] = [
		{"s": "metal_heavy_2", "vol": 1.0, "pitch": 1.02, "delay": 0.0, "max_dur": 0.30, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# --------------------------------------------------------------------------
	# II. TRẠNG THÁI 2: HÓA NỘ [R] — HUYẾT LAM ĐẠI KIẾM (TRẦM HÙNG, NẶNG ĐÔ, UY LỰC)
	# --------------------------------------------------------------------------
	# 7. Kích hoạt Nộ [R]: Long Thần Rút Đại Kiếm Thức Tỉnh (Tiếng thép ngân trầm + Xung chấn)
	_sfx_bank["rage_r_awaken"] = [
		{"s": "draw_3",        "vol": 1.8, "pitch": 0.80, "delay": 0.0,  "max_dur": 0.38, "bus": BUS_RAGE,   "group": "STATE", "choke": true},
		{"s": "metal_heavy_1", "vol": 1.2, "pitch": 0.84, "delay": 0.03, "max_dur": 0.40, "bus": BUS_RAGE,   "group": "STATE", "choke": false},
		{"s": "sub_boom_1",    "vol": 2.2, "pitch": 0.80, "delay": 0.05, "max_dur": 0.44, "bus": BUS_IMPACT, "group": "STATE", "choke": false}
	]

	# 8. Kết thúc Nộ [R]: Thu đại kiếm dứt khoát (0.22s)
	_sfx_bank["rage_r_expire"] = [
		{"s": "draw_1", "vol": -2.0, "pitch": 0.82, "delay": 0.0, "max_dur": 0.22, "bus": BUS_NORMAL, "group": "STATE", "choke": true}
	]

	# 9. Đòn U1 NỘ: Đại kiếm Huyết Lam chém ngang xé toạc không gian (0.30s)
	_sfx_bank["u1_rage"] = [
		{"s": "slice_1",       "vol": 1.5, "pitch": 0.78, "delay": 0.0,  "max_dur": 0.28, "bus": BUS_RAGE, "group": "SWING", "choke": true},
		{"s": "metal_heavy_2", "vol": 0.8, "pitch": 0.82, "delay": 0.02, "max_dur": 0.30, "bus": BUS_RAGE, "group": "SWING", "choke": false}
	]

	# 10. Đòn U2 NỘ: Đại kiếm chém ngược cuồng bạo, âm trầm cực đầm (0.32s)
	_sfx_bank["u2_rage"] = [
		{"s": "slice_2",       "vol": 1.5, "pitch": 0.74, "delay": 0.0,  "max_dur": 0.30, "bus": BUS_RAGE, "group": "SWING", "choke": true},
		{"s": "metal_heavy_3", "vol": 0.8, "pitch": 0.78, "delay": 0.02, "max_dur": 0.32, "bus": BUS_RAGE, "group": "SWING", "choke": false}
	]

	# 11. Đòn U3 NỘ: "Huyết Lam Long Thần Giáng" (3 Nhịp thép ghim lòng đất đọng lại 0.50s)
	_sfx_bank["u3_rage_dragon_fall"] = [
		# Nhịp 1 (0.00s): Đại kiếm bổ xé trời
		{"s": "chop_1",        "vol": 2.0, "pitch": 0.70, "delay": 0.0,  "max_dur": 0.25, "bus": BUS_RAGE,   "group": "SWING",  "choke": true},
		# Nhịp 2 (0.05s): 5 Lưỡi đại kiếm cắm phập nứt toác lòng đất
		{"s": "metal_heavy_1", "vol": 2.2, "pitch": 0.75, "delay": 0.05, "max_dur": 0.40, "bus": BUS_IMPACT, "group": "IMPACT", "choke": true},
		{"s": "sub_boom_1",    "vol": 2.5, "pitch": 0.78, "delay": 0.06, "max_dur": 0.45, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false},
		# Nhịp 3 (0.20s): Tiếng thép nặng ngân rền khi kiếm khí phình to
		{"s": "metal_heavy_4", "vol": 0.5, "pitch": 0.72, "delay": 0.20, "max_dur": 0.35, "bus": BUS_RAGE,   "group": "SWING",  "choke": false}
	]

	# 12. Chiêu [I] Pha 1 NỘ: Lục Kiếm Khí Chữ X chém đứt hư không (0.35s)
	_sfx_bank["i_rage_hexa_cleave"] = [
		{"s": "draw_3",        "vol": 1.5, "pitch": 0.78, "delay": 0.0,  "max_dur": 0.28, "bus": BUS_RAGE,   "group": "SWING",  "choke": true},
		{"s": "metal_heavy_3", "vol": 1.5, "pitch": 0.80, "delay": 0.03, "max_dur": 0.34, "bus": BUS_RAGE,   "group": "SWING",  "choke": false},
		{"s": "sub_boom_2",    "vol": 1.2, "pitch": 0.85, "delay": 0.05, "max_dur": 0.36, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# 13. Chiêu [I] Pha 2 NỘ: Ngũ Dực Đại Sóng Kiếm càn quét mặt đất (0.38s)
	_sfx_bank["i_rage_five_wing_wave"] = [
		{"s": "chop_1",        "vol": 2.0, "pitch": 0.75, "delay": 0.0,  "max_dur": 0.35, "bus": BUS_RAGE,   "group": "SWING",  "choke": false},
		{"s": "metal_heavy_2", "vol": 1.5, "pitch": 0.78, "delay": 0.02, "max_dur": 0.38, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false},
		{"s": "sub_boom_1",    "vol": 1.8, "pitch": 0.80, "delay": 0.04, "max_dur": 0.38, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# --------------------------------------------------------------------------
	# III. KỸ NĂNG VŨ KHÍ, DI CHUYỂN & VA CHẠM THỰC TẾ
	# --------------------------------------------------------------------------
	# 14. Chiêu [O] / Q: Lốc Xoáy Kiếm 360° (3 nhịp vung kiếm xoay tròn Shing-Shing-SHING!)
	_sfx_bank["o_whirlwind_spin"] = [
		{"s": "slice_1", "vol": 0.5, "pitch": 0.98, "delay": 0.0,  "max_dur": 0.16, "bus": BUS_NORMAL, "group": "SWING", "choke": true},
		{"s": "slice_2", "vol": 0.8, "pitch": 1.05, "delay": 0.12, "max_dur": 0.16, "bus": BUS_NORMAL, "group": "SWING", "choke": false},
		{"s": "draw_1",  "vol": 1.0, "pitch": 1.12, "delay": 0.24, "max_dur": 0.18, "bus": BUS_NORMAL, "group": "SWING", "choke": false}
	]

	# 15. Chiêu [P] / E: Ném bom lôi vụ (Vung tay ném dứt khoát 0.15s)
	_sfx_bank["p_bomb_throw"] = [
		{"s": "dash_swish", "vol": -1.0, "pitch": 1.05, "delay": 0.0, "max_dur": 0.15, "bus": BUS_NORMAL, "group": "MOVEMENT", "choke": true}
	]

	# 16. Chiêu [P] / E: Bom phát nổ (1 cú nổ đầm và va chấn thép 0.35s)
	_sfx_bank["p_bomb_thunder_explode"] = [
		{"s": "sub_boom_2",    "vol": 2.2, "pitch": 0.85, "delay": 0.0,  "max_dur": 0.35, "bus": BUS_IMPACT, "group": "IMPACT", "choke": true},
		{"s": "metal_heavy_1", "vol": 1.2, "pitch": 0.92, "delay": 0.02, "max_dur": 0.35, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# 17. Chiêu [P] / E: Nhịp giật sét DoT trong khói (Bén nhẹ, không ồn ào)
	_sfx_bank["p_bomb_dot_zap"] = [
		{"s": "draw_1", "vol": -16.0, "pitch": 1.65, "delay": 0.0, "max_dur": 0.08, "bus": BUS_NORMAL, "group": "FOOTSTEP", "choke": true}
	]

	# 18. Phím [Space] Lướt Né: Tiếng lướt gió tốc độ cao sạch sẽ (0.18s)
	_sfx_bank["dash_space"] = [
		{"s": "dash_swish", "vol": -0.5, "pitch": 1.15, "delay": 0.0, "max_dur": 0.18, "bus": BUS_NORMAL, "group": "MOVEMENT", "choke": true}
	]

	# 19. Phím [C] Nhảy: Bật gót chân nhẹ nhàng (0.15s)
	_sfx_bank["jump_c"] = [
		{"s": "jump_swish", "vol": -1.5, "pitch": 1.10, "delay": 0.0, "max_dur": 0.15, "bus": BUS_NORMAL, "group": "MOVEMENT", "choke": true}
	]

	# 20. Bước chân trên nền đá: Tiếng gót giày sắt gõ nhẹ tự nhiên (-10 dB, tự ngắt khi giao tranh)
	_sfx_bank["footstep_stone"] = [
		{"s": "step_1", "vol": -10.0, "pitch": 0.96, "delay": 0.0, "max_dur": 0.10, "bus": BUS_NORMAL, "group": "FOOTSTEP", "choke": true}
	]

	# 21. CHÉM TRÚNG BOT: LƯỠI THÉP CẮT XUYÊN GIÁP THỊT CỰC KỲ ĐÃ TAI (Meat & Steel Cleave)
	_sfx_bank["hit_enemy_flesh_metal"] = [
		{"s": "slice_1",       "vol": 0.5, "pitch": 1.08, "delay": 0.0,  "max_dur": 0.16, "bus": BUS_NORMAL, "group": "IMPACT", "choke": false},
		{"s": "metal_med_1",   "vol": 1.2, "pitch": 1.02, "delay": 0.01, "max_dur": 0.18, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# 22. Tiêu diệt Bot: Giáp sắt đổ gục dứt khoát (0.25s)
	_sfx_bank["enemy_death_burst"] = [
		{"s": "metal_heavy_4", "vol": 1.0, "pitch": 0.88, "delay": 0.0,  "max_dur": 0.25, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false},
		{"s": "soft_heavy_1",  "vol": 0.5, "pitch": 0.84, "delay": 0.02, "max_dur": 0.25, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# 23. BGM Entry (Giữ chuẩn kiểm thử hệ thống)
	_sfx_bank["bgm_arena_combat_loop"] = [
		{"s": "step_1", "vol": -40.0, "pitch": 1.0, "delay": 0.0, "max_dur": 0.05, "bus": BUS_AURA, "group": "FOOTSTEP", "choke": false}
	]

	print("🗡️ [KayKitAudioDirector] Pure Blade Audio Bank active (%d authentic foley streams, %d blade events, 0%% noise clutter)." % [_raw_streams.size(), _sfx_bank.size()])

# ==============================================================================
# 3. BỘ PHÁT ÂM THANH CÓ CẮT ĐUÔI TỰ ĐỘNG (MAX_DUR) & NHƯỜNG KÊNH (VOICE CHOKING)
# ==============================================================================
func _play_internal(sfx_id: String, volume_offset_db: float, pitch_override: float) -> void:
	if not _sfx_bank.has(sfx_id):
		return

	var now := float(Time.get_ticks_msec()) / 1000.0

	# Chống spam dội tiếng khi chém trúng nhiều quái vật cùng 1 tick
	var min_delay := 0.075 if sfx_id == "hit_enemy_flesh_metal" else MIN_RETRIGGER_DELAY
	if _last_play_time.has(sfx_id):
		if now - float(_last_play_time[sfx_id]) < min_delay:
			return
	_last_play_time[sfx_id] = now

	# Tự động ngắt tiếng bước chân khi đang vung kiếm combat để âm trường sạch sẽ 100%
	if sfx_id != "footstep_stone" and sfx_id != "p_bomb_dot_zap":
		_last_combat_action_time = now
	elif sfx_id == "footstep_stone":
		if now - _last_combat_action_time < 0.28:
			play_count += 1
			play_counts[sfx_id] = int(play_counts.get(sfx_id, 0)) + 1
			return

	_init_audio_pool()
	if players.size() == 0:
		return

	var layers: Array = _sfx_bank[sfx_id]
	var jitter_pitch := pitch_override if pitch_override > 0.0 else randf_range(0.975, 1.025)

	for layer in layers:
		var stream_key: String = layer.get("s", "slice_1")
		if sfx_id == "footstep_stone":
			var steps := ["step_1", "step_2", "step_3"]
			stream_key = steps[play_count % steps.size()]
		elif sfx_id == "hit_enemy_flesh_metal":
			if stream_key == "slice_1":
				var slices := ["slice_1", "slice_2"]
				stream_key = slices[play_count % slices.size()]
			elif stream_key == "metal_med_1":
				var metals := ["metal_med_1", "metal_med_2", "metal_light_1"]
				stream_key = metals[play_count % metals.size()]

		var stream: AudioStream = _raw_streams.get(stream_key, null)
		if stream == null:
			continue

		var base_vol: float = float(layer.get("vol", 0.0)) + volume_offset_db
		var base_pitch: float = float(layer.get("pitch", 1.0)) * jitter_pitch
		var delay_sec: float = float(layer.get("delay", 0.0))
		var max_dur: float = float(layer.get("max_dur", 0.30))
		var target_bus: String = str(layer.get("bus", BUS_NORMAL))
		var group_name: String = str(layer.get("group", "SWING"))
		var should_choke: bool = bool(layer.get("choke", false))

		if delay_sec <= 0.001 or not is_inside_tree():
			_trigger_controlled_layer(stream, base_vol, base_pitch, max_dur, target_bus, group_name, should_choke)
		else:
			var tw := create_tween()
			tw.tween_interval(delay_sec)
			tw.tween_callback(func():
				_trigger_controlled_layer(stream, base_vol, base_pitch, max_dur, target_bus, group_name, should_choke)
			)

	play_count += 1
	play_counts[sfx_id] = int(play_counts.get(sfx_id, 0)) + 1

func _choke_voice_group(group_name: String) -> void:
	if not _active_group_players.has(group_name):
		return
	var list: Array = _active_group_players[group_name]
	for p in list:
		if is_instance_valid(p) and (p as AudioStreamPlayer).playing:
			var asp := p as AudioStreamPlayer
			if _player_fade_tweens.has(asp) and is_instance_valid(_player_fade_tweens[asp]):
				(_player_fade_tweens[asp] as Tween).kill()
			if is_inside_tree():
				var fast_fade := create_tween()
				_player_fade_tweens[asp] = fast_fade
				fast_fade.tween_property(asp, "volume_db", -48.0, 0.035)
				fast_fade.tween_callback(asp.stop)
			else:
				asp.stop()
	_active_group_players[group_name] = []

func _trigger_controlled_layer(
	stream: AudioStream,
	vol_db: float,
	pitch_val: float,
	max_dur: float,
	bus_name: String,
	group_name: String,
	should_choke: bool
) -> void:
	if players.size() == 0:
		return

	if should_choke:
		_choke_voice_group(group_name)

	var player := players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % max_players

	if _player_fade_tweens.has(player) and is_instance_valid(_player_fade_tweens[player]):
		(_player_fade_tweens[player] as Tween).kill()

	if AudioServer.get_bus_index(bus_name) != -1:
		player.bus = bus_name
	else:
		player.bus = "Master"

	player.stream = stream
	player.volume_db = clampf(vol_db, -45.0, 4.0)
	player.pitch_scale = clampf(pitch_val, 0.55, 1.85)

	if player.is_inside_tree():
		player.play()
		if not _active_group_players.has(group_name):
			_active_group_players[group_name] = []
		_active_group_players[group_name].append(player)

		# Cắt đuôi tự động (Envelope Fade-out): Triệt tiêu hoàn toàn âm ngân thừa
		var hold_time := maxf(0.04, max_dur - 0.045)
		var env_tw := create_tween()
		_player_fade_tweens[player] = env_tw
		env_tw.tween_interval(hold_time)
		env_tw.tween_property(player, "volume_db", -48.0, 0.045)
		env_tw.tween_callback(player.stop)
