shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

// ==============================================================================
// ARGONS DIRECTIVE 25: PRISMATIC 5-STOP HDR OVERDRIVE SLASH SHADER
// 100% Backward Compatible + Prismatic Iridescence + Sparkle Dissolve
// ==============================================================================

uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.85, 0.15, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.2, 0.05, 1.0);
uniform vec4 accent_color : source_color = vec4(0.85, 0.1, 1.0, 1.0);
uniform float emission_strength : hint_range(1.0, 16.0) = 6.5;
uniform float slash_progress : hint_range(0.0, 1.0) = 0.0;
uniform float tail_fade : hint_range(0.1, 2.5) = 0.85;
uniform float chromatic_shift : hint_range(0.0, 1.0) = 0.55;
uniform float dissolve_scale : hint_range(2.0, 40.0) = 15.0;
uniform float core_sharpness : hint_range(0.5, 4.0) = 1.65;
uniform float hold_power : hint_range(0.0, 1.0) = 0.35;

// Backward Compatibility Aliases for Phase 20-24 callers
uniform vec4 main_color : source_color = vec4(0.0, 0.85, 1.0, 1.0);
uniform float emission_boost : hint_range(0.0, 16.0) = 0.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D slash_mask_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D streak_noise_tex : filter_linear_mipmap, repeat_enable;

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

	// Resolve compatibility parameters
	float eff_prog_raw = max(slash_progress, progress);
	float eff_prog = smoothstep(hold_power * 0.65, 1.0, eff_prog_raw);
	float eff_emission = (emission_boost > 0.05) ? emission_boost : emission_strength;
	vec3 eff_mid = (mid_color != vec4(1.0, 0.85, 0.15, 1.0) || main_color == vec4(0.0, 0.85, 1.0, 1.0)) ? mid_color.rgb : main_color.rgb;

	// Hai lớp sóng năng lượng cuộn dọc theo lưỡi kiếm
	float n1 = value_noise(uv * vec2(dissolve_scale, dissolve_scale * 0.55) - vec2(TIME * 11.0, 0.0));
	float n2 = value_noise(uv * vec2(dissolve_scale * 2.0, dissolve_scale * 1.15) + vec2(TIME * 7.5, TIME * 3.2));
	float energy_flow = mix(n1, n2, 0.5);

	// Độ dày ngang lưỡi kiếm: dùng core_sharpness để lưỡi kiếm sắc lẹm, không bị phình trắng xóa
	float radial = 1.0 - abs(uv.y * 2.0 - 1.0);
	float blade_body = pow(clamp(radial, 0.0, 1.0), 0.70);
	float razor_spine = pow(clamp(radial, 0.0, 1.0), 2.4 * core_sharpness);

	// Đường cong đọng lại (Hold Curve): Giữ nguyên độ sáng ở thời gian đầu, sau đó mới rút dần
	float arc_mask = smoothstep(0.0, 0.09, uv.x) * (1.0 - smoothstep(0.86, 1.0, uv.x));
	float fade_curve = clamp(1.0 - eff_prog * (0.55 + (1.0 - uv.x) * tail_fade), 0.0, 1.0);

	// Ăn mòn tàn lửa sắc nét khi đòn đánh tan dần
	float erosion = smoothstep(eff_prog * 0.72, eff_prog * 0.72 + 0.25, blade_body * (0.65 + 0.55 * energy_flow));
	float intensity = blade_body * arc_mask * erosion * fade_curve;

	// Tia lửa điện lấp lánh dọc lưỡi kiếm
	float sparkle = step(0.84, n2) * smoothstep(0.10, 0.90, radial) * fade_curve;

	// Hòa trộn màu sắc: Đảm bảo 85% thân kiếm mang màu chủ đạo (Đỏ Huyết / Xanh Dương), chỉ 15% sống kiếm trắng sáng
	float iridescence = clamp(sin(uv.x * 7.5 - TIME * 10.0 + n1 * 3.14) * 0.5 + 0.5, 0.0, 1.0) * chromatic_shift;
	vec3 outer_col = mix(edge_color.rgb, accent_color.rgb, iridescence);
	vec3 col = mix(outer_col, eff_mid, smoothstep(0.18, 0.62, intensity));
	col = mix(col, core_color.rgb, clamp(razor_spine * 1.15 + sparkle * 0.55, 0.0, 1.0));

	float alpha = clamp((intensity * 1.50 + sparkle * 0.85) * core_color.a, 0.0, 1.0);
	ALBEDO = col * eff_emission;
	ALPHA = alpha;
}
