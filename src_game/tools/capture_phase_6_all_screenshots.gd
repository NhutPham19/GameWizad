extends SceneTree

# ==============================================================================
# TOOL CAPTURE 5 REAL GPU SCREENSHOTS (RTX 4060) — DIRECTIVE 16, PHASE 6
# ==============================================================================

const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")
const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")

var frame_count: int = 0
var arena_node: Node = null
var hero: Node3D = null
var cam: Camera3D = null
var enemies: Array[Node] = []

func _init() -> void:
	print(">>> [TOOL] Initializing Phase 6 GPU Screenshot Capture System...")
	var sc: PackedScene = ResourceLoader.load("res://scenes/levels/kaykit_multitier_arena.tscn") as PackedScene
	if sc:
		arena_node = sc.instantiate()
		root.add_child(arena_node)

func _process(delta: float) -> bool:
	frame_count += 1

	if frame_count == 10:
		hero = arena_node.get_node_or_null("HeroKnight3D") as Node3D
		cam = arena_node.get_node_or_null("IsometricCamera3D") as Camera3D
		var enemies_node = arena_node.get_node_or_null("Enemies")
		if enemies_node:
			enemies = enemies_node.get_children()

	# --- 1. OVERVIEW SCREENSHOT (Frame 60) ---
	if frame_count == 60:
		print(">>> Capturing Screenshot 1: Overview...")
		_save_screenshot("phase6_1_multitier_arena_overview.png")

	# --- 2. SETUP & CAPTURE KNIGHT CLIMBING STAIRS (Frames 65..110) ---
	if frame_count == 70:
		print(">>> Setting up Scenario 2: Knight Climbing Stairs...")
		if hero:
			hero.global_position = Vector3(-6.0, 2.05, -14.0)
			if hero.get("visual_root"):
				hero.visual_root.rotation.y = PI
			if hero.get("anim_player"):
				hero.anim_player.play("Running_A")
		if cam:
			cam.global_position = Vector3(-6.0 + 8.0, 2.0 + 9.0, -14.0 + 8.0)
			cam.size = 12.0

	if frame_count == 110:
		print(">>> Capturing Screenshot 2: Knight Climbing Stairs...")
		_save_screenshot("phase6_2_knight_climbing_stairs.png")

	# --- 3. SETUP & CAPTURE MELEE SLASH & HIT VFX (Frames 115..170) ---
	if frame_count == 120:
		print(">>> Setting up Scenario 3: Melee Slash & Hit VFX...")
		if hero:
			hero.global_position = Vector3(-5.0, 0.05, -3.2)
			if hero.get("visual_root"):
				hero.visual_root.rotation.y = atan2(-1.0, -1.0)
			if hero.get("anim_player"):
				hero.anim_player.play("1H_Melee_Attack_Slice_Horizontal")
				hero.anim_player.seek(0.25, true)
			if "sword_trail_particles" in hero:
				KayKitVFXManager.enable_sword_trails(hero.sword_trail_particles)

		var target_minion: EnemyMinion3D = null
		if enemies.size() > 0:
			target_minion = enemies[0] as EnemyMinion3D
		if target_minion:
			target_minion.global_position = Vector3(-6.0, 0.05, -4.0)
			if target_minion.get("visual_root"):
				target_minion.visual_root.rotation.y = atan2(1.0, 1.0)
			if target_minion.get("anim_player"):
				target_minion.anim_player.play("Hit_A")
				target_minion.anim_player.seek(0.15, true)
			KayKitVFXManager.spawn_hit_impact_at_chest(target_minion)

		if cam:
			cam.global_position = Vector3(-5.5 + 6.0, 1.0 + 7.0, -3.6 + 6.0)
			cam.size = 8.5

	if frame_count == 160:
		print(">>> Capturing Screenshot 3: Melee Slash & Hit VFX...")
		_save_screenshot("phase6_3_melee_slash_and_hit_vfx.png")

	# --- 4. SETUP & CAPTURE SPIN ATTACK DECAL Q (Frames 170..230) ---
	if frame_count == 175:
		print(">>> Setting up Scenario 4: Spin Attack Decal Q...")
		if hero:
			hero.global_position = Vector3(0.0, 4.05, -20.0) # Tier 2 Center
			if hero.get("anim_player"):
				hero.anim_player.play("2H_Melee_Attack_Spinning")
				hero.anim_player.seek(0.35, true)
			if "sword_trail_particles" in hero:
				KayKitVFXManager.enable_sword_trails(hero.sword_trail_particles)
			KayKitVFXManager.spawn_ground_decal_shockwave(
				arena_node, Vector3(0.0, 4.0, -20.0), 3.5, Color(1.0, 0.45, 0.1, 0.95)
			)

		if cam:
			cam.global_position = Vector3(0.0 + 9.0, 4.0 + 10.0, -20.0 + 9.0)
			cam.size = 11.0

	if frame_count == 220:
		print(">>> Capturing Screenshot 4: Spin Attack Decal Q...")
		_save_screenshot("phase6_4_spin_attack_decal_q.png")

	# --- 5. SETUP & CAPTURE SMOKEBOMB 3D THROW E (Frames 235..290) ---
	if frame_count == 235:
		print(">>> Setting up Scenario 5: Smokebomb 3D Throw E...")
		if hero:
			hero.global_position = Vector3(0.0, 0.05, 2.0)
			if hero.get("visual_root"):
				hero.visual_root.rotation.y = PI
			if hero.get("anim_player"):
				hero.anim_player.play("Throw")
				hero.anim_player.seek(0.3, true)

		# Spawn projectile & smoke burst
		var start_p := Vector3(0.0, 1.2, 2.0)
		var target_p := Vector3(0.0, 0.05, -5.0)
		KayKitVFXManager.spawn_kaykit_3d_projectile(arena_node, start_p, target_p, "smokebomb")
		KayKitVFXManager.spawn_ground_decal_shockwave(arena_node, target_p, 2.2, Color(0.6, 0.6, 0.7, 0.8))

		if cam:
			cam.global_position = Vector3(0.0 + 9.0, 1.0 + 9.5, -1.5 + 9.0)
			cam.size = 12.0

	if frame_count == 280:
		print(">>> Capturing Screenshot 5: Smokebomb 3D Throw E...")
		_save_screenshot("phase6_5_smokebomb_3d_throw_e.png")

	# --- FINISH (Frame 290) ---
	if frame_count >= 290:
		print(">>> [TOOL] All 5 Screenshots Captured Successfully!")
		quit(0)
		return true

	return false

func _save_screenshot(filename: String) -> void:
	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("Failed to get viewport image!")
		return
	var save_path := ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/" + filename)
	var err := img.save_png(save_path)
	print("  Saved: ", save_path, " | Status: ", "OK (0)" if err == OK else str("ERR: ", err))
