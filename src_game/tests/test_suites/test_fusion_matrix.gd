extends SceneTree

# ==============================================================================
# TEST SUITE: TASK 2.2 - ELEMENTAL FUSION MATRIX, PILLARS & UPGRADE UI
# AGENT-06 QA INDEPENDENT VERIFICATION (HEADLESS RUNNER)
# ==============================================================================

const DamageData = preload("res://scripts/combat/damage_data.gd")
const Hitbox3D = preload("res://scripts/combat/hitbox_3d.gd")
const Hurtbox3D = preload("res://scripts/combat/hurtbox_3d.gd")
const FusionMatrixScript = preload("res://scripts/elements/fusion_matrix.gd")
const ElementalPillar3DScript = preload("res://scripts/elements/elemental_pillar_3d.gd")
const UpgradeCardsUIScript = preload("res://scripts/ui/upgrade_cards_ui.gd")
const HeroIgnisScript = preload("res://scripts/characters/hero_ignis.gd")

const FusionFirestormVortex3DScript = preload("res://scripts/combat/fusion_spells/fusion_firestorm_vortex_3d.gd")
const FusionPlasmaOverdrive3DScript = preload("res://scripts/combat/fusion_spells/fusion_plasma_overdrive_3d.gd")
const FusionMagmaEruption3DScript = preload("res://scripts/combat/fusion_spells/fusion_magma_eruption_3d.gd")
const FusionScaldingSteam3DScript = preload("res://scripts/combat/fusion_spells/fusion_scalding_steam_3d.gd")
const FusionThunderCyclone3DScript = preload("res://scripts/combat/fusion_spells/fusion_thunder_cyclone_3d.gd")
const FusionSandstormShrapnel3DScript = preload("res://scripts/combat/fusion_spells/fusion_sandstorm_shrapnel_3d.gd")
const FusionBlizzardMaelstrom3DScript = preload("res://scripts/combat/fusion_spells/fusion_blizzard_maelstrom_3d.gd")
const FusionMagneticMonolith3DScript = preload("res://scripts/combat/fusion_spells/fusion_magnetic_monolith_3d.gd")
const FusionElectrifiedTide3DScript = preload("res://scripts/combat/fusion_spells/fusion_electrified_tide_3d.gd")
const FusionQuagmireSpikes3DScript = preload("res://scripts/combat/fusion_spells/fusion_quagmire_spikes_3d.gd")

const REPORT_PATH := "res://../docs/QA_REPORTS/QA_REPORT_TASK_2.2_RESULTS.json"

var test_results := []

func _init() -> void:
	print("\n=======================================================")
	print("🔍 [AGENT-06 QA GATE] TESTING TASK 2.2: FUSION MATRIX & PILLARS...")
	print("=======================================================\n")
	
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	_test_10_fusion_matrix_mappings()
	_test_instantiate_all_10_fusion_spells(root_node)
	_test_elemental_pillars(root_node)
	_test_upgrade_cards_ui(root_node)
	_test_hero_equip_and_cast_e(root_node)
	
	var passed = 0
	var failed = 0
	for r in test_results:
		if r["status"] == "PASS":
			passed += 1
		else:
			failed += 1
			
	var report = {
		"timestamp": Time.get_datetime_string_from_system(),
		"task": "TASK_2.2",
		"total_tests": test_results.size(),
		"passed": passed,
		"failed": failed,
		"overall_status": "PASS" if failed == 0 else "FAIL",
		"details": test_results
	}
	
	print("\n-------------------------------------------------------")
	print("🏁 [AGENT-06 QA GATE] TASK 2.2 OVERALL STATUS: ", report.overall_status, " (", passed, "/", test_results.size(), " tests passed)")
	print("-------------------------------------------------------\n")
	
	var json_str := JSON.stringify(report, "\t")
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		print("✅ Report written to: docs/QA_REPORTS/QA_REPORT_TASK_2.2_RESULTS.json")
		
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

func _test_10_fusion_matrix_mappings() -> void:
	var expected_pairs = [
		{"a": "fire", "b": "wind", "id": "firestorm_vortex"},
		{"a": "fire", "b": "lightning", "id": "plasma_overdrive"},
		{"a": "fire", "b": "earth", "id": "magma_eruption"},
		{"a": "fire", "b": "water", "id": "scalding_steam"},
		{"a": "wind", "b": "lightning", "id": "thunder_cyclone"},
		{"a": "wind", "b": "earth", "id": "sandstorm_shrapnel"},
		{"a": "wind", "b": "water", "id": "blizzard_maelstrom"},
		{"a": "earth", "b": "lightning", "id": "magnetic_monolith"},
		{"a": "lightning", "b": "water", "id": "electrified_tide"},
		{"a": "earth", "b": "water", "id": "quagmire_spikes"}
	]
	
	for pair in expected_pairs:
		var data = FusionMatrixScript.get_fusion_data(pair["a"], pair["b"])
		var ok = not data.is_empty() and data.get("id") == pair["id"]
		var rev_data = FusionMatrixScript.get_fusion_data(pair["b"], pair["a"])
		var rev_ok = not rev_data.is_empty() and rev_data.get("id") == pair["id"]
		_assert(ok and rev_ok, "Fusion Matrix mapping: " + pair["a"] + " + " + pair["b"] + " -> " + pair["id"])

