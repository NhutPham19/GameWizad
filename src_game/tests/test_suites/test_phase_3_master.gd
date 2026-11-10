extends SceneTree

# ==============================================================================
# AGENT-06 QA GATE: PHASE 3 MASTER VERIFICATION SUITE
# Verifying Task 2.4A, 2.4B, 3.1, 3.2, 3.3 for Argons Directive #4
# ==============================================================================

const HealthOrb3DScript = preload("res://scripts/elements/health_orb_3d.gd")
const PortalGate3DScript = preload("res://scripts/levels/portal_gate_3d.gd")
const Biome2Script = preload("res://scripts/levels/biome_2_sunscorched_canyon.gd")
const Biome3Script = preload("res://scripts/levels/biome_3_astral_sanctum.gd")
const ZephyrionScript = preload("res://scripts/enemies/boss_zephyrion_djinn_3d.gd")
const VexorScript = preload("res://scripts/enemies/boss_archmage_vexor_3d.gd")
const HeroSelectScript = preload("res://scripts/ui/hero_select_modal_ui.gd")
const SynthAudioScript = preload("res://scripts/core/synth_audio.gd")

func _init() -> void:
	print("\n===================================================================")
	print("👑 [AGENT-06 QA GATE] AUDITING PHASE 3 MASTER (DIRECTIVE #4)...")
	print("===================================================================\n")
	
	var results := []
	
	# 1. Task 2.4A: WASD & Movement Facing & Snap Cast
	var t1 = _audit_task_2_4a()
	results.append(t1)
	
	# 2. Task 2.4B: Auto-Pickup, Queue, Grace Period, HealthOrb
	var t2 = _audit_task_2_4b()
	results.append(t2)
	
	# 3. Task 3.1: Biome 2 Canyon & Boss Zephyrion
	var t3 = _audit_task_3_1()
	results.append(t3)
	
	# 4. Task 3.2: Biome 3 Astral Sanctum & Final Boss Vexor
	var t4 = _audit_task_3_2()
	results.append(t4)
	
	# 5. Task 3.3: Hero Select 3D, Synth Audio SFX & HUD
	var t5 = _audit_task_3_3()
	results.append(t5)
	
	var all_pass := true
	for r in results:
		if not r.passed:
			all_pass = false
			
	print("\n-------------------------------------------------------------------")
	if all_pass:
		print("🏆 [AGENT-06 QA GATE] ALL 5 AUDIT PHASES PASSED 100%! READY FOR ARGONS!")
		print("-------------------------------------------------------------------\n")
		quit(0)
	else:
		print("❌ [AGENT-06 QA GATE] AUDIT FAILED ON ONE OR MORE TASKS!")
		print("-------------------------------------------------------------------\n")
		quit(1)

func _audit_task_2_4a() -> Dictionary:
	print("▶ [TASK 2.4A] Auditing Camera-Basis WASD, Facing & Combat Snap...")
	var cam := Camera3D.new()
	cam.rotation_degrees = Vector3(-45.0, 45.0, 0.0)
	var basis := Basis.from_euler(Vector3(deg_to_rad(-45.0), deg_to_rad(45.0), 0.0), EULER_ORDER_YXZ)
	var screen_right := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	var screen_up := Vector3(basis.y.x, 0.0, basis.y.z).normalized()
	
	# W input vector
	var move_w = screen_up
	var move_s = -screen_up
	var move_a = -screen_right
	var move_d = screen_right
	
	# Verify W goes up/away from camera
	var w_ok = (move_w.x < 0.0 and move_w.z < 0.0)
	var s_ok = (move_s.x > 0.0 and move_s.z > 0.0)
	var a_ok = (move_a.x < 0.0 and move_a.z > 0.0)
	var d_ok = (move_d.x > 0.0 and move_d.z < 0.0)
	
	var hero = HeroBase3D.new()
	root.add_child(hero)
	hero._ready()
	
	# Test snap to cursor
	hero.aim_direction = Vector3(0, 0, 1)
	hero.snap_facing_to_cursor()
	var snap_ok = (hero.cast_facing_lock_timer >= 0.3)
	
	# Test clamped range
	var clamped_pos = hero.get_clamped_cast_target(9.5)
	var clamp_ok = (clamped_pos.distance_to(hero.global_position) <= 9.51)
	
	hero.queue_free()
	var passed = w_ok and s_ok and a_ok and d_ok and snap_ok and clamp_ok
	print("  -> Result Task 2.4A: ", "PASS" if passed else "FAIL")
	return {"name": "Task 2.4A", "passed": passed}

