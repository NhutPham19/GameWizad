class_name KayKitVFXManager
extends RefCounted

# ==============================================================================
# KAYKIT VFX MANAGER — DIRECTIVE 15B, FILE LÕI SỐ 2
# Hệ thống VFX thuần khiết: 0% Hình Khối Cơ Bản (ZERO PRIMITIVE MESH)
# ⛔ NGHIÊM CẤM: BoxMesh, SphereMesh, CylinderMesh, CapsuleMesh, PrismMesh, TorusMesh
# Chỉ dùng: GPUParticles3D + Kenney Particle Textures + Decal + KayKit 3D Models
# ==============================================================================

# --- Đường dẫn texture VFX (Kenney Particle Pack) ---
const TEX_SLASH_01 := "res://assets/vfx_textures/slash_01.png"
const TEX_SPARK_02 := "res://assets/vfx_textures/spark_02.png"
const TEX_SPARK_05 := "res://assets/vfx_textures/spark_05.png"
const TEX_FLAME_02 := "res://assets/vfx_textures/flame_02.png"
const TEX_SMOKE_04 := "res://assets/vfx_textures/smoke_04.png"
const TEX_STAR_04 := "res://assets/vfx_textures/star_04.png"
const TEX_CIRCLE_01 := "res://assets/vfx_textures/circle_01.png"


