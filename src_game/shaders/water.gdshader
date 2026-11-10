shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

// Stylized Translucent Water with Shoreline Foam (Biome 1 Purple / Biome 3 Emerald)
uniform vec4 deep_color : source_color = vec4(0.25, 0.08, 0.38, 0.9);
uniform vec4 shallow_color : source_color = vec4(0.45, 0.2, 0.6, 0.7);
uniform vec4 foam_color : source_color = vec4(0.9, 0.85, 1.0, 1.0);
uniform float foam_distance : hint_range(0.01, 1.0) = 0.25;

uniform float wave_speed : hint_range(0.1, 5.0) = 1.2;
uniform float wave_strength : hint_range(0.01, 0.5) = 0.06;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.5;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

void vertex() {
    float wave = sin(VERTEX.x * wave_frequency + TIME * wave_speed) * cos(VERTEX.z * wave_frequency + TIME * wave_speed);
    VERTEX.y += wave * wave_strength;
}

void fragment() {
    float depth = texture(depth_texture, SCREEN_UV).r;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view.xyz /= view.w;
    float linear_depth = -view.z;
    float water_depth = linear_depth - (-VERTEX.z);
    
    // Shoreline foam edge
    float foam_factor = clamp(1.0 - (water_depth / foam_distance), 0.0, 1.0);
    foam_factor = step(0.5, foam_factor);
    
    vec4 water_color = mix(shallow_color, deep_color, clamp(water_depth * 0.8, 0.0, 1.0));
    vec3 final_color = mix(water_color.rgb, foam_color.rgb, foam_factor * foam_color.a);
    
    ALBEDO = final_color;
    ALPHA = mix(water_color.a, 1.0, foam_factor);
    ROUGHNESS = 0.1;
    METALLIC = 0.0;
    SPECULAR = 0.8;
}
