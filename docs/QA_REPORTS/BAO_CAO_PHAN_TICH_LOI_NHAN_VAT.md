# 📋 BÁO CÁO PHÂN TÍCH CHUYÊN SÂU NGUYÊN NHÂN LỖI NHÂN VẬT VÀ GIẢI PHÁP KHẮC PHỤC TRIỆT ĐỂ
- **Dự án:** GameWizad (3D Action Roguelike - Wizard of Legend 2 Style)
- **Đơn vị phân tích:** Antigravity AI Engineering Team
- **Người chỉ đạo:** Kiến trúc trưởng ARGONS
- **Ngày lập:** 08/11/2026

---

## 1. TRẢ LỜI CÂU HỎI TRỌNG TÂM CỦA USER

> **Câu hỏi:** *"Lỗi nhân vật, do đâu, do nhân vật không có hay sao?"*

### ➡️ KẾT LUẬN XÁC ĐỊNH:
**HOÀN TOÀN KHÔNG PHẢI DO THIẾU NHÂN VẬT.**
Mô hình 3D của cả 2 nhân vật (`Knight.glb` cho Solaris và `Rogue_Hooded.glb` cho Nyx) đã có sẵn đầy đủ 100% trong thư mục dự án `src_game/assets/characters/`. Cả hai đều sở hữu hệ xương chuẩn 41 khớp (`Rig/Skeleton3D`), kết nối với cây hoạt ảnh 3 tầng `AnimationTree` và 76 hoạt ảnh chuyển động KayKit mượt mà.

Nguyên nhân nhân vật bị biến dạng, đen sì, lóa sáng hoặc nham nhở nét đen trong 3 bức ảnh người dùng cung cấp xuất phát từ **4 LỖI KỸ THUẬT VỀ SHADER, VẬT LIỆU, MESH TRÙNG LẶP VÀ SIGNAL HUD**.

---

## 2. PHÂN TÍCH CHI TIẾT 4 NGUYÊN NHÂN GÂY LỖI TRONG 3 ẢNH CHỤP

| Hình ảnh ghi nhận | Hiện tượng lỗi thực tế | Nguyên nhân kỹ thuật gốc rễ |
| :--- | :--- | :--- |
| **Ảnh 1 (Nyx)** | Toàn thân Nyx biến thành một **khối bóng đen sì (Silhouette)**, không thấy mặt mũi, áo giáp, chi tiết da hay thắt lưng. Tay cầm một khối hồng/trắng lạ. Máu hiển thị `0 / 120 HP`. | **Lỗi Material Override:** Code tự tạo `ShaderMaterial` với màu tím đậm `#2A1B4E` và gán vào `material_override`. Việc này **xóa sổ hoàn toàn Texture gốc** của KayKit (`Rogue_Hooded_rogue_texture.png`). Vì shader không nạp texture, toàn bộ cơ thể bị nhuộm một màu tối đồng nhất, biến thành bóng đen. Khối hồng trên tay là cuốn sách cổ (`spellbook_open.gltf`). |
| **Ảnh 2 (Solaris)** | Thân Solaris phát sáng trắng bệch mất chi tiết, đầu và mũ giáp bị **các vệt đen ngoằn ngoèo nham nhở** bao phủ như bị cào mực. | **Lỗi Z-Fighting Viền Mực (Inverted Hull) & Mesh Trùng:** Trong `Knight.glb`, cả 2 node `Knight_Helmet` (Mũ giáp) và `Knight_Head` (Đầu người) đều được bật `visible = true`. Khi shader viền mực `ink_outline.gdshader` thổi phồng vertex ra ngoài, các mặt viền đen của `Knight_Head` bên trong đâm xuyên qua mũ giáp bên ngoài, tạo nên các vệt đen xước nham nhở. |
| **Ảnh 3 (Nyx)** | Phần đầu của Nyx biến thành **một quả cầu ánh sáng Cyan rực sáng chói lóa (Nuclear Glow)** che khuất toàn bộ khuôn mặt, cổ và ngực. Máu hiển thị `0 / 120 HP` kèm `80 Giáp`. | **Lỗi HDR Emission Overexposure:** Shader gán màu phát xạ Cyan `#00E5FF` với hệ số năng lượng `emission_energy = 2.2` lên toàn bộ mesh đầu/mũ trùm. Khi qua bộ xử lý WorldEnvironment Glow/Bloom của Forward+ Vulkan, ánh sáng bị khuếch đại cực đại thành khối cầu trắng-lam lóa mắt. |

---

## 3. TẠI SAO HUD HIỂN THỊ "0 / 120 HP" KHI ĐANG ĐIỀU KHIỂN NYX?

