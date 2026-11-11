class_name HeroKnight3D
extends CharacterBody3D

# ==============================================================================
# HERO KNIGHT 3D — DIRECTIVE 16 (PHASE 4 & 6)
# Điều khiển duy nhất 1 Knight.glb: chuyển động mượt mà 12 kiểu dáng,
# leo cầu thang 3 tầng tự động (_apply_stair_step_up), ngắm chuột Raycast 3D đa tầng.
# Đòn đánh thường LMB chém trúng quái 100% qua _apply_melee_hit_detection.
# CharacterBody3D | Collision Layer 2, Mask 1|4
# Pure AnimationPlayer cross-fade 0.12s (NO AnimationTree)
# ==============================================================================

# --- Tốc độ & Vật lý ---
const MOVE_SPEED: float = 6.5
const RUN_SPEED: float = 6.5
const WALK_SPEED: float = 3.2
const DASH_SPEED: float = 14.0
const DASH_DURATION: float = 0.35
const JUMP_VELOCITY: float = 8.5
const GRAVITY: float = 25.0
const ROTATION_SPEED: float = 16.0
const CROSS_FADE_TIME: float = 0.12

# --- Chiến đấu ---
const MELEE_RANGE: float = 2.8
const MELEE_DAMAGE: float = 25.0
const SPIN_RANGE: float = 3.5
const SPIN_DAMAGE: float = 35.0
const SWORD_TRAIL_DURATION: float = 0.28
const COMBO_WINDOW: float = 0.45
const COOLDOWN_Q: float = 5.0
const COOLDOWN_RMB: float = 3.5
const COOLDOWN_E: float = 6.0
const MAX_E_THROW_RANGE: float = 7.5

# --- Animation Names (KayKit 75 anims) ---
const ANIM_IDLE := "Idle"
const ANIM_WALK := "Walking_A"
const ANIM_RUN := "Running_A"
const ANIM_JUMP_START := "Jump_Start"
const ANIM_JUMP_IDLE := "Jump_Idle"
const ANIM_JUMP_LAND := "Jump_Land"
const ANIM_DODGE_FWD := "Dodge_Forward"
const ANIM_ATTACK_SLICE_H := "1H_Melee_Attack_Slice_Horizontal"
const ANIM_ATTACK_SLICE_D := "1H_Melee_Attack_Slice_Diagonal"
const ANIM_ATTACK_CHOP := "1H_Melee_Attack_Chop"
const ANIM_BLOCK := "Block"
const ANIM_ATTACK_STAB := "1H_Melee_Attack_Stab"
const ANIM_SPIN := "2H_Melee_Attack_Spinning"
const ANIM_THROW := "Throw"
const ANIM_HIT := "Hit_A"
const ANIM_DEATH := "Death_A"

# --- Combo sequence ---
const COMBO_SEQUENCE: Array[String] = [ANIM_ATTACK_SLICE_H, ANIM_ATTACK_SLICE_D, ANIM_ATTACK_CHOP]

# --- Node References ---
var visual_root: Node3D = null
var skeleton: Skeleton3D = null
var anim_player: AnimationPlayer = null
var sword_instance: Node3D = null
var blade_center_marker: Marker3D = null
var blade_tip_marker: Marker3D = null
var sword_trail_particles: Array[GPUParticles3D] = []

# --- State ---
var _action_lock_timer: float = 0.0
var _sword_trail_timer: float = 0.0
var _combo_index: int = 0
var _combo_timer: float = 0.0
var _is_dead: bool = false
var _jump_state: int = 0  # 0=ground, 1=rising, 2=falling, 3=landing
var _landing_timer: float = 0.0
var _current_anim: String = ""
var _dash_dir: Vector3 = Vector3.ZERO
var _dash_timer: float = 0.0
var _last_safe_floor_pos: Vector3 = Vector3(0.0, 0.05, 4.0)
var external_move_dir: Vector3 = Vector3.ZERO
var _stuck_timer: float = 0.0
var _rebound_timer: float = 0.0
var _rebound_vel: Vector3 = Vector3.ZERO
var _iframe_timer: float = 0.0
var _is_spinning_q: bool = false
var _spin_timer: float = 0.0
var _throw_timer: float = 0.0
var _is_throwing_e: bool = false
var _lunge_timer: float = 0.0
var _lunge_dir: Vector3 = Vector3.ZERO
var _cd_q_timer: float = 0.0
var _cd_rmb_timer: float = 0.0
var _cd_e_timer: float = 0.0
var _buffered_action: String = ""
var _buffer_timer: float = 0.0
var _facing_angle: float = 0.0
var _combat_facing_lock_timer: float = 0.0
var _rmb_cleave_timer: float = 0.0
var _rmb_cleave_dir: Vector3 = Vector3.ZERO
var _rmb_wave_spawned: bool = false

# --- Stats ---
var hp: float = 100.0
var max_hp: float = 100.0

# --- Task 23.4: Bộ đọc phím vật lý trực tiếp U - I - O - P (Chống Unikey nuốt phím) ---
var _prev_skill_phys_keys: Dictionary = {
	KEY_U: false,
	KEY_I: false,
	KEY_O: false,
	KEY_P: false
}

func _is_skill_key_just_pressed(phys_key: Key, action_name: String) -> Dictionary:
	var has_focus := true
	var win := get_window()
	if win and DisplayServer.get_name() != "headless":
		has_focus = win.has_focus()
	if not has_focus:
		_prev_skill_phys_keys[phys_key] = false
		return {"pressed": false, "from_keyboard": false}
	var key_down := Input.is_physical_key_pressed(phys_key)
	var was_down: bool = _prev_skill_phys_keys.get(phys_key, false)
	_prev_skill_phys_keys[phys_key] = key_down
	var kb_just_pressed := key_down and not was_down
	var action_just_pressed := Input.is_action_just_pressed(action_name)
	return {
		"pressed": kb_just_pressed or action_just_pressed,
		"from_keyboard": kb_just_pressed
	}

