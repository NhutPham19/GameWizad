class_name KayKitAudioDirector
extends Node

# ==============================================================================
# KAYKIT AUDIO DIRECTOR — AAA STUDIO STEREO MASTER AUDIO SYSTEM (DIRECTIVE 32)
# - 100% Thuần Chất ARPG Chặt Chém Đỉnh Cao: 25 File Master Stereo .wav Độc Bản Riêng Biệt.
# - Tuyệt đối không dùng chung 1 file chop.ogg hay knifeSlice.ogg cho nhiều chiêu thức.
# - Bỏ hoàn toàn đoạn Tween cắt cụt đuôi 0.18s-0.30s: Để đại tuyệt kỹ U3, I, R, P ngân vang trọn vẹn 0.7s-1.2s.
# - Tích hợp nhạc nền chiến trận BGM (25_bgm_arena_combat_loop.wav) tự động phát & phím F2 bật/tắt.
# - Kiến trúc 4 Audio Bus DSP chuyên nghiệp: EQ6 + Compressor + Stereo Reverb tự nhiên.
# - Cơ chế Voice Group Choking nhường kênh thông minh giữa các nhịp chém.
# ==============================================================================

static var _instance: KayKitAudioDirector = null
static var _raw_streams: Dictionary = {}
static var _sfx_bank: Dictionary = {}
static var _is_prebaked: bool = false
static var _is_adding: bool = false
static var bgm_enabled: bool = true

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
	start_bgm()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F2 or event.physical_keycode == KEY_F2:
			toggle_bgm()

