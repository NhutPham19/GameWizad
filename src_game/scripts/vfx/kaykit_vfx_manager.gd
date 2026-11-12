class_name KayKitVFXManager
extends Node3D

const KayKitAudioDirector = preload("res://scripts/audio/kaykit_audio_director.gd")

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
static var _cached_prismatic_ramp: GradientTexture1D = null
static var _cached_rage_red_blue_ramp: GradientTexture1D = null

static func _get_root_parent(parent_node: Node = null) -> Node:
	if is_instance_valid(parent_node):
		return parent_node
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		if tree.current_scene != null:
			return tree.current_scene
		return tree.root
	return null

static func _load_cached_tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var resolved_path := path
	if not ResourceLoader.exists(resolved_path):
		var base_name := path.get_file()
		var alt_path := "res://assets/vfx_textures/" + base_name
		if ResourceLoader.exists(alt_path):
			resolved_path = alt_path
	if ResourceLoader.exists(resolved_path):
		var t := load(resolved_path) as Texture2D
		_tex_cache[path] = t
		return t
	return null

static func _get_tex(file_name: String) -> Texture2D:
	return _load_cached_tex(file_name)

static func _get_slash_shader() -> Shader:
	if _cached_slash_shader == null and ResourceLoader.exists(SLASH_SHADER_PATH):
		_cached_slash_shader = load(SLASH_SHADER_PATH) as Shader
	return _cached_slash_shader

static func _get_stylized_slash_shader() -> Shader:
	return _get_slash_shader()

static func _snap_vfx_to_ground(tree: SceneTree, pos: Vector3) -> Vector3:
	if tree == null or tree.root == null or tree.root.get_world_3d() == null:
		return pos
	var space := tree.root.get_world_3d().direct_space_state
	if space == null:
		return pos
	var query := PhysicsRayQueryParameters3D.create(
		pos + Vector3(0.0, 2.8, 0.0),
		pos - Vector3(0.0, 3.8, 0.0),
		1
	)
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		return hit["position"] + Vector3(0.0, 0.03, 0.0)
	return pos

static func _get_prismatic_color_ramp() -> GradientTexture1D:
	if _cached_prismatic_ramp != null:
		return _cached_prismatic_ramp
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.18, 0.45, 0.75, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),    # Trắng Kim Cương
		Color(1.0, 0.90, 0.15, 1.0),  # Vàng Hoàng Kim
		Color(1.0, 0.25, 0.55, 0.95), # Hồng Cực Quang
		Color(0.55, 0.15, 1.0, 0.75), # Tím Tinh Vân
		Color(0.0, 0.85, 1.0, 0.0)    # Lam Điện Quang tan biến
	])
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	tex.width = 128
	_cached_prismatic_ramp = tex
	return _cached_prismatic_ramp

## Bảng màu Hạt Nộ Đỏ Huyết & Xanh Dương Điện Quang (Directive 26 Task 26.4)
static func _get_rage_crimson_cobalt_ramp() -> GradientTexture1D:
	if _cached_rage_red_blue_ramp != null:
		return _cached_rage_red_blue_ramp
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.22, 0.52, 0.82, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 0.96, 0.92, 1.0),  # Trắng Nóng
		Color(1.0, 0.06, 0.14, 1.0),  # Đỏ Huyết Ngục (#FF0F24)
		Color(0.85, 0.0, 0.18, 0.95), # Đỏ Thẫm
		Color(0.0, 0.45, 1.0, 0.90),  # Xanh Dương Điện Quang (#0073FF)
		Color(0.0, 0.85, 1.0, 0.0)    # Lam Băng tan biến
	])
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	tex.width = 128
	_cached_rage_red_blue_ramp = tex
	return _cached_rage_red_blue_ramp

