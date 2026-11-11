# 👑 CHỈ ĐẠO SỐ 20 TỪ ARGONS: ĐẠI TU HIỆU ỨNG KIẾM KHÍ 3D (`SLASH FX` ĐA TẦNG RỰC RỠ CHUẨN STUDIO), NÂNG CẤP TỐI ĐA 6 CHIÊU THỨC CỦA `HERO KNIGHT` & CẬP NHẬT THANH MÁU ĐỎ CHO BOT

- **Người chỉ đạo (Chief Architect):** ARGONS
- **Đơn vị thực thi:** ANTIGRAVITY IDE (`Claude Opus 4.6` / `Gemini 3.8 Flash`)
- **Kho GitHub chính thức:** `https://github.com/NhutPham19/GameWizad`
- **Tài liệu luật nền tảng:** Tuân thủ nghiêm ngặt `docs/00_PROJECT_MEMORY_AND_AGENT_RULES.md` (Đặc biệt là **Luật Số 2: Cấm tuyệt đối 100% `PrimitiveMesh`**).

---

## 🎯 TỔNG QUAN MỤC TIÊU BẮT BUỘC TRONG CHỈ ĐẠO SỐ 20

1. **Mục tiêu 1 — Cập nhật Thanh Máu Bot (`EnemyMinion3D`) về màu Đỏ Huyết Rực Rỡ (`Crimson Red`) kèm Lớp Tụt Máu Trễ (`Damage Catch-up Bar`):**
   - Duy nhất 1 cụm thanh máu trên đỉnh đầu mỗi con Bot ($Y = 2.25\text{m}$), hiển thị màu **Đỏ Tươi (`#E61E2A`)** nổi bật trên nền Đen viền tối, kèm vạch **Trắng Vàng (`#FFF5E4`)** giữ lại $0.20\text{s}$ rồi co dần khi trúng đòn để tạo cảm giác chém cực kỳ "thấm đòn".
2. **Mục tiêu 2 — Xây dựng Kiến Trúc Kiếm Khí 4 Lớp (`4-Layer Stylized SlashFX` chuẩn mẫu *NoSugarTechArt*):**
   - Thay thế hoàn toàn kiểu phát hạt rời rạc cũ bằng **Dải Lưới Cung Trăng Uốn Cong 3D (`Procedural Curved Crescent ArrayMesh`)** kết hợp **Shader Kiếm Khí 3 Tầng Màu (`vfx_stylized_slash.gdshader`)**:
     - **Lõi trong cùng:** Màu **Trắng Phát Sáng HDR (`Emission 3.8x`)** bị cắt thành các tia xé gió sắc lẹm.
     - **Thân kiếm khí:** Màu **Xanh Băng Điện Tử (`Electric Cyan #00D8FF`)** (hoặc Đỏ Hoàng Kim cho đòn kết liễu).
     - **Viền sống kiếm ngoài cùng:** Đường viền mảnh màu **Cam Lửa Rực (`Fiery Orange #FF7700`)** tạo độ tương phản Nóng – Lạnh bắt mắt y hệt ảnh mẫu.
3. **Mục tiêu 3 — Nâng cấp Tối Đa 6 Hiệu Ứng Chiêu Thức & Trúng Đòn cho `HeroKnight3D` (Làm kỹ từng chi tiết, kết hợp 80+ Texture Kenney trong `src_game/assets/vfx_textures/`):**
   - Mỗi nhịp đánh thường (`LMB` Nhịp 1, Nhịp 2, Nhịp 3), Khiên Phản Kích (`RMB`), Lốc Xoáy $360^\circ$ (`Q`), Bom Khói Lôi Vụ (`E`), Lướt (`Space`) và Vết Chém Chữ Thập (`Hit Impact`) đều có thiết kế đa tầng riêng biệt.
4. **Mục tiêu 4 — Cam kết `PRIMITIVE MESHES: 0 (PASS 100%)`:**
   - Tuyệt đối không dùng `BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PrismMesh`, `TorusMesh` hay `QuadMesh` (vì tất cả các lớp này đều kế thừa từ `PrimitiveMesh` trong Godot 4!).
   - Toàn bộ lưới phẳng cho hạt `GPUParticles3D` và dải kiếm khí uốn cong **BẮT BUỘC khởi tạo bằng `ArrayMesh`** (kế thừa trực tiếp từ `Mesh`, đảm bảo `mesh is PrimitiveMesh == false` 100%!).

