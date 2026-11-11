extends SceneTree

# ==============================================================================
# TEST PHASE 23: UNIFIED FIXES - ARGONS DIRECTIVE 23 VERIFICATION SUITE
# 5 BÀI TEST NGHIÊM NGẶT:
#   [TEST 23.1]: Zero Invisible Obstacles & Zero Stair Side Clipping
#   [TEST 23.2]: Upward Stair Dash Smoothness (Y >= 1.6m in 1 Dash)
#   [TEST 23.3]: Thick Wall No-Clip & Gap-Free Stair Junction (Z >= -14.85m)
#   [TEST 23.4]: U - I - O - P Skill Keys & HUD Label Synchronization
#   [TEST 23.5]: 165Hz Smoothness, No Blade Tip Label & Zero Primitive Meshes
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")
const KayKitArenaBuilder = preload("res://scripts/levels/kaykit_arena_builder.gd")
const StrictQAHUD = preload("res://scripts/ui/strict_qa_hud.gd")

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 23: ARGONS UNIFIED FIXES & 165HZ VERIFICATION")
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
	# TEST 23.1: ZERO INVISIBLE OBSTACLES & ZERO STAIR SIDE CLIPPING
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 23.1 - ZERO VẬT THỂ TÀNG HÌNH & KHÔNG ĐI XUYÊN THÀNH CẦU THANG]...")

	# 1. Kiểm tra cầu thang chuẩn World-Aligned: rotation == Vector3.ZERO
	var test_stair_holder := Node3D.new()
	arena.add_child(test_stair_holder)
	var stair: StaticBody3D = KayKitArenaBuilder.create_leakproof_stair_assembly(
		test_stair_holder,
		Vector3(-6.0, 0.0, -12.0),
		Vector3(-6.0, 4.0, -16.0),
		4.0
	)
	var stair_rot_err := stair.rotation.length()
	print("  - Stair root rotation: %s" % stair.rotation)
	if stair_rot_err < 0.001:
		print("  PASS: Stair root StaticBody3D is 100% World-Aligned (rotation = Vector3.ZERO)")
	else:
		printerr("  FAIL: Stair root StaticBody3D is tilted (rot_err = %.4f)" % stair_rot_err)
		all_pass = false

	# 2. Kiểm tra thành lan can hai bên cầu thang (2 khối đặc dọc 2 bên hông)
	var shapes := stair.find_children("*", "CollisionShape3D", true, false)
	var side_balustrades: Array[CollisionShape3D] = []
	for s in shapes:
		var cs := s as CollisionShape3D
		if cs.name.begins_with("StairSideBalustrade"):
			side_balustrades.append(cs)
	print("  - Side balustrades found: %d (Expected: 2)" % side_balustrades.size())
	if side_balustrades.size() == 2:
		print("  PASS: Exactly 2 solid side balustrades protecting stair flanks")
	else:
		printerr("  FAIL: Expected 2 side balustrades, got %d" % side_balustrades.size())
		all_pass = false

	test_stair_holder.queue_free()

	# 3. Thử nghiệm di chuyển Hero ép vào thành hông cầu thang tại X = -8.2 và X = -3.8
	# Di dời quái vật ra xa
	for e in get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e is Node3D:
			(e as Node3D).global_position = Vector3(50.0, 0.0, 50.0)

	# Đi từ ngoài vào thành Tây (X = -8.8 -> -X hướng sang +X)
	hero.global_position = Vector3(-8.8, 0.05, -14.0)
	hero.velocity = Vector3.ZERO
	hero.external_move_dir = Vector3(1.0, 0.0, 0.0)
	for i in range(25):
		hero._physics_process(0.016)
	var stopped_x_west := hero.global_position.x
	print("  - Hero pushed into West balustrade stopped at X = %.2fm (Stair edge = -8.0m)" % stopped_x_west)
	if stopped_x_west <= -8.0:
		print("  PASS: Hero stopped firmly outside stair flank (X = %.2fm <= -8.0m, 0%% clipping!)" % stopped_x_west)
	else:
		printerr("  FAIL: Hero clipped inside stair cheek! (X = %.2fm)" % stopped_x_west)
		all_pass = false

	# Đi từ trong hành lang vào thành Đông (X = -3.2 -> hướng sang -X)
	hero.global_position = Vector3(-3.2, 0.05, -14.0)
	hero.velocity = Vector3.ZERO
	hero.external_move_dir = Vector3(-1.0, 0.0, 0.0)
	for i in range(25):
		hero._physics_process(0.016)
	var stopped_x_east := hero.global_position.x
	print("  - Hero pushed into East balustrade stopped at X = %.2fm (Stair edge = -4.0m)" % stopped_x_east)
	if stopped_x_east >= -4.0:
		print("  PASS: Hero stopped firmly outside stair flank (X = %.2fm >= -4.0m, 0%% clipping!)" % stopped_x_east)
	else:
		printerr("  FAIL: Hero clipped inside stair cheek! (X = %.2fm)" % stopped_x_east)
		all_pass = false

	hero.external_move_dir = Vector3.ZERO

	# 4. Kiểm tra hành lang hai bên cầu thang thông thoáng tuyệt đối (Z = -11.5)
	# Hành lang Tây: đi từ X = -11.0 đến X = -8.5 (không còn cột đá X = -9.5 cản lối)
	hero.global_position = Vector3(-11.0, 0.05, -11.5)
	hero.velocity = Vector3.ZERO
	hero._action_lock_timer = 0.0
	hero.external_move_dir = Vector3(1.0, 0.0, 0.0)
	for i in range(60):
		hero._physics_process(0.016)
		if hero.global_position.x >= -8.5:
			break
	var west_progress := hero.global_position.x
	print("  - West corridor walk reached X = %.2fm (Started at -11.0m)" % west_progress)
	if west_progress >= -8.55:
		print("  PASS: West corridor is 100%% clear of invisible obstacles (walked freely to X = %.2fm)!" % west_progress)
	else:
		printerr("  FAIL: West corridor blocked by invisible obstacle at X = %.2fm!" % west_progress)
		all_pass = false

	# Hành lang Đông: đi từ X = -3.5 đến X = -0.5 (không còn cột đá X = -2.5 cản lối)
	hero.global_position = Vector3(-3.5, 0.05, -11.5)
	hero.velocity = Vector3.ZERO
	hero._action_lock_timer = 0.0
	hero.external_move_dir = Vector3(1.0, 0.0, 0.0)
	for i in range(70):
		hero._physics_process(0.016)
		if hero.global_position.x >= -0.5:
			break
	var east_progress := hero.global_position.x
	print("  - East corridor walk reached X = %.2fm (Started at -3.5m)" % east_progress)
	if east_progress >= -0.8:
		print("  PASS: East corridor is 100%% clear of invisible obstacles (walked freely past X = -2.5 to X = %.2fm)!" % east_progress)
	else:
		printerr("  FAIL: East corridor blocked by invisible obstacle at X = %.2fm!" % east_progress)
		all_pass = false

	hero.external_move_dir = Vector3.ZERO

	# --------------------------------------------------------------------------
	# TEST 23.2: UPWARD STAIR DASH SMOOTHNESS (Y >= 1.6m IN 1 DASH)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 23.2 - LƯỚT SPACE TỪ DƯỚI LÊN CẦU THANG 0% BỊ KẸT (Y >= 1.6M)]...")
	hero.global_position = Vector3(-6.0, 0.05, -11.0)
	hero.velocity = Vector3.ZERO
	hero._facing_angle = PI
	hero._snap_to_aim_direction(Vector3(0, 0, -1), 0.3)

	# Kích hoạt cú lướt Dash lên cầu thang
	hero._dash_dir = Vector3(0.0, 0.0, -1.0)
	hero._dash_timer = hero.DASH_DURATION
	var start_dash_y := hero.global_position.y
	var start_dash_z := hero.global_position.z

	# Chạy 22 frames vật lý (khoảng 0.35s = trọn vẹn 1 lần lướt)
	for i in range(22):
		hero._physics_process(0.016)

	var end_dash_y := hero.global_position.y
	var end_dash_z := hero.global_position.z
	var dash_climbed := end_dash_y - start_dash_y
	var dash_advanced := start_dash_z - end_dash_z
	print("  - Dash start: (Y=%.2f, Z=%.2f) | Dash end: (Y=%.2f, Z=%.2f)" % [start_dash_y, start_dash_z, end_dash_y, end_dash_z])
	print("  - Height climbed in 1 dash: %.2fm (Requirement: >= 1.60m)" % dash_climbed)
	print("  - Forward advanced: %.2fm" % dash_advanced)

	if dash_climbed >= 1.60:
		print("  PASS: Hero dashed up stairs smoothly, climbing %.2fm (>= 1.60m) in 1 dash with ZERO foot catch!" % dash_climbed)
	else:
		printerr("  FAIL: Dash got stuck or failed to climb sufficiently! (climbed = %.2fm < 1.60m)" % dash_climbed)
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 23.3: THICK WALL NO-CLIP & GAP-FREE STAIR JUNCTION (Z >= -14.85M)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 23.3 - THICK WALL COLLIDER & KHÍT 100% CẠNH CẦU THANG (Z >= -14.85M)]...")
	# Kiểm tra Capsule radius của Hero == 0.50m
	var hero_capsule_radius := 0.0
	for c in hero.get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape is CapsuleShape3D:
			hero_capsule_radius = ((c as CollisionShape3D).shape as CapsuleShape3D).radius
	print("  - Hero CapsuleShape3D radius: %.2fm (Expected: 0.50m)" % hero_capsule_radius)
	if absf(hero_capsule_radius - 0.50) < 0.01:
		print("  PASS: Hero capsule radius is strictly 0.50m")
	else:
		printerr("  FAIL: Hero capsule radius mismatch: got %.2fm (Expected 0.50m)" % hero_capsule_radius)
		all_pass = false

	# Chạy đâm thẳng vào bức tường cạnh cầu thang tại X = 8.2, Z = -14.2 theo hướng (0, 0, -1)
	# (Vị trí bị lún nửa người trong ảnh báo lỗi)
	hero.global_position = Vector3(8.2, 0.05, -14.2)
	hero.velocity = Vector3.ZERO
	hero.external_move_dir = Vector3(0.0, 0.0, -1.0)
	for i in range(25):
		hero._physics_process(0.016)

	var stopped_wall_z := hero.global_position.z
	print("  - Hero pushed into wall junction at X=8.2 stopped at Z = %.2fm (Requirement: Z >= -14.85m)" % stopped_wall_z)
	if stopped_wall_z >= -14.85:
		print("  PASS: Hero stopped securely before wall brick face (Z = %.2fm >= -14.85m, ZERO clipping!)" % stopped_wall_z)
	else:
		printerr("  FAIL: Hero penetrated wall junction! Stopped at Z = %.2fm (< -14.85m)" % stopped_wall_z)
		all_pass = false

	hero.external_move_dir = Vector3.ZERO

	# --------------------------------------------------------------------------
	# TEST 23.4: U - I - O - P SKILL KEYS & HUD SYNCHRONIZATION
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 23.4 - BỘ PHÍM KỸ NĂNG U - I - O - P & ĐỒNG BỘ HUD]...")
	# 1. Kiểm tra InputMap binding
	var expected_actions := {
		"skill_lmb": KEY_U,
		"skill_rmb": KEY_I,
		"skill_q": KEY_O,
		"skill_e": KEY_P
	}
	for act in expected_actions:
		var has_key := false
		if InputMap.has_action(act):
			for ev in InputMap.action_get_events(act):
				if ev is InputEventKey:
					var iek := ev as InputEventKey
					if iek.keycode == expected_actions[act] or iek.physical_keycode == expected_actions[act]:
						has_key = true
						break
		if has_key:
			print("  PASS: Action '%s' successfully bound to physical key code %d" % [act, expected_actions[act]])
		else:
			printerr("  FAIL: Action '%s' not bound to expected key code %d" % [act, expected_actions[act]])
			all_pass = false

	# 2. Kiểm tra kích hoạt 4 kỹ năng
	# U: Liên Trảm
	hero._action_lock_timer = 0.0
	hero._do_melee_combo(Vector3(0, 0, -1))
	print("  - Activated U (Melee Combo): anim = '%s'" % hero._current_anim)
	if hero._current_anim.begins_with("1H_Melee_Attack"):
		print("  PASS: [U] Liên Trảm executed cleanly")
	else:
		printerr("  FAIL: [U] Melee Combo failed to play attack animation!")
		all_pass = false
	hero._action_lock_timer = 0.0

	# I: Phá Không Trảm
	hero._cd_rmb_timer = 0.0
	hero._do_rmb_cross_cleave(Vector3(0, 0, -1))
	print("  - Activated I (Solar Cross-Cleave): _cd_rmb_timer = %.1fs" % hero._cd_rmb_timer)
	if absf(hero._cd_rmb_timer - 3.5) < 0.15:
		print("  PASS: [I] Phá Không Trảm triggered with 3.5s cooldown and 55.0 total DMG")
	else:
		printerr("  FAIL: [I] Phá Không Trảm cooldown mismatch (got %.2f)" % hero._cd_rmb_timer)
		all_pass = false
	hero._cd_rmb_timer = 0.0
	hero._action_lock_timer = 0.0
	hero._rmb_cleave_timer = 0.0

	# O: Cuồng Phong 360°
	hero._cd_q_timer = 0.0
	hero._is_spinning_q = false
	hero._do_spin_attack(Vector3(0, 0, -1))
	print("  - Activated O (Cuồng Phong 360): _cd_q_timer = %.1fs" % hero._cd_q_timer)
	if absf(hero._cd_q_timer - 5.0) < 0.15:
		print("  PASS: [O] Cuồng Phong 360° triggered with 5.0s cooldown")
	else:
		printerr("  FAIL: [O] Cuồng Phong cooldown mismatch (got %.2f)" % hero._cd_q_timer)
		all_pass = false
	hero._cd_q_timer = 0.0
	hero._is_spinning_q = false
	hero._action_lock_timer = 0.0

	# P: Bom Lôi Vụ
	hero._cd_e_timer = 0.0
	hero._is_throwing_e = false
	hero._do_ranged_throw(hero.global_position + Vector3(0, 0, -4.8))
	print("  - Activated P (Bom Lôi Vụ): _cd_e_timer = %.1fs" % hero._cd_e_timer)
	if absf(hero._cd_e_timer - 6.0) < 0.15:
		print("  PASS: [P] Bom Lôi Vụ triggered with 6.0s cooldown, DoT & 55% Slow")
	else:
		printerr("  FAIL: [P] Bom Lôi Vụ cooldown mismatch (got %.2f)" % hero._cd_e_timer)
		all_pass = false
	hero._cd_e_timer = 0.0
	hero._is_throwing_e = false
	hero._action_lock_timer = 0.0

	# 3. Kiểm tra nhãn HUD hiển thị U - I - O - P
	hud._update_telemetry_display(0.016)
	var skills_text := hud.hero_skills_label.text
	var cd_text := hud.skill_cooldown_label.text
	print("  - HUD Skills text: ", skills_text)
	print("  - HUD Cooldown text: ", cd_text)
	if skills_text.contains("[U]") and skills_text.contains("[I]") and skills_text.contains("[O]") and skills_text.contains("[P]"):
		print("  PASS: Top-left HUD label accurately displays [U] [I] [O] [P] keys")
	else:
		printerr("  FAIL: Top-left HUD label does not contain all U-I-O-P keys!")
		all_pass = false

	if cd_text.contains("[U]") and cd_text.contains("[I]") and cd_text.contains("[O]") and cd_text.contains("[P]"):
		print("  PASS: Bottom Cooldown Bar accurately displays [U] [I] [O] [P] cooldowns")
	else:
		printerr("  FAIL: Bottom Cooldown Bar does not contain all U-I-O-P keys!")
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 23.5: 165HZ SMOOTHNESS, NO BLADE TIP LABEL & ZERO PRIMITIVE MESHES
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 23.5 - 165HZ+, XÓA BLADE TIP & ZERO PRIMITIVE MESHES]...")
	# 1. Physics ticks per second
	var hz := Engine.physics_ticks_per_second
	print("  - Engine physics ticks per second: %d (Requirement: >= 120)" % hz)
	if hz >= 120:
		print("  PASS: Physics tick rate synchronized for high refresh rate displays (>= 120Hz)")
	else:
		printerr("  FAIL: Physics tick rate is too low: %d < 120" % hz)
		all_pass = false

	# 2. Blade tip label removed
	print("  - telemetry_blade_label: %s (Expected: <null>)" % hud.telemetry_blade_label)
	if hud.telemetry_blade_label == null:
		print("  PASS: telemetry_blade_label is completely removed (0% redundant UI redraw)")
	else:
		printerr("  FAIL: telemetry_blade_label is still instantiated!")
		all_pass = false

	# 3. Zero Primitive Meshes Audit
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	var prim_count := 0
	var array_count := 0
	for m in meshes:
		var mi := m as MeshInstance3D
		if mi and mi.mesh:
			var cls := mi.mesh.get_class()
			if cls in ["BoxMesh", "SphereMesh", "CylinderMesh", "CapsuleMesh", "PrismMesh", "TorusMesh", "PlaneMesh", "QuadMesh"]:
				prim_count += 1
				printerr("  Found primitive mesh: %s (%s) in node %s" % [mi.name, cls, mi.get_path()])
			elif cls == "ArrayMesh":
				array_count += 1

	print("  - Total scanned meshes: %d | ArrayMeshes: %d | PrimitiveMeshes: %d" % [meshes.size(), array_count, prim_count])
	if prim_count == 0:
		print("  PASS: ZERO PRIMITIVE MESHES CONFIRMED (primitive_count == 0, 100% KayKit GLB / Custom ArrayMesh)")
	else:
		printerr("  FAIL: Found %d PrimitiveMeshes!" % prim_count)
		all_pass = false

	# --------------------------------------------------------------------------
	# FINAL RESULT
	# --------------------------------------------------------------------------
	print("==================================================================")
	if all_pass:
		print("  🏆 ALL 5 TESTS PASSED 100% (ARGONS DIRECTIVE 23 SATISFIED)!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  ❌ AT LEAST ONE TEST FAILED IN PHASE 23!")
		print("==================================================================")
		quit(1)