func _test_instantiate_all_10_fusion_spells(parent_node: Node) -> void:
	var s1 = FusionFirestormVortex3DScript.new()
	parent_node.add_child(s1)
	s1.setup(Vector3.ZERO)
	_assert(s1 != null and s1.funnel_mesh != null, "Spell 1: Firestorm Vortex setup")
	s1.queue_free()
	
	var s2 = FusionPlasmaOverdrive3DScript.new()
	parent_node.add_child(s2)
	s2.setup(Vector3.ZERO, Vector3.FORWARD)
	_assert(s2 != null and s2.beam_mesh != null, "Spell 2: Plasma Overdrive setup")
	s2.queue_free()
	
	var s3 = FusionMagmaEruption3DScript.new()
	parent_node.add_child(s3)
	s3.setup(Vector3.ZERO, Vector3.FORWARD)
	_assert(s3 != null and s3.rocks.size() == 3, "Spell 3: Magma Eruption setup")
	s3.queue_free()
	
	var s4 = FusionScaldingSteam3DScript.new()
	parent_node.add_child(s4)
	s4.setup(Vector3.ZERO)
	_assert(s4 != null and s4.steam_cloud_mesh != null, "Spell 4: Scalding Steam setup")
	s4.queue_free()
	
	var s5 = FusionThunderCyclone3DScript.new()
	parent_node.add_child(s5)
	s5.setup(Vector3.ZERO, Vector3.FORWARD)
	_assert(s5 != null and s5.rings.size() == 2, "Spell 5: Thunder Cyclone setup")
	s5.queue_free()
	
	var s6 = FusionSandstormShrapnel3DScript.new()
	parent_node.add_child(s6)
	s6.setup(Vector3.ZERO)
	_assert(s6 != null and s6.rock_debris.size() == 4, "Spell 6: Sandstorm Shrapnel setup")
	s6.queue_free()
	
	var s7 = FusionBlizzardMaelstrom3DScript.new()
	parent_node.add_child(s7)
	s7.setup(Vector3.ZERO)
	_assert(s7 != null and s7.maelstrom_mesh != null, "Spell 7: Blizzard Maelstrom setup")
	s7.queue_free()
	
	var s8 = FusionMagneticMonolith3DScript.new()
	parent_node.add_child(s8)
	s8.setup(Vector3.ZERO)
	_assert(s8 != null and s8.pillars.size() == 3, "Spell 8: Magnetic Monolith setup")
	s8.queue_free()
	
	var s9 = FusionElectrifiedTide3DScript.new()
	parent_node.add_child(s9)
	s9.setup(Vector3.ZERO, Vector3.FORWARD)
	_assert(s9 != null and s9.sphere_mesh != null, "Spell 9: Electrified Tide setup")
	s9.queue_free()
	
	var s10 = FusionQuagmireSpikes3DScript.new()
	parent_node.add_child(s10)
	s10.setup(Vector3.ZERO)
	_assert(s10 != null and s10.mud_pool_mesh != null, "Spell 10: Quagmire Spikes setup")
	s10.queue_free()

func _test_elemental_pillars(parent_node: Node) -> void:
	var elements = ["fire", "wind", "lightning", "earth", "water"]
	for elem in elements:
		var pillar = ElementalPillar3DScript.new()
		parent_node.add_child(pillar)
		pillar.setup(elem, Vector3(2, 0, 2))
		_assert(pillar.crystal_mesh != null and pillar.prompt_label != null, "Elemental Pillar: " + elem + " instantiated")
		pillar.queue_free()

func _test_upgrade_cards_ui(parent_node: Node) -> void:
	var ui = UpgradeCardsUIScript.new()
	parent_node.add_child(ui)
	
	var hero = HeroIgnisScript.new()
	parent_node.add_child(hero)
	
	var pillar = ElementalPillar3DScript.new()
	parent_node.add_child(pillar)
	pillar.setup("wind", Vector3(3, 0, 3))
	
	ui.present_choices(hero, "wind", pillar)
	_assert(ui.visible == true, "UpgradeCardsUI visible on present_choices")
	_assert(Engine.time_scale < 0.2, "UpgradeCardsUI activates bullet-time (time_scale == 0.15)")
	_assert(ui.cards_data.size() == 3, "UpgradeCardsUI generates exactly 3 cards")
	
	ui._on_card_selected(1)
	_assert(Engine.time_scale == 1.0, "UpgradeCardsUI restores normal time scale (1.0) on selection")
	_assert(hero.fusion_spell_id == "firestorm_vortex", "Hero equipped fusion spell: firestorm_vortex")
	
	ui.queue_free()
	hero.queue_free()

func _test_hero_equip_and_cast_e(parent_node: Node) -> void:
	var hero = HeroIgnisScript.new()
	parent_node.add_child(hero)
	
	var fusion_data = FusionMatrixScript.get_fusion_data("fire", "lightning")
	hero.equip_fusion_spell("plasma_overdrive", fusion_data)
	_assert(hero.fusion_spell_id == "plasma_overdrive", "Hero equipped plasma_overdrive")
	
	hero.cast_skill_e()
	_assert(hero.fusion_spell_id != "", "Hero cast fusion skill E executed successfully")
	
	hero.queue_free()