---

## 🩸 TASK 20.1: CẬP NHẬT THANH MÁU BOT VỀ MÀU ĐỎ HUYẾT & HIỆU ỨNG TỤT MÁU TRỄ (`src_game/scripts/enemies/enemy_minion_3d.gd`)

### Yêu cầu kỹ thuật bắt buộc trong `enemy_minion_3d.gd`:
1. **Xóa bỏ mọi thanh máu cũ / trùng lặp** trước khi tạo thanh máu mới trong `_setup_overhead_health_bar()`.
2. **Sử dụng `Sprite3D` hiển thị `ImageTexture` động (Cập nhật mượt mà 3 lớp màu: Nền Đen + Vạch Trắng Tụt Trễ + Vạch Đỏ Máu Hiện Tại):**
   - Thêm biến theo dõi máu trễ vào `EnemyMinion3D`:
     ```gdscript
     var _displayed_lag_hp: float = 80.0
     var _hp_bar_img: Image = null
     var _hp_bar_tex: ImageTexture = null
     var _hp_bar_sprite: Sprite3D = null
     var _hp_label_3d: Label3D = null
     ```
   - Cài đặt hàm `_setup_overhead_health_bar()` và `_update_overhead_health_bar(delta: float)` chuẩn xác như sau:
     ```gdscript
     func _setup_overhead_health_bar() -> void:
     	# Dọn sạch mọi node thanh máu cũ để đảm bảo chỉ có DUY NHẤT 1 thanh máu
     	for child in get_children():
     		if child.name.begins_with("OverheadHP") or child.name.find("HealthBar") != -1:
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
     ```
   - Trong `_physics_process(delta)` của `EnemyMinion3D`, gọi cập nhật thanh máu trễ:
     ```gdscript
     if absf(_displayed_lag_hp - current_hp) > 0.05:
     	_displayed_lag_hp = move_toward(_displayed_lag_hp, current_hp, max_hp * 1.45 * delta)
     	_redraw_hp_bar_image()
     ```

---

## 🎨 TASK 20.2: VIẾT SHADER KIẾM KHÍ ĐA TẦNG `src_game/shaders/vfx_stylized_slash.gdshader` (CHUẨN MẪU *NOSUGARTECHART*)

Hãy tạo file `src_game/shaders/vfx_stylized_slash.gdshader` tái hiện chính xác 100% hiệu ứng vệt chém trong bức ảnh mẫu của User:
- **Lõi trắng phát sáng HDR (`core_color`)** chạy dọc giữa thân chém kèm các đường xước gió tốc độ cao.
- **Thân năng lượng chính (`main_color`)** màu Xanh Băng Điện Tử (`Cyan`) hoặc Đỏ Hoàng Kim.
- **Viền sống kiếm ngoài cùng (`edge_color`)** màu Cam Lửa (`Fiery Orange`) bọc ở mép ngoài cung chém.
- **Hiệu ứng quét tiến trình (`progress`)** từ $0.0 \rightarrow 1.0$: Đầu mũi kiếm vọt nhanh tới trước, trong khi phần đuôi kiếm tự động xé thành những tia gió mảnh rồi tan biến!

