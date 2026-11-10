shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

// Wizard of Legend 2 Style - Cel-Shaded Toon Material
uniform vec4 albedo_color : source_color = vec4(0.9, 0.9, 0.9, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 shadow_tint : source_color = vec4(0.4, 0.45, 0.55, 1.0);

// Cel thresholds
uniform float light_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float light_smoothness : hint_range(0.001, 0.2) = 0.04;
uniform float mid_threshold : hint_range(0.0, 1.0) = 0.15;

// Rim lighting
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.6;
uniform float rim_smoothness : hint_range(0.001, 0.2) = 0.05;

// Emission (For glowing magic, runes, eyes)
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 16.0) = 0.0;

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = albedo_color.rgb * tex.rgb;
    ALPHA = albedo_color.a * tex.a;
    EMISSION = emission_color.rgb * emission_energy;
    ROUGHNESS = 0.8;
    METALLIC = 0.0;
}

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float light_factor = smoothstep(light_threshold - light_smoothness, light_threshold + light_smoothness, NdotL);
    float mid_factor = smoothstep(mid_threshold - light_smoothness, mid_threshold + light_smoothness, NdotL);

    vec3 light_color_stepped = mix(shadow_tint.rgb, vec3(0.75), mid_factor);
    light_color_stepped = mix(light_color_stepped, vec3(1.0), light_factor);

    // Rim highlight
    float NdotV = 1.0 - dot(NORMAL, VIEW);
    float rim_factor = smoothstep(rim_threshold - rim_smoothness, rim_threshold + rim_smoothness, NdotV * NdotL);
    vec3 final_rim = rim_color.rgb * rim_factor * rim_color.a;

    DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * light_color_stepped * ATTENUATION + final_rim;
}
