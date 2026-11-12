# 👑 CHỈ ĐẠO SỐ 26 TỪ ARGONS: TRẠNG THÁI THỨ 2 KÍCH HOẠT NỘ (PHÍM `[R]` — 10S DUY TRÌ / 6S HỒI), ĐỔI PHÍM CHƠI LẠI SANG `[F1]` & ĐẠI TU HIỆU ỨNG ĐỎ - XANH DƯƠNG ĐỌNG LẠI, KÉO DÀI, TO VÀ UY LỰC HƠN

- **Người chỉ đạo (Chief Architect):** ARGONS
- **Đơn vị thực thi:** ANTIGRAVITY IDE (`Claude Opus 4.6` / `Gemini 3.8 Flash`)
- **Kho GitHub dự án:** `https://github.com/NhutPham19/GameWizad`
- **Trạng thái nền tảng:** Phase 24 & Phase 25 đang hoạt động ổn định 100% (Golden Master).

---

## 🛡️ 5 LUẬT THÉP BẤT DI BẤT DỊCH (ZERO-BUG, ANTI-BLOB & ZERO-CRUDE-MESH RULES)

1. **LUẬT SỐ 1 — CẤM 100% KHỐI HÌNH HỌC THÔ (`PrimitiveMesh == 0`):**
   - Nghiêm cấm sử dụng `BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PlaneMesh`, `PrismMesh`, `TorusMesh`, `QuadMesh` và nghiêm cấm tự vẽ các khối chóp/hộp đa giác thô kệch.
   - 100% hiệu ứng mới phải dùng dải lụa kiếm khí cong mượt `build_curved_slash_arc_mesh(..., 36)`, bộ Texture nghệ thuật của Kenney (`res://assets/vfx_textures/kenney_particles/*.png`), `Decal`, `GPUParticles3D` và nhân bản lưới `.glb` thật của nhân vật KayKit.
2. **LUẬT SỐ 2 — CHỐNG CHÓI BỆT THÀNH 1 MẢNG (`ANTI-CLUMP & SPATIAL STAGGERING`):**
   - **Tuyệt đối không đặt nhiều lưỡi kiếm khí cùng bán kính đè khít lên một tọa độ** (gây cộng dồn `blend_add` thành một cục trắng-hồng như lỗi cũ).
   - Ở Trạng thái 2 (Kích hoạt Nộ), các lưỡi kiếm **Đỏ Huyết (`#FF0824`)** và **Xanh Dương Điện Quang (`#0055FF`)** bắt buộc phải **Tách Lớp Không Gian (Spatial Staggering)**: Lưỡi Đỏ và Lưỡi Xanh phải chênh lệch bán kính từ `0.45m – 0.65m` hoặc xòe cánh quạt lệch góc `16° – 34°`, đồng thời thu hẹp lõi trắng xuống chỉ còn `15%` sống kiếm (`core_sharpness = 2.2`) để nhìn rõ từng lưỡi kiếm Đỏ và Xanh sắc lẹm đan xen nhau!
3. **LUẬT SỐ 3 — CƠ CHẾ "ĐỌNG LẠI, KÉO DÀI & TO RA" (`LINGERING POWER EXPANSION`):**
   - Mọi đòn đánh và chiêu thức (đặc biệt là ở Trạng thái 2) không được biến mất ngay sau khi vung kiếm!
   - Phải áp dụng **Chu kỳ 3 Giai đoạn**:
     - *Giai đoạn 1 (0% -> 22% thời gian — Chém Tốc Độ Cao):* Vệt kiếm quét ra cực nhanh đạt kích thước chuẩn.
     - *Giai đoạn 2 (22% -> 70% thời gian — Đọng Lại & Phình To Uy Lực):* Vệt kiếm **đọng lại trên không trung (`slash_progress` giữ ở mức thấp `0.10 -> 0.28`)**, đồng thời **phình to kích thước thêm `+20% đến +30%` (`scale` nở từ `1.0x` lên `1.25x`) và vươn dài về phía trước thêm `0.35m`** để người chơi cảm nhận rõ sức nặng và uy lực khủng khiếp của nhát chém!
     - *Giai đoạn 3 (70% -> 100% thời gian — Tan Thành Tàn Lửa & Tia Sét):* Mép kiếm phân rã thành các hạt tinh thể Đỏ & Xanh Dương.
4. **LUẬT SỐ 4 — BẢO TOÀN 100% VẬT LÝ, CẦU THANG & COOLDOWN CỦA PHASE 24/25:**
   - Tuyệt đối không sửa đổi `kaykit_arena_builder.gd` hay logic va chạm cầu thang, tường và Cooldown Lướt `Space` (`1.0s`).
5. **LUẬT SỐ 5 — AN TOÀN BỘ NHỚ & 165Hz+:**
   - Mọi `Tween` gắn trực tiếp vào node hiệu ứng (`node.create_tween()`), kiểm tra `is_instance_valid()`. Khi kết thúc 10s Nộ hoặc khi bấm `F1` Chơi lại, phải dọn sạch hào quang Nộ an toàn.