## Khi bấm U / I / P trên bàn phím: Ưu tiên nhắm vào Bot gần nhất trong tầm đánh trước mặt, hoặc đánh theo hướng chạy WASD / hướng mặt hiện tại
func _get_smart_keyboard_aim_direction(max_auto_aim_range: float = 4.2) -> Vector3:
	var move_vec := _get_movement_input_vector()
	var base_dir := move_vec if move_vec.length_squared() > 0.01 else _get_forward_dir()

	var best_bot_dir := Vector3.ZERO
	var best_dist := max_auto_aim_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy is Node3D and not enemy.get("is_dead"):
			var diff: Vector3 = (enemy as Node3D).global_position - global_position
			if absf(diff.y) <= 2.2:
				diff.y = 0.0
				var d := diff.length()
				if d > 0.05 and d <= best_dist:
					var dir_to_bot := diff.normalized()
					if base_dir.dot(dir_to_bot) >= -0.15 or d <= 2.2:
						best_dist = d
						best_bot_dir = dir_to_bot
	if best_bot_dir.length_squared() > 0.01:
		return best_bot_dir
	return base_dir


func _ready() -> void:
	# --- Group & Collision ---
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4

	# Task 23.4: Đăng ký thêm KEY_U, KEY_I, KEY_O, KEY_P vào InputMap cho các action tương ứng
	var map_bindings := {
		"skill_lmb": KEY_U,
		"skill_rmb": KEY_I,
		"skill_q": KEY_O,
		"skill_e": KEY_P
	}
	for act in map_bindings:
		if not InputMap.has_action(act):
			InputMap.add_action(act)
		var ev := InputEventKey.new()
		ev.physical_keycode = map_bindings[act]
		ev.keycode = map_bindings[act]
		InputMap.action_add_event(act, ev)

	# --- Cấu hình CharacterBody3D chuẩn leo dốc / cầu thang (Directive 19 & 21) ---
	floor_snap_length = 0.60
	floor_max_angle = deg_to_rad(62.0)
	floor_stop_on_slope = true
	floor_constant_speed = true
	floor_block_on_wall = true
	safe_margin = 0.05
	wall_min_slide_angle = deg_to_rad(10.0)

	# --- Collision Shape (Task 23.3: tăng Capsule radius = 0.50m) ---
	var col_shape := CollisionShape3D.new()
	col_shape.name = "PlayerCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.50
	capsule.height = 1.80
	col_shape.shape = capsule
	col_shape.position = Vector3(0.0, 0.90, 0.0)
	add_child(col_shape)

	# --- Visual Root ---
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)

	# --- Instantiate Knight.glb ---
	var knight_scene: PackedScene = load(KayKitAssetRegistry.HERO_KNIGHT) as PackedScene
	if knight_scene == null:
		push_error("[HeroKnight3D] Failed to load Knight.glb!")
		return

	var knight_model: Node3D = knight_scene.instantiate() as Node3D
	knight_model.name = "KnightModel"
	visual_root.add_child(knight_model)

	# --- Setup Animation Binder (Opus 4.6) ---
	var bind_result: Dictionary = KayKitAnimationBinder.setup_and_bind_internal_animations(knight_model)
	if bind_result.is_empty():
		push_error("[HeroKnight3D] Animation binding failed!")
		return

	skeleton = bind_result["skeleton"]
	anim_player = bind_result["anim_player"]

	# --- Dọn vũ khí mặc định, gắn Sword + Shield ---
	KayKitAnimationBinder.clear_all_hand_slots(skeleton)

	await get_tree().process_frame

	# Gắn kiếm tay phải (kèm Blade Markers)
	sword_instance = KayKitAnimationBinder.attach_weapon_to_bone(
		skeleton, "handslot.r", KayKitAssetRegistry.WEAPON_SWORD, true
	)
	if sword_instance:
		blade_center_marker = sword_instance.get_node_or_null("BladeCenterMarker") as Marker3D
		blade_tip_marker = sword_instance.get_node_or_null("BladeTipMarker") as Marker3D

	# Gắn khiên tay trái
	KayKitAnimationBinder.attach_weapon_to_bone(
		skeleton, "handslot.l", KayKitAssetRegistry.WEAPON_SHIELD, false
	)

	# --- Gắn VFX vệt kiếm ---
	if blade_center_marker and blade_tip_marker:
		sword_trail_particles = KayKitVFXManager.attach_sword_trail_particles(
			blade_center_marker, blade_tip_marker
		)

	# --- Play Idle ---
	_play_anim(ANIM_IDLE)


func _get_raw_physical_movement_input() -> Vector2:
	# Nếu cửa sổ game mất tiêu điểm (Alt-Tab), dừng ngay lập tức
	if not get_window().has_focus():
		_force_release_all_movement_actions()
		return Vector2.ZERO

	# Đọc trực tiếp phím vật lý trên phần cứng (Bất chấp Unikey/EVKey đang bật tiếng Việt!)
	var p_right := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	var p_left  := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var p_down  := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	var p_up    := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)

	# Nếu không có phím vật lý nào đang được giữ trên bàn phím -> Xả sạch mọi Action bị kẹt!
	if not (p_right or p_left or p_down or p_up):
		_force_release_all_movement_actions()
		return Vector2.ZERO

	var raw := Vector2(
		(1.0 if p_right else 0.0) - (1.0 if p_left else 0.0),
		(1.0 if p_down else 0.0) - (1.0 if p_up else 0.0)
	)
	return raw.normalized() if raw.length_squared() > 1.0 else raw

func _force_release_all_movement_actions() -> void:
	for act in ["move_up", "move_down", "move_left", "move_right", "move_forward", "move_backward"]:
		if Input.is_action_pressed(act):
			Input.action_release(act)

