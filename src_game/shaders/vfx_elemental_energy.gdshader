shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

// ==============================================================================
// VFX ELEMENTAL ENERGY SHADER - PROCEDURAL FBM NOISE & HDR RADIANT FRESNEL
// Task 5.6: Wizard of Legend 2 Style Dynamic Energy for Fire, Wind, Ice, Lightning
// ==============================================================================

uniform vec4 core_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.9, 0.3, 1.0);
uniform float emission_energy : hint_range(1.0, 12.0) = 6.0;
uniform float scroll_speed_u : hint_range(-5.0, 5.0) = 1.2;
uniform float scroll_speed_v : hint_range(-5.0, 5.0) = 2.4;
uniform float noise_scale : hint_range(1.0, 20.0) = 6.0;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.2;
uniform float pulse_frequency : hint_range(0.0, 10.0) = 3.5;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.5)));
    for (int i = 0; i < 3; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 uv = UV * noise_scale;
    uv.x += TIME * scroll_speed_u;
    uv.y += TIME * scroll_speed_v;
    
    float n = fbm(uv);
    
    // Fresnel Rim Glow
    float fresnel = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
    fresnel = pow(fresnel, fresnel_power);
    
    // Pulsing energy
    float pulse = 0.85 + 0.15 * sin(TIME * pulse_frequency);
    
    vec3 col = mix(core_color.rgb, rim_color.rgb, clamp(fresnel + n * 0.4, 0.0, 1.0));
    col *= emission_energy * pulse;
    
    ALBEDO = col;
    EMISSION = col;
    ALPHA = clamp((fresnel * 0.7 + n * 0.5) * core_color.a, 0.15, 1.0);
}