```glsl
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform sampler2D slash_mask_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D streak_noise_tex : filter_linear_mipmap, repeat_enable;

uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 main_color : source_color = vec4(0.0, 0.82, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.45, 0.05, 1.0);

uniform float emission_boost : hint_range(1.0, 10.0) = 3.8;
uniform float progress : hint_range(0.0, 1.0) = 0.25;
uniform float arc_fill : hint_range(0.1, 1.0) = 0.82;
uniform float streak_frequency : hint_range(4.0, 40.0) = 18.0;
uniform float speed_scroll : hint_range(-10.0, 10.0) = 4.5;

// Hàm nhiễu giả lập các tia xé gió sắc nhọn dọc theo cung kiếm
float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	// UV.x: 0.0 (Đuôi chém) -> 1.0 (Mũi chém)
	// UV.y: 0.0 (Mép trong gần người) -> 1.0 (Sống kiếm mép ngoài cùng)
	vec2 uv = UV;

	// 1. Tính cửa sổ quét động (Swipe Head & Eroding Tail) theo progress (0.0 -> 1.0)
	float head_pos = clamp(progress * 1.45, 0.0, 1.0);
	float tail_pos = clamp((progress - 0.18) * 1.35, 0.0, 1.0);

	// Tạo các tia xé gió chạy dọc theo chiều vung kiếm
	vec2 streak_uv = vec2(uv.x * 3.5 - TIME * speed_scroll, uv.y * streak_frequency);
	float streak1 = value_noise(streak_uv);
	float streak2 = value_noise(streak_uv * vec2(2.2, 1.7) + vec2(4.1, 1.3));
	float wind_streaks = smoothstep(0.28, 0.78, streak1 * 0.65 + streak2 * 0.35);

	// 2. Độ vát nhọn ở Mũi chém (Head Taper) và Đuôi chém xé tia (Streaked Tail Erosion)
	float head_mask = smoothstep(head_pos + 0.02, head_pos - 0.12, uv.x);
	float tail_noise_offset = (1.0 - wind_streaks) * 0.28;
	float tail_mask = smoothstep(tail_pos - 0.05 + tail_noise_offset, tail_pos + 0.25 + tail_noise_offset, uv.x);
	float longitudinal_mask = head_mask * tail_mask;

	// 3. Hình dáng tiết diện ngang (Radial Profile: Mép trong mờ -> Lõi sáng -> Sống kiếm sắc nét)
	// Mép ngoài (UV.y ~ 0.88 - 0.98) là lưỡi kiếm sắc nhất; mép trong (UV.y < 0.25) mỏng dần
	float inner_fade = smoothstep(0.05, 0.38 + (1.0 - wind_streaks) * 0.22, uv.y);
	float outer_sharp_cut = 1.0 - smoothstep(0.92, 1.0, uv.y);
	float radial_mask = inner_fade * outer_sharp_cut;

	// Kết hợp thêm texture slash của Kenney nếu được truyền vào
	vec4 tex_col = texture(slash_mask_tex, uv);
	float base_alpha = longitudinal_mask * radial_mask * mix(1.0, tex_col.r * 1.25, 0.35);

	// 4. Phối 3 tầng màu chuẩn mẫu NoSugarTechArt:
	// - Tầng Lõi Trắng (Core Streaks): Nằm ở vùng UV.y từ 0.50 -> 0.85 nơi có wind_streaks cao
	float core_band = smoothstep(0.45, 0.72, uv.y) * (1.0 - smoothstep(0.84, 0.94, uv.y));
	float core_mask = clamp(core_band * (wind_streaks * 1.35) * smoothstep(0.15, 0.85, head_mask), 0.0, 1.0);

	// - Tầng Viền Sống Kiếm Ngoài Cùng (Outer Razor Rim): Màu Cam Lửa ở UV.y từ 0.85 -> 0.98
	float outer_rim_mask = smoothstep(0.80, 0.91, uv.y) * (1.0 - smoothstep(0.96, 1.0, uv.y));

	// Trộn màu: Thân Cyan -> Viền Cam Lửa -> Lõi Trắng HDR
	vec3 col = main_color.rgb;
	col = mix(col, edge_color.rgb * 1.35, outer_rim_mask);
	col = mix(col, core_color.rgb * 1.65, core_mask);

	// Cường độ rút dần ở cuối chu kỳ
	float life_fade = 1.0 - smoothstep(0.78, 1.0, progress);
	float final_alpha = clamp(base_alpha * (0.45 + 0.55 * wind_streaks) * life_fade, 0.0, 1.0);

	ALBEDO = col * emission_boost;
	ALPHA = final_alpha;
}
```

---

## ⚡ TASK 20.3: NÂNG CẤP LÕI `src_game/scripts/core/kaykit_vfx_manager.gd` (BỘ DỰNG CUNG KIẾM 3D `ArrayMesh` + 6 HIỆU ỨNG ĐA TẦNG)

