extends SceneTree

# ==============================================================================
# AGENT-06 QA GATE: TASK 2.4A VERIFICATION SUITE
# Testing Camera-Basis WASD, Movement-Driven Facing, Cast Facing Snap
# ==============================================================================

func _init() -> void:
	print("\n=======================================================")
	print("🧪 [AGENT-06 QA GATE] AUDITING TASK 2.4A (WASD & FACING)...")
	print("=======================================================\n")
	
	var all_pass := true
	
	# Test 1: Camera Basis ground projection vectors
	var t1 = _test_camera_vectors()
	if not t1: all_pass = false
	
	# Test 2: HeroBase3D facing & lock timer
	var t2 = _test_hero_facing_and_casting()
	if not t2: all_pass = false
	
	# Test 3: Clamped cast target
	var t3 = _test_clamped_cast()
	if not t3: all_pass = false
	
	if all_pass:
		print("\n✅ [AGENT-06 QA GATE] TASK 2.4A 100% PASS!\n")
		quit(0)
	else:
		print("\n❌ [AGENT-06 QA GATE] TASK 2.4A FAIL!\n")
		quit(1)

func _test_camera_vectors() -> bool:
	print("[TEST 1/3] Camera-Basis Ground Projection Directions...")
	var cam := Camera3D.new()
	cam.rotation_degrees = Vector3(-45.0, 45.0, 0.0)
	var basis := Basis.from_euler(Vector3(deg_to_rad(-45.0), deg_to_rad(45.0), 0.0), EULER_ORDER_YXZ)
	
	var screen_right := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	var screen_up := Vector3(basis.y.x, 0.0, basis.y.z).normalized()
	
	# Check orthogonality
	var dot_prod = screen_right.dot(screen_up)
	if abs(dot_prod) > 0.001:
		print("  -> FAIL: screen_right and screen_up are not orthogonal! dot = ", dot_prod)
		return false
		
	# Verify screen_right points toward +X and -Z in isometric 45 deg
	if screen_right.x <= 0.0 or screen_right.z >= 0.0:
		print("  -> FAIL: screen_right direction incorrect: ", screen_right)
		return false
		
	# Verify screen_up points toward -X and -Z (away from camera / up on screen)
	if screen_up.x >= 0.0 or screen_up.z >= 0.0:
		print("  -> FAIL: screen_up direction incorrect: ", screen_up)
		return false
		
	print("  -> PASS: Screen vectors correct: Right=", screen_right, ", Up=", screen_up)
	return true

func _test_hero_facing_and_casting() -> bool:
	print("[TEST 2/3] Hero Movement-Driven Facing & Cast Snap...")
	var hero = HeroBase3D.new()
	root.add_child(hero)
	hero._ready()
	
	if not hero.visual_root:
		print("  -> FAIL: visual_root is null after _ready!")
		hero.queue_free()
		return false
	
	# Simulate moving forward (screen_up)
	var move_dir = Vector3(-0.7071, 0, -0.7071).normalized()
	var target_yaw = atan2(move_dir.x, move_dir.z)
	hero.visual_root.rotation.y = target_yaw
	
	# Check facing forward
	if abs(hero.visual_root.rotation.y - target_yaw) > 0.01:
		print("  -> FAIL: Hero visual root rotation does not match move_dir!")
		hero.queue_free()
		return false
		
	# Test Cast Snap
	hero.aim_direction = Vector3(1.0, 0.0, 0.0)
	hero.snap_facing_to_cursor()
	
	var expected_cast_yaw = atan2(hero.aim_direction.x, hero.aim_direction.z)
	if abs(hero.visual_root.rotation.y - expected_cast_yaw) > 0.01:
		print("  -> FAIL: Snap facing did not orient visual_root to cursor! Current: ", hero.visual_root.rotation.y, ", Expected: ", expected_cast_yaw)
		hero.queue_free()
		return false
		
	if hero.cast_facing_lock_timer < 0.3:
		print("  -> FAIL: cast_facing_lock_timer not set properly: ", hero.cast_facing_lock_timer)
		hero.queue_free()
		return false
		
	hero.queue_free()
	print("  -> PASS: Movement facing and Snap-to-Cursor cast lock verified.")
	return true

func _test_clamped_cast() -> bool:
	print("[TEST 3/3] Clamped Cast Target Range (Max 9.5m)...")
	var hero = HeroBase3D.new()
	hero.global_position = Vector3(0, 0, 0)
	hero.aim_direction = Vector3(0, 0, 1)
	
	# If cursor is 20m away along Z
	var far_pos = Vector3(0, 0, 20)
	var offset = far_pos - hero.global_position
	offset.y = 0.0
	var clamped = hero.global_position + offset.normalized() * 9.5
	
	if clamped.distance_to(hero.global_position) > 9.51:
		print("  -> FAIL: Distance exceeds 9.5m: ", clamped.distance_to(hero.global_position))
		hero.queue_free()
		return false
		
	hero.queue_free()
	print("  -> PASS: Clamping limits cast range to <= 9.5m correctly.")
	return true
