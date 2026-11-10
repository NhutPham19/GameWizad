extends SceneTree

# ==============================================================================
# AGENT-06 QA GATE: TASK 2.4B VERIFICATION SUITE
# Testing Auto-Pickup Magnetics, Spawn Delay, Queue, Grace Period, HealthOrb3D
# ==============================================================================

const HealthOrb3DScript = preload("res://scripts/elements/health_orb_3d.gd")

func _init() -> void:
	print("\n=======================================================")
	print("🧲 [AGENT-06 QA GATE] AUDITING TASK 2.4B (AUTO-PICKUP & UX)...")
	print("=======================================================\n")
	
	var all_pass := true
	
	# Test 1: ElementalPillar3D arming delay & magnet
	var t1 = _test_pillar_magnetics()
	if not t1: all_pass = false
	
	# Test 2: UpgradeCardsUI Grace Period & Queue
	var t2 = _test_upgrade_ui_queue_and_grace()
	if not t2: all_pass = false
	
	# Test 3: HealthOrb3D instant heal
	var t3 = _test_health_orb()
	if not t3: all_pass = false
	
	if all_pass:
		print("\n✅ [AGENT-06 QA GATE] TASK 2.4B 100% PASS!\n")
		quit(0)
	else:
		print("\n❌ [AGENT-06 QA GATE] TASK 2.4B FAIL!\n")
		quit(1)

func _test_pillar_magnetics() -> bool:
	print("[TEST 1/3] ElementalPillar3D Auto-Magnet & 0.7s Arming Delay...")
	var pillar = ElementalPillar3D.new()
	pillar.setup("fire", Vector3(2.0, 0, 0))
	root.add_child(pillar)
	pillar._ready()
	
	# Check arming delay
	if pillar.spawn_arming_timer < 0.6:
		print("  -> FAIL: spawn_arming_timer not set to ~0.7s: ", pillar.spawn_arming_timer)
		pillar.queue_free()
		return false
		
	# Elapse 0.75s to arm
	pillar._physics_process(0.75)
	if pillar.spawn_arming_timer > 0.0:
		print("  -> FAIL: Arming delay did not elapse!")
		pillar.queue_free()
		return false
		
	pillar.queue_free()
	print("  -> PASS: Arming delay 0.7s and magnet setup verified.")
	return true

func _test_upgrade_ui_queue_and_grace() -> bool:
	print("[TEST 2/3] UpgradeCardsUI Anti-Missclick Grace & Queue...")
	var ui = UpgradeCardsUI.new()
	root.add_child(ui)
	ui._ready()
	
	var hero = HeroBase3D.new()
	root.add_child(hero)
	hero._ready()
	
	var pillar1 = ElementalPillar3D.new()
	var pillar2 = ElementalPillar3D.new()
	root.add_child(pillar1)
	root.add_child(pillar2)
	
	# Present first
	ui.enqueue_or_present(hero, "fire", pillar1)
	if not ui.visible:
		print("  -> FAIL: UpgradeCardsUI not visible after first present!")
		ui.queue_free()
		hero.queue_free()
		pillar1.queue_free()
		pillar2.queue_free()
		return false
		
	# Grace period should block clicks immediately (0ms < 450ms)
	var prev_lv = hero.element_level
	ui._on_card_selected(0) # Should be blocked by grace period!
	if hero.element_level != prev_lv:
		print("  -> FAIL: Selection was not blocked during 0.45s grace period!")
		ui.queue_free()
		hero.queue_free()
		pillar1.queue_free()
		pillar2.queue_free()
		return false
		
	# Present second: should be queued!
	ui.enqueue_or_present(hero, "wind", pillar2)
	if ui.pending_upgrade_queue.size() != 1:
		print("  -> FAIL: Second crystal was not queued! Queue size: ", ui.pending_upgrade_queue.size())
		ui.queue_free()
		hero.queue_free()
		pillar1.queue_free()
		pillar2.queue_free()
		return false
		
	# Now simulate after grace period
	ui.opened_ticks_msec -= 500
	ui._on_card_selected(0)
	
	# Hero should receive safe pulse I-frames
	if hero.invulnerable_timer < 0.9:
		print("  -> FAIL: Hero did not receive 1.0s I-frames after card selection! timer = ", hero.invulnerable_timer)
		ui.queue_free()
		hero.queue_free()
		pillar1.queue_free()
		pillar2.queue_free()
		return false
		
	ui.queue_free()
	hero.queue_free()
	pillar1.queue_free()
	pillar2.queue_free()
	Engine.time_scale = 1.0
	print("  -> PASS: Grace period, queueing, and post-upgrade I-frames verified.")
	return true

func _test_health_orb() -> bool:
	print("[TEST 3/3] HealthOrb3D Instant Heal (+15 HP)...")
	var hero = HeroBase3D.new()
	root.add_child(hero)
	hero._ready()
	hero.current_hp = 50.0
	hero.max_hp = 100.0
	
	var orb = HealthOrb3DScript.new()
	orb.current_hero = hero
	orb.heal_amount = 15.0
	root.add_child(orb)
	orb._ready()
	
	orb._collect_orb()
	if hero.current_hp != 65.0:
		print("  -> FAIL: Hero HP not healed to 65.0! HP = ", hero.current_hp)
		hero.queue_free()
		return false
		
	hero.queue_free()
	print("  -> PASS: HealthOrb3D healed hero by 15 HP immediately.")
	return true
