shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 core_color : source_color = vec4(0.35, 0.65, 1.0, 1.0);
uniform vec4 outer_color : source_color = vec4(0.58, 0.25, 0.95, 1.0);
uniform float emission_strength : hint_range(0.5, 3.8) = 2.6;

float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 centered = (UV - vec2(0.5)) * 2.0;
    float r = length(centered);
    float angle = atan(centered.y, centered.x);

    if (r > 1.0) {
        ALPHA = 0.0;
    } else {
        // Vòng tròn ngoại vi và nội vi xoay ngược chiều
        float outer_ring = smoothstep(0.035, 0.0, abs(r - 0.92));
        float inner_ring = smoothstep(0.025, 0.0, abs(r - 0.58));

        // Ngôi sao cổ ngữ 8 cánh xoay chậm
        float star_angle = angle + TIME * 0.8;
        float rune_star = smoothstep(0.04, 0.0, abs(r - (0.72 + 0.14 * cos(star_angle * 8.0))));

        // Các ký tự cổ ngữ phân đoạn trên vành đai (Rune Segments)
        float rune_band = step(0.62, r) * step(r, 0.86);
        float seg = sin(angle * 24.0 - TIME * 2.5) * cos(r * 40.0);
        float runes = rune_band * smoothstep(0.45, 0.85, seg) * 0.65;

        // Sóng xung điện lan từ tâm ra ngoài
        float pulse_wave = fract(r * 2.0 - TIME * 1.6);
        float electric_pulse = smoothstep(0.12, 0.0, abs(pulse_wave - 0.5)) * (1.0 - r);

        // Tia hồ quang zic-zac ngẫu nhiên
        float arc_noise = sin(angle * 16.0 + TIME * 18.0 + sin(r * 25.0 - TIME * 10.0) * 2.5);
        float lightning_web = smoothstep(0.92, 0.99, arc_noise) * (1.0 - r * 0.5);

        float pattern = clamp(outer_ring * 1.4 + inner_ring + rune_star * 0.9 + runes + electric_pulse * 0.7 + lightning_web * 1.5, 0.0, 1.0);
        float edge_fade = smoothstep(1.0, 0.88, r);

        vec3 col = mix(outer_color.rgb, core_color.rgb, clamp(lightning_web + outer_ring, 0.0, 1.0));
        ALBEDO = col * emission_strength;
        ALPHA = clamp(pattern * edge_fade * 0.85, 0.0, 0.9);
    }
}
