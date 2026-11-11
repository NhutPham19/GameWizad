class_name KayKitVFXManager
extends Node3D

# ==============================================================================
# KAYKIT VFX MANAGER — DIRECTIVE 20 (PHASE 20 OVERHAUL)
# Hệ thống VFX Kiếm Khí Đa Tầng 3D & Kỹ Xảo Chiêu Thức Chuẩn Studio
# TUYỆT ĐỐI 0% PRIMITIVE MESH — 100% ArrayMesh (ZERO PRIMITIVE MESHES GUARANTEED)
# Phục vụ 6 chiêu thức HeroKnight3D & Đòn đánh kẻ địch
# ==============================================================================

const TEX_DIR := "res://assets/vfx_textures/"
const SLASH_SHADER_PATH := "res://shaders/vfx_stylized_slash.gdshader"

# Texture paths
const TEX_SLASH_01 := "res://assets/vfx_textures/slash_01.png"
const TEX_SLASH_02 := "res://assets/vfx_textures/slash_02.png"
const TEX_SLASH_04 := "res://assets/vfx_textures/slash_04.png"
const TEX_SPARK_01 := "res://assets/vfx_textures/spark_01.png"
const TEX_SPARK_02 := "res://assets/vfx_textures/spark_02.png"
const TEX_SPARK_03 := "res://assets/vfx_textures/spark_03.png"
const TEX_SPARK_05 := "res://assets/vfx_textures/spark_05.png"
const TEX_SPARK_06 := "res://assets/vfx_textures/spark_06.png"
const TEX_FLAME_02 := "res://assets/vfx_textures/flame_02.png"
const TEX_FLAME_04 := "res://assets/vfx_textures/flame_04.png"
const TEX_SMOKE_04 := "res://assets/vfx_textures/smoke_04.png"
const TEX_SMOKE_07 := "res://assets/vfx_textures/smoke_07.png"
const TEX_STAR_04 := "res://assets/vfx_textures/star_04.png"
const TEX_STAR_08 := "res://assets/vfx_textures/star_08.png"
const TEX_CIRCLE_01 := "res://assets/vfx_textures/circle_01.png"
const TEX_CIRCLE_02 := "res://assets/vfx_textures/circle_02.png"
const TEX_CIRCLE_03 := "res://assets/vfx_textures/circle_03.png"
const TEX_CIRCLE_04 := "res://assets/vfx_textures/circle_04.png"
const TEX_CIRCLE_05 := "res://assets/vfx_textures/circle_05.png"
const TEX_SCORCH_02 := "res://assets/vfx_textures/scorch_02.png"
const TEX_TWIRL_01 := "res://assets/vfx_textures/twirl_01.png"
const TEX_TWIRL_02 := "res://assets/vfx_textures/twirl_02.png"
const TEX_TWIRL_03 := "res://assets/vfx_textures/twirl_03.png"
const TEX_MAGIC_03 := "res://assets/vfx_textures/magic_03.png"
const TEX_LIGHT_02 := "res://assets/vfx_textures/light_02.png"

static var _cached_slash_shader: Shader = null
static var _tex_cache: Dictionary = {}

static func _get_root_parent(parent_node: Node = null) -> Node:
	if is_instance_valid(parent_node):
		return parent_node
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		if tree.current_scene != null:
			return tree.current_scene
		return tree.root
	return null

static func _get_tex(file_name: String) -> Texture2D:
	if _tex_cache.has(file_name):
		return _tex_cache[file_name]
	var full_path := file_name if file_name.begins_with("res://") else (TEX_DIR + file_name)
	if ResourceLoader.exists(full_path):
		var t := load(full_path) as Texture2D
		_tex_cache[file_name] = t
		return t
	return null

static func _get_slash_shader() -> Shader:
	if _cached_slash_shader == null and ResourceLoader.exists(SLASH_SHADER_PATH):
		_cached_slash_shader = load(SLASH_SHADER_PATH) as Shader
	return _cached_slash_shader

# ==============================================================================
# 0. LÕI HÌNH HỌC AN TOÀN (ZERO PRIMITIVE MESHES)
# ==============================================================================

## Tạo lưới phẳng 2 tam giác bằng ArrayMesh (mesh is PrimitiveMesh == FALSE 100%)
static func get_safe_particle_quad_mesh(size: Vector2 = Vector2(1.0, 1.0)) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(Vector3(-hw,  hh, 0.0))
	st.set_uv(Vector2(1.0, 0.0)); st.add_vertex(Vector3( hw,  hh, 0.0))
	st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(Vector3( hw, -hh, 0.0))

	st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(Vector3(-hw,  hh, 0.0))
	st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(Vector3( hw, -hh, 0.0))
	st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(Vector3(-hw, -hh, 0.0))
	return st.commit()