> ⚠️ **LUẬT BẤT DI BẤT DỊCH (0% PRIMITIVE MESHES):**
> Trong Godot 4, cả `QuadMesh`, `PlaneMesh`, `BoxMesh`, `SphereMesh`, `CylinderMesh` đều kế thừa từ lớp `PrimitiveMesh`. Để bộ kiểm định `StrictQAHUD` báo cáo **`PRIMITIVE MESHES: 0 (PASS 100%)`**, toàn bộ các mặt phẳng hạt `GPUParticles3D` và dải lưới cung kiếm **BẮT BUỘC tạo bằng `ArrayMesh`** (vì `ArrayMesh` kế thừa trực tiếp từ `Mesh`, KHÔNG phải `PrimitiveMesh`!).

Hãy cập nhật file `src_game/scripts/core/kaykit_vfx_manager.gd` với đầy đủ hệ thống tạo lưới `ArrayMesh` cong 3D và 6 hàm kỹ xảo chuyên biệt dưới đây:

```gdscript
class_name KayKitVFXManager
extends Node3D

const TEX_DIR := "res://assets/vfx_textures/"
const SLASH_SHADER_PATH := "res://shaders/vfx_stylized_slash.gdshader"

static var _cached_quad_array_mesh: ArrayMesh = null
static var _cached_slash_shader: Shader = null
static var _tex_cache: Dictionary = {}

## 1. Tạo lưới phẳng 2 tam giác bằng ArrayMesh (Đảm bảo mesh is PrimitiveMesh == FALSE 100%)
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

## 2. Tạo Dải Lưới Cung Trăng Uốn Cong 3D (Procedural Curved Crescent Slash Arc ArrayMesh)
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

static func _get_tex(file_name: String) -> Texture2D:
	if _tex_cache.has(file_name):
		return _tex_cache[file_name]
	var full_path := TEX_DIR + file_name
	if ResourceLoader.exists(full_path):
		var t := load(full_path) as Texture2D
		_tex_cache[file_name] = t
		return t
	return null

static func _get_slash_shader() -> Shader:
	if _cached_slash_shader == null and ResourceLoader.exists(SLASH_SHADER_PATH):
		_cached_slash_shader = load(SLASH_SHADER_PATH) as Shader
	return _cached_slash_shader

## 3. HIỆU ỨNG CỐT LÕI: Triệu hồi Vệt Chém Lưỡi Liềm Đa Tầng (Chuẩn mẫu NoSugarTechArt)
func spawn_stylized_crescent_slash(
	origin_pos: Vector3,
	forward_yaw: float,
	tilt_roll_deg: float = 0.0,
	reverse_swing: bool = false,
	core_col: Color = Color(1.0, 1.0, 1.0, 1.0),
	main_col: Color = Color(0.0, 0.85, 1.0, 1.0),
	edge_col: Color = Color(1.0, 0.45, 0.05, 1.0),
	scale_mult: float = 1.0,
	duration: float = 0.24
) -> void:
	var slash_root := Node3D.new()
	slash_root.name = "StylizedSlashArcFX"
	add_child(slash_root)
	slash_root.global_position = origin_pos
	slash_root.rotation.y = forward_yaw

	# Pivot nghiêng mặt phẳng chém (Ngang 0 độ, Chéo 32 độ, Bổ dọc 90 độ)
	var tilt_pivot := Node3D.new()
	slash_root.add_child(tilt_pivot)
	tilt_pivot.rotation.z = deg_to_rad(tilt_roll_deg)
	if reverse_swing:
		tilt_pivot.scale.x = -1.0

	# LỚP 1 & 2: Lưới Cung Trăng ArrayMesh + Shader 3 Tầng Màu
	var arc_mesh_inst := MeshInstance3D.new()
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

	# LỚP 3: Dải Phụ Bóng Mờ Năng Lượng (Secondary After-Glow Arc) tạo độ dày 3D
	var sub_arc := MeshInstance3D.new()
	sub_arc.mesh = build_curved_slash_arc_mesh(0.55 * scale_mult, 2.20 * scale_mult, 140.0, 20, -0.06)
	sub_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sub_mat := smat.duplicate() as ShaderMaterial
	sub_mat.set_shader_parameter("emission_boost", 2.4)
	sub_mat.set_shader_parameter("streak_frequency", 28.0)
	sub_arc.material_override = sub_mat
	sub_arc.rotation.y = deg_to_rad(-12.0)
	tilt_pivot.add_child(sub_arc)

	# LỚP 4: Chùm Hạt Tia Lửa Kéo Dài Bay Theo Cung Kiếm (Velocity-Stretched Sparks)
	_spawn_slash_sparks_burst(tilt_pivot, main_col, edge_col, scale_mult)

	# LỚP 5: Chớp Sáng Không Gian (Dynamic Combat Light Flash)
	var flash_light := OmniLight3D.new()
	flash_light.light_color = main_col.lerp(edge_col, 0.35)
	flash_light.light_energy = 3.2
	flash_light.omni_range = 4.8 * scale_mult
	slash_root.add_child(flash_light)

	# Diễn hoạt quét cung kiếm mượt mà bằng Tween
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v: float):
		smat.set_shader_parameter("progress", v)
		sub_mat.set_shader_parameter("progress", clampf(v - 0.08, 0.0, 1.0))
	, 0.05, 1.0, duration)
	tw.tween_property(tilt_pivot, "rotation:y", deg_to_rad(28.0), duration).from(deg_to_rad(-18.0))
	tw.tween_property(flash_light, "light_energy", 0.0, duration)
	tw.chain().tween_callback(slash_root.queue_free)

func _spawn_slash_sparks_burst(parent_node: Node3D, col_a: Color, col_b: Color, scale_mult: float) -> void:
	var sparks := GPUParticles3D.new()
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
```