func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	# Directive 18: Khóa cứng rotation của node cha CharacterBody3D = 0, chỉ xoay visual_root
	rotation = Vector3.ZERO

	# --- Chốt bảo hiểm phục hồi tọa độ an toàn chống rơi mép map ---
	if is_on_floor() and global_position.y >= -0.05:
		_last_safe_floor_pos = global_position
	if global_position.y < -1.0:
		global_position = _last_safe_floor_pos + Vector3(0.0, 0.15, 0.0)
		velocity = Vector3.ZERO

	# --- Timers ---
	if _iframe_timer > 0.0:
		_iframe_timer -= delta
	if _action_lock_timer > 0.0:
		_action_lock_timer -= delta
	if _sword_trail_timer > 0.0:
		_sword_trail_timer -= delta
		if _sword_trail_timer <= 0.0:
			KayKitVFXManager.disable_sword_trails(sword_trail_particles)
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_index = 0
	if _landing_timer > 0.0:
		_landing_timer -= delta
		if _landing_timer <= 0.0:
			_jump_state = 0

	# --- Cooldowns (Task 21.1 & 21.2) ---
	_cd_q_timer = maxf(0.0, _cd_q_timer - delta)
	_cd_rmb_timer = maxf(0.0, _cd_rmb_timer - delta)
	_cd_e_timer = maxf(0.0, _cd_e_timer - delta)

	# --- Combat Facing Lock (Task 21.5) ---
	if _combat_facing_lock_timer > 0.0:
		_combat_facing_lock_timer -= delta
		if visual_root != null:
			visual_root.rotation.y = _facing_angle

	# --- Input Buffer (0.18s, Task 21.2) ---
	if _buffer_timer > 0.0:
		_buffer_timer -= delta
		if _buffered_action != "" and _action_lock_timer <= 0.0:
			if _buffered_action == "skill_q" and _cd_q_timer <= 0.0 and not _is_spinning_q:
				_buffered_action = ""
				_buffer_timer = 0.0
				_do_spin_attack()
			elif _buffered_action == "skill_rmb" and _cd_rmb_timer <= 0.0:
				_buffered_action = ""
				_buffer_timer = 0.0
				_do_rmb_cross_cleave()
			elif _buffered_action == "skill_e" and _cd_e_timer <= 0.0 and not _is_throwing_e:
				_buffered_action = ""
				_buffer_timer = 0.0
				_do_ranged_throw()
		if _buffer_timer <= 0.0:
			_buffered_action = ""

	# --- RMB Solar Cross-Cleave Dash (Task 21.3) ---
	if _rmb_cleave_timer > 0.0:
		_rmb_cleave_timer -= delta
		velocity.x = _rmb_cleave_dir.x * 15.7
		velocity.z = _rmb_cleave_dir.z * 15.7
		if visual_root:
			visual_root.rotation.y = _facing_angle
		_apply_stair_step_up(Vector3(velocity.x, 0.0, velocity.z), delta)
		move_and_slide()
		if _rmb_cleave_timer <= 0.0 and not _rmb_wave_spawned:
			_rmb_wave_spawned = true
			_trigger_rmb_phase_two(_rmb_cleave_dir)
		_apply_wall_micro_separation(delta)
		return

	# --- Gravity ---
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	# --- Space: Instant Dash-Cancel (Task 19.4 Kỹ thuật C) ---
	# Hủy mọi đòn đánh tức thì khi bấm Space để né đòn
	if Input.is_action_just_pressed("dash"):
		_action_lock_timer = 0.0
		_is_spinning_q = false
		_is_throwing_e = false
		_lunge_timer = 0.0
		_rmb_cleave_timer = 0.0
		_do_dodge()
		return

	# --- Rebound Override (Task 19.3 Lớp 2): Dội ngược khi lướt trúng quái ---
	if _rebound_timer > 0.0:
		_rebound_timer -= delta
		velocity.x = _rebound_vel.x
		velocity.z = _rebound_vel.z
		move_and_slide()
		return

	# --- Dash Override (Task 23.2: Lướt mượt từ dưới lên cầu thang 0% bị chặn) ---
	if _dash_timer > 0.0:
		_dash_timer -= delta
		var stair_state := _detect_stair_slope_ahead(_dash_dir)
		var is_on_stairs: bool = stair_state["on_stairs"]
		var slope_dy: float = stair_state["slope_dy"]

		if is_on_stairs:
			floor_block_on_wall = false
			var effective_dash_speed := DASH_SPEED * 0.88
			velocity.x = _dash_dir.x * effective_dash_speed
			velocity.z = _dash_dir.z * effective_dash_speed
			# Nếu đang lướt theo chiều đi lên dốc cầu thang (slope_dy > 0), cấp vận tốc Y bám theo mặt dốc
			if slope_dy > 0.02:
				velocity.y = clampf((slope_dy / 0.85) * effective_dash_speed, 4.0, effective_dash_speed * 1.05)
			elif slope_dy < -0.02:
				velocity.y = clampf((slope_dy / 0.85) * effective_dash_speed, -effective_dash_speed * 1.05, -1.0)
			_apply_stair_step_up(Vector3(velocity.x, 0.0, velocity.z), delta, true)
		else:
			floor_block_on_wall = true
			velocity.x = _dash_dir.x * DASH_SPEED
			velocity.z = _dash_dir.z * DASH_SPEED

		move_and_slide()
		floor_block_on_wall = true
		_check_dash_impact_against_enemies()
		return

	# --- Xoay Kiếm Q Đang Hoạt Động (Task 19.4 Kỹ thuật B & Task 21.2 Vacuum Pull) ---
	if _is_spinning_q:
		_spin_timer -= delta
		if _spin_timer <= 0.0:
			_is_spinning_q = false
			_action_lock_timer = 0.0
			if anim_player:
				anim_player.speed_scale = 1.0
		else:
			# Kéo nhẹ Bot về phía nhân vật 0.35m trong 3 nhịp đầu (Whirlwind Vacuum Pull)
			if _spin_timer > 0.10:
				var pull_bots := get_tree().get_nodes_in_group("enemies")
				for pb in pull_bots:
					if is_instance_valid(pb) and pb is CharacterBody3D and not pb.get("is_dead"):
						var diff_vec: Vector3 = global_position - (pb as Node3D).global_position
						diff_vec.y = 0.0
						var d_len := diff_vec.length()
						if d_len > 0.4 and d_len <= 3.4:
							var pull_dir := diff_vec.normalized()
							(pb as CharacterBody3D).global_position += pull_dir * minf(0.35 * delta * 7.5, d_len - 0.4)

			var spin_mv := _get_movement_input_vector()
			if spin_mv.length_squared() > 0.01:
				velocity.x = spin_mv.x * (RUN_SPEED * 0.80)
				velocity.z = spin_mv.z * (RUN_SPEED * 0.80)
				if visual_root:
					if _combat_facing_lock_timer > 0.0:
						visual_root.rotation.y = _facing_angle
					else:
						visual_root.rotation.y = atan2(spin_mv.x, spin_mv.z)
			else:
				velocity.x = 0.0
				velocity.z = 0.0
			_apply_stair_step_up(Vector3(velocity.x, 0.0, velocity.z), delta)
			move_and_slide()
			_apply_wall_micro_separation(delta)
			return

	# --- Ném Bom Khói E Đang Hoạt Động (Task 19.4 Kỹ thuật B: Vừa di chuyển vừa ném) ---
	if _is_throwing_e:
		_throw_timer -= delta
		if _throw_timer <= 0.0:
			_is_throwing_e = false
			_action_lock_timer = 0.0
			if anim_player:
				anim_player.speed_scale = 1.0
		else:
			var throw_mv := _get_movement_input_vector()
			if throw_mv.length_squared() > 0.01:
				velocity.x = throw_mv.x * RUN_SPEED
				velocity.z = throw_mv.z * RUN_SPEED
				if visual_root:
					if _combat_facing_lock_timer > 0.0:
						visual_root.rotation.y = _facing_angle
					else:
						visual_root.rotation.y = atan2(throw_mv.x, throw_mv.z)
			else:
				velocity.x = 0.0
				velocity.z = 0.0
			_apply_stair_step_up(Vector3(velocity.x, 0.0, velocity.z), delta)
			move_and_slide()
			_apply_wall_micro_separation(delta)
			return

	# --- Bước Tấn Công Cận Chiến (Task 19.4 Kỹ thuật A: Step-Lunge 0.14s) ---
	if _lunge_timer > 0.0:
		_lunge_timer -= delta
		velocity.x = _lunge_dir.x * 6.2
		velocity.z = _lunge_dir.z * 6.2
		if visual_root:
			if _combat_facing_lock_timer > 0.0:
				visual_root.rotation.y = _facing_angle
			elif _lunge_dir.length_squared() > 0.01:
				visual_root.rotation.y = atan2(_lunge_dir.x, _lunge_dir.z)
		_apply_stair_step_up(Vector3(velocity.x, 0.0, velocity.z), delta)
		move_and_slide()
		_apply_wall_micro_separation(delta)
		return
	elif _action_lock_timer > 0.0:
		# Pha 2 (0.14s -> 0.24s): Đặt trụ vững, chém trúng đích, 0% trượt chân
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		_apply_wall_micro_separation(delta)
		return

	# --- Input Di Chuyển & Chiến Đấu Bình Thường (can_act) ---
	var input_dir := _get_movement_input_vector()
	var can_act: bool = _action_lock_timer <= 0.0 and _jump_state == 0

	# --- Xử lý hành động chiến đấu & Bộ đệm phím (Task 23.4: U-I-O-P & Smart Auto-Aim) ---
	var trig_u := _is_skill_key_just_pressed(KEY_U, "skill_lmb")
	var trig_i := _is_skill_key_just_pressed(KEY_I, "skill_rmb")
	var trig_o := _is_skill_key_just_pressed(KEY_O, "skill_q")
	var trig_p := _is_skill_key_just_pressed(KEY_P, "skill_e")

	if trig_i["pressed"]:
		var aim_i := _get_smart_keyboard_aim_direction(5.5) if trig_i["from_keyboard"] else _get_stable_aim_direction()
		if can_act and _cd_rmb_timer <= 0.0:
			_do_rmb_cross_cleave(aim_i)
			return
		elif _cd_rmb_timer <= 0.18 or _action_lock_timer <= 0.18:
			_buffered_action = "skill_rmb"
			_buffer_timer = 0.18

	if trig_o["pressed"]:
		var aim_o := _get_smart_keyboard_aim_direction(4.0) if trig_o["from_keyboard"] else _get_stable_aim_direction()
		if can_act and _cd_q_timer <= 0.0 and not _is_spinning_q:
			_do_spin_attack(aim_o)
			return
		elif _cd_q_timer <= 0.18 or _action_lock_timer <= 0.18:
			_buffered_action = "skill_q"
			_buffer_timer = 0.18

	if trig_p["pressed"]:
		if can_act and _cd_e_timer <= 0.0 and not _is_throwing_e:
			if trig_p["from_keyboard"]:
				var throw_dir := _get_smart_keyboard_aim_direction(7.5)
				_do_ranged_throw(global_position + throw_dir * 4.8)
			else:
				_do_ranged_throw()
			return
		elif _cd_e_timer <= 0.18 or _action_lock_timer <= 0.18:
			_buffered_action = "skill_e"
			_buffer_timer = 0.18

	if can_act:
		if trig_u["pressed"]:
			var aim_u := _get_smart_keyboard_aim_direction(3.5) if trig_u["from_keyboard"] else _get_stable_aim_direction()
			_do_melee_combo(aim_u)
			return

		# C / Jump: Nhảy
		if Input.is_action_just_pressed("interact") and is_on_floor():
			_do_jump()

	# --- Di chuyển & Chạy Running_A (Dừng tức thì khi nhả phím) ---
	if _action_lock_timer <= 0.0 and _jump_state == 0:
		if input_dir.length_squared() > 0.01:
			velocity.x = input_dir.x * RUN_SPEED
			velocity.z = input_dir.z * RUN_SPEED
			if _combat_facing_lock_timer <= 0.0:
				var target_yaw := atan2(input_dir.x, input_dir.z)
				_facing_angle = lerp_angle(
					_facing_angle,
					target_yaw,
					minf(1.0, ROTATION_SPEED * delta)
				)
				if visual_root:
					visual_root.rotation.y = _facing_angle
			else:
				if visual_root:
					visual_root.rotation.y = _facing_angle
			_play_anim(ANIM_RUN)
		else:
			# Dừng ngay lập tức khi thả tay khỏi phím
			velocity.x = 0.0
			velocity.z = 0.0
			if is_on_floor():
				_play_anim(ANIM_IDLE)

	# --- Jump animation states ---
	if _jump_state == 1:
		if velocity.y <= 0.0:
			_jump_state = 2
			_play_anim(ANIM_JUMP_IDLE)
	elif _jump_state == 2:
		if is_on_floor():
			_jump_state = 3
			_landing_timer = 0.25
			_play_anim(ANIM_JUMP_LAND)

	# Tự động bước lên bậc thang mượt mà
	_apply_stair_step_up(Vector3(velocity.x, 0.0, velocity.z), delta)
	move_and_slide()

	# --- Corner Crowd Shove (Task 19.3 Lớp 3: Chen vai đẩy mềm lính khi đi bộ) ---
	if input_dir.length_squared() > 0.01:
		for i in range(get_slide_collision_count()):
			var col := get_slide_collision(i)
			var col_obj = col.get_collider()
			if col_obj is Node and (col_obj as Node).is_in_group("enemies"):
				if col_obj.has_method("apply_knockback"):
					col_obj.apply_knockback(input_dir * 6.5)

	# --- Anti-Stuck Depenetration Guard (Giải cứu kẹt góc) ---
	if get_slide_collision_count() >= 2:
		var horiz_spd := Vector2(velocity.x, velocity.z).length()
		if horiz_spd < 0.05 and input_dir.length_squared() > 0.01:
			_stuck_timer += delta
			if _stuck_timer >= 0.35:
				var push_dir := Vector3.ZERO
				for i in range(get_slide_collision_count()):
					var c := get_slide_collision(i)
					push_dir += c.get_normal()
				push_dir.y = 0.0
				if push_dir.length_squared() > 0.01:
					global_position += push_dir.normalized() * 0.15
				_stuck_timer = 0.0
		else:
			_stuck_timer = 0.0
	else:
		_stuck_timer = 0.0

	# Đảm bảo visual_root luôn khóa chặt theo _facing_angle khi combat facing lock còn hiệu lực
	if visual_root and _combat_facing_lock_timer > 0.0:
		visual_root.rotation.y = _facing_angle

	# --- Đệm Chống Lún Tường / Tượng 8 Hướng (Task 21.4) ---
	_apply_wall_micro_separation(delta)


