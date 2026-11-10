shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 magma_bright : source_color = vec4(1.0, 0.82, 0.25, 1.0);
uniform vec4 magma_mid : source_color = vec4(0.95, 0.28, 0.05, 1.0);
uniform vec4 crust_dark : source_color = vec4(0.12, 0.06, 0.05, 1.0);
uniform float emission_power : hint_range(1.0, 3.8) = 2.8;
uniform float life_fade : hint_range(0.0, 1.0) = 1.0;

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453);
    float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
    float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
    float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec2 uv = UV;
    float center_dist = abs(uv.y - 0.5) * 2.0;
    float end_fade = smoothstep(0.0, 0.12, uv.x) * smoothstep(1.0, 0.88, uv.x);

    // Tạo đường nứt zic-zac dọc theo chiều dài vết nứt
    float n1 = noise(vec2(uv.x * 14.0 - TIME * 1.8, uv.y * 6.0));
    float n2 = noise(vec2(uv.x * 28.0 + TIME * 1.2, uv.y * 12.0));
    float crack_width = (0.45 + 0.35 * n1) * end_fade * life_fade;

    if (center_dist > crack_width + 0.25) {
        ALPHA = 0.0;
    } else if (center_dist > crack_width) {
        // Viền đá cháy đen quanh mép vết nứt
        ALBEDO = crust_dark.rgb;
        ALPHA = smoothstep(crack_width + 0.25, crack_width, center_dist);
    } else {
        // Lõi dung nham nóng chảy cuộn bên trong
        float core_heat = clamp(1.0 - (center_dist / max(crack_width, 0.001)) + (n2 - 0.5) * 0.4, 0.0, 1.0);
        vec3 col = mix(magma_mid.rgb, magma_bright.rgb, smoothstep(0.4, 0.9, core_heat));
        ALBEDO = col * emission_power;
        ALPHA = 1.0;
    }
}
