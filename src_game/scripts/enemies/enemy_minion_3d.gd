class_name EnemyMinion3D
extends CharacterBody3D

# ==============================================================================
# ENEMY MINION 3D — DIRECTIVE 16 (PHASE 4 & 6)
# Sử dụng mô hình Barbarian.glb + Rìu chiến axe_1handed.gltf
# 0% PRIMITIVE GEOMETRY — NavigationAgent3D + Multi-Tier Stair Waypoint AI
# Tự động leo bậc thang (_apply_stair_step_up), nhận sát thương LMB 100%,
# hiển thị thanh máu Label3D trên đầu và chữ nhảy sát thương "-25" mượt mà.
# ==============================================================================

const KayKitAssetRegistry = preload("res://scripts/core/kaykit_asset_registry.gd")
const KayKitAnimationBinder = preload("res://scripts/characters/kaykit_animation_binder.gd")

@export var max_hp: float = 80.0
@export var move_speed: float = 4.2
@export var attack_range: float = 1.9
@export var aggro_range: float = 24.0
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 1.35

var hp: float = 80.0
var current_hp: float:
	get:
		return hp
	set(v):
		hp = v
var is_dead: bool = false
var _action_lock_timer: float = 0.0
var _attack_cd_timer: float = 0.0
var _damage_dealt_in_swing: bool = false
var _is_attacking: bool = false
var _knockback_vel: Vector3 = Vector3.ZERO
var _current_anim: String = ""
var _last_safe_floor_pos: Vector3 = Vector3.ZERO

var visual_root: Node3D = null
var model_inst: Node3D = null
var skeleton: Skeleton3D = null
var anim_player: AnimationPlayer = null
var nav_agent: NavigationAgent3D = null
var weapon_inst: Node3D = null
var blade_center_marker: Marker3D = null
var blade_tip_marker: Marker3D = null
var axe_trails: Array[GPUParticles3D] = []
var _displayed_lag_hp: float = 80.0
var _hp_bar_img: Image = null
var _hp_bar_tex: ImageTexture = null
var _hp_bar_sprite: Sprite3D = null
var _hp_label_3d: Label3D = null
var hp_label_3d: Label3D:
	get:
		return _hp_label_3d
	set(v):
		_hp_label_3d = v
var _stuck_timer: float = 0.0
var _hit_stun_timer: float = 0.0
var _smoke_slow_timer: float = 0.0
var _smoke_slow_factor: float = 0.0
var _slow_multiplier: float = 1.0
var _slow_timer: float = 0.0
var _avoid_commit_timer: float = 0.0
var _avoid_commit_sign: float = 1.0
var _stuck_check_timer: float = 0.0
var _last_stuck_check_pos: Vector3 = Vector3.ZERO
var _unstuck_recovery_timer: float = 0.0
var _unstuck_move_dir: Vector3 = Vector3.ZERO

# Định nghĩa các tuyến cầu thang nối 3 tầng
const STAIR_LINKS = [
	{"bottom": Vector3(-6.0, 0.0, -12.0), "top": Vector3(-6.0, 4.0, -16.0), "y_bot": 0.0, "y_top": 4.0},
	{"bottom": Vector3(6.0, 0.0, -12.0), "top": Vector3(6.0, 4.0, -16.0), "y_bot": 0.0, "y_top": 4.0},
	{"bottom": Vector3(0.0, 4.0, -24.0), "top": Vector3(0.0, 8.0, -28.0), "y_bot": 4.0, "y_top": 8.0}
]