## Diễn hoạt "Đọng Lại, Kéo Dài & Phình To Uy Lực" (Directive 26 Task 26.4 Lớp Dùng Chung)
static func _animate_lingering_power_slash(
	pivot: Node3D,
	mesh_inst: MeshInstance3D,
	smat: ShaderMaterial,
	start_yaw_deg: float,
	end_yaw_deg: float,
	total_duration: float,
	expand_scale: float = 1.25,
	forward_push: Vector3 = Vector3.ZERO
) -> void:
	var strike_time := total_duration * 0.24
	var linger_time := total_duration * 0.46
	var decay_time := total_duration * 0.30

	mesh_inst.rotation.y = deg_to_rad(start_yaw_deg)
	pivot.scale = Vector3.ONE * 0.92
	var start_pos := pivot.global_position

	var tw := pivot.create_tween()
	# Pha 1 (24% thời gian): Quét kiếm cực nhanh tới góc đích + bung kích thước chuẩn 1.06x
	tw.set_parallel(true)
	tw.tween_property(mesh_inst, "rotation:y", deg_to_rad(end_yaw_deg * 0.88), strike_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(pivot, "scale", Vector3.ONE * 1.06, strike_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float):
		if is_instance_valid(smat):
			smat.set_shader_parameter("slash_progress", v)
	, 0.0, 0.14, strike_time)

	# Pha 2 (46% thời gian - ĐỌNG LẠI & TO RA): Lưỡi kiếm ghim lại trong không trung, phình to lên expand_scale và nhích nhẹ về trước
	tw.chain().set_parallel(true)
	tw.tween_property(mesh_inst, "rotation:y", deg_to_rad(end_yaw_deg), linger_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(pivot, "scale", Vector3(expand_scale, expand_scale * 1.08, expand_scale), linger_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if forward_push.length_squared() > 0.001:
		tw.tween_property(pivot, "global_position", start_pos + forward_push, linger_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float):
		if is_instance_valid(smat):
			smat.set_shader_parameter("slash_progress", v)
	, 0.14, 0.36, linger_time)

	# Pha 3 (30% thời gian): Tan biến thành tàn lửa và tia điện
	tw.chain().set_parallel(true)
	tw.tween_property(pivot, "scale", Vector3(expand_scale * 1.08, expand_scale * 0.85, expand_scale * 1.08), decay_time)
	tw.tween_method(func(v: float):
		if is_instance_valid(smat):
			smat.set_shader_parameter("slash_progress", v)
	, 0.36, 1.0, decay_time)
	tw.chain().tween_callback(pivot.queue_free)

# ==============================================================================
# 0. LÕI HÌNH HỌC AN TOÀN (ZERO PRIMITIVE MESHES)
# ==============================================================================

## Tạo lưới phẳng 2 tam giác bằng ArrayMesh (mesh is PrimitiveMesh == FALSE 100%)
static func get_safe_particle_quad_mesh(size_val = Vector2(1.0, 1.0)) -> ArrayMesh:
	var size: Vector2 = size_val if (size_val is Vector2) else Vector2(float(size_val), float(size_val))
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
	st.generate_normals()
	return st.commit()

## Tạo Dải Lưới Cung Trăng Uốn Cong 3D bằng ArrayMesh (Procedural Curved Crescent Slash Arc ArrayMesh)
static func build_curved_slash_arc_mesh(
	inner_or_radius: float = 0.85,
	outer_or_width: float = 2.55,
	arc_angle_deg: float = 155.0,
	segments: int = 36,
	vertical_arch: float = 0.12
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var total_rad := deg_to_rad(arc_angle_deg)
	var start_rad := -total_rad * 0.5

	var in_radius: float
	var out_radius: float
	if inner_or_radius > outer_or_width:
		out_radius = inner_or_radius
		in_radius = maxf(0.05, inner_or_radius - outer_or_width)
	else:
		in_radius = inner_or_radius
		out_radius = outer_or_width

	for i in range(segments):
		var t0 := float(i) / float(segments)
		var t1 := float(i + 1) / float(segments)
		var a0 := start_rad + t0 * total_rad
		var a1 := start_rad + t1 * total_rad

		# Độ mở rộng hình lưỡi liềm: Thuôn nhọn ở 2 đầu (0.0 và 1.0), phình to sắc lẹm ở giữa cung
		var width_scale0 := sin(t0 * PI)
		var width_scale1 := sin(t1 * PI)
		var cur_in0 := lerpf(out_radius * 0.92, in_radius, width_scale0)
		var cur_in1 := lerpf(out_radius * 0.92, in_radius, width_scale1)

		var y_arch0 := sin(t0 * PI) * vertical_arch
		var y_arch1 := sin(t1 * PI) * vertical_arch

		var p0_in := Vector3(sin(a0) * cur_in0, y_arch0, cos(a0) * cur_in0)
		var p0_out := Vector3(sin(a0) * out_radius, y_arch0 * 0.5, cos(a0) * out_radius)
		var p1_in := Vector3(sin(a1) * cur_in1, y_arch1, cos(a1) * cur_in1)
		var p1_out := Vector3(sin(a1) * out_radius, y_arch1 * 0.5, cos(a1) * out_radius)

		# Tam giác 1
		st.set_uv(Vector2(t0, 0.0)); st.add_vertex(p0_in)
		st.set_uv(Vector2(t0, 1.0)); st.add_vertex(p0_out)
		st.set_uv(Vector2(t1, 1.0)); st.add_vertex(p1_out)
		# Tam giác 2
		st.set_uv(Vector2(t0, 0.0)); st.add_vertex(p0_in)
		st.set_uv(Vector2(t1, 1.0)); st.add_vertex(p1_out)
		st.set_uv(Vector2(t1, 0.0)); st.add_vertex(p1_in)

	st.generate_normals()
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

## Vòng Lụa Kiếm Khí Xoáy Ngang Mặt Đất (Directive 25 Task 25.2)
static func _spawn_prismatic_cyclone_ring_ribbon(
	tree: SceneTree,
	center_pos: Vector3,
	start_radius: float,
	end_radius: float,
	ribbon_width: float,
	core_col: Color,
	mid_col: Color,
	edge_col: Color,
	accent_col: Color,
	spin_speed_rad: float = 10.0,
	duration: float = 0.36,
	custom_name: String = "PrismaticCycloneRibbon3D"
) -> void:
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	var scene_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if scene_parent == null:
		return
	var ring_inst := MeshInstance3D.new()
	ring_inst.name = custom_name
	ring_inst.mesh = build_curved_slash_arc_mesh(1.0, ribbon_width, 330.0, 36)
	ring_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := ShaderMaterial.new()
	mat.shader = _get_stylized_slash_shader()
	mat.set_shader_parameter("core_color", core_col)
	mat.set_shader_parameter("mid_color", mid_col)
	mat.set_shader_parameter("edge_color", edge_col)
	mat.set_shader_parameter("accent_color", accent_col)
	mat.set_shader_parameter("emission_strength", 7.8)
	mat.set_shader_parameter("chromatic_shift", 0.75)
	mat.set_shader_parameter("slash_progress", 0.0)
	ring_inst.material_override = mat

	scene_parent.add_child(ring_inst)
	ring_inst.global_position = center_pos + Vector3(0.0, 0.14, 0.0)
	ring_inst.scale = Vector3(start_radius, 1.0, start_radius)

	var tw := ring_inst.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring_inst, "scale", Vector3(end_radius, 1.0, end_radius), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring_inst, "rotation:y", ring_inst.rotation.y + spin_speed_rad * duration, duration)
	tw.tween_method(func(val: float):
		if is_instance_valid(mat):
			mat.set_shader_parameter("slash_progress", val)
	, 0.0, 1.0, duration)
	tw.chain().tween_callback(ring_inst.queue_free)

## Hoa Đăng Tinh Tú Kenney 2D/3D Giao Thoa (Directive 25 Task 25.2)
static func _spawn_kenney_star_flare_burst(
	tree: SceneTree,
	pos: Vector3,
	flare_scale: float = 2.4,
	color_a: Color = Color(1.0, 0.92, 0.35, 1.0),
	color_b: Color = Color(1.0, 0.25, 0.85, 1.0),
	duration: float = 0.26
) -> void:
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	var scene_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if scene_parent == null:
		return
	var holder := Node3D.new()
	holder.name = "KenneyStarFlareBurst"
	scene_parent.add_child(holder)
	holder.global_position = pos

	var tex_paths := [
		"res://assets/vfx_textures/kenney_particles/star_07.png",
		"res://assets/vfx_textures/kenney_particles/light_01.png"
	]
	for i in range(2):
		var quad := MeshInstance3D.new()
		quad.mesh = get_safe_particle_quad_mesh(1.0)
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var smat := StandardMaterial3D.new()
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		smat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var tex := _load_cached_tex(tex_paths[i])
		if tex:
			smat.albedo_texture = tex
		smat.albedo_color = color_a if i == 0 else color_b
		smat.emission_enabled = true
		smat.emission = (color_a if i == 0 else color_b)
		smat.emission_energy_multiplier = 5.5
		quad.material_override = smat
		holder.add_child(quad)

	holder.scale = Vector3.ONE * 0.2
	var tw := holder.create_tween()
	tw.set_parallel(true)
	tw.tween_property(holder, "scale", Vector3.ONE * flare_scale, duration * 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(holder, "scale", Vector3.ONE * 0.05, duration * 0.55).set_delay(duration * 0.45)
	tw.chain().tween_callback(holder.queue_free)

## Bóng Mờ Nhân Bản Từ Mô Hình .glb Thật (Directive 25 Task 25.2)
static func spawn_prismatic_hero_afterimage(tree: SceneTree, visual_root: Node3D, tint_color: Color, duration: float = 0.28) -> void:
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	var scene_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if scene_parent == null or visual_root == null or not is_instance_valid(visual_root):
		return
	var ghost_root := Node3D.new()
	ghost_root.name = "PrismaticHeroAfterimage"
	scene_parent.add_child(ghost_root)
	ghost_root.global_transform = visual_root.global_transform

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(tint_color.r, tint_color.g, tint_color.b, 0.52)
	mat.emission_enabled = true
	mat.emission = tint_color
	mat.emission_energy_multiplier = 3.8

	var mesh_nodes: Array[MeshInstance3D] = []
	_collect_real_glb_meshes(visual_root, mesh_nodes)
	for m in mesh_nodes:
		if m.mesh == null or m.mesh is PrimitiveMesh:
			continue
		var clone := MeshInstance3D.new()
		clone.mesh = m.mesh
		if m.skin != null:
			clone.skin = m.skin
		clone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		clone.material_override = mat
		ghost_root.add_child(clone)
		clone.global_transform = m.global_transform

	var tw := ghost_root.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, duration)
	tw.tween_callback(ghost_root.queue_free)

static func _collect_real_glb_meshes(node: Node, out_list: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.visible:
		out_list.append(node)
	for child in node.get_children():
		_collect_real_glb_meshes(child, out_list)

## Kích hoạt Trạng Thái 2: Vụ nổ Lốc Xoáy Kép Đỏ - Xanh Dương thức tỉnh Nộ (Task 26.2 & 26.4)
static func spawn_rage_awakening_burst(tree: SceneTree, origin: Vector3) -> void:
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	var scene_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if scene_parent == null:
		return
	var ground_pos := _snap_vfx_to_ground(tree, origin)

	# 2 vòng lụa xoáy ngược chiều sát mặt đất: Vòng trong R=2.6m Đỏ Huyết, Vòng ngoài R=3.5m Xanh Dương
	_spawn_prismatic_cyclone_ring_ribbon(
		tree, ground_pos + Vector3(0.0, 0.04, 0.0), 0.6, 2.6, 0.65,
		Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 0.06, 0.14, 1.0), Color(0.85, 0.0, 0.18, 1.0), Color(1.0, 0.4, 0.0, 1.0),
		16.0, 0.55, "RageAwakeningRingInner"
	)
	_spawn_prismatic_cyclone_ring_ribbon(
		tree, ground_pos + Vector3(0.0, 0.06, 0.0), 1.2, 3.5, 0.72,
		Color(1.0, 1.0, 1.0, 1.0), Color(0.0, 0.45, 1.0, 1.0), Color(0.0, 0.15, 0.85, 1.0), Color(0.0, 0.9, 1.0, 1.0),
		-15.0, 0.55, "RageAwakeningRingOuter"
	)

	# 2 Cột lụa xoắn ốc (1 Đỏ, 1 Xanh Dương) vọt cao 3.8m
	for h_idx in range(2):
		var pillar_pivot := Node3D.new()
		pillar_pivot.name = "RageAwakeningPillar_%s" % ("Red" if h_idx == 0 else "Blue")
		scene_parent.add_child(pillar_pivot)
		pillar_pivot.global_position = ground_pos + Vector3(0.0, 0.25 + h_idx * 0.45, 0.0)
		pillar_pivot.rotation.z = deg_to_rad(22.0 if h_idx == 0 else -22.0)

		var p_mesh := MeshInstance3D.new()
		p_mesh.mesh = build_curved_slash_arc_mesh(1.15, 0.72, 260.0, 36)
		p_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var p_mat := ShaderMaterial.new()
		p_mat.shader = _get_stylized_slash_shader()
		p_mat.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
		p_mat.set_shader_parameter("mid_color", Color(1.0, 0.06, 0.14, 1.0) if h_idx == 0 else Color(0.0, 0.45, 1.0, 1.0))
		p_mat.set_shader_parameter("edge_color", Color(0.85, 0.0, 0.18, 1.0) if h_idx == 0 else Color(0.0, 0.15, 0.85, 1.0))
		p_mat.set_shader_parameter("accent_color", Color(1.0, 0.4, 0.0, 1.0) if h_idx == 0 else Color(0.0, 0.9, 1.0, 1.0))
		p_mat.set_shader_parameter("emission_strength", 8.5)
		p_mat.set_shader_parameter("core_sharpness", 2.2)
		p_mesh.material_override = p_mat
		pillar_pivot.add_child(p_mesh)

		var p_tw := pillar_pivot.create_tween()
		p_tw.set_parallel(true)
		p_tw.tween_property(pillar_pivot, "global_position:y", ground_pos.y + 3.8, 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		p_tw.tween_property(pillar_pivot, "rotation:y", (1.0 if h_idx == 0 else -1.0) * TAU * 1.5, 0.52)
		p_tw.tween_property(pillar_pivot, "scale", Vector3(1.9, 1.6, 1.9), 0.52)
		p_tw.tween_method(func(val: float):
			if is_instance_valid(p_mat):
				p_mat.set_shader_parameter("slash_progress", val)
		, 0.0, 1.0, 0.52)
		p_tw.chain().tween_callback(pillar_pivot.queue_free)

	# Hoa đăng Kenney Đỏ - Xanh
	_spawn_kenney_star_flare_burst(
		tree, ground_pos + Vector3(0.0, 1.2, 0.0), 3.8,
		Color(1.0, 0.15, 0.25, 1.0), Color(0.1, 0.5, 1.0, 1.0), 0.45
	)

	# Xung ánh sáng OmniLight3D
	var light := OmniLight3D.new()
	light.name = "RageAwakeningLight"
	light.shadow_enabled = false
	light.omni_range = 6.5
	light.light_color = Color(1.0, 0.25, 0.45)
	light.light_energy = 6.0
	scene_parent.add_child(light)
	light.global_position = ground_pos + Vector3(0.0, 1.2, 0.0)
	var ltw := light.create_tween()
	ltw.tween_property(light, "light_energy", 0.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ltw.tween_callback(light.queue_free)

class RageAuraAnimator extends Node:
	var wings_l: Array[Node] = []
	var wings_r: Array[Node] = []
	var gyro1: Node3D = null
	var gyro2: Node3D = null
	var gyro3: Node3D = null
	var d1: Decal = null
	var d2: Decal = null
	var d3: Decal = null
	var aura_light: OmniLight3D = null
	var flare: Node3D = null
	var _time: float = 0.0

	func _process(delta: float) -> void:
		_time += delta
		var flap: float = sin(_time * 7.5) * 0.18
		for w in wings_l:
			if is_instance_valid(w):
				var base_r: float = float((w as Node3D).get_meta("base_roll", 0.0))
				(w as Node3D).rotation.z = base_r + flap
		for w in wings_r:
			if is_instance_valid(w):
				var base_r: float = float((w as Node3D).get_meta("base_roll", 0.0))
				(w as Node3D).rotation.z = base_r - flap

		if is_instance_valid(gyro1):
			gyro1.rotate_object_local(Vector3.UP, 4.8 * delta)
		if is_instance_valid(gyro2):
			gyro2.rotate_object_local(Vector3.UP, -5.2 * delta)
		if is_instance_valid(gyro3):
			gyro3.rotate_object_local(Vector3.UP, 6.5 * delta)

		if is_instance_valid(d1):
			d1.rotate_y(-1.8 * delta)
		if is_instance_valid(d2):
			d2.rotate_y(2.6 * delta)
		if is_instance_valid(d3):
			var s: float = 1.9 * (1.0 + 0.14 * sin(_time * 9.0))
			d3.size = Vector3(s, 2.5, s)
			d3.rotate_y(1.2 * delta)

		if is_instance_valid(aura_light):
			var blend_t: float = sin(_time * 6.0) * 0.5 + 0.5
			aura_light.light_color = Color(1.0, 0.15, 0.25).lerp(Color(0.1, 0.55, 1.0), blend_t)

		if is_instance_valid(flare):
			flare.rotate_z(5.0 * delta)

## Gắn Hào Quang Nộ "Linh Giáp Cực Quang Huyết Lam 6 Lớp" (Directive 27 Task 27.1)
## 100% Zero PrimitiveMesh (ArrayMesh & Safe Quad Mesh)
## Trả về Node3D mang tên "RageState2AuraHolder" gắn làm con của hero_node
static func attach_persistent_rage_aura(hero_node: Node3D, _visual_root: Node3D = null) -> Node3D:
	if not is_instance_valid(hero_node):
		return null

	var aura_holder := Node3D.new()
	aura_holder.name = "RageState2AuraHolder"
	hero_node.add_child(aura_holder)
	aura_holder.position = Vector3.ZERO

	# -------------------------------------------------------------------------
	# LỚP 1: ĐÔI CÁNH KIẾM KHÍ HUYẾT LAM SAU VAI (WingsPivot - 4 dải lụa cong)
	# -------------------------------------------------------------------------
	var wings_pivot := Node3D.new()
	wings_pivot.name = "WingsPivot"
	wings_pivot.position = Vector3(0.0, 1.15, -0.25)
	aura_holder.add_child(wings_pivot)

	var wing_configs := [
		{"name": "WingUpperLeft", "is_left": true, "yaw": 25.0, "roll": 35.0, "pitch": 15.0,
		 "mid": Color(1.0, 0.03, 0.14), "edge": Color(1.0, 0.72, 0.0), "accent": Color(1.0, 0.0, 0.33), "energy": 6.2},
		{"name": "WingUpperRight", "is_left": false, "yaw": -25.0, "roll": -35.0, "pitch": 15.0,
		 "mid": Color(1.0, 0.03, 0.14), "edge": Color(1.0, 0.72, 0.0), "accent": Color(1.0, 0.0, 0.33), "energy": 6.2},
		{"name": "WingLowerLeft", "is_left": true, "yaw": 15.0, "roll": 65.0, "pitch": -10.0,
		 "mid": Color(0.0, 0.40, 1.0), "edge": Color(0.0, 0.94, 1.0), "accent": Color(0.47, 0.0, 1.0), "energy": 6.0},
		{"name": "WingLowerRight", "is_left": false, "yaw": -15.0, "roll": -65.0, "pitch": -10.0,
		 "mid": Color(0.0, 0.40, 1.0), "edge": Color(0.0, 0.94, 1.0), "accent": Color(0.47, 0.0, 1.0), "energy": 6.0}
	]

	var wings_left: Array[Node] = []
	var wings_right: Array[Node] = []

	for wcfg in wing_configs:
		var wing_mesh := MeshInstance3D.new()
		wing_mesh.name = String(wcfg["name"])
		wing_mesh.mesh = build_curved_slash_arc_mesh(0.95, 0.42, 85.0, 36)
		wing_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var wsmat := ShaderMaterial.new()
		wsmat.shader = _get_stylized_slash_shader()
		wsmat.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
		wsmat.set_shader_parameter("mid_color", wcfg["mid"])
		wsmat.set_shader_parameter("edge_color", wcfg["edge"])
		wsmat.set_shader_parameter("accent_color", wcfg["accent"])
		wsmat.set_shader_parameter("emission_strength", float(wcfg["energy"]))
		wsmat.set_shader_parameter("core_sharpness", 2.2)
		wsmat.set_shader_parameter("slash_progress", 0.05)
		wing_mesh.material_override = wsmat

		wing_mesh.rotation = Vector3(
			deg_to_rad(float(wcfg["pitch"])),
			deg_to_rad(float(wcfg["yaw"])),
			deg_to_rad(float(wcfg["roll"]))
		)
		wing_mesh.set_meta("base_roll", deg_to_rad(float(wcfg["roll"])))
		wings_pivot.add_child(wing_mesh)
		if bool(wcfg["is_left"]):
			wings_left.append(wing_mesh)
		else:
			wings_right.append(wing_mesh)

	# -------------------------------------------------------------------------
	# LỚP 2: TAM VÒNG TINH HOÀN 3D XOAY CHÉO (GyroRings)
	# -------------------------------------------------------------------------
	var gyro_pivot := Node3D.new()
	gyro_pivot.name = "GyroRings"
	gyro_pivot.position = Vector3(0.0, 0.85, 0.0)
	aura_holder.add_child(gyro_pivot)

	# Tinh Hoàn 1 (Nghiêng X +32°, Z -18°): Đỏ Huyết -> Cam Vàng
	var g1 := MeshInstance3D.new()
	g1.name = "GyroRing1"
	g1.mesh = build_curved_slash_arc_mesh(1.15, 0.28, 310.0, 36)
	g1.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var smat_g1 := ShaderMaterial.new()
	smat_g1.shader = _get_stylized_slash_shader()
	smat_g1.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
	smat_g1.set_shader_parameter("mid_color", Color(1.0, 0.04, 0.14, 1.0))
	smat_g1.set_shader_parameter("edge_color", Color(1.0, 0.53, 0.0, 1.0))
	smat_g1.set_shader_parameter("accent_color", Color(1.0, 0.0, 0.35, 1.0))
	smat_g1.set_shader_parameter("emission_strength", 6.0)
	smat_g1.set_shader_parameter("core_sharpness", 2.2)
	smat_g1.set_shader_parameter("slash_progress", 0.08)
	g1.material_override = smat_g1
	g1.rotation = Vector3(deg_to_rad(32.0), 0.0, deg_to_rad(-18.0))
	gyro_pivot.add_child(g1)

	# Tinh Hoàn 2 (Nghiêng X -32°, Z +18°): Xanh Dương -> Xanh Ngọc
	var g2 := MeshInstance3D.new()
	g2.name = "GyroRing2"
	g2.mesh = build_curved_slash_arc_mesh(1.15, 0.28, 310.0, 36)
	g2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var smat_g2 := ShaderMaterial.new()
	smat_g2.shader = _get_stylized_slash_shader()
	smat_g2.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
	smat_g2.set_shader_parameter("mid_color", Color(0.0, 0.40, 1.0, 1.0))
	smat_g2.set_shader_parameter("edge_color", Color(0.0, 0.95, 0.90, 1.0))
	smat_g2.set_shader_parameter("accent_color", Color(0.0, 0.15, 0.70, 1.0))
	smat_g2.set_shader_parameter("emission_strength", 6.0)
	smat_g2.set_shader_parameter("core_sharpness", 2.2)
	smat_g2.set_shader_parameter("slash_progress", 0.08)
	g2.material_override = smat_g2
	g2.rotation = Vector3(deg_to_rad(-32.0), 0.0, deg_to_rad(18.0))
	gyro_pivot.add_child(g2)

	# Tinh Hoàn 3 (Nằm ngang tại Y = 0.22m, R = 1.55m): Đỏ - Lam - Tím Hồng
	var g3 := MeshInstance3D.new()
	g3.name = "GyroRing3"
	g3.mesh = build_curved_slash_arc_mesh(1.55, 0.28, 310.0, 36)
	g3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var smat_g3 := ShaderMaterial.new()
	smat_g3.shader = _get_stylized_slash_shader()
	smat_g3.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
	smat_g3.set_shader_parameter("mid_color", Color(1.0, 0.03, 0.14, 1.0))
	smat_g3.set_shader_parameter("edge_color", Color(0.0, 0.45, 1.0, 1.0))
	smat_g3.set_shader_parameter("accent_color", Color(1.0, 0.0, 0.90, 1.0))
	smat_g3.set_shader_parameter("emission_strength", 6.2)
	smat_g3.set_shader_parameter("core_sharpness", 2.2)
	smat_g3.set_shader_parameter("chromatic_shift", 0.85)
	smat_g3.set_shader_parameter("slash_progress", 0.06)
	g3.material_override = smat_g3
	g3.position = Vector3(0.0, -0.63, 0.0) # 0.85 - 0.63 = 0.22m
	gyro_pivot.add_child(g3)

	# -------------------------------------------------------------------------
	# LỚP 3: ĐẠI TRẬN PHÁP LIÊN HOA 3 TẦNG DECAL DƯỚI CHÂN (GroundSanctum)
	# -------------------------------------------------------------------------
	var sanctum_pivot := Node3D.new()
	sanctum_pivot.name = "GroundSanctum"
	sanctum_pivot.position = Vector3(0.0, 0.05, 0.0)
	aura_holder.add_child(sanctum_pivot)

	var dec1 := Decal.new()
	dec1.name = "SanctumDecal_0"
	var t_c4 := _load_cached_tex("res://assets/vfx_textures/circle_04.png")
	if t_c4:
		dec1.texture_albedo = t_c4
		dec1.texture_emission = t_c4
	dec1.modulate = Color(0.05, 0.55, 1.0, 0.90)
	dec1.emission_energy = 4.2
	dec1.size = Vector3(3.6, 2.5, 3.6)
	sanctum_pivot.add_child(dec1)

	var dec2 := Decal.new()
	dec2.name = "SanctumDecal_1"
	var t_c2 := _load_cached_tex("res://assets/vfx_textures/circle_02.png")
	if t_c2:
		dec2.texture_albedo = t_c2
		dec2.texture_emission = t_c2
	dec2.modulate = Color(1.0, 0.12, 0.22, 0.95)
	dec2.emission_energy = 4.8
	dec2.size = Vector3(2.7, 2.5, 2.7)
	sanctum_pivot.add_child(dec2)

	var dec3 := Decal.new()
	dec3.name = "SanctumDecal_2"
	var t_s7 := _load_cached_tex("res://assets/vfx_textures/star_07.png")
	if t_s7:
		dec3.texture_albedo = t_s7
		dec3.texture_emission = t_s7
	dec3.modulate = Color(1.0, 0.85, 0.3, 0.95)
	dec3.emission_energy = 5.2
	dec3.size = Vector3(1.9, 2.5, 1.9)
	sanctum_pivot.add_child(dec3)

	# -------------------------------------------------------------------------
	# LỚP 4: BÃO LỬA ĐỎ & HỒ QUANG SÉT XANH (GPUParticles3D, 100% ArrayMesh)
	# -------------------------------------------------------------------------
	var flame_particles := GPUParticles3D.new()
	flame_particles.name = "RageCrimsonFlameAura"
	flame_particles.amount = 28
	flame_particles.lifetime = 0.65
	flame_particles.draw_pass_1 = get_safe_particle_quad_mesh(Vector2(0.35, 0.35))

	var fpmat := ParticleProcessMaterial.new()
	fpmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	fpmat.emission_ring_radius = 0.85
	fpmat.emission_ring_inner_radius = 0.25
	fpmat.direction = Vector3(0.0, 1.0, 0.0)
	fpmat.spread = 22.0
	fpmat.initial_velocity_min = 2.0
	fpmat.initial_velocity_max = 3.8
	fpmat.gravity = Vector3(0.0, 1.5, 0.0)
	fpmat.scale_min = 0.70
	fpmat.scale_max = 1.35
	fpmat.color_ramp = _get_rage_crimson_cobalt_ramp()
	flame_particles.process_material = fpmat

	var f_draw_mat := StandardMaterial3D.new()
	f_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	f_draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	f_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	f_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	f_draw_mat.vertex_color_use_as_albedo = true
	var tex_flame := _load_cached_tex("res://assets/vfx_textures/flame_04.png")
	if tex_flame:
		f_draw_mat.albedo_texture = tex_flame
	f_draw_mat.emission_enabled = true
	f_draw_mat.emission = Color(1.0, 0.15, 0.25)
	f_draw_mat.emission_energy_multiplier = 4.2
	flame_particles.material_override = f_draw_mat
	flame_particles.position = Vector3(0.0, 0.15, 0.0)
	aura_holder.add_child(flame_particles)

	var spark_particles := GPUParticles3D.new()
	spark_particles.name = "RageCobaltLightningSparks"
	spark_particles.amount = 24
	spark_particles.lifetime = 0.40
	spark_particles.draw_pass_1 = get_safe_particle_quad_mesh(Vector2(0.28, 0.28))

	var spk_pmat := ParticleProcessMaterial.new()
	spk_pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spk_pmat.emission_sphere_radius = 0.95
	spk_pmat.direction = Vector3(0.0, 1.0, 0.0)
	spk_pmat.spread = 180.0
	spk_pmat.initial_velocity_min = 1.2
	spk_pmat.initial_velocity_max = 3.2
	spk_pmat.gravity = Vector3(0.0, -0.5, 0.0)
	spk_pmat.scale_min = 0.45
	spk_pmat.scale_max = 0.95
	spark_particles.process_material = spk_pmat

	var spk_draw_mat := StandardMaterial3D.new()
	spk_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spk_draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spk_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spk_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	spk_draw_mat.vertex_color_use_as_albedo = true
	var tex_spark := _load_cached_tex("res://assets/vfx_textures/spark_06.png")
	if tex_spark:
		spk_draw_mat.albedo_texture = tex_spark
	spk_draw_mat.emission_enabled = true
	spk_draw_mat.emission = Color(0.0, 0.65, 1.0)
	spk_draw_mat.emission_energy_multiplier = 4.5
	spark_particles.material_override = spk_draw_mat
	spark_particles.position = Vector3(0.0, 0.85, 0.0)
	aura_holder.add_child(spark_particles)

	# -------------------------------------------------------------------------
	# LỚP 5: ĐÈN OMNILIGHT3D CHUYỂN SẮC & CHỚP SÁNG MŨI KIẾM
	# -------------------------------------------------------------------------
	var light := OmniLight3D.new()
	light.name = "RageAuraLight"
	light.shadow_enabled = false
	light.omni_range = 5.5
	light.light_energy = 3.2
	light.position = Vector3(0.0, 1.1, 0.0)
	aura_holder.add_child(light)

	var weapon_flare := MeshInstance3D.new()
	weapon_flare.name = "WeaponGlowFlare"
	weapon_flare.mesh = get_safe_particle_quad_mesh(Vector2(0.38, 0.38))
	weapon_flare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var wf_mat := StandardMaterial3D.new()
	wf_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wf_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	wf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wf_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var wf_tex := _load_cached_tex("res://assets/vfx_textures/star_07.png")
	if wf_tex:
		wf_mat.albedo_texture = wf_tex
	wf_mat.emission_enabled = true
	wf_mat.emission = Color(1.0, 0.9, 0.4)
	wf_mat.emission_energy_multiplier = 5.0
	weapon_flare.material_override = wf_mat
	weapon_flare.position = Vector3(0.45, 1.05, 0.35)
	aura_holder.add_child(weapon_flare)

	# -------------------------------------------------------------------------
	# BỘ DIỄN HOẠT HÀO QUANG TOÀN NĂNG (RageAuraAnimator)
	# -------------------------------------------------------------------------
	var anim_node := RageAuraAnimator.new()
	anim_node.name = "RageAuraAnimator"
	aura_holder.add_child(anim_node)
	anim_node.wings_l = wings_left
	anim_node.wings_r = wings_right
	anim_node.gyro1 = g1
	anim_node.gyro2 = g2
	anim_node.gyro3 = g3
	anim_node.d1 = dec1
	anim_node.d2 = dec2
	anim_node.d3 = dec3
	anim_node.aura_light = light
	anim_node.flare = weapon_flare

	return aura_holder

## Hiệu ứng trúng đòn Đa Sắc (Directive 25 Task 25.5)
static func spawn_hit_sparks(tree: SceneTree, hit_pos: Vector3, hit_dir: Vector3 = Vector3.UP) -> void:
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	var scene_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if scene_parent == null:
		return

	# Hoa đăng tinh tú chớp sáng tức thì
	_spawn_kenney_star_flare_burst(tree, hit_pos, 1.85, Color(1.0, 0.92, 0.35, 1.0), Color(1.0, 0.22, 0.78, 1.0), 0.18)

	# 22 hạt tia lửa dùng _get_prismatic_color_ramp()
	var sparks := GPUParticles3D.new()
	sparks.name = "HitSparksPrismatic"
	sparks.amount = 22
	sparks.lifetime = 0.28
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	sparks.local_coords = false

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = hit_dir
	pmat.spread = 80.0
	pmat.initial_velocity_min = 4.5
	pmat.initial_velocity_max = 9.5
	pmat.gravity = Vector3(0.0, -8.0, 0.0)
	pmat.scale_min = 0.2
	pmat.scale_max = 0.5
	pmat.color_ramp = _get_prismatic_color_ramp()
	sparks.process_material = pmat

	var draw_mat := StandardMaterial3D.new()
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	draw_mat.vertex_color_use_as_albedo = true
	var stex := _load_cached_tex("res://assets/vfx_textures/kenney_particles/spark_05.png")
	if stex:
		draw_mat.albedo_texture = stex
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(1.0, 0.85, 0.95)
	draw_mat.emission_energy_multiplier = 3.5

	var qmesh := get_safe_particle_quad_mesh(Vector2(0.4, 0.4))
	sparks.draw_pass_1 = qmesh
	sparks.material_override = draw_mat

	scene_parent.add_child(sparks)
	sparks.global_position = hit_pos
	sparks.emitting = true
	var tw := sparks.create_tween()
	tw.tween_interval(0.35)
	tw.tween_callback(sparks.queue_free)

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

## Chiêu 1: Đánh thường LMB / [U] Combo 3 Nhịp Biến Hóa (Directive 25 & Directive 26)
static func spawn_combo_slash_vfx(
	combo_step: int,
	origin: Vector3,
	yaw: float,
	parent_node: Node = null,
	is_rage: bool = false
) -> void:
	if is_rage:
		var tree_inst := Engine.get_main_loop() as SceneTree
		var scene_parent: Node = tree_inst.current_scene if (tree_inst and tree_inst.current_scene) else (tree_inst.root if tree_inst else null)
		if scene_parent == null:
			return
		var flat_fwd := Vector3(sin(yaw), 0.0, cos(yaw)).normalized()

		if combo_step == 0 or combo_step == 1:
			var tilt_base := 6.0 if combo_step == 0 else -30.0
			var slash_sign := 1.0 if combo_step == 0 else -1.0

			# Lưỡi Tầng Trong: Đỏ Huyết Ngục (R = 2.15m, W = 0.82m)
			var p_red := Node3D.new()
			p_red.name = "U%dRageDualSlashRed" % (combo_step + 1)
			scene_parent.add_child(p_red)
			p_red.global_position = origin
			p_red.rotation = Vector3(0.0, yaw, deg_to_rad(tilt_base))

			var m_red := MeshInstance3D.new()
			m_red.mesh = build_curved_slash_arc_mesh(2.15, 0.82, 160.0, 36)
			m_red.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var smat_red := ShaderMaterial.new()
			smat_red.shader = _get_stylized_slash_shader()
			smat_red.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
			smat_red.set_shader_parameter("mid_color", Color(1.0, 0.03, 0.14, 1.0)) # #FF0824
			smat_red.set_shader_parameter("edge_color", Color(0.72, 0.0, 0.07, 1.0)) # #B80012
			smat_red.set_shader_parameter("accent_color", Color(1.0, 0.33, 0.0, 1.0)) # #FF5500
			smat_red.set_shader_parameter("emission_strength", 6.2)
			smat_red.set_shader_parameter("core_sharpness", 2.2)
			smat_red.set_shader_parameter("hold_power", 0.35)
			smat_red.set_shader_parameter("slash_progress", 0.0)
			m_red.material_override = smat_red
			p_red.add_child(m_red)

			_animate_lingering_power_slash(p_red, m_red, smat_red, 50.0 * slash_sign, -92.0 * slash_sign, 0.48, 1.25, flat_fwd * 0.35)

			# Lưỡi Tầng Ngoài: Xanh Dương Lam Lôi (R = 2.78m, W = 0.72m, lệch 15°)
			var p_blue := Node3D.new()
			p_blue.name = "U%dRageDualSlashBlue" % (combo_step + 1)
			scene_parent.add_child(p_blue)
			p_blue.global_position = origin
			p_blue.rotation = Vector3(0.0, yaw, deg_to_rad(tilt_base + 15.0 * slash_sign))

			var m_blue := MeshInstance3D.new()
			m_blue.mesh = build_curved_slash_arc_mesh(2.78, 0.72, 165.0, 36)
			m_blue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var smat_blue := ShaderMaterial.new()
			smat_blue.shader = _get_stylized_slash_shader()
			smat_blue.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
			smat_blue.set_shader_parameter("mid_color", Color(0.0, 0.40, 1.0, 1.0)) # #0066FF
			smat_blue.set_shader_parameter("edge_color", Color(0.0, 0.13, 0.67, 1.0)) # #0022AA
			smat_blue.set_shader_parameter("accent_color", Color(0.0, 0.90, 1.0, 1.0)) # #00E5FF
			smat_blue.set_shader_parameter("emission_strength", 6.2)
			smat_blue.set_shader_parameter("core_sharpness", 2.2)
			smat_blue.set_shader_parameter("hold_power", 0.35)
			smat_blue.set_shader_parameter("slash_progress", 0.0)
			m_blue.material_override = smat_blue
			p_blue.add_child(m_blue)

			_animate_lingering_power_slash(p_blue, m_blue, smat_blue, 54.0 * slash_sign, -96.0 * slash_sign, 0.48, 1.25, flat_fwd * 0.35)
			return
		else:
			# U3 Trạng thái 2: Huyết Lam Long Thần Giáng (5 Đại Kiếm Khí Xếp Quạt)
			spawn_u3_rage_crimson_cobalt_finale(tree_inst, origin, flat_fwd)
			return

	match combo_step:
		0:
			# Nhịp 1: Cung Trăng Lam Băng Cực Quang (#00F5FF) -> Vàng Phượng Hoàng (#FFD700) -> Tím Tinh Vân (#9D00FF)
			spawn_stylized_crescent_slash(
				origin,
				yaw,
				4.0,     # tilt_roll_deg
				false,   # reverse_swing
				Color(1.0, 1.0, 1.0, 1.0),   # Lõi Trắng Kim Cương
				Color(0.0, 0.96, 1.0, 1.0),   # Lam Băng Cực Quang (#00F5FF)
				Color(1.0, 0.84, 0.0, 1.0),   # Vàng Phượng Hoàng (#FFD700)
				1.0,
				0.24,
				parent_node
			)
			# Dải lụa kiếm khí phụ mỏng quét lệch 8° và hạt spark_05
			var tree_inst := Engine.get_main_loop() as SceneTree
			if tree_inst != null:
				var scene_parent: Node = tree_inst.current_scene if tree_inst.current_scene else tree_inst.root
				if scene_parent != null:
					var pivot_sub := Node3D.new()
					pivot_sub.name = "U1SubSlashPivot"
					scene_parent.add_child(pivot_sub)
					pivot_sub.global_position = origin
					pivot_sub.rotation = Vector3(0.0, yaw, deg_to_rad(12.0))
					var sub_mesh := MeshInstance3D.new()
					sub_mesh.mesh = build_curved_slash_arc_mesh(2.1, 0.45, 140.0, 36)
					sub_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					var smat_sub := ShaderMaterial.new()
					smat_sub.shader = _get_stylized_slash_shader()
					smat_sub.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
					smat_sub.set_shader_parameter("mid_color", Color(0.62, 0.0, 1.0, 1.0)) # Tím Tinh Vân (#9D00FF)
					smat_sub.set_shader_parameter("edge_color", Color(0.0, 0.96, 1.0, 1.0))
					smat_sub.set_shader_parameter("accent_color", Color(1.0, 0.84, 0.0, 1.0))
					smat_sub.set_shader_parameter("emission_strength", 7.0)
					sub_mesh.material_override = smat_sub
					pivot_sub.add_child(sub_mesh)
					var tw_sub := pivot_sub.create_tween()
					tw_sub.tween_method(func(v: float):
						if is_instance_valid(smat_sub):
							smat_sub.set_shader_parameter("slash_progress", v)
					, 0.0, 1.0, 0.22)
					tw_sub.tween_callback(pivot_sub.queue_free)
		1:
			# Nhịp 2: Song Kiếm Khí Giao Thoa: Hồng Cực Quang (#FF1A8C) -> Cam Rực Lửa (#FF6600) -> Tím Sấm Sét (#8C00FF)
			spawn_stylized_crescent_slash(
				origin,
				yaw,
				-32.0,   # tilt_roll_deg chém chéo
				true,    # reverse_swing
				Color(1.0, 1.0, 1.0, 1.0),
				Color(1.0, 0.10, 0.55, 1.0), # Hồng Cực Quang (#FF1A8C)
				Color(1.0, 0.40, 0.0, 1.0),  # Cam Rực Lửa (#FF6600)
				1.08,
				0.24,
				parent_node
			)
			var tree := Engine.get_main_loop() as SceneTree
			if tree != null:
				var t := tree.create_timer(0.04)
				t.timeout.connect(func():
					spawn_stylized_crescent_slash(
						origin,
						yaw,
						24.0,
						false,
						Color(1.0, 1.0, 1.0, 1.0),
						Color(0.55, 0.0, 1.0, 1.0), # Tím Sấm Sét (#8C00FF)
						Color(1.0, 0.10, 0.55, 1.0),
						0.96,
						0.20,
						parent_node
					)
				)
		2, _:
			# Nhịp 3: "Thánh Long Thiên Giáng Trảm" (7 Lớp Đa Sắc)
			var tree_inst := Engine.get_main_loop() as SceneTree
			var fwd := Vector3(sin(yaw), 0.0, cos(yaw)).normalized()
			spawn_u3_heaven_shatter_finale(tree_inst, origin, fwd)

## Lớp hoàn thiện nhịp 3: Thánh Long Thiên Giáng Trảm 7 Lớp Đa Sắc (Directive 25 Task 25.3)
static func spawn_u3_heaven_shatter_finale(tree: SceneTree, origin: Vector3, forward_dir: Vector3) -> void:
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	var scene_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if scene_parent == null:
		return
	var flat_fwd := Vector3(forward_dir.x, 0.0, forward_dir.z).normalized()
	if flat_fwd.length_squared() < 0.001:
		flat_fwd = Vector3.FORWARD
	var right_dir := flat_fwd.cross(Vector3.UP).normalized()
	var impact_pos := _snap_vfx_to_ground(tree, origin + flat_fwd * 1.85)
	var base_yaw := atan2(flat_fwd.x, flat_fwd.z)

	# =========================================================================
	# LỚP 1: TAM TRÙNG ĐẠI KIẾM KHÍ BỔ DỌC ĐA SẮC (3 CURVED SLASH RIBBONS)
	# =========================================================================
	var arc_configs := [
		{
			"radius": 2.35, "width": 0.95, "roll": deg_to_rad(88.0), "yaw_off": 0.0,
			"core": Color(1.0, 1.0, 1.0, 1.0), "mid": Color(1.0, 0.88, 0.15, 1.0),
			"edge": Color(1.0, 0.18, 0.02, 1.0), "accent": Color(0.85, 0.05, 1.0, 1.0),
			"emission": 9.2, "dur": 0.34
		},
		{
			"radius": 2.15, "width": 0.78, "roll": deg_to_rad(70.0), "yaw_off": deg_to_rad(-14.0),
			"core": Color(1.0, 0.98, 1.0, 1.0), "mid": Color(1.0, 0.20, 0.68, 1.0),
			"edge": Color(0.58, 0.0, 1.0, 1.0), "accent": Color(1.0, 0.85, 0.1, 1.0),
			"emission": 8.4, "dur": 0.36
		},
		{
			"radius": 2.15, "width": 0.78, "roll": deg_to_rad(106.0), "yaw_off": deg_to_rad(14.0),
			"core": Color(1.0, 1.0, 1.0, 1.0), "mid": Color(0.0, 0.96, 1.0, 1.0),
			"edge": Color(0.0, 0.32, 1.0, 1.0), "accent": Color(1.0, 0.15, 0.75, 1.0),
			"emission": 8.4, "dur": 0.36
		}
	]

	for arc_idx in range(arc_configs.size()):
		var cfg: Dictionary = arc_configs[arc_idx]
		var pivot := Node3D.new()
		pivot.name = "U3TripleGuillotineArc_%d" % arc_idx
		scene_parent.add_child(pivot)
		pivot.global_position = origin + Vector3(0.0, 1.25, 0.0) + flat_fwd * 0.45
		pivot.rotation = Vector3(0.0, base_yaw + float(cfg["yaw_off"]), float(cfg["roll"]))

		var mesh_inst := MeshInstance3D.new()
		mesh_inst.mesh = build_curved_slash_arc_mesh(float(cfg["radius"]), float(cfg["width"]), 155.0, 36)
		mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var smat := ShaderMaterial.new()
		smat.shader = _get_stylized_slash_shader()
		smat.set_shader_parameter("core_color", cfg["core"])
		smat.set_shader_parameter("mid_color", cfg["mid"])
		smat.set_shader_parameter("edge_color", cfg["edge"])
		smat.set_shader_parameter("accent_color", cfg["accent"])
		smat.set_shader_parameter("emission_strength", float(cfg["emission"]))
		smat.set_shader_parameter("chromatic_shift", 0.70)
		smat.set_shader_parameter("slash_progress", 0.0)
		mesh_inst.material_override = smat
		pivot.add_child(mesh_inst)

		var dur: float = float(cfg["dur"])
		var tw := pivot.create_tween()
		tw.set_parallel(true)
		tw.tween_property(mesh_inst, "rotation:y", deg_to_rad(-95.0), dur).from(deg_to_rad(55.0)).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(v: float):
			if is_instance_valid(smat):
				smat.set_shader_parameter("slash_progress", v)
		, 0.0, 1.0, dur)
		tw.chain().tween_callback(pivot.queue_free)

	# =========================================================================
	# LỚP 2: 2 VÒNG LỤA KIẾM KHÍ XOÁY NGƯỢC CHIỀU SÁT MẶT ĐẤT (CYCLONE RINGS)
	# =========================================================================
	_spawn_prismatic_cyclone_ring_ribbon(
		tree, impact_pos, 0.45, 3.25, 0.65,
		Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 0.85, 0.1, 1.0),
		Color(1.0, 0.20, 0.0, 1.0), Color(1.0, 0.1, 0.8, 1.0),
		12.0, 0.38,
		"PrismaticCycloneRibbon3D_0"
	)
	_spawn_prismatic_cyclone_ring_ribbon(
		tree, impact_pos + Vector3(0.0, 0.12, 0.0), 0.60, 3.85, 0.52,
		Color(1.0, 1.0, 1.0, 1.0), Color(0.0, 0.95, 1.0, 1.0),
		Color(0.65, 0.0, 1.0, 1.0), Color(1.0, 0.25, 0.65, 1.0),
		-14.0, 0.44,
		"PrismaticCycloneRibbon3D_1"
	)

	# =========================================================================
	# LỚP 3: CỘT LỐC XOÁY LỤA ĐÔI BỐC LÊN TRỜI (VERTICAL HELIX SLASH RIBBONS)
	# =========================================================================
	for h_idx in range(2):
		var pillar_pivot := Node3D.new()
		pillar_pivot.name = "U3HelixRibbonPillar_%d" % h_idx
		scene_parent.add_child(pillar_pivot)
		pillar_pivot.global_position = impact_pos + Vector3(0.0, 0.25 + h_idx * 0.45, 0.0)
		pillar_pivot.rotation.z = deg_to_rad(22.0 if h_idx == 0 else -22.0)

		var p_mesh := MeshInstance3D.new()
		p_mesh.mesh = build_curved_slash_arc_mesh(1.15, 0.72, 260.0, 36)
		p_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var p_mat := ShaderMaterial.new()
		p_mat.shader = _get_stylized_slash_shader()
		p_mat.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
		p_mat.set_shader_parameter("mid_color", Color(1.0, 0.9, 0.2, 1.0) if h_idx == 0 else Color(1.0, 0.2, 0.85, 1.0))
		p_mat.set_shader_parameter("edge_color", Color(1.0, 0.25, 0.0, 1.0) if h_idx == 0 else Color(0.0, 0.85, 1.0, 1.0))
		p_mat.set_shader_parameter("accent_color", Color(0.75, 0.1, 1.0, 1.0))
		p_mat.set_shader_parameter("emission_strength", 8.5)
		p_mesh.material_override = p_mat
		pillar_pivot.add_child(p_mesh)

		var p_tw := pillar_pivot.create_tween()
		p_tw.set_parallel(true)
		p_tw.tween_property(pillar_pivot, "global_position:y", impact_pos.y + 3.2, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		p_tw.tween_property(pillar_pivot, "rotation:y", (1.0 if h_idx == 0 else -1.0) * TAU * 1.4, 0.36)
		p_tw.tween_property(pillar_pivot, "scale", Vector3(1.85, 1.5, 1.85), 0.36)
		p_tw.tween_method(func(val: float):
			if is_instance_valid(p_mat):
				p_mat.set_shader_parameter("slash_progress", val)
		, 0.0, 1.0, 0.36)
		p_tw.chain().tween_callback(pillar_pivot.queue_free)

	# =========================================================================
	# LỚP 4: TRẬN PHÁP CỔ NGỮ ĐA SẮC KÉP XOAY NGƯỢC CHIỀU (2 KENNEY DECALS)
	# =========================================================================
	var decal_configs := [
		{"tex": "res://assets/vfx_textures/kenney_particles/scorch_02.png", "size": 4.4, "col": Color(1.0, 0.32, 0.05, 0.95), "energy": 5.5, "spin": 2.2, "dur": 0.75},
		{"tex": "res://assets/vfx_textures/kenney_particles/circle_02.png", "size": 3.9, "col": Color(1.0, 0.85, 0.25, 0.95), "energy": 6.8, "spin": -3.5, "dur": 0.65}
	]
	for d_idx in range(decal_configs.size()):
		var dcfg: Dictionary = decal_configs[d_idx]
		var dec := Decal.new()
		dec.name = "U3HeavenDecal_%d" % d_idx
		var dtex := _load_cached_tex(String(dcfg["tex"]))
		if dtex:
			dec.texture_albedo = dtex
			dec.texture_emission = dtex
		dec.modulate = dcfg["col"]
		dec.emission_energy = float(dcfg["energy"])
		var s: float = float(dcfg["size"])
		dec.size = Vector3(s * 0.2, 3.0, s * 0.2)
		scene_parent.add_child(dec)
		dec.global_position = impact_pos
		var d_tw := dec.create_tween()
		d_tw.set_parallel(true)
		d_tw.tween_property(dec, "size", Vector3(s, 3.0, s), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		d_tw.tween_property(dec, "rotation:y", float(dcfg["spin"]), float(dcfg["dur"]))
		d_tw.tween_property(dec, "modulate:a", 0.0, float(dcfg["dur"]) * 0.55).set_delay(float(dcfg["dur"]) * 0.45)
		d_tw.chain().tween_callback(dec.queue_free)

	# =========================================================================
	# LỚP 5: HOA ĐĂNG TINH TÚ KENNEY BÙNG NỔ TẠI TÂM VA CHẠM
	# =========================================================================
	_spawn_kenney_star_flare_burst(
		tree, impact_pos + Vector3(0.0, 0.55, 0.0), 3.2,
		Color(1.0, 0.95, 0.35, 1.0), Color(1.0, 0.20, 0.80, 1.0), 0.30
	)

	# =========================================================================
	# LỚP 6: ĐÀI PHUN HẠT CẦU VỒNG 42 HẠT (PRISMATIC KENNEY GPUPARTICLES3D)
	# =========================================================================
	var sparks := GPUParticles3D.new()
	sparks.name = "U3PrismaticFountainParticles"
	sparks.amount = 42
	sparks.lifetime = 0.48
	sparks.one_shot = true
	sparks.explosiveness = 0.92
	sparks.draw_pass_1 = get_safe_particle_quad_mesh(Vector2(0.42, 0.42))

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0.0, 1.0, 0.0)
	pmat.spread = 62.0
	pmat.initial_velocity_min = 6.5
	pmat.initial_velocity_max = 13.5
	pmat.gravity = Vector3(0.0, -18.0, 0.0)
	pmat.scale_min = 0.55
	pmat.scale_max = 1.35
	pmat.color_ramp = _get_prismatic_color_ramp()
	sparks.process_material = pmat

	var spark_draw_mat := StandardMaterial3D.new()
	spark_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	spark_draw_mat.vertex_color_use_as_albedo = true
	var stex := _load_cached_tex("res://assets/vfx_textures/kenney_particles/spark_05.png")
	if stex:
		spark_draw_mat.albedo_texture = stex
	spark_draw_mat.emission_enabled = true
	spark_draw_mat.emission = Color(1.0, 0.75, 0.95)
	spark_draw_mat.emission_energy_multiplier = 4.2
	sparks.material_override = spark_draw_mat

	scene_parent.add_child(sparks)
	sparks.global_position = impact_pos + Vector3(0.0, 0.35, 0.0)
	sparks.emitting = true
	var sp_tw := sparks.create_tween()
	sp_tw.tween_interval(0.65)
	sp_tw.tween_callback(sparks.queue_free)

	# =========================================================================
	# LỚP 7: XUNG ÁNH SÁNG ĐỘNG OMNILIGHT3D ĐỔI MÀU (SHADOWLESS HDR LIGHT)
	# =========================================================================
	var light := OmniLight3D.new()
	light.name = "U3HeavenFlashLight"
	light.shadow_enabled = false
	light.omni_range = 7.2
	light.light_color = Color(1.0, 0.82, 0.28)
	light.light_energy = 6.2
	scene_parent.add_child(light)
	light.global_position = impact_pos + Vector3(0.0, 1.1, 0.0)
	var l_tw := light.create_tween()
	l_tw.set_parallel(true)
	l_tw.tween_property(light, "light_color", Color(0.95, 0.20, 1.0), 0.32)
	l_tw.tween_property(light, "light_energy", 0.0, 0.32)
	l_tw.chain().tween_callback(light.queue_free)


## U3 Trạng thái 2: "HUYẾT LAM LONG THẦN GIÁNG" 5 Đại Kiếm Khí Xếp Quạt & Đọng Lại 0.58s (Directive 26 Task 26.4)
static func spawn_u3_rage_crimson_cobalt_finale(tree: SceneTree, origin: Vector3, forward_dir: Vector3) -> void:
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	var scene_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if scene_parent == null:
		return
	var flat_fwd := Vector3(forward_dir.x, 0.0, forward_dir.z).normalized()
	if flat_fwd.length_squared() < 0.001:
		flat_fwd = Vector3.FORWARD
	var impact_pos := _snap_vfx_to_ground(tree, origin + flat_fwd * 2.0)
	var base_yaw := atan2(flat_fwd.x, flat_fwd.z)

	# =========================================================================
	# LỚP 1: NGŨ ĐẠI KIẾM KHÍ BỔ DỌC XẾP HÌNH CÁNH QUẠT (5 LƯỠI TÁCH RỜI)
	# =========================================================================
	var rage_u3_blades := [
		# 1. Chính giữa yaw=0°, radius=2.85m, width=1.05m, roll=90°: Đỏ Huyết Tối Thượng
		{"yaw_off": 0.0, "roll": deg_to_rad(90.0), "radius": 2.85, "width": 1.05, "mid": Color(1.0, 0.03, 0.14, 1.0), "edge": Color(0.60, 0.0, 0.0, 1.0), "accent": Color(1.0, 0.40, 0.0, 1.0)},
		# 2. Cánh Trái Trong yaw=-18°, roll=72°, radius=2.55m, width=0.85m: Xanh Dương Điện Quang
		{"yaw_off": deg_to_rad(-18.0), "roll": deg_to_rad(72.0), "radius": 2.55, "width": 0.85, "mid": Color(0.0, 0.40, 1.0, 1.0), "edge": Color(0.0, 0.12, 0.60, 1.0), "accent": Color(0.0, 0.94, 1.0, 1.0)},
		# 3. Cánh Phải Trong yaw=+18°, roll=108°, radius=2.55m, width=0.85m: Xanh Dương Điện Quang
		{"yaw_off": deg_to_rad(18.0), "roll": deg_to_rad(108.0), "radius": 2.55, "width": 0.85, "mid": Color(0.0, 0.40, 1.0, 1.0), "edge": Color(0.0, 0.12, 0.60, 1.0), "accent": Color(0.0, 0.94, 1.0, 1.0)},
		# 4. Cánh Trái Ngoài yaw=-36°, roll=58°, radius=2.30m, width=0.75m: Đỏ Huyết Cực Quang
		{"yaw_off": deg_to_rad(-36.0), "roll": deg_to_rad(58.0), "radius": 2.30, "width": 0.75, "mid": Color(1.0, 0.10, 0.21, 1.0), "edge": Color(0.53, 0.0, 0.08, 1.0), "accent": Color(0.0, 0.33, 1.0, 1.0)},
		# 5. Cánh Phải Ngoài yaw=+36°, roll=122°, radius=2.30m, width=0.75m: Đỏ Huyết Cực Quang
		{"yaw_off": deg_to_rad(36.0), "roll": deg_to_rad(122.0), "radius": 2.30, "width": 0.75, "mid": Color(1.0, 0.10, 0.21, 1.0), "edge": Color(0.53, 0.0, 0.08, 1.0), "accent": Color(0.0, 0.33, 1.0, 1.0)}
	]

	for b_idx in range(rage_u3_blades.size()):
		var bcfg: Dictionary = rage_u3_blades[b_idx]
		var pivot := Node3D.new()
		pivot.name = "U3RageFiveBladeFan_%d" % b_idx
		scene_parent.add_child(pivot)
		pivot.global_position = origin + Vector3(0.0, 1.35, 0.0) + flat_fwd * 0.55
		pivot.rotation = Vector3(0.0, base_yaw + float(bcfg["yaw_off"]), float(bcfg["roll"]))

		var mesh_inst := MeshInstance3D.new()
		mesh_inst.mesh = build_curved_slash_arc_mesh(float(bcfg["radius"]), float(bcfg["width"]), 160.0, 36)
		mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var smat := ShaderMaterial.new()
		smat.shader = _get_stylized_slash_shader()
		smat.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
		smat.set_shader_parameter("mid_color", bcfg["mid"])
		smat.set_shader_parameter("edge_color", bcfg["edge"])
		smat.set_shader_parameter("accent_color", bcfg["accent"])
		smat.set_shader_parameter("emission_strength", 9.8)
		smat.set_shader_parameter("core_sharpness", 2.2)
		smat.set_shader_parameter("hold_power", 0.35)
		smat.set_shader_parameter("chromatic_shift", 0.75)
		smat.set_shader_parameter("slash_progress", 0.0)
		mesh_inst.material_override = smat
		pivot.add_child(mesh_inst)

		_animate_lingering_power_slash(pivot, mesh_inst, smat, 55.0, -95.0, 0.58, 1.28, flat_fwd * 0.42)

	# =========================================================================
	# LỚP 2: TAM TRÙNG VÒNG LỤA XOÁY PHÂN TẦNG ĐỎ - XANH (3 CYCLONE RINGS, 0.62s)
	# =========================================================================
	_spawn_prismatic_cyclone_ring_ribbon(
		tree, impact_pos, 0.4, 2.2, 0.65,
		Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 0.03, 0.14, 1.0), Color(0.70, 0.0, 0.10, 1.0), Color(1.0, 0.35, 0.0, 1.0),
		14.0, 0.62, "U3RageCycloneRing_0"
	)
	_spawn_prismatic_cyclone_ring_ribbon(
		tree, impact_pos + Vector3(0.0, 0.05, 0.0), 1.2, 3.3, 0.65,
		Color(1.0, 1.0, 1.0, 1.0), Color(0.0, 0.40, 1.0, 1.0), Color(0.0, 0.12, 0.60, 1.0), Color(0.0, 0.90, 1.0, 1.0),
		-15.0, 0.62, "U3RageCycloneRing_1"
	)
	_spawn_prismatic_cyclone_ring_ribbon(
		tree, impact_pos + Vector3(0.0, 0.10, 0.0), 2.0, 4.3, 0.65,
		Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 0.03, 0.14, 1.0), Color(0.0, 0.30, 1.0, 1.0), Color(0.0, 0.90, 1.0, 1.0),
		12.0, 0.62, "U3RageCycloneRing_2"
	)

	# =========================================================================
	# LỚP 3: 4 CỘT LỐC XOÁY LỤA ĐỎ - XANH CAO 4.2M (4 VERTICAL HELIX PILLARS)
	# =========================================================================
	for h_idx in range(4):
		var pillar_pivot := Node3D.new()
		pillar_pivot.name = "U3RageHelixPillar_%d" % h_idx
		scene_parent.add_child(pillar_pivot)
		pillar_pivot.global_position = impact_pos + Vector3(0.0, 0.20 + h_idx * 0.35, 0.0)
		pillar_pivot.rotation.z = deg_to_rad(24.0 if (h_idx % 2 == 0) else -24.0)

		var p_mesh := MeshInstance3D.new()
		p_mesh.mesh = build_curved_slash_arc_mesh(1.25, 0.78, 270.0, 36)
		p_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var p_mat := ShaderMaterial.new()
		p_mat.shader = _get_stylized_slash_shader()
		p_mat.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
		var is_red := (h_idx % 2 == 0)
		p_mat.set_shader_parameter("mid_color", Color(1.0, 0.04, 0.14, 1.0) if is_red else Color(0.0, 0.42, 1.0, 1.0))
		p_mat.set_shader_parameter("edge_color", Color(0.70, 0.0, 0.08, 1.0) if is_red else Color(0.0, 0.15, 0.80, 1.0))
		p_mat.set_shader_parameter("accent_color", Color(1.0, 0.40, 0.0, 1.0) if is_red else Color(0.0, 0.85, 1.0, 1.0))
		p_mat.set_shader_parameter("emission_strength", 8.8)
		p_mat.set_shader_parameter("core_sharpness", 2.2)
		p_mesh.material_override = p_mat
		pillar_pivot.add_child(p_mesh)

		var p_tw := pillar_pivot.create_tween()
		p_tw.set_parallel(true)
		p_tw.tween_property(pillar_pivot, "global_position:y", impact_pos.y + 4.2, 0.56).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		p_tw.tween_property(pillar_pivot, "rotation:y", (1.0 if (h_idx % 2 == 0) else -1.0) * TAU * 1.6, 0.56)
		p_tw.tween_property(pillar_pivot, "scale", Vector3(2.1, 1.65, 2.1), 0.56)
		p_tw.tween_method(func(val: float):
			if is_instance_valid(p_mat):
				p_mat.set_shader_parameter("slash_progress", val)
		, 0.0, 1.0, 0.56)
		p_tw.chain().tween_callback(pillar_pivot.queue_free)

	# =========================================================================
	# LỚP 4: 2 ẤN CHÚ NỨT ĐẤT ĐỌNG LẠI 1.10 GIÂY
	# =========================================================================
	var decal_configs := [
		{"tex": "res://assets/vfx_textures/kenney_particles/scorch_02.png", "size": 5.2, "col": Color(1.0, 0.05, 0.15, 0.95), "energy": 6.0, "spin": 2.0},
		{"tex": "res://assets/vfx_textures/kenney_particles/circle_05.png", "size": 4.6, "col": Color(0.0, 0.45, 1.0, 0.95), "energy": 6.5, "spin": -3.0}
	]
	for d_idx in range(decal_configs.size()):
		var dcfg: Dictionary = decal_configs[d_idx]
		var dec := Decal.new()
		dec.name = "U3RageDecal_%d" % d_idx
		var dtex := _load_cached_tex(String(dcfg["tex"]))
		if dtex:
			dec.texture_albedo = dtex
			dec.texture_emission = dtex
		dec.modulate = dcfg["col"]
		dec.emission_energy = float(dcfg["energy"])
		var s: float = float(dcfg["size"])
		dec.size = Vector3(s * 0.2, 3.0, s * 0.2)
		scene_parent.add_child(dec)
		dec.global_position = impact_pos
		var d_tw := dec.create_tween()
		d_tw.set_parallel(true)
		d_tw.tween_property(dec, "size", Vector3(s, 3.0, s), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		d_tw.tween_property(dec, "rotation:y", float(dcfg["spin"]), 1.10)
		d_tw.tween_property(dec, "modulate:a", 0.0, 0.45).set_delay(0.65)
		d_tw.chain().tween_callback(dec.queue_free)

	# =========================================================================
	# LỚP 5: HOA ĐĂNG ĐỎ - XANH DƯƠNG TẠI TÂM VA CHẠM
	# =========================================================================
	_spawn_kenney_star_flare_burst(
		tree, impact_pos + Vector3(0.0, 0.65, 0.0), 3.8,
		Color(1.0, 0.10, 0.25, 1.0), Color(0.0, 0.50, 1.0, 1.0), 0.42
	)

	# =========================================================================
	# LỚP 6: ĐÀI PHUN 56 HẠT ĐỎ - XANH DƯƠNG PHUN TRÀO (GPUPARTICLES3D)
	# =========================================================================
	var sparks := GPUParticles3D.new()
	sparks.name = "U3RagePrismaticFountainParticles"
	sparks.amount = 56
	sparks.lifetime = 0.58
	sparks.one_shot = true
	sparks.explosiveness = 0.94
	sparks.draw_pass_1 = get_safe_particle_quad_mesh(Vector2(0.44, 0.44))

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0.0, 1.0, 0.0)
	pmat.spread = 65.0
	pmat.initial_velocity_min = 7.5
	pmat.initial_velocity_max = 15.0
	pmat.gravity = Vector3(0.0, -17.0, 0.0)
	pmat.scale_min = 0.65
	pmat.scale_max = 1.45
	pmat.color_ramp = _get_rage_crimson_cobalt_ramp()
	sparks.process_material = pmat

	var spark_draw_mat := StandardMaterial3D.new()
	spark_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	spark_draw_mat.vertex_color_use_as_albedo = true
	var stex := _load_cached_tex("res://assets/vfx_textures/kenney_particles/spark_05.png")
	if stex:
		spark_draw_mat.albedo_texture = stex
	spark_draw_mat.emission_enabled = true
	spark_draw_mat.emission = Color(1.0, 0.4, 0.6)
	spark_draw_mat.emission_energy_multiplier = 4.5
	sparks.material_override = spark_draw_mat

	scene_parent.add_child(sparks)
	sparks.global_position = impact_pos + Vector3(0.0, 0.35, 0.0)
	sparks.emitting = true
	var sp_tw := sparks.create_tween()
	sp_tw.tween_interval(0.75)
	sp_tw.tween_callback(sparks.queue_free)

	# =========================================================================
	# LỚP 7: XUNG ÁNH SÁNG ĐỘNG OMNILIGHT3D
	# =========================================================================
	var light := OmniLight3D.new()
	light.name = "U3RageFlashLight"
	light.shadow_enabled = false
	light.omni_range = 8.2
	light.light_color = Color(1.0, 0.15, 0.30)
	light.light_energy = 7.0
	scene_parent.add_child(light)
	light.global_position = impact_pos + Vector3(0.0, 1.2, 0.0)
	var l_tw := light.create_tween()
	l_tw.set_parallel(true)
	l_tw.tween_property(light, "light_color", Color(0.0, 0.45, 1.0), 0.48)
	l_tw.tween_property(light, "light_energy", 0.0, 0.48)
	l_tw.chain().tween_callback(light.queue_free)

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

