# 👑 CHỈ ĐẠO SỐ 25 TỪ ARGONS: ĐẠI TU HIỆU ỨNG ĐA SẮC SIÊU CẤP (PRISMATIC 3D VFX OVERHAUL) — TẬP TRUNG ĐÒN ĐÁNH THỨ 3 [U/LMB] & TUYỆT KỸ [I/RMB]

- **Người chỉ đạo (Chief Architect):** ARGONS
- **Đơn vị thực thi:** ANTIGRAVITY IDE (`Claude Opus 4.6` / `Gemini 3.8 Flash`)
- **Kho GitHub dự án:** `https://github.com/NhutPham19/GameWizad`
- **Trạng thái nền tảng:** Phase 24 (Golden Master) đang ở trạng thái ổn định nhất (100% PASS).

---

## 🛡️ 4 LUẬT THÉP BẤT DI BẤT DỊCH (ZERO-BUG & ZERO-CRUDE-MESH RULES)

Trước khi sửa bất kỳ dòng code nào, Antigravity **BẮT BUỘC** phải tuân thủ tuyệt đối 4 quy tắc an toàn sau đây:

1. **LUẬT SỐ 1 — CẤM 100% KHỐI HÌNH HỌC THÔ & CẤM AI TỰ VẼ KHỐI ĐA GIÁC THÔ (`0% PRIMITIVE & 0% BLOCKY PROCEDURAL MESHES`):**
   - Nghiêm cấm khởi tạo `BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PlaneMesh`, `PrismMesh`, `TorusMesh`, `QuadMesh` (`primitive_count == 0`).
   - **Nghiêm cấm tự viết code dựng các khối chóp nhọn, gai đá thô, hình hộp, hình nón hay hình trụ đa giác thô kệch!**
   - Mọi hiệu ứng 3D trong Chỉ Đạo Số 25 **CHỈ ĐƯỢC PHÉP** sử dụng:
     - **(A)** Hàm dựng dải lụa kiếm khí cong mượt `build_curved_slash_arc_mesh()` (với `segments = 36` mịn màng) kết hợp shader `vfx_stylized_slash.gdshader`.
     - **(B)** Các file ảnh Texture nghệ thuật vẽ sẵn của **Kenney Particle Pack** trong `res://assets/vfx_textures/kenney_particles/` (`circle_01..05.png`, `slash_01..04.png`, `star_01..09.png`, `spark_01..06.png`, `flame_01..04.png`, `scorch_01..03.png`, `light_01..03.png`) hiển thị qua `Decal`, `GPUParticles3D` và `get_safe_particle_quad_mesh()`.
     - **(C)** Nhân bản trực tiếp lưới `MeshInstance3D` từ mô hình `.glb/.gltf` thật của **KayKit** khi làm bóng mờ tàn ảnh (`Afterimage`).

2. **LUẬT SỐ 2 — BẢO TOÀN 100% VẬT LÝ, CẦU THANG & COOLDOWN CỦA PHASE 24:**
   - **TUYỆT ĐỐI KHÔNG** chỉnh sửa file `src_game/scripts/levels/kaykit_arena_builder.gd` hay `kaykit_multitier_arena.gd`.
   - **TUYỆT ĐỐI KHÔNG** chỉnh sửa logic di chuyển `WASD`, hàm bước cầu thang `_apply_stair_step_up`, `_is_in_stair_walk_corridor`, hay Cooldown Lướt `Space` ($1.0\text{s}$), Cooldown `U - I - O - P` trong `hero_knight_3d.gd`. Chỉ nâng cấp phần hiển thị hiệu ứng (VFX) và rung chấn Camera vi mô.

3. **LUẬT SỐ 3 — CHỐNG LỖI RUNTIME & CHỐNG GIẬT LAG Ở TẦN SỐ QUÉT CAO 165Hz+:**
   - Mọi `Tween` điều khiển hiệu ứng bắt buộc phải gắn trực tiếp vào chính node hiệu ứng đó (`var tw := vfx_node.create_tween()`) thay vì `tree.create_tween()`, để khi chuyển cảnh hoặc hủy node không bao giờ văng lỗi `previously freed instance`.
   - Mọi đèn `OmniLight3D` của hiệu ứng bắt buộc đặt `shadow_enabled = false` để tốn $0.0\text{ms}$ đổ bóng.
   - Toàn bộ Texture và Shader phải được lưu bộ nhớ đệm tĩnh (`static var`) và nạp trước trong `ShaderPrewarmer`.

