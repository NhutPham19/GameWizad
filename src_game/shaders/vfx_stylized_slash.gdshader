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
	float eff_prog = max(slash_progress, progress);
	float eff_emission = (emission_boost > 0.05) ? emission_boost : emission_strength;
	vec3 eff_mid = (mid_color != vec4(1.0, 0.85, 0.15, 1.0) || main_color == vec4(0.0, 0.85, 1.0, 1.0)) ? mid_color.rgb : main_color.rgb;

	// Hai lớp sóng năng lượng cuộn ngược chiều dọc theo lưỡi kiếm
	float n1 = value_noise(uv * vec2(dissolve_scale, dissolve_scale * 0.55) - vec2(TIME * 10.5, 0.0));
	float n2 = value_noise(uv * vec2(dissolve_scale * 1.9, dissolve_scale * 1.1) + vec2(TIME * 7.0, TIME * 3.0));
	float energy_flow = mix(n1, n2, 0.5);

	// Độ dày ngang của dải lụa kiếm khí (sáng rực ở sống kiếm, vát mượt ở 2 rìa)
	float radial = 1.0 - abs(uv.y * 2.0 - 1.0);
	radial = pow(clamp(radial, 0.0, 1.0), 0.72);

	// Mặt nạ đầu & đuôi vệt chém kết hợp tiến trình tan biến mượt mà
	float arc_mask = smoothstep(0.0, 0.10, uv.x) * (1.0 - smoothstep(0.84, 1.0, uv.x));
	float fade_curve = clamp(1.0 - eff_prog * (0.60 + (1.0 - uv.x) * tail_fade), 0.0, 1.0);

	float intensity = radial * arc_mask * (0.68 + 0.58 * energy_flow) * fade_curve;

	// Hạt tinh tú lấp lánh dọc theo đuôi kiếm khí
	float sparkle = step(0.85, n2) * smoothstep(0.12, 0.88, radial) * fade_curve;

	// Hòa trộn 4 tầng màu + Tán sắc Cực Quang (Prismatic Iridescence)
	float iridescence = clamp(sin(uv.x * 8.0 - TIME * 11.0 + n1 * 3.14) * 0.5 + 0.5, 0.0, 1.0) * chromatic_shift;
	vec3 outer_blend = mix(edge_color.rgb, accent_color.rgb, iridescence);
	vec3 col = mix(outer_blend, eff_mid, smoothstep(0.20, 0.60, intensity));
	col = mix(col, core_color.rgb, smoothstep(0.64, 0.90, intensity) + sparkle * 0.65);

	float alpha = clamp((intensity * 1.55 + sparkle * 0.85) * core_color.a, 0.0, 1.0);
	ALBEDO = col * eff_emission;
	ALPHA = alpha;
}
