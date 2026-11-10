shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

// ==============================================================================
// VFX SHOCKWAVE DISTORTION SHADER - EXPANDING 3D VOLUMETRIC RING & ENERGY EDGE
// Task 5.6: Impact shockwaves, post-upgrade pulses & blast waves
// ==============================================================================

uniform vec4 shockwave_color : source_color = vec4(0.3, 0.85, 1.0, 1.0);
uniform float emission_energy : hint_range(1.0, 10.0) = 6.0;
uniform float ring_radius : hint_range(0.0, 1.0) = 0.5;
uniform float ring_thickness : hint_range(0.01, 0.4) = 0.12;
uniform float fade_progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 center_uv = UV - vec2(0.5);
    float dist = length(center_uv) * 2.0; // 0 at center, 1 at edge
    
    // Ring band
    float ring_dist = abs(dist - ring_radius);
    float ring_intensity = smoothstep(ring_thickness, 0.0, ring_dist);
    
    // Leading bright edge
    float edge_boost = smoothstep(ring_thickness * 0.3, 0.0, ring_dist);
    
    // Fade out over lifetime
    float alpha = ring_intensity * (1.0 - fade_progress) * shockwave_color.a;
    
    vec3 col = shockwave_color.rgb * (emission_energy + edge_boost * 3.0);
    
    ALBEDO = col;
    EMISSION = col;
    ALPHA = clamp(alpha, 0.0, 1.0);
}