func _ready() -> void:
	hp = max_hp
	_last_safe_floor_pos = global_position
	_last_stuck_check_pos = global_position
	add_to_group("enemies")
	add_to_group("enemy")

	# 1. Cấu hình Vật lý & Leo cầu thang 3 tầng khớp chuẩn với HeroKnight3D
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	floor_snap_length = 0.60
	floor_max_angle = deg_to_rad(58.0)
	floor_stop_on_slope = true
	floor_constant_speed = true
	floor_block_on_wall = true
	safe_margin = 0.002
	wall_min_slide_angle = 0.0

	var col := CollisionShape3D.new()
	col.name = "EnemyCollision"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.46
	cap.height = 1.80
	col.shape = cap
	col.position = Vector3(0.0, 0.90, 0.0)
	add_child(col)

	# 2. Cấu hình NavigationAgent3D tìm đường qua cầu thang đa tầng
	nav_agent = NavigationAgent3D.new()
	nav_agent.name = "NavigationAgent3D"
	nav_agent.path_desired_distance = 0.6
	nav_agent.target_desired_distance = 1.5
	nav_agent.path_max_distance = 5.0
	add_child(nav_agent)

	# 3. Khởi tạo Mô hình Barbarian.glb + Ánh xạ 75 Animations bằng KayKitAnimationBinder của Opus
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)

	var model_path := KayKitAssetRegistry.ENEMY_MINION
	if not ResourceLoader.exists(model_path):
		model_path = "res://assets/characters/Barbarian.glb"
	if not ResourceLoader.exists(model_path):
		model_path = KayKitAssetRegistry.HERO_KNIGHT

	var packed := load(model_path) as PackedScene
	if packed != null:
		model_inst = packed.instantiate() as Node3D
		model_inst.name = "BarbarianModel"
		visual_root.add_child(model_inst)

		var bind_result = KayKitAnimationBinder.setup_and_bind_internal_animations(model_inst)
		if bind_result is Dictionary:
			skeleton = bind_result.get("skeleton", null)
			anim_player = bind_result.get("anim_player", null)
		if skeleton == null:
			skeleton = _find_skel_fallback(model_inst)

		if skeleton != null:
			KayKitAnimationBinder.clear_all_hand_slots(skeleton)
			await get_tree().process_frame
			if not is_instance_valid(skeleton):
				return

			var axe_path := KayKitAssetRegistry.WEAPON_AXE
			if not ResourceLoader.exists(axe_path):
				axe_path = "res://assets/weapons/axe_1handed.gltf"
			if not ResourceLoader.exists(axe_path):
				axe_path = KayKitAssetRegistry.WEAPON_SWORD

			weapon_inst = KayKitAnimationBinder.attach_weapon_to_bone(skeleton, "handslot.r", axe_path, true)
			if weapon_inst != null:
				blade_center_marker = weapon_inst.get_node_or_null("BladeCenterMarker") as Marker3D
				blade_tip_marker = weapon_inst.get_node_or_null("BladeTipMarker") as Marker3D
				if blade_center_marker != null and blade_tip_marker != null:
					axe_trails = KayKitVFXManager.attach_sword_trail_particles(blade_center_marker, blade_tip_marker)

	# 4. Tạo sẵn 1 Thanh Máu 3D Đỏ Huyết + Vạch Tụt Trễ trên đầu Bot
	_setup_overhead_health_bar()

	_play_anim_safe("Idle")
	_action_lock_timer = 0.35

func _setup_overhead_ui() -> void:
	_setup_overhead_health_bar()

func _setup_overhead_health_bar() -> void:
	# Dọn sạch mọi node thanh máu cũ để đảm bảo chỉ có DUY NHẤT 1 thanh máu
	for child in get_children():
		if child.name.begins_with("OverheadHP") or child.name.find("HealthBar") != -1 or child.name.begins_with("HPBar"):
			child.queue_free()

	var holder := Node3D.new()
	holder.name = "OverheadHPHolder"
	holder.position = Vector3(0.0, 2.28, 0.0)
	add_child(holder)

	_hp_bar_img = Image.create(128, 16, false, Image.FORMAT_RGBA8)
	_hp_bar_tex = ImageTexture.create_from_image(_hp_bar_img)

	_hp_bar_sprite = Sprite3D.new()
	_hp_bar_sprite.name = "HPBarSprite3D"
	_hp_bar_sprite.texture = _hp_bar_tex
	_hp_bar_sprite.pixel_size = 0.011
	_hp_bar_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_bar_sprite.no_depth_test = true
	_hp_bar_sprite.render_priority = 10
	holder.add_child(_hp_bar_sprite)

	_hp_label_3d = Label3D.new()
	_hp_label_3d.name = "HPLabel3D"
	_hp_label_3d.position = Vector3(0.0, 0.22, 0.0)
	_hp_label_3d.pixel_size = 0.0045
	_hp_label_3d.font_size = 32
	_hp_label_3d.outline_size = 10
	_hp_label_3d.modulate = Color(1.0, 0.92, 0.92, 1.0)
	_hp_label_3d.outline_modulate = Color(0.08, 0.02, 0.02, 1.0)
	_hp_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_label_3d.no_depth_test = true
	holder.add_child(_hp_label_3d)

	_displayed_lag_hp = current_hp
	_redraw_hp_bar_image()