---

## 🔄 TASK 26.1: CHUYỂN PHÍM "CHƠI LẠI" TỪ `[R]` SANG `[F1]` & GIẢI PHÓNG PHÍM `[R]` CHO KÍCH HOẠT NỘ

1. **Cập nhật xử lý phím Chơi Lại (Restart) trong `src_game/scripts/levels/kaykit_multitier_arena.gd` và `src_game/scripts/ui/strict_qa_hud.gd`:**
   - Tìm toàn bộ nơi đang bắt phím `KEY_R` để gọi `reload_current_scene()` hoặc `_on_restart_pressed()`.
   - **Thay thế hoàn toàn `KEY_R` bằng `KEY_F1`** (`Input.is_physical_key_pressed(KEY_F1)`).
   - Cập nhật nhãn nút bấm ở chính giữa đỉnh màn hình trên `StrictQAHUD` từ `"🔄 CHƠI LẠI (Phím R)"` thành:
     ```gdscript
     restart_btn.text = "🔄 CHƠI LẠI (Phím F1)"
     ```
   - Đảm bảo cả khi nhấn phím vật lý **`F1`** trên bàn phím lẫn khi click chuột vào nút `"🔄 CHƠI LẠI (Phím F1)"` đều khởi động lại màn chơi mượt mà.

---

## 🔥 TASK 26.2: XÂY DỰNG HỆ THỐNG TRẠNG THÁI THỨ 2 — KÍCH HOẠT NỘ BẰNG PHÍM `[R]` ("HUYẾT LAM CUỒNG NỘ")

Trong `src_game/scripts/characters/hero_knight_3d.gd` và `src_game/scripts/ui/strict_qa_hud.gd`:

### 1. Thông số & Biến trạng thái trong `hero_knight_3d.gd`:
- **Trạng thái 1 (Mặc định):** Chính là trạng thái Cực Quang Đa Sắc hiện tại của Phase 25 (`_is_rage_state_2 = false`).
- **Trạng thái 2 (Kích hoạt khi nhấn phím `[R]` — Huyết Lam Cuồng Nộ):**
  ```gdscript
  const RAGE_ACTIVE_DURATION: float = 10.0   # Duy trì trạng thái 2 trong đúng 10.0 giây
  const COOLDOWN_RAGE_R: float = 6.0         # Hồi chiêu 6.0 giây sau khi kết thúc 10s Nộ
  const RAGE_DAMAGE_MULTIPLIER: float = 1.45 # Tăng +45% sát thương toàn bộ đòn đánh & kỹ năng
  const RAGE_SPEED_MULTIPLIER: float = 1.15  # Tăng +15% tốc độ chạy và tốc độ vung kiếm

  var _is_rage_state_2: bool = false
  var _rage_active_timer: float = 0.0
  var _cd_rage_r_timer: float = 0.0
  var _prev_r_phys_down: bool = false
  var _rage_aura_node: Node3D = null
  ```

### 2. Hàm bắt phím vật lý `[R]` (`_is_rage_key_just_pressed()`) & Vòng đời 10s Duy trì -> 6s Hồi:
- Đọc trực tiếp `Input.is_physical_key_pressed(KEY_R)` (chống Unikey 100%).
- **Kích hoạt (`_activate_rage_state_2()`):**
  - Chỉ kích hoạt khi `not _is_rage_state_2` và `_cd_rage_r_timer <= 0.0`.
  - **Không khóa di chuyển hay ngắt chuỗi đánh đang thực hiện** (Zero Cast-Lock: người chơi có thể bật `[R]` ngay giữa lúc đang chạy hoặc đang chém combo!).
  - Đặt `_is_rage_state_2 = true`, `_rage_active_timer = RAGE_ACTIVE_DURATION` (`10.0s`).
  - Gọi `KayKitVFXManager.spawn_rage_awakening_burst(get_tree(), global_position)` tạo vụ nổ Lốc Xoáy Kép Đỏ - Xanh Dương dưới chân, đẩy lùi nhẹ các Bot trong bán kính `2.4m` và gây `15.0 DMG` xung kích.
  - Gắn hào quang duy trì `_rage_aura_node = KayKitVFXManager.attach_persistent_rage_aura(self, visual_root)` đi theo nhân vật suốt 10 giây.
- **Duy trì & Kết thúc trong `_physics_process(delta)`:**
  ```gdscript
  if _is_rage_state_2:
      _rage_active_timer -= delta
      if _rage_active_timer <= 0.0:
          _deactivate_rage_state_2()
  else:
      _cd_rage_r_timer = maxf(0.0, _cd_rage_r_timer - delta)

  if _is_rage_key_just_pressed():
      if not _is_rage_state_2 and _cd_rage_r_timer <= 0.0:
          _activate_rage_state_2()
  ```
