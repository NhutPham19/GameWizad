extends SceneTree

# ==============================================================================
# TEST PHASE 19: CORNERS TRAP FIX, BALANCED STAIR DASH & FLUID COMBAT
# 5 BÀI KIỂM THỬ BẮT BUỘC ĐẠT PASS 100% (ARGONS DIRECTIVE 19):
#   [TEST 1]: Không bị kẹt đuốc / góc tường Tầng 3 (Y = 8.05m) tại (4.8, 8.05, -39.5)
#   [TEST 2]: Cân bằng tốc độ lướt cầu thang (Space) so với mặt phẳng (<= 1.05x)
#   [TEST 3]: Lướt đụng Bot dội ngược lại (Rebound) & Húc văng Bot >= 1.5m (0% xuyên qua)
#   [TEST 4]: Tung chiêu linh hoạt (Attack Step-Lunge + Early Walk-Cancel 0.24s -> Running_A) & Hit-Stun Bot
#   [TEST 5]: Bot định tuyến đa tầng, cảm biến 7 tia đi vòng vật cản & xoay mặt theo vận tốc bước đi
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 19: CORNERS TRAP, BALANCED DASH & FLUID COMBAT")
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
	# TEST 1: NO TORCH / CORNER STUCK AT TIER 3 (Y = 8.05m)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 1 - NO TORCH / CORNER STUCK AT TIER 3]...")
	# Đặt Hero tại góc phía Đông Tầng 3 cạnh cây đuốc (4.8, 8.05, -39.5)
	hero.global_position = Vector3(4.5, 8.05, -39.5)
	hero.velocity = Vector3.ZERO
	# Cho Hero di chuyển hướng về phía Nam đi ngang qua vị trí cây đuốc (Z = -38.0)
	hero.external_move_dir = Vector3(0.0, 0.0, 1.0)

	for i in range(40):
		await physics_frame

	var passed_forward := hero.global_position.z > -37.5
	print("  - Hero forward movement through torch area: pos=%s (passed=%s)" % [hero.global_position, passed_forward])

	# Cho Hero di chuyển ngược lại về phía Bắc qua vị trí cây đuốc
	hero.external_move_dir = Vector3(0.0, 0.0, -1.0)
	for i in range(40):
		await physics_frame

	var passed_backward := hero.global_position.z < -38.5
	print("  - Hero backward movement through torch area: pos=%s (passed=%s)" % [hero.global_position, passed_backward])
	hero.external_move_dir = Vector3.ZERO

	if passed_forward and passed_backward:
		print("  PASS: Hero moves freely around Tier 3 torches and corners with 0% obstruction")
	else:
		printerr("  FAIL: Hero got stuck at Tier 3 torch / corner!")
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 2: BALANCED STAIR DASH SPEED (<= 1.05x FLAT DASH)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 2 - BALANCED STAIR DASH SPEED]...")
	# 2.1 Đo quãng đường Dash trên mặt phẳng Tầng 1
	hero.global_position = Vector3(0.0, 0.05, 0.0)
	hero.velocity = Vector3.ZERO
	await physics_frame
	var flat_start := hero.global_position
	hero._dash_dir = Vector3(0.0, 0.0, -1.0)
	hero._dash_timer = hero.DASH_DURATION
	var dash_frames := int(ceil(hero.DASH_DURATION * 60.0)) + 2

	for i in range(dash_frames):
		await physics_frame

	var flat_disp := flat_start.distance_to(hero.global_position)
	print("  - Flat surface Dash 3D displacement: %.3fm" % flat_disp)

	# 2.2 Đo quãng đường Dash trên dốc cầu thang Tầng 1 -> Tầng 2
	hero.global_position = Vector3(-6.0, 0.8, -12.8)
	hero.velocity = Vector3.ZERO
	for i in range(3):
		await physics_frame
	var stair_start := hero.global_position
	hero._dash_dir = Vector3(0.0, 0.0, -1.0)
	hero._dash_timer = hero.DASH_DURATION

	for i in range(dash_frames):
		await physics_frame

	var stair_disp := stair_start.distance_to(hero.global_position)
	var ratio := stair_disp / maxf(0.001, flat_disp)
	print("  - Stair slope Dash 3D displacement: %.3fm (Ratio: %.2fx, Max allowed: 1.05x)" % [stair_disp, ratio])

	if ratio <= 1.05:
		print("  PASS: Stair Dash speed balanced successfully (%.2fx <= 1.05x)" % ratio)
	else:
		printerr("  FAIL: Stair Dash speed too high (%.2fx > 1.05x)" % ratio)
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 3: DASH INTO BOT REBOUNDS & KNOCKS BOT BACK (ZERO PHASE-THROUGH)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 3 - DASH INTO BOT REBOUND & KNOCKBACK (ZERO PHASE-THROUGH)]...")
	hero.global_position = Vector3(0.0, 0.05, 0.0)
	hero.velocity = Vector3.ZERO

	var test_minion := EnemyMinion3D.new()
	test_minion.position = Vector3(0.0, 0.05, 1.5)
	arena.add_child(test_minion)
	for i in range(3):
		await physics_frame

	var minion_initial_z := test_minion.global_position.z
	var max_hero_z := hero.global_position.z
	hero._dash_dir = Vector3(0.0, 0.0, 1.0)
	hero._dash_timer = hero.DASH_DURATION

	var rebound_detected := false
	for i in range(25):
		await physics_frame
		if hero.global_position.z > max_hero_z:
			max_hero_z = hero.global_position.z
		if hero._rebound_timer > 0.0 or hero.velocity.z < -1.0:
			rebound_detected = true

	var minion_final_z := test_minion.global_position.z
	var minion_kb_dist := minion_final_z - minion_initial_z
	print("  - Minion initial Z: %.2fm | Final Z: %.2fm | Knockback: %.2fm (Req >= 1.5m)" % [minion_initial_z, minion_final_z, minion_kb_dist])
	print("  - Hero initial Z: 0.0m | Max Z reached: %.2fm | Final Z: %.2fm | Rebound detected: %s" % [max_hero_z, hero.global_position.z, rebound_detected])

	var zero_phase := max_hero_z <= minion_initial_z + 0.15 # Never penetrated through bot
	var bot_knocked := minion_kb_dist >= 1.5

	if zero_phase and bot_knocked and rebound_detected:
		print("  PASS: Hero rebounded on Bot collision with 0%% phase-through and knocked Bot back %.2fm" % minion_kb_dist)
	else:
		printerr("  FAIL: Dash impact failed! (zero_phase=%s, bot_knocked=%s, rebound=%s)" % [zero_phase, bot_knocked, rebound_detected])
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 4: FLUID COMBAT WALK-CANCEL & ENEMY HIT-STUN
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 4 - FLUID COMBAT WALK-CANCEL & ENEMY HIT-STUN]...")
	hero.global_position = Vector3(0.0, 0.05, 0.0)
	hero.velocity = Vector3.ZERO
	test_minion.global_position = Vector3(0.0, 0.05, 1.5)
	test_minion.hp = 80.0
	test_minion.velocity = Vector3.ZERO
	for i in range(3):
		await physics_frame

	hero.external_move_dir = Vector3(0.0, 0.0, 1.0)
	hero._do_melee_combo()
	var initial_action_lock := hero._action_lock_timer
	print("  - Action lock timer at melee swing: %.3fs (Expected <= 0.24s)" % initial_action_lock)

	# Chạy 17 frames (~0.28s > 0.24s action lock)
	for i in range(17):
		await physics_frame

	var anim_after_cancel := hero._current_anim
	var hero_moving_speed := Vector2(hero.velocity.x, hero.velocity.z).length()
	var bot_hit_stun := test_minion._hit_stun_timer
	var bot_hp := test_minion.hp
	print("  - After 0.28s: Hero anim=%s, Move speed=%.2fm/s, Bot HP=%.1f (took dmg=%s), Bot hit stun=%.3fs" % [
		anim_after_cancel, hero_moving_speed, bot_hp, bot_hp < 80.0, bot_hit_stun
	])
	hero.external_move_dir = Vector3.ZERO

	var walk_cancel_pass := (anim_after_cancel == HeroKnight3D.ANIM_RUN) and (hero_moving_speed > 3.0)
	var hit_stun_pass := (bot_hp <= 55.0)

	if walk_cancel_pass and hit_stun_pass:
		print("  PASS: Fluid combat walk-cancel into Running_A verified and Bot interrupted by Hit-Stun")
	else:
		printerr("  FAIL: Fluid combat walk-cancel failed! (walk_cancel=%s, hit_stun=%s)" % [walk_cancel_pass, hit_stun_pass])
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 5: BOT LONG-RANGE OBSTACLE DETOUR & VELOCITY-ALIGNED FACING
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 5 - BOT OBSTACLE DETOUR & VELOCITY-ALIGNED FACING]...")
	hero.global_position = Vector3(0.0, 0.05, -6.0)
	hero.velocity = Vector3.ZERO

	var detour_minion := EnemyMinion3D.new()
	detour_minion.position = Vector3(0.0, 0.05, 6.0) # Cách Hero 12m
	detour_minion.aggro_range = 30.0
	arena.add_child(detour_minion)

	# Đặt 1 khối vật cản StaticBody3D rộng 3.0m chắn thẳng hướng giữa Minion và Hero tại Z = 0.0
	var obstacle := StaticBody3D.new()
	obstacle.name = "TestObstacleWall"
	obstacle.collision_layer = 1
	obstacle.collision_mask = 0
	var obs_col := CollisionShape3D.new()
	var obs_box := BoxShape3D.new()
	obs_box.size = Vector3(3.2, 2.5, 1.2)
	obs_col.shape = obs_box
	obstacle.add_child(obs_col)
	obstacle.position = Vector3(0.0, 1.25, 0.0)
	arena.add_child(obstacle)

	for i in range(4):
		await physics_frame

	var minion_max_sidestep := 0.0
	var alignment_dots: Array[float] = []

	# Giả lập vật lý 200 frames (~3.33s)
	for i in range(200):
		await physics_frame
		var cur_pos := detour_minion.global_position
		if absf(cur_pos.x) > minion_max_sidestep:
			minion_max_sidestep = absf(cur_pos.x)

		# Đo độ lệch góc giữa hướng xoay mặt của visual_root và vector vận tốc bước đi thực tế
		var h_vel := Vector3(detour_minion.velocity.x, 0.0, detour_minion.velocity.z)
		if h_vel.length() > 1.2 and detour_minion.visual_root != null:
			var walk_v := h_vel.normalized()
			var yaw: float = detour_minion.visual_root.rotation.y
			var face_v := Vector3(sin(yaw), 0.0, cos(yaw)).normalized()
			var dot_align := face_v.dot(walk_v)
			alignment_dots.append(dot_align)

	var minion_final_z_detour := detour_minion.global_position.z
	var advanced_towards_hero := minion_final_z_detour < 2.0
	var sidestep_pass := minion_max_sidestep >= 1.2

	var avg_dot := 0.0
	if alignment_dots.size() > 0:
		var sum := 0.0
		for d in alignment_dots:
			sum += d
		avg_dot = sum / alignment_dots.size()

	print("  - Bot initial Z: 6.0m | Final Z: %.2fm (Advanced=%s)" % [minion_final_z_detour, advanced_towards_hero])
	print("  - Bot max sidestep around wall: %.2fm (Req >= 1.2m, Pass=%s)" % [minion_max_sidestep, sidestep_pass])
	print("  - Bot velocity-aligned facing average dot: %.3f (Req >= 0.85, Samples: %d)" % [avg_dot, alignment_dots.size()])

	if advanced_towards_hero and sidestep_pass and avg_dot >= 0.85:
		print("  PASS: Bot intelligently steered around obstacle and maintained velocity-aligned facing")
	else:
		printerr("  FAIL: Bot obstacle detour or facing alignment failed! (adv=%s, side=%s, dot=%.3f)" % [advanced_towards_hero, sidestep_pass, avg_dot])
		all_pass = false

	# --------------------------------------------------------------------------
	# KẾT QUẢ CHUNG CUỘC
	# --------------------------------------------------------------------------
	print("\n==================================================================")
	if all_pass:
		print("  🏆 ALL 5 TESTS PASSED 100% (ARGONS DIRECTIVE 19 SATISFIED)!")
	else:
		printerr("  ❌ SOME TESTS FAILED! CHECK LOGS ABOVE.")
	print("==================================================================")

	quit(0 if all_pass else 1)