func _redraw_hp_bar_image() -> void:
	if _hp_bar_img == null or _hp_bar_tex == null:
		return
	var w := 128
	var h := 16
	# 1. Khung viền ngoài màu Đen Thẫm (#12131A)
	_hp_bar_img.fill(Color(0.07, 0.07, 0.10, 0.92))
	# 2. Lòng nền máu rỗng màu Đỏ Đen tối (#2A0B0E)
	_hp_bar_img.fill_rect(Rect2i(2, 2, w - 4, h - 4), Color(0.16, 0.04, 0.06, 0.95))

	var max_inner_w := w - 4
	var hp_ratio := clampf(current_hp / maxf(1.0, max_hp), 0.0, 1.0)
	var lag_ratio := clampf(_displayed_lag_hp / maxf(1.0, max_hp), hp_ratio, 1.0)

	var red_w := int(round(max_inner_w * hp_ratio))
	var lag_w := int(round(max_inner_w * lag_ratio))

	# 3. Vạch máu tụt trễ (Catch-up Bar) màu Trắng Vàng phát sáng (#FFF2D6)
	if lag_w > red_w:
		_hp_bar_img.fill_rect(Rect2i(2 + red_w, 2, lag_w - red_w, h - 4), Color(1.0, 0.95, 0.82, 1.0))

	# 4. Vạch máu chính màu ĐỎ HUYẾT RỰC RỠ (#E61E2A) có dải sáng bóng phía trên (#FF4D58)
	if red_w > 0:
		_hp_bar_img.fill_rect(Rect2i(2, 2, red_w, h - 4), Color(0.90, 0.12, 0.16, 1.0))
		_hp_bar_img.fill_rect(Rect2i(2, 2, red_w, 4), Color(1.0, 0.32, 0.36, 1.0))

	_hp_bar_tex.update(_hp_bar_img)
	if _hp_label_3d != null:
		_hp_label_3d.text = "%d / %d" % [int(ceil(current_hp)), int(max_hp)]

func _update_overhead_hp() -> void:
	_redraw_hp_bar_image()