- **Khi hết 10 giây (`_deactivate_rage_state_2()`):**
  - Đặt `_is_rage_state_2 = false`, `_rage_active_timer = 0.0`, và **bắt đầu đếm ngược hồi chiêu `_cd_rage_r_timer = COOLDOWN_RAGE_R` (`6.0s`)**.
  - Nếu `_rage_aura_node != null and is_instance_valid(_rage_aura_node)`, giải phóng hào quang mượt mà (`queue_free()`).

### 3. Bảng Sát Thương & Phạm Vi Nâng Cấp Khi Ở Trạng Thái 2 (`_is_rage_state_2 == true`):
| Kỹ năng | Trạng Thái 1 (Mặc định) | Trạng Thái 2 (Kích Hoạt Nộ `[R]` — Đỏ & Xanh Dương) |
| :--- | :--- | :--- |
| **Đòn `[U]` Nhịp 1 & 2** | `25.0 DMG` / nhịp, tầm `2.1m` | **`36.0 DMG` / nhịp (+44%)**, tầm quét mở rộng **`2.75m`**, đọng lại `0.46s` |
| **Đòn `[U]` Nhịp 3 (U3)** | `35.0 DMG`, 3 lưỡi, bán kính `2.4m` | **`52.0 DMG` (+48%)**, **5 Đại Kiếm Khí Xếp Quạt**, bán kính nổ **`3.4m`**, đọng lại `0.56s` |
| **Chiêu `[I]` Pha 1 (Chữ X)** | `25.0 DMG`, 4 lưỡi, tầm `3.5m` | **`36.0 DMG`**, **6 Đại Kiếm Khí Chữ X Tách 3 Tầng**, tầm **`4.3m`**, đọng lại `0.52s` |
| **Chiêu `[I]` Pha 2 (Sóng Kiếm)** | `30.0 DMG` (Tổng `55 DMG`), 3 cánh, bay `4.8m` | **`44.0 DMG` (Tổng `80.0 DMG`!)**, **Sóng Kiếm 5 Cánh**, bay xa **`6.2m`**, rộng **`3.1m`** |
| **Chiêu `[O]` (Xoay 360°)** | `18.0 DMG`/nhịp, hút `3.4m`, 2 dải lụa | **`26.0 DMG`/nhịp**, hút rộng **`4.3m`**, **4 dải lụa Đỏ-Xanh xoắn kép** to hơn `1.3x` |
| **Chiêu `[P]` (Bom Lôi Vụ)** | Nổ `20 DMG`, đốt `8 DMG`/nhịp | **Bom Huyết Lôi:** Nổ **`30.0 DMG`**, đốt **`12.0 DMG`/nhịp**, khói Đỏ giật sét Xanh Dương |

### 4. Hiển thị Trạng Thái `[R]` trên `StrictQAHUD` (`src_game/scripts/ui/strict_qa_hud.gd`):
- Trên thanh Cooldown dưới đáy màn hình, bổ sung hiển thị nổi bật cho phím **`[R]`**:
  - Khi sẵn sàng: `[R] Hóa Nộ: SẴN SÀNG`
  - Khi đang trong 10 giây Trạng thái 2: **`🔥 [R] HUYẾT LAM NỘ: 9.2s (ĐANG BẬT)`**
  - Khi đang trong 6 giây hồi chiêu: `[R] Hóa Nộ: CD: 5.4s`
- Trên bảng hướng dẫn góc trái trên, cập nhật dòng phím tắt có thêm `[R] Hóa Nộ (10s)` và `[F1] Chơi Lại`.

---

## 🌈 TASK 26.3: NÂNG CẤP SHADER `vfx_stylized_slash.gdshader` HỖ TRỢ LÕI SẮC LẸM (CHỐNG BỆT MẢNG) & ĐỌNG LẠI KÉO DÀI

Cập nhật `src_game/shaders/vfx_stylized_slash.gdshader` thêm 2 thông số `core_sharpness` (thu gọn lõi trắng để màu Đỏ Huyết và Xanh Dương hiện lên đậm, sắc lẹm 85% diện tích lưỡi kiếm) và `hold_power` (giữ lưỡi kiếm đọng lại rực sáng lâu hơn trước khi tan):