---

## ⚔️ TASK 20.4: ĐẶC TẢ CHI TIẾT TRỌN BỘ 6 HIỆU ỨNG CHIÊU THỨC CỦA `HeroKnight3D`

Trong `src_game/scripts/core/kaykit_vfx_manager.gd` và `src_game/scripts/characters/hero_knight_3d.gd`, kết nối từng đòn đánh với hiệu ứng chuyên biệt sau:

### 1. Đòn Đánh Thường `LMB` — Combo 3 Nhịp Biến Hóa (`spawn_combo_slash_vfx(combo_step, origin, yaw)`):
- **Nhịp 1 (`Slice_Horizontal` — *Hàn Băng Lưu Quang Trảm*):**
  - Gọi `spawn_stylized_crescent_slash()` với góc nghiêng `tilt_roll_deg = 4.0`, `reverse_swing = false`.
  - Bảng màu chuẩn ảnh mẫu *NoSugarTechArt*: Lõi Trắng (`#FFFFFF`), Thân Xanh Băng Điện Tử (`#00D8FF`), Viền ngoài Cam Lửa (`#FF7300`).
- **Nhịp 2 (`Slice_Diagonal` — *Song Nha Nghịch Phong Trảm*):**
  - Gọi `spawn_stylized_crescent_slash()` với mặt phẳng chém chéo `tilt_roll_deg = -32.0`, `reverse_swing = true` (vung ngược từ trái qua phải).
  - Sau $0.05\text{s}$, tự động sinh thêm 1 vệt kiếm khí phụ góc `+18.0` độ tạo hiệu ứng **Song Kiếm Giao Hoa** cực kỳ bắt mắt.
- **Nhịp 3 (`Chop` — *Liệt Hỏa Phá Thạch Trảm* - Đòn Bổ Dọc Uy Lực Lớn):**
  - Gọi `spawn_stylized_crescent_slash()` với góc bổ thẳng đứng từ đỉnh đầu xuống đất `tilt_roll_deg = 85.0`, `scale_mult = 1.28`, `duration = 0.30`.
  - Đổi bảng màu sang **Lõi Vàng Trắng (`#FFF8D6`) + Thân Đỏ Hoàng Kim (`#FF3B00`) + Viền Tím Sẫm (`#B800FF`)**.
  - Ngay khi lưỡi kiếm bổ xuống mặt sàn: Kích hoạt **Vụ Nổ Địa Chấn Kép** dưới mặt đất tại `origin + forward * 1.65`:
    - `Decal` 1: `scorch_02.png` màu Dung Nham Đỏ Cam nở rộng từ $0.5\text{m} \rightarrow 3.6\text{m}$.
    - `Decal` 2: `circle_02.png` vòng sóng xung kích vàng rực nở nhanh ra $4.2\text{m}$.
    - Cột hạt tia lửa `flame_04.png` + `spark_05.png` bắn tung tóe lên không trung.

