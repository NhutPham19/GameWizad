extends SceneTree

# ==============================================================================
# TEST PHASE 24: ARGONS DIRECTIVE 24 VERIFICATION SUITE
# 3 BÀI TEST NGHIÊM NGẶT:
#   [TEST 24.1]: Space Dash 1.0s Cooldown Anti-Spam
#   [TEST 24.2]: Zero Stair Side Clipping & Zero Corner Jitter across All 6 Stair Sides
#   [TEST 24.3]: Smooth Center Stair Walk & Dash Up/Down (Y >= 1.6m in 1 Dash) + 0 Primitive Meshes
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const KayKitArenaBuilder = preload("res://scripts/levels/kaykit_arena_builder.gd")
const StrictQAHUD = preload("res://scripts/ui/strict_qa_hud.gd")

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 24: DASH CD 1.0S & BULLETPROOF STAIRS VERIFICATION")
	print("==================================================================")

	var scene_res := load("res://scenes/levels/kaykit_multitier_arena.tscn") as PackedScene
	if not scene_res:
		printerr("FAIL: Cannot load arena scene!")
		quit(1)
		return

	var arena := scene_res.instantiate()
	root.add_child(arena)

	for f in range(6):
		await process_frame

	var hero := arena.get_node_or_null("HeroKnight3D") as HeroKnight3D
	if not hero:
		printerr("FAIL: HeroKnight3D not found!")
		quit(1)
		return

	var hud := arena.get_node_or_null("StrictQAHUD") as StrictQAHUD
	if not hud:
		printerr("FAIL: StrictQAHUD not found!")
		quit(1)
		return

	var all_pass := true

	# --------------------------------------------------------------------------
	# TEST 24.1: SPACE DASH 1.0S COOLDOWN ANTI-SPAM
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 24.1 - KHÓA SPAM NÚT SPACE VỚI COOLDOWN 1.0S]...")

	# 1. Ban đầu _cd_dash_timer = 0
	hero._cd_dash_timer = 0.0
	hero._dash_timer = 0.0
	hero._action_lock_timer = 0.0
	hero.external_move_dir = Vector3(0.0, 0.0, -1.0)

	# 2. Bấm Space lần 1 tại t = 0.0s
	hero._do_dodge()
	print("  - Lần 1 (t=0.0s) kích hoạt Dash: _cd_dash_timer = %.2fs, _dash_timer = %.2fs" % [hero._cd_dash_timer, hero._dash_timer])
	if absf(hero._cd_dash_timer - 1.0) < 0.05 and hero._dash_timer > 0.0:
		print("  PASS: Dash lần 1 kích hoạt thành công, _cd_dash_timer = 1.0s")
	else:
		printerr("  FAIL: Dash lần 1 không đặt đúng _cd_dash_timer = 1.0s (nhận: %.2f)" % hero._cd_dash_timer)
		all_pass = false

	# 3. Giả lập spam Space tại t = 0.40s
	hero._cd_dash_timer = 0.60
	hero._dash_timer = 0.0 # Hết thời lượng lướt nhưng CD vẫn còn 0.60s
	var cd_before := hero._cd_dash_timer
	hero._do_dodge() # Cố gắng kích hoạt lại
	if absf(hero._cd_dash_timer - cd_before) < 0.01 and hero._dash_timer == 0.0:
		print("  PASS: Spam Space tại t = 0.40s (CD còn %.2fs) bị từ chối thành công!" % hero._cd_dash_timer)
	else:
		printerr("  FAIL: Spam Space tại t = 0.40s không bị chặn!")
		all_pass = false

	# 4. Giả lập spam Space tại t = 0.65s
	hero._cd_dash_timer = 0.35
	hero._do_dodge()
	if hero._cd_dash_timer <= 0.36 and hero._dash_timer == 0.0:
		print("  PASS: Spam Space tại t = 0.65s (CD còn %.2fs) bị từ chối thành công!" % hero._cd_dash_timer)
	else:
		printerr("  FAIL: Spam Space tại t = 0.65s không bị chặn!")
		all_pass = false

	# 5. Giả lập spam Space tại t = 0.85s
	hero._cd_dash_timer = 0.15
	hero._do_dodge()
	if hero._cd_dash_timer <= 0.16 and hero._dash_timer == 0.0:
		print("  PASS: Spam Space tại t = 0.85s (CD còn %.2fs) bị từ chối thành công!" % hero._cd_dash_timer)
	else:
		printerr("  FAIL: Spam Space tại t = 0.85s không bị chặn!")
		all_pass = false

	# 6. Tại t = 1.05s (CD đếm xong về 0.0s), bấm Space lần 2
	hero._cd_dash_timer = 0.0
	hero._do_dodge()
	print("  - Lần 2 (t=1.05s, CD=0.0s): _cd_dash_timer = %.2fs, _dash_timer = %.2fs" % [hero._cd_dash_timer, hero._dash_timer])
	if absf(hero._cd_dash_timer - 1.0) < 0.05 and hero._dash_timer > 0.0:
		print("  PASS: Dash lần 2 sau khi hết hồi chiêu kích hoạt thành công!")
	else:
		printerr("  FAIL: Dash lần 2 không kích hoạt được sau khi hết CD!")
		all_pass = false

	# 7. Kiểm tra HUD Cooldown Label hiển thị [Space] Lướt
	hud._update_telemetry_display(0.016)
	var cd_label_text: String = hud.skill_cooldown_label.text if hud.skill_cooldown_label else ""
	print("  - HUD Cooldown Text: %s" % cd_label_text)
	if cd_label_text.contains("[Space] Lướt:"):
		print("  PASS: HUD Cooldown Bar hiển thị chính xác trạng thái [Space] Lướt!")
	else:
		printerr("  FAIL: HUD Cooldown Bar thiếu nhãn [Space] Lướt!")
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 24.2: ZERO STAIR SIDE CLIPPING & ZERO CORNER JITTER ACROSS ALL 6 SIDES
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 24.2 - ZERO LỖI ĐI XUYÊN & 0% GIẬT GÓC TẠI TẤT CẢ CÁC SƯỜN CẦU THANG]...")

	# Đặt lại trạng thái tĩnh cho Hero
	hero._cd_dash_timer = 0.0
	hero._dash_timer = 0.0
	hero._action_lock_timer = 0.0
	hero.velocity = Vector3.ZERO

	# Danh sách các điểm kiểm tra ép vào sườn cầu thang & góc tường:
	# [Tên, Vị trí xuất phát, Hướng ép (Vector3), Tâm cầu thang X, Độ cao mong muốn Y, Giới hạn min_dist_x]
	var flank_tests := [
		{
			"name": "Cầu thang Tây - Sườn Ngoài Bên Trái (-X)",
			"start": Vector3(-9.5, 0.05, -13.8),
			"push_dir": Vector3(1.0, 0.0, 0.0),
			"center_x": -6.0,
			"expected_y": 0.05,
			"min_dist_x": 2.90
		},
		{
			"name": "Cầu thang Tây - Sườn Trong Bên Phải (+X)",
			"start": Vector3(-2.5, 0.05, -13.8),
			"push_dir": Vector3(-1.0, 0.0, 0.0),
			"center_x": -6.0,
			"expected_y": 0.05,
			"min_dist_x": 2.90
		},
		{
			"name": "Góc Giao Tường & Cầu thang Đông (Corner Wedge +X)",
			"start": Vector3(10.2, 0.05, -14.0),
			"push_dir": Vector3(0.0, 0.0, -1.0),
			"center_x": 6.0,
			"expected_y": 0.05,
			"min_dist_x": 2.90
		},
		{
			"name": "Cầu thang Đông - Sườn Trong Bên Trái (-X)",
			"start": Vector3(2.5, 0.05, -13.8),
			"push_dir": Vector3(1.0, 0.0, 0.0),
			"center_x": 6.0,
			"expected_y": 0.05,
			"min_dist_x": 2.90
		},
		{
			"name": "Cầu thang Đông - Sườn Ngoài Bên Phải (+X)",
			"start": Vector3(9.5, 0.05, -13.8),
			"push_dir": Vector3(-1.0, 0.0, 0.0),
			"center_x": 6.0,
			"expected_y": 0.05,
			"min_dist_x": 2.90
		},
		{
			"name": "Cầu thang Giữa Tầng 3 - Sườn Bên Trái (-X)",
			"start": Vector3(-3.5, 4.05, -26.0),
			"push_dir": Vector3(1.0, 0.0, 0.0),
			"center_x": 0.0,
			"expected_y": 4.05,
			"min_dist_x": 2.90
		},
		{
			"name": "Cầu thang Giữa Tầng 3 - Sườn Bên Phải (+X)",
			"start": Vector3(3.5, 4.05, -26.0),
			"push_dir": Vector3(-1.0, 0.0, 0.0),
			"center_x": 0.0,
			"expected_y": 4.05,
			"min_dist_x": 2.90
		}
	]

	for tc in flank_tests:
		hero.global_position = tc["start"]
		hero.velocity = Vector3.ZERO
		hero.external_move_dir = tc["push_dir"]

		var y_min := hero.global_position.y
		var y_max := hero.global_position.y

		# Chạy ép mạnh vào sườn/góc trong 60 frames vật lý
		for step in range(60):
			hero.velocity = tc["push_dir"] * 6.5
			hero._apply_stair_step_up(hero.velocity, 0.016)
			hero.move_and_slide()
			y_min = minf(y_min, hero.global_position.y)
			y_max = maxf(y_max, hero.global_position.y)
			await physics_frame

		var dist_x: float = absf(hero.global_position.x - tc["center_x"])
		var y_jitter: float = y_max - y_min
		var y_dev: float = absf(hero.global_position.y - tc["expected_y"])

		print("  - [%s]:" % tc["name"])
		print("    Final Pos: %s | dist_x_to_center = %.2fm | Y_jitter = %.4fm | Y_dev = %.4fm" % [hero.global_position, dist_x, y_jitter, y_dev])

		# Kiểm chứng 1: Dừng ở bên ngoài thành cầu thang (dist_x >= min_dist_x)
		if dist_x >= tc["min_dist_x"]:
			print("    PASS: Dừng bên ngoài thành cầu thang (dist_x = %.2fm >= %.2fm, 0%% xuyên thành!)" % [dist_x, tc["min_dist_x"]])
		else:
			printerr("    FAIL: Đi xuyên vào trong thành cầu thang! (dist_x = %.2fm < %.2fm)" % [dist_x, tc["min_dist_x"]])
			all_pass = false

		# Kiểm chứng 2: Độ cao Y giữ phẳng tuyệt đối (dao động < 0.005m, 0% nhấc chân hay giật khấc)
		if y_jitter < 0.005 and y_dev < 0.01:
			print("    PASS: Độ cao Y giữ phẳng tuyệt đối (Y = %.2fm, dao động = %.4fm < 0.005m, 0%% giật góc!)" % [hero.global_position.y, y_jitter])
		else:
			printerr("    FAIL: Bị nhấc chân hoặc giật góc (y_jitter = %.4fm, y_dev = %.4fm)" % [y_jitter, y_dev])
			all_pass = false

	hero.external_move_dir = Vector3.ZERO
	hero.velocity = Vector3.ZERO

	# --------------------------------------------------------------------------
	# TEST 24.3: SMOOTH CENTER STAIR WALK & DASH UP/DOWN + ZERO PRIMITIVE MESHES
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 24.3 - BƯỚC ĐI VÀ LƯỚT DASH THẲNG LÊN CẦU THANG MƯỢT MÀ]...")

	# 1. Đặt Hero ở chân cầu thang phía Tây (-6.0, 0.05, -11.0) ngay chính giữa lòng rãnh
	hero.global_position = Vector3(-6.0, 0.05, -11.0)
	hero.velocity = Vector3.ZERO
	hero._cd_dash_timer = 0.0
	hero._dash_timer = 0.0
	hero.external_move_dir = Vector3(0.0, 0.0, -1.0)

	var start_y: float = hero.global_position.y
	var start_z: float = hero.global_position.z

	# Kích hoạt cú lướt Dash lên cầu thang
	hero._do_dodge()

	# Chạy 35 frames để lướt lên dốc
	for step in range(35):
		hero.velocity = Vector3(0.0, 0.0, -1.0) * 14.5
		var slope_info := hero._detect_stair_slope_ahead(hero.velocity)
		if slope_info["on_stairs"]:
			var effective_speed := 14.5 * 0.88
			hero.velocity.x = 0.0
			hero.velocity.z = -effective_speed
			hero.velocity.y = clampf((slope_info["slope_dy"] / 0.85) * effective_speed, 4.0, effective_speed * 1.05)
			hero._apply_stair_step_up(hero.velocity, 0.016, true)
		hero.move_and_slide()
		await physics_frame

	var end_y: float = hero.global_position.y
	var end_z: float = hero.global_position.z
	var climb_h: float = end_y - start_y
	var advance_z: float = start_z - end_z

	print("  - Dash start: (Y=%.2f, Z=%.2f) | Dash end: (Y=%.2f, Z=%.2f)" % [start_y, start_z, end_y, end_z])
	print("  - Height climbed in 1 dash: %.2fm (Yêu cầu: >= 1.60m)" % climb_h)
	print("  - Forward advanced: %.2fm" % advance_z)

	if climb_h >= 1.60:
		print("  PASS: Hero lướt lên cầu thang mượt mà, đạt độ cao %.2fm (>= 1.60m) trong 1 cú lướt duy nhất!" % climb_h)
	else:
		printerr("  FAIL: Hero bị khựng chân thang! Chỉ đạt độ cao %.2fm (< 1.60m)" % climb_h)
		all_pass = false

	# 2. Kiểm tra Luật Thép: Tuyệt đối 0 Primitive Meshes (BoxMesh, SphereMesh, CylinderMesh, ...)
	var total_mesh_instances := 0
	var array_mesh_count := 0
	var primitive_count := 0
	var primitive_details: Array[String] = []

	var stack: Array[Node] = [arena]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr is MeshInstance3D:
			total_mesh_instances += 1
			var mi := curr as MeshInstance3D
			if mi.mesh is PrimitiveMesh:
				primitive_count += 1
				primitive_details.append("%s (%s)" % [mi.name, mi.mesh.get_class()])
			elif mi.mesh is ArrayMesh:
				array_mesh_count += 1
		for ch in curr.get_children():
			stack.push_back(ch)

	print("  - Total scanned meshes: %d | ArrayMeshes: %d | PrimitiveMeshes: %d" % [total_mesh_instances, array_mesh_count, primitive_count])
	if primitive_count == 0:
		print("  PASS: ZERO PRIMITIVE MESHES CONFIRMED (primitive_count == 0, 100%% KayKit GLB / Custom ArrayMesh)")
	else:
		printerr("  FAIL: PHÁT HIỆN %d PRIMITIVE MESHES TRONG SCENE: %s" % [primitive_count, primitive_details])
		all_pass = false

	# --------------------------------------------------------------------------
	# KẾT LUẬN TOÀN BỘ SUITE
	# --------------------------------------------------------------------------
	print("==================================================================")
	if all_pass:
		print("  🏆 ALL 3 TESTS PASSED 100% (ARGONS DIRECTIVE 24 SATISFIED)!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  ❌ AT LEAST ONE TEST FAILED IN PHASE 24!")
		print("==================================================================")
		quit(1)