func _find_skel_fallback(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for c in node.get_children():
		var s := _find_skel_fallback(c)
		if s != null:
			return s
	return null

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Directive 18: Khóa cứng rotation của node CharacterBody3D = Vector3.ZERO
	rotation = Vector3.ZERO

	# Directive 20: Cập nhật vạch máu tụt trễ (Catch-up Bar) mượt mà
	if absf(_displayed_lag_hp - current_hp) > 0.05:
		_displayed_lag_hp = move_toward(_displayed_lag_hp, current_hp, max_hp * 1.45 * delta)
		_redraw_hp_bar_image()

	# Chốt bảo hiểm phục hồi an toàn chống rơi mép bản đồ
	if is_on_floor() and global_position.y >= -0.05:
		_last_safe_floor_pos = global_position
	if global_position.y < -1.0:
		global_position = _last_safe_floor_pos + Vector3(0.0, 0.15, 0.0)
		velocity = Vector3.ZERO

	if not is_on_floor():
		velocity.y -= 22.0 * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	if _attack_cd_timer > 0.0:
		_attack_cd_timer -= delta

	# Xử lý Hit-Stun Interrupt (Task 19.4 Kỹ thuật C: Ngắt đòn và khựng 0.35s)
	if _hit_stun_timer > 0.0:
		_hit_stun_timer -= delta
		velocity.x = _knockback_vel.x
		velocity.z = _knockback_vel.z
		_knockback_vel = _knockback_vel.move_toward(Vector3.ZERO, 18.0 * delta)
		_play_anim_safe("Hit_A")
		move_and_slide()
		return

	# Xử lý lực đẩy lùi khi trúng đòn
	_knockback_vel = _knockback_vel.move_toward(Vector3.ZERO, 18.0 * delta)

	# Làm chậm do Bom Khói Lôi Vụ E (Task 21.1)
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_multiplier = 1.0
			_set_status_tint(Color.WHITE)
	var current_move_speed := move_speed * _slow_multiplier
	if _smoke_slow_timer > 0.0:
		_smoke_slow_timer -= delta
		current_move_speed *= (1.0 - _smoke_slow_factor)

	if _action_lock_timer > 0.0:
		_action_lock_timer -= delta
		if _is_attacking and not _damage_dealt_in_swing and _action_lock_timer <= 0.25:
			_damage_dealt_in_swing = true
			_try_hit_player()
		if _action_lock_timer <= 0.0:
			_is_attacking = false
			_set_axe_trails(false)
		velocity.x = _knockback_vel.x
		velocity.z = _knockback_vel.z
		_apply_stair_step_up(Vector3(velocity.x, 0.0, velocity.z), delta)
		move_and_slide()
		floor_snap_length = 0.60
		return

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or not is_instance_valid(player):
		_play_anim_safe("Idle")
		return

	var to_player := player.global_position - global_position
	var dist_3d := to_player.length()
	var flat_to_player := Vector3(to_player.x, 0.0, to_player.z)
	var flat_dist := flat_to_player.length()
	var y_diff := to_player.y

	var desired_move_vel := Vector3.ZERO

	# Lớp 1 — Khoảng Cách Dừng Chiến Đấu (1.45m) & Tự Tách Đội Hình Vòng Cung (Task 19.3)
	if flat_dist <= 1.45 and absf(y_diff) < 1.2:
		if flat_dist < 1.10:
			# Quá sát người chơi -> lùi nhẹ ra sau để nhường khoảng thở
			var back_dir := -flat_to_player.normalized() if flat_dist > 0.01 else Vector3.BACK
			desired_move_vel = back_dir * 2.8
		else:
			desired_move_vel = Vector3.ZERO

		if _attack_cd_timer <= 0.0:
			_start_melee_attack()
		else:
			_play_anim_safe("Idle")
	elif dist_3d <= aggro_range:
		# Multi-Tier Stair Waypoint AI + Cảm Biến 7 Tia Đi Vòng Tránh Vật Cản (Task 19.5)
		var raw_dir := _get_movement_direction(player)
		var smart_dir := _compute_obstacle_avoidance_direction(raw_dir, flat_dist, delta)
		desired_move_vel = smart_dir * current_move_speed
		_play_anim_safe("Running_A")

		# Bộ Tự Động Gỡ Kẹt (Stuck Detector mỗi 0.35s, Task 19.5 Tầng 2)
		_stuck_check_timer += delta
		if _stuck_check_timer >= 0.35:
			_stuck_check_timer = 0.0
			var moved_dist := (global_position - _last_stuck_check_pos).length()
			if moved_dist < 0.12 and desired_move_vel.length_squared() > 0.5:
				_avoid_commit_sign = -_avoid_commit_sign
				_unstuck_recovery_timer = 0.55
				_unstuck_move_dir = raw_dir.rotated(Vector3.UP, deg_to_rad(105.0 * _avoid_commit_sign)).normalized()
			_last_stuck_check_pos = global_position
	else:
		desired_move_vel = Vector3.ZERO
		_play_anim_safe("Idle")

	# Lực đẩy tách bầy đàn giữa các Bot (Boids Separation Force, Task 19.3 Lớp 1)
	var separation_vec := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not is_instance_valid(other) or other.get("is_dead"):
			continue
		var diff: Vector3 = global_position - (other as Node3D).global_position
		diff.y = 0.0
		var d := diff.length()
		if d > 0.001 and d < 1.35:
			separation_vec += diff.normalized() * ((1.35 - d) / 1.35) * 4.5

	velocity.x = desired_move_vel.x + separation_vec.x + _knockback_vel.x
	velocity.z = desired_move_vel.z + separation_vec.z + _knockback_vel.z

	# Tầng 3 — Xoay Mặt Theo Hướng Bước Đi Thực Tế (Velocity-Aligned Facing, Task 19.5 Tầng 3)
	var horiz_vel := Vector3(velocity.x, 0.0, velocity.z)
	if horiz_vel.length_squared() > 0.15 and (flat_dist > 2.1 or _avoid_commit_timer > 0.0 or _unstuck_recovery_timer > 0.0 or absf(y_diff) > 1.15):
		var walk_yaw := atan2(horiz_vel.x, horiz_vel.z)
		if visual_root:
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, walk_yaw, 14.0 * delta)
	elif flat_dist <= 2.1 and absf(y_diff) <= 1.2:
		# Khi đã áp sát tầm cận chiến -> xoay trực diện vào người chơi để bổ rìu
		if flat_dist > 0.05 and visual_root:
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(flat_to_player.x, flat_to_player.z), 18.0 * delta)

	_apply_stair_step_up(Vector3(velocity.x, 0.0, velocity.z), delta)
	move_and_slide()
	floor_snap_length = 0.60
	_apply_wall_micro_separation(delta)


