class_name HeroKnight3D
extends CharacterBody3D

# ==============================================================================
# HERO KNIGHT 3D — DIRECTIVE 15B, FILE LÕI SỐ 3
# Điều khiển duy nhất 1 Knight.glb: chuyển động mượt mà 12 kiểu dáng,
# leo cầu thang 3 tầng, ngắm chuột Raycast 3D đa tầng.
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
const MELEE_RANGE: float = 2.4
const MELEE_FAN_ANGLE: float = 120.0  # Độ
const MELEE_DAMAGE: float = 25.0
const SPIN_RANGE: float = 3.5
const SPIN_DAMAGE: float = 35.0
const SWORD_TRAIL_DURATION: float = 0.28
const COMBO_WINDOW: float = 0.45  # Thời gian cho phép nhấn tiếp combo

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

# --- Stats ---
var hp: float = 100.0
var max_hp: float = 100.0


func _ready() -> void:
	# --- Group & Collision ---
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4

	# --- Physics cho leo cầu thang ---
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(52.0)
	floor_stop_on_slope = true
	floor_constant_speed = true

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

	# --- Setup Animation Binder ---
	var bind_result: Dictionary = KayKitAnimationBinder.setup_and_bind_internal_animations(knight_model)
	if bind_result.is_empty():
		push_error("[HeroKnight3D] Animation binding failed!")
		return

	skeleton = bind_result["skeleton"]
	anim_player = bind_result["anim_player"]

	# --- Dọn vũ khí mặc định, gắn Sword + Shield ---
	KayKitAnimationBinder.clear_all_hand_slots(skeleton)

	# Đợi 1 frame để queue_free hoàn tất trước khi gắn vũ khí mới
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
		move_and_slide()
		return

	# --- Input (chỉ khi không bị action lock) ---
	var input_dir := Vector3.ZERO
	var can_act: bool = _action_lock_timer <= 0.0 and _jump_state == 0

	if can_act:
		# WASD chiếu theo camera isometric
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

	# --- Di chuyển ---
	if _action_lock_timer <= 0.0 and _jump_state == 0:
		if input_dir.length_squared() > 0.01:
			velocity.x = input_dir.x * RUN_SPEED
			velocity.z = input_dir.z * RUN_SPEED
			# Xoay mặt đúng trục +Z của KayKit
			if visual_root:
				visual_root.rotation.y = lerp_angle(
					visual_root.rotation.y,
					atan2(input_dir.x, input_dir.z),
					ROTATION_SPEED * delta
				)
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

	move_and_slide()


# ==========================================================================
# ACTIONS
# ==========================================================================

func _do_melee_combo() -> void:
	# Xoay mặt về phía chuột
	_face_cursor()

	var anim_name: String = COMBO_SEQUENCE[_combo_index]
	_play_anim(anim_name)

	# Tính thời gian lock từ animation
	var anim_length: float = _get_anim_length(anim_name)
	_action_lock_timer = anim_length - 0.05  # Cho phép hủy gần cuối

	# Bật vệt kiếm
	_start_sword_trail()

	# Gây sát thương diện rộng hình quạt
	_deal_fan_damage(MELEE_RANGE, MELEE_FAN_ANGLE, MELEE_DAMAGE)

	# Chuẩn bị combo tiếp
	_combo_index = (_combo_index + 1) % COMBO_SEQUENCE.size()
	_combo_timer = COMBO_WINDOW + anim_length

	velocity.x = 0.0
	velocity.z = 0.0


func _do_block_counter() -> void:
	_face_cursor()

	# Block
	_play_anim(ANIM_BLOCK)
	_action_lock_timer = 0.35

	# Sau Block -> Counter Stab
	var timer := get_tree().create_timer(0.35)
	timer.timeout.connect(func():
		if _is_dead:
			return
		_play_anim(ANIM_ATTACK_STAB)
		_action_lock_timer = _get_anim_length(ANIM_ATTACK_STAB) - 0.05
		_start_sword_trail()

		# Ground Decal shockwave
		KayKitVFXManager.spawn_ground_decal_shockwave(
			get_tree().current_scene,
			global_position,
			2.5,
			Color(0.3, 0.7, 1.0, 0.8)
		)

		# Đẩy lùi lính xung quanh
		_knockback_nearby_enemies(2.5, 5.0)
	)

	velocity.x = 0.0
	velocity.z = 0.0