## Chiêu [I / RMB] Pha 1: Thánh Kiếm Phá Không Trảm: Cực Quang Thập Tự (Directive 25 & Directive 26)
static func spawn_rmb_solar_cross_cleave(arg1 = null, arg2 = null, arg3 = null, arg4 = null) -> Node3D:
	var tree: SceneTree = null
	var origin: Vector3 = Vector3.ZERO
	var forward_dir: Vector3 = Vector3.FORWARD
	var is_rage: bool = false

	if arg4 is bool:
		is_rage = arg4
	elif arg3 is bool:
		is_rage = arg3

	if arg1 is SceneTree:
		tree = arg1
		origin = arg2 if arg2 is Vector3 else Vector3.ZERO
		forward_dir = arg3 if arg3 is Vector3 else Vector3.FORWARD
	elif arg1 is Vector3:
		origin = arg1
		var yaw: float = float(arg2) if (arg2 is float or arg2 is int) else 0.0
		forward_dir = Vector3(sin(yaw), 0.0, cos(yaw)).normalized()
		var p_node := arg3 as Node
		if p_node and p_node.get_tree():
			tree = p_node.get_tree()
		else:
			tree = Engine.get_main_loop() as SceneTree
	else:
		tree = Engine.get_main_loop() as SceneTree

	if tree == null:
		return null
	var scene_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if scene_parent == null:
		return null

	var flat_fwd := Vector3(forward_dir.x, 0.0, forward_dir.z).normalized()
	if flat_fwd.length_squared() < 0.001:
		flat_fwd = Vector3.FORWARD
	var base_yaw := atan2(flat_fwd.x, flat_fwd.z)
	var cross_center := origin + Vector3(0.0, 1.15, 0.0) + flat_fwd * 1.15
	var ground_pos := _snap_vfx_to_ground(tree, origin + flat_fwd * 1.65)

	if is_rage:
		# =========================================================================
		# TRẠNG THÁI 2: LỤC KIẾM KHÍ CHỮ X TÁCH 3 TẦNG BÁN KÍNH (RMBHexaRageXSlash)
		# =========================================================================
		var rage_x_blades := [
			# 3 Vế Chéo Phải (+): Đỏ Huyết Ngục (#FF0824 / #CC0011) ở R=1.95m, 2.55m, 3.15m
			{"roll": deg_to_rad(38.0), "radius": 1.95, "width": 0.85, "dir": 1.0, "mid": Color(1.0, 0.03, 0.14, 1.0), "edge": Color(0.80, 0.0, 0.07, 1.0), "accent": Color(1.0, 0.35, 0.0, 1.0)},
			{"roll": deg_to_rad(44.0), "radius": 2.55, "width": 0.78, "dir": 1.0, "mid": Color(1.0, 0.03, 0.14, 1.0), "edge": Color(0.80, 0.0, 0.07, 1.0), "accent": Color(1.0, 0.35, 0.0, 1.0)},
			{"roll": deg_to_rad(50.0), "radius": 3.15, "width": 0.70, "dir": 1.0, "mid": Color(1.0, 0.03, 0.14, 1.0), "edge": Color(0.80, 0.0, 0.07, 1.0), "accent": Color(1.0, 0.35, 0.0, 1.0)},
			# 3 Vế Chéo Trái (-): Xanh Dương Lam Lôi (#0055FF / #00C8FF) ở R=1.95m, 2.55m, 3.15m
			{"roll": deg_to_rad(-38.0), "radius": 1.95, "width": 0.85, "dir": -1.0, "mid": Color(0.0, 0.33, 1.0, 1.0), "edge": Color(0.0, 0.12, 0.75, 1.0), "accent": Color(0.0, 0.80, 1.0, 1.0)},
			{"roll": deg_to_rad(-44.0), "radius": 2.55, "width": 0.78, "dir": -1.0, "mid": Color(0.0, 0.33, 1.0, 1.0), "edge": Color(0.0, 0.12, 0.75, 1.0), "accent": Color(0.0, 0.80, 1.0, 1.0)},
			{"roll": deg_to_rad(-50.0), "radius": 3.15, "width": 0.70, "dir": -1.0, "mid": Color(0.0, 0.33, 1.0, 1.0), "edge": Color(0.0, 0.12, 0.75, 1.0), "accent": Color(0.0, 0.80, 1.0, 1.0)}
		]

		for idx in range(rage_x_blades.size()):
			var bcfg: Dictionary = rage_x_blades[idx]
			var pivot := Node3D.new()
			pivot.name = "RMBHexaRageXSlash_%d" % idx
			scene_parent.add_child(pivot)
			pivot.global_position = cross_center
			pivot.rotation = Vector3(0.0, base_yaw, float(bcfg["roll"]))

			var arc_inst := MeshInstance3D.new()
			arc_inst.mesh = build_curved_slash_arc_mesh(float(bcfg["radius"]), float(bcfg["width"]), 160.0, 36)
			arc_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

			var smat := ShaderMaterial.new()
			smat.shader = _get_stylized_slash_shader()
			smat.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
			smat.set_shader_parameter("mid_color", bcfg["mid"])
			smat.set_shader_parameter("edge_color", bcfg["edge"])
			smat.set_shader_parameter("accent_color", bcfg["accent"])
			smat.set_shader_parameter("emission_strength", 9.8)
			smat.set_shader_parameter("core_sharpness", 2.2)
			smat.set_shader_parameter("hold_power", 0.35)
			smat.set_shader_parameter("chromatic_shift", 0.75)
			smat.set_shader_parameter("slash_progress", 0.0)
			arc_inst.material_override = smat
			pivot.add_child(arc_inst)

			var dir_sign: float = float(bcfg["dir"])
			_animate_lingering_power_slash(pivot, arc_inst, smat, 52.0 * dir_sign, -92.0 * dir_sign, 0.54, 1.28, flat_fwd * 0.38)

		# Hoa đăng & Vòng lụa xoáy Đỏ - Xanh Dương
		_spawn_kenney_star_flare_burst(
			tree, cross_center + flat_fwd * 0.75, 3.8,
			Color(1.0, 0.08, 0.20, 1.0), Color(0.0, 0.45, 1.0, 1.0), 0.35
		)
		_spawn_prismatic_cyclone_ring_ribbon(
			tree, ground_pos, 0.5, 3.4, 0.65,
			Color(1,1,1,1), Color(1.0, 0.04, 0.14, 1), Color(0.0, 0.40, 1.0, 1), Color(0.0, 0.9, 1.0, 1),
			15.0, 0.42, "RMBRageCycloneRing"
		)

		var sigil := Decal.new()
		sigil.name = "RMBRageDecal"
		var stex := _load_cached_tex("res://assets/vfx_textures/kenney_particles/circle_04.png")
		if stex:
			sigil.texture_albedo = stex
			sigil.texture_emission = stex
		sigil.modulate = Color(1.0, 0.10, 0.25, 0.95)
		sigil.emission_energy = 6.5
		sigil.size = Vector3(4.2, 3.0, 4.2)
		scene_parent.add_child(sigil)
		sigil.global_position = ground_pos
		var s_tw := sigil.create_tween()
		s_tw.set_parallel(true)
		s_tw.tween_property(sigil, "rotation:y", deg_to_rad(140.0), 0.65)
		s_tw.tween_property(sigil, "modulate:a", 0.0, 0.35).set_delay(0.30)
		s_tw.chain().tween_callback(sigil.queue_free)
		return null

	# =========================================================================
	# LỚP 1 & 2: TỨ KIẾM KHÍ CHỮ X ĐA SẮC (2 LƯỠI HOÀNG KIM + 2 LƯỠI CỰC QUANG)
	# =========================================================================
	var x_blades := [
		# Cặp Chéo Chính (+42° và -42°): Thái Dương Hoàng Kim - Đỏ Hồng Ngọc
		{"roll": deg_to_rad(42.0), "radius": 2.35, "width": 0.85, "core": Color(1,1,1,1), "mid": Color(1.0, 0.90, 0.15, 1), "edge": Color(1.0, 0.15, 0.05, 1), "accent": Color(1.0, 0.0, 0.65, 1), "emission": 9.5},
		{"roll": deg_to_rad(-42.0), "radius": 2.35, "width": 0.85, "core": Color(1,1,1,1), "mid": Color(1.0, 0.90, 0.15, 1), "edge": Color(1.0, 0.15, 0.05, 1), "accent": Color(1.0, 0.0, 0.65, 1), "emission": 9.5},
		# Cặp Chéo Phụ (+56° và -56°): Băng Lôi Điện Quang - Tím Tinh Vân
		{"roll": deg_to_rad(56.0), "radius": 2.60, "width": 0.68, "core": Color(1,1,1,1), "mid": Color(0.0, 0.96, 1.0, 1), "edge": Color(0.62, 0.0, 1.0, 1), "accent": Color(1.0, 0.2, 0.75, 1), "emission": 8.5},
		{"roll": deg_to_rad(-56.0), "radius": 2.60, "width": 0.68, "core": Color(1,1,1,1), "mid": Color(0.0, 0.96, 1.0, 1), "edge": Color(0.62, 0.0, 1.0, 1), "accent": Color(1.0, 0.2, 0.75, 1), "emission": 8.5}
	]

	for idx in range(x_blades.size()):
		var bcfg: Dictionary = x_blades[idx]
		var pivot := Node3D.new()
		pivot.name = "RMBQuadXSlashPivot_%d" % idx
		scene_parent.add_child(pivot)
		pivot.global_position = cross_center
		pivot.rotation = Vector3(0.0, base_yaw, float(bcfg["roll"]))

		var arc_inst := MeshInstance3D.new()
		arc_inst.mesh = build_curved_slash_arc_mesh(float(bcfg["radius"]), float(bcfg["width"]), 160.0, 36)
		arc_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var smat := ShaderMaterial.new()
		smat.shader = _get_stylized_slash_shader()
		smat.set_shader_parameter("core_color", bcfg["core"])
		smat.set_shader_parameter("mid_color", bcfg["mid"])
		smat.set_shader_parameter("edge_color", bcfg["edge"])
		smat.set_shader_parameter("accent_color", bcfg["accent"])
		smat.set_shader_parameter("emission_strength", float(bcfg["emission"]))
		smat.set_shader_parameter("chromatic_shift", 0.75)
		smat.set_shader_parameter("slash_progress", 0.0)
		arc_inst.material_override = smat
		pivot.add_child(arc_inst)

		var dir_sign := 1.0 if (idx % 2 == 0) else -1.0
		var dur := 0.28 + float(idx) * 0.02
		var tw := pivot.create_tween()
		tw.set_parallel(true)
		tw.tween_property(arc_inst, "rotation:y", dir_sign * deg_to_rad(-92.0), dur).from(dir_sign * deg_to_rad(52.0)).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(val: float):
			if is_instance_valid(smat):
				smat.set_shader_parameter("slash_progress", val)
		, 0.0, 1.0, dur)
		tw.chain().tween_callback(pivot.queue_free)

	# =========================================================================
	# LỚP 3: NGÔI SAO CHỚP SÁNG KENNEY & VÒNG LỤA XOÁY TẠI TÂM CHỮ X
	# =========================================================================
	_spawn_kenney_star_flare_burst(
		tree, cross_center + flat_fwd * 0.65, 3.4,
		Color(1.0, 0.95, 0.4, 1.0), Color(0.2, 0.95, 1.0, 1.0), 0.28
	)
	_spawn_prismatic_cyclone_ring_ribbon(
		tree, ground_pos, 0.5, 2.9, 0.55,
		Color(1,1,1,1), Color(1.0, 0.88, 0.2, 1), Color(1.0, 0.15, 0.5, 1), Color(0.0, 0.9, 1.0, 1),
		14.0, 0.32
	)

	# =========================================================================
	# LỚP 4: ẤN CHÚ THẬP TỰ QUANG DƯỚI MẶT ĐẤT (KENNEY CIRCLE_04 DECAL)
	# =========================================================================
	var sigil := Decal.new()
	var stex := _load_cached_tex("res://assets/vfx_textures/kenney_particles/circle_04.png")
	if stex:
		sigil.texture_albedo = stex
		sigil.texture_emission = stex
	sigil.modulate = Color(1.0, 0.65, 0.15, 0.95)
	sigil.emission_energy = 6.2
	sigil.size = Vector3(3.6, 3.0, 3.6)
	scene_parent.add_child(sigil)
	sigil.global_position = ground_pos
	var s_tw := sigil.create_tween()
	s_tw.set_parallel(true)
	s_tw.tween_property(sigil, "rotation:y", deg_to_rad(120.0), 0.50)
	s_tw.tween_property(sigil, "modulate:a", 0.0, 0.50)
	s_tw.chain().tween_callback(sigil.queue_free)

	return null

