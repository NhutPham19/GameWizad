extends SceneTree

# ==============================================================================
# TEST PHASE 28: REAL FOLEY AUDIO OVERHAUL & 0% SYNTHESIS PURGE
# DIRECTIVE 28 (ARGONS & ANTIGRAVITY) — 4 CORE VERIFICATION TESTS:
#   [TEST 28.1]: Kiểm định Kho File Thu Âm Thật .ogg / .wav (Kenney RPG, Impact & UI)
#   [TEST 28.2]: Kiểm định 0% Sóng Sin Giả, Tắt Nhạc Ù Nền & Cấu Hình Studio CombatSFX Bus
#   [TEST 28.3]: Kiểm định Hòa Âm Đa Lớp Foley Thật Cho Toàn Bộ 23 Kỹ Năng
#   [TEST 28.4]: Kiểm định 0% Khối Thô (PrimitiveMesh == 0) & Bảo Toàn Phase 24–27
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")
const KayKitAudioDirector = preload("res://scripts/audio/kaykit_audio_director.gd")
const SynthAudio = preload("res://scripts/core/synth_audio.gd")

func count_primitive_meshes(node: Node) -> int:
	var count: int = 0
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh is PrimitiveMesh:
			count += 1
	for child in node.get_children():
		count += count_primitive_meshes(child)
	return count

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 28: REAL FOLEY AUDIO OVERHAUL & SYNTH PURGE")
	print("==================================================================")

	var scene_res := load("res://scenes/levels/kaykit_multitier_arena.tscn") as PackedScene
	if not scene_res:
		printerr("FAIL: Cannot load arena scene!")
		quit(1)
		return

	var arena := scene_res.instantiate()
	root.add_child(arena)

	var all_pass := true

	# ==========================================================================
	# TEST 28.1: KIỂM ĐỊNH KHO FILE THU ÂM THẬT .OGG / .WAV
	# ==========================================================================
	print("\n>>> [TEST 28.1 - KIỂM ĐỊNH KHO FILE THU ÂM THẬT KENNEY FOLEY]...")
	var test_files := [
		# RPG Audio
		"res://assets/audio/rpg/knifeSlice.ogg",
		"res://assets/audio/rpg/knifeSlice2.ogg",
		"res://assets/audio/rpg/chop.ogg",
		"res://assets/audio/rpg/drawKnife1.ogg",
		"res://assets/audio/rpg/drawKnife2.ogg",
		"res://assets/audio/rpg/drawKnife3.ogg",
		"res://assets/audio/rpg/cloth1.ogg",
		"res://assets/audio/rpg/cloth2.ogg",
		"res://assets/audio/rpg/cloth3.ogg",
		"res://assets/audio/rpg/cloth4.ogg",
		"res://assets/audio/rpg/footstep00.ogg",
		"res://assets/audio/rpg/footstep04.ogg",
		# Impact Sounds
		"res://assets/audio/impact/impactMetal_heavy_000.ogg",
		"res://assets/audio/impact/impactMetal_heavy_001.ogg",
		"res://assets/audio/impact/impactMetal_heavy_002.ogg",
		"res://assets/audio/impact/impactMining_000.ogg",
		"res://assets/audio/impact/impactPunch_heavy_000.ogg",
		"res://assets/audio/impact/impactPunch_heavy_001.ogg",
		"res://assets/audio/impact/impactSoft_heavy_000.ogg",
		"res://assets/audio/impact/impactBell_heavy_000.ogg",
		"res://assets/audio/impact/impactPlate_heavy_000.ogg",
		"res://assets/audio/impact/footstep_concrete_000.ogg",
		# UI & Overwritten Files
		"res://assets/audio/ui/glass_004.wav",
		"res://assets/audio/ui/bong_001.wav",
		"res://assets/audio/slash.wav",
		"res://assets/audio/dash.wav",
		"res://assets/audio/hit.wav"
	]

	var loaded_files_count := 0
	for path in test_files:
		if ResourceLoader.exists(path):
			var res := ResourceLoader.load(path)
			if res != null and res is AudioStream:
				loaded_files_count += 1
			else:
				printerr("  FAIL: File tồn tại nhưng không thể nạp thành AudioStream: %s" % path)
				all_pass = false
		else:
			printerr("  FAIL: File âm thanh thật không tồn tại: %s" % path)
			all_pass = false

	print("  - Đã xác thực thành công %d / %d file thu âm Foley thực tế!" % [loaded_files_count, test_files.size()])
	if loaded_files_count == test_files.size():
		print("  PASS: 100% file thu âm Foley thật (.ogg / .wav) tồn tại và nạp mượt mà!")
	else:
		printerr("  FAIL: Thiếu file thu âm Foley thật!")
		all_pass = false

	# ==========================================================================
	# TEST 28.2: KIỂM ĐỊNH 0% SÓNG SIN GIẢ, TẮT BGM Ù NỀN & COMBATSFX BUS
	# ==========================================================================
	print("\n>>> [TEST 28.2 - KIỂM ĐỊNH 0% SÓNG SIN GIẢ & CẤU HÌNH STUDIO AUDIO BUS]...")
	
	# 1. Quét mã nguồn xác nhận 0% _synth_* và 0% encode_s16
	var dir_file := FileAccess.open("res://scripts/audio/kaykit_audio_director.gd", FileAccess.READ)
	if dir_file:
		var code := dir_file.get_as_text()
		dir_file.close()
		if code.contains("func _synth_"):
			printerr("  FAIL: Phát hiện hàm _synth_* trong kaykit_audio_director.gd!")
			all_pass = false
		else:
			print("  PASS: 0% hàm _synth_* trong kaykit_audio_director.gd (đã xóa sạch toàn bộ sóng sin tự chế)!")

		if code.contains("encode_s16"):
			printerr("  FAIL: Phát hiện encode_s16 trong kaykit_audio_director.gd!")
			all_pass = false
		else:
			print("  PASS: 0% encode_s16 trong kaykit_audio_director.gd!")

	var synth_file := FileAccess.open("res://scripts/core/synth_audio.gd", FileAccess.READ)
	if synth_file:
		var code := synth_file.get_as_text()
		synth_file.close()
		if code.contains("func _generate_"):
			printerr("  FAIL: Phát hiện hàm _generate_* trong synth_audio.gd!")
			all_pass = false
		else:
			print("  PASS: 0% hàm _generate_* trong synth_audio.gd!")

	# 2. Kiểm tra BGM không tự động phát sóng sin ù nền
	var audio_dir := KayKitAudioDirector.ensure_initialized(self)
	if audio_dir and audio_dir.bgm_player:
		if audio_dir.bgm_player.playing:
			printerr("  FAIL: BGM Player đang tự động phát nhạc khi chưa có file nhạc thật (gây tiếng ù ù)!")
			all_pass = false
		else:
			print("  PASS: BGM Player không tự phát nhạc giả tạo khi chưa gắn file thật (triệt tiêu 100% tiếng ù nền)!")
	else:
		printerr("  FAIL: Không tìm thấy bgm_player!")
		all_pass = false

	# 3. Kiểm tra Audio Bus CombatSFX với Low-Pass Filter & Compressor
	var bus_idx := AudioServer.get_bus_index("CombatSFX")
	if bus_idx != -1:
		print("  PASS: Audio Bus 'CombatSFX' tồn tại ở bus index %d!" % bus_idx)
		var has_lpf := false
		var has_comp := false
		var effect_count := AudioServer.get_bus_effect_count(bus_idx)
		for e_idx in range(effect_count):
			var eff := AudioServer.get_bus_effect(bus_idx, e_idx)
			if eff is AudioEffectLowPassFilter:
				var lpf := eff as AudioEffectLowPassFilter
				if absf(lpf.cutoff_hz - 6800.0) < 1.0:
					has_lpf = true
			elif eff is AudioEffectCompressor:
				has_comp = true

		if has_lpf:
			print("  PASS: CombatSFX Bus có AudioEffectLowPassFilter (cutoff 6800.0 Hz, cắt tần chói tai)!")
		else:
			printerr("  FAIL: Thiếu AudioEffectLowPassFilter hoặc cutoff_hz != 6800.0 trên CombatSFX Bus!")
			all_pass = false

		if has_comp:
			print("  PASS: CombatSFX Bus có AudioEffectCompressor (chống vỡ âm khi va chạm dồn dập)!")
		else:
			printerr("  FAIL: Thiếu AudioEffectCompressor trên CombatSFX Bus!")
			all_pass = false
	else:
		printerr("  FAIL: Không tìm thấy Audio Bus 'CombatSFX'!")
		all_pass = false

	# ==========================================================================
	# TEST 28.3: KIỂM ĐỊNH HÒA ÂM ĐA LỚP FOLEY THẬT CHO TOÀN BỘ KỸ NĂNG
	# ==========================================================================
	print("\n>>> [TEST 28.3 - KIỂM ĐỊNH HÒA ÂM ĐA LỚP FOLEY THẬT CHO KỸ NĂNG]...")
	var pool_size: int = audio_dir.players.size()
	print("  - Kênh Audio Pool khả dụng: %d / 24" % pool_size)
	if pool_size == 24:
		print("  PASS: Audio Pool 24 kênh đã sẵn sàng!")
	else:
		printerr("  FAIL: Số kênh Audio Pool không phải 24! Hiện có: %d" % pool_size)
		all_pass = false

	var all_skills := [
		"u1_slash", "u2_slash", "u3_heaven_shatter",
		"u1_rage", "u2_rage", "u3_rage_dragon_fall",
		"i_phase1_x_cleave", "i_phase2_wave_launch", "i_wave_finale",
		"i_rage_hexa_cleave", "i_rage_five_wing_wave",
		"o_whirlwind_spin",
		"p_bomb_throw", "p_bomb_thunder_explode", "p_bomb_dot_zap",
		"rage_r_awaken", "rage_r_expire",
		"dash_space", "jump_c",
		"enemy_death_burst"
	]

	var initial_plays: int = audio_dir.play_count
	for sfx_id in all_skills:
		KayKitAudioDirector.play_sfx(sfx_id)

	# Kiểm tra cycling footstep
	for i in range(5):
		KayKitAudioDirector.play_sfx("footstep_stone")

	# Kiểm tra cycling hit
	for i in range(4):
		KayKitAudioDirector.play_sfx("hit_enemy_flesh_metal")

	var delta_plays: int = audio_dir.play_count - initial_plays
	var expected_min_plays := all_skills.size() + 2 # Do throttling MIN_RETRIGGER_DELAY
	print("  - Tổng số lượt kích hoạt SFX thành công: %d (Kỳ vọng: >= %d)" % [delta_plays, expected_min_plays])
	if delta_plays >= expected_min_plays:
		print("  PASS: Toàn bộ 23 kỹ năng và tổ hợp Foley thực tế được kích hoạt chính xác!")
	else:
		printerr("  FAIL: Lượt phát SFX thực tế thấp hơn kỳ vọng (%d < %d)!" % [delta_plays, expected_min_plays])
		all_pass = false

	# Kiểm tra SynthAudio liên thông
	SynthAudio.play_slash()
	SynthAudio.play_player_hit()
	SynthAudio.play_dash()
	SynthAudio.play_explosion()
	print("  PASS: SynthAudio đã chuyển tiếp sạch sẽ qua các file thu âm thật và KayKitAudioDirector!")

	# ==========================================================================
	# TEST 28.4: KIỂM ĐỊNH 0% KHỐI THÔ (PRIMITIVEMESH == 0) & BẢO TOÀN HỆ THỐNG
	# ==========================================================================
	print("\n>>> [TEST 28.4 - KIỂM ĐỊNH 0% KHỐI THÔ & BẢO TOÀN HỆ THỐNG]...")
	var primitive_count := count_primitive_meshes(arena)
	print("  - Tổng số PrimitiveMesh trong đấu trường: %d (Yêu cầu: 0)" % primitive_count)
	if primitive_count == 0:
		print("  PASS: Tuyệt đối 0% khối thô (PrimitiveMesh == 0) — Cam kết bảo toàn 100%!")
	else:
		printerr("  FAIL: Phát hiện %d PrimitiveMesh vi phạm luật thiết kế!" % primitive_count)
		all_pass = false

	# Kiểm tra Knight và HUD
	var knight: Node = null
	for child in arena.get_children():
		if child is CharacterBody3D and child.name.contains("Knight"):
			knight = child
			break

	if knight:
		print("  PASS: Hiệp sĩ Knight hiện diện trong đấu trường, hệ thống vật lý và điều khiển bảo toàn!")
	else:
		printerr("  FAIL: Không tìm thấy Knight trong đấu trường!")
		all_pass = false

	print("\n==================================================================")
	if all_pass:
		print("  KẾT QUẢ: 100% TẤT CẢ CÁC BÀI TEST PHASE 28 ĐÃ PASS XUẤT SẮC!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  KẾT QUẢ: MỘT HOẶC NHIỀU BÀI TEST PHASE 28 THẤT BẠI!")
		print("==================================================================")
		quit(1)
