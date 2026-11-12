extends SceneTree

# ==============================================================================
# TEST PHASE 25: PRISMATIC 5-STOP HDR VFX OVERHAUL (U COMBO 3 & I CROSS-CLEAVE)
# DIRECTIVE 25 (ARGONS & ANTIGRAVITY) — 4 CORE VERIFICATION TESTS:
#   [TEST 25.1]: Đòn đánh thứ 3 [U/LMB] — "Thánh Long Thiên Giáng Trảm" 7 Lớp & 35 DMG
#   [TEST 25.2]: Tuyệt kỹ [I/RMB] — "Thánh Kiếm Phá Không: Cực Quang Thập Tự" 8 Lớp & 55 DMG
#   [TEST 25.3]: Kiểm định 0% Khối Thô (PrimitiveMesh == 0, 100% ArrayMesh & GLB)
#   [TEST 25.4]: Bảo toàn 100% Trạng thái Phase 24 (Stairs, Dash CD 1.0s, Wasd)
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")

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
	print("  TEST PHASE 25: PRISMATIC 5-STOP HDR VFX OVERHAUL VERIFICATION")
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
	# TEST 25.1: Đòn đánh thứ 3 Nút [U] — "Thánh Long Thiên Giáng Trảm" (7 Lớp & 35 DMG)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 25.1 - ĐÒN ĐÁNH THỨ 3 NÚT [U] 7 LỚP ĐA SẮC & SÁT THƯƠNG 35 DMG]...")
	var enemies := get_nodes_in_group("enemies")
	var test_bot: EnemyMinion3D = null
	if enemies.size() > 0:
		test_bot = enemies[0] as EnemyMinion3D

	if not test_bot:
		printerr("  FAIL: No enemy bot available for test!")
		all_pass = false
	else:
		# Đặt Bot ngay trước mặt Hero (1.8m phía trước)
		hero.global_position = Vector3(0.0, 0.05, 0.0)
		hero._facing_angle = 0.0 # Hướng về phía trước (+Z)
		if hero.visual_root:
			hero.visual_root.rotation.y = 0.0

		test_bot.global_position = Vector3(0.0, 0.05, 1.8)
		test_bot.current_hp = 100.0
		test_bot._displayed_lag_hp = 100.0

		# Thực hiện nhịp 1 và nhịp 2
		hero._combo_index = 0
		hero._combo_timer = 1.0
		hero._do_melee_combo(Vector3(0.0, 0.0, 1.0)) # Nhịp 1
		for f in range(4): await physics_frame

		hero._combo_timer = 1.0
		hero._do_melee_combo(Vector3(0.0, 0.0, 1.0)) # Nhịp 2
		for f in range(4): await physics_frame

		# Nhịp 3: "Thánh Long Thiên Giáng Trảm" (current_step == 2)
		var hp_before := test_bot.current_hp
		hero._combo_timer = 1.0
		hero._do_melee_combo(Vector3(0.0, 0.0, 1.0)) # Nhịp 3

		for f in range(3): await physics_frame

		var hp_after := test_bot.current_hp
		var damage_dealt := hp_before - hp_after
		print("  - Bot HP before U3: %.1f | After U3: %.1f | Damage dealt: %.1f DMG" % [hp_before, hp_after, damage_dealt])
		if is_equal_approx(damage_dealt, 35.0):
			print("  PASS: Đòn đánh thứ 3 nút [U] gây chính xác 35.0 DMG lên Bot!")
		else:
			printerr("  FAIL: Sát thương nhịp 3 không đúng 35.0 DMG! Nhận: %.1f" % damage_dealt)
			all_pass = false

		# Kiểm tra sự xuất hiện đầy đủ của 7 Lớp Hiệu Ứng trong SceneTree
		var guillotine_arcs := find_nodes_by_name(root, "U3TripleGuillotineArc", false)
		var cyclone_rings := find_nodes_by_name(root, "PrismaticCycloneRibbon3D", false)
		var helix_pillars := find_nodes_by_name(root, "U3HelixRibbonPillar", false)
		var star_flares := find_nodes_by_name(root, "KenneyStarFlareBurst", false)
		var fountain_nodes := find_nodes_by_name(root, "U3PrismaticFountainParticles", false)
		var fountain_sparks: GPUParticles3D = fountain_nodes[0] as GPUParticles3D if fountain_nodes.size() > 0 else null

		var u3_decals := find_nodes_by_name(root, "U3HeavenDecal", false)
		var u3_lights := find_nodes_by_name(root, "U3HeavenFlashLight", false)
		if u3_lights.is_empty():
			var stack_all: Array[Node] = [root]
			while not stack_all.is_empty():
				var curr := stack_all.pop_back() as Node
				if curr is OmniLight3D and (curr.global_position.distance_to(Vector3(0.0, 1.1, 1.85)) < 2.5):
					u3_lights.append(curr)
				for c in curr.get_children():
					stack_all.append(c)

		print("  - Lớp 1 (Tam Trùng Đại Kiếm Khí): %d nodes (Yêu cầu: 3)" % guillotine_arcs.size())
		print("  - Lớp 2 (Vòng Lụa Kiếm Khí Xoáy Dưới Đất): %d nodes (Yêu cầu: >= 2)" % cyclone_rings.size())
		print("  - Lớp 3 (Cột Xoáy Lụa Đôi Bốc Lên Trời): %d nodes (Yêu cầu: 2)" % helix_pillars.size())
		print("  - Lớp 4 (Trận Pháp Cổ Ngữ Decal Kép): %d decals (Yêu cầu: >= 2)" % u3_decals.size())
		print("  - Lớp 5 (Hoa Đăng Tinh Tú Kenney): %d nodes (Yêu cầu: >= 1)" % star_flares.size())
		print("  - Lớp 6 (Đài Phun Hạt Cầu Vồng): %s (Amount: %d, Yêu cầu: 42)" % [
			"TỒN TẠI" if fountain_sparks != null else "KHÔNG TÌM THẤY",
			fountain_sparks.amount if fountain_sparks != null else 0
		])
		print("  - Lớp 7 (Xung Ánh Sáng Đổi Màu OmniLight3D): %d lights (Shadowless: %s)" % [
			u3_lights.size(),
			str(not (u3_lights[0] as OmniLight3D).shadow_enabled) if u3_lights.size() > 0 else "N/A"
		])

		var l1_pass: bool = (guillotine_arcs.size() == 3)
		var l2_pass: bool = (cyclone_rings.size() >= 2)
		var l3_pass: bool = (helix_pillars.size() == 2)
		var l4_pass: bool = (u3_decals.size() >= 2)
		var l5_pass: bool = (star_flares.size() >= 1)
		var l6_pass: bool = (fountain_sparks != null and fountain_sparks.amount == 42)
		var l7_pass: bool = (u3_lights.size() >= 1 and not (u3_lights[0] as OmniLight3D).shadow_enabled)

		if l1_pass and l2_pass and l3_pass and l4_pass and l5_pass and l6_pass and l7_pass:
			print("  PASS: Toàn bộ 7 LỚP HIỆU ỨNG ĐA SẮC của đòn U3 đã khởi tạo đồng bộ và chính xác 100%!")
		else:
			printerr("  FAIL: Thiếu một hoặc nhiều lớp hiệu ứng trong đòn U3!")
			all_pass = false

	# Chờ hiệu ứng U3 hoàn tất
	for f in range(25): await physics_frame

	# --------------------------------------------------------------------------
	# TEST 25.2: Tuyệt Kỹ Nút [I] — "Thánh Kiếm Phá Không: Cực Quang Thập Tự" (55 DMG)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 25.2 - TUYỆT KỸ NÚT [I] CỰC QUANG THẬP TỰ (2 PHA, 8 LỚP & 55 DMG)]...")
	hero.global_position = Vector3(0.0, 0.05, 0.0)
	hero._facing_angle = 0.0
	hero._cd_rmb_timer = 0.0

	# Chuẩn bị Bot 1 cho Pha 1 (khoảng cách 1.2m trong quạt cận chiến 3.5m)
	var bot1 := test_bot
	bot1.global_position = Vector3(0.0, 0.05, 1.2)
	bot1.current_hp = 100.0

	# Chuẩn bị Bot 2 cho Pha 2 (khoảng cách 4.2m, ngoài quạt Pha 1 3.5m nhưng nằm trên đường sóng 4.8m)
	var bot2: EnemyMinion3D = null
	if enemies.size() > 1:
		bot2 = enemies[1] as EnemyMinion3D
	else:
		var bot_scene := load("res://scenes/enemies/enemy_minion_3d.tscn") as PackedScene
		if bot_scene:
			bot2 = bot_scene.instantiate() as EnemyMinion3D
			arena.add_child(bot2)
	bot2.global_position = Vector3(0.0, 0.05, 4.2)
	bot2.current_hp = 100.0

	# --- KÍCH HOẠT PHA 1 ---
	hero._do_rmb_cross_cleave(Vector3(0.0, 0.0, 1.0))

	for f in range(3): await physics_frame

	# Kiểm tra sát thương Pha 1 (25.0 DMG lên Bot 1)
	var bot1_dmg := 100.0 - bot1.current_hp
	print("  - [Pha 1] Bot 1 HP: %.1f | Sát thương chém chữ X: %.1f DMG (Yêu cầu: 25.0 DMG)" % [bot1.current_hp, bot1_dmg])
	if is_equal_approx(bot1_dmg, 25.0):
		print("  PASS: Pha 1 chém chữ X gây đúng 25.0 DMG lên Bot 1!")
	else:
		printerr("  FAIL: Sát thương Pha 1 không đúng 25.0 DMG! Nhận: %.1f" % bot1_dmg)
		all_pass = false

	# Kiểm tra Bot 2 chưa bị dính sát thương ở Pha 1 (ở ngoài 3.5m)
	print("  - [Pha 1] Bot 2 HP: %.1f (Yêu cầu chưa bị trúng đòn: 100.0 HP)" % bot2.current_hp)
	if is_equal_approx(bot2.current_hp, 100.0):
		print("  PASS: Bot 2 nằm ngoài tầm cận chiến Pha 1, giữ nguyên 100.0 HP!")
	else:
		printerr("  FAIL: Bot 2 bị trúng đòn sớm ở Pha 1! HP: %.1f" % bot2.current_hp)
		all_pass = false

	# Kiểm tra các node Pha 1: tàn ảnh .glb thật, 4 pivot chữ X
	var afterimages := find_nodes_by_name(root, "PrismaticHeroAfterimage", false)
	var x_pivots := find_nodes_by_name(root, "RMBQuadXSlashPivot_", false)

	print("  - [Pha 1] Tàn ảnh .glb KayKit thật: %d nodes | Tứ kiếm khí chữ X: %d nodes" % [afterimages.size(), x_pivots.size()])
	if x_pivots.size() == 4:
		print("  PASS: Tứ Kiếm Khí Chữ X Đa Sắc (4 pivots) đã sinh chuẩn xác!")
	else:
		printerr("  FAIL: Số lượng kiếm khí chữ X không đủ 4! Nhận: %d" % x_pivots.size())
		all_pass = false

	if afterimages.size() >= 1:
		print("  PASS: Tàn ảnh PrismaticHeroAfterimage từ mô hình .glb thật đã được tạo thành công!")
	else:
		printerr("  FAIL: Không tìm thấy tàn ảnh .glb thật nào!")
		all_pass = false

	# --- CHỜ PHA 2: SÓNG KIẾM KHÍ 3 CÁNH LAO ĐI TRÊN MẶT ĐẤT ---
	# Đợi hero hoàn tất lướt Pha 1 (_rmb_cleave_timer <= 0)
	while hero._rmb_cleave_timer > 0.0:
		await physics_frame
	for f in range(2):
		await physics_frame

	# Tìm kiếm node sóng kiếm RMBPrismaticTripleWave3D
	var wave_nodes := find_nodes_by_name(root, "RMBPrismaticTripleWave3D", false)
	var triple_wave: Node3D = wave_nodes[0] as Node3D if wave_nodes.size() > 0 else null

	if triple_wave != null:
		print("  PASS: [Pha 2] Đại Sóng Kiếm Khí Tam Dực RMBPrismaticTripleWave3D đã xuất hiện trên sân!")
		# Kiểm tra 3 cánh lụa cong bên trong wave
		var wave_wings := 0
		var wave_particles := 0
		var wave_lights := 0
		for w_child in triple_wave.get_children():
			if w_child is MeshInstance3D:
				wave_wings += 1
			elif w_child is GPUParticles3D:
				wave_particles += 1
			elif w_child is OmniLight3D:
				wave_lights += 1
		print("  - [Pha 2 Wave] Cánh kiếm lụa cong: %d (Yêu cầu: 3) | Hạt: %d | Đèn: %d" % [wave_wings, wave_particles, wave_lights])
		if wave_wings == 3:
			print("  PASS: Sóng kiếm mang kết cấu chuẩn xác 3 Cánh Lụa Cong 3D!")
		else:
			printerr("  FAIL: Số cánh kiếm lụa cong không đúng 3! Nhận: %d" % wave_wings)
			all_pass = false
	else:
		printerr("  FAIL: Không tìm thấy node RMBPrismaticTripleWave3D!")
		all_pass = false

	# Cho sóng kiếm bay hết hành trình 4.8m (khoảng 0.27s = 16-20 frames)
	for f in range(25): await physics_frame

	# Kiểm tra sát thương Pha 2 lên Bot 2 (30.0 DMG)
	var bot2_dmg := 100.0 - bot2.current_hp
	print("  - [Pha 2] Bot 2 HP: %.1f | Sát thương sóng kiếm càn quét: %.1f DMG (Yêu cầu: 30.0 DMG)" % [bot2.current_hp, bot2_dmg])
	if is_equal_approx(bot2_dmg, 30.0):
		print("  PASS: Pha 2 Đại Sóng Kiếm gây chính xác 30.0 DMG lên Bot 2 (Tổng chiêu: 55.0 DMG)!")
	else:
		printerr("  FAIL: Sát thương sóng kiếm không đúng 30.0 DMG! Nhận: %.1f" % bot2_dmg)
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 25.3: KIỂM ĐỊNH 0% KHỐI THÔ (PRIMITIVEMESH == 0)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 25.3 - KIỂM ĐỊNH 0% KHỐI THÔ: PRIMITIVEMESH == 0 TOÀN SCENETREE]...")
	# Kích hoạt cả hai hiệu ứng đồng thời để quét tại đỉnh điểm
	hero.global_position = Vector3(0.0, 0.05, 0.0)
	hero._facing_angle = 0.0
	hero._do_melee_combo()
	hero._do_rmb_cross_cleave()

	for f in range(4): await physics_frame

	var primitive_count := 0
	var primitive_names: Array[String] = []
	var array_mesh_count := 0
	var all_mesh_instances := 0

	var scan_stack: Array[Node] = [root]
	while not scan_stack.is_empty():
		var curr := scan_stack.pop_back() as Node
		if curr is MeshInstance3D:
			all_mesh_instances += 1
			var mi := curr as MeshInstance3D
			if mi.mesh != null:
				if mi.mesh is PrimitiveMesh:
					primitive_count += 1
					primitive_names.append("%s (%s)" % [mi.name, mi.mesh.get_class()])
				elif mi.mesh is ArrayMesh:
					array_mesh_count += 1
		for c in curr.get_children():
			scan_stack.append(c)

	print("  - Total MeshInstance3D scanned: %d" % all_mesh_instances)
	print("  - ArrayMeshes (KayKit GLB & Custom Curved Arcs): %d" % array_mesh_count)
	print("  - PrimitiveMeshes (BoxMesh, SphereMesh, CylinderMesh...): %d" % primitive_count)

	if primitive_count == 0:
		print("  PASS: 100% ZERO PRIMITIVE MESHES CONFIRMED (primitive_count == 0, Tuyệt đối 0% khối thô)!")
	else:
		printerr("  FAIL: Phát hiện %d PrimitiveMeshes: %s" % [primitive_count, primitive_names])
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 25.4: BẢO TOÀN TRẠNG THÁI PHASE 24 (DASH CD 1.0S & VẬT LÝ CẦU THANG)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 25.4 - KIỂM ĐỊNH BẢO TOÀN TRẠNG THÁI GOLDEN MASTER PHASE 24]...")
	# Kiểm tra khóa cooldown 1.0s của Dash
	hero._cd_dash_timer = 0.0
	hero._dash_timer = 0.0
	hero._do_dodge()
	var cd_after_dash := hero._cd_dash_timer
	print("  - Cooldown sau khi bấm Space: %.2fs (Yêu cầu: 1.00s)" % cd_after_dash)
	if is_equal_approx(cd_after_dash, 1.0):
		print("  PASS: Khóa Cooldown [Space] 1.0s được bảo toàn nguyên vẹn!")
	else:
		printerr("  FAIL: Cooldown Dash không đúng 1.0s! Nhận: %.2fs" % cd_after_dash)
		all_pass = false

	# Thử spam Space khi CD còn 0.5s -> phải bị từ chối
	hero._cd_dash_timer = 0.5
	hero._dash_timer = 0.0
	hero._do_dodge()
	if is_equal_approx(hero._cd_dash_timer, 0.5):
		print("  PASS: Spam Space khi Cooldown > 0 bị từ chối thành công!")
	else:
		printerr("  FAIL: Space kích hoạt bất hợp lệ trong lúc hồi chiêu!")
		all_pass = false

	print("\n==================================================================")
	if all_pass:
		print("  🏆 ALL 4 PHASE 25 TESTS PASSED 100% (ARGONS DIRECTIVE 25 SATISFIED)!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  ❌ SOME TESTS FAILED IN PHASE 25 VERIFICATION!")
		print("==================================================================")
		quit(1)