## Chiêu [I / RMB] Pha 2: Đại Sóng Kiếm Khí Càn Quét Mặt Đất (Directive 25 & Directive 26)
static func spawn_rmb_traveling_crescent_wave(
	tree: SceneTree,
	origin: Vector3,
	forward_dir: Vector3,
	travel_distance: float = 4.8,
	travel_speed: float = 18.0,
	wave_damage: float = 30.0,
	is_rage: bool = false
) -> Node3D:
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	var scene_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if scene_parent == null:
		return null

	if is_rage:
		travel_distance = 6.2
		wave_damage = 44.0

	var flat_fwd := Vector3(forward_dir.x, 0.0, forward_dir.z).normalized()
	if flat_fwd.length_squared() < 0.001:
		flat_fwd = Vector3.FORWARD
	var base_yaw := atan2(flat_fwd.x, flat_fwd.z)
	var start_pos := _snap_vfx_to_ground(tree, origin + flat_fwd * 0.9)

	var wave_root := Node3D.new()
	wave_root.name = "RMBFiveWingRageWave3D" if is_rage else "RMBPrismaticTripleWave3D"
	scene_parent.add_child(wave_root)
	wave_root.global_position = start_pos
	wave_root.rotation.y = base_yaw

	# =========================================================================
	# KẾT CẤU CÁNH LỤA CONG: 5 CÁNH NẾU NỘ / 3 CÁNH NẾU MẶC ĐỊNH
	# =========================================================================
	var wing_specs: Array = []
	if is_rage:
		wing_specs = [
			# 1. Cánh Trung Tâm Dựng Đứng 84°: Đỏ Huyết (#FF0824)
			{"roll": deg_to_rad(84.0), "pitch": deg_to_rad(-12.0), "radius": 2.05, "width": 1.05, "y_off": 0.95, "x_off": 0.0, "core": Color(1,1,1,1), "mid": Color(1.0, 0.03, 0.14, 1), "edge": Color(0.72, 0.0, 0.07, 1), "accent": Color(1.0, 0.35, 0.0, 1)},
			# 2. Cánh Nội Trái +32°: Xanh Dương Điện Quang (#0055FF -> #00E5FF)
			{"roll": deg_to_rad(32.0), "pitch": deg_to_rad(-6.0), "radius": 2.20, "width": 0.85, "y_off": 0.65, "x_off": -0.35, "core": Color(1,1,1,1), "mid": Color(0.0, 0.33, 1.0, 1), "edge": Color(0.0, 0.12, 0.70, 1), "accent": Color(0.0, 0.90, 1.0, 1)},
			# 3. Cánh Nội Phải -32°: Xanh Dương Điện Quang (#0055FF -> #00E5FF)
			{"roll": deg_to_rad(-32.0), "pitch": deg_to_rad(-6.0), "radius": 2.20, "width": 0.85, "y_off": 0.65, "x_off": 0.35, "core": Color(1,1,1,1), "mid": Color(0.0, 0.33, 1.0, 1), "edge": Color(0.0, 0.12, 0.70, 1), "accent": Color(0.0, 0.90, 1.0, 1)},
			# 4. Cánh Đại Bàng Ngoài Trái +58°: Đỏ Huyết Viền Lam (#FF1122 -> #0044FF)
			{"roll": deg_to_rad(58.0), "pitch": deg_to_rad(-8.0), "radius": 2.45, "width": 0.80, "y_off": 0.50, "x_off": -0.65, "core": Color(1,1,1,1), "mid": Color(1.0, 0.07, 0.13, 1), "edge": Color(0.65, 0.0, 0.06, 1), "accent": Color(0.0, 0.27, 1.0, 1)},
			# 5. Cánh Đại Bàng Ngoài Phải -58°: Đỏ Huyết Viền Lam (#FF1122 -> #0044FF)
			{"roll": deg_to_rad(-58.0), "pitch": deg_to_rad(-8.0), "radius": 2.45, "width": 0.80, "y_off": 0.50, "x_off": 0.65, "core": Color(1,1,1,1), "mid": Color(1.0, 0.07, 0.13, 1), "edge": Color(0.65, 0.0, 0.06, 1), "accent": Color(0.0, 0.27, 1.0, 1)}
		]
	else:
		wing_specs = [
			# Lưỡi Trung Tâm (Dựng đứng 82° - Hoàng Kim & Đỏ Lửa)
			{"roll": deg_to_rad(82.0), "pitch": deg_to_rad(-12.0), "radius": 1.65, "width": 0.95, "y_off": 0.95, "x_off": 0.0, "core": Color(1,1,1,1), "mid": Color(1.0, 0.88, 0.15, 1), "edge": Color(1.0, 0.18, 0.02, 1), "accent": Color(1.0, 0.0, 0.7, 1)},
			# Cánh Phượng Hoàng Bên Trái (Mở nghiêng +36° - Xanh Băng & Hồng Tím)
			{"roll": deg_to_rad(36.0), "pitch": deg_to_rad(-6.0), "radius": 1.85, "width": 0.78, "y_off": 0.65, "x_off": 0.0, "core": Color(1,1,1,1), "mid": Color(0.0, 0.96, 1.0, 1), "edge": Color(0.75, 0.0, 1.0, 1), "accent": Color(1.0, 0.25, 0.65, 1)},
			# Cánh Phượng Hoàng Bên Phải (Mở nghiêng -36° - Hồng Cực Quang & Lam Sét)
			{"roll": deg_to_rad(-36.0), "pitch": deg_to_rad(-6.0), "radius": 1.85, "width": 0.78, "y_off": 0.65, "x_off": 0.0, "core": Color(1,1,1,1), "mid": Color(1.0, 0.22, 0.75, 1), "edge": Color(0.0, 0.55, 1.0, 1), "accent": Color(1.0, 0.9, 0.15, 1)}
		]

	var wave_mats: Array[ShaderMaterial] = []
	for w in wing_specs:
		var wing_inst := MeshInstance3D.new()
		wing_inst.mesh = build_curved_slash_arc_mesh(float(w["radius"]), float(w["width"]), 150.0, 36)
		wing_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wing_inst.position = Vector3(float(w.get("x_off", 0.0)), float(w["y_off"]), 0.0)
		wing_inst.rotation = Vector3(float(w["pitch"]), deg_to_rad(-90.0), float(w["roll"]))

		var wmat := ShaderMaterial.new()
		wmat.shader = _get_stylized_slash_shader()
		wmat.set_shader_parameter("core_color", w["core"])
		wmat.set_shader_parameter("mid_color", w["mid"])
		wmat.set_shader_parameter("edge_color", w["edge"])
		wmat.set_shader_parameter("accent_color", w["accent"])
		wmat.set_shader_parameter("emission_strength", 9.8 if is_rage else 9.0)
		wmat.set_shader_parameter("core_sharpness", 2.2 if is_rage else 1.65)
		wmat.set_shader_parameter("hold_power", 0.35 if is_rage else 0.25)
		wmat.set_shader_parameter("chromatic_shift", 0.80)
		wmat.set_shader_parameter("slash_progress", 0.0)
		wing_inst.material_override = wmat
		wave_root.add_child(wing_inst)
		wave_mats.append(wmat)

	# =========================================================================
	# LUỒNG HẠT & ĐÈN OMNILIGHT3D BÁM ĐUÔI SÓNG KIẾM
	# =========================================================================
	var wake_particles := GPUParticles3D.new()
	wake_particles.amount = 40 if is_rage else 32
	wake_particles.lifetime = 0.35 if is_rage else 0.30
	wake_particles.draw_pass_1 = get_safe_particle_quad_mesh(Vector2(0.42, 0.42) if is_rage else Vector2(0.38, 0.38))
	var wp_mat := ParticleProcessMaterial.new()
	wp_mat.direction = Vector3(0.0, 0.4, -1.0)
	wp_mat.spread = 42.0
	wp_mat.initial_velocity_min = 4.5 if is_rage else 4.0
	wp_mat.initial_velocity_max = 9.5 if is_rage else 8.5
	wp_mat.gravity = Vector3(0.0, -5.0, 0.0)
	wp_mat.color_ramp = _get_rage_crimson_cobalt_ramp() if is_rage else _get_prismatic_color_ramp()
	wake_particles.process_material = wp_mat

	var wp_draw := StandardMaterial3D.new()
	wp_draw.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wp_draw.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	wp_draw.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wp_draw.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	wp_draw.vertex_color_use_as_albedo = true
	var ftex := _load_cached_tex("res://assets/vfx_textures/kenney_particles/spark_05.png")
	if ftex:
		wp_draw.albedo_texture = ftex
	wp_draw.emission_enabled = true
	wp_draw.emission = Color(1.0, 0.25, 0.45) if is_rage else Color(1.0, 0.8, 0.9)
	wp_draw.emission_energy_multiplier = 4.5 if is_rage else 4.0
	wake_particles.material_override = wp_draw
	wake_particles.position = Vector3(0.0, 0.55, 0.0)
	wave_root.add_child(wake_particles)

	var wave_light := OmniLight3D.new()
	wave_light.shadow_enabled = false
	wave_light.omni_range = 6.8 if is_rage else 5.5
	wave_light.light_color = Color(1.0, 0.20, 0.35) if is_rage else Color(1.0, 0.72, 0.35)
	wave_light.light_energy = 5.8 if is_rage else 5.0
	wave_light.position = Vector3(0.0, 0.85, 0.0)
	wave_root.add_child(wave_light)

	# =========================================================================
	# HÀNH TRÌNH CÀY ĐẤT, QUÉT SÁT THƯƠNG BOT & LINGERING FINALE ANCHOR
	# =========================================================================
	var duration := maxf(0.18, travel_distance / maxf(1.0, travel_speed))
	var hit_enemies: Dictionary = {}
	var state := {"dist": 0.0, "next_rupture": 0.70}

	var tw := wave_root.create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_method(func(t: float):
		if not is_instance_valid(wave_root):
			return
		var cur_dist := t * travel_distance
		var flat_pos := start_pos + flat_fwd * cur_dist
		var snapped := _snap_vfx_to_ground(tree, flat_pos)
		wave_root.global_position = snapped

		# Quét sát thương thực tế lên mọi Bot nằm trên đường sóng kiếm càn lướt qua
		var candidate_nodes: Array[Node] = []
		for grp in ["enemies", "enemy"]:
			for node in tree.get_nodes_in_group(grp):
				if is_instance_valid(node) and not candidate_nodes.has(node):
					candidate_nodes.append(node)

		for enemy in candidate_nodes:
			if is_instance_valid(enemy) and not hit_enemies.has(enemy.get_instance_id()):
				var d_xz := Vector2(enemy.global_position.x - snapped.x, enemy.global_position.z - snapped.z).length()
				var d_y := absf(enemy.global_position.y - snapped.y)
				if d_xz <= (2.85 if is_rage else 2.35) and d_y <= 2.2:
					hit_enemies[enemy.get_instance_id()] = true
					if enemy.has_method("take_hit"):
						enemy.take_hit(wave_damage, flat_fwd * (2.8 if is_rage else 2.2), 0.70 if is_rage else 0.65)
					elif enemy.has_method("take_damage"):
						enemy.take_damage(wave_damage, flat_fwd)
					if enemy.has_method("apply_knockback"):
						enemy.apply_knockback(flat_fwd * (13.5 if is_rage else 11.0))
					if enemy.has_method("apply_hit_stun"):
						enemy.apply_hit_stun(0.70 if is_rage else 0.65)
					spawn_hit_sparks(tree, enemy.global_position + Vector3(0.0, 1.0, 0.0), flat_fwd)

		# Cứ mỗi 0.90m sóng kiếm đi qua -> Bung vòng lụa xoáy + Ấn chú cháy dưới đất
		if cur_dist >= float(state["next_rupture"]):
			state["next_rupture"] = float(state["next_rupture"]) + (0.90 if is_rage else 0.95)
			if is_rage:
				_spawn_prismatic_cyclone_ring_ribbon(
					tree, snapped, 0.40, 2.35, 0.45,
					Color(1,1,1,1), Color(1.0, 0.04, 0.14, 1), Color(0.0, 0.45, 1.0, 1), Color(0.0, 0.9, 1.0, 1),
					16.0, 0.35, "RMBRagePathRing"
				)
			else:
				_spawn_prismatic_cyclone_ring_ribbon(
					tree, snapped, 0.35, 1.95, 0.38,
					Color(1,1,1,1), Color(1.0, 0.85, 0.2, 1), Color(1.0, 0.15, 0.55, 1), Color(0.0, 0.9, 1.0, 1),
					15.0, 0.26
				)
			var step_dec := Decal.new()
			var dtex := _load_cached_tex("res://assets/vfx_textures/kenney_particles/scorch_02.png")
			if dtex:
				step_dec.texture_albedo = dtex
				step_dec.texture_emission = dtex
			step_dec.modulate = Color(1.0, 0.12, 0.20, 0.92) if is_rage else Color(1.0, 0.45, 0.15, 0.88)
			step_dec.emission_energy = 5.5 if is_rage else 4.5
			step_dec.size = Vector3(2.6, 2.6, 2.6) if is_rage else Vector3(2.2, 2.4, 2.2)
			scene_parent.add_child(step_dec)
			step_dec.global_position = snapped
			var dtw := step_dec.create_tween()
			dtw.tween_property(step_dec, "modulate:a", 0.0, 0.85 if is_rage else 0.65).set_delay(0.35)
			dtw.tween_callback(step_dec.queue_free)

		if not is_rage and t > 0.72:
			var fade_val := (t - 0.72) / 0.28
			for wm in wave_mats:
				if is_instance_valid(wm):
					wm.set_shader_parameter("slash_progress", fade_val)
	, 0.0, 1.0, duration)

	# =========================================================================
	# ĐẠI TINH VÂN BÙNG NỔ CUỐI HÀNH TRÌNH (LINGERING FINALE ANCHOR KHI NỘ)
	# =========================================================================
	if is_rage:
		# Đọng lại tại điểm cuối 6.2m thêm 0.35s và phình to 1.35x trước khi nổ
		tw.chain().set_parallel(true)
		tw.tween_property(wave_root, "scale", Vector3.ONE * 1.35, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(v: float):
			for wm in wave_mats:
				if is_instance_valid(wm):
					wm.set_shader_parameter("slash_progress", v)
		, 0.0, 0.45, 0.35)
		tw.chain().tween_callback(func():
			if is_instance_valid(wave_root):
				var end_pos := wave_root.global_position
				KayKitAudioDirector.play_sfx("i_wave_finale")
				_spawn_prismatic_cyclone_ring_ribbon(
					tree, end_pos, 0.6, 3.8, 0.75,
					Color(1,1,1,1), Color(1.0, 0.04, 0.14, 1), Color(0.0, 0.45, 1.0, 1), Color(0.0, 0.9, 1.0, 1),
					18.0, 0.45, "RMBRageNovaRing"
				)
				_spawn_kenney_star_flare_burst(
					tree, end_pos + Vector3(0.0, 0.75, 0.0), 3.8,
					Color(1.0, 0.1, 0.25, 1.0), Color(0.0, 0.5, 1.0, 1.0), 0.35
				)
				wave_root.queue_free()
		)
	else:
		tw.tween_callback(func():
			if is_instance_valid(wave_root):
				var end_pos := wave_root.global_position
				KayKitAudioDirector.play_sfx("i_wave_finale")
				_spawn_prismatic_cyclone_ring_ribbon(
					tree, end_pos, 0.5, 3.1, 0.60,
					Color(1,1,1,1), Color(0.0, 0.95, 1.0, 1), Color(1.0, 0.15, 0.75, 1), Color(1.0, 0.88, 0.15, 1),
					16.0, 0.36
				)
				_spawn_kenney_star_flare_burst(
					tree, end_pos + Vector3(0.0, 0.65, 0.0), 3.0,
					Color(1.0, 0.9, 0.3, 1.0), Color(0.85, 0.2, 1.0, 1.0), 0.28
				)
				wave_root.queue_free()
		)

	return wave_root