# ==============================================================================
# CẢM BIẾN 7 TIA ĐI VÒNG VẬT CẢN & GHI NHỚ HƯỚNG LÁCH (TASK 19.5 TẦNG 2)
# ==============================================================================
func _compute_obstacle_avoidance_direction(desired_dir: Vector3, dist_to_target: float, delta: float) -> Vector3:
	if desired_dir.length_squared() < 0.001:
		return Vector3.ZERO
	var space_state := get_world_3d().direct_space_state
	var ray_origin := global_position + Vector3(0.0, 0.55, 0.0) # Độ cao ngang hông
	var probe_dist := clampf(dist_to_target, 1.4, 2.6)

	# 1. Nếu đang trong trạng thái Tự Gỡ Kẹt (Unstuck Recovery)
	if _unstuck_recovery_timer > 0.0:
		_unstuck_recovery_timer -= delta
		return _unstuck_move_dir

	# 2. Kiểm tra tia chính diện (0 độ) và 2 tia vai (-22 độ, +22 độ)
	var front_blocked := false
	for check_deg in [0.0, -22.0, 22.0]:
		var check_dir := desired_dir.rotated(Vector3.UP, deg_to_rad(check_deg))
		var q := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + check_dir * probe_dist, 1)
		q.exclude = [get_rid()]
		var hit := space_state.intersect_ray(q)
		if not hit.is_empty():
			var hit_normal: Vector3 = hit["normal"]
			if hit_normal.y < 0.55:
				front_blocked = true
				break

	if not front_blocked and _avoid_commit_timer <= 0.0:
		return desired_dir

	# 3. Quét các góc râu cảm biến hai bên để tìm lối đi vòng thông thoáng nhất
	if _avoid_commit_timer > 0.0:
		_avoid_commit_timer -= delta

	var candidate_angles := [35.0, -35.0, 65.0, -65.0, 95.0, -95.0, 130.0, -130.0]
	if _avoid_commit_timer > 0.0:
		candidate_angles.sort_custom(func(a, b): return (signf(a) == _avoid_commit_sign) and (signf(b) != _avoid_commit_sign))

	var best_dir := desired_dir
	var best_score := -999.0

	for deg in candidate_angles:
		var test_dir := desired_dir.rotated(Vector3.UP, deg_to_rad(deg)).normalized()
		var q := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + test_dir * (probe_dist + 0.6), 1)
		q.exclude = [get_rid()]
		var hit := space_state.intersect_ray(q)
		var clearance := probe_dist + 0.6
		if not hit.is_empty() and hit["normal"].y < 0.55:
			clearance = ray_origin.distance_to(hit["position"])

		var align_score := test_dir.dot(desired_dir) * 1.2
		var commit_bonus := 0.65 if (signf(deg) == _avoid_commit_sign and _avoid_commit_timer > 0.0) else 0.0
		var total_score := clearance + align_score + commit_bonus
		if total_score > best_score and clearance > 1.15:
			best_score = total_score
			best_dir = test_dir
			if front_blocked and _avoid_commit_timer <= 0.0:
				_avoid_commit_sign = signf(deg)
				_avoid_commit_timer = 0.65 # Giữ hướng đi vòng tối thiểu 0.65s

	return best_dir


# ==============================================================================
# MULTI-TIER STAIR WAYPOINT AI
# ==============================================================================
func _get_movement_direction(player: Node3D) -> Vector3:
	var my_y := global_position.y
	var p_y := player.global_position.y

	# Nếu chênh lệch Y > 1.15m: Sử dụng Waypoint cầu thang để leo/xuống tầng (Task 19.5 Tầng 1)
	if absf(p_y - my_y) > 1.15:
		var stair_waypoint := _get_nearest_stair_waypoint(my_y, p_y)
		var diff := stair_waypoint - global_position
		diff.y = 0.0
		if diff.length_squared() > 0.04:
			return diff.normalized()

	# Cùng tầng hoặc đã tới điểm chuyển tiếp: Hướng thẳng tới player
	var move_vec := player.global_position - global_position
	move_vec.y = 0.0
	return move_vec.normalized() if move_vec.length_squared() > 0.01 else Vector3.ZERO


