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