# ==============================================================================
# HÀM BƯỚC LÊN BẬC THANG TỰ ĐỘNG (_apply_stair_step_up)
# Giới hạn chỉ kích hoạt khi vật cản phía trước thuộc group "stairs"
# Khóa hoàn toàn khi đang Dash (Task 19.2)
# ==============================================================================
func _apply_stair_step_up(move_dir: Vector3, delta: float, is_dashing: bool = false) -> void:
	if _dash_timer > 0.0 and not is_dashing:
		return
	if move_dir.length_squared() < 0.01:
		return
	var space_state := get_world_3d().direct_space_state
	var horiz_dir := Vector3(move_dir.x, 0.0, move_dir.z).normalized()

	# Tia 1: Quét ngang ở độ cao cổ chân (0.15m) đến đầu gối xem có gặp bậc thang không
	var foot_from := global_position + Vector3(0.0, 0.15, 0.0)
	var foot_to := foot_from + horiz_dir * 0.70
	var foot_query := PhysicsRayQueryParameters3D.create(foot_from, foot_to, 1)
	foot_query.exclude = [get_rid()]
	var foot_hit := space_state.intersect_ray(foot_query)

	if not foot_hit.is_empty():
		var col_obj = foot_hit.get("collider", null)
		if col_obj == null or not col_obj.is_in_group("stairs"):
			return

		# Tia 2: Bắn từ phía trước ở độ cao 0.85m thẳng xuống để tìm mặt trên của bậc thang
		var step_from := global_position + horiz_dir * 0.60 + Vector3(0.0, 0.85, 0.0)
		var step_to := global_position + horiz_dir * 0.60 + Vector3(0.0, 0.02, 0.0)
		var down_query := PhysicsRayQueryParameters3D.create(step_from, step_to, 1)
		down_query.exclude = [get_rid()]
		var down_hit := space_state.intersect_ray(down_query)

		if not down_hit.is_empty():
			var down_obj = down_hit.get("collider", null)
			if down_obj != null and not down_obj.is_in_group("stairs"):
				return
			var target_y: float = down_hit["position"].y
			var step_h: float = target_y - global_position.y
			var normal: Vector3 = down_hit["normal"]
			if step_h > 0.02 and step_h <= 0.65 and normal.y >= 0.55:
				global_position.y = move_toward(global_position.y, target_y + 0.02, 12.0 * delta)
				velocity.y = maxf(velocity.y, 0.0)