4. **LUẬT SỐ 4 — BÁM SÁT ĐỊA HÌNH ĐA TẦNG & CẦU THANG (`TERRAIN-SNAPPING RAYCAST`):**
   - Mọi hiệu ứng nổ trên mặt đất, vòng cổ ngữ `Decal` và sóng kiếm khí bay trên đất bắt buộc phải dùng hàm bắn tia Raycast `_snap_vfx_to_ground()` để luôn nằm khít trên mặt sàn Tầng 1 ($Y=0\text{m}$), Tầng 2 ($Y=4\text{m}$), Tầng 3 ($Y=8\text{m}$) hoặc trượt mượt trên mặt dốc cầu thang.

---

## 🌈 TASK 25.1: NÂNG CẤP SHADER KIẾM KHÍ ĐA SẮC 5 TẦNG HDR (`src_game/shaders/vfx_stylized_slash.gdshader`)

Cập nhật toàn bộ nội dung file `src_game/shaders/vfx_stylized_slash.gdshader` bằng phiên bản **Prismatic 5-Stop HDR Overdrive** dưới đây. Shader mới giữ nguyên toàn bộ tên biến `uniform` cũ (đảm bảo tương thích ngược 100%) đồng thời bổ sung dải màu thứ 4 (`accent_color`), hiệu ứng tán sắc Cực Quang dọc lưỡi kiếm (`chromatic_shift`) và hạt tinh tú lấp lánh ở đuôi kiếm:

```glsl
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.85, 0.15, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.2, 0.05, 1.0);
uniform vec4 accent_color : source_color = vec4(0.85, 0.1, 1.0, 1.0);
uniform float emission_strength : hint_range(1.0, 16.0) = 6.5;
uniform float slash_progress : hint_range(0.0, 1.0) = 0.0;
uniform float tail_fade : hint_range(0.1, 2.5) = 0.85;
uniform float chromatic_shift : hint_range(0.0, 1.0) = 0.55;
uniform float dissolve_scale : hint_range(2.0, 40.0) = 15.0;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;

	// Hai lớp sóng năng lượng cuộn ngược chiều dọc theo lưỡi kiếm
	float n1 = value_noise(uv * vec2(dissolve_scale, dissolve_scale * 0.55) - vec2(TIME * 10.5, 0.0));
	float n2 = value_noise(uv * vec2(dissolve_scale * 1.9, dissolve_scale * 1.1) + vec2(TIME * 7.0, TIME * 3.0));
	float energy_flow = mix(n1, n2, 0.5);

	// Độ dày ngang của dải lụa kiếm khí (sáng rực ở sống kiếm, vát mượt ở 2 rìa)
	float radial = 1.0 - abs(uv.y * 2.0 - 1.0);
	radial = pow(clamp(radial, 0.0, 1.0), 0.72);

	// Mặt nạ đầu & đuôi vệt chém kết hợp tiến trình tan biến mượt mà
	float arc_mask = smoothstep(0.0, 0.10, uv.x) * (1.0 - smoothstep(0.84, 1.0, uv.x));
	float fade_curve = clamp(1.0 - slash_progress * (0.60 + (1.0 - uv.x) * tail_fade), 0.0, 1.0);

	float intensity = radial * arc_mask * (0.68 + 0.58 * energy_flow) * fade_curve;

	// Hạt tinh tú lấp lánh dọc theo đuôi kiếm khí
	float sparkle = step(0.85, n2) * smoothstep(0.12, 0.88, radial) * fade_curve;

	// Hòa trộn 4 tầng màu + Tán sắc Cực Quang (Prismatic Iridescence)
	float iridescence = clamp(sin(uv.x * 8.0 - TIME * 11.0 + n1 * 3.14) * 0.5 + 0.5, 0.0, 1.0) * chromatic_shift;
	vec3 outer_blend = mix(edge_color.rgb, accent_color.rgb, iridescence);
	vec3 col = mix(outer_blend, mid_color.rgb, smoothstep(0.20, 0.60, intensity));
	col = mix(col, core_color.rgb, smoothstep(0.64, 0.90, intensity) + sparkle * 0.65);

	float alpha = clamp((intensity * 1.55 + sparkle * 0.85) * core_color.a, 0.0, 1.0);
	ALBEDO = col * emission_strength;
	ALPHA = alpha;
}
```

---

