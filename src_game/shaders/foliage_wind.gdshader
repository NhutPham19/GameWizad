shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon;

// Stylized Wind Shader for Trees & Vegetation
uniform vec4 foliage_color : source_color = vec4(0.28, 0.45, 0.22, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.12, 0.2, 0.1, 1.0);
uniform float wind_speed : hint_range(0.1, 8.0) = 2.2;
uniform float wind_strength : hint_range(0.0, 0.5) = 0.12;

void vertex() {
    // Sway more at the top of the tree/foliage (VERTEX.y > 0)
    float height_factor = max(0.0, VERTEX.y);
    float sway = sin(TIME * wind_speed + (NODE_POSITION_WORLD.x + VERTEX.x) * 0.8) * wind_strength * height_factor;
    float sway_z = cos(TIME * wind_speed * 0.8 + (NODE_POSITION_WORLD.z + VERTEX.z) * 0.8) * (wind_strength * 0.7) * height_factor;
    VERTEX.x += sway;
    VERTEX.z += sway_z;
}

void fragment() {
    ALBEDO = foliage_color.rgb;
    ROUGHNESS = 0.9;
    METALLIC = 0.0;
}

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float factor = step(0.1, NdotL);
    vec3 col = mix(shadow_color.rgb, foliage_color.rgb, factor);
    DIFFUSE_LIGHT += col * LIGHT_COLOR * ATTENUATION;
}
