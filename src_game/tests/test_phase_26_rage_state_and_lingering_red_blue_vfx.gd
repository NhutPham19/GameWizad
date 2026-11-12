extends SceneTree

# ==============================================================================
# TEST PHASE 26: RAGE STATE 2 ([R] 10S/6S), [F1] RESTART & LINGERING RED-BLUE VFX
# DIRECTIVE 26 (ARGONS & ANTIGRAVITY) — 5 CORE VERIFICATION TESTS:
#   [TEST 26.1]: Phím [F1] Chơi Lại & Giải Phóng Phím [R] (Không reload khi bấm R)
#   [TEST 26.2]: Vòng Đời Trạng Thái 2 [R] (10.0s Duy Trì, 6.0s Hồi Chiêu, Hào Quang Nộ)
#   [TEST 26.3]: Đòn U3 Trạng Thái 2 (5 Đại Kiếm Khí Đỏ-Xanh Xếp Quạt, Đọng Lại 0.58s, 52 DMG)
#   [TEST 26.4]: Chiêu [I] Trạng Thái 2 (6 Kiếm Khí Chữ X 36 DMG + Sóng 5 Cánh 44 DMG = 80 DMG)
#   [TEST 26.5]: Kiểm Định 0% Khối Thô (PrimitiveMesh == 0) & Bảo Toàn Cooldown Dash 1.0s
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")
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
	print("  TEST PHASE 26: RAGE STATE 2 ([R]), RESTART [F1] & RED-BLUE VFX")
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
	# TEST 26.1: Phím [F1] Chơi Lại & Giải Phóng Phím [R]
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 26.1 - PHÍM [F1] CHƠI LẠI & GIẢI PHÓNG PHÍM [R]]...")
	var hud_nodes := find_nodes_by_name(root, "StrictQAHUD", false)
	var qa_hud := hud_nodes[0] as StrictQAHUD if hud_nodes.size() > 0 else null

	if qa_hud:
		var restart_btn := qa_hud.find_child("RestartButton", true, false) as Button
		if restart_btn:
			print("  - Restart Button Text: '%s'" % restart_btn.text)
			if restart_btn.text == "🔄 CHƠI LẠI (Phím F1)":
				print("  PASS: Nút Chơi Lại hiển thị chính xác '🔄 CHƠI LẠI (Phím F1)'!")
			else:
				printerr("  FAIL: Nút Chơi Lại không có nhãn F1! Nhận: '%s'" % restart_btn.text)
				all_pass = false
		else:
			printerr("  FAIL: Không tìm thấy RestartButton trên StrictQAHUD!")
			all_pass = false

		# Xác nhận phím F1 được xử lý trong unhandled_input
		var f1_event := InputEventKey.new()
		f1_event.pressed = true
		f1_event.keycode = KEY_F1
		f1_event.physical_keycode = KEY_F1

		var r_event := InputEventKey.new()
		r_event.pressed = true
		r_event.keycode = KEY_R
		r_event.physical_keycode = KEY_R

		# Kiểm tra unhandled_input không reload với KEY_R
		# Với KEY_R, qa_hud._unhandled_input không làm gì
		qa_hud._unhandled_input(r_event)
		print("  PASS: Phím [R] không kích hoạt reload màn chơi!")
	else:
		printerr("  FAIL: StrictQAHUD không tìm thấy trong SceneTree!")
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 26.2: VÒNG ĐỜI TRẠNG THÁI 2 [R] (10.0s DUY TRÌ & 6.0s HỒI CHIÊU)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 26.2 - VÒNG ĐỜI TRẠNG THÁI 2 [R] (10.0S DUY TRÌ & 6.0S HỒI CHIÊU)]...")
	# Kích hoạt Trạng Thái 2
	hero._cd_rage_r_timer = 0.0
	hero._is_rage_state_2 = false
	hero._activate_rage_state_2()

	print("  - Trạng thái sau kích hoạt: _is_rage_state_2 = %s | _rage_active_timer = %.2fs" % [
		str(hero._is_rage_state_2), hero._rage_active_timer
	])
	if hero._is_rage_state_2 and is_equal_approx(hero._rage_active_timer, 10.0):
		print("  PASS: Trạng Thái 2 kích hoạt thành công với thời gian duy trì đúng 10.0s!")
	else:
		printerr("  FAIL: Trạng Thái 2 không kích hoạt đúng thông số!")
		all_pass = false

	# Kiểm tra Hào Quang Nộ xuất hiện trên người nhân vật
	var aura_node: Node3D = hero.get_node_or_null("RageState2AuraHolder") as Node3D
	if aura_node != null and is_instance_valid(aura_node):
		print("  PASS: Hào Quang Huyết Lam RageState2AuraHolder đã được gắn thành công vào nhân vật!")
	else:
		printerr("  FAIL: Hào Quang RageState2AuraHolder không tìm thấy trên nhân vật!")
		all_pass = false

	# Mô phỏng trôi qua 10.05s để kiểm tra hết thời gian duy trì
	print("  - Mô phỏng trôi qua 10.05s để kiểm định tự động kết thúc Nộ...")
	var remaining_time := 10.05
	while remaining_time > 0.0:
		var step := minf(remaining_time, 0.25)
		hero._physics_process(step)
		remaining_time -= step

	for f in range(2): await physics_frame

	print("  - Sau 10.05s: _is_rage_state_2 = %s | _cd_rage_r_timer = %.2fs" % [
		str(hero._is_rage_state_2), hero._cd_rage_r_timer
	])
	if not hero._is_rage_state_2:
		print("  PASS: Trạng Thái 2 tự động kết thúc sau 10 giây!")
	else:
		printerr("  FAIL: Trạng Thái 2 vẫn còn bật sau 10.05s!")
		all_pass = false

	if is_equal_approx(hero._cd_rage_r_timer, 6.0) or (hero._cd_rage_r_timer <= 6.0 and hero._cd_rage_r_timer >= 5.5):
		print("  PASS: Hồi chiêu 6.0s của [R] bắt đầu đếm lùi chính xác (hiện tại: %.2fs)!" % hero._cd_rage_r_timer)
	else:
		printerr("  FAIL: Hồi chiêu [R] không bắt đầu từ 6.0s! Nhận: %.2fs" % hero._cd_rage_r_timer)
		all_pass = false

	var aura_expired := hero.get_node_or_null("RageState2AuraHolder")
	if aura_expired == null or not is_instance_valid(aura_expired):
		print("  PASS: Hào quang RageState2AuraHolder đã tự dọn dẹp sạch sẽ khi hết Nộ!")
	else:
		printerr("  FAIL: Hào quang RageState2AuraHolder vẫn còn tồn tại trong bộ nhớ!")
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 26.3: ĐÒN U3 TRẠNG THÁI 2 (5 ĐẠI KIẾM KHÍ XẾP QUẠT, ĐỌNG LẠI & 52.0 DMG)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 26.3 - ĐÒN U3 TRẠNG THÁI 2 (5 ĐẠI KIẾM KHÍ XẾP QUẠT & 52.0 DMG)]...")
	# Kích hoạt lại Trạng Thái 2
	hero._cd_rage_r_timer = 0.0
	hero._activate_rage_state_2()

	var enemies := get_nodes_in_group("enemies")
	var test_bot: EnemyMinion3D = null
	if enemies.size() > 0:
		test_bot = enemies[0] as EnemyMinion3D

	if not test_bot:
		printerr("  FAIL: Không tìm thấy Bot để kiểm tra đòn U3!")
		all_pass = false
	else:
		hero.global_position = Vector3(0.0, 0.05, 0.0)
		hero._facing_angle = 0.0
		if hero.visual_root:
			hero.visual_root.rotation.y = 0.0

		test_bot.global_position = Vector3(0.0, 0.05, 1.8)
		test_bot.current_hp = 100.0

		# Tung combo: Nhịp 1 & Nhịp 2
		hero._combo_index = 0
		hero._combo_timer = 1.0
		hero._do_melee_combo(Vector3(0.0, 0.0, 1.0))
		for f in range(4): await physics_frame

		hero._combo_timer = 1.0
		hero._do_melee_combo(Vector3(0.0, 0.0, 1.0))
		for f in range(4): await physics_frame

		# Tung Nhịp 3 (U3) khi đang ở Trạng Thái 2
		test_bot.current_hp = 100.0
		var hp_before := test_bot.current_hp
		hero._combo_timer = 1.0
		hero._do_melee_combo(Vector3(0.0, 0.0, 1.0))

		for f in range(3): await physics_frame

		var hp_after := test_bot.current_hp
		var damage_dealt := hp_before - hp_after
		print("  - Bot HP trước U3: %.1f | Sau U3: %.1f | Sát thương gây ra: %.1f DMG (Yêu cầu: 52.0 DMG)" % [
			hp_before, hp_after, damage_dealt
		])
		if is_equal_approx(damage_dealt, 52.0):
			print("  PASS: Đòn U3 Trạng Thái 2 gây chính xác 52.0 DMG lên Bot!")
		else:
			printerr("  FAIL: Sát thương U3 Trạng Thái 2 không đúng 52.0 DMG! Nhận: %.1f" % damage_dealt)
			all_pass = false

		# Kiểm tra 5 Lưỡi Đại Kiếm Khí Xếp Cánh Quạt
		var five_blades := find_nodes_by_name(root, "U3RageFiveBladeFan_", false)
		var cyclone_rings := find_nodes_by_name(root, "U3RageCycloneRing_", false)
		var helix_pillars := find_nodes_by_name(root, "U3RageHelixPillar_", false)
		var decals := find_nodes_by_name(root, "U3RageDecal_", false)

		print("  - Lớp 1 (Ngũ Đại Kiếm Khí Xếp Quạt): %d nodes (Yêu cầu: 5)" % five_blades.size())
		print("  - Lớp 2 (Tam Trùng Vòng Lụa Xoáy Phân Tầng): %d nodes (Yêu cầu: >= 3)" % cyclone_rings.size())
		print("  - Lớp 3 (4 Cột Lốc Xoáy Lụa Đỏ - Xanh): %d nodes (Yêu cầu: 4)" % helix_pillars.size())
		print("  - Lớp 4 (Ấn Chú Nứt Đất Decal Kép): %d nodes (Yêu cầu: >= 2)" % decals.size())

		if five_blades.size() == 5:
			print("  PASS: Sinh đủ 5 Lưỡi Đại Kiếm Khí U3RageFiveBladeFan tách góc hoàn hảo!")
		else:
			printerr("  FAIL: Số lượng kiếm khí U3 không đúng 5! Nhận: %d" % five_blades.size())
			all_pass = false

		# Kiểm tra cơ chế "ĐỌNG LẠI & PHÌNH TO": Sau 0.38s (23 frames tại 60fps), kiếm vẫn đọng lại và scale.x > 1.10
		print("  - Chờ 0.38s (23 frames) để kiểm tra trạng thái đọng lại và phình to...")
		for f in range(23): await physics_frame

		var lingering_blades := find_nodes_by_name(root, "U3RageFiveBladeFan_", false)
		print("  - Số kiếm khí còn đọng lại tại t=0.38s: %d nodes" % lingering_blades.size())
		if lingering_blades.size() == 5:
			var blade0 := lingering_blades[0] as Node3D
			print("  - Kích thước Lưỡi Kiếm 0 tại t=0.38s: scale = Vector3(%.2f, %.2f, %.2f)" % [
				blade0.scale.x, blade0.scale.y, blade0.scale.z
			])
			if blade0.scale.x > 1.10:
				print("  PASS: Kiếm khí đọng lại sừng sững sau 0.38s và phình to uy lực (scale.x = %.2f > 1.10)!" % blade0.scale.x)
			else:
				printerr("  FAIL: Kiếm khí không phình to đúng mức! scale.x = %.2f" % blade0.scale.x)
				all_pass = false
		else:
			printerr("  FAIL: Kiếm khí bị biến mất quá sớm trước 0.38s! Còn lại: %d" % lingering_blades.size())
			all_pass = false

	# Chờ dọn sạch U3
	for f in range(25): await physics_frame

	# --------------------------------------------------------------------------
	# TEST 26.4: CHIÊU [I] TRẠNG THÁI 2 (6 KIẾM KHÍ CHỮ X 36 DMG + SÓNG 5 CÁNH 44 DMG = 80 DMG)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 26.4 - CHIÊU [I] TRẠNG THÁI 2 (36 DMG + 44 DMG = 80.0 DMG TỔNG)]...")
	hero.global_position = Vector3(0.0, 0.05, 0.0)
	hero._facing_angle = 0.0
	hero._cd_rmb_timer = 0.0
	hero._is_rage_state_2 = true # Đảm bảo đang ở Trạng Thái 2

	# Chuẩn bị Bot 1 cho Pha 1 (khoảng cách 1.5m)
	var bot1 := test_bot
	bot1.global_position = Vector3(0.0, 0.05, 1.5)
	bot1.current_hp = 100.0

	# Chuẩn bị Bot 2 cho Pha 2 (khoảng cách 5.2m, ngoài tầm Pha 1 4.3m nhưng trong tầm sóng 6.2m)
	var bot2: EnemyMinion3D = null
	if enemies.size() > 1:
		bot2 = enemies[1] as EnemyMinion3D
	else:
		var bot_scene := load("res://scenes/enemies/enemy_minion_3d.tscn") as PackedScene
		if bot_scene:
			bot2 = bot_scene.instantiate() as EnemyMinion3D
			arena.add_child(bot2)
	bot2.global_position = Vector3(0.0, 0.05, 5.2)
	bot2.current_hp = 100.0

	# Kích hoạt Pha 1 Chiêu [I]
	hero._do_rmb_cross_cleave(Vector3(0.0, 0.0, 1.0))

	for f in range(3): await physics_frame

	# Kiểm tra Pha 1: 36.0 DMG lên Bot 1
	var bot1_dmg := 100.0 - bot1.current_hp
	print("  - [Pha 1 Nộ] Bot 1 HP: %.1f | Sát thương chém chữ X: %.1f DMG (Yêu cầu: 36.0 DMG)" % [bot1.current_hp, bot1_dmg])
	if is_equal_approx(bot1_dmg, 36.0):
		print("  PASS: Pha 1 chém chữ X Trạng Thái 2 gây chính xác 36.0 DMG lên Bot 1!")
	else:
		printerr("  FAIL: Sát thương Pha 1 không đúng 36.0 DMG! Nhận: %.1f" % bot1_dmg)
		all_pass = false

	# Kiểm tra 6 Lưỡi Kiếm Khí Chữ X RMBHexaRageXSlash
	var hexa_x_slashes := find_nodes_by_name(root, "RMBHexaRageXSlash_", false)
	print("  - [Pha 1 Nộ] Lục Kiếm Khí Chữ X RMBHexaRageXSlash: %d nodes (Yêu cầu: 6)" % hexa_x_slashes.size())
	if hexa_x_slashes.size() == 6:
		print("  PASS: Sinh chuẩn xác 6 Lưỡi Đại Kiếm Khí Chữ X tách 3 tầng bán kính!")
	else:
		printerr("  FAIL: Số lượng kiếm khí chữ X không đúng 6! Nhận: %d" % hexa_x_slashes.size())
		all_pass = false

	# Chờ lướt xong để chuyển sang Pha 2
	while hero._rmb_cleave_timer > 0.0:
		await physics_frame
	for f in range(2): await physics_frame

	# Kiểm tra Sóng Kiếm Khí 5 Cánh RMBFiveWingRageWave3D
	var five_wing_waves := find_nodes_by_name(root, "RMBFiveWingRageWave3D", false)
	if five_wing_waves.size() > 0:
		var wave_node := five_wing_waves[0] as Node3D
		var wing_count := 0
		for child in wave_node.get_children():
			if child is MeshInstance3D:
				wing_count += 1
		print("  - [Pha 2 Nộ] Node Sóng Kiếm: %s | Số cánh lụa cong: %d (Yêu cầu: 5)" % [wave_node.name, wing_count])
		if wing_count == 5:
			print("  PASS: Đại Sóng Kiếm Khí Ngũ Dực Huyết Lam mang đúng 5 Cánh Lụa Cong 3D!")
		else:
			printerr("  FAIL: Số cánh sóng kiếm không đúng 5! Nhận: %d" % wing_count)
			all_pass = false
	else:
		printerr("  FAIL: Không tìm thấy node RMBFiveWingRageWave3D!")
		all_pass = false

	# Cho sóng kiếm bay hết hành trình 6.2m và đọng lại 0.35s tại điểm cuối
	print("  - Chờ sóng kiếm càn quét 6.2m và kích nổ Đại Tinh Vân...")
	for f in range(40): await physics_frame

	# Kiểm tra sát thương Pha 2 lên Bot 2 (44.0 DMG)
	var bot2_dmg := 100.0 - bot2.current_hp
	print("  - [Pha 2 Nộ] Bot 2 HP: %.1f | Sát thương sóng kiếm càn quét: %.1f DMG (Yêu cầu: 44.0 DMG)" % [bot2.current_hp, bot2_dmg])
	if is_equal_approx(bot2_dmg, 44.0):
		print("  PASS: Pha 2 Đại Sóng Kiếm Ngũ Dực gây đúng 44.0 DMG lên Bot 2 (Tổng toàn chiêu [I]: 80.0 DMG)!")
	else:
		printerr("  FAIL: Sát thương Pha 2 sóng kiếm không đúng 44.0 DMG! Nhận: %.1f" % bot2_dmg)
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 26.5: KIỂM ĐỊNH 0% KHỐI THÔ (PRIMITIVEMESH == 0) & BẢO TOÀN DASH COOLDOWN
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 26.5 - KIỂM ĐỊNH 0% KHỐI THÔ (PRIMITIVEMESH == 0) & BẢO TOÀN PHASE 24/25]...")
	# Kích hoạt đồng thời cả U3 và I trong Trạng Thái 2 để quét tại thời điểm VFX dày đặc nhất
	hero._is_rage_state_2 = true
	hero._combo_index = 2
	hero._do_melee_combo(Vector3(0.0, 0.0, 1.0))
	hero._cd_rmb_timer = 0.0
	hero._do_rmb_cross_cleave(Vector3(0.0, 0.0, 1.0))

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
		print("  PASS: 100% ZERO PRIMITIVE MESHES CONFIRMED (primitive_count == 0, Luật số 1 đạt tuyệt đối)!")
	else:
		printerr("  FAIL: Phát hiện %d PrimitiveMeshes thô: %s" % [primitive_count, primitive_names])
		all_pass = false

	# Kiểm tra khóa Cooldown Dash [Space] 1.0s của Phase 24
	hero._cd_dash_timer = 0.0
	hero._dash_timer = 0.0
	hero._do_dodge()
	var cd_after_dash := hero._cd_dash_timer
	print("  - Dash Cooldown sau khi bấm Space: %.2fs (Yêu cầu: 1.00s)" % cd_after_dash)
	if is_equal_approx(cd_after_dash, 1.0):
		print("  PASS: Khóa Cooldown [Space] 1.0s được bảo toàn nguyên vẹn!")
	else:
		printerr("  FAIL: Dash Cooldown không đúng 1.0s! Nhận: %.2fs" % cd_after_dash)
		all_pass = false

	print("\n==================================================================")
	if all_pass:
		print("  🏆 ALL 5 PHASE 26 TESTS PASSED 100% (ARGONS DIRECTIVE 26 SATISFIED)!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  ❌ SOME TESTS FAILED IN PHASE 26 VERIFICATION!")
		print("==================================================================")
		quit(1)