## 🛠️ TASK 25.2: BỔ SUNG HÀM TIỆN ÍCH ĐA SẮC, BÁM ĐỊA HÌNH & RUNG CHẤN TRONG `KayKitVFXManager` (`src_game/scripts/vfx/kaykit_vfx_manager.gd`)

Trong `src_game/scripts/vfx/kaykit_vfx_manager.gd`, hãy đảm bảo có đầy đủ các hàm nền tảng sau (sử dụng 100% `build_curved_slash_arc_mesh`, `get_safe_particle_quad_mesh`, `Decal` và `GPUParticles3D` với Texture Kenney có sẵn):

### 1. Hàm bắn tia Raycast lấy đúng mặt sàn / mặt dốc cầu thang (`_snap_vfx_to_ground`):
```gdscript
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
```

### 2. Hàm tạo `GradientTexture1D` 5 màu Cực Quang cho Hạt (`_get_prismatic_color_ramp`):
```gdscript
static var _cached_prismatic_ramp: GradientTexture1D = null

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
```

### 3. Hàm tạo Vòng Lụa Kiếm Khí Xoáy Ngang Mặt Đất (`_spawn_prismatic_cyclone_ring_ribbon`):
Sử dụng chính hàm `build_curved_slash_arc_mesh` (36 phân đoạn cong mượt, góc quét $330^\circ$) đặt nằm ngang sát mặt đất và xoay tròn tốc độ cao để tạo vòng sóng xung kích lụa 3D mà **không dùng bất kỳ khối thô nào**:
```gdscript
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
	duration: float = 0.36
) -> void:
	if tree == null or tree.current_scene == null:
		return
	var ring_inst := MeshInstance3D.new()
	ring_inst.name = "PrismaticCycloneRibbon3D"
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

	tree.current_scene.add_child(ring_inst)
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
```

### 4. Hàm tạo Hoa Đăng Tinh Tú Kenney 2D/3D Giao Thoa (`_spawn_kenney_star_flare_burst`):
Sử dụng 2 mặt phẳng Quad (`get_safe_particle_quad_mesh`) gắn Texture ngôi sao sáng **`star_07.png` / `light_01.png`** của Kenney xoay ngược chiều nhau:
```gdscript
static func _spawn_kenney_star_flare_burst(
	tree: SceneTree,
	pos: Vector3,
	flare_scale: float = 2.4,
	color_a: Color = Color(1.0, 0.92, 0.35, 1.0),
	color_b: Color = Color(1.0, 0.25, 0.85, 1.0),
	duration: float = 0.26
) -> void:
	if tree == null or tree.current_scene == null:
		return
	var holder := Node3D.new()
	holder.name = "KenneyStarFlareBurst"
	tree.current_scene.add_child(holder)
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
```

### 5. Hàm tạo Bóng Mờ Nhân Bản Từ Mô Hình `.glb` Thật Của Hiệp Sĩ (`spawn_prismatic_hero_afterimage`):
Tuyệt đối không dùng khối trụ/viên thuốc làm bóng mờ! Nhân bản trực tiếp các `MeshInstance3D` đang hiển thị trên `visual_root` của nhân vật với màu phát sáng Cực Quang:
```gdscript
static func spawn_prismatic_hero_afterimage(tree: SceneTree, visual_root: Node3D, tint_color: Color, duration: float = 0.28) -> void:
	if tree == null or tree.current_scene == null or visual_root == null or not is_instance_valid(visual_root):
		return
	var ghost_root := Node3D.new()
	ghost_root.name = "PrismaticHeroAfterimage"
	tree.current_scene.add_child(ghost_root)
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
```

---

## 🔥 TASK 25.3 (TRỌNG TÂM SỐ 1): ĐẠI TU ĐÒN ĐÁNH THỨ 3 CỦA NÚT [U / CHUỘT TRÁI] — "THÁNH LONG THIÊN GIÁNG TRẢM" (7 LỚP HIỆU ỨNG ĐA SẮC)

Trong `KayKitVFXManager`, nâng cấp xử lý khi `combo_idx == 3` trong `spawn_slash_arc` ( đồng thời nâng cấp luôn sắc độ của `combo_idx == 1` và `combo_idx == 2`):

