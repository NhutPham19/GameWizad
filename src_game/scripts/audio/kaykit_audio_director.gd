class_name KayKitAudioDirector
extends Node

# ==============================================================================
# KAYKIT AUDIO DIRECTOR - HỆ THỐNG ÂM THANH TOÀN DIỆN (DIRECTIVE 27)
# 100% PRE-BAKED 44.1KHZ PCM VÀO RAM KHI KHỞI ĐỘNG (0MS LAG Ở 165HZ+)
# AUDIO POOL 24 KÊNH ĐA LUỒNG + POLYPHONIC VOICE LIMITER + AMBIENT BGM
# ==============================================================================

static var _instance: KayKitAudioDirector = null
static var _sfx_bank: Dictionary = {}
static var _is_prebaked: bool = false
static var _is_adding: bool = false

var players: Array[AudioStreamPlayer] = []
var max_players: int = 24
var current_player_idx: int = 0
var bgm_player: AudioStreamPlayer = null

var play_count: int = 0
var play_counts: Dictionary = {}
var _last_play_time: Dictionary = {}

const MIN_RETRIGGER_DELAY: float = 0.035

func _init() -> void:
	if _instance == null:
		_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_prebake_audio_bank()

func _ready() -> void:
	_is_adding = false
	_init_audio_pool()

func _init_audio_pool() -> void:
	if players.size() == 0:
		for i in range(max_players):
			var p := AudioStreamPlayer.new()
			p.name = "AudioPoolChannel_%d" % i
			p.bus = "Master"
			add_child(p)
			players.append(p)

	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer_CombatLoop"
		bgm_player.bus = "Master"
		bgm_player.volume_db = -14.0
		add_child(bgm_player)
		if _sfx_bank.has("bgm_arena_combat_loop"):
			bgm_player.stream = _sfx_bank["bgm_arena_combat_loop"]
			bgm_player.play()

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
				tree.root.call_deferred("add_child", _instance)
	elif not _instance.is_inside_tree() and not _is_adding:
		if tree == null:
			tree = Engine.get_main_loop() as SceneTree
		if tree and tree.root and _instance.get_parent() == null:
			_is_adding = true
			tree.root.call_deferred("add_child", _instance)

	if not _is_prebaked and _instance:
		_instance._prebake_audio_bank()
	return _instance

static func play_sfx(sfx_id: String, volume_offset_db: float = 0.0, pitch_override: float = 0.0) -> void:
	var inst := ensure_initialized()
	if inst:
		inst._play_internal(sfx_id, volume_offset_db, pitch_override)

static func start_bgm() -> void:
	var inst := ensure_initialized()
	if inst and inst.bgm_player:
		if not inst.bgm_player.playing and _sfx_bank.has("bgm_arena_combat_loop"):
			inst.bgm_player.stream = _sfx_bank["bgm_arena_combat_loop"]
			inst.bgm_player.play()

static func set_rage_bgm_mode(is_rage: bool) -> void:
	var inst := ensure_initialized()
	if inst and inst.bgm_player:
		if is_rage:
			inst.bgm_player.pitch_scale = 1.08
			inst.bgm_player.volume_db = -11.0
		else:
			inst.bgm_player.pitch_scale = 1.00
			inst.bgm_player.volume_db = -14.0

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

	var stream: AudioStream = _sfx_bank[sfx_id]
	var player := players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % max_players

	player.stream = stream
	player.volume_db = volume_offset_db
	if pitch_override > 0.0:
		player.pitch_scale = pitch_override
	else:
		player.pitch_scale = randf_range(0.95, 1.06)

	player.play()
	play_count += 1
	play_counts[sfx_id] = int(play_counts.get(sfx_id, 0)) + 1

# ==============================================================================
# BỘ TỔNG HỢP ÂM THANH ĐA TẦNG PHÒNG THU (44.1KHZ PCM PRE-BAKE)
# ==============================================================================