### 2. Khiên Phản Kích `RMB` (`spawn_shield_bash_vfx(origin, yaw)` — *Thánh Khiên Ấn Chú & Mũi Giáo Xoáy*):
- **Ấn Chú Thánh Khiên Dựng Đứng:**
  - Ngay trước mặt khiên ($0.85\text{m}$), dựng một `Sprite3D` nạp `circle_01.png` (màu Vàng Hoàng Kim HDR `Color(2.6, 1.9, 0.4)`) xoay tròn tốc độ cao và phóng to từ $0.4\text{m} \rightarrow 1.8\text{m}$ trong $0.25\text{s}$.
- **Luồng Xung Kích Đâm Xuyên (`Piercing Drill Waves`):**
  - Dọc theo trục đâm tới trước ($1.0\text{m} \rightarrow 2.8\text{m}$), dựng 3 vòng xoáy gió `twirl_01.png` + dải kiếm khí dọc hẹp phóng vọt về phía trước cùng chùm tia chớp `spark_03.png`.

### 3. Tuyệt Chiêu `Q` (`spawn_whirlwind_360_vfx(hero_node)` — *Song Long Lốc Xoáy $360^\circ$*):
- Khi người chơi bấm `Q` (`2H_Melee_Attack_Spinning`), gắn trực tiếp một `Node3D` (`WhirlwindVortexFX`) đi theo `HeroKnight3D` trong $0.48\text{s}$:
  1. **2 Dải Lụa Kiếm Khí $360^\circ$ Xoắn Kép (`Double-Helix 360 Arcs`):**
     - Dùng `build_curved_slash_arc_mesh(1.1, 3.1, 340.0, 36, 0.25)` tạo **2 vòng kiếm khí $340^\circ$ nối đuôi nhau**:
       - Vòng 1 (Nghiêng $+14^\circ$): Màu **Xanh Băng Điện Tử – Lõi Trắng – Viền Cam**.
       - Vòng 2 (Nghiêng $-14^\circ$, lệch pha $180^\circ$): Màu **Cam Lửa Hoàng Kim – Lõi Trắng – Viền Đỏ**.
     - Cả 2 vòng tự xoay quanh người Hiệp sĩ với tốc độ $1080^\circ/\text{s}$ (3 vòng xoay đầy đủ trong $0.48\text{s}$) tạo thành cơn lốc kiếm rực rỡ!
  2. **Trận Pháp Kép Dưới Chân:**
     - Đặt `Decal` `circle_05.png` (Xanh Cyan) và `twirl_03.png` (Vàng Cam) dưới mặt sàn xoay ngược chiều nhau + luồng hạt `spark_01.png` bốc xoáy hình lốc từ chân lên đầu.

### 4. Chiêu `E` (`spawn_smoke_bomb_3d` — *Ám Ảnh Lôi Vụ 4 Tầng*):
- Quả bom 3D `smokebomb.gltf` khi bay theo đường parabol sẽ gắn hạt đuôi sáng màu **Tím Ngọc (`magic_03.png`)**.
- Khi chạm đất nổ tung 4 lớp liên hoàn:
  1. **Lớp 1 (Chớp Sáng Tâm Nổ):** `Sprite3D` `light_02.png` + `OmniLight3D` màu Tím Điện lóe sáng bán kính $5.5\text{m}$.
  2. **Lớp 2 (Ấn Chú Mặt Đất):** `Decal` `circle_04.png` màu Tím Hồng phát sáng in chặt lên các bậc cầu thang/mặt sàn trong $2.5\text{s}$.
  3. **Lớp 3 (Đám Mây Khói Ma Thuật Cuộn Xoáy):** `GPUParticles3D` nạp `smoke_04.png` và `smoke_07.png` (màu Tím Đen huyền bí) cuộn dày đặc trong bán kính $4.0\text{m}$.
  4. **Lớp 4 (Tia Sét Giật Trong Khói):** `GPUParticles3D` nạp `spark_06.png` phát sáng màu Xanh Tím giật lách tách liên tục bên trong đám khói làm chậm các Bot!

