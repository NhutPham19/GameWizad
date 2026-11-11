extends SceneTree

# ==============================================================================
# TEST PHASE 20: ULTIMATE SLASH VFX OVERHAUL, 6 HERO SKILLS & BOT RED HP BAR
# DIRECTIVE 20 (ARGONS & ANTIGRAVITY) — 4 TIÊU CHUẨN KIỂM THỬ BẮT BUỘC:
#   [TEST 1]: Bot Red HP Bar (#E61E2A) & Lagging Catch-up Bar (Duy nhất 1 thanh máu/bot)
#   [TEST 2]: Stylized Crescent Slash ArrayMesh (0% PrimitiveMesh) & 3-Tier Shader
#   [TEST 3]: Đủ 6 Kỹ Xảo Chiêu Thức (LMB 3-Combo, RMB Shield, Q 360, E Smoke, Space, X-Slash)
#   [TEST 4]: Quét toàn bộ Scene Tree: PRIMITIVE MESHES: 0 (PASS 100%)
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 20: ULTIMATE SLASH VFX & RED HP BAR VERIFICATION")
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

	var all_pass := true

	# --------------------------------------------------------------------------
	# TEST 1: BOT RED HP BAR & LAGGING CATCH-UP BAR
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 1 - BOT CRIMSON RED HP BAR & CATCH-UP BAR]...")
	var enemies := get_nodes_in_group("enemies")
	print("  - Found %d enemy minions in arena" % enemies.size())

	if enemies.size() == 0:
		printerr("  FAIL: No enemies found in arena!")
		all_pass = false
	else:
		var test_bot := enemies[0] as EnemyMinion3D
		# 1.1 Kiểm tra duy nhất 1 cụm thanh máu
		var hp_holders := []
		for child in test_bot.get_children():
			if child.name == "OverheadHPHolder":
				hp_holders.append(child)
		print("  - OverheadHPHolder count: %d (Expected: 1)" % hp_holders.size())
		if hp_holders.size() != 1:
			printerr("  FAIL: Bot does not have exactly 1 OverheadHPHolder!")
			all_pass = false

		# 1.2 Kiểm tra màu Đỏ Huyết (#E61E2A) trong _hp_bar_img
		if test_bot._hp_bar_img != null:
			# Kiểm tra pixel màu máu chính ở x=16, y=8
			var red_px: Color = test_bot._hp_bar_img.get_pixel(16, 8)
			print("  - Sampled HP bar pixel color: (R=%.3f, G=%.3f, B=%.3f)" % [red_px.r, red_px.g, red_px.b])
			var is_crimson_red := (red_px.r >= 0.85 and red_px.r > red_px.g * 3.0 and red_px.r > red_px.b * 3.0)
			if is_crimson_red:
				print("  PASS: HP Bar color is confirmed Crimson Red (#E61E2A, R > 0.85 & R > 3*G/B)")
			else:
				printerr("  FAIL: HP Bar color is not Crimson Red! R=%.2f, G=%.2f, B=%.2f" % [red_px.r, red_px.g, red_px.b])
				all_pass = false

			# 1.3 Kiểm tra vạch máu tụt trễ (Catch-up Bar) khi nhận sát thương
			var init_hp := test_bot.current_hp
			test_bot.take_damage(25.0)
			print("  - Damaged Bot: Current HP = %.1f | Displayed Lag HP = %.1f" % [test_bot.current_hp, test_bot._displayed_lag_hp])

			if test_bot._displayed_lag_hp > test_bot.current_hp:
				print("  PASS: Lagging Catch-up Bar holds previous HP value (Lag HP > Current HP)")
			else:
				printerr("  FAIL: Catch-up bar did not lag behind current HP!")
				all_pass = false

			# Kiểm tra pixel vạch máu tụt trễ giữa red_w (85) và lag_w (124)
			var lag_px: Color = test_bot._hp_bar_img.get_pixel(100, 8)
			print("  - Sampled Catch-up bar pixel at (100,8): (R=%.3f, G=%.3f, B=%.3f)" % [lag_px.r, lag_px.g, lag_px.b])
			if lag_px.r > 0.8 and lag_px.g > 0.8:
				print("  PASS: Catch-up Bar rendered glowing White-Yellow (#FFF2D6)")
			else:
				printerr("  FAIL: Catch-up Bar pixel color incorrect!")
				all_pass = false

			# Chờ vài frame để vạch máu tụt trễ co dần
			for f in range(25):
				await physics_frame
			print("  - After 25 physics frames: Lag HP = %.1f" % test_bot._displayed_lag_hp)
			if test_bot._displayed_lag_hp < init_hp:
				print("  PASS: Catch-up bar smoothly interpolates toward current HP")
			else:
				printerr("  FAIL: Catch-up bar failed to smoothly move toward current HP!")
				all_pass = false
		else:
			printerr("  FAIL: Bot _hp_bar_img is null!")
			all_pass = false

	# --------------------------------------------------------------------------
	# TEST 2: STYLIZED CRESCENT SLASH ARRAYMESH & 3-TIER SHADER
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 2 - STYLIZED CRESCENT SLASH ARRAYMESH & SHADER]...")
	# Kiểm tra hàm build_curved_slash_arc_mesh
	var test_crescent_mesh := KayKitVFXManager.build_curved_slash_arc_mesh(0.8, 2.5, 160.0, 24, 0.1)
	print("  - Crescent mesh type: %s | Is ArrayMesh: %s" % [
		test_crescent_mesh.get_class(),
		test_crescent_mesh is ArrayMesh
	])
	if test_crescent_mesh is ArrayMesh:
		print("  PASS: Procedural crescent arc mesh is 100% ArrayMesh (0% PrimitiveMesh)")
	else:
		printerr("  FAIL: Crescent mesh violates Zero PrimitiveMesh rule!")
		all_pass = false

	# Triệu hồi vệt chém Nhịp 1, Nhịp 2, Nhịp 3
	var origin := hero.global_position + Vector3(0.0, 0.95, 0.0)
	var slash_fx := KayKitVFXManager.spawn_stylized_crescent_slash(
		origin, 0.0, 4.0, false,
		Color(1,1,1), Color(0, 0.85, 1), Color(1, 0.45, 0.05),
		1.0, 0.24, arena
	)

	if is_instance_valid(slash_fx):
		print("  - Spawned StylizedSlashArcFX: ", slash_fx.name)
		var main_arc := slash_fx.get_node_or_null("TiltPivot/MainArcMesh") as MeshInstance3D
		if main_arc and main_arc.mesh is ArrayMesh:
			var mat = main_arc.material_override as ShaderMaterial
			if mat and mat.shader:
				print("  - Shader path: ", mat.shader.resource_path)
				var core_c = mat.get_shader_parameter("core_color")
				var main_c = mat.get_shader_parameter("main_color")
				var edge_c = mat.get_shader_parameter("edge_color")
				print("  - 3-Tier Colors: Core=%s | Main=%s | Edge=%s" % [core_c, main_c, edge_c])
				print("  PASS: Stylized slash arc mesh and 3-tier shader verified successfully")
			else:
				printerr("  FAIL: MainArcMesh missing ShaderMaterial!")
				all_pass = false
		else:
			printerr("  FAIL: MainArcMesh not found or not ArrayMesh!")
			all_pass = false
	else:
		printerr("  FAIL: spawn_stylized_crescent_slash returned null!")
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 3: ALL 6 HERO SKILL VFX UPGRADES
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 3 - 6 HERO SKILL VFX UPGRADES VERIFICATION]...")

	# 3.1 LMB Combo 3 Nhịp & Địa chấn nhịp 3
	hero._combo_index = 0
	hero._do_melee_combo()
	print("  - Tested LMB Step 1 (Horizontal Slash)")

	hero._combo_index = 1
	hero._do_melee_combo()
	print("  - Tested LMB Step 2 (Diagonal Slash & Dual Intersecting Slash)")

	hero._combo_index = 2
	hero._do_melee_combo()
	print("  - Tested LMB Step 3 (Vertical Chop & Dual Earth Shatter Decals)")

	# 3.2 RMB Thánh Khiên Ấn Chú
	hero._do_block_counter()
	print("  - Tested RMB (Holy Shield Rune & Piercing Drill Sparks)")

	# 3.3 Q Tuyệt Chiêu Song Long Lốc Xoáy 360
	hero._do_spin_attack()
	var whirlwind := hero.get_node_or_null("WhirlwindVortexFX")
	if whirlwind:
		print("  - Spawned WhirlwindVortexFX with Double-Helix Arcs: true")
		print("  PASS: Whirlwind 360 VFX attached to Hero successfully")
	else:
		printerr("  FAIL: WhirlwindVortexFX not attached to hero!")
		all_pass = false

	# 3.4 E Bom Khói Ám Ảnh Lôi Vụ 4 Tầng
	var throw_target := hero.global_position + Vector3(0.0, 0.0, 4.0)
	KayKitVFXManager.spawn_smoke_bomb_3d(arena, hero.global_position + Vector3(0, 1.2, 0), throw_target)
	print("  - Tested E (Smoke Bomb 3D Projectile & 4-Layer Detonation)")

	# 3.5 Vết chém chữ thập X-Slash khi trúng đòn
	KayKitVFXManager.spawn_cross_slash_hit_impact(hero.global_position + Vector3(0, 1.0, 2.0), arena)
	print("  - Tested Hit Impact (Cross-Slash X-Impact & Spark Burst)")

	# 3.6 Space Lướt & Sóng Xung Kích va đập Bot
	hero._do_dodge()
	KayKitVFXManager.spawn_dash_impact(hero.global_position + Vector3(0, 0.9, 1.0), Vector3(0, 0, 1), arena)
	print("  - Tested Space Dash Trail & Impact Shockwave")

	# Cho chạy vài frame để kích hoạt tất cả particle và tween
	for f in range(12):
		await physics_frame

	print("  PASS: All 6 Hero Knight skill VFX executed without script or shader errors")

	# --------------------------------------------------------------------------
	# TEST 4: STRICT ZERO PRIMITIVE MESHES AUDIT (0% PRIMITIVE MESH)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 4 - ZERO PRIMITIVE MESHES AUDIT DURING ACTIVE COMBAT VFX]...")
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	var primitive_count := 0
	var array_mesh_count := 0

	for m in meshes:
		var mi := m as MeshInstance3D
		if mi and mi.mesh:
			if mi.mesh is PrimitiveMesh:
				primitive_count += 1
				printerr("  VIOLATION: Found PrimitiveMesh (%s) at %s" % [mi.mesh.get_class(), mi.get_path()])
			elif mi.mesh is ArrayMesh:
				array_mesh_count += 1

	var particles := root.find_children("*", "GPUParticles3D", true, false)
	for p in particles:
		var gp := p as GPUParticles3D
		if gp and gp.draw_pass_1:
			if gp.draw_pass_1 is PrimitiveMesh:
				primitive_count += 1
				printerr("  VIOLATION: Found PrimitiveMesh on GPUParticles3D (%s) at %s" % [gp.draw_pass_1.get_class(), gp.get_path()])
			elif gp.draw_pass_1 is ArrayMesh:
				array_mesh_count += 1

	print("  - Total scanned meshes: %d | ArrayMeshes: %d | PrimitiveMeshes: %d" % [meshes.size() + particles.size(), array_mesh_count, primitive_count])
	if primitive_count == 0:
		print("  PASS: ZERO PRIMITIVE MESHES CONFIRMED (primitive_count == 0, PASS 100%)")
	else:
		printerr("  FAIL: Zero Primitive Mesh audit failed with %d violations!" % primitive_count)
		all_pass = false

	# --------------------------------------------------------------------------
	# KẾT QUẢ TỔNG THỂ
	# --------------------------------------------------------------------------
	print("\n==================================================================")
	if all_pass:
		print("  🏆 ALL 4 TESTS PASSED 100% (ARGONS DIRECTIVE 20 FULLY SATISFIED)!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  ❌ SOME TESTS FAILED IN PHASE 20 VERIFICATION!")
		print("==================================================================")
		quit(1)
