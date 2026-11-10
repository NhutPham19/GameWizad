shader_type canvas_item;

uniform float cooldown_progress : hint_range(0.0, 1.0) = 0.0; // 0.0 = Sẵn sàng, 1.0 = Vừa bấm chiêu
uniform float ready_flash : hint_range(0.0, 1.0) = 0.0;       // Nháy sáng khi vừa hồi xong
uniform vec4 element_rim_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform vec4 frame_gold_color : source_color = vec4(0.92, 0.76, 0.38, 1.0);

void fragment() {
    vec2 centered = UV - vec2(0.5);
    // Khoảng cách Manhattan tạo khung Hình Thoi xoay 45 độ
    float manhattan_dist = abs(centered.x) + abs(centered.y);
    
    if (manhattan_dist > 0.5) {
        COLOR = vec4(0.0);
    } else {
        vec4 tex_col = texture(TEXTURE, UV);
        vec4 bg_col = mix(vec4(0.08, 0.09, 0.14, 0.92), element_rim_color * 0.35, UV.y);
        vec4 col = mix(bg_col, tex_col, tex_col.a);
        
        // Hiệu ứng quét góc kim đồng hồ khi đang Cooldown (Radial Sweep)
        if (cooldown_progress > 0.001) {
            float angle = atan(centered.x, -centered.y); // -PI đến PI tính từ đỉnh 12 giờ
            float norm_angle = (angle + 3.14159265) / (2.0 * 3.14159265);
            if (norm_angle <= cooldown_progress) {
                col.rgb *= 0.25; // Làm tối vùng chưa hồi xong
            } else if (abs(norm_angle - cooldown_progress) < 0.02) {
                col.rgb = vec3(1.0, 0.9, 0.6); // Kim quét phát sáng
            }
        }
        
        // Viền trong phát sáng màu nguyên tố & Viền ngoài vàng kim
        if (manhattan_dist > 0.455) {
            col = frame_gold_color;
        } else if (manhattan_dist > 0.415) {
            col = element_rim_color * (cooldown_progress > 0.0 ? 0.4 : 1.35);
        }
        
        // Hiệu ứng bừng sáng khi kỹ năng vừa hồi xong
        col.rgb += vec3(ready_flash * 0.85);
        COLOR = col;
    }
}