Có 2 lý do kết hợp dẫn đến con số bất thường này:
1. **Lỗi rò rỉ Signal kết nối (`Signal Leak`):**
   - Trong `combat_hud.gd`, khi người chơi chuyển từ Solaris sang Nyx bằng phím `[2]`, hàm `hook_hero()` kết nối signal `health_changed` của Nyx nhưng **không ngắt kết nối (`disconnect`)** với Solaris.
   - Khi Solaris (tướng trước) chịu đòn hoặc cạn máu về `0`, signal của Solaris vẫn kích hoạt hàm `_on_hero_health_changed(0, 120)` trên HUD, ghi đè con số `0 / 120 HP` lên thanh máu của Nyx.
2. **Cơ chế thừa hưởng tỷ lệ máu khi đổi tướng:**
   - Trong `hero_manager.gd`, code cũ tính tỷ lệ máu: `hp_ratio = clamp(active_hero.current_hp / active_hero.max_hp, 0.05, 1.0)`.
   - Nếu tướng trước bị quái vật đánh tụt máu gần chết, tướng mới khi xuất hiện cũng bị ép tỷ lệ máu xuống gần bằng `0`, khiến người chơi vừa chuyển tướng đã thấy thanh máu cạn kiệt.

---

## 4. CÁC BIỆN PHÁP ĐÃ THỰC THI ĐỂ KHẮC PHỤC TRIỆT ĐỂ

### 🛠️ 1. Bảo toàn 100% Texture Gốc KayKit & Tích hợp Toon Cel-Shading
- **Trước đây:** Dùng `mi.material_override = armor_mat / purple_mat` (xóa mất texture gốc).
- **Hiện tại:** Duyệt qua từng Surface của Mesh, gọi `orig_mat.duplicate()`. Giữ nguyên 100% `albedo_texture` gốc họa sĩ (`Knight_knight_texture.png` và `Rogue_Hooded_rogue_texture.png`), chỉ tinh chỉnh:
  - `diffuse_mode = BaseMaterial3D.DIFFUSE_TOON`: Đổ bóng hoạt hình phân bậc sắc nét.
  - `specular_mode = BaseMaterial3D.SPECULAR_TOON`: Điểm sáng kim loại toon.
  - **Solaris:** Giữ nguyên vân giáp trắng bạch kim, phủ màu Vàng Hoàng Gia (`Color(1.0, 0.72, 0.15)`) độc quyền cho áo choàng `Knight_Cape`.
  - **Nyx:** Phủ màu Tím Huyền Bí sang trọng (`Color(0.85, 0.75, 1.1)`) lên giáp da mà vẫn nhìn rõ từng đường chỉ, đai lưng và túi đựng tên.

### 🛠️ 2. Triệt tiêu lỗi đen mặt Solaris (Ẩn `Knight_Head`)
- Thêm lệnh `_set_node_visible(character_instance, "Knight_Head", false)` khi tạo nhân vật Solaris.
- Chỉ giữ lại duy nhất mũ giáp hiệp sĩ `Knight_Helmet`, loại bỏ 100% hiện tượng 2 mesh lồng nhau gây đâm xuyên viền mực. Mũ giáp giờ đây sáng bóng, viền đen sắc cạnh không còn vết xước.

### 🛠️ 3. Kiểm soát mức phát sáng (Emission Tuning)
- Hạ hệ số phát quang `emission_energy_multiplier` từ mức chói lóa `2.2` xuống mức dễ chịu `0.25` - `0.35`. Khăn trùm đầu của Nyx phát ánh huỳnh quang dịu mắt trong bóng tối, không làm cháy sáng khuôn mặt.
- Điều chỉnh độ dày viền mực `outline_width` từ `0.035` xuống `0.022` để đường viền đen mảnh dẻ, tinh tế chuẩn truyện tranh comic.

### 🛠️ 4. Sửa dứt điểm Signal & Hiển thị Máu HUD
- Trong `combat_hud.gd`: Thêm cơ chế tự động ngắt kết nối signal của tướng cũ trước khi nạp tướng mới.
- Trong `hero_manager.gd`: Tỷ lệ máu tối thiểu khi đổi tướng được nâng lên mức an toàn `0.25` (tối thiểu 25 HP), không để tướng mới vừa xuất hiện đã bị 0 HP. Đồng thời phát lệnh `health_changed` tức thì để cập nhật chuẩn xác `95/95 HP` cho Nyx và `120/120 HP` cho Solaris.

---

## 5. KẾT QUẢ NGHIỆM THU

1. **Headless Test Suite:** 18/18 Bài kiểm thử đạt **100% PASS** ghi nhận tại `docs/QA_REPORTS/HEADLESS_TEST_RESULTS.json`.
2. **GPU Forward+ (RTX 4060):** 4 ảnh chụp mới đã được xuất vào `docs/QA_REPORTS/screenshots/directive_12_solaris_nyx_1..4.png`.
3. **Trải nghiệm thực tế:** Khởi động bằng file `PLAY_GAME_WIZAD.bat` hoặc `CHAY_GAME_3D.bat`, nhân vật hiển thị rõ nét từng hoa văn, khuôn mặt, áo choàng, màu sắc hài hòa và thanh máu nhảy chính xác 100%.