# ==============================================================================
# 1. THIẾT LẬP 4 AUDIO BUS DSP CHUẨN PHÒNG THU (0% DISTORTION / 0% CHORUS)
# ==============================================================================
func _setup_studio_audio_buses() -> void:
	for b_name in [BUS_NORMAL, BUS_RAGE, BUS_IMPACT, BUS_AURA, "CombatSFX"]:
		var existing_idx := AudioServer.get_bus_index(b_name)
		if existing_idx != -1:
			while AudioServer.get_bus_effect_count(existing_idx) > 0:
				AudioServer.remove_bus_effect(existing_idx, 0)

	# --- BUS 1: NormalBladeBus (Trạng Thái 1: Bạch Kim Cực Quang - Sắc bén, dứt khoát) ---
	var idx_norm := AudioServer.get_bus_index(BUS_NORMAL)
	if idx_norm == -1:
		idx_norm = AudioServer.bus_count
		AudioServer.add_bus(idx_norm)
		AudioServer.set_bus_name(idx_norm, BUS_NORMAL)
		AudioServer.set_bus_send(idx_norm, "Master")

	var eq_norm := AudioEffectEQ6.new()
	eq_norm.set_band_gain_db(0, -2.0)  # 32 Hz
	eq_norm.set_band_gain_db(1, 2.0)   # 100 Hz
	eq_norm.set_band_gain_db(2, -2.0)  # 320 Hz
	eq_norm.set_band_gain_db(3, 1.5)   # 1000 Hz
	eq_norm.set_band_gain_db(4, 3.5)   # 3200 Hz (Độ sắc bén của lưỡi kiếm)
	eq_norm.set_band_gain_db(5, -2.5)  # 10000 Hz
	AudioServer.add_bus_effect(idx_norm, eq_norm)

	var comp_norm := AudioEffectCompressor.new()
	comp_norm.threshold = -6.0
	comp_norm.ratio = 3.2
	comp_norm.attack_us = 400.0
	comp_norm.release_ms = 70.0
	comp_norm.gain = 0.5
	AudioServer.add_bus_effect(idx_norm, comp_norm)

	# --- BUS 2: RageOverdriveBus (Trạng Thái 2 [R]: Huyết Lam Cuồng Nộ - Trầm dày, uy lực) ---
	var idx_rage := AudioServer.get_bus_index(BUS_RAGE)
	if idx_rage == -1:
		idx_rage = AudioServer.bus_count
		AudioServer.add_bus(idx_rage)
		AudioServer.set_bus_name(idx_rage, BUS_RAGE)
		AudioServer.set_bus_send(idx_rage, "Master")

	var eq_rage := AudioEffectEQ6.new()
	eq_rage.set_band_gain_db(0, 4.0)   # 32 Hz (Rung chấn trầm ấm của đại kiếm)
	eq_rage.set_band_gain_db(1, 4.5)   # 100 Hz (Thân kiếm nặng)
	eq_rage.set_band_gain_db(2, -1.5)  # 320 Hz
	eq_rage.set_band_gain_db(3, 1.8)   # 1000 Hz
	eq_rage.set_band_gain_db(4, 2.8)   # 3200 Hz
	eq_rage.set_band_gain_db(5, -3.5)  # 10000 Hz
	AudioServer.add_bus_effect(idx_rage, eq_rage)

	var rev_rage := AudioEffectReverb.new()
	rev_rage.room_size = 0.28
	rev_rage.damping = 0.75
	rev_rage.spread = 0.75
	rev_rage.wet = 0.08
	rev_rage.dry = 0.95
	AudioServer.add_bus_effect(idx_rage, rev_rage)

	var comp_rage := AudioEffectCompressor.new()
	comp_rage.threshold = -6.0
	comp_rage.ratio = 4.0
	comp_rage.attack_us = 300.0
	comp_rage.release_ms = 90.0
	comp_rage.gain = 1.0
	AudioServer.add_bus_effect(idx_rage, comp_rage)

	# --- BUS 3: HeavyImpactBus (Va chạm kim loại nện đất & Nổ sấm sét địa chấn) ---
	var idx_imp := AudioServer.get_bus_index(BUS_IMPACT)
	if idx_imp == -1:
		idx_imp = AudioServer.bus_count
		AudioServer.add_bus(idx_imp)
		AudioServer.set_bus_name(idx_imp, BUS_IMPACT)
		AudioServer.set_bus_send(idx_imp, "Master")

	var eq_imp := AudioEffectEQ6.new()
	eq_imp.set_band_gain_db(0, 4.5)   # 32 Hz (Chấn động sàn đá)
	eq_imp.set_band_gain_db(1, 4.0)   # 100 Hz
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

	# --- BUS 4: RageAuraBus & CombatSFX (Nhạc Nền BGM & Phụ Trợ) ---
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
		bgm_player.volume_db = -12.0
		add_child(bgm_player)
		var bgm_stream: AudioStream = _raw_streams.get("25_bgm_arena_combat_loop", null)
		if bgm_stream == null:
			bgm_stream = _raw_streams.get("bgm_arena_combat_loop", null)
		if bgm_stream != null:
			if bgm_stream is AudioStreamWAV:
				(bgm_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			bgm_player.stream = bgm_stream
			bgm_player.finished.connect(func():
				if bgm_player and is_instance_valid(bgm_player) and bgm_enabled:
					bgm_player.play()
			)

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
	var inst := ensure_initialized()
	if inst and inst.bgm_player:
		if not inst.bgm_player.playing and bgm_enabled:
			var bgm_stream: AudioStream = _raw_streams.get("25_bgm_arena_combat_loop", null)
			if bgm_stream != null and inst.bgm_player.stream == null:
				if bgm_stream is AudioStreamWAV:
					(bgm_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
				inst.bgm_player.stream = bgm_stream
			if inst.bgm_player.stream != null:
				inst.bgm_player.play()
				print("🎵 [KayKitAudioDirector] BGM Started: 25_bgm_arena_combat_loop.wav (120 BPM Taiko Loop)")

static func toggle_bgm() -> bool:
	var inst := ensure_initialized()
	if inst and inst.bgm_player:
		bgm_enabled = not bgm_enabled
		if bgm_enabled:
			if not inst.bgm_player.playing:
				inst.bgm_player.play()
			print("🎵 [KayKitAudioDirector] BGM Toggled: ON (F2)")
		else:
			inst.bgm_player.stop()
			print("🎵 [KayKitAudioDirector] BGM Toggled: OFF (F2)")
		return bgm_enabled
	return false

static func set_rage_bgm_mode(is_rage: bool) -> void:
	var inst := ensure_initialized()
	if inst == null:
		return
	inst._init_audio_pool()
	if inst.bgm_player:
		inst.bgm_player.pitch_scale = 1.08 if is_rage else 1.00
		inst.bgm_player.volume_db = -10.0 if is_rage else -12.0
	if inst.rage_aura_loop_player and inst.rage_aura_loop_player.playing:
		inst.rage_aura_loop_player.stop()

# ==============================================================================
# 2. KHO 25 FILE MASTER STEREO .WAV ĐỘC BẢN RIÊNG BIỆT CHO TỪNG KỸ NĂNG (DIRECTIVE 32)
# ==============================================================================
func _load_master_stream(key: String, filename: String) -> AudioStream:
	var path := "res://assets/audio/master_v32/" + filename
	if ResourceLoader.exists(path):
		var s := ResourceLoader.load(path) as AudioStream
		if s != null:
			_raw_streams[key] = s
			_raw_streams[filename] = s
			return s
	return null

func _prebake_audio_bank() -> void:
	if _is_prebaked:
		return
	_is_prebaked = true

	# Nạp đầy đủ 25 file Master Stereo .wav
	var s01 := _load_master_stream("01_u1_slash_platinum", "01_u1_slash_platinum.wav")
	var s02 := _load_master_stream("02_u2_slash_platinum", "02_u2_slash_platinum.wav")
	var s03 := _load_master_stream("03_u3_heaven_shatter", "03_u3_heaven_shatter.wav")
	var s04 := _load_master_stream("04_i_phase1_x_cleave", "04_i_phase1_x_cleave.wav")
	var s05 := _load_master_stream("05_i_phase2_wave_launch", "05_i_phase2_wave_launch.wav")
	var s06 := _load_master_stream("06_i_wave_finale", "06_i_wave_finale.wav")
	var s07 := _load_master_stream("07_rage_r_awaken", "07_rage_r_awaken.wav")
	var s08 := _load_master_stream("08_rage_r_expire", "08_rage_r_expire.wav")
	var s09 := _load_master_stream("09_u1_rage_crimson", "09_u1_rage_crimson.wav")
	var s10 := _load_master_stream("10_u2_rage_cobalt", "10_u2_rage_cobalt.wav")
	var s11 := _load_master_stream("11_u3_rage_dragon_fall", "11_u3_rage_dragon_fall.wav")
	var s12 := _load_master_stream("12_i_rage_hexa_cleave", "12_i_rage_hexa_cleave.wav")
	var s13 := _load_master_stream("13_i_rage_five_wing_wave", "13_i_rage_five_wing_wave.wav")
	var s14 := _load_master_stream("14_o_whirlwind_spin", "14_o_whirlwind_spin.wav")
	var s15 := _load_master_stream("15_p_bomb_throw", "15_p_bomb_throw.wav")
	var s16 := _load_master_stream("16_p_bomb_thunder_explode", "16_p_bomb_thunder_explode.wav")
	var s17 := _load_master_stream("17_p_bomb_dot_zap", "17_p_bomb_dot_zap.wav")
	var s18 := _load_master_stream("18_dash_space", "18_dash_space.wav")
	var s19 := _load_master_stream("19_jump_c", "19_jump_c.wav")
	var s20 := _load_master_stream("20_footstep_stone_1", "20_footstep_stone_1.wav")
	var s21 := _load_master_stream("21_footstep_stone_2", "21_footstep_stone_2.wav")
	var s22 := _load_master_stream("22_hit_enemy_cleave_1", "22_hit_enemy_cleave_1.wav")
	var s23 := _load_master_stream("23_hit_enemy_cleave_2", "23_hit_enemy_cleave_2.wav")
	var s24 := _load_master_stream("24_enemy_death_burst", "24_enemy_death_burst.wav")
	var s25 := _load_master_stream("25_bgm_arena_combat_loop", "25_bgm_arena_combat_loop.wav")
	_raw_streams["bgm_arena_combat_loop"] = s25

	# ==========================================================================
	# ÁNH XẠ 1-1 TỪNG KỸ NĂNG VÀO FILE MASTER STEREO .WAV RIÊNG BIỆT
	# CẤM TUYỆT ĐỐI DÙNG CHUNG 1 FILE CHO NHIỀU CHIÊU THỨC CHIẾN ĐẤU!
	# ==========================================================================

	# --- PHẦN I: TRẠNG THÁI 1 (BẠCH KIM CỰC QUANG) ---
	# 1. Đòn U1: Lưỡi kiếm thép sắc lẹm xé gió
	_sfx_bank["u1_slash"] = [
		{"s": "01_u1_slash_platinum", "stream": s01, "file": "01_u1_slash_platinum.wav", "vol": 0.5, "pitch": 1.0, "bus": BUS_NORMAL, "group": "SWING", "choke": true}
	]

	# 2. Đòn U2: Nhát chém chéo ngược đầm chắc, tinh thể ánh sáng
	_sfx_bank["u2_slash"] = [
		{"s": "02_u2_slash_platinum", "stream": s02, "file": "02_u2_slash_platinum.wav", "vol": 0.8, "pitch": 1.0, "bus": BUS_NORMAL, "group": "SWING", "choke": true}
	]

	# 3. Đòn U3: Đại kiếm Thiên Hạ Liệt nện sàn đá nứt toác, lửa bùng, ngân vang 0.82s
	_sfx_bank["u3_heaven_shatter"] = [
		{"s": "03_u3_heaven_shatter", "stream": s03, "file": "03_u3_heaven_shatter.wav", "vol": 1.5, "pitch": 1.0, "bus": BUS_NORMAL, "group": "SWING", "choke": true}
	]

	# 4. Chiêu [I] Pha 1: Song kiếm lướt chém chữ X
	_sfx_bank["i_phase1_x_cleave"] = [
		{"s": "04_i_phase1_x_cleave", "stream": s04, "file": "04_i_phase1_x_cleave.wav", "vol": 1.0, "pitch": 1.0, "bus": BUS_NORMAL, "group": "SWING", "choke": true}
	]

	# 5. Chiêu [I] Pha 2: Quét kiếm phóng Sóng Kiếm Khí
	_sfx_bank["i_phase2_wave_launch"] = [
		{"s": "05_i_phase2_wave_launch", "stream": s05, "file": "05_i_phase2_wave_launch.wav", "vol": 1.2, "pitch": 1.0, "bus": BUS_NORMAL, "group": "SWING", "choke": false}
	]

	# 6. Chiêu [I] Nổ cuối: Sóng kiếm khí găm nổ kim loại đanh chắc
	_sfx_bank["i_wave_finale"] = [
		{"s": "06_i_wave_finale", "stream": s06, "file": "06_i_wave_finale.wav", "vol": 1.2, "pitch": 1.0, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# --- PHẦN II: TRẠNG THÁI 2 HÓA NỘ [R] (HUYẾT LAM LONG THẦN - LỬA NGỤC, SẤM SÉT, ĐỊA CHẤN) ---
	# 7. Kích hoạt Nộ [R]: Long Thần Rút Đại Kiếm Thức Tỉnh (1.15s)
	_sfx_bank["rage_r_awaken"] = [
		{"s": "07_rage_r_awaken", "stream": s07, "file": "07_rage_r_awaken.wav", "vol": 2.2, "pitch": 1.0, "bus": BUS_RAGE, "group": "STATE", "choke": true}
	]

	# 8. Kết thúc Nộ [R]: Thu đại kiếm dứt khoát
	_sfx_bank["rage_r_expire"] = [
		{"s": "08_rage_r_expire", "stream": s08, "file": "08_rage_r_expire.wav", "vol": -1.0, "pitch": 1.0, "bus": BUS_NORMAL, "group": "STATE", "choke": true}
	]

	# 9. Đòn U1 NỘ: Đại kiếm Huyết Lam chém ngang xé toạc không gian
	_sfx_bank["u1_rage"] = [
		{"s": "09_u1_rage_crimson", "stream": s09, "file": "09_u1_rage_crimson.wav", "vol": 1.6, "pitch": 1.0, "bus": BUS_RAGE, "group": "SWING", "choke": true}
	]

	# 10. Đòn U2 NỘ: Đại kiếm chém ngược cuồng bạo, sấm sét rền vang
	_sfx_bank["u2_rage"] = [
		{"s": "10_u2_rage_cobalt", "stream": s10, "file": "10_u2_rage_cobalt.wav", "vol": 1.6, "pitch": 1.0, "bus": BUS_RAGE, "group": "SWING", "choke": true}
	]

	# 11. Đòn U3 NỘ: "Huyết Lam Long Thần Giáng" (5 Đại Kiếm bổ trời, Lửa ngục & Địa chấn 1.18s)
	_sfx_bank["u3_rage_dragon_fall"] = [
		{"s": "11_u3_rage_dragon_fall", "stream": s11, "file": "11_u3_rage_dragon_fall.wav", "vol": 2.6, "pitch": 1.0, "bus": BUS_RAGE, "group": "SWING", "choke": true}
	]

	# 12. Chiêu [I] Pha 1 NỘ: Lục Kiếm Khí Chữ X chém đứt hư không
	_sfx_bank["i_rage_hexa_cleave"] = [
		{"s": "12_i_rage_hexa_cleave", "stream": s12, "file": "12_i_rage_hexa_cleave.wav", "vol": 1.8, "pitch": 1.0, "bus": BUS_RAGE, "group": "SWING", "choke": true}
	]

	# 13. Chiêu [I] Pha 2 NỘ: Ngũ Dực Đại Sóng Kiếm càn quét sàn đá (0.98s)
	_sfx_bank["i_rage_five_wing_wave"] = [
		{"s": "13_i_rage_five_wing_wave", "stream": s13, "file": "13_i_rage_five_wing_wave.wav", "vol": 2.2, "pitch": 1.0, "bus": BUS_RAGE, "group": "SWING", "choke": false}
	]

	# --- PHẦN III: KỸ NĂNG VŨ KHÍ, DI CHUYỂN & VA CHẠM THỰC TẾ ---
	# 14. Chiêu [O] / Q: Lốc Xoáy Kiếm 360° (3 nhịp vung kiếm xoay tròn)
	_sfx_bank["o_whirlwind_spin"] = [
		{"s": "14_o_whirlwind_spin", "stream": s14, "file": "14_o_whirlwind_spin.wav", "vol": 1.2, "pitch": 1.0, "bus": BUS_NORMAL, "group": "SWING", "choke": true}
	]

	# 15. Chiêu [P] / E: Ném bom lôi vụ
	_sfx_bank["p_bomb_throw"] = [
		{"s": "15_p_bomb_throw", "stream": s15, "file": "15_p_bomb_throw.wav", "vol": -0.5, "pitch": 1.0, "bus": BUS_NORMAL, "group": "MOVEMENT", "choke": true}
	]

	# 16. Chiêu [P] / E: Bom sấm sét phát nổ nứt đất
	_sfx_bank["p_bomb_thunder_explode"] = [
		{"s": "16_p_bomb_thunder_explode", "stream": s16, "file": "16_p_bomb_thunder_explode.wav", "vol": 2.2, "pitch": 1.0, "bus": BUS_IMPACT, "group": "IMPACT", "choke": true}
	]

	# 17. Chiêu [P] / E: Nhịp giật sét DoT trong khói
	_sfx_bank["p_bomb_dot_zap"] = [
		{"s": "17_p_bomb_dot_zap", "stream": s17, "file": "17_p_bomb_dot_zap.wav", "vol": -12.0, "pitch": 1.0, "bus": BUS_NORMAL, "group": "FOOTSTEP", "choke": true}
	]

	# 18. Phím [Space] Lướt Né
	_sfx_bank["dash_space"] = [
		{"s": "18_dash_space", "stream": s18, "file": "18_dash_space.wav", "vol": -0.5, "pitch": 1.0, "bus": BUS_NORMAL, "group": "MOVEMENT", "choke": true}
	]

	# 19. Phím [C] Nhảy
	_sfx_bank["jump_c"] = [
		{"s": "19_jump_c", "stream": s19, "file": "19_jump_c.wav", "vol": -1.0, "pitch": 1.0, "bus": BUS_NORMAL, "group": "MOVEMENT", "choke": true}
	]

	# 20. Bước chân trên nền đá (Luân phiên 2 file footstep stone)
	_sfx_bank["footstep_stone"] = [
		{"s": "20_footstep_stone_1", "stream": s20, "file": "20_footstep_stone_1.wav", "vol": -10.0, "pitch": 1.0, "bus": BUS_NORMAL, "group": "FOOTSTEP", "choke": true}
	]

	# 21. Chém trúng quái: Lưỡi kiếm cắt qua giáp kim loại đanh thép (Luân phiên 2 nhịp)
	_sfx_bank["hit_enemy_flesh_metal"] = [
		{"s": "22_hit_enemy_cleave_1", "stream": s22, "file": "22_hit_enemy_cleave_1.wav", "vol": 1.2, "pitch": 1.0, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# 22. Quái vật tử trận: Bùng nổ giáp sắt đổ gục
	_sfx_bank["enemy_death_burst"] = [
		{"s": "24_enemy_death_burst", "stream": s24, "file": "24_enemy_death_burst.wav", "vol": 1.5, "pitch": 1.0, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# 23. BGM Entry
	_sfx_bank["bgm_arena_combat_loop"] = [
		{"s": "25_bgm_arena_combat_loop", "stream": s25, "file": "25_bgm_arena_combat_loop.wav", "vol": 0.0, "pitch": 1.0, "bus": BUS_AURA, "group": "STATE", "choke": false}
	]

	print("🗡️ [KayKitAudioDirector] Directive 32 Master Audio Bank active (%d unique master streams, %d skill events, 1-to-1 unique mapping)." % [_raw_streams.size(), _sfx_bank.size()])

static func get_stream(sfx_id: String) -> AudioStream:
	ensure_initialized()
	if _sfx_bank.has(sfx_id):
		var layers: Array = _sfx_bank[sfx_id]
		if layers.size() > 0:
			var lay: Dictionary = layers[0]
			if lay.has("stream") and lay["stream"] != null:
				return lay["stream"]
			var s_key: String = lay.get("s", "")
			if _raw_streams.has(s_key):
				return _raw_streams[s_key]
	if _raw_streams.has(sfx_id):
		return _raw_streams[sfx_id]
	return null

# ==============================================================================
# 3. BỘ PHÁT ÂM THANH KHÔNG CẮT CỤT ĐUÔI (NGÂN VANG TỰ NHIÊN TRỌN VẸN 0.7S - 1.2S)
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
	var jitter_pitch := pitch_override if pitch_override > 0.0 else randf_range(0.985, 1.015)

	for layer in layers:
		var stream: AudioStream = layer.get("stream", null)
		var stream_key: String = layer.get("s", "")

		# Luân phiên đa mẫu (Round-robin) cho bước chân và chém trúng quái
		if sfx_id == "footstep_stone":
			var steps := ["20_footstep_stone_1", "21_footstep_stone_2"]
			stream_key = steps[play_count % steps.size()]
			stream = _raw_streams.get(stream_key, stream)
		elif sfx_id == "hit_enemy_flesh_metal":
			var hits := ["22_hit_enemy_cleave_1", "23_hit_enemy_cleave_2"]
			stream_key = hits[play_count % hits.size()]
			stream = _raw_streams.get(stream_key, stream)
		elif stream == null and stream_key != "":
			stream = _raw_streams.get(stream_key, null)

		if stream == null:
			continue

		var base_vol: float = float(layer.get("vol", 0.0)) + volume_offset_db
		var base_pitch: float = float(layer.get("pitch", 1.0)) * jitter_pitch
		var delay_sec: float = float(layer.get("delay", 0.0))
		var target_bus: String = str(layer.get("bus", BUS_NORMAL))
		var group_name: String = str(layer.get("group", "SWING"))
		var should_choke: bool = bool(layer.get("choke", false))

		if delay_sec <= 0.001 or not is_inside_tree():
			_trigger_controlled_layer(stream, base_vol, base_pitch, target_bus, group_name, should_choke)
		else:
			var tw := create_tween()
			tw.tween_interval(delay_sec)
			tw.tween_callback(func():
				_trigger_controlled_layer(stream, base_vol, base_pitch, target_bus, group_name, should_choke)
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
		# BỎ HOÀN TOÀN ĐOẠN TWEEN CẮT CỤT ĐUÔI!
		# Các file Master Stereo .wav ngân vang trọn vẹn theo độ dài tự nhiên của file (0.32s - 1.2s)!