```glsl
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.85, 0.15, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.2, 0.05, 1.0);
uniform vec4 accent_color : source_color = vec4(0.85, 0.1, 1.0, 1.0);
uniform float emission_strength : hint_range(1.0, 16.0) = 6.0;
uniform float slash_progress : hint_range(0.0, 1.0) = 0.0;
uniform float tail_fade : hint_range(0.1, 2.5) = 0.80;
uniform float chromatic_shift : hint_range(0.0, 1.0) = 0.50;
uniform float dissolve_scale : hint_range(2.0, 40.0) = 16.0;
uniform float core_sharpness : hint_range(0.5, 4.0) = 1.65;
uniform float hold_power : hint_range(0.0, 1.0) = 0.35;

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

	// Hai lớp sóng năng lượng cuộn dọc lưỡi kiếm
	float n1 = value_noise(uv * vec2(dissolve_scale, dissolve_scale * 0.55) - vec2(TIME * 11.0, 0.0));
	float n2 = value_noise(uv * vec2(dissolve_scale * 2.0, dissolve_scale * 1.15) + vec2(TIME * 7.5, TIME * 3.2));
	float energy_flow = mix(n1, n2, 0.5);

	// Độ dày ngang lưỡi kiếm: dùng core_sharpness để lưỡi kiếm sắc lẹm, không bị phình trắng xóa
	float radial = 1.0 - abs(uv.y * 2.0 - 1.0);
	float blade_body = pow(clamp(radial, 0.0, 1.0), 0.70);
	float razor_spine = pow(clamp(radial, 0.0, 1.0), 2.4 * core_sharpness);

	// Đường cong đọng lại (Hold Curve): Giữ nguyên độ sáng ở 45% thời gian đầu, sau đó mới rút dần
	float effective_prog = smoothstep(hold_power * 0.65, 1.0, slash_progress);
	float arc_mask = smoothstep(0.0, 0.09, uv.x) * (1.0 - smoothstep(0.86, 1.0, uv.x));
	float fade_curve = clamp(1.0 - effective_prog * (0.55 + (1.0 - uv.x) * tail_fade), 0.0, 1.0);

	// Ăn mòn tàn lửa sắc nét khi đòn đánh tan dần
	float erosion = smoothstep(effective_prog * 0.72, effective_prog * 0.72 + 0.25, blade_body * (0.65 + 0.55 * energy_flow));
	float intensity = blade_body * arc_mask * erosion * fade_curve;

	// Tia lửa điện lấp lánh dọc lưỡi kiếm
	float sparkle = step(0.84, n2) * smoothstep(0.10, 0.90, radial) * fade_curve;

	// Hòa trộn màu sắc: Đảm bảo 85% thân kiếm mang màu chủ đạo (Đỏ Huyết / Xanh Dương), chỉ 15% sống kiếm trắng sáng
	float iridescence = clamp(sin(uv.x * 7.5 - TIME * 10.0 + n1 * 3.14) * 0.5 + 0.5, 0.0, 1.0) * chromatic_shift;
	vec3 outer_col = mix(edge_color.rgb, accent_color.rgb, iridescence);
	vec3 col = mix(outer_col, mid_color.rgb, smoothstep(0.18, 0.62, intensity));
	col = mix(col, core_color.rgb, clamp(razor_spine * 1.15 + sparkle * 0.55, 0.0, 1.0));

	float alpha = clamp((intensity * 1.50 + sparkle * 0.85) * core_color.a, 0.0, 1.0);
	ALBEDO = col * emission_strength;
	ALPHA = alpha;
}
```

---

## ⚔️ TASK 26.4: CHI TIẾT HIỆU ỨNG TRẠNG THÁI 2 (ĐỎ HUYẾT & XANH DƯƠNG — ĐỌNG LẠI, KÉO DÀI, TO VÀ HẦM HỐ HƠN) TRONG `KayKitVFXManager`

Trong `src_game/scripts/vfx/kaykit_vfx_manager.gd`, bổ sung bảng màu Hạt Nộ Đỏ-Xanh và nâng cấp toàn bộ các hàm hiệu ứng khi `is_rage: bool = true` (đồng thời ở Trạng thái 1 mặc định cũng tăng nhẹ thời gian đọng lại `+20%` và độ nở `scale` `+12%` để đòn đánh thường cũng có lực hơn):

### 1. Hàm tạo `ColorRamp` Đỏ Huyết & Xanh Dương Điện Quang (`_get_rage_crimson_cobalt_ramp()`):
```gdscript
static var _cached_rage_red_blue_ramp: GradientTexture1D = null

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
```

### 2. Hàm diễn hoạt "Đọng Lại, Kéo Dài & Phình To Uy Lực" (`_animate_lingering_power_slash`):
Dùng chung cho các lưỡi kiếm khí để tạo cảm giác **vung ra nhanh $\rightarrow$ đọng lại giữa không trung và phình to ra (`scale` tăng `1.0x -> 1.26x`, tiến về trước `+0.32m`) $\rightarrow$ tan thành tia sáng**:
```gdscript
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
	# Pha 1 (24% thời gian): Quét kiếm cực nhanh tới góc đích + bung kích thước chuẩn 1.05x
	tw.set_parallel(true)
	tw.tween_property(mesh_inst, "rotation:y", deg_to_rad(end_yaw_deg * 0.88), strike_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(pivot, "scale", Vector3.ONE * 1.06, strike_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float):
		if is_instance_valid(smat):
			smat.set_shader_parameter("slash_progress", v)
	, 0.0, 0.14, strike_time)

	# Pha 2 (46% thời gian - ĐỌNG LẠI & TO RA): Lưỡi kiếm ghim lại trong không trung, phình to lên expand_scale (1.25x - 1.32x) và nhích nhẹ về trước
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
```