## Tạo vật liệu hạt Additive Blend (nền đen/trong suốt biến mất 100%)
static func _create_additive_particle_mat(tex_path: String, tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = tint
	var tex := load(tex_path) as Texture2D
	if tex:
		mat.albedo_texture = tex
	else:
		push_warning("[KayKitVFXManager] Texture not found: %s" % tex_path)
	return mat


## Tạo ParticleProcessMaterial cơ bản cho GPUParticles3D
static func _create_particle_process_mat(
	direction: Vector3,
	spread: float,
	initial_velocity_min: float,
	initial_velocity_max: float,
	gravity: Vector3 = Vector3.ZERO,
	scale_min: float = 0.05,
	scale_max: float = 0.12
) -> ParticleProcessMaterial:
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = direction
	pmat.spread = spread
	pmat.initial_velocity_min = initial_velocity_min
	pmat.initial_velocity_max = initial_velocity_max
	pmat.gravity = gravity
	pmat.scale_min = scale_min
	pmat.scale_max = scale_max
	pmat.damping_min = 2.0
	pmat.damping_max = 5.0
	return pmat


# ==========================================================================
# 1. VỆT KIẾM KHÍ (Sword Trail Particles)
# ==========================================================================

## Tạo 2 GPUParticles3D gắn vào BladeCenterMarker & BladeTipMarker
## Trả về Array[GPUParticles3D] = [center_particles, tip_particles]
static func attach_sword_trail_particles(
	blade_center: Marker3D,
	blade_tip: Marker3D
) -> Array[GPUParticles3D]:
	# --- Center trail (vệt kiếm vàng kim) ---
	var center_p := GPUParticles3D.new()
	center_p.name = "SwordTrailCenter"
	center_p.emitting = false
	center_p.local_coords = false
	center_p.amount = 32
	center_p.lifetime = 0.16
	center_p.draw_pass_1 = QuadMesh.new()
	center_p.draw_pass_1.size = Vector2(0.08, 0.08)
	center_p.draw_pass_1.material = _create_additive_particle_mat(
		TEX_SLASH_01, Color(1.0, 0.85, 0.3, 1.0)  # Vàng kim
	)
	center_p.process_material = _create_particle_process_mat(
		Vector3(0, 1, 0), 25.0, 0.3, 1.2, Vector3.ZERO, 0.04, 0.1
	)
	blade_center.add_child(center_p)

	# --- Tip trail (tia lửa cam sáng) ---
	var tip_p := GPUParticles3D.new()
	tip_p.name = "SwordTrailTip"
	tip_p.emitting = false
	tip_p.local_coords = false
	tip_p.amount = 32
	tip_p.lifetime = 0.16
	tip_p.draw_pass_1 = QuadMesh.new()
	tip_p.draw_pass_1.size = Vector2(0.06, 0.06)
	tip_p.draw_pass_1.material = _create_additive_particle_mat(
		TEX_SPARK_02, Color(1.0, 0.6, 0.15, 1.0)  # Cam sáng
	)
	tip_p.process_material = _create_particle_process_mat(
		Vector3(0, 1, 0), 35.0, 0.5, 1.8, Vector3.ZERO, 0.03, 0.08
	)
	blade_tip.add_child(tip_p)

	var result: Array[GPUParticles3D] = [center_p, tip_p]
	return result


# ==========================================================================
# 2. NỔ TRÚNG ĐÒN TẠI NGỰC (Hit Impact at Chest)
# ==========================================================================

## Nổ hạt tại vị trí ngực mục tiêu (Y + 0.95m) rồi tự xóa
static func spawn_hit_impact_at_chest(target_node: Node3D) -> void:
	if not is_instance_valid(target_node):
		return

	var hit_pos: Vector3 = target_node.global_position + Vector3(0.0, 0.95, 0.0)

	var particles := GPUParticles3D.new()
	particles.name = "HitImpact"
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = 18
	particles.lifetime = 0.35
	particles.emitting = true
	particles.local_coords = false

	# Draw pass: QuadMesh với spark texture
	particles.draw_pass_1 = QuadMesh.new()
	particles.draw_pass_1.size = Vector2(0.1, 0.1)
	particles.draw_pass_1.material = _create_additive_particle_mat(
		TEX_SPARK_05, Color(1.0, 0.9, 0.4, 1.0)
	)

	# Process material: bung ra mọi hướng
	var pmat := _create_particle_process_mat(
		Vector3(0, 1, 0), 180.0, 2.0, 5.0,
		Vector3(0, -4.0, 0), 0.06, 0.14
	)
	particles.process_material = pmat

	var tree := target_node.get_tree()
	if tree == null:
		return
	var scene_parent: Node = tree.current_scene if tree.current_scene != null else tree.root
	scene_parent.add_child(particles)
	particles.global_position = hit_pos

	# Tự xóa khi hết hiệu ứng
	particles.finished.connect(particles.queue_free)


# ==========================================================================
# 3. ẤN CHÚ MẶT ĐẤT ĐA TẦNG (Ground Decal Shockwave)
# ==========================================================================

## Tạo Decal vòng sáng mặt đất, Tween phóng to rồi mờ dần, tự xóa
static func spawn_ground_decal_shockwave(
	parent: Node,
	ground_pos: Vector3,
	radius: float,
	color: Color
) -> void:
	var decal := Decal.new()
	decal.name = "GroundShockwave"
	decal.global_position = ground_pos + Vector3(0.0, 0.15, 0.0)  # Offset nhẹ lên trên mặt sàn

	# Kích thước khởi đầu nhỏ
	var initial_size := radius * 0.6
	decal.size = Vector3(initial_size * 2.0, 3.5, initial_size * 2.0)

	var circle_tex := load(TEX_CIRCLE_01) as Texture2D
	if circle_tex:
		decal.texture_albedo = circle_tex
	decal.modulate = color

	parent.add_child(decal)

	# Tween: phóng to bán kính rồi mờ dần
	var tween := parent.get_tree().create_tween()
	var final_size := Vector3(radius * 2.0, 3.5, radius * 2.0)
	tween.tween_property(decal, "size", final_size, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(decal, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(decal.queue_free)


# ==========================================================================
# 4. ĐẠN 3D THẬT KAYKIT (3D Projectile — Smokebomb / Arrow)
# ==========================================================================

## Phóng mô hình 3D thật (smokebomb hoặc arrow) tới target_pos
## projectile_type: "smokebomb" hoặc "arrow"
static func spawn_kaykit_3d_projectile(
	parent: Node,
	start_pos: Vector3,
	target_pos: Vector3,
	projectile_type: String = "smokebomb"
) -> void:
	var model_path: String
	var fly_time: float
	var use_arc: bool

	match projectile_type:
		"smokebomb":
			model_path = KayKitAssetRegistry.WEAPON_SMOKEBOMB
			fly_time = 0.55
			use_arc = true
		"arrow":
			model_path = KayKitAssetRegistry.WEAPON_ARROW
			fly_time = 0.35
			use_arc = false
		_:
			push_error("[KayKitVFXManager] Unknown projectile type: %s" % projectile_type)
			return

	var scene: PackedScene = load(model_path) as PackedScene
	if scene == null:
		push_error("[KayKitVFXManager] Failed to load projectile: %s" % model_path)
		return

	var proj: Node3D = scene.instantiate() as Node3D
	parent.add_child(proj)
	proj.global_position = start_pos

	# Hướng mũi tên/smokebomb về target
	var dir_to_target := (target_pos - start_pos).normalized()
	if dir_to_target.length_squared() > 0.001:
		proj.look_at(target_pos, Vector3.UP)

	var tween := parent.get_tree().create_tween()

	if use_arc:
		# Bay vòng cung (smokebomb)
		var mid_pos := (start_pos + target_pos) * 0.5
		mid_pos.y += 3.5  # Độ cao vòng cung

		# Phase 1: bay lên đỉnh vòng cung
		tween.tween_property(proj, "global_position", mid_pos, fly_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Phase 2: rơi xuống target
		tween.tween_property(proj, "global_position", target_pos, fly_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		# Bay thẳng (arrow)
		tween.tween_property(proj, "global_position", target_pos, fly_time).set_trans(Tween.TRANS_LINEAR)

	# Khi đến nơi: bung hiệu ứng nổ rồi xóa
	tween.tween_callback(func():
		if projectile_type == "smokebomb":
			# Bung cụm khói
			_spawn_smoke_burst(parent, target_pos)
		# Xóa đạn
		proj.queue_free()
	)


## Bung cụm hạt khói tại vị trí nổ (dùng cho smokebomb)
static func _spawn_smoke_burst(parent: Node, pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "SmokeBurst"
	particles.one_shot = true
	particles.explosiveness = 0.85
	particles.amount = 24
	particles.lifetime = 0.5
	particles.emitting = true
	particles.local_coords = false
	particles.global_position = pos

	particles.draw_pass_1 = QuadMesh.new()
	particles.draw_pass_1.size = Vector2(0.25, 0.25)
	particles.draw_pass_1.material = _create_additive_particle_mat(
		TEX_SMOKE_04, Color(0.7, 0.7, 0.7, 0.8)
	)

	particles.process_material = _create_particle_process_mat(
		Vector3(0, 1, 0), 120.0, 1.0, 3.0,
		Vector3(0, -2.0, 0), 0.15, 0.35
	)

	parent.add_child(particles)
	particles.finished.connect(particles.queue_free)


# ==========================================================================
# 5. BẬT / TẮT VỆT KIẾM (Utility cho HeroKnight3D)
# ==========================================================================

## Bật emitting cho tất cả trail particles
static func enable_sword_trails(trails: Array[GPUParticles3D]) -> void:
	for p in trails:
		if is_instance_valid(p):
			p.emitting = true


## Tắt emitting cho tất cả trail particles
static func disable_sword_trails(trails: Array[GPUParticles3D]) -> void:
	for p in trails:
		if is_instance_valid(p):
			p.emitting = false
