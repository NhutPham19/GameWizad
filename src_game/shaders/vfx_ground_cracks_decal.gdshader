shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

// ==============================================================================
// VFX GROUND CRACKS DECAL SHADER - PROCEDURAL FISSURES & RADIANT EMISSION
// Task 5.6: Ground slam & AoE decals (Lava fissures, Frost frostbite, Arcane runes)
// ==============================================================================

uniform vec4 crack_glow_color : source_color = vec4(1.0, 0.4, 0.1, 1.0);
uniform vec4 surface_color : source_color = vec4(0.12, 0.08, 0.06, 0.9);
uniform float emission_energy : hint_range(1.0, 12.0) = 5.5;
uniform float crack_scale : hint_range(2.0, 30.0) = 10.0;
uniform float crack_width : hint_range(0.01, 0.25) = 0.08;
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 voronoi(vec2 p) {
    vec2 n = floor(p);
    vec2 f = fract(p);
    float md = 8.0;
    vec2 mr = vec2(0.0);
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = vec2(hash(n + g), hash(n + g + vec2(1.0)));
            vec2 r = g + o - f;
            float d = dot(r, r);
            if (d < md) {
                md = d;
                mr = r;
            }
        }
    }
    return vec2(sqrt(md), hash(n + mr));
}

void fragment() {
    vec2 center_uv = UV - vec2(0.5);
    float dist = length(center_uv) * 2.0; // 0.0 at center, 1.0 at edge
    
    vec2 v = voronoi(UV * crack_scale);
    float cell_dist = v.x;
    
    // Crack line logic: edges between cells
    float crack = smoothstep(crack_width, 0.0, cell_dist);
    
    // Radial boundary
    float radial_mask = smoothstep(1.0 - dissolve_progress, 0.3 - dissolve_progress, dist);
    
    vec3 col = mix(surface_color.rgb, crack_glow_color.rgb * emission_energy, crack);
    
    ALBEDO = col;
    EMISSION = crack_glow_color.rgb * (crack * emission_energy);
    ALPHA = clamp((surface_color.a * (1.0 - dissolve_progress) + crack) * radial_mask, 0.0, 1.0);
}