### 3. Hiệu Ứng Kích Hoạt Nộ `[R]` & Hào Quang Duy Trì 10 Giây (`spawn_rage_awakening_burst` & `attach_persistent_rage_aura`):
- **`spawn_rage_awakening_burst(tree, origin)`:**
  - Bung 2 vòng lụa xoáy ngược chiều sát mặt đất: Vòng trong (`R = 2.6m`) màu **Đỏ Huyết `#FF0824`**, Vòng ngoài (`R = 3.5m`) màu **Xanh Dương `#0055FF`** đọng lại `0.55s`.
  - Bung 2 cột lụa xoắn ốc (1 Đỏ, 1 Xanh Dương) vọt cao `3.8m` + Hoa đăng Kenney Đỏ-Xanh + `OmniLight3D` đỏ-xanh.
- **`attach_persistent_rage_aura(hero_node, visual_root) -> Node3D`:**
  - Tạo node `RageState2AuraHolder` gắn làm con của `hero_node`.
  - Bên dưới chân (`Y = 0.06m`): Đặt 2 mặt phẳng `get_safe_particle_quad_mesh(2.35)` nằm ngang xoay ngược chiều nhau liên tục suốt 10 giây:
    - Lớp 1 (`circle_04.png`): Phát sáng **Đỏ Huyết `#FF0A24`** (`emission = 4.5`).
    - Lớp 2 (`circle_02.png`, rộng `2.75m`): Phát sáng **Xanh Dương `#0066FF`** (`emission = 4.5`).
  - Quanh thân hiệp sĩ (`Y = 0.85m`): 2 dải lụa kiếm khí nhỏ (`build_curved_slash_arc_mesh(0.95, 0.28, 210.0, 28)`) — 1 dải **Đỏ Huyết** và 1 dải **Xanh Dương** tự xoay tròn ngược chiều nhau quanh cơ thể kèm `GPUParticles3D` 18 hạt tia lửa Đỏ-Xanh bay lên liên tục.

### 4. Đòn `[U]` Nhịp 1 & Nhịp 2 Ở Trạng Thái 2 — "SONG KIẾM PHÂN CỰC ĐỎ - XANH" (To hơn, Đọng lại `0.48s`):
Khi `is_rage == true` ở `combo_idx == 1` hoặc `combo_idx == 2`:
- Mỗi nhát chém tung ra **2 Lưỡi Đại Kiếm Khí Tách Tầng Rõ Rệt**:
  - **Lưỡi Tầng Trong (`radius = 2.15m`, `width = 0.82m`):** Sắc **Đỏ Huyết Ngục** (`core = Trắng`, `mid = #FF0824`, `edge = #B80012`, `accent = #FF5500`, `core_sharpness = 2.2`, `emission = 6.2`).
  - **Lưỡi Tầng Ngoài (`radius = 2.78m`, `width = 0.72m`, nghiêng lệch `15°`):** Sắc **Xanh Dương Lam Lôi** (`core = Trắng`, `mid = #0066FF`, `edge = #0022AA`, `accent = #00E5FF`, `core_sharpness = 2.2`, `emission = 6.2`).
- Cả 2 lưỡi đều gọi `_animate_lingering_power_slash(..., total_duration = 0.48, expand_scale = 1.25, forward_push = flat_fwd * 0.35)` — vệt kiếm vừa to vừa đọng lại trên không trung gần nửa giây!

### 5. Đòn `[U]` Nhịp 3 (U3) Ở Trạng Thái 2 — "HUYẾT LAM LONG THẦN GIÁNG" (5 Đại Kiếm Khí Xếp Cánh Quạt + Đọng Lại `0.58s`, `52.0 DMG`):
Khi `combo_idx == 3` và `is_rage == true`, gọi `spawn_u3_rage_crimson_cobalt_finale(tree, origin, forward_dir)`:
1. **Lớp 1 — Ngũ Đại Kiếm Khí Bổ Dọc Xếp Hình Cánh Quạt (`U3RageFiveBladeFan` — 5 Lưỡi Tách Rời Tuyệt Đối Không Bệt Mảng):**
   - Sinh **5 Lưỡi Đại Kiếm Khí 3D (`segments = 36`)** bổ từ trên cao xuống đất tại 5 góc xoay ngang (`yaw_off`) và bán kính (`radius`) tách biệt hoàn toàn:
     - **Lưỡi 1 (Chính giữa `yaw = 0°`, `radius = 2.85m`, `width = 1.05m`):** **Đỏ Huyết Tối Thượng** (`mid = #FF0824`, `edge = #990000`, `accent = #FF6600`).
     - **Lưỡi 2 (Cánh Trái Trong `yaw = -18°`, `roll = 72°`, `radius = 2.55m`):** **Xanh Dương Điện Quang** (`mid = #0066FF`, `edge = #001F99`, `accent = #00F0FF`).
     - **Lưỡi 3 (Cánh Phải Trong `yaw = +18°`, `roll = 108°`, `radius = 2.55m`):** **Xanh Dương Điện Quang** (`mid = #0066FF`, `edge = #001F99`, `accent = #00F0FF`).
     - **Lưỡi 4 (Cánh Trái Ngoài `yaw = -36°`, `roll = 58°`, `radius = 2.30m`):** **Đỏ Huyết Cực Quang** (`mid = #FF1A35`, `edge = #880015`, `accent = #0055FF`).
     - **Lưỡi 5 (Cánh Phải Ngoài `yaw = +36°`, `roll = 122°`, `radius = 2.30m`):** **Đỏ Huyết Cực Quang** (`mid = #FF1A35`, `edge = #880015`, `accent = #0055FF`).
   - Cả 5 lưỡi kiếm dùng `_animate_lingering_power_slash(..., total_duration = 0.58, expand_scale = 1.28, forward_push = flat_fwd * 0.42)`: Sau khi chém phập xuống đất, **5 đại kiếm khí Đỏ - Xanh vẫn ghim lại sừng sững trên mặt đất và phình to ra `1.28x` suốt `0.58 giây`**!
