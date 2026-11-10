shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform sampler2D noise_tex_primary : source_color, repeat_enable;
uniform sampler2D noise_tex_secondary : source_color, repeat_enable;
uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.28, 0.05, 1.0);
uniform float emission_power : hint_range(1.0, 12.0) = 5.5;
uniform vec2 scroll_speed_1 = vec2(1.2, 0.8);
uniform vec2 scroll_speed_2 = vec2(-0.7, 1.4);
uniform float erosion_threshold : hint_range(0.0, 1.0) = 0.22;
uniform float proximity_fade_dist : hint_range(0.05, 2.0) = 0.45;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

void vertex() {
    // Biến dạng nhẹ bề mặt 3D theo sóng năng lượng
    float disp = sin(VERTEX.x * 6.0 + TIME * 10.0) * cos(VERTEX.z * 6.0 - TIME * 8.0) * 0.06;
    VERTEX += NORMAL * disp;
}

void fragment() {
    // Cuộn 2 lớp vân nhiễu ngược chiều nhau
    float n1 = texture(noise_tex_primary, UV + TIME * scroll_speed_1).r;
    float n2 = texture(noise_tex_secondary, UV * 1.5 + TIME * scroll_speed_2).r;
    float combined_noise = n1 * 0.65 + n2 * 0.35;
    
    // Hiệu ứng Fresnel phát sáng viền 3D
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
    
    // Alpha Erosion: Ăn mòn viền tạo hình ngọn lửa/tàn năng lượng thật
    float life_alpha = COLOR.a;
    float erode_cutoff = mix(1.0, erosion_threshold, life_alpha);
    float alpha_mask = smoothstep(erode_cutoff, erode_cutoff + 0.14, combined_noise);
    
    // SỬA TRIỆT ĐỂ LỖI MẤT CHIÊU Ở NỬA PHẢI MÀN HÌNH TRÊN CAMERA ORTHOGONAL (ARGONS HOTFIX 10.2)
    float soft_fade = 1.0;
    if (proximity_fade_dist > 0.001) {
        float depth_raw = texture(depth_texture, SCREEN_UV).r;
        vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_raw, 1.0);
        // Kiểm tra PROJECTION_MATRIX[3][3]: Bằng 1.0 là Orthogonal, bằng 0.0 là Perspective
        bool is_ortho = abs(PROJECTION_MATRIX[3][3] - 1.0) < 0.01;
        if (is_ortho) {
            // Trên Camera Orthogonal, giữ nguyên 100% độ rõ nét của hạt và lưới 3D trên toàn màn hình
            soft_fade = 1.0;
        } else {
            float scene_depth = -upos.z / upos.w;
            float fragment_depth = -VERTEX.z;
            soft_fade = clamp((scene_depth - fragment_depth) / proximity_fade_dist, 0.25, 1.0);
        }
    }
    
    // Phối màu Lõi trắng nóng (Core) và Quầng nguyên tố (Edge)
    vec4 final_color = mix(edge_color, core_color, smoothstep(0.45, 0.82, combined_noise - fresnel * 0.3));
    
    ALBEDO = final_color.rgb * emission_power;
    ALPHA = clamp(alpha_mask * soft_fade * life_alpha, 0.0, 1.0);
}
