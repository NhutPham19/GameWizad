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
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")

@export var max_hp: float = 80.0
@export var move_speed: float = 4.2
@export var attack_range: float = 1.9
@export var aggro_range: float = 24.0
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 1.35

var hp: float = 80.0
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
var hp_label_3d: Label3D = null

# Định nghĩa các tuyến cầu thang nối 3 tầng
const STAIR_LINKS = [
	{"bottom": Vector3(-6.0, 0.0, -12.0), "top": Vector3(-6.0, 4.0, -16.0), "y_bot": 0.0, "y_top": 4.0},
	{"bottom": Vector3(6.0, 0.0, -12.0), "top": Vector3(6.0, 4.0, -16.0), "y_bot": 0.0, "y_top": 4.0},
	{"bottom": Vector3(0.0, 4.0, -24.0), "top": Vector3(0.0, 8.0, -28.0), "y_bot": 4.0, "y_top": 8.0}
]

func _ready() -> void:
	hp = max_hp
	_last_safe_floor_pos = global_position
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

	var col := CollisionShape3D.new()
	col.name = "EnemyCollision"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.75
	col.shape = cap
	col.position = Vector3(0.0, 0.875, 0.0)
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

	# 4. Tạo sẵn 1 Label3D nổi phía trên đầu mỗi Bot quái
	_setup_overhead_ui()

	_play_anim_safe("Idle")
	_action_lock_timer = 0.35

func _setup_overhead_ui() -> void:
	hp_label_3d = Label3D.new()
	hp_label_3d.name = "OverheadHPLabel"
	hp_label_3d.position = Vector3(0.0, 2.25, 0.0)
	hp_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label_3d.no_depth_test = true
	hp_label_3d.font_size = 42
	hp_label_3d.outline_size = 10
	hp_label_3d.outline_modulate = Color(0.0, 0.0, 0.0)
	add_child(hp_label_3d)
	_update_overhead_hp()

func _update_overhead_hp() -> void:
	if hp_label_3d == null or not is_instance_valid(hp_label_3d):
		return
	if is_dead:
		hp_label_3d.visible = false
		return
	var pct := clampf(hp / max_hp, 0.0, 1.0)
	var total_blocks := 8
	var filled := int(round(pct * total_blocks))
	var bar_str := ""
	for i in range(total_blocks):
		if i < filled:
			bar_str += "█"
		else:
			bar_str += "░"
	hp_label_3d.text = "[%s] %.0f/%.0f HP" % [bar_str, hp, max_hp]
	if pct > 0.5:
		hp_label_3d.modulate = Color(0.2, 0.95, 0.35)
	elif pct > 0.25:
		hp_label_3d.modulate = Color(1.0, 0.75, 0.2)
	else:
		hp_label_3d.modulate = Color(1.0, 0.25, 0.25)

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

	# Xử lý lực đẩy lùi khi trúng đòn
	_knockback_vel = _knockback_vel.move_toward(Vector3.ZERO, 18.0 * delta)

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

	# Nếu trong tầm đánh & cùng tầng độ cao (chênh lệch Y < 1.35m)
	if flat_dist <= attack_range and absf(y_diff) < 1.35:
		velocity.x = _knockback_vel.x
		velocity.z = _knockback_vel.z
		if flat_dist > 0.05:
			var aim_dir := flat_to_player.normalized()
			if visual_root:
				visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(aim_dir.x, aim_dir.z), 18.0 * delta)
		if _attack_cd_timer <= 0.0:
			_start_melee_attack()
		else:
			_play_anim_safe("Idle")
	elif dist_3d <= aggro_range:
		# Multi-Tier Stair Waypoint AI: Khi khác tầng, tự động tìm và chạy qua cầu thang
		var move_dir := _get_movement_direction(player)
		velocity.x = move_dir.x * move_speed + _knockback_vel.x
		velocity.z = move_dir.z * move_speed + _knockback_vel.z
		if move_dir.length_squared() > 0.01 and visual_root:
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(move_dir.x, move_dir.z), 14.0 * delta)
		_play_anim_safe("Running_A")
	else:
		velocity.x = _knockback_vel.x
		velocity.z = _knockback_vel.z
		_play_anim_safe("Idle")

	_apply_stair_step_up(Vector3(velocity.x, 0.0, velocity.z), delta)
	move_and_slide()


# ==============================================================================
# MULTI-TIER STAIR WAYPOINT AI
# ==============================================================================
func _get_movement_direction(player: Node3D) -> Vector3:
	var my_y := global_position.y
	var p_y := player.global_position.y

	# Nếu chênh lệch Y > 0.75m: Sử dụng Waypoint cầu thang để leo/xuống tầng
	if absf(p_y - my_y) > 0.75:
		var stair_waypoint := _get_nearest_stair_waypoint(my_y, p_y)
		var diff := stair_waypoint - global_position
		diff.y = 0.0
		if diff.length_squared() > 0.04:
			return diff.normalized()

	# Cùng tầng hoặc đã tới điểm chuyển tiếp: Sử dụng NavAgent hoặc hướng thẳng tới player
	nav_agent.target_position = player.global_position
	var next_pos := nav_agent.get_next_path_position()
	var move_vec := next_pos - global_position
	move_vec.y = 0.0
	if move_vec.length_squared() < 0.01:
		move_vec = player.global_position - global_position
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
# HÀM BƯỚC LÊN BẬC THANG TỰ ĐỘNG (_apply_stair_step_up)
# ==============================================================================
func _apply_stair_step_up(move_dir: Vector3, delta: float) -> void:
	if move_dir.length_squared() < 0.01:
		return
	var space_state := get_world_3d().direct_space_state
	var horiz_dir := Vector3(move_dir.x, 0.0, move_dir.z).normalized()

	var foot_from := global_position + Vector3(0.0, 0.15, 0.0)
	var foot_to := foot_from + horiz_dir * 0.70
	var foot_query := PhysicsRayQueryParameters3D.create(foot_from, foot_to, 1)
	foot_query.exclude = [get_rid()]
	var foot_hit := space_state.intersect_ray(foot_query)

	if not foot_hit.is_empty():
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

func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	hp = maxf(0.0, hp - amount)
	_update_overhead_hp()
	_spawn_floating_damage_text(amount)
	_is_attacking = false
	_set_axe_trails(false)
	KayKitVFXManager.spawn_hit_impact_at_chest(self)

	if knockback_dir.length_squared() > 0.001:
		var flat_kb := Vector3(knockback_dir.x, 0.0, knockback_dir.z).normalized()
		_knockback_vel = flat_kb * 5.0

	if hp <= 0.0:
		is_dead = true
		collision_layer = 0
		collision_mask = 1
		if hp_label_3d and is_instance_valid(hp_label_3d):
			hp_label_3d.visible = false
		_play_anim_safe("Death_A")
		var tw := create_tween()
		tw.tween_interval(1.8)
		tw.tween_callback(queue_free)
	else:
		_action_lock_timer = 0.32
		_play_anim_safe("Hit_A")

func _spawn_floating_damage_text(damage_amount: float) -> void:
	var dmg_label := Label3D.new()
	dmg_label.name = "FloatingDamageText"
	dmg_label.text = "-%.0f" % damage_amount
	dmg_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dmg_label.no_depth_test = true
	dmg_label.font_size = 48
	dmg_label.outline_size = 12
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
