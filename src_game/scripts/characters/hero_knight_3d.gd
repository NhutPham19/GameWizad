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

# --- Stats ---
var hp: float = 100.0
var max_hp: float = 100.0


func _ready() -> void:
	# --- Group & Collision ---
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4

	# --- Cấu hình CharacterBody3D chuẩn leo dốc / cầu thang ---
	floor_snap_length = 0.60
	floor_max_angle = deg_to_rad(58.0)
	floor_stop_on_slope = true
	floor_constant_speed = true
	floor_block_on_wall = true

	# --- Collision Shape ---
	var col_shape := CollisionShape3D.new()
	col_shape.name = "PlayerCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.75
	col_shape.shape = capsule
	col_shape.position = Vector3(0.0, 0.875, 0.0)
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


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	# --- Chốt bảo hiểm phục hồi tọa độ an toàn chống rơi mép map ---
	if is_on_floor() and global_position.y >= -0.05:
		_last_safe_floor_pos = global_position
	if global_position.y < -1.0:
		global_position = _last_safe_floor_pos + Vector3(0.0, 0.15, 0.0)
		velocity = Vector3.ZERO

	# --- Timers ---
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

	# --- Gravity ---
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	# --- Dash override ---
	if _dash_timer > 0.0:
		_dash_timer -= delta
		velocity.x = _dash_dir.x * DASH_SPEED
		velocity.z = _dash_dir.z * DASH_SPEED
		_apply_stair_step_up(_dash_dir, delta)
		move_and_slide()
		return

	# --- Input (chỉ khi không bị action lock) ---
	var input_dir := Vector3.ZERO
	var can_act: bool = _action_lock_timer <= 0.0 and _jump_state == 0

	if can_act:
		if external_move_dir.length_squared() > 0.01:
			input_dir = external_move_dir.normalized()
		else:
			var cam := get_viewport().get_camera_3d()
			if cam:
				var cam_basis := cam.global_transform.basis
				var screen_right := Vector3(cam_basis.x.x, 0.0, cam_basis.x.z).normalized()
				var screen_up := Vector3(cam_basis.z.x, 0.0, cam_basis.z.z).normalized()

				if Input.is_action_pressed("move_right"):
					input_dir += screen_right
				if Input.is_action_pressed("move_left"):
					input_dir -= screen_right
				if Input.is_action_pressed("move_forward"):
					input_dir -= screen_up
				if Input.is_action_pressed("move_backward"):
					input_dir += screen_up

				if input_dir.length_squared() > 0.01:
					input_dir = input_dir.normalized()

	# --- Xử lý hành động chiến đấu ---
	if can_act:
		# LMB: Combo Chém 3 Nhịp
		if Input.is_action_just_pressed("skill_lmb"):
			_do_melee_combo()
			return

		# RMB: Block + Counter Stab
		if Input.is_action_just_pressed("skill_rmb"):
			_do_block_counter()
			return

		# Q: Tuyệt chiêu Xoay Kiếm 360
		if Input.is_action_just_pressed("skill_q"):
			_do_spin_attack()
			return

		# E: Phóng đạn 3D
		if Input.is_action_just_pressed("skill_e"):
			_do_ranged_throw()
			return

		# Space: Lướt né
		if Input.is_action_just_pressed("dash"):
			_do_dodge()
			return

		# C / Jump: Nhảy
		if Input.is_action_just_pressed("interact") and is_on_floor():
			_do_jump()

	# --- Di chuyển & Chạy Running_A ---
	if _action_lock_timer <= 0.0 and _jump_state == 0:
		if input_dir.length_squared() > 0.01:
			velocity.x = input_dir.x * RUN_SPEED
			velocity.z = input_dir.z * RUN_SPEED
			if visual_root:
				visual_root.rotation.y = lerp_angle(
					visual_root.rotation.y,
					atan2(input_dir.x, input_dir.z),
					ROTATION_SPEED * delta
				)
			_play_anim(ANIM_RUN)
		elif Vector2(velocity.x, velocity.z).length() > 0.1:
			_play_anim(ANIM_RUN)
		else:
			velocity.x = move_toward(velocity.x, 0.0, RUN_SPEED * 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, RUN_SPEED * 8.0 * delta)
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


# ==============================================================================
# HÀM BƯỚC LÊN BẬC THANG TỰ ĐỘNG (_apply_stair_step_up)
# ==============================================================================
func _apply_stair_step_up(move_dir: Vector3, delta: float) -> void:
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
		# Tia 2: Bắn từ phía trước ở độ cao 0.85m thẳng xuống để tìm mặt trên của bậc thang
		var step_from := global_position + horiz_dir * 0.60 + Vector3(0.0, 0.85, 0.0)
		var step_to := global_position + horiz_dir * 0.60 + Vector3(0.0, 0.02, 0.0)
		var down_query := PhysicsRayQueryParameters3D.create(step_from, step_to, 1)
		down_query.exclude = [get_rid()]
		var down_hit := space_state.intersect_ray(down_query)

		if not down_hit.is_empty():
			var target_y: float = down_hit["position"].y
			var step_h: float = target_y - global_position.y
			var normal: Vector3 = down_hit["normal"]
			if step_h > 0.02 and step_h <= 0.65 and normal.y >= 0.55:
				global_position.y = move_toward(global_position.y, target_y + 0.02, 12.0 * delta)
				velocity.y = maxf(velocity.y, 0.0)