### 1. Sắc độ mới cho Nhịp 1 & Nhịp 2 của nút [U]:
- **Nhịp 1 (`combo_idx == 1`):** Kiếm khí Cung Trăng **Lam Băng Cực Quang (`#00F5FF`) $\rightarrow$ Vàng Phượng Hoàng (`#FFD700`) $\rightarrow$ Tím Tinh Vân (`#9D00FF`)**, kèm một dải lụa kiếm khí phụ mỏng quét lệch $8^\circ$ và chùm hạt tia sáng `spark_05.png`.
- **Nhịp 2 (`combo_idx == 2`):** Song Kiếm Khí Giao Thoa **Hồng Cực Quang (`#FF1A8C`) $\rightarrow$ Cam Rực Lửa (`#FF6600`) $\rightarrow$ Tím Sấm Sét (`#8C00FF`)**.

### 2. Toàn bộ 7 Lớp Hiệu Ứng Đa Sắc của Nhịp Thứ 3 (`combo_idx == 3` — hàm `spawn_u3_heaven_shatter_finale`):
Khi `combo_idx == 3`, gọi ngay hàm `spawn_u3_heaven_shatter_finale(tree, origin, forward_dir)` dưới đây để kích hoạt đồng bộ **7 lớp hiệu ứng rực rỡ (0% khối thô)**:

```gdscript
static func spawn_u3_heaven_shatter_finale(tree: SceneTree, origin: Vector3, forward_dir: Vector3) -> void:
	if tree == null or tree.current_scene == null:
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
		# Lưỡi 1 (Trung tâm - Hoàng Kim Dung Nham Tím)
		{
			"radius": 2.35, "width": 0.95, "roll": deg_to_rad(88.0), "yaw_off": 0.0,
			"core": Color(1.0, 1.0, 1.0, 1.0), "mid": Color(1.0, 0.88, 0.15, 1.0),
			"edge": Color(1.0, 0.18, 0.02, 1.0), "accent": Color(0.85, 0.05, 1.0, 1.0),
			"emission": 9.2, "dur": 0.34
		},
		# Lưỡi 2 (Cánh Trái - Hồng Cực Quang & Tím Thiên Hà)
		{
			"radius": 2.15, "width": 0.78, "roll": deg_to_rad(70.0), "yaw_off": deg_to_rad(-14.0),
			"core": Color(1.0, 0.98, 1.0, 1.0), "mid": Color(1.0, 0.20, 0.68, 1.0),
			"edge": Color(0.58, 0.0, 1.0, 1.0), "accent": Color(1.0, 0.85, 0.1, 1.0),
			"emission": 8.4, "dur": 0.36
		},
		# Lưỡi 3 (Cánh Phải - Xanh Điện Quang & Lam Thẫm)
		{
			"radius": 2.15, "width": 0.78, "roll": deg_to_rad(106.0), "yaw_off": deg_to_rad(14.0),
			"core": Color(1.0, 1.0, 1.0, 1.0), "mid": Color(0.0, 0.96, 1.0, 1.0),
			"edge": Color(0.0, 0.32, 1.0, 1.0), "accent": Color(1.0, 0.15, 0.75, 1.0),
			"emission": 8.4, "dur": 0.36
		}
	]

	for cfg in arc_configs:
		var pivot := Node3D.new()
		pivot.name = "U3TripleGuillotineArc"
		tree.current_scene.add_child(pivot)
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
		12.0, 0.38
	)
	_spawn_prismatic_cyclone_ring_ribbon(
		tree, impact_pos + Vector3(0.0, 0.12, 0.0), 0.60, 3.85, 0.52,
		Color(1.0, 1.0, 1.0, 1.0), Color(0.0, 0.95, 1.0, 1.0),
		Color(0.65, 0.0, 1.0, 1.0), Color(1.0, 0.25, 0.65, 1.0),
		-14.0, 0.44
	)

	# =========================================================================
	# LỚP 3: CỘT LỐC XOÁY LỤA ĐÔI BỐC LÊN TRỜI (VERTICAL HELIX SLASH RIBBONS)
	# =========================================================================
	for h_idx in range(2):
		var pillar_pivot := Node3D.new()
		pillar_pivot.name = "U3HelixRibbonPillar"
		tree.current_scene.add_child(pillar_pivot)
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
	for dcfg in decal_configs:
		var dec := Decal.new()
		var dtex := _load_cached_tex(String(dcfg["tex"]))
		if dtex:
			dec.texture_albedo = dtex
			dec.texture_emission = dtex
		dec.modulate = dcfg["col"]
		dec.emission_energy = float(dcfg["energy"])
		var s: float = float(dcfg["size"])
		dec.size = Vector3(s * 0.2, 3.0, s * 0.2)
		tree.current_scene.add_child(dec)
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
	sparks.draw_pass_1 = get_safe_particle_quad_mesh(0.42)

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

	tree.current_scene.add_child(sparks)
	sparks.global_position = impact_pos + Vector3(0.0, 0.35, 0.0)
	sparks.emitting = true
	var sp_tw := sparks.create_tween()
	sp_tw.tween_interval(0.65)
	sp_tw.tween_callback(sparks.queue_free)

	# =========================================================================
	# LỚP 7: XUNG ÁNH SÁNG ĐỘNG OMNILIGHT3D ĐỔI MÀU (SHADOWLESS HDR LIGHT)
	# =========================================================================
	var light := OmniLight3D.new()
	light.shadow_enabled = false
	light.omni_range = 7.2
	light.light_color = Color(1.0, 0.82, 0.28)
	light.light_energy = 6.2
	tree.current_scene.add_child(light)
	light.global_position = impact_pos + Vector3(0.0, 1.1, 0.0)
	var l_tw := light.create_tween()
	l_tw.set_parallel(true)
	l_tw.tween_property(light, "light_color", Color(0.95, 0.20, 1.0), 0.32)
	l_tw.tween_property(light, "light_energy", 0.0, 0.32)
	l_tw.chain().tween_callback(light.queue_free)
```