## Tạo Dải Lưới Cung Trăng Uốn Cong 3D bằng ArrayMesh (Procedural Curved Crescent Slash Arc ArrayMesh)
static func build_curved_slash_arc_mesh(
	inner_radius: float = 0.85,
	outer_radius: float = 2.55,
	arc_angle_deg: float = 155.0,
	segments: int = 28,
	vertical_arch: float = 0.12
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var total_rad := deg_to_rad(arc_angle_deg)
	var start_rad := -total_rad * 0.5

	for i in range(segments):
		var t0 := float(i) / float(segments)
		var t1 := float(i + 1) / float(segments)
		var a0 := start_rad + t0 * total_rad
		var a1 := start_rad + t1 * total_rad

		# Độ mở rộng hình lưỡi liềm: Thuôn nhọn ở 2 đầu (0.0 và 1.0), phình to sắc lẹm ở giữa cung
		var width_scale0 := sin(t0 * PI)
		var width_scale1 := sin(t1 * PI)
		var cur_in0 := lerpf(outer_radius * 0.92, inner_radius, width_scale0)
		var cur_in1 := lerpf(outer_radius * 0.92, inner_radius, width_scale1)

		var y_arch0 := sin(t0 * PI) * vertical_arch
		var y_arch1 := sin(t1 * PI) * vertical_arch

		var p0_in := Vector3(sin(a0) * cur_in0, y_arch0, cos(a0) * cur_in0)
		var p0_out := Vector3(sin(a0) * outer_radius, y_arch0 * 0.5, cos(a0) * outer_radius)
		var p1_in := Vector3(sin(a1) * cur_in1, y_arch1, cos(a1) * cur_in1)
		var p1_out := Vector3(sin(a1) * outer_radius, y_arch1 * 0.5, cos(a1) * outer_radius)

		# Tam giác 1
		st.set_uv(Vector2(t0, 0.0)); st.add_vertex(p0_in)
		st.set_uv(Vector2(t0, 1.0)); st.add_vertex(p0_out)
		st.set_uv(Vector2(t1, 1.0)); st.add_vertex(p1_out)
		# Tam giác 2
		st.set_uv(Vector2(t0, 0.0)); st.add_vertex(p0_in)
		st.set_uv(Vector2(t1, 1.0)); st.add_vertex(p1_out)
		st.set_uv(Vector2(t1, 0.0)); st.add_vertex(p1_in)

	return st.commit()

## Helper tạo StandardMaterial3D cho hạt hạt Additive (100% trong suốt nền đen)
static func _create_additive_particle_mat(tex: Texture2D, tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = tint
	mat.albedo_texture = tex
	return mat

## Helper tạo ParticleProcessMaterial
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

# ==============================================================================
# 1. HIỆU ỨNG CỐT LÕI: TRIỆU HỒI VỆT CHÉM CUNG TRĂNG ĐA TẦNG (Task 20.3)
# ==============================================================================

static func spawn_stylized_crescent_slash(
	origin_pos: Vector3,
	forward_yaw: float,
	tilt_roll_deg: float = 0.0,
	reverse_swing: bool = false,
	core_col: Color = Color(1.0, 1.0, 1.0, 1.0),
	main_col: Color = Color(0.0, 0.85, 1.0, 1.0),
	edge_col: Color = Color(1.0, 0.45, 0.05, 1.0),
	scale_mult: float = 1.0,
	duration: float = 0.24,
	parent_node: Node = null
) -> Node3D:
	var p := _get_root_parent(parent_node)
	if p == null:
		return null

	var slash_root := Node3D.new()
	slash_root.name = "StylizedSlashArcFX"
	p.add_child(slash_root)
	slash_root.global_position = origin_pos
	slash_root.rotation.y = forward_yaw

	# Pivot nghiêng mặt phẳng chém (Ngang 0 độ, Chéo 32 độ, Bổ dọc 85 độ)
	var tilt_pivot := Node3D.new()
	tilt_pivot.name = "TiltPivot"
	slash_root.add_child(tilt_pivot)
	tilt_pivot.rotation.z = deg_to_rad(tilt_roll_deg)
	if reverse_swing:
		tilt_pivot.scale.x = -1.0

	# LỚP 1 & 2: Lưới Cung Trăng ArrayMesh + Shader 3 Tầng Màu
	var arc_mesh_inst := MeshInstance3D.new()
	arc_mesh_inst.name = "MainArcMesh"
	arc_mesh_inst.mesh = build_curved_slash_arc_mesh(0.75 * scale_mult, 2.65 * scale_mult, 160.0, 28, 0.10)
	arc_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var smat := ShaderMaterial.new()
	smat.shader = _get_slash_shader()
	smat.set_shader_parameter("slash_mask_tex", _get_tex("slash_01.png"))
	smat.set_shader_parameter("core_color", core_col)
	smat.set_shader_parameter("main_color", main_col)
	smat.set_shader_parameter("edge_color", edge_col)
	smat.set_shader_parameter("emission_boost", 4.2)
	smat.set_shader_parameter("progress", 0.05)
	arc_mesh_inst.material_override = smat
	tilt_pivot.add_child(arc_mesh_inst)

	# LỚP 3: Dải Phụ Bóng Mờ Năng Lượng (Secondary After-Glow Arc)
	var sub_arc := MeshInstance3D.new()
	sub_arc.name = "SubArcMesh"
	sub_arc.mesh = build_curved_slash_arc_mesh(0.55 * scale_mult, 2.20 * scale_mult, 140.0, 20, -0.06)
	sub_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sub_mat := smat.duplicate() as ShaderMaterial
	sub_mat.set_shader_parameter("emission_boost", 2.4)
	sub_mat.set_shader_parameter("streak_frequency", 28.0)
	sub_arc.material_override = sub_mat
	sub_arc.rotation.y = deg_to_rad(-12.0)
	tilt_pivot.add_child(sub_arc)

	# LỚP 4: Chùm Hạt Tia Lửa Bay Theo Cung Kiếm (Velocity-Stretched Sparks)
	_spawn_slash_sparks_burst(tilt_pivot, main_col, edge_col, scale_mult)

	# LỚP 5: Chớp Sáng Không Gian (Dynamic Combat Light Flash)
	var flash_light := OmniLight3D.new()
	flash_light.name = "SlashFlashLight"
	flash_light.light_color = main_col.lerp(edge_col, 0.35)
	flash_light.light_energy = 3.2
	flash_light.omni_range = 4.8 * scale_mult
	slash_root.add_child(flash_light)

	# Diễn hoạt quét cung kiếm mượt mà bằng Tween
	var tw := slash_root.create_tween().set_parallel(true)
	tw.tween_method(func(v: float):
		if is_instance_valid(smat):
			smat.set_shader_parameter("progress", v)
		if is_instance_valid(sub_mat):
			sub_mat.set_shader_parameter("progress", clampf(v - 0.08, 0.0, 1.0))
	, 0.05, 1.0, duration)
	tw.tween_property(tilt_pivot, "rotation:y", deg_to_rad(28.0), duration).from(deg_to_rad(-18.0))
	tw.tween_property(flash_light, "light_energy", 0.0, duration)
	tw.chain().tween_callback(slash_root.queue_free)

	return slash_root

static func _spawn_slash_sparks_burst(parent_node: Node3D, col_a: Color, col_b: Color, scale_mult: float) -> void:
	var sparks := GPUParticles3D.new()
	sparks.name = "SlashSparks"
	sparks.amount = 22
	sparks.lifetime = 0.26
	sparks.one_shot = true
	sparks.explosiveness = 0.88
	sparks.local_coords = false

	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pmat.emission_ring_axis = Vector3(0, 1, 0)
	pmat.emission_ring_radius = 1.9 * scale_mult
	pmat.emission_ring_inner_radius = 1.2 * scale_mult
	pmat.emission_ring_height = 0.15
	pmat.direction = Vector3(0, 0.2, 1)
	pmat.spread = 65.0
	pmat.initial_velocity_min = 4.5
	pmat.initial_velocity_max = 9.5
	pmat.gravity = Vector3(0, -4.0, 0)
	pmat.damping_min = 6.0
	pmat.damping_max = 12.0
	pmat.scale_min = 0.22
	pmat.scale_max = 0.48

	var grad := Gradient.new()
	grad.set_color(0, Color(col_a.r * 2.0, col_a.g * 2.0, col_a.b * 2.0, 1.0))
	grad.set_color(1, Color(col_b.r, col_b.g, col_b.b, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	pmat.color_ramp = grad_tex
	sparks.process_material = pmat

	var draw_mat := StandardMaterial3D.new()
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	draw_mat.vertex_color_use_as_albedo = true
	draw_mat.albedo_texture = _get_tex("spark_02.png")

	var quad_mesh := get_safe_particle_quad_mesh(Vector2(0.55, 0.55))
	quad_mesh.surface_set_material(0, draw_mat)
	sparks.draw_pass_1 = quad_mesh

	parent_node.add_child(sparks)
	sparks.emitting = true

# ==============================================================================
# 2. TOÀN BỘ 6 CHIÊU THỨC HERO KNIGHT 3D (Task 20.4)
# ==============================================================================

## Chiêu 1: Đánh thường LMB Combo 3 Nhịp Biến Hóa
static func spawn_combo_slash_vfx(
	combo_step: int,
	origin: Vector3,
	yaw: float,
	parent_node: Node = null
) -> void:
	match combo_step:
		0:
			# Nhịp 1: Slice_Horizontal — Hàn Băng Lưu Quang Trảm
			spawn_stylized_crescent_slash(
				origin,
				yaw,
				4.0,     # tilt_roll_deg
				false,   # reverse_swing
				Color(1.0, 1.0, 1.0, 1.0), # Lõi Trắng HDR
				Color(0.0, 0.85, 1.0, 1.0), # Thân Xanh Băng Điện Tử (#00D8FF)
				Color(1.0, 0.45, 0.0, 1.0), # Viền Cam Lửa (#FF7300)
				1.0,
				0.24,
				parent_node
			)
		1:
			# Nhịp 2: Slice_Diagonal — Song Nha Nghịch Phong Trảm
			spawn_stylized_crescent_slash(
				origin,
				yaw,
				-32.0,   # tilt_roll_deg chém chéo
				true,    # reverse_swing từ trái qua phải
				Color(1.0, 1.0, 1.0, 1.0),
				Color(0.0, 0.85, 1.0, 1.0),
				Color(1.0, 0.45, 0.0, 1.0),
				1.05,
				0.24,
				parent_node
			)
			# Sau 0.05s sinh thêm vệt chém phụ góc +18.0 tạo Song Kiếm Giao Hoa
			var tree := Engine.get_main_loop() as SceneTree
			if tree != null:
				var t := tree.create_timer(0.05)
				t.timeout.connect(func():
					spawn_stylized_crescent_slash(
						origin,
						yaw,
						18.0,
						false,
						Color(1.0, 1.0, 1.0, 1.0),
						Color(0.2, 0.9, 1.0, 1.0),
						Color(1.0, 0.6, 0.1, 1.0),
						0.92,
						0.20,
						parent_node
					)
				)
		2, _:
			# Nhịp 3: Chop — Liệt Hỏa Phá Thạch Trảm (Bổ Dọc Uy Lực Lớn)
			spawn_stylized_crescent_slash(
				origin,
				yaw,
				85.0,    # tilt_roll_deg bổ thẳng đứng
				false,
				Color(1.0, 0.97, 0.84, 1.0), # Lõi Vàng Trắng (#FFF8D6)
				Color(1.0, 0.23, 0.0, 1.0),  # Thân Đỏ Hoàng Kim (#FF3B00)
				Color(0.72, 0.0, 1.0, 1.0),  # Viền Tím Sẫm (#B800FF)
				1.28,
				0.30,
				parent_node
			)
			# Vụ Nổ Địa Chấn Kép dưới sàn
			var forward_vec := Vector3(sin(yaw), 0.0, cos(yaw)).normalized()
			var impact_pos := origin + forward_vec * 1.65
			impact_pos.y = origin.y - 0.90
			_spawn_earth_shatter_burst(impact_pos, parent_node)

## Vụ nổ địa chấn kép cho Nhịp 3 LMB
static func _spawn_earth_shatter_burst(ground_pos: Vector3, parent_node: Node = null) -> void:
	var p := _get_root_parent(parent_node)
	if p == null:
		return

	# Decal 1: scorch_02.png dung nham đỏ cam nở từ 0.5m -> 3.6m
	var d1 := Decal.new()
	d1.name = "EarthShatterDecal"
	d1.size = Vector3(1.0, 3.0, 1.0)
	d1.texture_albedo = _get_tex("scorch_02.png")
	d1.modulate = Color(1.0, 0.35, 0.05, 0.95)
	p.add_child(d1)
	d1.global_position = ground_pos + Vector3(0.0, 0.12, 0.0)

	# Decal 2: circle_02.png sóng xung kích vàng rực nở nhanh ra 4.2m
	var d2 := Decal.new()
	d2.name = "ShockwaveRingDecal"
	d2.size = Vector3(1.2, 3.0, 1.2)
	d2.texture_albedo = _get_tex("circle_02.png")
	d2.modulate = Color(1.0, 0.85, 0.2, 0.9)
	p.add_child(d2)
	d2.global_position = ground_pos + Vector3(0.0, 0.15, 0.0)

	var tw := d1.create_tween().set_parallel(true)
	tw.tween_property(d1, "size", Vector3(3.6, 3.0, 3.6), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(d2, "size", Vector3(4.2, 3.0, 4.2), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(d1, "modulate:a", 0.0, 0.55)
	tw.parallel().tween_property(d2, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(d1.queue_free)
	tw.parallel().tween_callback(d2.queue_free)

	# Cột hạt tia lửa flame_04 + spark_05 bắn tung tóe lên trời
	var fire_burst := GPUParticles3D.new()
	fire_burst.name = "EarthFirePillar"
	fire_burst.amount = 26
	fire_burst.lifetime = 0.45
	fire_burst.one_shot = true
	fire_burst.explosiveness = 0.92
	fire_burst.local_coords = false

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 45.0
	pmat.initial_velocity_min = 6.0
	pmat.initial_velocity_max = 12.0
	pmat.gravity = Vector3(0, -7.0, 0)
	pmat.damping_min = 3.0
	pmat.damping_max = 8.0
	pmat.scale_min = 0.35
	pmat.scale_max = 0.75
	fire_burst.process_material = pmat

	var draw_mat := _create_additive_particle_mat(_get_tex("flame_04.png"), Color(1.0, 0.6, 0.1, 1.0))
	var qmesh := get_safe_particle_quad_mesh(Vector2(0.65, 0.65))
	qmesh.surface_set_material(0, draw_mat)
	fire_burst.draw_pass_1 = qmesh

	p.add_child(fire_burst)
	fire_burst.global_position = ground_pos + Vector3(0.0, 0.25, 0.0)
	fire_burst.emitting = true
	fire_burst.finished.connect(fire_burst.queue_free)

## Chiêu 2: Khiên Phản Kích RMB — Thánh Khiên Ấn Chú & Mũi Giáo Xoáy
static func spawn_shield_bash_vfx(
	origin: Vector3,
	yaw: float,
	parent_node: Node = null
) -> void:
	var p := _get_root_parent(parent_node)
	if p == null:
		return

	var forward_vec := Vector3(sin(yaw), 0.0, cos(yaw)).normalized()
	var shield_pos := origin + forward_vec * 0.85 + Vector3(0.0, 0.95, 0.0)

	# 1. Ấn Chú Thánh Khiên Dựng Đứng (Sprite3D xoay tròn và phóng to 0.4m -> 1.8m)
	var shield_sprite := Sprite3D.new()
	shield_sprite.name = "HolyShieldRune"
	shield_sprite.texture = _get_tex("circle_01.png")
	shield_sprite.modulate = Color(2.6, 1.9, 0.4, 1.0) # Vàng Hoàng Kim HDR
	shield_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	shield_sprite.no_depth_test = true
	shield_sprite.render_priority = 8
	shield_sprite.pixel_size = 0.003
	shield_sprite.scale = Vector3(0.4, 0.4, 0.4)
	p.add_child(shield_sprite)
	shield_sprite.global_position = shield_pos
	shield_sprite.rotation.y = yaw

	var tw := shield_sprite.create_tween().set_parallel(true)
	tw.tween_property(shield_sprite, "scale", Vector3(1.8, 1.8, 1.8), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(shield_sprite, "rotation:z", PI * 2.0, 0.25)
	tw.chain().tween_property(shield_sprite, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(shield_sprite.queue_free)

	# 2. Luồng Xung Kích Đâm Xuyên (twirl_01 + spark_03)
	var drill_sparks := GPUParticles3D.new()
	drill_sparks.name = "ShieldDrillSparks"
	drill_sparks.amount = 20
	drill_sparks.lifetime = 0.28
	drill_sparks.one_shot = true
	drill_sparks.explosiveness = 0.85
	drill_sparks.local_coords = false

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = forward_vec
	pmat.spread = 22.0
	pmat.initial_velocity_min = 7.5
	pmat.initial_velocity_max = 14.0
	pmat.gravity = Vector3.ZERO
	pmat.damping_min = 5.0
	pmat.damping_max = 10.0
	pmat.scale_min = 0.35
	pmat.scale_max = 0.65
	drill_sparks.process_material = pmat

	var draw_mat := _create_additive_particle_mat(_get_tex("spark_03.png"), Color(1.0, 0.85, 0.3, 1.0))
	var qmesh := get_safe_particle_quad_mesh(Vector2(0.45, 0.45))
	qmesh.surface_set_material(0, draw_mat)
	drill_sparks.draw_pass_1 = qmesh

	p.add_child(drill_sparks)
	drill_sparks.global_position = shield_pos
	drill_sparks.emitting = true
	drill_sparks.finished.connect(drill_sparks.queue_free)

	# Vòng sóng xung kích Decal dưới sàn
	spawn_ground_decal_shockwave(p, origin, 2.5, Color(0.3, 0.7, 1.0, 0.8))

## Chiêu 3: Tuyệt chiêu Q — Song Long Lốc Xoáy 360° (Task 20.4 Chiêu Q)
static func spawn_whirlwind_360_vfx(
	hero_node: Node3D,
	parent_node: Node = null
) -> void:
	if not is_instance_valid(hero_node):
		return
	var p := _get_root_parent(parent_node)
	if p == null:
		return

	var vortex_root := Node3D.new()
	vortex_root.name = "WhirlwindVortexFX"
	hero_node.add_child(vortex_root)
	vortex_root.position = Vector3(0.0, 0.85, 0.0)

	# --- VÒNG 1: Xanh Băng Điện Tử – Lõi Trắng – Viền Cam (Nghiêng +14 độ) ---
	var ring1_pivot := Node3D.new()
	ring1_pivot.name = "WhirlwindRing1Pivot"
	ring1_pivot.rotation.x = deg_to_rad(14.0)
	vortex_root.add_child(ring1_pivot)

	var ring1_mesh := MeshInstance3D.new()
	ring1_mesh.name = "WhirlwindArc1"
	ring1_mesh.mesh = build_curved_slash_arc_mesh(1.1, 3.1, 340.0, 36, 0.25)
	ring1_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var smat1 := ShaderMaterial.new()
	smat1.shader = _get_slash_shader()
	smat1.set_shader_parameter("slash_mask_tex", _get_tex("slash_01.png"))
	smat1.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
	smat1.set_shader_parameter("main_color", Color(0.0, 0.85, 1.0, 1.0)) # Xanh Băng Cyan
	smat1.set_shader_parameter("edge_color", Color(1.0, 0.45, 0.05, 1.0)) # Viền Cam Lửa
	smat1.set_shader_parameter("emission_boost", 4.2)
	smat1.set_shader_parameter("progress", 0.1)
	ring1_mesh.material_override = smat1
	ring1_pivot.add_child(ring1_mesh)

	# --- VÒNG 2: Cam Lửa Hoàng Kim – Lõi Trắng – Viền Đỏ (Nghiêng -14 độ, lệch pha 180 độ) ---
	var ring2_pivot := Node3D.new()
	ring2_pivot.name = "WhirlwindRing2Pivot"
	ring2_pivot.rotation.x = deg_to_rad(-14.0)
	ring2_pivot.rotation.y = PI # Lệch pha 180 độ
	vortex_root.add_child(ring2_pivot)

	var ring2_mesh := MeshInstance3D.new()
	ring2_mesh.name = "WhirlwindArc2"
	ring2_mesh.mesh = build_curved_slash_arc_mesh(1.1, 3.1, 340.0, 36, -0.25)
	ring2_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var smat2 := ShaderMaterial.new()
	smat2.shader = _get_slash_shader()
	smat2.set_shader_parameter("slash_mask_tex", _get_tex("slash_01.png"))
	smat2.set_shader_parameter("core_color", Color(1.0, 0.96, 0.84, 1.0))
	smat2.set_shader_parameter("main_color", Color(1.0, 0.53, 0.0, 1.0)) # Cam Lửa Hoàng Kim
	smat2.set_shader_parameter("edge_color", Color(0.90, 0.12, 0.16, 1.0)) # Viền Đỏ Huyết
	smat2.set_shader_parameter("emission_boost", 4.2)
	smat2.set_shader_parameter("progress", 0.1)
	ring2_mesh.material_override = smat2
	ring2_pivot.add_child(ring2_mesh)

	# --- Trận Pháp Kép Dưới Chân (circle_05 Xanh Cyan & twirl_03 Vàng Cam) ---
	var decal1 := Decal.new()
	decal1.name = "WhirlwindDecal1"
	decal1.position = Vector3(0.0, -0.75, 0.0)
	decal1.size = Vector3(5.8, 2.5, 5.8)
	decal1.texture_albedo = _get_tex("circle_05.png")
	decal1.modulate = Color(0.0, 0.8, 1.0, 0.8)
	vortex_root.add_child(decal1)

	var decal2 := Decal.new()
	decal2.name = "WhirlwindDecal2"
	decal2.position = Vector3(0.0, -0.72, 0.0)
	decal2.size = Vector3(5.2, 2.5, 5.2)
	decal2.texture_albedo = _get_tex("twirl_03.png")
	decal2.modulate = Color(1.0, 0.6, 0.1, 0.8)
	vortex_root.add_child(decal2)

	# Luồng hạt tia lửa xoáy từ chân lên đầu (spark_01)
	var vortex_sparks := GPUParticles3D.new()
	vortex_sparks.name = "WhirlwindSparks"
	vortex_sparks.amount = 30
	vortex_sparks.lifetime = 0.35
	vortex_sparks.local_coords = false

	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pmat.emission_ring_axis = Vector3(0, 1, 0)
	pmat.emission_ring_radius = 2.4
	pmat.emission_ring_inner_radius = 1.0
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 35.0
	pmat.initial_velocity_min = 3.5
	pmat.initial_velocity_max = 7.0
	pmat.gravity = Vector3(0, 2.0, 0)
	pmat.scale_min = 0.25
	pmat.scale_max = 0.55
	vortex_sparks.process_material = pmat

	var draw_mat := _create_additive_particle_mat(_get_tex("spark_01.png"), Color(1.0, 0.8, 0.3, 1.0))
	var qmesh := get_safe_particle_quad_mesh(Vector2(0.45, 0.45))
	qmesh.surface_set_material(0, draw_mat)
	vortex_sparks.draw_pass_1 = qmesh
	vortex_root.add_child(vortex_sparks)
	vortex_sparks.emitting = true

	# Diễn hoạt xoay 1080 độ trong 0.48s
	var duration := 0.48
	var tw := vortex_root.create_tween().set_parallel(true)
	tw.tween_property(ring1_pivot, "rotation:y", deg_to_rad(1080.0), duration)
	tw.tween_property(ring2_pivot, "rotation:y", PI + deg_to_rad(1080.0), duration)
	tw.tween_property(decal1, "rotation:y", deg_to_rad(360.0), duration)
	tw.tween_property(decal2, "rotation:y", deg_to_rad(-360.0), duration)

	tw.tween_method(func(v: float):
		if is_instance_valid(smat1):
			smat1.set_shader_parameter("progress", v)
		if is_instance_valid(smat2):
			smat2.set_shader_parameter("progress", v)
	, 0.1, 0.95, duration)

	tw.chain().tween_callback(vortex_root.queue_free)

## Chiêu 4: Bom Khói 3D phím E — Ám Ảnh Lôi Vụ 4 Tầng
static func spawn_smoke_bomb_3d(
	parent_node: Node,
	start_pos: Vector3,
	target_pos: Vector3
) -> void:
	var p := _get_root_parent(parent_node)
	if p == null:
		return

	var model_path := "res://assets/weapons/smokebomb.gltf"
	var scene: PackedScene = null
	if ResourceLoader.exists(model_path):
		scene = load(model_path) as PackedScene

	var proj: Node3D = null
	if scene != null:
		proj = scene.instantiate() as Node3D
	else:
		proj = Node3D.new()

	proj.name = "SmokeBomb3DProjectile"
	p.add_child(proj)
	proj.global_position = start_pos

	# Đuôi sáng màu Tím Ngọc (magic_03)
	var trail := GPUParticles3D.new()
	trail.name = "BombTrail"
	trail.amount = 16
	trail.lifetime = 0.25
	trail.local_coords = false

	var tpmat := ParticleProcessMaterial.new()
	tpmat.direction = Vector3(0, 0, -1)
	tpmat.spread = 25.0
	tpmat.initial_velocity_min = 1.0
	tpmat.initial_velocity_max = 2.5
	tpmat.gravity = Vector3(0, -1.0, 0)
	tpmat.scale_min = 0.15
	tpmat.scale_max = 0.35
	trail.process_material = tpmat

	var tmat := _create_additive_particle_mat(_get_tex("magic_03.png"), Color(0.7, 0.3, 1.0, 0.9))
	var qmesh := get_safe_particle_quad_mesh(Vector2(0.35, 0.35))
	qmesh.surface_set_material(0, tmat)
	trail.draw_pass_1 = qmesh
	proj.add_child(trail)
	trail.emitting = true

	# Bay theo đường parabol (fly_time = 0.55s)
	var fly_time := 0.55
	var mid_pos := (start_pos + target_pos) * 0.5
	mid_pos.y += 3.5

	var tween := proj.create_tween()
	tween.tween_property(proj, "global_position", mid_pos, fly_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(proj, "global_position", target_pos, fly_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_spawn_smoke_bomb_4layer_detonation(p, target_pos)
		proj.queue_free()
	)

## Nổ 4 lớp liên hoàn của Ám Ảnh Lôi Vụ
static func _spawn_smoke_bomb_4layer_detonation(parent: Node, pos: Vector3) -> void:
	# Lớp 1: Chớp Sáng Tâm Nổ (Sprite3D light_02 + OmniLight3D Tím Điện)
	var flash_sprite := Sprite3D.new()
	flash_sprite.name = "SmokeDetonationFlash"
	flash_sprite.texture = _get_tex("light_02.png")
	flash_sprite.modulate = Color(0.85, 0.35, 1.0, 1.0)
	flash_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flash_sprite.no_depth_test = true
	flash_sprite.pixel_size = 0.012
	parent.add_child(flash_sprite)
	flash_sprite.global_position = pos + Vector3(0.0, 0.8, 0.0)

	var light := OmniLight3D.new()
	light.light_color = Color(0.8, 0.3, 1.0)
	light.light_energy = 4.5
	light.omni_range = 5.5
	parent.add_child(light)
	light.global_position = pos + Vector3(0.0, 0.8, 0.0)

	var tw_flash := flash_sprite.create_tween().set_parallel(true)
	tw_flash.tween_property(flash_sprite, "scale", Vector3(2.5, 2.5, 2.5), 0.35)
	tw_flash.tween_property(flash_sprite, "modulate:a", 0.0, 0.35)
	tw_flash.tween_property(light, "light_energy", 0.0, 0.35)
	tw_flash.chain().tween_callback(flash_sprite.queue_free)
	tw_flash.parallel().tween_callback(light.queue_free)

	# Lớp 2: Ấn Chú Mặt Đất (Decal circle_04 màu Tím Hồng in chặt trong 2.5s)
	var ground_decal := Decal.new()
	ground_decal.name = "SmokeRuneDecal"
	ground_decal.size = Vector3(8.0, 4.0, 8.0)
	ground_decal.texture_albedo = _get_tex("circle_04.png")
	ground_decal.modulate = Color(0.75, 0.2, 0.9, 0.85)
	parent.add_child(ground_decal)
	ground_decal.global_position = pos + Vector3(0.0, 0.15, 0.0)

	var tw_decal := ground_decal.create_tween()
	tw_decal.tween_interval(2.1)
	tw_decal.tween_property(ground_decal, "modulate:a", 0.0, 0.4)
	tw_decal.tween_callback(ground_decal.queue_free)

	# Lớp 3: Đám Mây Khói Ma Thuật Cuộn Xoáy (smoke_04 & smoke_07 Tím Đen dày đặc)
	var smoke := GPUParticles3D.new()
	smoke.name = "SmokeCloudZone"
	smoke.amount = 32
	smoke.lifetime = 2.2
	smoke.one_shot = true
	smoke.explosiveness = 0.82
	smoke.local_coords = false

	var spmat := ParticleProcessMaterial.new()
	spmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spmat.emission_sphere_radius = 2.2
	spmat.direction = Vector3(0, 1, 0)
	spmat.spread = 80.0
	spmat.initial_velocity_min = 1.2
	spmat.initial_velocity_max = 3.2
	spmat.gravity = Vector3(0, 0.2, 0)
	spmat.damping_min = 1.5
	spmat.damping_max = 3.5
	spmat.scale_min = 0.8
	spmat.scale_max = 1.8
	smoke.process_material = spmat

	var smat := _create_additive_particle_mat(_get_tex("smoke_04.png"), Color(0.42, 0.15, 0.55, 0.75))
	var qmesh := get_safe_particle_quad_mesh(Vector2(1.2, 1.2))
	qmesh.surface_set_material(0, smat)
	smoke.draw_pass_1 = qmesh

	parent.add_child(smoke)
	smoke.global_position = pos + Vector3(0.0, 0.5, 0.0)
	smoke.emitting = true
	smoke.finished.connect(smoke.queue_free)

	# Lớp 4: Tia Sét Giật Trong Khói (spark_06 giật lách tách)
	var thunder := GPUParticles3D.new()
	thunder.name = "SmokeThunderSparks"
	thunder.amount = 24
	thunder.lifetime = 0.35
	thunder.one_shot = false
	thunder.local_coords = false

	var th_pmat := ParticleProcessMaterial.new()
	th_pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	th_pmat.emission_sphere_radius = 3.0
	th_pmat.direction = Vector3(0, 1, 0)
	th_pmat.spread = 180.0
	th_pmat.initial_velocity_min = 2.0
	th_pmat.initial_velocity_max = 5.0
	th_pmat.scale_min = 0.25
	th_pmat.scale_max = 0.55
	thunder.process_material = th_pmat

	var th_mat := _create_additive_particle_mat(_get_tex("spark_06.png"), Color(0.7, 0.5, 1.0, 1.0))
	var th_mesh := get_safe_particle_quad_mesh(Vector2(0.5, 0.5))
	th_mesh.surface_set_material(0, th_mat)
	thunder.draw_pass_1 = th_mesh

	parent.add_child(thunder)
	thunder.global_position = pos + Vector3(0.0, 1.0, 0.0)
	thunder.emitting = true

	# Tắt sét sau 2.5s
	var tw_thunder := thunder.create_tween()
	tw_thunder.tween_interval(2.2)
	tw_thunder.tween_callback(func():
		thunder.emitting = false
	)
	tw_thunder.tween_interval(0.4)
	tw_thunder.tween_callback(thunder.queue_free)

## Chiêu 5: Vết Chém Chữ Thập X-Slash Khi Trúng Đòn (Task 20.4 Hit Impact)
static func spawn_cross_slash_hit_impact(
	world_pos: Vector3,
	parent_node: Node = null
) -> void:
	var p := _get_root_parent(parent_node)
	if p == null:
		return

	var impact_root := Node3D.new()
	impact_root.name = "CrossSlashHitImpact"
	p.add_child(impact_root)
	impact_root.global_position = world_pos

	# Tia chém 1: slash_04.png chéo +42 độ
	var slash1 := Sprite3D.new()
	slash1.name = "SlashCross1"
	slash1.texture = _get_tex("slash_04.png")
	slash1.modulate = Color(1.8, 1.4, 0.8, 1.0)
	slash1.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	slash1.no_depth_test = true
	slash1.pixel_size = 0.003
	slash1.rotation.z = deg_to_rad(42.0)
	slash1.scale = Vector3(0.2, 0.2, 0.2)
	impact_root.add_child(slash1)

	# Tia chém 2: slash_04.png chéo -42 độ
	var slash2 := Sprite3D.new()
	slash2.name = "SlashCross2"
	slash2.texture = _get_tex("slash_04.png")
	slash2.modulate = Color(1.8, 1.0, 0.4, 1.0)
	slash2.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	slash2.no_depth_test = true
	slash2.pixel_size = 0.003
	slash2.rotation.z = deg_to_rad(-42.0)
	slash2.scale = Vector3(0.2, 0.2, 0.2)
	impact_root.add_child(slash2)

	# Ngôi sao chớp sáng tâm star_08.png
	var star := Sprite3D.new()
	star.name = "HitStarFlash"
	star.texture = _get_tex("star_08.png")
	star.modulate = Color(2.0, 2.0, 1.6, 1.0)
	star.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	star.no_depth_test = true
	star.pixel_size = 0.0025
	star.scale = Vector3(0.3, 0.3, 0.3)
	impact_root.add_child(star)

	var tw := impact_root.create_tween().set_parallel(true)
	tw.tween_property(slash1, "scale", Vector3(1.2, 1.2, 1.2), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(slash2, "scale", Vector3(1.2, 1.2, 1.2), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(star, "scale", Vector3(1.5, 1.5, 1.5), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(slash1, "modulate:a", 0.0, 0.12)
	tw.parallel().tween_property(slash2, "modulate:a", 0.0, 0.12)
	tw.parallel().tween_property(star, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(impact_root.queue_free)

	# 18 hạt tia lửa spark_01 văng tung tóe
	var sparks := GPUParticles3D.new()
	sparks.name = "HitSparks"
	sparks.amount = 18
	sparks.lifetime = 0.28
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	sparks.local_coords = false

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 3.5
	pmat.initial_velocity_max = 7.5
	pmat.gravity = Vector3(0, -6.0, 0)
	pmat.scale_min = 0.2
	pmat.scale_max = 0.45
	sparks.process_material = pmat

	var draw_mat := _create_additive_particle_mat(_get_tex("spark_01.png"), Color(1.0, 0.85, 0.3, 1.0))
	var qmesh := get_safe_particle_quad_mesh(Vector2(0.4, 0.4))
	qmesh.surface_set_material(0, draw_mat)
	sparks.draw_pass_1 = qmesh

	p.add_child(sparks)
	sparks.global_position = world_pos
	sparks.emitting = true
	sparks.finished.connect(sparks.queue_free)

## Tương thích ngược: Nổ trúng đòn tại ngực mục tiêu
static func spawn_hit_impact_at_chest(target_node: Node3D) -> void:
	if not is_instance_valid(target_node):
		return
	var hit_pos: Vector3 = target_node.global_position + Vector3(0.0, 0.95, 0.0)
	spawn_cross_slash_hit_impact(hit_pos, target_node)

## Chiêu 6: Hiệu Ứng Lướt Space (Gió lướt sát sàn)
static func spawn_dash_trail(
	hero_node: Node3D,
	dash_dir: Vector3,
	parent_node: Node = null
) -> void:
	var p := _get_root_parent(parent_node)
	if p == null or not is_instance_valid(hero_node):
		return

	var dash_sprite := Sprite3D.new()
	dash_sprite.name = "DashWindStreak"
	dash_sprite.texture = _get_tex("slash_02.png")
	dash_sprite.modulate = Color(0.3, 0.8, 1.0, 0.8)
	dash_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	dash_sprite.rotation.x = deg_to_rad(90.0)
	dash_sprite.rotation.y = atan2(dash_dir.x, dash_dir.z)
	dash_sprite.pixel_size = 0.006
	dash_sprite.scale = Vector3(0.5, 0.5, 0.5)
	p.add_child(dash_sprite)
	dash_sprite.global_position = hero_node.global_position + Vector3(0.0, 0.2, 0.0)

	var tw := dash_sprite.create_tween().set_parallel(true)
	tw.tween_property(dash_sprite, "scale", Vector3(1.8, 1.8, 1.8), 0.28)
	tw.tween_property(dash_sprite, "modulate:a", 0.0, 0.28)
	tw.chain().tween_callback(dash_sprite.queue_free)

## Chiêu 6 (Phần 2): Sóng Xung Kích Khi Lướt Húc Văng Bot (Task 20.4 Chiêu Space)
static func spawn_dash_impact(
	impact_pos: Vector3,
	impact_dir: Vector3,
	parent_node: Node = null
) -> void:
	var p := _get_root_parent(parent_node)
	if p == null:
		return

	# Vòng Sóng Va Chạm Dựng Đứng (circle_03.png phóng to 0.3m -> 2.6m)
	var shock_sprite := Sprite3D.new()
	shock_sprite.name = "DashImpactShockwave"
	shock_sprite.texture = _get_tex("circle_03.png")
	shock_sprite.modulate = Color(1.3, 0.95, 0.4, 1.0)
	shock_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shock_sprite.no_depth_test = true
	shock_sprite.pixel_size = 0.0035
	shock_sprite.scale = Vector3(0.3, 0.3, 0.3)
	p.add_child(shock_sprite)
	shock_sprite.global_position = impact_pos

	var tw := shock_sprite.create_tween().set_parallel(true)
	tw.tween_property(shock_sprite, "scale", Vector3(2.6, 2.6, 2.6), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(shock_sprite, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(shock_sprite.queue_free)

	# Hạt tia lửa va chạm spark_05
	var sparks := GPUParticles3D.new()
	sparks.name = "DashImpactSparks"
	sparks.amount = 16
	sparks.lifetime = 0.24
	sparks.one_shot = true
	sparks.explosiveness = 0.92
	sparks.local_coords = false

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = impact_dir
	pmat.spread = 75.0
	pmat.initial_velocity_min = 4.0
	pmat.initial_velocity_max = 8.5
	pmat.gravity = Vector3(0, -5.0, 0)
	pmat.scale_min = 0.25
	pmat.scale_max = 0.5
	sparks.process_material = pmat

	var draw_mat := _create_additive_particle_mat(_get_tex("spark_05.png"), Color(1.0, 0.8, 0.3, 1.0))
	var qmesh := get_safe_particle_quad_mesh(Vector2(0.4, 0.4))
	qmesh.surface_set_material(0, draw_mat)
	sparks.draw_pass_1 = qmesh

	p.add_child(sparks)
	sparks.global_position = impact_pos
	sparks.emitting = true
	sparks.finished.connect(sparks.queue_free)

# ==============================================================================
# 3. TIỆN ÍCH DÀNH CHO VŨ KHÍ & VỆT KIẾM (Compatibility Utilities)
# ==============================================================================

## Gắn vệt kiếm GPUParticles3D bằng ArrayMesh an toàn (0% PrimitiveMesh)
static func attach_sword_trail_particles(
	blade_center: Marker3D,
	blade_tip: Marker3D
) -> Array[GPUParticles3D]:
	# Center trail (Vệt kiếm vàng kim)
	var center_p := GPUParticles3D.new()
	center_p.name = "SwordTrailCenter"
	center_p.emitting = false
	center_p.local_coords = false
	center_p.amount = 32
	center_p.lifetime = 0.16

	var qm1 := get_safe_particle_quad_mesh(Vector2(0.08, 0.08))
	var mat1 := _create_additive_particle_mat(_get_tex("slash_01.png"), Color(1.0, 0.85, 0.3, 1.0))
	qm1.surface_set_material(0, mat1)
	center_p.draw_pass_1 = qm1

	center_p.process_material = _create_particle_process_mat(
		Vector3(0, 1, 0), 25.0, 0.3, 1.2, Vector3.ZERO, 0.04, 0.1
	)
	blade_center.add_child(center_p)

	# Tip trail (Tia lửa cam sáng)
	var tip_p := GPUParticles3D.new()
	tip_p.name = "SwordTrailTip"
	tip_p.emitting = false
	tip_p.local_coords = false
	tip_p.amount = 32
	tip_p.lifetime = 0.16

	var qm2 := get_safe_particle_quad_mesh(Vector2(0.06, 0.06))
	var mat2 := _create_additive_particle_mat(_get_tex("spark_02.png"), Color(1.0, 0.6, 0.15, 1.0))
	qm2.surface_set_material(0, mat2)
	tip_p.draw_pass_1 = qm2

	tip_p.process_material = _create_particle_process_mat(
		Vector3(0, 1, 0), 35.0, 0.5, 1.8, Vector3.ZERO, 0.03, 0.08
	)
	blade_tip.add_child(tip_p)

	var result: Array[GPUParticles3D] = [center_p, tip_p]
	return result

static func enable_sword_trails(trails: Array[GPUParticles3D]) -> void:
	for p in trails:
		if is_instance_valid(p):
			p.emitting = true

static func disable_sword_trails(trails: Array[GPUParticles3D]) -> void:
	for p in trails:
		if is_instance_valid(p):
			p.emitting = false

static func spawn_ground_decal_shockwave(
	parent: Node,
	ground_pos: Vector3,
	radius: float,
	color: Color
) -> void:
	var p := _get_root_parent(parent)
	if p == null:
		return

	var decal := Decal.new()
	decal.name = "GroundShockwave"
	var initial_size := radius * 0.6
	decal.size = Vector3(initial_size * 2.0, 3.5, initial_size * 2.0)
	decal.texture_albedo = _get_tex("circle_01.png")
	decal.modulate = color
	p.add_child(decal)
	decal.global_position = ground_pos + Vector3(0.0, 0.15, 0.0)

	var tween := decal.create_tween()
	var final_size := Vector3(radius * 2.0, 3.5, radius * 2.0)
	tween.tween_property(decal, "size", final_size, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(decal, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(decal.queue_free)

static func spawn_kaykit_3d_projectile(
	parent: Node,
	start_pos: Vector3,
	target_pos: Vector3,
	projectile_type: String = "smokebomb"
) -> void:
	if projectile_type == "smokebomb":
		spawn_smoke_bomb_3d(parent, start_pos, target_pos)
		return

	var p := _get_root_parent(parent)
	if p == null:
		return

	var model_path := "res://assets/weapons/arrow.gltf"
	var scene: PackedScene = null
	if ResourceLoader.exists(model_path):
		scene = load(model_path) as PackedScene
	if scene == null:
		return

	var proj: Node3D = scene.instantiate() as Node3D
	p.add_child(proj)
	proj.global_position = start_pos
	var dir_to_target := (target_pos - start_pos).normalized()
	if dir_to_target.length_squared() > 0.001:
		proj.look_at(target_pos, Vector3.UP)

	var tween := proj.create_tween()
	tween.tween_property(proj, "global_position", target_pos, 0.35).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(proj.queue_free)
