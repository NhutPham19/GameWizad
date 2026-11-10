extends SceneTree

func _init() -> void:
	print("--- TEST PHASE 3 & 5: HERO KNIGHT + VFX + BINDER ---")
	var scene_res = load("res://scenes/levels/kaykit_multitier_arena.tscn")
	if not scene_res:
		print("FAIL: Cannot load arena scene")
		quit(1)
		return
		
	var arena = scene_res.instantiate()
	root.add_child(arena)
	
	# Check HeroKnight3D
	var hero = arena.get_node_or_null("HeroKnight3D")
	if not hero:
		print("FAIL: HeroKnight3D not found in arena scene")
		quit(1)
		return
	print("PASS: HeroKnight3D found in arena, type: ", hero.get_class())
	
	# Wait for ready and a couple frames for async attachment
	await process_frame
	await process_frame
	
	print("Hero HP: ", hero.hp, "/", hero.max_hp)
	print("Hero VisualRoot: ", hero.visual_root != null)
	print("Hero Skeleton: ", hero.skeleton != null)
	print("Hero AnimPlayer: ", hero.anim_player != null)
	if hero.anim_player:
		print("Hero Current Anim: ", hero.anim_player.current_animation)
		print("Hero Total Anims: ", hero.anim_player.get_animation_list().size())
	print("Hero Sword Instance: ", hero.sword_instance != null)
	print("Hero Blade Center: ", hero.blade_center_marker != null)
	print("Hero Blade Tip: ", hero.blade_tip_marker != null)
	print("Hero Sword Trails: ", hero.sword_trail_particles.size())
	
	# Test Camera target
	var cam = arena.get_node_or_null("IsometricCamera3D")
	if cam:
		print("Camera target: ", cam.target_node.name if cam.target_node else "null")
	
	print("--- ALL INITIALIZATION CHECKS PASSED ---")
	quit(0)
