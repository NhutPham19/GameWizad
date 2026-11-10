extends SceneTree

# ==============================================================================
# TEST SUITE: TASK 2.3 - BIOME 1 (WHISPERING GROVE) & BOSS ANCIENT MOSS TITAN
# AGENT-06 QA INDEPENDENT VERIFICATION (HEADLESS RUNNER)
# ==============================================================================

const SkeletonWarrior3DScript = preload("res://scripts/enemies/skeleton_warrior_3d.gd")
const SkeletonArcher3DScript = preload("res://scripts/enemies/skeleton_archer_3d.gd")
const SkeletonMage3DScript = preload("res://scripts/enemies/skeleton_mage_3d.gd")
const BossAncientMossTitan3DScript = preload("res://scripts/enemies/boss_ancient_moss_titan_3d.gd")
const HeroIgnisScript = preload("res://scripts/characters/hero_ignis.gd")
const DamageData = preload("res://scripts/combat/damage_data.gd")

const REPORT_PATH := "res://../docs/QA_REPORTS/QA_REPORT_TASK_2.3_RESULTS.json"

var test_results := []

func _init() -> void:
	print("\n=======================================================")
	print("🔍 [AGENT-06 QA GATE] TESTING TASK 2.3: BIOME 1 & BOSS MOSS TITAN...")
	print("=======================================================\n")
	
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	_test_skeleton_enemies(root_node)
	_test_boss_ancient_moss_titan(root_node)
	_test_biome_1_architecture(root_node)
	
	var passed = 0
	var failed = 0
	for r in test_results:
		if r["status"] == "PASS":
			passed += 1
		else:
			failed += 1
			
	var report = {
		"timestamp": Time.get_datetime_string_from_system(),
		"task": "TASK_2.3",
		"total_tests": test_results.size(),
		"passed": passed,
		"failed": failed,
		"overall_status": "PASS" if failed == 0 else "FAIL",
		"details": test_results
	}
	
	print("\n-------------------------------------------------------")
	print("🏁 [AGENT-06 QA GATE] TASK 2.3 OVERALL STATUS: ", report.overall_status, " (", passed, "/", test_results.size(), " tests passed)")
	print("-------------------------------------------------------\n")
	
	var json_str := JSON.stringify(report, "\t")
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		print("✅ Report written to: docs/QA_REPORTS/QA_REPORT_TASK_2.3_RESULTS.json")
		
	root_node.queue_free()
	
	if failed == 0:
		quit(0)
	else:
		quit(1)

func _assert(condition: bool, test_name: String, error_msg: String = "") -> void:
	if condition:
		test_results.append({"name": test_name, "status": "PASS"})
		print("  ✅ PASS: ", test_name)
	else:
		test_results.append({"name": test_name, "status": "FAIL", "error": error_msg})
		print("  ❌ FAIL: ", test_name, " - ", error_msg)

func _test_skeleton_enemies(parent: Node) -> void:
	# 1. Test Skeleton Warrior
	var warrior = SkeletonWarrior3DScript.new()
	parent.add_child(warrior)
	warrior.initialize()
	_assert(warrior.max_hp == 70.0 and warrior.attack_damage == 15.0, "Skeleton Warrior stats: 70 HP, 15 DMG")
	_assert(warrior.weapon_mesh != null and warrior.hp_bar != null, "Skeleton Warrior visual & floating HP bar")
	
	warrior.hurtbox.take_damage(DamageData.new(20.0, "fire", Vector3.ZERO, "none", 0.0, null))
	_assert(warrior.current_hp == 50.0, "Skeleton Warrior damage reception (70 -> 50 HP)")
	warrior.queue_free()
	
	# 2. Test Skeleton Archer
	var archer = SkeletonArcher3DScript.new()
	parent.add_child(archer)
	archer.initialize()
	_assert(archer.max_hp == 45.0 and archer.attack_range >= 8.0, "Skeleton Archer stats: 45 HP, 8.5m range")
	_assert(archer.bow_mesh != null, "Skeleton Archer bow visual")
	archer.queue_free()
	
	# 3. Test Skeleton Mage
	var mage = SkeletonMage3DScript.new()
	parent.add_child(mage)
	mage.initialize()
	_assert(mage.max_hp == 50.0 and mage.staff_mesh != null, "Skeleton Mage stats & magic staff visual")
	mage.queue_free()

func _test_boss_ancient_moss_titan(parent: Node) -> void:
	var boss = BossAncientMossTitan3DScript.new()
	parent.add_child(boss)
	boss.initialize()
	
	_assert(boss.max_hp == 650.0, "Boss Ancient Moss Titan max HP == 650")
	_assert(boss.eye_glow_left != null and boss.eye_glow_right != null, "Boss glowing ancient blue eyes")
	
	var hp_box := {"val": 0.0}
	boss.boss_hp_updated.connect(func(c, _m): hp_box["val"] = c)
	boss.hurtbox.take_damage(DamageData.new(50.0, "fire", Vector3.ZERO, "none", 0.0, null))
	_assert(boss.current_hp == 600.0 and hp_box["val"] == 600.0, "Boss HP bar update signal (650 -> 600 HP)")
	
	# Test Telegraph generation
	var tele = boss._create_telegraph_circle(Vector3.ZERO, 5.0, 1.0)
	_assert(tele != null and tele.mesh != null, "Boss Telegraph Decal circle generated")
	tele.queue_free()
	
	boss.queue_free()

func _test_biome_1_architecture(parent: Node) -> void:
	var scene_res = load("res://scenes/levels/biome_1_whispering_grove.tscn")
	_assert(scene_res != null, "Biome 1 Whispering Grove .tscn loaded")
	
	var biome = scene_res.instantiate()
	parent.add_child(biome)
	if not biome.is_node_ready():
		biome._ready()
	
	var terrain = biome.get_node_or_null("Terrain3D")
	_assert(terrain != null, "Biome 1 Terrain3D hierarchy generated")
	_assert(biome.mat_water_purple != null, "Biome 1 Purple River material loaded")
	_assert(biome.mat_statue_eyes != null, "Biome 1 Ancient Statue Eye material loaded")
	_assert(biome.hero_manager != null, "HeroManager linked in Biome 1")
	_assert(biome.hud != null, "CombatHUD linked in Biome 1")
	
	# Test Wave 1 Spawning
	biome.start_next_wave()
	_assert(biome.current_wave == 1, "Wave 1 started successfully")
	_assert(biome.active_enemies.size() == 6, "Wave 1 spawned 6 enemies (4 warriors + 2 archers)")
	
	# Clear wave 1
	for e in biome.active_enemies.duplicate():
		e.die()
	_assert(biome.active_enemies.size() == 0, "Wave 1 cleared successfully")
	
	biome.queue_free()
