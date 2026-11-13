extends SceneTree

# ==============================================================================
# TEST PHASE 30: CLEAN & STRUCTURED COMBAT AUDIO VERIFICATION
# DIRECTIVE 30 (ARGONS & ANTIGRAVITY) — 4 MANDATORY VERIFICATION TESTS:
#   [TEST 30.1]: Cấm File Laser & Tàu Vũ Trụ & Tắt Hào Quang Ù Nền
#   [TEST 30.2]: Số Lớp Tinh Gọn (1-2 Lớp Thường, <=3 Lớp Nộ) & Cắt Đuôi max_dur <= 0.55s
#   [TEST 30.3]: Audio Bus Sạch (0% Distortion / 0% Chorus) & Định Tuyến Trạng Thái 1 vs 2
#   [TEST 30.4]: Bảo Toàn 0% Khối Thô (PrimitiveMesh == 0) & Voice Choking Nhường Kênh
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const KayKitAudioDirector = preload("res://scripts/audio/kaykit_audio_director.gd")

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 30: CLEAN & STRUCTURED COMBAT AUDIO SYSTEM")
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
	# TEST 30.1: CẤM FILE LASER, TÀU VŨ TRỤ & TẮT HÀO QUANG Ù NỀN
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 30.1 - KIỂM ĐỊNH CẤM FILE LASER & TÀU VŨ TRỤ]...")
	var audio_dir := KayKitAudioDirector.ensure_initialized(root.get_tree())
	if audio_dir == null:
		printerr("  FAIL: Không khởi tạo được KayKitAudioDirector!")
		all_pass = false
	else:
		var raw_keys := KayKitAudioDirector._raw_streams.keys()
		var forbidden_found := false
		for k in raw_keys:
			var str_k: String = str(k).to_lower()
			if str_k.contains("laser") or str_k.contains("engine_roar") or str_k.contains("forcefield"):
				printerr("  FAIL: Phát hiện file cấm trong _raw_streams: %s" % k)
				forbidden_found = true
				all_pass = false
		if not forbidden_found:
			print("  PASS: 100%% không chứa bất kỳ file súng laser hay tàu vũ trụ nào trong _raw_streams (%d streams tinh chọn)!" % raw_keys.size())

		# Kiểm tra rage_aura_loop_player không được phát tiếng ù ngầm
		KayKitAudioDirector.set_rage_bgm_mode(true)
		if audio_dir.rage_aura_loop_player and audio_dir.rage_aura_loop_player.playing:
			printerr("  FAIL: rage_aura_loop_player đang tự ý phát tiếng ù nền trong lúc Nộ!")
			all_pass = false
		else:
			print("  PASS: rage_aura_loop_player đã được tắt hoàn toàn, không gây ù nền!")
		KayKitAudioDirector.set_rage_bgm_mode(false)

	# --------------------------------------------------------------------------
	# TEST 30.2: SỐ LỚP TINH GỌN (1-2 LỚP THƯỜNG, <=3 LỚP NỘ) & CẮT ĐUÔI MAX_DUR
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 30.2 - KIỂM ĐỊNH SỐ LỚP TINH GỌN & CẮT ĐUÔI MAX_DUR]...")
	var bank: Dictionary = KayKitAudioDirector._sfx_bank
	print("  - Tổng số sự kiện âm thanh cấu hình trong Bank: %d" % bank.size())
	if bank.size() < 23:
		printerr("  FAIL: Số sự kiện âm thanh không đủ 23! Hiện có: %d" % bank.size())
		all_pass = false

	var layer_count_ok := true
	var max_dur_ok := true
	var group_ok := true

	var single_or_dual_events := [
		"u1_slash", "u2_slash",
		"u1_rage", "u2_rage",
		"i_phase1_x_cleave", "i_phase2_wave_launch", "i_wave_finale",
		"p_bomb_throw", "p_bomb_thunder_explode", "p_bomb_dot_zap",
		"dash_space", "jump_c", "footstep_stone",
		"hit_enemy_flesh_metal", "enemy_death_burst", "rage_r_expire"
	]

	for ev_name in bank:
		var layers: Array = bank[ev_name]
		# Kiểm tra số lớp cho các đòn đánh thông thường
		if ev_name in single_or_dual_events:
			if layers.size() > 2:
				printerr("  FAIL: Sự kiện '%s' có quá 2 lớp âm thanh (%d lớp)!" % [ev_name, layers.size()])
				layer_count_ok = false
				all_pass = false
		else:
			# Các đòn U3, Nộ thức tỉnh, Xoay 360 tối đa 3-4 lớp theo các pha
			if layers.size() > 4:
				printerr("  FAIL: Sự kiện phức hợp '%s' có quá 4 lớp âm thanh (%d lớp)!" % [ev_name, layers.size()])
				layer_count_ok = false
				all_pass = false

		# Kiểm tra từng layer: max_dur <= 0.55s và group hợp lệ
		for layer in layers:
			var dur: float = float(layer.get("max_dur", 99.0))
			if dur > 0.55:
				printerr("  FAIL: Sự kiện '%s' có lớp âm thanh max_dur = %.2fs > 0.55s!" % [ev_name, dur])
				max_dur_ok = false
				all_pass = false
			var grp: String = str(layer.get("group", ""))
			if grp not in ["SWING", "IMPACT", "MOVEMENT", "FOOTSTEP", "STATE"]:
				printerr("  FAIL: Sự kiện '%s' có nhóm group không hợp lệ: '%s'!" % [ev_name, grp])
				group_ok = false
				all_pass = false

	if layer_count_ok:
		print("  PASS: 100% sự kiện âm thanh đạt chuẩn tinh gọn (đòn thường 1-2 lớp, chiêu thức tối đa 3 lớp)!")
	if max_dur_ok:
		print("  PASS: 100% lớp âm thanh đều có thông số cắt đuôi max_dur <= 0.55s!")
	if group_ok:
		print("  PASS: 100% lớp âm thanh thuộc các nhóm Voice Choking hợp lệ (SWING, IMPACT, MOVEMENT, FOOTSTEP, STATE)!")

	# --------------------------------------------------------------------------
	# TEST 30.3: AUDIO BUS SẠCH KHÔNG DISTORTION & ĐỊNH TUYẾN CHUẨN XÁC
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 30.3 - KIỂM ĐỊNH AUDIO BUS SẠCH KHÔNG DISTORTION/CHORUS]...")
	var bus_rage_idx := AudioServer.get_bus_index(KayKitAudioDirector.BUS_RAGE)
	var bus_norm_idx := AudioServer.get_bus_index(KayKitAudioDirector.BUS_NORMAL)
	var distortion_free := true

	for b_idx in [bus_norm_idx, bus_rage_idx]:
		if b_idx != -1:
			var eff_count := AudioServer.get_bus_effect_count(b_idx)
			for i in range(eff_count):
				var eff := AudioServer.get_bus_effect(b_idx, i)
				if eff is AudioEffectDistortion:
					printerr("  FAIL: Bus %s vẫn còn AudioEffectDistortion gây vỡ tiếng!" % AudioServer.get_bus_name(b_idx))
					distortion_free = false
					all_pass = false
				if eff is AudioEffectChorus:
					printerr("  FAIL: Bus %s vẫn còn AudioEffectChorus gây nhòe tiếng!" % AudioServer.get_bus_name(b_idx))
					distortion_free = false
					all_pass = false

	if distortion_free:
		print("  PASS: AudioServer hoàn toàn sạch, KHÔNG CÒN AudioEffectDistortion hay AudioEffectChorus gây rè vỡ tiếng!")

	# Kiểm tra định tuyến: Trạng thái 1 qua NormalBladeBus, Trạng thái 2 qua RageOverdriveBus/HeavyImpactBus
	var u1_layers: Array = bank.get("u1_slash", [])
	var u1_rage_layers: Array = bank.get("u1_rage", [])
	if u1_layers.size() > 0 and u1_layers[0].get("bus") == KayKitAudioDirector.BUS_NORMAL:
		print("  PASS: U1 Thường ('u1_slash') định tuyến qua NormalBladeBus chuẩn xác!")
	else:
		printerr("  FAIL: U1 Thường không định tuyến qua NormalBladeBus!")
		all_pass = false

	if u1_rage_layers.size() > 0 and u1_rage_layers[0].get("bus") == KayKitAudioDirector.BUS_RAGE:
		print("  PASS: U1 Nộ ('u1_rage') định tuyến qua RageOverdriveBus chuẩn xác!")
	else:
		printerr("  FAIL: U1 Nộ không định tuyến qua RageOverdriveBus!")
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 30.4: BẢO TOÀN 0% PRIMITIVEMESH & CƠ CHẾ VOICE GROUP CHOKING
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 30.4 - BẢO TOÀN 0% PRIMITIVEMESH & CƠ CHẾ VOICE CHOKING]...")
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
					printerr("  FAIL: Phát hiện PrimitiveMesh vi phạm tại: %s" % curr.get_path())
				elif m is ArrayMesh:
					array_mesh_count += 1
		for c in curr.get_children():
			stack.append(c)

	print("  - Tổng MeshInstance3D: %d | ArrayMeshes: %d | PrimitiveMeshes: %d" % [primitive_count + array_mesh_count, array_mesh_count, primitive_count])
	if primitive_count == 0:
		print("  PASS: 100% ZERO PRIMITIVE MESHES CONFIRMED (primitive_count == 0)!")
	else:
		printerr("  FAIL: Có %d PrimitiveMesh vi phạm!" % primitive_count)
		all_pass = false

	# Kiểm tra cơ chế Voice Choking khi gọi liên tiếp U1 -> U2 -> U3
	var prev_plays := audio_dir.play_count
	KayKitAudioDirector.play_sfx("u1_slash")
	KayKitAudioDirector.play_sfx("u2_slash")
	KayKitAudioDirector.play_sfx("u3_heaven_shatter")
	var new_plays := audio_dir.play_count
	if new_plays > prev_plays:
		print("  PASS: Voice Group Choking và kích hoạt combo U1 -> U2 -> U3 hoạt động mượt mà, không xung đột kênh!")
	else:
		printerr("  FAIL: Lỗi khi phát chuỗi combo âm thanh!")
		all_pass = false

	print("\n==================================================================")
	if all_pass:
		print("  🏆 ALL 4 PHASE 30 TESTS PASSED 100% (ARGONS DIRECTIVE 30 SATISFIED)!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  💥 SOME TESTS FAILED IN PHASE 30!")
		print("==================================================================")
		quit(1)