## Cảm biến dốc cầu thang phía trước khi Dash (Task 23.2)
func _detect_stair_slope_ahead(dir: Vector3) -> Dictionary:
	var on_stairs := false
	var slope_dy := 0.0
	if is_on_floor() and get_floor_normal().y < 0.96:
		on_stairs = true
		slope_dy = 0.85
	var space_state := get_world_3d().direct_space_state
	var horiz := Vector3(dir.x, 0.0, dir.z).normalized()
	if horiz.length_squared() > 0.01:
		# Tia 1: Quét ngang mũi giày (0.15m) và ống đồng (0.45m) phía trước 1.2m
		for h_y in [0.15, 0.45]:
			var from_p := global_position + Vector3(0.0, h_y, 0.0)
			var q_fwd := PhysicsRayQueryParameters3D.create(from_p, from_p + horiz * 1.2, 1)
			q_fwd.exclude = [get_rid()]
			var hit_fwd := space_state.intersect_ray(q_fwd)
			if not hit_fwd.is_empty():
				var col_obj = hit_fwd.get("collider", null)
				if (col_obj is Node and (col_obj as Node).is_in_group("stairs")) or (hit_fwd["normal"].y > 0.45 and hit_fwd["normal"].y < 0.96):
					on_stairs = true
					if slope_dy <= 0.02:
						slope_dy = 0.85
					break
		# Tia 2: Đo độ chênh lệch độ cao mặt đất/dốc ở điểm phía trước 0.85m
		var top_probe := global_position + horiz * 0.85 + Vector3(0.0, 1.4, 0.0)
		var bot_probe := global_position + horiz * 0.85 + Vector3(0.0, -1.2, 0.0)
		var q_down := PhysicsRayQueryParameters3D.create(top_probe, bot_probe, 1)
		q_down.exclude = [get_rid()]
		var hit_down := space_state.intersect_ray(q_down)
		if not hit_down.is_empty():
			var down_col = hit_down.get("collider", null)
			if (down_col is Node and (down_col as Node).is_in_group("stairs")) or (hit_down["normal"].y > 0.45 and hit_down["normal"].y < 0.96):
				on_stairs = true
			var dy: float = hit_down["position"].y - global_position.y
			if dy > slope_dy:
				slope_dy = dy
	return {"on_stairs": on_stairs, "slope_dy": slope_dy}


# ==============================================================================
# HÀM LẤY VECTOR DI CHUYỂN THEO CAMERA HOẶC EXTERNAL
# ==============================================================================
func _get_movement_input_vector() -> Vector3:
	if external_move_dir.length_squared() > 0.01:
		return external_move_dir.normalized()
	var input_vec := _get_raw_physical_movement_input()
	if input_vec.length_squared() > 0.001:
		var cam := get_viewport().get_camera_3d()
		var cam_right := Vector3.RIGHT
		var cam_forward := Vector3.BACK
		if cam != null:
			cam_right = Vector3(cam.global_transform.basis.x.x, 0.0, cam.global_transform.basis.x.z).normalized()
			cam_forward = Vector3(-cam.global_transform.basis.z.x, 0.0, -cam.global_transform.basis.z.z).normalized()
		return (cam_right * input_vec.x + cam_forward * (-input_vec.y)).normalized()
	return Vector3.ZERO


