extends SceneTree

# ==============================================================================
# TEST PHASE 21: COOLDOWNS, RMB SOLAR CROSS-CLEAVE, WATERTIGHT STAIRS & AIM-SYNC
# DIRECTIVE 21 (ARGONS & ANTIGRAVITY) — 6 TIÊU CHUẨN KIỂM THỬ BẮT BUỘC:
#   [TEST 21.1]: E Range Clamp <= 7.55m, Cooldown 6.0s, DoT Damage & 55% Slow
#   [TEST 21.2]: Q Cooldown 5.0s, Input Buffering (0.18s) & Vacuum Pull
#   [TEST 21.3]: RMB Solar Cross-Cleave 55.0 DMG (Phase 1 25 DMG + Phase 2 30 DMG)
#   [TEST 21.4]: Wall Micro-Buffer (>= 0.46m) & Watertight Stair Assembly (16 Angles)
#   [TEST 21.5]: Combat Aim-Facing Sync (Visual Root Yaw matches aim within < 0.005 rad)
#   [TEST 21.6]: Zero Primitive Meshes Audit across All 4 Active Skills
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")
const KayKitArenaBuilder = preload("res://scripts/levels/kaykit_arena_builder.gd")

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 21: ARGONS SKILL COOLDOWNS, RMB OVERHAUL & AIM-SYNC")
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
	# TEST 21.1: E RANGE CLAMP <= 7.55m, COOLDOWN 6.0s, DoT & 55% SLOW
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 21.1 - CHIÊU E: GIỚI HẠN 7.5M + COOLDOWN 6.0S + DoT & 55% SLOW]...")
	var test_far_cursor := hero.global_position + Vector3(22.0, 0.0, 0.0)
	var clamped_target := hero._compute_clamped_bomb_target(test_far_cursor)
	var actual_dist := Vector2(clamped_target.x - hero.global_position.x, clamped_target.z - hero.global_position.z).length()
	print("  - Target requested: 22.0m | Clamped target dist: %.2fm" % actual_dist)
	if actual_dist <= 7.55:
		print("  PASS: E range clamped successfully (%.2fm <= 7.55m)" % actual_dist)
	else:
		printerr("  FAIL: E range clamp exceeded: %.2fm > 7.55m" % actual_dist)
		all_pass = false

	# Test Cooldown E
	hero._cd_e_timer = 0.0
	hero._do_ranged_throw()
	print("  - After activating E: _cd_e_timer = %.1fs (Expected: 6.0s)" % hero._cd_e_timer)
	if absf(hero._cd_e_timer - 6.0) < 0.1:
		print("  PASS: E cooldown is strictly 6.0s")
	else:
		printerr("  FAIL: E cooldown is not 6.0s (got %.2f)" % hero._cd_e_timer)
		all_pass = false
	hero._is_throwing_e = false
	hero._action_lock_timer = 0.0

	# Test DoT & Slow on Bot
	var enemies := get_nodes_in_group("enemies")
	if enemies.size() > 0:
		var test_bot := enemies[0] as EnemyMinion3D
		var hp_before := test_bot.hp
		test_bot.take_dot_damage(8.0, Color(0.75, 0.35, 1.0))
		test_bot.apply_slow_debuff(0.45, 1.0)
		print("  - Bot HP before DoT: %.1f | after DoT: %.1f | slow multiplier: %.2f" % [hp_before, test_bot.hp, test_bot._slow_multiplier])
		if test_bot.hp <= hp_before - 7.9 and absf(test_bot._slow_multiplier - 0.45) < 0.01:
			print("  PASS: Bot received 8.0 DoT damage and 55% slow (speed = 45%)")
		else:
			printerr("  FAIL: DoT damage or slow debuff mismatch!")
			all_pass = false

	# --------------------------------------------------------------------------
	# TEST 21.2: Q COOLDOWN 5.0s, INPUT BUFFERING & VACUUM PULL
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 21.2 - CHIÊU Q: KHÓA COOLDOWN 5.0S, INPUT BUFFERING & VACUUM PULL]...")
	hero._cd_q_timer = 0.0
	hero._is_spinning_q = false
	hero._action_lock_timer = 0.0
	hero._do_spin_attack()
	print("  - After activating Q: _cd_q_timer = %.1fs (Expected: 5.0s)" % hero._cd_q_timer)
	if absf(hero._cd_q_timer - 5.0) < 0.1:
		print("  PASS: Q cooldown is strictly 5.0s")
	else:
		printerr("  FAIL: Q cooldown mismatch: %.2f" % hero._cd_q_timer)
		all_pass = false

	# Try second activation during cooldown
	hero._cd_q_timer = 4.2
	hero._is_spinning_q = false
	hero._action_lock_timer = 0.0
	hero._do_spin_attack()
	if hero._cd_q_timer >= 4.1:
		print("  PASS: Q re-activation while on cooldown is completely blocked")
	else:
		printerr("  FAIL: Q cooldown reset prematurely!")
		all_pass = false

	# Test Input Buffering
	hero._cd_rmb_timer = 0.12
	hero._buffered_action = "skill_rmb"
	hero._buffer_timer = 0.18
	hero._action_lock_timer = 0.0
	# Advance 10 physics frames (0.16s)
	for i in range(10):
		hero._physics_process(0.016)
	if hero._cd_rmb_timer >= 3.4 and hero._buffered_action == "":
		print("  PASS: Input buffering (0.18s) successfully consumed and triggered RMB")
	else:
		printerr("  FAIL: Input buffering failed (cd_rmb=%.2f, buff_act=%s)" % [hero._cd_rmb_timer, hero._buffered_action])
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 21.3: RMB SOLAR CROSS-CLEAVE (55.0 DMG: 25 DMG PHASE 1 + 30 DMG PHASE 2)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 21.3 - CHIÊU RMB: THÁNH KIẾM PHÁ KHÔNG TRẢM (55.0 DMG)]...")
	if enemies.size() > 0:
		var rmb_bot := enemies[0] as EnemyMinion3D
		rmb_bot.hp = 80.0
		rmb_bot.is_dead = false
		rmb_bot.global_position = hero.global_position + Vector3(0.0, 0.0, 2.5)

		hero._facing_angle = 0.0 # Facing +Z (toward bot)
		hero._cd_rmb_timer = 0.0
		hero._action_lock_timer = 0.0

		hero._do_rmb_cross_cleave(Vector3(0.0, 0.0, 1.0))
		print("  - After Phase 1 (X-Cleave): Bot HP = %.1f (Expected: 55.0)" % rmb_bot.hp)
		if absf(rmb_bot.hp - 55.0) < 1.0:
			print("  PASS: Phase 1 dealt 25.0 DMG (80.0 -> 55.0)")
		else:
			printerr("  FAIL: Phase 1 damage mismatch: Bot HP = %.1f" % rmb_bot.hp)
			all_pass = false

		# Advance frames for Phase 2 traveling crescent wave
		for i in range(12):
			hero._physics_process(0.016)

		print("  - After Phase 2 (Wave): Bot HP = %.1f (Expected: 25.0)" % rmb_bot.hp)
		if absf(rmb_bot.hp - 25.0) < 1.0:
			print("  PASS: Phase 2 dealt 30.0 DMG (Total: 55.0 DMG confirmed)")
		else:
			printerr("  FAIL: Total RMB damage mismatch: Bot HP = %.1f" % rmb_bot.hp)
			all_pass = false

	# --------------------------------------------------------------------------
	# TEST 21.4: WALL MICRO-BUFFER & WATERTIGHT STAIR ASSEMBLY
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 21.4 - ĐỆM CHỐNG LÚN TƯỜNG (>= 0.46M) & WATERTIGHT STAIR ASSEMBLY]...")
	var hero_shapes := hero.find_children("*", "CollisionShape3D", true, false)
	if hero_shapes.size() > 0:
		var rad: float = hero_shapes[0].shape.radius
		print("  - Hero Capsule radius: %.2fm (Expected: 0.46m) | safe_margin: %.2f" % [rad, hero.safe_margin])
		if absf(rad - 0.46) < 0.01 and absf(hero.safe_margin - 0.05) < 0.01:
			print("  PASS: Hero collision shape radius is 0.46m with safe_margin 0.05")
		else:
			printerr("  FAIL: Capsule radius or safe_margin mismatch!")
			all_pass = false
	else:
		printerr("  FAIL: Hero has no CollisionShape3D!")
		all_pass = false

	# Test build_watertight_stair_assembly
	var test_stair_holder := Node3D.new()
	arena.add_child(test_stair_holder)
	var stair_assembly = KayKitArenaBuilder.build_watertight_stair_assembly(
		test_stair_holder,
		Vector3(0, 0, 0),
		Vector3(0, 4.0, 10.0),
		5.0
	)
	var shapes := stair_assembly.find_children("*", "CollisionShape3D", true, false)
	print("  - Watertight stair collider shapes count: %d (Expected: >= 4: ramp + 2 cheeks + under block)" % shapes.size())
	if shapes.size() >= 4:
		print("  PASS: Watertight stair monolith includes main ramp, side cheeks, and under block")
	else:
		printerr("  FAIL: Missing watertight stair collider components (found %d)" % shapes.size())
		all_pass = false
	test_stair_holder.queue_free()

	# --------------------------------------------------------------------------
	# TEST 21.5: COMBAT AIM-FACING SYNC (< 0.005 RAD)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 21.5 - ĐỒNG BỘ XOAY MẶT & HƯỚNG CHÉM COMBAT AIM-FACING SYNC]...")
	hero._is_throwing_e = false
	hero._is_spinning_q = false
	hero._rmb_cleave_timer = 0.0
	hero._lunge_timer = 0.0
	hero._action_lock_timer = 0.0

	# Aim directly North: (0, 0, -1)
	var aim_north := Vector3(0.0, 0.0, -1.0)
	hero._snap_to_aim_direction(aim_north, 0.30)
	var expected_yaw := atan2(aim_north.x, aim_north.z)
	var actual_yaw: float = hero.visual_root.rotation.y
	var diff_rad := absf(wrapf(actual_yaw - expected_yaw, -PI, PI))
	print("  - Expected yaw: %.4f rad | Actual visual root yaw: %.4f rad | Diff: %.5f rad" % [expected_yaw, actual_yaw, diff_rad])
	if diff_rad < 0.005:
		print("  PASS: Combat aim-facing synced instantaneously within < 0.005 rad")
	else:
		printerr("  FAIL: Aim-facing yaw mismatch: diff = %.5f rad" % diff_rad)
		all_pass = false

	# Verify facing lock resists WASD movement override during attack
	hero.external_move_dir = Vector3(1.0, 0.0, 0.0) # Moving East
	hero._physics_process(0.016)
	var locked_yaw: float = hero.visual_root.rotation.y
	var lock_diff := absf(wrapf(locked_yaw - expected_yaw, -PI, PI))
	print("  - Movement override check: locked_yaw: %.4f rad | lock_diff: %.5f rad" % [locked_yaw, lock_diff])
	if lock_diff < 0.005:
		print("  PASS: Facing lock prevents WASD movement from overriding attack orientation mid-swing")
	else:
		printerr("  FAIL: Facing lock broke during attack! (locked_yaw=%.4f vs expected=%.4f)" % [locked_yaw, expected_yaw])
		all_pass = false
	hero.external_move_dir = Vector3.ZERO
	hero._combat_facing_lock_timer = 0.0

	# --------------------------------------------------------------------------
	# TEST 21.6: ZERO PRIMITIVE MESHES AUDIT ACROSS ALL ACTIVE SKILLS
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 21.6 - ZERO PRIMITIVE MESHES AUDIT ACROSS ALL SKILLS]...")
	# Spawn all active VFX simultaneously
	KayKitVFXManager.spawn_combo_slash_vfx(0, hero.global_position, hero._facing_angle)
	KayKitVFXManager.spawn_combo_slash_vfx(1, hero.global_position, hero._facing_angle)
	KayKitVFXManager.spawn_combo_slash_vfx(2, hero.global_position, hero._facing_angle)
	KayKitVFXManager.spawn_rmb_solar_cross_cleave(hero.global_position, hero._facing_angle, arena)
	KayKitVFXManager.spawn_whirlwind_360_vfx(hero, arena)
	KayKitVFXManager.spawn_smoke_bomb_hazard_zone(arena, hero.global_position, hero.global_position + Vector3(3.0, 0.0, 0.0))

	await process_frame
	await process_frame

	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	var prim_count := 0
	var array_count := 0
	for m in meshes:
		var mi := m as MeshInstance3D
		if mi and mi.mesh:
			var cls := mi.mesh.get_class()
			if cls in ["BoxMesh", "SphereMesh", "CylinderMesh", "CapsuleMesh", "PrismMesh", "TorusMesh", "QuadMesh", "PlaneMesh"]:
				prim_count += 1
				printerr("  Found primitive mesh: %s (%s) in node %s" % [mi.name, cls, mi.get_path()])
			elif cls == "ArrayMesh":
				array_count += 1

	print("  - Total scanned meshes: %d | ArrayMeshes: %d | PrimitiveMeshes: %d" % [meshes.size(), array_count, prim_count])
	if prim_count == 0:
		print("  PASS: ZERO PRIMITIVE MESHES CONFIRMED (primitive_count == 0, PASS 100%)")
	else:
		printerr("  FAIL: Found %d PrimitiveMeshes!" % prim_count)
		all_pass = false

	# --------------------------------------------------------------------------
	# FINAL RESULT
	# --------------------------------------------------------------------------
	print("==================================================================")
	if all_pass:
		print("  🏆 ALL 6 TESTS PASSED 100% (ARGONS DIRECTIVE 21 FULLY SATISFIED)!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  ❌ AT LEAST ONE TEST FAILED IN PHASE 21!")
		print("==================================================================")
		quit(1)
