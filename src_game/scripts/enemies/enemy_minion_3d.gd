class_name EnemyMinion3D
extends CharacterBody3D

# ==============================================================================
# ENEMY MINION 3D — DIRECTIVE 16, PHASE 4
# Sử dụng mô hình Barbarian.glb + Rìu chiến axe_1handed.gltf
# Tái sử dụng KayKitAnimationBinder & KayKitVFXManager của Claude Opus 4.6
# 0% PRIMITIVE GEOMETRY — NavigationAgent3D tìm đường & leo thang đa tầng
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

var visual_root: Node3D = null
var model_inst: Node3D = null
var skeleton: Skeleton3D = null
var anim_player: AnimationPlayer = null
var nav_agent: NavigationAgent3D = null
var weapon_inst: Node3D = null
var blade_center_marker: Marker3D = null
var blade_tip_marker: Marker3D = null
var axe_trails: Array[GPUParticles3D] = []

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	add_to_group("enemy")

	# 1. Cấu hình Vật lý & Leo cầu thang 3 tầng khớp chuẩn với HeroKnight3D
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(52.0)
	floor_stop_on_slope = true
	floor_constant_speed = true

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

		# Gọi bộ Binder chuẩn của Opus 4.6
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

	_play_anim_safe("Idle")
	_action_lock_timer = 0.35

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
		# Gây sát thương ở giữa nhịp vung rìu
		if _is_attacking and not _damage_dealt_in_swing and _action_lock_timer <= 0.25:
			_damage_dealt_in_swing = true
			_try_hit_player()
		if _action_lock_timer <= 0.0:
			_is_attacking = false
			_set_axe_trails(false)
		velocity.x = _knockback_vel.x
		velocity.z = _knockback_vel.z
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

	# Nếu trong tầm đánh & cùng tầng độ cao (chênh lệch Y < 1.35m)
	if flat_dist <= attack_range and absf(to_player.y) < 1.35:
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
		# Tìm đường qua cầu thang đa tầng bằng NavigationAgent3D
		nav_agent.target_position = player.global_position
		var next_pos := nav_agent.get_next_path_position()
		var move_vec := next_pos - global_position
		move_vec.y = 0.0
		if move_vec.length_squared() < 0.01:
			move_vec = flat_to_player
		var move_dir := move_vec.normalized()
		velocity.x = move_dir.x * move_speed + _knockback_vel.x
		velocity.z = move_dir.z * move_speed + _knockback_vel.z
		if move_dir.length_squared() > 0.01 and visual_root:
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(move_dir.x, move_dir.z), 14.0 * delta)
		_play_anim_safe("Running_A")
	else:
		velocity.x = _knockback_vel.x
		velocity.z = _knockback_vel.z
		_play_anim_safe("Idle")

	move_and_slide()

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
	_is_attacking = false
	_set_axe_trails(false)
	KayKitVFXManager.spawn_hit_impact_at_chest(self)

	if knockback_dir.length_squared() > 0.001:
		var flat_kb := Vector3(knockback_dir.x, 0.0, knockback_dir.z).normalized()
		_knockback_vel = flat_kb * 6.5

	if hp <= 0.0:
		is_dead = true
		collision_layer = 0
		collision_mask = 1
		_play_anim_safe("Death_A")
		var tw := create_tween()
		tw.tween_interval(1.8)
		tw.tween_callback(queue_free)
	else:
		_action_lock_timer = 0.32
		_play_anim_safe("Hit_A")

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