# ==============================================================================
# KIỂM TRA VA CHẠM KHI LƯỚT VÀO BOT (DỘI LẠI + HÚC VĂNG BOT)
# ==============================================================================
func _check_dash_impact_against_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.get("is_dead"):
			continue
		var e_node := enemy as Node3D
		var diff := e_node.global_position - global_position
		diff.y = 0.0
		var dist := diff.length()
		if dist <= 1.15:
			var dot_fwd := _dash_dir.dot(diff.normalized()) if dist > 0.001 else 1.0
			if dot_fwd >= 0.2:
				# 1. Chấm dứt đà tiến của cú Lướt ngay lập tức (KHÔNG XUYÊN QUA BOT!)
				_dash_timer = 0.0

				# 2. Nhân vật bị dội nảy ngược lại phía sau ~0.8m trong 0.16 giây
				_rebound_timer = 0.16
				_rebound_vel = -_dash_dir * 6.2
				velocity.x = _rebound_vel.x
				velocity.z = _rebound_vel.z

				# 3. Húc văng con Bot bị đụng (và các Bot đứng sát cạnh nó trong bán kính 1.8m) lùi ra xa 2.0m!
				for near_enemy in enemies:
					if is_instance_valid(near_enemy) and near_enemy.has_method("apply_dash_impact_knockback"):
						var ne_node := near_enemy as Node3D
						if ne_node and (ne_node == e_node or ne_node.global_position.distance_to(e_node.global_position) <= 1.8):
							var push_dir: Vector3 = ne_node.global_position - global_position
							push_dir.y = 0.0
							if push_dir.length_squared() < 0.01:
								push_dir = _dash_dir
							near_enemy.apply_dash_impact_knockback(push_dir.normalized() * 14.5, 0.38)

				# 4. Hiệu ứng va chạm & Sóng Xung Kích (Directive 20 Task 20.4 Chiêu Space)
				var impact_pt := (global_position + e_node.global_position) * 0.5 + Vector3(0.0, 0.9, 0.0)
				KayKitVFXManager.spawn_dash_impact(impact_pt, _dash_dir)
				KayKitVFXManager.spawn_hit_impact_at_chest(e_node)
				break


# ==============================================================================
# ACTIONS (TASK 19.4: FLUID COMBAT & DIRECTIVE 21: AIM-FACING SYNC & RMB CLEAVE)
# ==============================================================================

func _get_forward_dir() -> Vector3:
	return Vector3(sin(_facing_angle), 0.0, cos(_facing_angle)).normalized()

func _get_stable_aim_direction() -> Vector3:
	var raw_cursor := _get_cursor_world_pos()
	var diff := Vector3(raw_cursor.x - global_position.x, 0.0, raw_cursor.z - global_position.z)
	if diff.length() < 0.42:
		return _get_forward_dir()
	return diff.normalized()

func _snap_to_aim_direction(aim_dir: Vector3, lock_duration: float = 0.30) -> void:
	if aim_dir.length_squared() > 0.001:
		_facing_angle = atan2(aim_dir.x, aim_dir.z)
		if visual_root != null:
			visual_root.rotation.y = _facing_angle
	_combat_facing_lock_timer = maxf(_combat_facing_lock_timer, lock_duration)

func _compute_clamped_bomb_target(raw_cursor_pos: Vector3) -> Vector3:
	var space_state := get_world_3d().direct_space_state
	var flat_offset := Vector3(raw_cursor_pos.x - global_position.x, 0.0, raw_cursor_pos.z - global_position.z)
	var dist := flat_offset.length()
	if dist > MAX_E_THROW_RANGE:
		flat_offset = flat_offset.normalized() * MAX_E_THROW_RANGE
	elif dist < 0.5:
		flat_offset = _get_forward_dir() * 1.5

	var candidate_xz := global_position + flat_offset

	# 1. Bắn tia ngang ở độ cao ngực (Y + 1.0m) để không ném xuyên qua tường biên
	var wall_ray := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0.0, 1.0, 0.0),
		candidate_xz + Vector3(0.0, 1.0, 0.0),
		1
	)
	wall_ray.exclude = [get_rid()]
	var wall_hit := space_state.intersect_ray(wall_ray)
	if not wall_hit.is_empty():
		candidate_xz = wall_hit["position"] + wall_hit["normal"] * 0.6

	# 2. Bắn tia từ trên cao xuống để bắt dính chính xác mặt sàn đa tầng
	var floor_ray := PhysicsRayQueryParameters3D.create(
		Vector3(candidate_xz.x, maxf(global_position.y, raw_cursor_pos.y) + 10.0, candidate_xz.z),
		Vector3(candidate_xz.x, -2.0, candidate_xz.z),
		1
	)
	floor_ray.exclude = [get_rid()]
	var floor_hit := space_state.intersect_ray(floor_ray)
	if not floor_hit.is_empty():
		return floor_hit["position"] + Vector3(0.0, 0.05, 0.0)
	return Vector3(candidate_xz.x, global_position.y, candidate_xz.z)

# Task 23.5: Tắt hoàn toàn _apply_wall_micro_separation() để loại bỏ 100% rung giật vị trí
func _apply_wall_micro_separation(_delta: float) -> void:
	pass

func _do_melee_combo(aim_override: Vector3 = Vector3.ZERO) -> void:
	var aim_dir := aim_override if aim_override.length_squared() > 0.001 else _get_stable_aim_direction()
	_snap_to_aim_direction(aim_dir, 0.30)
	var locked_attack_dir := Vector3(sin(_facing_angle), 0.0, cos(_facing_angle)).normalized()

	var current_step := _combo_index
	var anim_name: String = COMBO_SEQUENCE[_combo_index]
	_play_anim(anim_name)
	if anim_player:
		anim_player.speed_scale = 1.45

	_action_lock_timer = 0.24
	_start_sword_trail()

	var slash_pos := global_position + Vector3(0.0, 0.95, 0.0)
	KayKitVFXManager.spawn_combo_slash_vfx(current_step, slash_pos, _facing_angle)

	_lunge_dir = locked_attack_dir
	_lunge_timer = 0.14
	_combo_index = (_combo_index + 1) % COMBO_SEQUENCE.size()
	_combo_timer = COMBO_WINDOW + 0.24

	_apply_melee_hit_detection(MELEE_DAMAGE, MELEE_RANGE, false)