func _get_nearest_stair_waypoint(my_y: float, target_y: float) -> Vector3:
	# Trường hợp 1: Bot ở Tầng 1 (Y ~ 0) muốn lên Tầng 2 hoặc 3 (Y >= 3.5)
	if my_y < 2.0 and target_y >= 2.0:
		var stair_1 = STAIR_LINKS[0]
		var stair_2 = STAIR_LINKS[1]
		var d1 := Vector2(global_position.x - stair_1["bottom"].x, global_position.z - stair_1["bottom"].z).length()
		var d2 := Vector2(global_position.x - stair_2["bottom"].x, global_position.z - stair_2["bottom"].z).length()
		var best_stair = stair_1 if d1 <= d2 else stair_2

		# Nếu chưa tới chân cầu thang
		if global_position.z > best_stair["bottom"].z + 0.5:
			return best_stair["bottom"]
		# Đang trên cầu thang -> chạy thẳng lên đỉnh cầu thang
		return best_stair["top"]

	# Trường hợp 2: Bot ở Tầng 2 (Y ~ 4) muốn lên Tầng 3 (Y >= 6.0)
	elif my_y >= 2.0 and my_y < 6.0 and target_y >= 6.0:
		var stair_3 = STAIR_LINKS[2]
		if global_position.z > stair_3["bottom"].z + 0.5:
			return stair_3["bottom"]
		return stair_3["top"]

	# Trường hợp 3: Bot ở Tầng 3 (Y ~ 8) muốn xuống Tầng 2 hoặc 1 (Y < 6.0)
	elif my_y >= 6.0 and target_y < 6.0:
		var stair_3 = STAIR_LINKS[2]
		if global_position.z < stair_3["top"].z - 0.5:
			return stair_3["top"]
		return stair_3["bottom"]

	# Trường hợp 4: Bot ở Tầng 2 (Y ~ 4) muốn xuống Tầng 1 (Y < 2.0)
	elif my_y >= 2.0 and my_y < 6.0 and target_y < 2.0:
		var stair_1 = STAIR_LINKS[0]
		var stair_2 = STAIR_LINKS[1]
		var d1 := Vector2(global_position.x - stair_1["top"].x, global_position.z - stair_1["top"].z).length()
		var d2 := Vector2(global_position.x - stair_2["top"].x, global_position.z - stair_2["top"].z).length()
		var best_stair = stair_1 if d1 <= d2 else stair_2

		if global_position.z < best_stair["top"].z - 0.5:
			return best_stair["top"]
		return best_stair["bottom"]

	# Mặc định hướng về phía player
	var p := get_tree().get_first_node_in_group("player") as Node3D
	return p.global_position if p else global_position


# ==============================================================================
# HÀM KIỂM TRA HÀNH LANG BƯỚC ĐI CẦU THANG (Task 24.2 Lớp 2: Stair Corridor Gate)
# ==============================================================================
func _is_in_stair_walk_corridor(pos: Vector3, move_dir: Vector3) -> bool:
	var horiz := Vector2(move_dir.x, move_dir.z)
	if horiz.length_squared() < 0.001:
		return false
	# Chỉ kích hoạt khi hướng di chuyển có thành phần đi lên/xuống dọc theo trục Z của cầu thang
	if absf(horiz.normalized().y) < 0.25:
		return false

	# Tọa độ X của nhân vật phải nằm lọt trong lòng rãnh giữa cầu thang (center_x ± 1.40m):
	# 1. Cầu thang Tây (Tầng 1 <-> 2): center_x = -6.0, Z từ -17.5 đến -9.5
	if absf(pos.x - (-6.0)) <= 1.40 and pos.z >= -17.5 and pos.z <= -9.5:
		return true
	# 2. Cầu thang Đông (Tầng 1 <-> 2): center_x = +6.0, Z từ -17.5 đến -9.5
	if absf(pos.x - 6.0) <= 1.40 and pos.z >= -17.5 and pos.z <= -9.5:
		return true
	# 3. Cầu thang Giữa (Tầng 2 <-> 3): center_x = 0.0, Z từ -29.5 đến -21.5
	if absf(pos.x - 0.0) <= 1.40 and pos.z >= -29.5 and pos.z <= -21.5:
		return true

	return false