---

## ⚡ TASK 25.4 (TRỌNG TÂM SỐ 2): ĐẠI TU TUYỆT KỸ NÚT [I / CHUỘT PHẢI] — "THÁNH KIẾM PHÁ KHÔNG TRẢM: CỰC QUANG THẬP TỰ" (2 PHA - 8 LỚP HIỆU ỨNG)

Nâng cấp toàn diện cả 2 pha của kỹ năng nút **[I / Chuột Phải]** trong `KayKitVFXManager` và `HeroKnight3D` (giữ nguyên sát thương chuẩn `25.0 + 30.0 = 55.0 DMG` và Cooldown `3.5s` của Phase 24):

### 1. PHA 1 — Lướt Tàn Ảnh Cầu Vồng & Chém Thập Tự 4 Lưỡi (`spawn_rmb_solar_cross_cleave`):
- Trong `hero_knight_3d.gd`: Khi bắt đầu `_do_rmb_cross_cleave()`, sinh **3 Tàn Ảnh Mô Hình KayKit Thật (`spawn_prismatic_hero_afterimage`)** dọc theo bước lướt với 3 màu: **Vàng Hoàng Kim (`#FFD700`) $\rightarrow$ Hồng Cực Quang (`#FF1A8C`) $\rightarrow$ Lam Điện Quang (`#00F0FF`)**.
- Trong `KayKitVFXManager.spawn_rmb_solar_cross_cleave(tree, origin, forward_dir)`: Thay thế hàm cũ bằng phiên bản **Tứ Kiếm Khí Chữ X Đa Sắc** dưới đây:

```gdscript
static func spawn_rmb_solar_cross_cleave(tree: SceneTree, origin: Vector3, forward_dir: Vector3) -> void:
	if tree == null or tree.current_scene == null:
		return
	var flat_fwd := Vector3(forward_dir.x, 0.0, forward_dir.z).normalized()
	if flat_fwd.length_squared() < 0.001:
		flat_fwd = Vector3.FORWARD
	var base_yaw := atan2(flat_fwd.x, flat_fwd.z)
	var cross_center := origin + Vector3(0.0, 1.15, 0.0) + flat_fwd * 1.15
	var ground_pos := _snap_vfx_to_ground(tree, origin + flat_fwd * 1.65)

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
		tree.current_scene.add_child(pivot)
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
	tree.current_scene.add_child(sigil)
	sigil.global_position = ground_pos
	var s_tw := sigil.create_tween()
	s_tw.set_parallel(true)
	s_tw.tween_property(sigil, "rotation:y", deg_to_rad(120.0), 0.50)
	s_tw.tween_property(sigil, "modulate:a", 0.0, 0.50)
	s_tw.chain().tween_callback(sigil.queue_free)
```

---

### 2. PHA 2 — Đại Sóng Kiếm Khí Tam Dực Càn Quét `4.8m` Mặt Đất (`spawn_rmb_traveling_crescent_wave`):
Thay thế hàm `spawn_rmb_traveling_crescent_wave` trong `KayKitVFXManager` để tạo ra một **Cụm 3 Lưỡi Kiếm Khí Lụa Cong 3D (`Triple-Winged Prismatic Wave`)** lao đi trên mặt đất, tự động nở vòng xoáy lụa + ấn chú dọc đường bay và phát nổ **Đại Tinh Vân Cực Quang (`Grand Finale Nova`)** ở cuối hành trình:

```gdscript
static func spawn_rmb_traveling_crescent_wave(
	tree: SceneTree,
	origin: Vector3,
	forward_dir: Vector3,
	travel_distance: float = 4.8,
	travel_speed: float = 18.0,
	wave_damage: float = 30.0
) -> Node3D:
	if tree == null or tree.current_scene == null:
		return null

	var flat_fwd := Vector3(forward_dir.x, 0.0, forward_dir.z).normalized()
	if flat_fwd.length_squared() < 0.001:
		flat_fwd = Vector3.FORWARD
	var base_yaw := atan2(flat_fwd.x, flat_fwd.z)
	var start_pos := _snap_vfx_to_ground(tree, origin + flat_fwd * 0.9)

	var wave_root := Node3D.new()
	wave_root.name = "RMBPrismaticTripleWave3D"
	tree.current_scene.add_child(wave_root)
	wave_root.global_position = start_pos
	wave_root.rotation.y = base_yaw

	# =========================================================================
	# LỚP 5: KẾT CẤU SÓNG KIẾM 3 CÁNH LỤA CONG (TRIPLE-WINGED SLASH RIBBONS)
	# =========================================================================
	var wing_specs := [
		# Lưỡi Trung Tâm (Dựng đứng 82° - Hoàng Kim & Đỏ Lửa)
		{"roll": deg_to_rad(82.0), "pitch": deg_to_rad(-12.0), "radius": 1.65, "width": 0.95, "y_off": 0.95, "core": Color(1,1,1,1), "mid": Color(1.0, 0.88, 0.15, 1), "edge": Color(1.0, 0.18, 0.02, 1), "accent": Color(1.0, 0.0, 0.7, 1)},
		# Cánh Phượng Hoàng Bên Trái (Mở nghiêng +36° - Xanh Băng & Hồng Tím)
		{"roll": deg_to_rad(36.0), "pitch": deg_to_rad(-6.0), "radius": 1.85, "width": 0.78, "y_off": 0.65, "core": Color(1,1,1,1), "mid": Color(0.0, 0.96, 1.0, 1), "edge": Color(0.75, 0.0, 1.0, 1), "accent": Color(1.0, 0.25, 0.65, 1)},
		# Cánh Phượng Hoàng Bên Phải (Mở nghiêng -36° - Hồng Cực Quang & Lam Sét)
		{"roll": deg_to_rad(-36.0), "pitch": deg_to_rad(-6.0), "radius": 1.85, "width": 0.78, "y_off": 0.65, "core": Color(1,1,1,1), "mid": Color(1.0, 0.22, 0.75, 1), "edge": Color(0.0, 0.55, 1.0, 1), "accent": Color(1.0, 0.9, 0.15, 1)}
	]

	var wave_mats: Array[ShaderMaterial] = []
	for w in wing_specs:
		var wing_inst := MeshInstance3D.new()
		wing_inst.mesh = build_curved_slash_arc_mesh(float(w["radius"]), float(w["width"]), 150.0, 36)
		wing_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wing_inst.position = Vector3(0.0, float(w["y_off"]), 0.0)
		wing_inst.rotation = Vector3(float(w["pitch"]), deg_to_rad(-90.0), float(w["roll"]))

		var wmat := ShaderMaterial.new()
		wmat.shader = _get_stylized_slash_shader()
		wmat.set_shader_parameter("core_color", w["core"])
		wmat.set_shader_parameter("mid_color", w["mid"])
		wmat.set_shader_parameter("edge_color", w["edge"])
		wmat.set_shader_parameter("accent_color", w["accent"])
		wmat.set_shader_parameter("emission_strength", 9.0)
		wmat.set_shader_parameter("chromatic_shift", 0.80)
		wmat.set_shader_parameter("slash_progress", 0.0)
		wing_inst.material_override = wmat
		wave_root.add_child(wing_inst)
		wave_mats.append(wmat)

	# =========================================================================
	# LỚP 6: LUỒNG HẠT CẦU VỒNG & ĐÈN OMNILIGHT3D BÁM ĐUÔI SÓNG KIẾM
	# =========================================================================
	var wake_particles := GPUParticles3D.new()
	wake_particles.amount = 32
	wake_particles.lifetime = 0.30
	wake_particles.draw_pass_1 = get_safe_particle_quad_mesh(0.38)
	var wp_mat := ParticleProcessMaterial.new()
	wp_mat.direction = Vector3(0.0, 0.4, -1.0)
	wp_mat.spread = 42.0
	wp_mat.initial_velocity_min = 4.0
	wp_mat.initial_velocity_max = 8.5
	wp_mat.gravity = Vector3(0.0, -5.0, 0.0)
	wp_mat.color_ramp = _get_prismatic_color_ramp()
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
	wp_draw.emission = Color(1.0, 0.8, 0.9)
	wp_draw.emission_energy_multiplier = 4.0
	wake_particles.material_override = wp_draw
	wake_particles.position = Vector3(0.0, 0.55, 0.0)
	wave_root.add_child(wake_particles)

	var wave_light := OmniLight3D.new()
	wave_light.shadow_enabled = false
	wave_light.omni_range = 5.5
	wave_light.light_color = Color(1.0, 0.72, 0.35)
	wave_light.light_energy = 5.0
	wave_light.position = Vector3(0.0, 0.85, 0.0)
	wave_root.add_child(wave_light)

	# =========================================================================
	# LỚP 7 & 8: HÀNH TRÌNH CÀY ĐẤT, QUÉT SÁT THƯƠNG BOT & ĐẠI TINH VÂN CUỐI ĐƯỜNG
	# =========================================================================
	var duration := maxf(0.18, travel_distance / maxf(1.0, travel_speed))
	var hit_enemies: Dictionary = {}
	var state := {"dist": 0.0, "next_rupture": 0.75}

	var tw := wave_root.create_tween()
	tw.tween_method(func(t: float):
		if not is_instance_valid(wave_root):
			return
		var cur_dist := t * travel_distance
		var flat_pos := start_pos + flat_fwd * cur_dist
		var snapped := _snap_vfx_to_ground(tree, flat_pos)
		wave_root.global_position = snapped

		# Quét sát thương thực tế lên mọi Bot nằm trên đường sóng kiếm càn lướt qua
		for enemy in tree.get_nodes_in_group("enemies"):
			if is_instance_valid(enemy) and not hit_enemies.has(enemy.get_instance_id()):
				var d_xz := Vector2(enemy.global_position.x - snapped.x, enemy.global_position.z - snapped.z).length()
				var d_y := absf(enemy.global_position.y - snapped.y)
				if d_xz <= 2.35 and d_y <= 2.2:
					hit_enemies[enemy.get_instance_id()] = true
					if enemy.has_method("take_hit"):
						enemy.take_hit(wave_damage, flat_fwd * 2.2, 0.65)
					spawn_hit_sparks(tree, enemy.global_position + Vector3(0.0, 1.0, 0.0), flat_fwd)

		# LỚP 7: Cứ mỗi 0.95m sóng kiếm đi qua -> Bung vòng lụa xoáy + Ấn chú cháy dưới đất
		if cur_dist >= float(state["next_rupture"]):
			state["next_rupture"] = float(state["next_rupture"]) + 0.95
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
			step_dec.modulate = Color(1.0, 0.45, 0.15, 0.88)
			step_dec.emission_energy = 4.5
			step_dec.size = Vector3(2.2, 2.4, 2.2)
			tree.current_scene.add_child(step_dec)
			step_dec.global_position = snapped
			var dtw := step_dec.create_tween()
			dtw.tween_property(step_dec, "modulate:a", 0.0, 0.65).set_delay(0.35)
			dtw.tween_callback(step_dec.queue_free)

		if t > 0.72:
			var fade_val := (t - 0.72) / 0.28
			for wm in wave_mats:
				if is_instance_valid(wm):
					wm.set_shader_parameter("slash_progress", fade_val)
	, 0.0, 1.0, duration)

	# LỚP 8: ĐẠI TINH VÂN BÙNG NỔ CUỐI HÀNH TRÌNH (GRAND FINALE PRISMATIC NOVA)
	tw.tween_callback(func():
		if is_instance_valid(wave_root):
			var end_pos := wave_root.global_position
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
```