func _do_rmb_cross_cleave(aim_override: Vector3 = Vector3.ZERO) -> void:
	if _cd_rmb_timer > 0.0:
		return
	_cd_rmb_timer = COOLDOWN_RMB

	var aim_dir := aim_override if aim_override.length_squared() > 0.001 else _get_stable_aim_direction()
	_snap_to_aim_direction(aim_dir, 0.35)
	var locked_attack_dir := Vector3(sin(_facing_angle), 0.0, cos(_facing_angle)).normalized()

	_play_anim(ANIM_ATTACK_SLICE_H)
	if anim_player:
		anim_player.speed_scale = 1.6

	_start_sword_trail()
	_sword_trail_timer = 0.4

	_rmb_cleave_timer = 0.14
	_rmb_cleave_dir = locked_attack_dir
	_rmb_wave_spawned = false
	_action_lock_timer = 0.32

	# Phase 1: 25.0 DMG trong quạt 3.5m trước mặt
	_apply_melee_hit_detection(25.0, 3.5, false)

	# 4-layer VFX (Task 21.3)
	KayKitVFXManager.spawn_rmb_solar_cross_cleave(global_position, _facing_angle, get_tree().current_scene)


func _trigger_rmb_phase_two(fwd_dir: Vector3) -> void:
	var hit_any := false
	var enemies := get_tree().get_nodes_in_group("enemies")
	var wave_origin := global_position
	for enemy in enemies:
		if not is_instance_valid(enemy) or not (enemy is Node3D):
			continue
		var e_node := enemy as Node3D
		var diff := e_node.global_position - wave_origin
		diff.y = 0.0
		var forward_dist := fwd_dir.dot(diff)
		if forward_dist >= 0.0 and forward_dist <= 5.2:
			var perp_dist := (diff - fwd_dir * forward_dist).length()
			if perp_dist <= 2.0 and absf(e_node.global_position.y - wave_origin.y) <= 2.0:
				hit_any = true
				if enemy.has_method("take_damage"):
					enemy.take_damage(30.0, fwd_dir)
				if enemy.has_method("apply_knockback"):
					enemy.apply_knockback(fwd_dir * 11.0)
				if enemy.has_method("apply_hit_stun"):
					enemy.apply_hit_stun(0.65)
				KayKitVFXManager.spawn_cross_slash_hit_impact(e_node.global_position + Vector3(0.0, 0.95, 0.0))

	if hit_any:
		var cam := get_viewport().get_camera_3d()
		if cam != null and cam.has_method("add_screen_shake"):
			cam.add_screen_shake(0.12)
		elif cam != null and cam.has_method("add_shake"):
			cam.add_shake(0.12)


func _do_block_counter() -> void:
	_do_rmb_cross_cleave()


func _do_spin_attack(aim_override: Vector3 = Vector3.ZERO) -> void:
	if _cd_q_timer > 0.0 or _is_spinning_q:
		return
	_cd_q_timer = COOLDOWN_Q

	var aim_dir := aim_override if aim_override.length_squared() > 0.001 else _get_stable_aim_direction()
	_snap_to_aim_direction(aim_dir, 0.45)

	_play_anim(ANIM_SPIN)
	if anim_player:
		anim_player.speed_scale = 1.55
	_is_spinning_q = true
	_spin_timer = 0.45
	_action_lock_timer = 0.45

	_start_sword_trail()
	_sword_trail_timer = 0.6

	# Song Long Lốc Xoáy 360 độ (Directive 20 Task 20.4 Chiêu Q)
	KayKitVFXManager.spawn_whirlwind_360_vfx(self)

	# Sát thương diện rộng 360 độ
	_apply_melee_hit_detection(SPIN_DAMAGE, SPIN_RANGE, true)


func _do_ranged_throw(target_pos_override: Vector3 = Vector3.ZERO) -> void:
	if _cd_e_timer > 0.0 or _is_throwing_e:
		return
	_cd_e_timer = COOLDOWN_E

	var raw_cursor := target_pos_override if target_pos_override != Vector3.ZERO else _get_cursor_world_pos()
	var aim_dir := _get_stable_aim_direction()
	if target_pos_override != Vector3.ZERO:
		var d := target_pos_override - global_position
		d.y = 0.0
		if d.length_squared() > 0.01:
			aim_dir = d.normalized()
	_snap_to_aim_direction(aim_dir, 0.25)

	_play_anim(ANIM_THROW)
	if anim_player:
		anim_player.speed_scale = 1.75
	_is_throwing_e = true
	_throw_timer = 0.18
	_action_lock_timer = 0.18

	var target_pos := _compute_clamped_bomb_target(raw_cursor)
	var start_pos := global_position + Vector3(0.0, 1.2, 0.0)

	# Ám Ảnh Lôi Vụ 4 tầng & Vùng Khói Lôi Vụ Hazard Zone (Task 21.1)
	KayKitVFXManager.spawn_smoke_bomb_hazard_zone(
		get_tree().current_scene, start_pos, target_pos
	)


func _do_dodge() -> void:
	var dodge_dir := _get_movement_input_vector()
	if dodge_dir.length_squared() < 0.01:
		if visual_root:
			dodge_dir = Vector3(sin(visual_root.rotation.y), 0.0, cos(visual_root.rotation.y)).normalized()
		else:
			dodge_dir = Vector3.FORWARD

	dodge_dir = dodge_dir.normalized()
	_dash_dir = dodge_dir
	_dash_timer = DASH_DURATION
	_action_lock_timer = DASH_DURATION
	_iframe_timer = 0.35 # 0.35s Bất tử (I-Frames, Task 19.4 Kỹ thuật C)

	if visual_root:
		visual_root.rotation.y = atan2(dodge_dir.x, dodge_dir.z)

	_play_anim(ANIM_DODGE_FWD)
	KayKitVFXManager.spawn_dash_trail(self, _dash_dir)


func _do_jump() -> void:
	velocity.y = JUMP_VELOCITY
	_jump_state = 1
	_action_lock_timer = 0.1
	_play_anim(ANIM_JUMP_START)