## Chiêu 3: Tuyệt chiêu Q — Song Long Lốc Xoáy 360° (Task 20.4 Chiêu Q & Directive 26)
static func spawn_whirlwind_360_vfx(
	hero_node: Node3D,
	arg2 = null,
	arg3 = null
) -> void:
	if not is_instance_valid(hero_node):
		return
	var parent_node: Node = null
	var is_rage: bool = false
	if arg2 is bool:
		is_rage = arg2
		parent_node = arg3 as Node
	elif arg2 is Node:
		parent_node = arg2
		if arg3 is bool:
			is_rage = arg3

	var p := _get_root_parent(parent_node)
	if p == null:
		return

	var vortex_root := Node3D.new()
	vortex_root.name = "WhirlwindVortexFX"
	hero_node.add_child(vortex_root)
	vortex_root.position = Vector3(0.0, 0.85, 0.0)

	var scale_mult := 1.30 if is_rage else 1.0

	# --- VÒNG 1: Đỏ Huyết nếu Nộ / Xanh Băng nếu thường ---
	var ring1_pivot := Node3D.new()
	ring1_pivot.name = "WhirlwindRing1Pivot"
	ring1_pivot.rotation.x = deg_to_rad(14.0)
	vortex_root.add_child(ring1_pivot)

	var ring1_mesh := MeshInstance3D.new()
	ring1_mesh.name = "WhirlwindArc1"
	ring1_mesh.mesh = build_curved_slash_arc_mesh(1.1 * scale_mult, 3.1 * scale_mult, 340.0, 36, 0.25)
	ring1_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var smat1 := ShaderMaterial.new()
	smat1.shader = _get_slash_shader()
	smat1.set_shader_parameter("slash_mask_tex", _get_tex("slash_01.png"))
	smat1.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
	smat1.set_shader_parameter("main_color", Color(1.0, 0.04, 0.14, 1.0) if is_rage else Color(0.0, 0.85, 1.0, 1.0))
	smat1.set_shader_parameter("edge_color", Color(0.70, 0.0, 0.08, 1.0) if is_rage else Color(1.0, 0.45, 0.05, 1.0))
	smat1.set_shader_parameter("emission_boost", 5.5 if is_rage else 4.2)
	smat1.set_shader_parameter("core_sharpness", 2.2 if is_rage else 1.65)
	smat1.set_shader_parameter("progress", 0.1)
	ring1_mesh.material_override = smat1
	ring1_pivot.add_child(ring1_mesh)

	# --- VÒNG 2: Xanh Dương nếu Nộ / Cam Lửa nếu thường ---
	var ring2_pivot := Node3D.new()
	ring2_pivot.name = "WhirlwindRing2Pivot"
	ring2_pivot.rotation.x = deg_to_rad(-14.0)
	ring2_pivot.rotation.y = PI
	vortex_root.add_child(ring2_pivot)

	var ring2_mesh := MeshInstance3D.new()
	ring2_mesh.name = "WhirlwindArc2"
	ring2_mesh.mesh = build_curved_slash_arc_mesh(1.1 * scale_mult, 3.1 * scale_mult, 340.0, 36, -0.25)
	ring2_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var smat2 := ShaderMaterial.new()
	smat2.shader = _get_slash_shader()
	smat2.set_shader_parameter("slash_mask_tex", _get_tex("slash_01.png"))
	smat2.set_shader_parameter("core_color", Color(1.0, 0.96, 0.84, 1.0))
	smat2.set_shader_parameter("main_color", Color(0.0, 0.42, 1.0, 1.0) if is_rage else Color(1.0, 0.53, 0.0, 1.0))
	smat2.set_shader_parameter("edge_color", Color(0.0, 0.15, 0.80, 1.0) if is_rage else Color(0.90, 0.12, 0.16, 1.0))
	smat2.set_shader_parameter("emission_boost", 5.5 if is_rage else 4.2)
	smat2.set_shader_parameter("core_sharpness", 2.2 if is_rage else 1.65)
	smat2.set_shader_parameter("progress", 0.1)
	ring2_mesh.material_override = smat2
	ring2_pivot.add_child(ring2_mesh)

	# --- Trận Pháp Kép Dưới Chân ---
	var decal1 := Decal.new()
	decal1.name = "WhirlwindDecal1"
	decal1.position = Vector3(0.0, -0.75, 0.0)
	decal1.size = Vector3(6.5 * scale_mult, 2.5, 6.5 * scale_mult)
	decal1.texture_albedo = _get_tex("circle_05.png")
	decal1.modulate = Color(1.0, 0.08, 0.2, 0.85) if is_rage else Color(0.0, 0.8, 1.0, 0.8)
	vortex_root.add_child(decal1)

	var decal2 := Decal.new()
	decal2.name = "WhirlwindDecal2"
	decal2.position = Vector3(0.0, -0.72, 0.0)
	decal2.size = Vector3(5.8 * scale_mult, 2.5, 5.8 * scale_mult)
	decal2.texture_albedo = _get_tex("twirl_03.png")
	decal2.modulate = Color(0.0, 0.45, 1.0, 0.85) if is_rage else Color(1.0, 0.6, 0.1, 0.8)
	vortex_root.add_child(decal2)

	# Luồng hạt tia lửa xoáy từ chân lên đầu
	var vortex_sparks := GPUParticles3D.new()
	vortex_sparks.name = "WhirlwindSparks"
	vortex_sparks.amount = 40 if is_rage else 30
	vortex_sparks.lifetime = 0.38 if is_rage else 0.35
	vortex_sparks.local_coords = false

	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pmat.emission_ring_axis = Vector3(0, 1, 0)
	pmat.emission_ring_radius = 2.4 * scale_mult
	pmat.emission_ring_inner_radius = 1.0
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 35.0
	pmat.initial_velocity_min = 3.5
	pmat.initial_velocity_max = 7.5
	pmat.gravity = Vector3(0, 2.0, 0)
	pmat.scale_min = 0.25
	pmat.scale_max = 0.55
	pmat.color_ramp = _get_rage_crimson_cobalt_ramp() if is_rage else _get_prismatic_color_ramp()
	vortex_sparks.process_material = pmat

	var draw_mat := _create_additive_particle_mat(_get_tex("spark_01.png"), Color(1.0, 0.4, 0.5, 1.0) if is_rage else Color(1.0, 0.8, 0.3, 1.0))
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