---

## ✨ TASK 25.5: NÂNG CẤP HIỆU ỨNG TRÚNG ĐÒN ĐA SẮC (`spawn_hit_sparks`) & ĐĂNG KÝ `ShaderPrewarmer`

1. **Nâng cấp `spawn_hit_sparks(tree, hit_pos, hit_dir)` trong `KayKitVFXManager`:**
   - Khi bất kỳ đòn đánh nào trúng Bot, ngoài 22 hạt tia lửa dùng `_get_prismatic_color_ramp()`, gọi thêm `_spawn_kenney_star_flare_burst(tree, hit_pos, 1.85, Color(1.0, 0.92, 0.35), Color(1.0, 0.22, 0.78), 0.18)` để mỗi nhát chém trúng đích đều chớp sáng hoa đăng Kenney cực kỳ bắt mắt.
2. **Cập nhật `ShaderPrewarmer` (`src_game/scripts/vfx/shader_prewarmer.gd`):**
   - Trong bước khởi động Prewarm, gọi sẵn `KayKitVFXManager._get_prismatic_color_ramp()` và nạp trước các texture Kenney (`star_07.png`, `light_01.png`, `circle_02.png`, `circle_04.png`, `scorch_02.png`, `spark_05.png`) để tốc độ khung hình giữ vững **165Hz+ phẳng tuyệt đối (0ms khựng hình)**.