# ==============================================================================
# HÀM PHÁT HIỆN & GÂY SÁT THƯƠNG CẬN CHIẾN CHUẨN XÁC (_apply_melee_hit_detection)
# ==============================================================================
func _apply_melee_hit_detection(damage: float, hit_radius: float = 2.8, full_circle: bool = false) -> int:
	var hit_enemies: Array[Node] = []
	var facing_dir := Vector3(sin(visual_root.rotation.y), 0.0, cos(visual_root.rotation.y)).normalized() if visual_root else Vector3.MODEL_FRONT
	var blade_zone_center := global_position + facing_dir * 1.15
	if is_instance_valid(blade_center_marker):
		blade_zone_center = blade_center_marker.global_position

	# 1. Gom toàn bộ quái từ cả group "enemies", "enemy" VÀ Physics Sphere Query (Layer 4)
	var candidates: Array[Node] = []
	for g_name in ["enemies", "enemy"]:
		for node in get_tree().get_nodes_in_group(g_name):
			if is_instance_valid(node) and node != self and not candidates.has(node):
				candidates.append(node)

	var space_state := get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = hit_radius + 0.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0.0, 0.9, 0.0))
	query.collision_mask = 4
	for hit_dict in space_state.intersect_shape(query, 16):
		var col_obj = hit_dict.get("collider")
		if is_instance_valid(col_obj) and col_obj != self and not candidates.has(col_obj):
			candidates.append(col_obj)

	# 2. Kiểm tra khoảng cách và trừ máu trực tiếp
	for target in candidates:
		if not (target is Node3D) or not target.has_method("take_damage"):
			continue
		var t_node := target as Node3D
		var t_pos := t_node.global_position
		# Cho phép chênh lệch độ cao lên tới 2.0m (đánh trúng cả trên cầu thang)
		if absf(t_pos.y - global_position.y) > 2.0:
			continue

		var flat_diff := Vector3(t_pos.x - global_position.x, 0.0, t_pos.z - global_position.z)
		var dist_to_hero := flat_diff.length()
		var dist_to_blade := Vector2(t_pos.x - blade_zone_center.x, t_pos.z - blade_zone_center.z).length()

		var is_valid_hit := false
		if full_circle:
			is_valid_hit = (dist_to_hero <= hit_radius)
		else:
			var dir_to_target := flat_diff.normalized() if dist_to_hero > 0.001 else facing_dir
			var dot_val := facing_dir.dot(dir_to_target)
			# Trúng đòn nếu: đứng sát người (<= 1.5m), hoặc gần lưỡi kiếm (<= 1.85m), hoặc trong cung quạt 160 độ phía trước
			is_valid_hit = (dist_to_hero <= 1.5) or (dist_to_blade <= 1.85) or (dist_to_hero <= hit_radius and dot_val >= -0.25)

		if is_valid_hit:
			var kb_dir := flat_diff.normalized() if dist_to_hero > 0.01 else facing_dir
			target.take_damage(damage, kb_dir)
			KayKitVFXManager.spawn_cross_slash_hit_impact(t_pos + Vector3(0.0, 0.95, 0.0))
			hit_enemies.append(target)

	return hit_enemies.size()


## Đẩy lùi lính xung quanh
func _knockback_nearby_enemies(radius: float, force: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy_node in enemies:
		if enemy_node is Node3D and is_instance_valid(enemy_node):
			var to_enemy: Vector3 = enemy_node.global_position - global_position
			to_enemy.y = 0.0
			if to_enemy.length() <= radius and to_enemy.length() > 0.01:
				var push_dir := to_enemy.normalized()
				if enemy_node.has_method("apply_knockback"):
					enemy_node.apply_knockback(push_dir * force)


## Nhận sát thương (Hỗ trợ I-Frames & Hyper-Armor khi xoay kiếm Q)
func take_damage(amount: float, _from_dir: Vector3 = Vector3.ZERO) -> void:
	if _is_dead:
		return
	# 1. Bất tử khi đang Lướt né (I-Frames, Task 19.4 Kỹ thuật C)
	if _iframe_timer > 0.0:
		return

	# 2. Hyper-Armor khi đang Xoay Kiếm Q (Giảm 60% sát thương, Task 19.4 Kỹ thuật B)
	var final_amount := amount
	if _is_spinning_q:
		final_amount *= 0.40

	hp -= final_amount
	if hp <= 0.0:
		hp = 0.0
		_die()
	else:
		if not _is_spinning_q:
			_play_anim(ANIM_HIT)
			_action_lock_timer = 0.3


func _die() -> void:
	_is_dead = true
	_play_anim(ANIM_DEATH)
	velocity = Vector3.ZERO
	collision_layer = 0


# ==============================================================================
# HELPERS
# ==============================================================================

## Phát animation với cross-fade, tránh phát lại animation đang chạy
func _play_anim(anim_name: String) -> void:
	if anim_player == null:
		return
	# Khi quay về Idle hoặc Running_A, hoàn trả tốc độ hoạt ảnh chuẩn 1.0 (Task 19.4)
	if anim_name == ANIM_IDLE or anim_name == ANIM_RUN:
		anim_player.speed_scale = 1.0

	if _current_anim == anim_name and anim_player.is_playing():
		return
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name, CROSS_FADE_TIME)
		_current_anim = anim_name
	else:
		push_warning("[HeroKnight3D] Animation not found: %s" % anim_name)


## Lấy độ dài animation
func _get_anim_length(anim_name: String) -> float:
	if anim_player and anim_player.has_animation(anim_name):
		return anim_player.get_animation(anim_name).length
	return 0.5


## Bật vệt kiếm tạm thời
func _start_sword_trail() -> void:
	KayKitVFXManager.enable_sword_trails(sword_trail_particles)
	_sword_trail_timer = SWORD_TRAIL_DURATION


## Xoay mặt tức thời về phía chuột
func _face_cursor() -> void:
	var cursor_pos := _get_cursor_world_pos()
	var aim_dir: Vector3 = cursor_pos - global_position
	aim_dir.y = 0.0
	if aim_dir.length_squared() > 0.01 and visual_root:
		visual_root.rotation.y = atan2(aim_dir.x, aim_dir.z)


## Lấy tọa độ chuột đa tầng bằng 3D Physics Raycast (Layer 1)
func _get_cursor_world_pos() -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return global_position + Vector3.FORWARD * 3.0

	if cam.has_method("get_accurate_ground_cursor_pos"):
		return cam.get_accurate_ground_cursor_pos(get_viewport())

	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := cam.project_ray_origin(mouse_pos)
	var ray_dir := cam.project_ray_normal(mouse_pos)
	var ray_end := ray_origin + ray_dir * 500.0

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1)
	var hit := space_state.intersect_ray(query)
	if not hit.is_empty():
		return hit["position"]

	var plane := Plane(Vector3.UP, global_position.y)
	var pos = plane.intersects_ray(ray_origin, ray_dir)
	return pos if pos != null else global_position