func _do_spin_attack() -> void:
	_face_cursor()
	_play_anim(ANIM_SPIN)
	_action_lock_timer = 0.65

	# Bật vệt kiếm rực sáng
	_start_sword_trail()
	_sword_trail_timer = 0.6  # Kéo dài hơn bình thường

	# Ground Decal
	KayKitVFXManager.spawn_ground_decal_shockwave(
		get_tree().current_scene,
		global_position,
		SPIN_RANGE,
		Color(1.0, 0.4, 0.1, 0.9)
	)

	# Sát thương diện rộng 360°
	_deal_fan_damage(SPIN_RANGE, 360.0, SPIN_DAMAGE)

	velocity.x = 0.0
	velocity.z = 0.0


func _do_ranged_throw() -> void:
	_face_cursor()
	_play_anim(ANIM_THROW)
	_action_lock_timer = _get_anim_length(ANIM_THROW) - 0.05

	# Lấy vị trí chuột đa tầng
	var target_pos := _get_cursor_world_pos()
	var start_pos := global_position + Vector3(0.0, 1.2, 0.0)

	# Phóng smokebomb
	KayKitVFXManager.spawn_kaykit_3d_projectile(
		get_tree().current_scene, start_pos, target_pos, "smokebomb"
	)

	velocity.x = 0.0
	velocity.z = 0.0


func _do_dodge() -> void:
	# Hướng né: theo input hoặc hướng đang nhìn
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
		# Mặc định né về phía đang nhìn
		if visual_root:
			dodge_dir = -visual_root.global_transform.basis.z
		else:
			dodge_dir = Vector3.FORWARD

	dodge_dir = dodge_dir.normalized()
	_dash_dir = dodge_dir
	_dash_timer = DASH_DURATION
	_action_lock_timer = DASH_DURATION

	# Xoay visual về hướng né
	if visual_root:
		visual_root.rotation.y = atan2(dodge_dir.x, dodge_dir.z)

	_play_anim(ANIM_DODGE_FWD)


func _do_jump() -> void:
	velocity.y = JUMP_VELOCITY
	_jump_state = 1
	_action_lock_timer = 0.1  # Tạm khóa input ngắn khi nhảy
	_play_anim(ANIM_JUMP_START)


# ==========================================================================
# DAMAGE
# ==========================================================================

## Gây sát thương hình quạt phía trước
func _deal_fan_damage(radius: float, angle_deg: float, damage: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var my_pos := global_position
	var forward := -visual_root.global_transform.basis.z if visual_root else Vector3.FORWARD
	forward.y = 0.0
	forward = forward.normalized()
	var half_angle := deg_to_rad(angle_deg * 0.5)

	for enemy_node in enemies:
		if enemy_node is Node3D and is_instance_valid(enemy_node):
			var to_enemy: Vector3 = enemy_node.global_position - my_pos
			to_enemy.y = 0.0
			var dist := to_enemy.length()
			if dist > radius or dist < 0.01:
				continue
			var dir_to_enemy := to_enemy.normalized()
			var angle_to_enemy := acos(clamp(forward.dot(dir_to_enemy), -1.0, 1.0))
			if angle_to_enemy <= half_angle:
				# Gây sát thương
				if enemy_node.has_method("take_damage"):
					enemy_node.take_damage(damage, forward)
				# VFX trúng đòn tại ngực
				KayKitVFXManager.spawn_hit_impact_at_chest(enemy_node)


## Đẩy lùi lính xung quanh
func _knockback_nearby_enemies(radius: float, force: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
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


# ==========================================================================
# HELPERS
# ==========================================================================

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
	return 0.5  # Fallback


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

	# Kiểm tra nếu camera có hàm chuyên dụng
	if cam.has_method("get_accurate_ground_cursor_pos"):
		return cam.get_accurate_ground_cursor_pos(get_viewport())

	# Fallback: tự raycast
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := cam.project_ray_origin(mouse_pos)
	var ray_dir := cam.project_ray_normal(mouse_pos)
	var ray_end := ray_origin + ray_dir * 500.0

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1)  # Layer 1: Ground
	var hit := space_state.intersect_ray(query)
	if not hit.is_empty():
		return hit["position"]

	# Fallback Plane
	var plane := Plane(Vector3.UP, global_position.y)
	var pos = plane.intersects_ray(ray_origin, ray_dir)
	return pos if pos != null else global_position
