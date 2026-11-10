shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_front, unshaded;

// Bold Comic/Cel-Shaded Ink Outline
uniform vec4 outline_color : source_color = vec4(0.05, 0.05, 0.08, 1.0);
uniform float outline_width : hint_range(0.0, 0.15) = 0.035;

void vertex() {
    // Extrude along normal in view or object space
    vec3 normal = normalize(NORMAL);
    VERTEX += normal * outline_width;
}

void fragment() {
    ALBEDO = outline_color.rgb;
    ALPHA = outline_color.a;
}