func _prebake_audio_bank() -> void:
	if _is_prebaked:
		return
	_is_prebaked = true

	# Nạp các file .wav thực tế nếu có sẵn
	var existing_wavs := {
		"slash": "res://assets/audio/slash.wav",
		"dash": "res://assets/audio/dash.wav",
		"hit": "res://assets/audio/hit.wav",
	}
	var loaded_wavs: Dictionary = {}
	for k in existing_wavs:
		var p: String = existing_wavs[k]
		if ResourceLoader.exists(p):
			var w = load(p) as AudioStream
			if w:
				loaded_wavs[k] = w

	# 1. "u1_slash": Vung kiếm nhịp 1 sắc gọn
	_sfx_bank["u1_slash"] = _synth_slash(720.0, 240.0, 0.14, 0.85)

	# 2. "u2_slash": Vung kiếm nhịp 2 chém chéo 2 nhịp
	_sfx_bank["u2_slash"] = _synth_dual_slash(820.0, 280.0, 0.18, 0.90)

	# 3. "u3_heaven_shatter": Đại kiếm giáng trần 55Hz Sub-Bass + chuông ngân hoàng kim
	_sfx_bank["u3_heaven_shatter"] = _synth_impact_blast(55.0, 950.0, 0.45, 1.15)

	# 4. "u1_rage": Nhát chém Nộ 1 - Nặng và có tia điện
	_sfx_bank["u1_rage"] = _synth_rage_slash(540.0, 160.0, 0.16, 1.05)

	# 5. "u2_rage": Nhát chém Nộ 2 - Song kiếm Nộ điện quang
	_sfx_bank["u2_rage"] = _synth_rage_slash(620.0, 180.0, 0.20, 1.10)

	# 6. "u3_rage_dragon_fall": Ngũ Đại Kiếm Khí Nộ - Địa chấn kép rền vang 0.65s
	_sfx_bank["u3_rage_dragon_fall"] = _synth_dragon_fall_roar(48.0, 0.65, 1.25)

	# 7. "i_phase1_x_cleave": Chém chữ X lướt nhanh + kim loại ngân
	_sfx_bank["i_phase1_x_cleave"] = _synth_metallic_cross(1150.0, 0.24, 0.95)

	# 8. "i_phase2_wave_launch": Phóng sóng kiếm năng lượng càn quét
	_sfx_bank["i_phase2_wave_launch"] = _synth_wave_launch(180.0, 520.0, 0.28, 0.95)

	# 9. "i_wave_finale": Đại Tinh Vân nổ bùng cuối đường sóng
	_sfx_bank["i_wave_finale"] = _synth_supernova_burst(65.0, 0.38, 1.10)

	# 10. "i_rage_hexa_cleave": Lục Kiếm Khí Chữ X Nộ - Kim loại nặng & sấm sét
	_sfx_bank["i_rage_hexa_cleave"] = _synth_metallic_cross(880.0, 0.32, 1.20)

	# 11. "i_rage_five_wing_wave": Sóng Kiếm Ngũ Dực Nộ 5 Cánh - Tiếng gầm năng lượng
	_sfx_bank["i_rage_five_wing_wave"] = _synth_rage_wave_roar(60.0, 0.36, 1.20)

	# 12. "o_whirlwind_spin": Lốc xoáy 360 độ liên hoàn 4 nhịp
	_sfx_bank["o_whirlwind_spin"] = _synth_whirlwind(0.48, 1.0)

	# 13. "p_bomb_throw": Ném bom vút gió
	_sfx_bank["p_bomb_throw"] = _synth_whoosh(280.0, 560.0, 0.16, 0.75)

	# 14. "p_bomb_thunder_explode": Bom nổ lôi vụ sấm sét đanh thép
	_sfx_bank["p_bomb_thunder_explode"] = _synth_thunder_explosion(0.42, 1.15)

	# 15. "p_bomb_dot_zap": Giật điện DoT lách tách
	_sfx_bank["p_bomb_dot_zap"] = _synth_electric_zap(0.08, 0.65)

	# 16. "rage_r_awaken": Long Thần Thức Tỉnh Kích Hoạt Nộ hoành tráng
	_sfx_bank["rage_r_awaken"] = _synth_awaken_roar(0.72, 1.30)

	# 17. "rage_r_expire": Năng lượng Nộ thu hồi êm ái
	_sfx_bank["rage_r_expire"] = _synth_whoosh(480.0, 110.0, 0.32, 0.70)

	# 18. "dash_space": Lướt né đòn Space
	if loaded_wavs.has("dash"):
		_sfx_bank["dash_space"] = loaded_wavs["dash"]
	else:
		_sfx_bank["dash_space"] = _synth_whoosh(600.0, 200.0, 0.18, 0.85)

	# 19. "jump_c": Bật nhảy cao
	_sfx_bank["jump_c"] = _synth_tone_rise(160.0, 360.0, 0.15, 0.80)

	# 20. "footstep_stone": Bước chân giẫm trên đá
	_sfx_bank["footstep_stone"] = _synth_footstep(0.06, 0.45)

	# 21. "hit_enemy_flesh_metal": Chém trúng mục tiêu đầm tay
	if loaded_wavs.has("hit"):
		_sfx_bank["hit_enemy_flesh_metal"] = loaded_wavs["hit"]
	else:
		_sfx_bank["hit_enemy_flesh_metal"] = _synth_hit_impact(0.12, 0.95)

	# 22. "enemy_death_burst": Quái vật bị tiêu diệt
	_sfx_bank["enemy_death_burst"] = _synth_death_pop(0.32, 0.90)

	# 23. "bgm_arena_combat_loop": Nhạc nền nhịp trống chiến trận 44.1kHz loop 4.0s
	_sfx_bank["bgm_arena_combat_loop"] = _synth_battle_pulse_loop(4.0)

	print("🎵 [KayKitAudioDirector] Pre-baked %d studio-grade SFX & BGM into RAM (44.1kHz 16-bit PCM, 0ms lag)." % _sfx_bank.size())

