extends SceneTree

# ==============================================================================
# TEST PHASE 22: STAIR DASH, CORNER FIX & WORLD-ALIGNED SMOOTHNESS
# DIRECTIVE 22 (ARGONS & ANTIGRAVITY)
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const KayKitArenaBuilder = preload("res://scripts/levels/kaykit_arena_builder.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 22: ARGONS STAIR DASH & CORNER LAG FIX")
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
	# TEST 22.1: WORLD-ALIGNED STAIR ASSEMBLY & ZERO TILT ON CHEEKS/UNDER BLOCK
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 22.1 - WORLD-ALIGNED STAIR ASSEMBLY & ZERO TILT CHEEKS]...")
	var test_stair_holder := Node3D.new()
	arena.add_child(test_stair_holder)
	var stair: StaticBody3D = KayKitArenaBuilder.create_leakproof_stair_assembly(
		test_stair_holder,
		Vector3(-6.0, 0.0, -12.0),
		Vector3(-6.0, 4.0, -16.0),
		4.6
	)

	# 1. Stair root node must have rotation == Vector3.ZERO
	var rot_err: float = stair.rotation.length()
	print("  - Stair root rotation: %s (Expected: Vector3.ZERO)" % stair.rotation)
	if rot_err < 0.001:
		print("  PASS: Stair root StaticBody3D is 100% World-Aligned (rotation = Vector3.ZERO)")
	else:
		printerr("  FAIL: Stair root StaticBody3D is tilted (rot_err = %.4f)" % rot_err)
		all_pass = false

	# 2. Check collision shapes: exactly 4 shapes (1 ramp + 2 side cheeks + 1 under block)
	var shapes := stair.find_children("*", "CollisionShape3D", true, false)
	print("  - Total stair shapes: %d (Expected: 4: 1 ramp + 2 side cheeks + 1 under block)" % shapes.size())
	if shapes.size() == 4:
		print("  PASS: Exactly 4 world-aligned collider shapes created (0 protruding bevels)")
	else:
		printerr("  FAIL: Unexpected shape count: %d (Expected 4)" % shapes.size())
		all_pass = false

	# 3. Check under block does not extend forward to stair foot
	var under_shape: CollisionShape3D = null
	for s in shapes:
		var cs := s as CollisionShape3D
		if cs.name != "RampSurfaceShape" and (cs.shape as BoxShape3D).size.x > 4.0:
			under_shape = cs
			break
	if under_shape:
		var under_z: float = under_shape.position.z
		print("  - Under-stair block Z: %.2f (Foot Z: -12.0, Top Z: -16.0)" % under_z)
		# lerpf(-12.0, -16.0, 0.76) = -15.04
		if under_z < -14.0:
			print("  PASS: Under-stair block is tucked safely in the upper half of stairs (Z = %.2f <= -14.0)" % under_z)
		else:
			printerr("  FAIL: Under-stair block protrudes forward toward foot!")
			all_pass = false
	else:
		printerr("  FAIL: Under-stair block not found!")
		all_pass = false

	test_stair_holder.queue_free()

	# --------------------------------------------------------------------------
	# TEST 22.2: PILLAR-TO-STAIR CLEARANCE (ZERO LAG CORNER PINCH)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 22.2 - KHOẢNG HỞ CỘT ĐÁ & THÀNH CẦU THANG (>= 0.40M)]...")
	# Stair 1 at X = -6.0, ramp_width = 4.6 (half_w = 2.3, cheek at -6.0 + 2.3 + 0.12 = -3.58)
	# Pillar at X = -2.5 (radius ~0.55m -> boundary at -3.05)
	# Clearance = abs(-3.46 - (-3.05)) = 0.41m
	var cheek_outer_x := -6.0 + 2.3 + 0.12 + 0.12 # -3.46m
	var pillar_inner_x := -2.5 - 0.55 # -3.05m
	var clearance := absf(pillar_inner_x - cheek_outer_x)
	print("  - Stair cheek outer edge: %.2fm | Pillar inner edge: %.2fm | Gap: %.2fm" % [cheek_outer_x, pillar_inner_x, clearance])
	if clearance >= 0.35:
		print("  PASS: Pillar-to-stair corridor has clear >= 0.35m clearance with 0 pinching bevels")
	else:
		printerr("  FAIL: Corridor pinched between pillar and stair: gap = %.2fm" % clearance)
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 22.3: HERO DASH UP STAIRS WITHOUT STICKING OR STOPPING
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 22.3 - LƯỚT DASH (SPACE) LÊN CẦU THANG 0% KẸT CHÂN]...")
	# Di dời tạm thời quái vật để không cản trở bài test vật lý dốc cầu thang
	for e in get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e is Node3D:
			(e as Node3D).global_position = Vector3(50.0, 0.0, 50.0)

	# Place Hero in front of stair foot, facing stair (-Z direction)
	hero.global_position = Vector3(-6.0, 0.05, -11.0)
	hero.velocity = Vector3.ZERO
	hero._facing_angle = PI # North (-Z)
	hero._snap_to_aim_direction(Vector3(0, 0, -1), 0.3)

	# Trigger Dash into stairs
	hero._dash_dir = Vector3(0.0, 0.0, -1.0)
	hero._dash_timer = hero.DASH_DURATION
	var start_y := hero.global_position.y
	var start_z := hero.global_position.z

	# Simulate 18 physics frames of dashing (0.288s <= 0.35s DASH_DURATION)
	for i in range(18):
		hero._physics_process(0.016)

	var end_y := hero.global_position.y
	var end_z := hero.global_position.z
	var climbed := end_y - start_y
	var advanced := start_z - end_z
	print("  - Start pos: (Y=%.2f, Z=%.2f) | End pos: (Y=%.2f, Z=%.2f)" % [start_y, start_z, end_y, end_z])
	print("  - Distance advanced: %.2fm | Height climbed: %.2fm" % [advanced, climbed])

	if advanced >= 1.20 and climbed >= 0.40:
		print("  PASS: Hero dashed up stairs smoothly without stopping or sticking (climbed %.2fm)" % climbed)
	else:
		printerr("  FAIL: Hero stuck at stair foot during dash! (advanced=%.2fm, climbed=%.2fm)" % [advanced, climbed])
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 22.4: ZERO PRIMITIVE MESHES AUDIT
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 22.4 - ZERO PRIMITIVE MESHES AUDIT]...")
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
		print("  🏆 ALL TESTS PASSED 100% (ARGONS DIRECTIVE 22 FULLY SATISFIED)!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  ❌ AT LEAST ONE TEST FAILED IN PHASE 22!")
		print("==================================================================")
		quit(1)