# ==============================================================================
# HÀM BƯỚC LÊN BẬC THANG TỰ ĐỘNG (_apply_stair_step_up)
# Giới hạn chỉ kích hoạt khi vật cản phía trước thuộc group "stairs" hoặc sàn đón
# ==============================================================================
func _apply_stair_step_up(move_dir: Vector3, delta: float) -> void:
	if not _is_in_stair_walk_corridor(global_position, move_dir):
		return
	if move_dir.length_squared() < 0.01:
		return
	var space_state := get_world_3d().direct_space_state
	var horiz_dir := Vector3(move_dir.x, 0.0, move_dir.z).normalized()

	var foot_from := global_position + Vector3(0.0, 0.15, 0.0)
	var foot_to := foot_from + horiz_dir * 0.75
	var foot_query := PhysicsRayQueryParameters3D.create(foot_from, foot_to, 1)
	foot_query.exclude = [get_rid()]
	var foot_hit := space_state.intersect_ray(foot_query)

	if not foot_hit.is_empty():
		var col_obj = foot_hit.get("collider", null)
		var is_valid_surface := false
		if col_obj != null and col_obj is Node:
			var node_col := col_obj as Node
			if node_col.is_in_group("stairs") or node_col.name.to_lower().contains("floor") or node_col.name.to_lower().contains("tile"):
				is_valid_surface = true
		if not is_valid_surface:
			return

		var step_from := global_position + horiz_dir * 0.60 + Vector3(0.0, 0.85, 0.0)
		var step_to := global_position + horiz_dir * 0.60 + Vector3(0.0, 0.02, 0.0)
		var down_query := PhysicsRayQueryParameters3D.create(step_from, step_to, 1)
		down_query.exclude = [get_rid()]
		var down_hit := space_state.intersect_ray(down_query)

		if not down_hit.is_empty():
			var down_obj = down_hit.get("collider", null)
			var is_down_valid := false
			if down_obj != null and down_obj is Node:
				var node_down := down_obj as Node
				if node_down.is_in_group("stairs") or node_down.name.to_lower().contains("floor") or node_down.name.to_lower().contains("tile"):
					is_down_valid = true
			if not is_down_valid:
				return
			var target_y: float = down_hit["position"].y
			var step_h: float = target_y - global_position.y
			var normal: Vector3 = down_hit["normal"]
			if step_h > 0.02 and step_h <= 0.65 and normal.y >= 0.55:
				global_position.y = move_toward(global_position.y, target_y + 0.02, 14.0 * delta)
				velocity.y = maxf(velocity.y, 4.5)
				floor_snap_length = 0.0


# ==============================================================================
# COMBAT & DAMAGE
# ==============================================================================

func _start_melee_attack() -> void:
	_is_attacking = true
	_damage_dealt_in_swing = false
	_action_lock_timer = 0.52
	_attack_cd_timer = attack_cooldown
	_set_axe_trails(true)
	var atk_anim := "1H_Melee_Attack_Chop" if randf() < 0.5 else "1H_Melee_Attack_Slice_Horizontal"
	_play_anim_safe(atk_anim)

func _try_hit_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or not is_instance_valid(player):
		return
	var diff := player.global_position - global_position
	if Vector2(diff.x, diff.z).length() <= attack_range + 0.45 and absf(diff.y) < 1.4:
		var dir := Vector3(diff.x, 0.0, diff.z).normalized()
		if player.has_method("take_damage"):
			player.take_damage(attack_damage, dir)
		KayKitVFXManager.spawn_hit_impact_at_chest(player)

func apply_knockback(force_vec: Vector3) -> void:
	if is_dead:
		return
	var flat_kb := Vector3(force_vec.x, 0.0, force_vec.z)
	_knockback_vel = flat_kb

func apply_dash_impact_knockback(impulse: Vector3, stun_duration: float) -> void:
	if is_dead:
		return
	_knockback_vel = impulse
	_hit_stun_timer = maxf(_hit_stun_timer, stun_duration)
	_action_lock_timer = maxf(_action_lock_timer, stun_duration)
	_is_attacking = false
	_attack_cd_timer = maxf(_attack_cd_timer, 0.5)
	_set_axe_trails(false)
	_play_anim_safe("Hit_A")

func apply_smoke_slow(slow_factor: float, duration: float) -> void:
	if is_dead:
		return
	_smoke_slow_factor = slow_factor
	_smoke_slow_timer = duration
	_is_attacking = false
	_action_lock_timer = 0.4
	_play_anim_safe("Hit_A")

## Sát thương đốt DoT (Task 21.1)
func take_dot_damage(amount: float, tint_color: Color = Color(0.75, 0.35, 1.0)) -> void:
	if is_dead:
		return
	hp = maxf(0.0, hp - amount)
	_update_overhead_hp()
	_spawn_floating_damage_text(amount, tint_color)
	KayKitVFXManager.spawn_cross_slash_hit_impact(global_position + Vector3(0.0, 0.95, 0.0))
	if hp <= 0.0:
		take_damage(0.0)

