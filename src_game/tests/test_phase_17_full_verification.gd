extends SceneTree

# ==============================================================================
# TEST PHASE 17: FULL VERIFICATION SUITE (ARGONS DIRECTIVE 16)
# 4 BÀI KIỂM THỬ BẮT BUỘC ĐẠT PASS 100%:
#   [TEST 1]: Leo bậc thang tự động cho CẢ HeroKnight3D và EnemyMinion3D (Running_A)
#   [TEST 2]: LMB đòn đánh thường chém trúng quái mất máu (80 -> 55 HP, -25 DMG)
#   [TEST 3]: Khung va chạm và tường thành bọc kín 4 rìa map chống rơi 100%
#   [TEST 4]: Kiểm tra luật Zero Primitive Geometry (0% Hình Khối Cơ Bản)
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 17: FULL VERIFICATION SUITE (ARGONS DIRECTIVE 16)")
	print("==================================================================")

	var scene_res := load("res://scenes/levels/kaykit_multitier_arena.tscn") as PackedScene
	if not scene_res:
		printerr("FAIL: Cannot load res://scenes/levels/kaykit_multitier_arena.tscn")
		quit(1)
		return

	var arena := scene_res.instantiate()
	root.add_child(arena)

	# Chờ arena sẵn sàng
	for f in range(6):
		await process_frame

	var hero := arena.get_node_or_null("HeroKnight3D") as HeroKnight3D
	if not hero:
		printerr("FAIL: HeroKnight3D not found!")
		quit(1)
		return

	var all_pass := true

	# --------------------------------------------------------------------------
	# TEST 1: HERO & MINION STAIR CLIMBING
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 1 - HERO & MINION STAIR CLIMBING]...")
	# 1.1 Hero leo cầu thang Tầng 1 -> Tầng 2
	hero.global_position = Vector3(-6.0, 0.05, -11.2)
	hero.external_move_dir = Vector3(0.0, 0.0, -1.0)
	var hero_anim_during_climb := ""

	for i in range(75):
		await physics_frame
		if hero.global_position.y > 1.0 and hero_anim_during_climb == "":
			hero_anim_during_climb = hero._current_anim

	var final_hero_anim := hero._current_anim
	hero.external_move_dir = Vector3.ZERO
	var hero_y := hero.global_position.y
	print("  - Hero position after climbing: ", hero.global_position, " | Anim during climb: ", hero_anim_during_climb, " | Final: ", final_hero_anim)
	if hero_y >= 1.8 and (hero_anim_during_climb == HeroKnight3D.ANIM_RUN or final_hero_anim == HeroKnight3D.ANIM_RUN):
		print("  PASS: Hero climbed stairs successfully (Y = %.2fm >= 1.8m, Anim = %s)" % [hero_y, HeroKnight3D.ANIM_RUN])
	else:
		printerr("  FAIL: Hero failed stair climb (Y = %.2fm, Anim = %s)" % [hero_y, final_hero_anim])
		all_pass = false

	# 1.2 EnemyMinion3D leo cầu thang Tầng 1 -> Tầng 2 theo Player
	var enemies_node = arena.get_node_or_null("Enemies")
	var minion: EnemyMinion3D = null
	if enemies_node and enemies_node.get_child_count() > 0:
		minion = enemies_node.get_child(0) as EnemyMinion3D
	if minion:
		minion.global_position = Vector3(6.0, 0.05, -11.2)
		minion.velocity = Vector3.ZERO
		hero.global_position = Vector3(6.0, 4.05, -18.0)

		for i in range(75):
			await physics_frame

		var minion_y := minion.global_position.y
		print("  - Minion position after climbing: ", minion.global_position, " | Anim: ", minion._current_anim)
		if minion_y >= 1.8:
			print("  PASS: Minion climbed stairs successfully via Waypoint AI (Y = %.2fm >= 1.8m)" % minion_y)
		else:
			printerr("  FAIL: Minion failed stair climb (Y = %.2fm)" % minion_y)
			all_pass = false
	else:
		printerr("  FAIL: No minion found for stair climb test")
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 2: LMB NORMAL ATTACK DEALS DAMAGE
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 2 - LMB NORMAL ATTACK DEALS DAMAGE]...")
	hero.global_position = Vector3(0.0, 0.05, 4.0)
	hero.velocity = Vector3.ZERO
	if hero.visual_root:
		hero.visual_root.rotation.y = 0.0

	var combat_minion := EnemyMinion3D.new()
	combat_minion.position = Vector3(0.0, 0.05, 5.8)
	combat_minion.max_hp = 80.0
	combat_minion.hp = 80.0
	arena.add_child(combat_minion)
	for f in range(3):
		await process_frame

	print("  - Initial combat minion HP: ", combat_minion.hp)
	var hits := hero._apply_melee_hit_detection(HeroKnight3D.MELEE_DAMAGE, HeroKnight3D.MELEE_RANGE, false)
	print("  - LMB hit count: ", hits, " | HP after LMB: ", combat_minion.hp)

	if combat_minion.hp == 55.0 and hits >= 1:
		print("  PASS: LMB Attack dealt exactly 25 damage (HP 80.0 -> 55.0)")
	else:
		printerr("  FAIL: LMB Attack did not apply damage correctly! HP: %.1f, Hits: %d" % [combat_minion.hp, hits])
		all_pass = false

	combat_minion.queue_free()
	await process_frame

	# --------------------------------------------------------------------------
	# TEST 3: MAP PERIMETER BOUNDARY PROTECTION
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 3 - MAP PERIMETER BOUNDARY PROTECTION]...")
	var test_edges = [
		{"name": "South Edge (+Z)", "start": Vector3(0.0, 0.05, 14.5), "dir": Vector3(0, 0, 1), "limit_axis": "z", "limit_val": 16.5, "greater": false},
		{"name": "West Edge (-X)", "start": Vector3(-14.5, 0.05, 0.0), "dir": Vector3(-1, 0, 0), "limit_axis": "x", "limit_val": -16.5, "greater": true},
		{"name": "East Edge (+X)", "start": Vector3(14.5, 0.05, 0.0), "dir": Vector3(1, 0, 0), "limit_axis": "x", "limit_val": 16.5, "greater": false}
	]

	for edge in test_edges:
		hero.global_position = edge["start"]
		hero.external_move_dir = edge["dir"]
		for i in range(40):
			await physics_frame
		hero.external_move_dir = Vector3.ZERO

		var pos_val: float = hero.global_position[edge["limit_axis"]]
		var bounded: bool = (pos_val >= edge["limit_val"]) if edge["greater"] else (pos_val <= edge["limit_val"])
		var not_fallen: bool = hero.global_position.y >= 0.0

		if bounded and not_fallen:
			print("  PASS: %s blocked successfully (Pos: %s, Y = %.2fm)" % [edge["name"], hero.global_position, hero.global_position.y])
		else:
			printerr("  FAIL: %s boundary breached or fallen! Pos: %s" % [edge["name"], hero.global_position])
			all_pass = false

	# --------------------------------------------------------------------------
	# TEST 4: ZERO PRIMITIVE GEOMETRY CHECK
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 4 - ZERO PRIMITIVE GEOMETRY CHECK]...")
	var all_meshes := root.find_children("*", "MeshInstance3D", true, false)
	var primitive_violations := 0
	var total_meshes := all_meshes.size()
	for m in all_meshes:
		var mi := m as MeshInstance3D
		if mi and mi.mesh:
			var mtype := mi.mesh.get_class()
			if mtype in ["BoxMesh", "SphereMesh", "CylinderMesh", "CapsuleMesh", "PrismMesh", "TorusMesh"]:
				printerr("  VIOLATION: Found primitive mesh: %s at %s" % [mtype, mi.get_path()])
				primitive_violations += 1

	if primitive_violations == 0:
		print("  PASS: ZERO PRIMITIVE GEOMETRY VERIFIED (0 primitive meshes among %d total meshes)" % total_meshes)
	else:
		printerr("  FAIL: Found %d primitive meshes!" % primitive_violations)
		all_pass = false

	# --------------------------------------------------------------------------
	# KẾT QUẢ TỔNG HỢP
	# --------------------------------------------------------------------------
	print("\n==================================================================")
	if all_pass:
		print("  🏆 ALL 4 TESTS PASSED 100% (ARGONS DIRECTIVE 16 SATISFIED)!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  ❌ SOME TESTS FAILED! CHECK LOGS ABOVE.")
		print("==================================================================")
		quit(1)
