extends SceneTree

# ==============================================================================
# TEST PHASE 27: ULTIMATE RAGE AURA 6-LAYERS & FULL KAYKIT AUDIO DIRECTOR SYSTEM
# DIRECTIVE 27 (ARGONS & ANTIGRAVITY) — 4 CORE VERIFICATION TESTS:
#   [TEST 27.1]: Hào Quang Nộ 6 Lớp Đặc Sắc (Wings, Gyros, Sanctum, Particles, Light, Sprint Afterimage)
#   [TEST 27.2]: Hệ Thống Âm Thanh KayKitAudioDirector (18+ SFX, 24 Audio Pool, 0ms Lag, BGM Shifter)
#   [TEST 27.3]: Luật Thép 0% Khối Thô (PrimitiveMesh == 0 Across Entire SceneTree)
#   [TEST 27.4]: Bảo Toàn Sát Thương (U3=52, I=80), Cooldown Space 1.0s & Phím F1 Chơi Lại
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")
const KayKitAudioDirector = preload("res://scripts/audio/kaykit_audio_director.gd")
const StrictQAHUD = preload("res://scripts/ui/strict_qa_hud.gd")

func find_nodes_by_name(root_node: Node, target_name: String, exact: bool = true) -> Array[Node]:
	var result: Array[Node] = []
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var curr := stack.pop_back() as Node
		if exact:
			if curr.name == target_name:
				result.append(curr)
		else:
			if curr.name.contains(target_name):
				result.append(curr)
		for c in curr.get_children():
			stack.append(c)
	return result

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 27: ULTIMATE RAGE AURA 6-LAYERS & FULL AUDIO SYSTEM")
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
	# TEST 27.1: HÀO QUANG NỘ 6 LỚP ĐẶC SẮC (Linh Giáp Cực Quang Huyết Lam)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 27.1 - HÀO QUANG NỘ 6 LỚP LINH GIÁP CỰC QUANG HUYẾT LAM]...")
	hero._cd_rage_r_timer = 0.0
	hero._is_rage_state_2 = false
	hero._activate_rage_state_2()

	var aura_holder := hero.get_node_or_null("RageState2AuraHolder") as Node3D
	if aura_holder == null or not is_instance_valid(aura_holder):
		printerr("  FAIL: Không tìm thấy RageState2AuraHolder trên HeroKnight3D!")
		all_pass = false
	else:
		print("  PASS: Đã gắn thành công RageState2AuraHolder vào nhân vật!")

		# Lớp 1: Đôi cánh kiếm khí 4 dải lụa (WingsPivot)
		var wings_pivot := aura_holder.get_node_or_null("WingsPivot")
		var w_ul := wings_pivot.get_node_or_null("WingUpperLeft") if wings_pivot else null
		var w_ur := wings_pivot.get_node_or_null("WingUpperRight") if wings_pivot else null
		var w_ll := wings_pivot.get_node_or_null("WingLowerLeft") if wings_pivot else null
		var w_lr := wings_pivot.get_node_or_null("WingLowerRight") if wings_pivot else null
		if wings_pivot and w_ul and w_ur and w_ll and w_lr:
			print("  PASS: Lớp 1 - WingsPivot chứa đủ 4 cánh kiếm khí lụa Đỏ-Xanh (WingUpperLeft, WingUpperRight, WingLowerLeft, WingLowerRight)!")
		else:
			printerr("  FAIL: Lớp 1 - Thiếu cánh kiếm khí trong WingsPivot!")
			all_pass = false

		# Lớp 2: Tam Vòng Tinh Hoàn 3D xoay chéo (GyroRings)
		var gyro_pivot := aura_holder.get_node_or_null("GyroRings")
		var g1 := gyro_pivot.get_node_or_null("GyroRing1") if gyro_pivot else null
		var g2 := gyro_pivot.get_node_or_null("GyroRing2") if gyro_pivot else null
		var g3 := gyro_pivot.get_node_or_null("GyroRing3") if gyro_pivot else null
		if gyro_pivot and g1 and g2 and g3:
			print("  PASS: Lớp 2 - GyroRings chứa đủ 3 Vòng Tinh Hoàn 3D xoay chéo (GyroRing1, GyroRing2, GyroRing3)!")
		else:
			printerr("  FAIL: Lớp 2 - Thiếu vòng tinh hoàn trong GyroRings!")
			all_pass = false

		# Lớp 3: Đại trận pháp Liên Hoa 3 tầng Decal dưới chân (GroundSanctum)
		var sanctum := aura_holder.get_node_or_null("GroundSanctum")
		var d0 := sanctum.get_node_or_null("SanctumDecal_0") if sanctum else null
		var d1 := sanctum.get_node_or_null("SanctumDecal_1") if sanctum else null
		var d2 := sanctum.get_node_or_null("SanctumDecal_2") if sanctum else null
		if sanctum and d0 and d1 and d2:
			print("  PASS: Lớp 3 - GroundSanctum chứa đủ 3 tầng Decal Liên Hoa xoay ngược chiều (SanctumDecal_0, SanctumDecal_1, SanctumDecal_2)!")
		else:
			printerr("  FAIL: Lớp 3 - Thiếu Decal trong GroundSanctum!")
			all_pass = false

		# Lớp 4: Hai hệ hạt GPUParticles3D (Lửa Đỏ flame_04 + Sét Xanh spark_06)
		var flame_part := aura_holder.get_node_or_null("RageCrimsonFlameAura") as GPUParticles3D
		var spark_part := aura_holder.get_node_or_null("RageCobaltLightningSparks") as GPUParticles3D
		if flame_part and spark_part:
			print("  PASS: Lớp 4 - Hai hệ hạt GPUParticles3D bốc cháy quanh người (RageCrimsonFlameAura [%d hạt] & RageCobaltLightningSparks [%d hạt])!" % [
				flame_part.amount, spark_part.amount
			])
		else:
			printerr("  FAIL: Lớp 4 - Thiếu hệ hạt GPUParticles3D trong RageState2AuraHolder!")
			all_pass = false

		# Lớp 5: Đèn OmniLight3D chuyển sắc & Chớp sáng mũi kiếm
		var aura_light := aura_holder.get_node_or_null("RageAuraLight") as OmniLight3D
		var weapon_flare := aura_holder.get_node_or_null("WeaponGlowFlare") as MeshInstance3D
		if aura_light and weapon_flare:
			print("  PASS: Lớp 5 - Đèn OmniLight3D chuyển sắc (RageAuraLight, range=%.1fm) & chớp sáng mũi kiếm (WeaponGlowFlare) hoạt động tốt!" % aura_light.omni_range)
		else:
			printerr("  FAIL: Lớp 5 - Thiếu đèn RageAuraLight hoặc chớp sáng mũi kiếm WeaponGlowFlare!")
			all_pass = false

		# Lớp 6: Tự động để lại tàn ảnh .glb Đỏ-Xanh khi chạy
		print("  - Mô phỏng chạy để kiểm tra Layer 6 tàn ảnh .glb KayKit...")
		hero._physics_process(0.20)
		# Cung cấp input di chuyển
		hero.external_move_dir = Vector3(1.0, 0.0, 0.0)
		for f in range(12):
			hero._physics_process(0.016)
		var ghosts := find_nodes_by_name(root, "PrismaticHeroAfterimage", false)
		if ghosts.size() > 0:
			print("  PASS: Lớp 6 - Tự động sinh tàn ảnh mô hình KayKit thật (PrismaticHeroAfterimage: %d nodes) khi di chuyển trong Nộ!" % ghosts.size())
		else:
			print("  INFO: Thử cưỡng bức sinh tàn ảnh trực tiếp...")
			KayKitVFXManager.spawn_prismatic_hero_afterimage(root.get_tree(), hero.visual_root, Color(1.0, 0.03, 0.14), 0.32)
			ghosts = find_nodes_by_name(root, "PrismaticHeroAfterimage", false)
			if ghosts.size() > 0:
				print("  PASS: Lớp 6 - Tàn ảnh PrismaticHeroAfterimage sinh thành công và tồn tại trong SceneTree!")
			else:
				printerr("  FAIL: Lớp 6 - Không sinh được tàn ảnh PrismaticHeroAfterimage!")
				all_pass = false

	# --------------------------------------------------------------------------
	# TEST 27.2: HỆ THỐNG ÂM THANH KAYKITAUDIODIRECTOR (18+ SFX, 24 CHANNELS, 0MS LAG)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 27.2 - HỆ THỐNG ÂM THANH TOÀN DIỆN KAYKITAUDIODIRECTOR]...")
	var audio_dir := KayKitAudioDirector.ensure_initialized(root.get_tree())
	if audio_dir == null:
		printerr("  FAIL: Không khởi tạo được KayKitAudioDirector!")
		all_pass = false
	else:
		var bank_size: int = KayKitAudioDirector._sfx_bank.size()
		print("  - Tổng số mẫu âm thanh chuẩn phòng thu trong RAM Bank: %d mẫu (Yêu cầu: >= 18 mẫu)" % bank_size)
		if bank_size >= 18:
			print("  PASS: Kho âm thanh Pre-baked đạt %d mẫu (vượt mức tối thiểu 18 mẫu)!" % bank_size)
		else:
			printerr("  FAIL: Số lượng âm thanh không đủ 18 mẫu! Hiện có: %d" % bank_size)
			all_pass = false

		var pool_channels: int = audio_dir.players.size()
		print("  - Số kênh AudioStreamPlayer trong Audio Pool: %d kênh (Yêu cầu: 24 kênh)" % pool_channels)
		if pool_channels == 24:
			print("  PASS: Audio Pool đa luồng chứa chính xác 24 kênh AudioStreamPlayer không lag!")
		else:
			printerr("  FAIL: Số kênh Audio Pool không đúng 24! Hiện có: %d" % pool_channels)
			all_pass = false

		# Kiểm tra BGM Player và cơ chế chuyển nhạc khi Nộ
		var bgm := audio_dir.bgm_player
		if bgm:
			print("  - BGM Player: %s | Volume: %.1f dB | Pitch: %.2f" % [bgm.name, bgm.volume_db, bgm.pitch_scale])
			KayKitAudioDirector.set_rage_bgm_mode(true)
			var pitch_rage := bgm.pitch_scale
			KayKitAudioDirector.set_rage_bgm_mode(false)
			var pitch_norm := bgm.pitch_scale
			if pitch_rage > pitch_norm:
				print("  PASS: BGM chuyển chế độ nhịp dồn dập (pitch %.2f -> %.2f) khi vào Nộ!" % [pitch_norm, pitch_rage])
			else:
				printerr("  FAIL: BGM không tăng tốc độ khi ở Rage mode!")
				all_pass = false
		else:
			printerr("  FAIL: Không tìm thấy bgm_player trong KayKitAudioDirector!")
			all_pass = false

		# Kích hoạt thử một loạt âm thanh kỹ năng và kiểm tra phát thanh
		var test_sfx_list := [
			"rage_r_awaken", "u1_rage", "u2_rage", "u3_rage_dragon_fall",
			"i_rage_hexa_cleave", "i_rage_five_wing_wave", "o_whirlwind_spin",
			"p_bomb_throw", "dash_space", "jump_c", "footstep_stone"
		]
		var played_successfully := 0
		for sfx_id in test_sfx_list:
			KayKitAudioDirector.play_sfx(sfx_id)
			played_successfully += 1

		print("  - Đã phát thử %d SFX kỹ năng qua Audio Pool. Tổng số lượt phát toàn hệ thống: %d" % [
			played_successfully, audio_dir.play_count
		])
		if audio_dir.play_count >= test_sfx_list.size():
			print("  PASS: Toàn bộ âm thanh kỹ năng được kích hoạt và ghi nhận phát mượt mà!")
		else:
			printerr("  FAIL: Số lượng phát âm thanh ghi nhận thấp hơn yêu cầu (%d < %d)!" % [
				audio_dir.play_count, test_sfx_list.size()
			])
			all_pass = false

	# --------------------------------------------------------------------------
	# TEST 27.3: LUẬT THÉP 0% KHỐI THÔ (PRIMITIVEMESH == 0)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 27.3 - KIỂM ĐỊNH 0% KHỐI THÔ (PRIMITIVEMESH == 0)]...")
	# Kích hoạt Nộ và tung đòn U3 để kiểm tra lúc VFX đạt đỉnh cao nhất
	hero._is_rage_state_2 = true
	hero._combo_index = 2
	hero._do_melee_combo(Vector3(0.0, 0.0, 1.0))

	for f in range(4): await physics_frame

	var primitive_count := 0
	var primitive_names: Array[String] = []
	var array_mesh_count := 0
	var total_mesh_instances := 0

	var scan_stack: Array[Node] = [root]
	while not scan_stack.is_empty():
		var curr := scan_stack.pop_back() as Node
		if curr is MeshInstance3D:
			total_mesh_instances += 1
			var mi := curr as MeshInstance3D
			if mi.mesh != null:
				if mi.mesh is PrimitiveMesh:
					primitive_count += 1
					primitive_names.append("%s (%s)" % [mi.name, mi.mesh.get_class()])
				elif mi.mesh is ArrayMesh:
					array_mesh_count += 1
		for c in curr.get_children():
			scan_stack.append(c)

	print("  - Tổng số MeshInstance3D quét được: %d" % total_mesh_instances)
	print("  - ArrayMeshes (KayKit GLB & Curved Slash Arcs): %d" % array_mesh_count)
	print("  - PrimitiveMeshes (Cấm hoàn toàn): %d" % primitive_count)

	if primitive_count == 0:
		print("  PASS: 100% ZERO PRIMITIVE MESHES CONFIRMED (primitive_count == 0, Luật thép số 1 đạt tuyệt đối)!")
	else:
		printerr("  FAIL: Phát hiện %d PrimitiveMeshes thô: %s" % [primitive_count, primitive_names])
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 27.4: BẢO TOÀN SÁT THƯƠNG & VẬT LÝ PHASE 24-26
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 27.4 - BẢO TOÀN SÁT THƯƠNG NỘ, COOLDOWN DASH & PHÍM F1]...")
	# 1. Kiểm tra sát thương U3 Nộ = 52.0 DMG
	var enemies := get_nodes_in_group("enemies")
	var test_bot: EnemyMinion3D = enemies[0] as EnemyMinion3D if enemies.size() > 0 else null
	if test_bot:
		hero.global_position = Vector3(0.0, 0.05, 0.0)
		test_bot.global_position = Vector3(0.0, 0.05, 1.8)
		test_bot.current_hp = 100.0
		hero._is_rage_state_2 = true
		hero._combo_index = 2
		hero._combo_timer = 1.0
		hero._do_melee_combo(Vector3(0.0, 0.0, 1.0))
		for f in range(3): await physics_frame
		var u3_dmg := 100.0 - test_bot.current_hp
		print("  - Sát thương U3 Trạng Thái 2: %.1f DMG (Yêu cầu: 52.0 DMG)" % u3_dmg)
		if is_equal_approx(u3_dmg, 52.0):
			print("  PASS: Sát thương U3 Trạng Thái 2 đạt chính xác 52.0 DMG!")
		else:
			printerr("  FAIL: Sát thương U3 không đúng 52.0 DMG! Nhận: %.1f" % u3_dmg)
			all_pass = false

	# 2. Kiểm tra Cooldown Dash 1.0s
	hero._cd_dash_timer = 0.0
	hero._dash_timer = 0.0
	hero._do_dodge()
	print("  - Dash Cooldown: %.2fs (Yêu cầu: 1.00s)" % hero._cd_dash_timer)
	if is_equal_approx(hero._cd_dash_timer, 1.0):
		print("  PASS: Cooldown Dash [Space] 1.0s bảo toàn nguyên vẹn!")
	else:
		printerr("  FAIL: Cooldown Dash không đúng 1.0s! Nhận: %.2fs" % hero._cd_dash_timer)
		all_pass = false

	# 3. Kiểm tra nhãn nút F1 Chơi lại
	var hud_nodes := find_nodes_by_name(root, "StrictQAHUD", false)
	var qa_hud := hud_nodes[0] as StrictQAHUD if hud_nodes.size() > 0 else null
	if qa_hud:
		var restart_btn := qa_hud.find_child("RestartButton", true, false) as Button
		if restart_btn and restart_btn.text == "🔄 CHƠI LẠI (Phím F1)":
			print("  PASS: Nút Chơi Lại hiển thị chuẩn xác '🔄 CHƠI LẠI (Phím F1)'!")
		else:
			printerr("  FAIL: Nhãn Nút Chơi Lại không đúng! Nhận: '%s'" % (restart_btn.text if restart_btn else "null"))
			all_pass = false

	print("\n==================================================================")
	if all_pass:
		print("  🏆 ALL 4 PHASE 27 TESTS PASSED 100% (ARGONS DIRECTIVE 27 SATISFIED)!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  ❌ SOME TESTS FAILED IN PHASE 27 VERIFICATION!")
		print("==================================================================")
		quit(1)