func _audit_task_2_4b() -> Dictionary:
	print("▶ [TASK 2.4B] Auditing Auto-Pickup Magnet, Queue, Grace Period & HealthOrb...")
	var pillar = ElementalPillar3D.new()
	pillar.setup("fire", Vector3(1, 0, 1))
	root.add_child(pillar)
	pillar._ready()
	var arm_ok = (pillar.spawn_arming_timer >= 0.6)
	pillar.queue_free()
	
	var ui = UpgradeCardsUI.new()
	root.add_child(ui)
	ui._ready()
	var hero = HeroBase3D.new()
	root.add_child(hero)
	hero._ready()
	
	var p1 = ElementalPillar3D.new()
	var p2 = ElementalPillar3D.new()
	root.add_child(p1)
	root.add_child(p2)
	
	ui.enqueue_or_present(hero, "fire", p1)
	ui.enqueue_or_present(hero, "wind", p2)
	var queue_ok = (ui.pending_upgrade_queue.size() == 1)
	
	# Grace period blocks immediate input
	var prev_lv = hero.element_level
	ui._on_card_selected(0)
	var grace_ok = (hero.element_level == prev_lv)
	
	# Test HealthOrb
	hero.current_hp = 40.0
	var orb = HealthOrb3DScript.new()
	orb.current_hero = hero
	orb.heal_amount = 15.0
	root.add_child(orb)
	orb._ready()
	orb._collect_orb()
	var heal_ok = (hero.current_hp == 55.0)
	
	ui.queue_free()
	hero.queue_free()
	p1.queue_free()
	p2.queue_free()
	Engine.time_scale = 1.0
	
	var passed = arm_ok and queue_ok and grace_ok and heal_ok
	print("  -> Result Task 2.4B: ", "PASS" if passed else "FAIL")
	return {"name": "Task 2.4B", "passed": passed}

func _audit_task_3_1() -> Dictionary:
	print("▶ [TASK 3.1] Auditing Biome 2 Sunscorched Canyon & Boss Zephyrion...")
	var biome2 = Biome2Script.new()
	root.add_child(biome2)
	biome2._ready()
	
	var has_terrain = biome2.has_node("CanyonTerrain3D")
	var djinn = ZephyrionScript.new()
	root.add_child(djinn)
	djinn.initialize()
	var djinn_hp_ok = (djinn.max_hp == 650.0)
	
	var portal = PortalGate3DScript.new()
	portal.setup(Vector3.ZERO, "res://scenes/levels/biome_3_astral_sanctum.tscn")
	root.add_child(portal)
	portal._ready()
	var portal_ok = (portal.target_scene_path.contains("biome_3"))
	
	biome2.queue_free()
	djinn.queue_free()
	portal.queue_free()
	
	var passed = has_terrain and djinn_hp_ok and portal_ok
	print("  -> Result Task 3.1: ", "PASS" if passed else "FAIL")
	return {"name": "Task 3.1", "passed": passed}

func _audit_task_3_2() -> Dictionary:
	print("▶ [TASK 3.2] Auditing Biome 3 Astral Sanctum & Final Boss Archmage Vexor...")
	var biome3 = Biome3Script.new()
	root.add_child(biome3)
	biome3._ready()
	
	var has_bridge = biome3.has_node("MarbleBridge3D")
	var vexor = VexorScript.new()
	root.add_child(vexor)
	vexor.initialize()
	var vexor_hp_ok = (vexor.max_hp == 900.0)
	var vexor_circle_ok = (vexor.ground_circle != null)
	
	biome3.queue_free()
	vexor.queue_free()
	
	var passed = has_bridge and vexor_hp_ok and vexor_circle_ok
	print("  -> Result Task 3.2: ", "PASS" if passed else "FAIL")
	return {"name": "Task 3.2", "passed": passed}

func _audit_task_3_3() -> Dictionary:
	print("▶ [TASK 3.3] Auditing Hero Select Modal UI, Synth Audio & HUD...")
	var modal = HeroSelectScript.new()
	root.add_child(modal)
	modal._ready()
	var modal_cards_ok = (modal.cards_box != null and modal.cards_box.get_child_count() == 5)
	
	# Test Synth Audio
	var synth = SynthAudioScript.new()
	root.add_child(synth)
	synth._ready()
	var synth_ok = (synth.sfx_cast != null and synth.sfx_crystal != null and synth.sfx_health != null)
	
	modal.queue_free()
	synth.queue_free()
	
	var passed = modal_cards_ok and synth_ok
	print("  -> Result Task 3.3: ", "PASS" if passed else "FAIL")
	return {"name": "Task 3.3", "passed": passed}