### 5. Hiệu Ứng Trúng Đòn (`spawn_cross_slash_hit_impact(world_pos)` — *Chớp Chém Chữ Thập `X-Slash`*):
- Mỗi khi lưỡi kiếm của `HeroKnight3D` chém trúng ngực `EnemyMinion3D`:
  - Thay vì chỉ bắn vài hạt nhỏ, lập tức bung ra **2 Tia Chém Sắc Lẹm Chữ X (`slash_04.png` đặt chéo $+42^\circ$ và $-42^\circ$)** phát sáng màu Trắng – Vàng Cam kết hợp ngôi sao lóe sáng tâm điểm `star_08.png` và 18 tia lửa `spark_01.png` văng tung tóe!

### 6. Hiệu Ứng Lướt `Space` & Sóng Xung Kích Khi Húc Văng Bot (`spawn_dash_trail_and_impact`):
- Khi bấm `Space` Lướt: Sinh ra vệt gió lướt `slash_02.png` nằm ngang sát mặt sàn cùng các hạt bụi sáng `twirl_02.png`.
- Khi Lướt đụng trúng Bot (kích hoạt cơ chế *Dash Impact & Rebound*): Ngay tại điểm va chạm giữa Hiệp sĩ và Bot, bung ra một **Vòng Sóng Va Chạm Dựng Đứng (`circle_03.png` + `spark_05.png`)** nở bung từ $0.3\text{m} \rightarrow 2.6\text{m}$ làm nổi bật lực húc văng đám Bot ra xa $2.0\text{m}$!

---

## 🧪 TASK 20.5: KIỂM THỬ TỰ ĐỘNG & CHỤP ẢNH NGHIỆM THU TRÊN GPU RTX 4060

1. **Viết script kiểm thử tự động `src_game/tests/test_phase_20_ultimate_slash_vfx_and_red_hp.gd` xác nhận 4 tiêu chuẩn:**
   - **Test 1 (Bot Red HP Bar & Single Instance):** Kiểm tra mọi `EnemyMinion3D` chỉ có đúng 1 thanh máu `OverheadHPHolder`, màu pixel vùng máu chính có kênh Đỏ vượt trội (`color.r > 0.80` và `color.r > color.g * 3.0`) và có hiệu ứng máu tụt trễ `_displayed_lag_hp`.
   - **Test 2 (Stylized Crescent Slash Shader & ArrayMesh):** Kích hoạt `LMB` Nhịp 1, Nhịp 2, Nhịp 3 $\rightarrow$ Xác nhận node `StylizedSlashArcFX` được sinh ra, sử dụng `ArrayMesh` gắn `ShaderMaterial` (`vfx_stylized_slash.gdshader`).
   - **Test 3 (360 Whirlwind, Shield Bash & Smoke Bomb VFX):** Kích hoạt `RMB`, `Q`, `E`, `Space` $\rightarrow$ Xác nhận toàn bộ hiệu ứng chạy mượt mà không có lỗi Shader hay null reference.
   - **Test 4 (Zero Primitive Meshes Audit):** Quét toàn bộ Scene Tree trong lúc tất cả hiệu ứng `LMB`, `RMB`, `Q`, `E`, `Space` và `Hit Impact` đang phát đồng thời $\rightarrow$ Xác nhận **`primitive_count == 0` (`PASS 100%`)**!
2. **Chụp ảnh màn hình thực tế trên GPU RTX 4060 lưu vào `docs/QA_REPORTS/screenshots/phase20_ultimate_slash_vfx.png`** ngay khoảnh khắc Hiệp sĩ đang quét dải kiếm khí lưỡi liềm Xanh Cyan – Lõi Trắng – Viền Cam Lửa vào đám Bot có thanh máu Đỏ.
3. **Cập nhật `docs/CURRENT_CODE_SNAPSHOT.md` và đẩy thẳng lên GitHub:**
   - Thực hiện `git add .`, `git commit -m "feat(phase20): overhaul 4-layer stylized crescent slash VFX, upgrade all 6 hero skills, and set bot HP bar to crimson red"`, và `git push` lên `https://github.com/NhutPham19/GameWizad`.