# ==============================================================================
# THUẬT TOÁN TẠO MẪU SÓNG ÂM THANH NGUYÊN BẢN (44,100 HZ, 16-BIT PCM MONO)
# ==============================================================================

func _create_wav(byte_data: PackedByteArray, loop: bool = false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 44100
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

func _synth_slash(f_start: float, f_end: float, dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env := sin(prog * PI) * exp(-prog * 2.8)
		var freq := lerpf(f_start, f_end, prog * prog)
		var s := sin(TAU * freq * t) * 0.65 + randf_range(-0.35, 0.35)
		var val := int(clampf(s * env * gain, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_dual_slash(f_start: float, f_end: float, dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var split := int(n * 0.42)
	for i in range(n):
		var t := float(i) / float(sr)
		var env: float
		var freq: float
		if i < split:
			var p1 := float(i) / float(split)
			env = sin(p1 * PI)
			freq = lerpf(f_start, f_end, p1)
		else:
			var p2 := float(i - split) / float(n - split)
			env = sin(p2 * PI) * 1.15
			freq = lerpf(f_start * 1.15, f_end * 0.9, p2)
		var s := sin(TAU * freq * t) * 0.6 + randf_range(-0.4, 0.4)
		var val := int(clampf(s * env * gain, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_impact_blast(f_sub: float, f_chime: float, dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env_sub := exp(-prog * 6.5)
		var env_chime := exp(-prog * 4.0)
		var sub := sin(TAU * f_sub * t) * env_sub * 0.75
		var chime := (sin(TAU * f_chime * t) + sin(TAU * f_chime * 1.5 * t) * 0.5) * env_chime * 0.35
		var noise := randf_range(-0.3, 0.3) * exp(-prog * 12.0)
		var s := (sub + chime + noise) * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_rage_slash(f_start: float, f_end: float, dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env := sin(prog * PI) * exp(-prog * 2.2)
		var freq := lerpf(f_start, f_end, prog)
		var sub := sin(TAU * 75.0 * t) * 0.35
		var body := sin(TAU * freq * t) * 0.45
		var spark := (randf_range(-1.0, 1.0) if (i % 3 == 0) else 0.0) * 0.4
		var s := (sub + body + spark) * env * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_dragon_fall_roar(f_sub: float, dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env := exp(-prog * 4.2)
		var sub := sin(TAU * f_sub * t + sin(TAU * 12.0 * t) * 0.5) * 0.65
		var mid := sin(TAU * (140.0 - prog * 60.0) * t) * 0.35
		var crackle := randf_range(-0.35, 0.35) * exp(-prog * 8.0)
		var s := (sub + mid + crackle) * env * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_metallic_cross(f_ping: float, dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env_metal := exp(-prog * 7.5)
		var whoosh := randf_range(-0.4, 0.4) * sin(prog * PI) * 0.5
		var ping := (sin(TAU * f_ping * t) + sin(TAU * f_ping * 1.62 * t) * 0.6) * env_metal * 0.65
		var s := (whoosh + ping) * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_wave_launch(f_start: float, f_end: float, dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env := sin(prog * PI) * (1.0 - prog * 0.4)
		var freq := lerpf(f_start, f_end, prog)
		var sweep := sin(TAU * freq * t) * 0.6
		var air := randf_range(-0.35, 0.35) * 0.4
		var s := (sweep + air) * env * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_supernova_burst(f_sub: float, dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env := exp(-prog * 5.5)
		var sub := sin(TAU * f_sub * t) * 0.6
		var noise := randf_range(-0.5, 0.5) * exp(-prog * 10.0)
		var sparkle := sin(TAU * 1600.0 * t) * exp(-prog * 14.0) * 0.3
		var s := (sub + noise + sparkle) * env * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_rage_wave_roar(f_sub: float, dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env := sin(prog * PI) * exp(-prog * 1.8)
		var sub := sin(TAU * f_sub * t) * 0.55
		var sweep := sin(TAU * (220.0 + sin(TAU * 18.0 * t) * 60.0) * t) * 0.45
		var s := (sub + sweep) * env * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_whirlwind(dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var mod := (sin(TAU * 7.5 * t) * 0.4 + 0.6)
		var env := sin(prog * PI)
		var whoosh := randf_range(-0.55, 0.55) * mod
		var s := whoosh * env * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_whoosh(f_start: float, f_end: float, dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var env := sin(prog * PI)
		var noise := randf_range(-0.6, 0.6)
		var val := int(clampf(noise * env * gain, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_thunder_explosion(dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env := exp(-prog * 6.0)
		var boom := sin(TAU * 52.0 * t) * 0.6
		var crack := randf_range(-0.6, 0.6) * exp(-prog * 15.0)
		var s := (boom + crack) * env * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_electric_zap(dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env := exp(-prog * 16.0)
		var zap := (fmod(420.0 * t, 1.0) * 2.0 - 1.0) * 0.7 + randf_range(-0.3, 0.3)
		var s := zap * env * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_awaken_roar(dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var s := 0.0
		if prog < 0.22:
			var p1 := prog / 0.22
			s = sin(TAU * lerpf(60.0, 190.0, p1) * t) * p1 * 0.5
		else:
			var p2 := (prog - 0.22) / 0.78
			var env := exp(-p2 * 4.5)
			var sub := sin(TAU * 48.0 * t) * 0.6
			var blast := randf_range(-0.5, 0.5) * exp(-p2 * 9.0)
			var horn := (sin(TAU * 165.0 * t) + sin(TAU * 330.0 * t) * 0.4) * 0.45
			s = (sub + blast + horn) * env
		var val := int(clampf(s * gain, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_tone_rise(f_start: float, f_end: float, dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env := sin(prog * PI)
		var freq := lerpf(f_start, f_end, prog)
		var s := sin(TAU * freq * t) * env * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_footstep(dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env := exp(-prog * 18.0)
		var thud := sin(TAU * 110.0 * t) * 0.65
		var click := randf_range(-0.4, 0.4) * exp(-prog * 25.0)
		var s := (thud + click) * env * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_hit_impact(dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env := exp(-prog * 14.0)
		var punch := sin(TAU * 125.0 * t) * 0.7
		var slap := randf_range(-0.5, 0.5) * exp(-prog * 20.0)
		var s := (punch + slap) * env * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_death_pop(dur: float, gain: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var prog := float(i) / float(n)
		var t := float(i) / float(sr)
		var env := exp(-prog * 6.0)
		var s := (sin(TAU * lerpf(240.0, 70.0, prog) * t) * 0.6 + randf_range(-0.3, 0.3)) * env * gain
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes)

func _synth_battle_pulse_loop(dur: float) -> AudioStreamWAV:
	var sr := 44100
	var n := int(dur * float(sr))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var bpm := 128.0
	var beat_interval := 60.0 / bpm
	for i in range(n):
		var t := float(i) / float(sr)
		var beat_time := fmod(t, beat_interval)
		var beat_prog := beat_time / beat_interval
		var env_drum := exp(-beat_prog * 12.0)
		var drum := sin(TAU * 65.0 * beat_time) * env_drum * 0.45
		var hat_time := fmod(t, beat_interval * 0.5)
		var hat := randf_range(-0.15, 0.15) * exp(-(hat_time / (beat_interval * 0.5)) * 18.0) * 0.25
		var chord := (sin(TAU * 220.0 * t) + sin(TAU * 261.63 * t) + sin(TAU * 329.63 * t)) * 0.08
		var s := (drum + hat + chord) * 0.65
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val)
	return _create_wav(bytes, true)