2. **Lớp 2 — Tam Trùng Vòng Lụa Xoáy Phân Tầng Đỏ - Xanh (`3 Staggered Cyclone Rings`):**
   - Bung 3 vòng lụa ở 3 bán kính khác nhau (không đè lên nhau) và tồn tại lâu **`0.62s`**:
     - Vòng Trong (`0.4m -> 2.2m`): **Đỏ Huyết `#FF0824`** xoay `+14 rad/s`.
     - Vòng Giữa (`1.2m -> 3.3m`): **Xanh Dương `#0066FF`** xoay ngược `-15 rad/s`.
     - Vòng Ngoài (`2.0m -> 4.3m`): **Đỏ Huyết & Lam Điện** xoay `+12 rad/s`.
3. **Lớp 3 — 4 Cột Lốc Xoáy Lụa Đỏ - Xanh (`4 Vertical Helix Pillars`):**
   - 2 cột lụa **Đỏ Huyết** và 2 cột lụa **Xanh Dương** xoắn kép vọt lên độ cao **`4.2m`** (cao hơn và rộng hơn `1.35x` so với Trạng thái 1), tồn tại **`0.56s`**.
4. **Lớp 4, 5, 6, 7 — Ấn Chú Nứt Đất Đọng Lại `1.1s`, Hoa Đăng Đỏ-Xanh, 56 Hạt Phun Trào & Đèn Xung Kích:**
   - 2 `Decal` (`scorch_02.png` màu Đỏ Huyết `#FF0824` rộng `5.2m` + `circle_05.png` màu Xanh Dương `#0077FF` rộng `4.6m`) đọng lại trên mặt đất **`1.10 giây`** mới mờ dần.

### 6. Tuyệt Kỹ `[I]` Ở Trạng Thái 2 — "HUYẾT LAM PHÁ KHÔNG THẬP TỰ TRẢM" (`36.0 + 44.0 = 80.0 DMG` Tổng):

#### PHA 1: Lướt 4 Tàn Ảnh Đỏ-Xanh & Lục Kiếm Khí Chữ X Tách 3 Tầng (`spawn_rmb_solar_cross_cleave` khi `is_rage == true`)
1. **4 Tàn Ảnh `.glb` KayKit Thật Đỏ - Xanh Dương:**
   - Khi lướt tới, sinh 4 tàn ảnh xen kẽ: **Đỏ Huyết (`#FF0824`) $\rightarrow$ Xanh Dương (`#0066FF`) $\rightarrow$ Đỏ Huyết $\rightarrow$ Xanh Dương**, tồn tại `0.42s`.
2. **Lục Kiếm Khí Chữ X Tách 3 Tầng Bán Kính (`RMBHexaRageXSlash` — 6 Lưỡi Rõ Từng Đường Nét, Không Bệt Mảng):**
   - Sinh **6 vòng cung kiếm khí 3D (`segments = 36`)** chia làm 2 vế chéo của chữ X, mỗi vế gồm **3 lưỡi xếp ở 3 tầng bán kính khác nhau (`1.95m`, `2.55m`, `3.15m`)**:
     - **Vế Chéo Phải (`roll = +38°`, `+44°`, `+50°`):** **3 Đại Kiếm Khí Đỏ Huyết Ngục (`#FF0824` / `#CC0011`)** ở bán kính `1.95m`, `2.55m`, `3.15m`.
     - **Vế Chéo Trái (`roll = -38°`, `-44°`, `-50°`):** **3 Đại Kiếm Khí Xanh Dương Lam Lôi (`#0055FF` / `#00C8FF`)** ở bán kính `1.95m`, `2.55m`, `3.15m`.
   - Cả 6 lưỡi kiếm chữ X áp dụng `_animate_lingering_power_slash(..., total_duration = 0.54, expand_scale = 1.28, forward_push = flat_fwd * 0.38)`: Chữ X khổng lồ 6 lưỡi Đỏ - Xanh **đọng lại giữa không trung hơn nửa giây và bung rộng ra tới `4.2m`**!