---

## 🧪 TASK 25.6: KIỂM THỬ TỰ ĐỘNG 100% PASS (`test_phase_25_prismatic_vfx_overhaul.gd`) & ĐỒNG BỘ GITHUB (`AGENT-06`)

1. Viết và chạy kịch bản kiểm thử tự động `src_game/tests/test_phase_25_prismatic_vfx_overhaul.gd` xác nhận **PASS 100%** 4 bài kiểm tra:
   - **Test 25.1 (Đòn đánh thứ 3 Nút [U] — 7 Lớp Hiệu Ứng Đa Sắc & Sát Thương 35 DMG):**
     - Kích hoạt chuỗi 3 nhịp đánh [U], xác nhận ở nhịp thứ 3 sinh đầy đủ Tam Trùng Đại Kiếm Khí (`U3TripleGuillotineArc`), Vòng Lụa Xoáy Ngược Chiều (`PrismaticCycloneRibbon3D`), Cột Xoáy Lụa Đôi (`U3HelixRibbonPillar`), Trận Pháp Kép `Decal`, Hoa Đăng `KenneyStarFlareBurst`, Đài Phun Hạt Cầu Vồng 42 hạt và gây đúng `35.0 DMG` lên Bot.
   - **Test 25.2 (Tuyệt kỹ Nút [I] — Tứ Kiếm Khí Chữ X & Đại Sóng Kiếm 3 Cánh Cày Đất):**
     - Kích hoạt kỹ năng [I], xác nhận Pha 1 sinh 3 Tàn Ảnh Mô Hình `.glb` thật + 4 cung kiếm khí chữ X đa sắc (`RMBQuadXSlashPivot`, gây `25.0 DMG`) và Pha 2 phóng Đại Sóng Kiếm 3 Cánh (`RMBPrismaticTripleWave3D`) bay xa `4.8m`, sinh các vòng xoáy lụa dọc đường bay, phát nổ Nova ở cuối hành trình và gây `30.0 DMG` (Tổng `55.0 DMG`).
   - **Test 25.3 (Kiểm định 0% Khối Thô — `primitive_count == 0`):**
     - Quét toàn bộ SceneTree ngay tại thời điểm cả chiêu [U nhịp 3] và chiêu [I] đang phát nổ rực rỡ nhất trên sân $\rightarrow$ Xác nhận **`primitive_count == 0`** (0% `PrimitiveMesh` và 0% khối chóp/hộp tự vẽ).
   - **Test 25.4 (Kiểm định Bảo Toàn 100% Trạng Thái Golden Master Phase 24):**
     - Chạy lại toàn bộ suite `test_phase_24_dash_cd_and_bulletproof_stairs.gd` xác nhận Cooldown Space 1.0s và di chuyển/lướt cầu thang vẫn **PASS 100%**.
2. Chụp ảnh màn hình thực tế khoảnh khắc tung đòn thứ 3 nút [U] và chiêu [I] trên GPU RTX 4060 lưu vào `docs/QA_REPORTS/screenshots/`, cập nhật báo cáo tiến độ, sau đó chạy `git add .`, `git commit -m "feat(phase25): prismatic 5-stop HDR VFX overhaul for U combo 3 and I cross-cleave with 0% primitive meshes"` và `git push` lên `https://github.com/NhutPham19/GameWizad`.