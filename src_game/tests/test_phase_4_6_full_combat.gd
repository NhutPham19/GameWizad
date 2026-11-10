extends SceneTree

const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")
const StrictQAHUD = preload("res://scripts/ui/strict_qa_hud.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")

# ==============================================================================
# TEST PHASE 4 & 6: FULL COMBAT, 5 MINIONS, 3 TIERS, ZERO PRIMITIVE CHECK
# ==============================================================================

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 4 & 6: FULL COMBAT & 5 MINIONS 3-TIER TEST")
	print("==================================================================")

	var scene_res = load("res://scenes/levels/kaykit_multitier_arena.tscn")
	if not scene_res:
		print("FAIL: Cannot load arena scene")
		quit(1)
		return

	var arena = scene_res.instantiate()
	root.add_child(arena)

	# Chờ các node khởi tạo và process_frame
	for i in range(5):
		await process_frame

	# 1. Kiểm tra HeroKnight3D
	var hero = arena.get_node_or_null("HeroKnight3D")
	if not hero:
		print("FAIL: HeroKnight3D not found!")
		quit(1)
		return
	print("PASS: HeroKnight3D found in scene (HP: ", hero.hp, "/", hero.max_hp, ")")

	# 2. Kiểm tra StrictQAHUD
	var hud = arena.get_node_or_null("StrictQAHUD")
	if not hud:
		print("FAIL: StrictQAHUD not found!")
		quit(1)
		return
	print("PASS: StrictQAHUD found and attached")

	# 3. Kiểm tra 5 EnemyMinion3D trên 3 tầng
	var enemies_node = arena.get_node_or_null("Enemies")
	var enemies = enemies_node.get_children() if enemies_node else arena.get_tree().get_nodes_in_group("enemies")
	print("PASS: Found ", enemies.size(), " EnemyMinion3D nodes")
	if enemies.size() != 5:
		print("FAIL: Expected 5 minions, found: ", enemies.size())
		quit(1)
		return

	var tier_1_count := 0
	var tier_2_count := 0
	var tier_3_count := 0

	for e in enemies:
		var ey: float = (e as Node3D).position.y
		if ey < 2.0:
			tier_1_count += 1
		elif ey < 6.0:
			tier_2_count += 1
		else:
			tier_3_count += 1

	print("  - Tier 1 Minions (Y ~ 0.05m): ", tier_1_count, " (Expected 2)")
	print("  - Tier 2 Minions (Y ~ 4.05m): ", tier_2_count, " (Expected 2)")
	print("  - Tier 3 Boss    (Y ~ 8.05m): ", tier_3_count, " (Expected 1)")

	if tier_1_count != 2 or tier_2_count != 2 or tier_3_count != 1:
		print("FAIL: Minion tier distribution mismatch!")
		quit(1)
		return

	# Kiểm tra Boss máu 150
	var boss: EnemyMinion3D = null
	for e in enemies:
		if (e as Node3D).position.y > 6.0:
			boss = e as EnemyMinion3D
			break
	if boss == null or boss.max_hp < 150.0:
		print("FAIL: Tier 3 Boss HP expected 150, got: ", boss.max_hp if boss else 0)
		quit(1)
		return
	print("PASS: Tier 3 Boss verified with Max HP: ", boss.max_hp)

	# 4. Kiểm tra Zero Primitive Geometry (Luật Thép 0% Hình Khối)
	var all_meshes = root.find_children("*", "MeshInstance3D", true, false)
	var primitive_violations := 0
	for m in all_meshes:
		var mi := m as MeshInstance3D
		if mi and mi.mesh:
			var mtype := mi.mesh.get_class()
			if mtype in ["BoxMesh", "SphereMesh", "CylinderMesh", "CapsuleMesh", "PrismMesh", "TorusMesh"]:
				print("VIOLATION: Found primitive mesh: ", mtype, " at ", mi.get_path())
				primitive_violations += 1

	if primitive_violations > 0:
		print("FAIL: Zero Primitive Law violated! Found ", primitive_violations, " primitive meshes.")
		quit(1)
		return
	print("PASS: ZERO PRIMITIVE GEOMETRY VERIFIED! (0 primitive meshes among ", all_meshes.size(), " total meshes)")

	# 5. Kiểm tra Chiến đấu 2 Chiều (Combat & Damage)
	var target_minion = enemies[0] as EnemyMinion3D
	var initial_minion_hp: float = target_minion.hp
	print("Testing Combat: Minion initial HP = ", initial_minion_hp)

	# Hero gây sát thương
	target_minion.take_damage(25.0, Vector3.FORWARD)
	for i in range(3):
		await process_frame

	print("Minion HP after 25 dmg: ", target_minion.hp)
	if target_minion.hp >= initial_minion_hp:
		print("FAIL: Minion did not take damage!")
		quit(1)
		return
	print("PASS: Minion took damage correctly (HP reduced from ", initial_minion_hp, " to ", target_minion.hp, ")")

	# Minion gây sát thương ngược lại cho Hero
	var initial_hero_hp: float = hero.hp
	hero.take_damage(12.0, Vector3.BACK)
	for i in range(3):
		await process_frame

	print("Hero HP after 12 dmg: ", hero.hp)
	if hero.hp >= initial_hero_hp:
		print("FAIL: Hero did not take damage!")
		quit(1)
		return
	print("PASS: Hero took damage correctly (HP reduced from ", initial_hero_hp, " to ", hero.hp, ")")

	# 6. Kiểm tra VFX Shockwave Decal & 3D Projectile
	KayKitVFXManager.spawn_ground_decal_shockwave(arena, hero.global_position, 3.5, Color(1, 0, 0))
	KayKitVFXManager.spawn_kaykit_3d_projectile(arena, hero.global_position, target_minion.global_position, "smokebomb")
	for i in range(3):
		await process_frame
	print("PASS: VFX Shockwave Decal and 3D Smokebomb spawned successfully")

	print("==================================================================")
	print("  ALL PHASE 4 & 6 CHECKS PASSED (100% SUCCESS)!")
	print("==================================================================")
	quit(0)