#### PHA 2: Đại Sóng Kiếm Khí 5 Cánh "Ngũ Dực Huyết Lam" Càn Quét `6.2m` & Đọng Lại Cuối Đường (`spawn_rmb_traveling_crescent_wave` khi `is_rage == true`)
1. **Kết Cấu Sóng Kiếm 5 Cánh Lụa Cong Khổng Lồ (`RMBFiveWingRageWave3D` — To Hơn `1.32x`):**
   - Khi `is_rage == true`, `travel_distance = 6.2m` (xa hơn mặc định `4.8m`), `wave_damage = 44.0 DMG`, và cấu trúc sóng kiếm nâng từ 3 cánh lên **5 Cánh Lụa Cong Tách Lớp**:
     - **Cánh 1 (Trung Tâm Dựng Đứng `84°`, `radius = 2.05m`, `width = 1.05m`):** **Đỏ Huyết Chủ Đạo (`#FF0824`)**.
     - **Cánh 2 & 3 (Cánh Nội Trái/Phải `±32°`, `radius = 2.20m`, dịch ngang `±0.35m`):** **Xanh Dương Điện Quang (`#0055FF` -> `#00E5FF`)**.
     - **Cánh 4 & 5 (Cánh Đại Bàng Mở Rộng `±58°`, `radius = 2.45m`, dịch ngang `±0.65m`):** **Đỏ Huyết Viền Lam (`#FF1122` -> `#0044FF`)**.
2. **Vệt Cày Mặt Đất Kéo Dài & Đọng Lại Cuối Hành Trình (`Lingering Finale Anchor`):**
   - Dọc đường bay `6.2m`, cứ mỗi `0.90m` bung ra 1 cặp vòng xoáy Đỏ - Xanh và ấn chú cháy đỏ-xanh tồn tại **`0.85s`**.
   - **Đặc biệt tại điểm cuối hành trình (`6.2m`):** Thay vì biến mất ngay khi chạm đích, 5 cánh của Đại Sóng Kiếm **dừng lại, ghim cố định tại điểm cuối thêm `0.35 giây` đồng thời phình to kích thước lên `1.35x`**, sau đó mới kích hoạt vụ nổ **Đại Tinh Vân Song Cực Đỏ - Xanh (`3.8m`)**!

---

## 🧪 TASK 26.5: KIỂM THỬ TỰ ĐỘNG 100% PASS (`test_phase_26_rage_state_and_lingering_red_blue_vfx.gd`) & ĐỒNG BỘ GITHUB (`AGENT-06`)

1. Cập nhật `ShaderPrewarmer` (`src_game/scripts/vfx/shader_prewarmer.gd`) nạp sẵn `_get_rage_crimson_cobalt_ramp()` và shader `vfx_stylized_slash.gdshader` mới để giữ vững **165Hz+ (0ms lag khi bấm `[R]`)**.
2. Viết và chạy kịch bản kiểm thử tự động `src_game/tests/test_phase_26_rage_state_and_lingering_red_blue_vfx.gd` xác nhận **PASS 100%** 5 bài kiểm tra:
   - **Test 26.1 (Phím `[F1]` Chơi Lại & Giải Phóng Phím `[R]`):** Xác nhận nút Restart hiển thị đúng `"🔄 CHƠI LẠI (Phím F1)"` và phím `[R]` không làm reload màn chơi mà kích hoạt Trạng thái 2.
   - **Test 26.2 (Vòng Đời Trạng Thái 2 `[R]`: 10.0s Duy Trì & 6.0s Hồi Chiêu):**
     - Kích hoạt `_activate_rage_state_2()` $\rightarrow$ Xác nhận `_is_rage_state_2 == true`, `_rage_active_timer == 10.0`, hào quang `RageState2AuraHolder` xuất hiện trên người nhân vật.
     - Mô phỏng trôi qua `10.05s` $\rightarrow$ Xác nhận `_is_rage_state_2 == false`, hào quang tự dọn sạch và `_cd_rage_r_timer` bắt đầu đếm lùi từ `6.0s`.
   - **Test 26.3 (Đòn U3 Trạng Thái 2 — 5 Đại Kiếm Khí Đỏ-Xanh Xếp Quạt, Đọng Lại `>= 0.50s` & `52.0 DMG`):**
     - Trong lúc `_is_rage_state_2 == true`, tung đòn đánh thứ 3 nút `[U]` $\rightarrow$ Xác nhận sinh đủ **5 lưỡi đại kiếm khí tách góc**, sau `0.38s` các lưỡi kiếm vẫn đang đọng lại và phình to (`scale.x > 1.10`), gây chính xác **`52.0 DMG`** lên Bot.
   - **Test 26.4 (Chiêu `[I]` Trạng Thái 2 — 6 Kiếm Khí Chữ X + Đại Sóng Kiếm 5 Cánh Bay `6.2m` & `80.0 DMG` Tổng):**
     - Trong lúc `_is_rage_state_2 == true`, kích hoạt kỹ năng `[I]` $\rightarrow$ Xác nhận Pha 1 sinh **6 lưỡi kiếm chữ X tách 3 tầng bán kính** (gây **`36.0 DMG`**) và Pha 2 phóng **Đại Sóng Kiếm 5 Cánh** bay xa `6.2m`, đọng lại ở cuối đường và gây **`44.0 DMG`** (Tổng **`80.0 DMG`**).
   - **Test 26.5 (Kiểm Định 0% Khối Thô `PrimitiveMesh == 0` & Bảo Toàn Phase 24/25):**
     - Quét toàn bộ SceneTree ngay lúc Trạng thái 2 đang tung cả U3 và I $\rightarrow$ Xác nhận **`primitive_count == 0`** và chạy lại suite Phase 24/25 xác nhận PASS 100%.
