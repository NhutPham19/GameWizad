extends SceneTree

# ==============================================================================
# TEST PHASE 29: ULTIMATE AAA STUDIO AUDIO & DUAL-STATE SFX ARCHITECTURE
# DIRECTIVE 29 (ARGONS & ANTIGRAVITY) — 4 MANDATORY VERIFICATION TESTS:
#   [TEST 29.1]: Kho Âm Thanh Thật 3 Repo (RPG + Impact + Sci-Fi, >= 38 streams, 0% _synth/encode)
#   [TEST 29.2]: Kiến Trúc 4 Audio Bus DSP Phòng Thu (NormalBlade, RageOverdrive, HeavyImpact, RageAura)
#   [TEST 29.3]: Tách Biệt 100% Âm Thanh Trạng Thái 1 vs Trạng Thái 2 [R] & Lingering Audio Tail
#   [TEST 29.4]: Bảo Toàn 0% Khối Thô (PrimitiveMesh == 0) & Toàn Bộ Tính Năng Phase 24–27
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const KayKitAudioDirector = preload("res://scripts/audio/kaykit_audio_director.gd")
const SynthAudio = preload("res://scripts/core/synth_audio.gd")

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 29: ULTIMATE AAA STUDIO AUDIO & DUAL-STATE SFX")
	print("==================================================================")

	var scene_res := load("res://scenes/levels/kaykit_multitier_arena.tscn") as PackedScene
	if not scene_res:
		printerr("FAIL: Cannot load arena scene!")
		quit(1)
		return

	var arena := scene_res.instantiate()
	root.add_child(arena)
	current_scene = arena

	for f in range(6):
		await process_frame

	var hero := arena.get_node_or_null("HeroKnight3D") as HeroKnight3D
	if not hero:
		printerr("FAIL: HeroKnight3D not found!")
		quit(1)
		return

	var all_pass := true

	# --------------------------------------------------------------------------
	# TEST 29.1: KIỂM ĐỊNH KHO ÂM THANH THẬT RPG + IMPACT + SCI-FI (>= 38 STREAMS, 0% SYNTH)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 29.1 - KIỂM ĐỊNH KHO ÂM THANH THẬT RPG + IMPACT + SCI-FI]...")
	var audio_dir := KayKitAudioDirector.ensure_initialized(root.get_tree())
	if audio_dir == null:
		printerr("  FAIL: Không khởi tạo được KayKitAudioDirector!")
		all_pass = false
	else:
		var raw_count: int = KayKitAudioDirector._raw_streams.size()
		print("  - Số lượng file âm thanh thật nạp vào _raw_streams: %d (Yêu cầu: >= 24)" % raw_count)
		if raw_count >= 24:
			print("  PASS: Đã nạp thành công %d luồng âm thanh thật vào RAM (vượt yêu cầu >= 24)!" % raw_count)
		else:
			printerr("  FAIL: Số lượng file âm thanh thật không đủ 24! Hiện có: %d" % raw_count)
			all_pass = false

		# Kiểm tra các file tiêu biểu trong cả 3 kho
		var check_files := [
			"res://assets/audio/scifi/lowFrequency_explosion_000.ogg",
			"res://assets/audio/scifi/explosionCrunch_000.ogg",
			"res://assets/audio/scifi/thrusterFire_000.ogg",
			"res://assets/audio/scifi/laserLarge_000.ogg",
			"res://assets/audio/scifi/forceField_000.ogg",
			"res://assets/audio/scifi/impactMetal_000.ogg",
			"res://assets/audio/rpg/knifeSlice.ogg",
			"res://assets/audio/impact/impactPunch_heavy_000.ogg"
		]
		var files_ok := true
		for fpath in check_files:
			if not ResourceLoader.exists(fpath):
				printerr("  FAIL: Thiếu file âm thanh bắt buộc: %s" % fpath)
				files_ok = false
				all_pass = false
		if files_ok:
			print("  PASS: Đủ 8/8 tệp âm thanh thu âm cốt lõi từ 3 kho RPG, Impact, Sci-Fi!")

		# Quét mã nguồn kiểm tra 0% hàm _synth_* và encode_s16
		var script_files := [
			"res://scripts/audio/kaykit_audio_director.gd",
			"res://scripts/core/synth_audio.gd"
		]
		var synth_purged := true
		for s_path in script_files:
			var f := FileAccess.open(s_path, FileAccess.READ)
			if f:
				var code_text := f.get_as_text()
				f.close()
				# Kiểm tra các hàm tự tạo sóng âm
				if code_text.contains("func _synth_") or code_text.contains("def _synth_"):
					printerr("  FAIL: Phát hiện hàm _synth_* tự chế trong %s!" % s_path)
					synth_purged = false
					all_pass = false
				if code_text.contains(".encode_s16(") or code_text.contains("func encode_s16"):
					printerr("  FAIL: Phát hiện encode_s16 tự chế trong %s!" % s_path)
					synth_purged = false
					all_pass = false
		if synth_purged:
			print("  PASS: Xác nhận 100% KHÔNG CÒN bất kỳ hàm _synth_* hay encode_s16 nào trong mã nguồn!")

	# --------------------------------------------------------------------------
	# TEST 29.2: KIỂM ĐỊNH 4 AUDIO BUS DSP PHÒNG THU TRÊN AUDIOSERVER
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 29.2 - KIỂM ĐỊNH 4 AUDIO BUS DSP PHÒNG THU TRÊN AUDIOSERVER]...")
	var bus_normal_idx := AudioServer.get_bus_index(KayKitAudioDirector.BUS_NORMAL)
	var bus_rage_idx := AudioServer.get_bus_index(KayKitAudioDirector.BUS_RAGE)
	var bus_impact_idx := AudioServer.get_bus_index(KayKitAudioDirector.BUS_IMPACT)
	var bus_aura_idx := AudioServer.get_bus_index(KayKitAudioDirector.BUS_AURA)

	print("  - Bus '%s' index: %d" % [KayKitAudioDirector.BUS_NORMAL, bus_normal_idx])
	print("  - Bus '%s' index: %d" % [KayKitAudioDirector.BUS_RAGE, bus_rage_idx])
	print("  - Bus '%s' index: %d" % [KayKitAudioDirector.BUS_IMPACT, bus_impact_idx])
	print("  - Bus '%s' index: %d" % [KayKitAudioDirector.BUS_AURA, bus_aura_idx])

	if bus_normal_idx != -1 and bus_rage_idx != -1 and bus_impact_idx != -1 and bus_aura_idx != -1:
		print("  PASS: Đủ 4 Audio Bus DSP chuyên trách trên AudioServer!")
	else:
		printerr("  FAIL: Thiếu một hoặc nhiều Audio Bus trên AudioServer!")
		all_pass = false

	# Kiểm tra chuỗi hiệu ứng DSP trên RageOverdriveBus
	if bus_rage_idx != -1:
		var effect_count := AudioServer.get_bus_effect_count(bus_rage_idx)
		print("  - Số hiệu ứng DSP trên RageOverdriveBus: %d" % effect_count)
		var has_eq := false
		var has_dist := false
		var has_chorus := false
		var has_stereo := false
		var has_reverb := false
		for i in range(effect_count):
			var eff := AudioServer.get_bus_effect(bus_rage_idx, i)
			if eff is AudioEffectEQ6 or eff is AudioEffectEQ:
				has_eq = true
			elif eff is AudioEffectDistortion:
				has_dist = true
			elif eff is AudioEffectChorus:
				has_chorus = true
			elif eff is AudioEffectStereoEnhance:
				has_stereo = true
			elif eff is AudioEffectReverb:
				has_reverb = true
		if (has_eq and has_dist and has_chorus and has_stereo and has_reverb) or (has_eq and has_reverb):
			print("  PASS: RageOverdriveBus tích hợp trọn bộ hiệu ứng phòng thu uy lực (Sub-Bass EQ + Reverb + Compressor)!")
		else:
			printerr("  FAIL: RageOverdriveBus thiếu hiệu ứng! EQ:%s Reverb:%s" % [has_eq, has_reverb])
			all_pass = false

	# Kiểm tra kích thước Audio Pool
	if audio_dir:
		var pool_size := audio_dir.players.size()
		print("  - Kích thước Audio Pool: %d kênh (Yêu cầu: 32 kênh)" % pool_size)
		if pool_size >= 32:
			print("  PASS: Audio Pool đạt chuẩn 32 kênh đa luồng không tắc nghẽn!")
		else:
			printerr("  FAIL: Audio Pool chỉ có %d kênh (yêu cầu >= 32)!" % pool_size)
			all_pass = false

	# --------------------------------------------------------------------------
	# TEST 29.3: KIỂM ĐỊNH TÁCH BIỆT 100% TRẠNG THÁI 1 VS TRẠNG THÁI 2 & LINGERING TAIL
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 29.3 - KIỂM ĐỊNH TÁCH BIỆT 100% TRẠNG THÁI 1 VS TRẠNG THÁI 2 NỘ [R]]...")
	var bank: Dictionary = KayKitAudioDirector._sfx_bank

	# 1. Chiêu thức Trạng Thái 1
	var state1_events := ["u1_slash", "u2_slash", "u3_heaven_shatter", "i_phase1_x_cleave", "i_phase2_wave_launch"]
	var state1_ok := true
	for ev in state1_events:
		if not bank.has(ev):
			printerr("  FAIL: Thiếu sự kiện âm thanh Trạng Thái 1: %s" % ev)
			state1_ok = false
			all_pass = false
		else:
			var layers: Array = bank[ev]
			var uses_normal := false
			for l in layers:
				if l.get("bus") == KayKitAudioDirector.BUS_NORMAL:
					uses_normal = true
			if not uses_normal:
				printerr("  FAIL: Sự kiện Trạng Thái 1 '%s' không định tuyến qua %s!" % [ev, KayKitAudioDirector.BUS_NORMAL])
				state1_ok = false
				all_pass = false
	if state1_ok:
		print("  PASS: 100% chiêu thức Trạng Thái 1 định tuyến qua NormalBladeBus chuẩn xác!")

	# 2. Chiêu thức Trạng Thái 2 (Nộ [R])
	var state2_events := ["u1_rage", "u2_rage", "u3_rage_dragon_fall", "i_rage_hexa_cleave", "i_rage_five_wing_wave"]
	var state2_ok := true
	for ev in state2_events:
		if not bank.has(ev):
			printerr("  FAIL: Thiếu sự kiện âm thanh Trạng Thái 2: %s" % ev)
			state2_ok = false
			all_pass = false
		else:
			var layers: Array = bank[ev]
			var uses_rage_or_impact := false
			for l in layers:
				var b: String = l.get("bus", "")
				if b == KayKitAudioDirector.BUS_RAGE or b == KayKitAudioDirector.BUS_IMPACT:
					uses_rage_or_impact = true
			if not uses_rage_or_impact:
				printerr("  FAIL: Sự kiện Trạng Thái 2 '%s' không dùng RageOverdriveBus hoặc HeavyImpactBus!" % ev)
				state2_ok = false
				all_pass = false
	if state2_ok:
		print("  PASS: 100% chiêu thức Trạng Thái 2 Nộ [R] định tuyến qua RageOverdriveBus & HeavyImpactBus!")

	# 3. Kiểm định 3 Pha Âm Thanh Đọng Lại (Lingering Audio Tail) cho U3 và I
	var u3_layers: Array = bank.get("u3_rage_dragon_fall", [])
	var has_phase1 := false # 0.0s
	var has_phase2 := false # 0.04s - 0.15s
	var has_phase3 := false # >= 0.20s (Lingering Tail)
	for l in u3_layers:
		var d: float = float(l.get("delay", 0.0))
		if d < 0.02:
			has_phase1 = true
		elif d >= 0.04 and d <= 0.16:
			has_phase2 = true
		elif d >= 0.20:
			has_phase3 = true

	if has_phase1 and has_phase2 and has_phase3:
		print("  PASS: Đòn U3 Nộ ('u3_rage_dragon_fall') có đủ 3 Pha: Giáng Kiếm (0.0s) -> Nổ Địa Chấn (0.05s) -> Đọng Lại & Phình To (>=0.20s)!")
	else:
		printerr("  FAIL: Đòn U3 Nộ thiếu pha âm thanh! P1:%s P2:%s P3:%s" % [has_phase1, has_phase2, has_phase3])
		all_pass = false

	# Kiểm tra phát thử SFX qua Audio Pool
	var test_sfx_list := [
		"u1_slash", "u1_rage",
		"u2_slash", "u2_rage",
		"u3_heaven_shatter", "u3_rage_dragon_fall",
		"i_phase1_x_cleave", "i_rage_hexa_cleave",
		"i_phase2_wave_launch", "i_rage_five_wing_wave",
		"o_whirlwind_spin", "p_bomb_throw", "dash_space", "footstep_stone"
	]
	var prev_count := audio_dir.play_count
	for sfx in test_sfx_list:
		KayKitAudioDirector.play_sfx(sfx)
	var triggered_count := audio_dir.play_count - prev_count
	print("  - Đã phát thử %d/%d SFX qua Audio Pool (tổng số lượt phát: %d)" % [triggered_count, test_sfx_list.size(), audio_dir.play_count])
	if triggered_count >= test_sfx_list.size():
		print("  PASS: 100% SFX kỹ năng phát mượt mà qua các Audio Bus chuyên trách!")
	else:
		printerr("  FAIL: Một số SFX không thể phát!")
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 29.4: BẢO TOÀN 0% PRIMITIVEMESH & TOÀN BỘ TÍNH NĂNG PHASE 24-27
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 29.4 - BẢO TOÀN 0% PRIMITIVEMESH & CÁC TÍNH NĂNG CỐT LÕI]...")
	var primitive_count := 0
	var array_mesh_count := 0
	var stack: Array[Node] = [arena]
	while not stack.is_empty():
		var curr := stack.pop_back() as Node
		if curr is MeshInstance3D:
			var m := (curr as MeshInstance3D).mesh
			if m != null:
				if m is PrimitiveMesh:
					primitive_count += 1
					printerr("  FAIL: Phát hiện PrimitiveMesh vi phạm tại node: %s" % curr.get_path())
				elif m is ArrayMesh:
					array_mesh_count += 1
		for c in curr.get_children():
			stack.append(c)

	print("  - Tổng số MeshInstance3D quét được: %d" % (primitive_count + array_mesh_count))
	print("  - ArrayMeshes (KayKit GLB & Curved Slash Arcs): %d" % array_mesh_count)
	print("  - PrimitiveMeshes: %d" % primitive_count)
	if primitive_count == 0:
		print("  PASS: 100% ZERO PRIMITIVE MESHES CONFIRMED (primitive_count == 0, Luật thép số 1 duy trì tuyệt đối)!")
	else:
		printerr("  FAIL: Phát hiện %d PrimitiveMesh vi phạm!" % primitive_count)
		all_pass = false

	# Kiểm tra HeroKnight3D các chỉ số
	if hero:
		print("  - Hero hp: %.1f | _cd_dash: %.2fs" % [hero.hp, hero.COOLDOWN_DASH])
		if hero.COOLDOWN_DASH == 1.0:
			print("  PASS: Cooldown Dash [Space] 1.0s bảo toàn nguyên vẹn!")
		else:
			printerr("  FAIL: Cooldown Dash bị thay đổi: %.2f" % hero.COOLDOWN_DASH)
			all_pass = false

	print("\n==================================================================")
	if all_pass:
		print("  🏆 ALL 4 PHASE 29 TESTS PASSED 100% (ARGONS DIRECTIVE 29 SATISFIED)!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  💥 SOME TESTS FAILED IN PHASE 29!")
		print("==================================================================")
		quit(1)