## Làm chậm Debuff (Task 21.1)
func apply_slow_debuff(multiplier: float, duration: float) -> void:
	if is_dead:
		return
	_slow_multiplier = multiplier
	_slow_timer = maxf(_slow_timer, duration)
	_set_status_tint(Color(0.55, 0.75, 1.35))

func _set_status_tint(tint: Color) -> void:
	if visual_root == null:
		return
	for m in visual_root.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi:
			if tint == Color.WHITE:
				mi.material_override = null
			else:
				var sm := StandardMaterial3D.new()
				sm.albedo_color = tint
				mi.material_override = sm

# Task 23.5: Tắt hoàn toàn _apply_wall_micro_separation() để loại bỏ rung giật
func _apply_wall_micro_separation(_delta: float) -> void:
	pass

func apply_hit_stun(duration: float) -> void:
	_hit_stun_timer = maxf(_hit_stun_timer, duration)
	_action_lock_timer = maxf(_action_lock_timer, duration)
	_is_attacking = false
	_set_axe_trails(false)
	_play_anim_safe("Hit_A")

func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	hp = maxf(0.0, hp - amount)
	_update_overhead_hp()
	_spawn_floating_damage_text(amount)
	_is_attacking = false
	_set_axe_trails(false)
	_hit_stun_timer = 0.35 # Hit-Stun Interrupt ngắt ngay đòn bổ rìu của Bot (Task 19.4 Kỹ thuật C)
	_action_lock_timer = 0.35
	_attack_cd_timer = maxf(_attack_cd_timer, 0.4)
	KayKitVFXManager.spawn_hit_impact_at_chest(self)

	if knockback_dir.length_squared() > 0.001:
		var flat_kb := Vector3(knockback_dir.x, 0.0, knockback_dir.z).normalized()
		_knockback_vel = flat_kb * 6.5

	if hp <= 0.0:
		is_dead = true
		collision_layer = 0
		collision_mask = 1
		var holder = get_node_or_null("OverheadHPHolder")
		if holder and is_instance_valid(holder):
			holder.visible = false
		if _hp_label_3d and is_instance_valid(_hp_label_3d):
			_hp_label_3d.visible = false
		if _hp_bar_sprite and is_instance_valid(_hp_bar_sprite):
			_hp_bar_sprite.visible = false
		_play_anim_safe("Death_A")
		var tw := create_tween()
		tw.tween_interval(1.8)
		tw.tween_callback(queue_free)
	else:
		_play_anim_safe("Hit_A")

func _spawn_floating_damage_text(damage_amount: float, custom_color: Color = Color.TRANSPARENT) -> void:
	var dmg_label := Label3D.new()
	dmg_label.name = "FloatingDamageText"
	dmg_label.text = "-%.0f" % damage_amount
	dmg_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dmg_label.no_depth_test = true
	dmg_label.font_size = 48
	dmg_label.outline_size = 12
	if custom_color != Color.TRANSPARENT:
		dmg_label.modulate = custom_color
	else:
		dmg_label.modulate = Color(1.0, 0.85, 0.2)
	dmg_label.outline_modulate = Color(0.1, 0.05, 0.0)

	var start_pos := global_position + Vector3(randf_range(-0.25, 0.25), 1.35, randf_range(-0.25, 0.25))
	var parent_scene = get_tree().current_scene if get_tree().current_scene else get_parent()
	if parent_scene == null:
		parent_scene = self
	parent_scene.add_child(dmg_label)
	dmg_label.global_position = start_pos

	var tw := dmg_label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(dmg_label, "global_position:y", start_pos.y + 1.45, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(dmg_label, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(dmg_label.queue_free)

func _set_axe_trails(active: bool) -> void:
	for p in axe_trails:
		if is_instance_valid(p):
			p.emitting = active

func _play_anim_safe(anim_name: String) -> void:
	if anim_player == null:
		return
	var actual_name := anim_name
	if not anim_player.has_animation(actual_name):
		if anim_name == "Running_A" and anim_player.has_animation("Walk"):
			actual_name = "Walk"
		elif anim_name == "Spawn_Ground" and anim_player.has_animation("Idle"):
			actual_name = "Idle"
		else:
			return
	if _current_anim != actual_name:
		_current_anim = actual_name
		anim_player.play(actual_name, 0.12)