3. Chụp 2 ảnh màn hình thực tế trên GPU RTX 4060 khi nhân vật đang bật **Trạng Thái 2 (Hào quang Đỏ-Xanh)** tung đòn **U3 (5 đại kiếm khí Đỏ-Xanh)** và **Chiêu I (6 kiếm khí chữ X & Sóng 5 cánh)** lưu vào `docs/QA_REPORTS/screenshots/`, cập nhật báo cáo tiến độ, rồi `git commit` và `git push` lên `https://github.com/NhutPham19/GameWizad`.
```

---

### 📋 Câu lệnh ngắn gọn để bạn copy gửi cho Antigravity thực thi ngay:

```text
Hãy đọc kỹ file chỉ đạo: 26_ARGONS_SECOND_STATE_RAGE_MODE_R_AND_LINGERING_RED_BLUE_VFX.md và thực hiện chính xác, đầy đủ từ Task 26.1 đến Task 26.5:
1. Task 26.1: Chuyển phím "Chơi Lại" từ [R] sang [F1] (cập nhật nhãn nút trên HUD thành "🔄 CHƠI LẠI (Phím F1)") và giải phóng hoàn toàn phím [R] cho cơ chế Kích Hoạt Nộ (Trạng Thái 2).
2. Task 26.2: Xây dựng Trạng Thái Thứ 2 ("Huyết Lam Cuồng Nộ" khi nhấn phím [R]): Duy trì 10.0 giây, hồi chiêu 6.0 giây, tăng +45% sát thương, +15% tốc độ, nổ lốc xoáy Đỏ-Xanh khi kích hoạt và gắn Hào Quang Nộ Đỏ-Xanh dưới chân + quanh người suốt 10 giây. Hiển thị rõ trạng thái [R] trên thanh Cooldown HUD.
3. Task 26.3 & 26.4: Nâng cấp vfx_stylized_slash.gdshader (thu gọn lõi trắng core_sharpness = 2.2 để 85% thân kiếm hiện rõ màu Đỏ Huyết #FF0824 và Xanh Dương #0055FF sắc lẹm, tách lớp bán kính và góc nghiêng tuyệt đối không để bệt thành 1 mảng) và áp dụng cơ chế "Đọng Lại, Kéo Dài & Phình To Uy Lực" (_animate_lingering_power_slash):
   - Đòn [U] Nhịp 1 & 2 (Trạng thái 2): Song kiếm phân cực Đỏ - Xanh tách 2 tầng bán kính, đọng lại 0.48s, phình to 1.25x (36 DMG).
   - Đòn [U] Nhịp 3 (U3 Trạng thái 2): 5 Đại Kiếm Khí Đỏ - Xanh xếp hình cánh quạt (-36°, -18°, 0°, +18°, +36°) ghim đọng lại trên mặt đất 0.58s và phình to 1.28x + 3 vòng lụa xoáy phân tầng + 4 cột xoáy cao 4.2m (52 DMG).
   - Chiêu [I] (Trạng thái 2): Pha 1 lướt 4 tàn ảnh .glb Đỏ-Xanh + 6 Đại Kiếm Khí Chữ X tách 3 tầng bán kính đọng lại 0.54s (36 DMG); Pha 2 phóng Đại Sóng Kiếm 5 Cánh "Ngũ Dực Huyết Lam" to hơn 1.32x càn quét xa 6.2m, đọng lại ở điểm cuối thêm 0.35s rồi nổ Đại Tinh Vân Đỏ-Xanh (44 DMG, tổng 80 DMG).
4. Task 26.5: Giữ nguyên 100% vật lý cầu thang Phase 24 và luật 0% khối thô (PrimitiveMesh == 0), chạy test_phase_26_rage_state_and_lingering_red_blue_vfx.gd PASS 100%, chụp ảnh màn hình thực tế và git push lên GitHub https://github.com/NhutPham19/GameWizad!