## Chiêu 4: Bom Khói 3D phím E — Vùng Khói Lôi Vụ (Task 21.1 & Directive 26 Bom Huyết Lôi)
static func spawn_smoke_bomb_hazard_zone(
	parent_node: Node,
	start_pos: Vector3,
	target_pos: Vector3,
	is_rage: bool = false
) -> Node3D:
	var p := _get_root_parent(parent_node)
	if p == null:
		return null

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

	# Đuôi sáng màu Đỏ-Xanh nếu Nộ / Tím Ngọc nếu thường
	var trail := GPUParticles3D.new()
	trail.name = "BombTrail"
	trail.amount = 18 if is_rage else 16
	trail.lifetime = 0.24 if is_rage else 0.22
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

	var tmat := _create_additive_particle_mat(_get_tex("magic_03.png"), Color(1.0, 0.15, 0.30, 0.9) if is_rage else Color(0.7, 0.3, 1.0, 0.9))
	var qmesh := get_safe_particle_quad_mesh(Vector2(0.35, 0.35))
	qmesh.surface_set_material(0, tmat)
	trail.draw_pass_1 = qmesh
	proj.add_child(trail)
	trail.emitting = true

	# Bay theo đường parabol (fly_time = 0.22s theo Task 21.1)
	var fly_time := 0.22
	var mid_pos := (start_pos + target_pos) * 0.5
	mid_pos.y += 2.2

	var tween := proj.create_tween()
	tween.tween_property(proj, "global_position", mid_pos, fly_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(proj, "global_position", target_pos, fly_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_detonate_smoke_hazard_zone(p, target_pos, is_rage)
		proj.queue_free()
	)
	return proj

static func spawn_smoke_bomb_3d(
	parent_node: Node,
	start_pos: Vector3,
	target_pos: Vector3,
	is_rage: bool = false
) -> void:
	spawn_smoke_bomb_hazard_zone(parent_node, start_pos, target_pos, is_rage)

## Kích nổ 4 lớp liên hoàn + Vùng Khói Lôi Vụ DoT & Slow (Task 21.1 & Task 26.2 Bom Huyết Lôi)
static func _detonate_smoke_hazard_zone(parent: Node, pos: Vector3, is_rage: bool = false) -> void:
	KayKitAudioDirector.play_sfx("p_bomb_thunder_explode")
	var burst_dmg := 30.0 if is_rage else 20.0
	var dot_dmg := 12.0 if is_rage else 8.0

	# 1. Sát thương nổ tức thì cho các Bot trong bán kính 3.2m
	var tree := parent.get_tree()
	if tree != null:
		var enemies := tree.get_nodes_in_group("enemies")
		for bot in enemies:
			if is_instance_valid(bot) and bot is Node3D:
				var b_node := bot as Node3D
				var flat_dist := Vector2(b_node.global_position.x - pos.x, b_node.global_position.z - pos.z).length()
				var y_diff := absf(b_node.global_position.y - pos.y)
				if flat_dist <= 3.2 and y_diff <= 1.8:
					if bot.has_method("take_damage"):
						var kb: Vector3 = (b_node.global_position - pos).normalized()
						bot.take_damage(burst_dmg, kb)
					elif bot.has_method("take_dot_damage"):
						bot.take_dot_damage(burst_dmg, Color(1.0, 0.15, 0.3) if is_rage else Color(0.85, 0.35, 1.0))

	# 2. Lớp chớp sáng tâm nổ
	var flash_sprite := Sprite3D.new()
	flash_sprite.name = "SmokeDetonationFlash"
	flash_sprite.texture = _get_tex("light_02.png")
	flash_sprite.modulate = Color(1.0, 0.10, 0.25, 1.0) if is_rage else Color(0.85, 0.35, 1.0, 1.0)
	flash_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flash_sprite.no_depth_test = true
	flash_sprite.pixel_size = 0.012
	parent.add_child(flash_sprite)
	flash_sprite.global_position = pos + Vector3(0.0, 0.8, 0.0)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.15, 0.30) if is_rage else Color(0.8, 0.3, 1.0)
	light.light_energy = 5.5 if is_rage else 4.5
	light.omni_range = 6.2 if is_rage else 5.5
	parent.add_child(light)
	light.global_position = pos + Vector3(0.0, 0.8, 0.0)

	var tw_flash := flash_sprite.create_tween().set_parallel(true)
	tw_flash.tween_property(flash_sprite, "scale", Vector3(2.8, 2.8, 2.8) if is_rage else Vector3(2.5, 2.5, 2.5), 0.35)
	tw_flash.tween_property(flash_sprite, "modulate:a", 0.0, 0.35)
	tw_flash.tween_property(light, "light_energy", 0.0, 0.35)
	tw_flash.chain().tween_callback(flash_sprite.queue_free)
	tw_flash.parallel().tween_callback(light.queue_free)

	# 3. VÙNG KHÓI LÔI VỤ HAZARD ZONE (4.0s, Bán kính 3.2m)
	var hazard_root := Node3D.new()
	hazard_root.name = "ThunderSmokeHazardZone"
	parent.add_child(hazard_root)
	hazard_root.global_position = pos

	# Decal cổ ngữ
	var ground_decal := Decal.new()
	ground_decal.name = "SmokeRuneDecal"
	ground_decal.size = Vector3(6.4, 3.0, 6.4)
	ground_decal.texture_albedo = _get_tex("circle_04.png")
	ground_decal.modulate = Color(1.0, 0.08, 0.20, 0.88) if is_rage else Color(0.65, 0.25, 1.0, 0.85)
	hazard_root.add_child(ground_decal)
	ground_decal.position = Vector3(0.0, 0.15, 0.0)

	# Khói
	var smoke := GPUParticles3D.new()
	smoke.name = "SmokeCloudZone"
	smoke.amount = 36 if is_rage else 32
	smoke.lifetime = 2.0
	smoke.explosiveness = 0.75
	smoke.local_coords = false

	var spmat := ParticleProcessMaterial.new()
	spmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spmat.emission_sphere_radius = 2.8
	spmat.direction = Vector3(0, 1, 0)
	spmat.spread = 70.0
	spmat.initial_velocity_min = 1.0
	spmat.initial_velocity_max = 2.5
	spmat.gravity = Vector3(0, 0.15, 0)
	spmat.damping_min = 1.5
	spmat.damping_max = 3.0
	spmat.scale_min = 0.8
	spmat.scale_max = 1.8
	smoke.process_material = spmat

	var smat := _create_additive_particle_mat(_get_tex("smoke_04.png"), Color(0.60, 0.04, 0.12, 0.75) if is_rage else Color(0.42, 0.15, 0.55, 0.75))
	var qmesh := get_safe_particle_quad_mesh(Vector2(1.2, 1.2))
	qmesh.surface_set_material(0, smat)
	smoke.draw_pass_1 = qmesh
	hazard_root.add_child(smoke)
	smoke.position = Vector3(0.0, 0.5, 0.0)
	smoke.emitting = true

	# Tia sét giật trong khói
	var thunder := GPUParticles3D.new()
	thunder.name = "SmokeThunderSparks"
	thunder.amount = 28 if is_rage else 24
	thunder.lifetime = 0.35
	thunder.local_coords = false

	var th_pmat := ParticleProcessMaterial.new()
	th_pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	th_pmat.emission_sphere_radius = 2.8
	th_pmat.direction = Vector3(0, 1, 0)
	th_pmat.spread = 180.0
	th_pmat.initial_velocity_min = 2.0
	th_pmat.initial_velocity_max = 4.5
	th_pmat.scale_min = 0.25
	th_pmat.scale_max = 0.55
	thunder.process_material = th_pmat

	var th_mat := _create_additive_particle_mat(_get_tex("spark_06.png"), Color(0.0, 0.55, 1.0, 1.0) if is_rage else Color(0.7, 0.5, 1.0, 1.0))
	var th_mesh := get_safe_particle_quad_mesh(Vector2(0.5, 0.5))
	th_mesh.surface_set_material(0, th_mat)
	thunder.draw_pass_1 = th_mesh
	hazard_root.add_child(thunder)
	thunder.position = Vector3(0.0, 0.8, 0.0)
	thunder.emitting = true

	# Vòng lặp 8 nhịp (mỗi 0.5s trong 4.0s)
	var zone_tween := hazard_root.create_tween()
	for tick in range(8):
		zone_tween.tween_interval(0.5)
		zone_tween.tween_callback(func():
			if not is_instance_valid(hazard_root):
				return
			var current_tree := hazard_root.get_tree()
			if current_tree == null:
				return
			var bots := current_tree.get_nodes_in_group("enemies")
			for bot in bots:
				if not is_instance_valid(bot) or not (bot is Node3D):
					continue
				var b_pos := (bot as Node3D).global_position
				var flat_d := Vector2(b_pos.x - pos.x, b_pos.z - pos.z).length()
				var y_d := absf(b_pos.y - pos.y)
				if flat_d <= 3.2 and y_d <= 1.8:
					if bot.has_method("take_dot_damage"):
						bot.take_dot_damage(dot_dmg, Color(1.0, 0.15, 0.3) if is_rage else Color(0.75, 0.35, 1.0))
					elif bot.has_method("take_damage"):
						bot.take_damage(dot_dmg)
					if bot.has_method("apply_slow_debuff"):
						bot.apply_slow_debuff(0.45, 1.0)
					KayKitAudioDirector.play_sfx("p_bomb_dot_zap", -6.0)
		)

	# Kết thúc 4.0s: Mờ dần decal và hạt rồi dọn dẹp
	zone_tween.tween_property(ground_decal, "modulate:a", 0.0, 0.4)
	zone_tween.tween_callback(func():
		if is_instance_valid(smoke):
			smoke.emitting = false
		if is_instance_valid(thunder):
			thunder.emitting = false
	)
	zone_tween.tween_interval(0.5)
	zone_tween.tween_callback(hazard_root.queue_free)

## Chiêu 5: Vết Chém Chữ Thập X-Slash Khi Trúng Đòn (Task 20.4 Hit Impact & Task 25.5)
static func spawn_cross_slash_hit_impact(
	world_pos: Vector3,
	parent_node: Node = null
) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	spawn_hit_sparks(tree, world_pos, Vector3.UP)

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