# ==============================================================================
# ACTIONS
# ==============================================================================

func _do_melee_combo() -> void:
	_face_cursor()

	var anim_name: String = COMBO_SEQUENCE[_combo_index]
	_play_anim(anim_name)

	var anim_length: float = _get_anim_length(anim_name)
	_action_lock_timer = anim_length - 0.05

	_start_sword_trail()

	# Gây sát thương cận chiến ngay lập tức (LMB 25.0 HP)
	_apply_melee_hit_detection(MELEE_DAMAGE, MELEE_RANGE, false)

	_combo_index = (_combo_index + 1) % COMBO_SEQUENCE.size()
	_combo_timer = COMBO_WINDOW + anim_length

	velocity.x = 0.0
	velocity.z = 0.0


func _do_block_counter() -> void:
	_face_cursor()

	_play_anim(ANIM_BLOCK)
	_action_lock_timer = 0.35

	var timer := get_tree().create_timer(0.35)
	timer.timeout.connect(func():
		if _is_dead:
			return
		_play_anim(ANIM_ATTACK_STAB)
		_action_lock_timer = _get_anim_length(ANIM_ATTACK_STAB) - 0.05
		_start_sword_trail()

		KayKitVFXManager.spawn_ground_decal_shockwave(
			get_tree().current_scene,
			global_position,
			2.5,
			Color(0.3, 0.7, 1.0, 0.8)
		)

		_apply_melee_hit_detection(20.0, 2.5, false)
		_knockback_nearby_enemies(2.5, 5.0)
	)

	velocity.x = 0.0
	velocity.z = 0.0


func _do_spin_attack() -> void:
	_face_cursor()
	_play_anim(ANIM_SPIN)
	_action_lock_timer = 0.65

	_start_sword_trail()
	_sword_trail_timer = 0.6

	KayKitVFXManager.spawn_ground_decal_shockwave(
		get_tree().current_scene,
		global_position,
		SPIN_RANGE,
		Color(1.0, 0.4, 0.1, 0.9)
	)

	# Sát thương diện rộng 360 độ
	_apply_melee_hit_detection(SPIN_DAMAGE, SPIN_RANGE, true)

	velocity.x = 0.0
	velocity.z = 0.0


func _do_ranged_throw() -> void:
	_face_cursor()
	_play_anim(ANIM_THROW)
	_action_lock_timer = _get_anim_length(ANIM_THROW) - 0.05

	var target_pos := _get_cursor_world_pos()
	var start_pos := global_position + Vector3(0.0, 1.2, 0.0)

	KayKitVFXManager.spawn_kaykit_3d_projectile(
		get_tree().current_scene, start_pos, target_pos, "smokebomb"
	)

	velocity.x = 0.0
	velocity.z = 0.0


func _do_dodge() -> void:
	var cam := get_viewport().get_camera_3d()
	var dodge_dir := Vector3.ZERO
	if cam:
		var cam_basis := cam.global_transform.basis
		var screen_right := Vector3(cam_basis.x.x, 0.0, cam_basis.x.z).normalized()
		var screen_up := Vector3(cam_basis.z.x, 0.0, cam_basis.z.z).normalized()

		if Input.is_action_pressed("move_right"):
			dodge_dir += screen_right
		if Input.is_action_pressed("move_left"):
			dodge_dir -= screen_right
		if Input.is_action_pressed("move_forward"):
			dodge_dir -= screen_up
		if Input.is_action_pressed("move_backward"):
			dodge_dir += screen_up

	if dodge_dir.length_squared() < 0.01:
		if visual_root:
			dodge_dir = Vector3(sin(visual_root.rotation.y), 0.0, cos(visual_root.rotation.y)).normalized()
		else:
			dodge_dir = Vector3.FORWARD

	dodge_dir = dodge_dir.normalized()
	_dash_dir = dodge_dir
	_dash_timer = DASH_DURATION
	_action_lock_timer = DASH_DURATION

	if visual_root:
		visual_root.rotation.y = atan2(dodge_dir.x, dodge_dir.z)

	_play_anim(ANIM_DODGE_FWD)


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
			KayKitVFXManager.spawn_hit_impact_at_chest(t_node)
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


## Nhận sát thương
func take_damage(amount: float, _from_dir: Vector3 = Vector3.ZERO) -> void:
	if _is_dead:
		return
	hp -= amount
	if hp <= 0.0:
		hp = 0.0
		_die()
	else:
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
