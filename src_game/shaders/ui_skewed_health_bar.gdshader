shader_type canvas_item;

uniform float current_hp_ratio : hint_range(0.0, 1.0) = 0.85;
uniform float delayed_hp_ratio : hint_range(0.0, 1.0) = 0.95;
uniform float shield_ratio : hint_range(0.0, 1.0) = 0.25;
uniform float skew_angle : hint_range(-0.6, 0.6) = -0.28; // Nghiêng khung bình hành -15 độ
uniform vec4 hp_color_bright : source_color = vec4(1.0, 0.22, 0.28, 1.0);
uniform vec4 hp_color_dark : source_color = vec4(0.55, 0.04, 0.12, 1.0);
uniform vec4 catchup_color : source_color = vec4(1.0, 0.92, 0.55, 1.0); // Lớp máu tụt trễ trắng vàng
uniform vec4 border_color : source_color = vec4(0.95, 0.78, 0.35, 1.0);  // Viền vàng cổ ngữ

void fragment() {
    // Biến đổi tọa độ UV thành hình bình hành nghiêng sắc sảo
    vec2 uv = UV;
    uv.x += (uv.y - 0.5) * skew_angle;
    
    // Cắt bỏ phần nằm ngoài hình bình hành
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        COLOR = vec4(0.0);
    } else {
        // Kiểm tra khung viền kim loại cổ ngữ
        float border_x = 0.018;
        float border_y = 0.08;
        bool is_border = (uv.x < border_x || uv.x > 1.0 - border_x || uv.y < border_y || uv.y > 1.0 - border_y);
        
        // Hiệu ứng sóng năng lượng trôi bên trong thanh máu
        float wave = sin(uv.x * 18.0 - TIME * 4.5) * 0.04 + sin(uv.x * 35.0 + TIME * 2.5) * 0.02;
        vec4 bg_col = vec4(0.07, 0.06, 0.10, 0.88);
        vec4 final_col = bg_col;
        
        // Lớp 1: Thanh máu tụt trễ (Damage Catch-up Bar)
        if (uv.x <= delayed_hp_ratio && uv.x > current_hp_ratio) {
            float pulse = 0.85 + 0.15 * sin(TIME * 16.0);
            final_col = catchup_color * pulse;
        }
        // Lớp 2: Thanh máu thực tế có chuyển sắc Gradient + Sóng chảy
        else if (uv.x <= current_hp_ratio) {
            float grad = clamp(uv.y + wave, 0.0, 1.0);
            final_col = mix(hp_color_bright, hp_color_dark, grad);
            // Vệt sáng phản quang phía trên thanh máu
            if (uv.y > 0.15 && uv.y < 0.32) {
                final_col.rgb += vec3(0.22);
            }
            // Vạch sáng rực tại mép cắt máu hiện tại
            if (abs(uv.x - current_hp_ratio) < 0.012) {
                final_col = vec4(1.0, 0.95, 0.85, 1.0);
            }
        }
        
        // Vạch chia từng nấc 25% máu
        if (abs( fract(uv.x * 4.0) ) < 0.008 && uv.y < 0.45) {
            final_col.rgb *= 0.35;
        }
        
        // Áp viền vàng cổ ngữ ngoài cùng
        if (is_border) {
            final_col = border_color;
        }
        COLOR = final_col;
    }
}
