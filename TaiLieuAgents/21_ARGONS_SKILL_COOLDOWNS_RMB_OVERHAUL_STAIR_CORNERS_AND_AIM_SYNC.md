# 👑 CHỈ ĐẠO SỐ 21 TỪ ARGONS: ĐẶC TẢ KỸ THUẬT CHI TIẾT & ĐỀ XUẤT CẢI TIẾN NÂNG CAO (CHIÊU E/Q/RMB, CHỐNG KẸT BẬC THANG, ĐỆM TƯỜNG & ĐỒNG BỘ HƯỚNG ĐÁNH)

- **Người chỉ đạo (Chief Architect):** ARGONS
- **Đơn vị thực thi:** ANTIGRAVITY IDE (`Claude Opus 4.6` / `Gemini 3.8 Flash`)
- **Kho GitHub dự án:** `https://github.com/NhutPham19/GameWizad`
- **Luật Thép Bất Di Bất Dịch:**
  1. **Tuyệt đối $0\%$ Khối Hình Học Thô (`PRIMITIVE MESHES == 0`):** Nghiêm cấm khởi tạo `BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PrismMesh`, `TorusMesh`. Mọi hiệu ứng hình học 3D bắt buộc dựng bằng `ArrayMesh` (dải lụa/cung kiếm uốn cong dùng `vfx_stylized_slash.gdshader`), `GPUParticles3D` (từ kho `src_game/assets/vfx_textures/`) và `Decal`.
  2. **Không làm hỏng hệ thống xương `KayKitAnimationBinder` và tốc độ khung hình $\ge 120\text{ FPS}$.**

---

## 💡 TỔNG HỢP CÁC ĐỀ XUẤT CẢI TIẾN NÂNG CAO (PROPOSED IMPROVEMENTS)

Qua phân tích 6 yêu cầu nâng cấp, nếu chỉ sửa theo cách thông thường sẽ phát sinh các lỗi biên (edge-cases) trong thực chiến. Dưới đây là **6 Đề Xuất Cải Tiến Nâng Cao** được tích hợp thẳng vào hướng dẫn code bên dưới:

| Hạng mục | Cách làm cơ bản (Dễ phát sinh lỗi phụ) | Đề xuất cải tiến chuyên sâu (Áp dụng trong Chỉ Đạo 21) |
| :--- | :--- | :--- |
| **1. Chiêu E (Ném Bom Lôi Vụ)** | Chỉ cắt khoảng cách $\le 7.5\text{m}$ trên mặt phẳng (dễ làm bom rơi xuyên vào trong tường dày hoặc rơi xuống vực tầng dưới). | **Cải tiến 1A:** Quỹ đạo bay hình Parabol mượt trong $0.25\text{s}$ + **Tia kiểm tra chống ném xuyên tường & Bắt dính mặt sàn đa tầng (`Multi-Tier Ground Snap`)**.<br>**Cải tiến 1B:** Hiển thị vòng ranh giới `Decal` điện tím rõ ràng và hiệu ứng **Tê Liệt Điện (`Shock Slow 55%`)** đổi màu thân Bot + nhảy số sát thương tím `-8` mỗi $0.5\text{s}$. |
| **2. Cooldown Chiêu Q & Bộ Kỹ Năng** | Khóa cứng phím `Q` trong $5.0\text{s}$ (nếu người chơi bấm sớm $0.1\text{s}$ trước khi hồi xong sẽ bị mất lệnh). | **Cải tiến 2A:** Thêm **Bộ đệm thao tác (`Input Buffering 0.18s`)** giúp tự động tung chiêu ngay khi vừa hết Cooldown hoặc vừa kết thúc nhịp đánh trước.<br>**Cải tiến 2B:** Lốc kiếm `Q` có **Lực Hút Chân Không nhẹ (`Vacuum Pull`)** giữ Bot không bị văng ra ngoài vòng kiếm, kèm đồng hồ đếm ngược trực quan trên HUD. |
| **3. Chiêu Chuột Phải (RMB Mới)** | Thay bằng một nhát chém mạnh hơn bình thường. | **Cải tiến 3A — Tuyệt kỹ *"Thánh Kiếm Phá Không Trảm" (`Solar Cross-Cleave`)*:** Chia làm **2 tầng sát thương liên hoàn** (Tầng 1: Lướt chém chữ thập `X-Slash` $25\text{ DMG}$ phá giáp $\rightarrow$ Tầng 2: Sóng kiếm khí mặt đất phát nổ $30\text{ DMG}$, tổng $55\text{ DMG}$).<br>**Cải tiến 3B:** Lướt bám sát mặt dốc cầu thang (không bị bay lơ lửng khi dùng RMB trên cầu thang) + Hiệu ứng khựng khung hình uy lực (`Hit-Stop 0.035s`). |
| **4. Chống đi sát bị tường/tượng che** | Chỉ tăng bán kính `CapsuleShape3D` lên quá to (làm nhân vật đi qua khe hẹp nặng nề). | **Cải tiến 4A — Đệm Đẩy Đàn Hồi Kép (`Soft Wall Repulsion Cushion`):** Tăng nhẹ `CapsuleShape3D.radius` từ $0.38\text{m} \rightarrow 0.45\text{m}$ kết hợp lực đệm đàn hồi 8 tia ngang giữ khoảng cách an toàn $0.52\text{m}$ với tường/tượng.<br>**Cải tiến 4B — Chống Che Khuất Góc Nhìn Camera (`Camera Occlusion X-Ray / Fade`):** Khi nhân vật đi ra phía sau tượng đá cao hoặc tường tầng, tự động làm trong suốt nhẹ vật cản đó (hoặc bật viền sáng Silhouette) để người chơi luôn nhìn thấy $100\%$ nhân vật! |
| **5. Sửa góc lag & đi xuyên bậc thang** | Chỉ đặt thêm 2 tấm chắn phẳng ở 2 bên hông cầu thang (dễ làm nhân vật bị vướng vào mép tấm chắn khi đi ngang chân thang). | **Cải tiến 5A — Kết Cấu Cầu Thang Nguyên Khối Kín Khít (`Watertight Stair Monolith`):** Gồm (1) Khối đặc bịt kín gầm thang, (2) Hai vách chắn hông nối liền mạch $0.0\text{m gap}$ với tường tầng, và (3) **Phễu Vát Góc $35^\circ$ ở 2 đầu cầu thang (`Funnel Entry Bevels`)** giúp nhân vật đi chéo vào thành thang sẽ tự trượt êm vào lòng cầu thang chứ không bao giờ bị kẹt góc! |
| **6. Đồng bộ Xoay Mặt & Đánh Thường** | Gán cứng góc xoay theo chuột ở mọi vị trí (nếu trỏ chuột để sát chân nhân vật sẽ bị giật góc xoay $180^\circ$ loạn xạ). | **Cải tiến 6A — Vùng Chết Tâm Chuột (`Cursor Deadzone Stabilizer 0.45m`) + Xoay Tức Thời $0.03\text{s}$ (`Instant Combat Snap-Facing`):** Xoay mặt nhân vật trùng khít $100\%$ hướng chuột ngay frame đầu tiên vung kiếm, khóa không cho `WASD` ghi đè góc mặt trong $0.30\text{s}$ chém, nhưng vẫn cho phép bước lùi/lách (`Kiting`) mượt mà! |

---

## 🎯 TASK 21.1: GIỚI HẠN TẦM NÉM CHIÊU E ($7.5\text{m}$), QUỸ ĐẠO PARABOL & VÙNG ĐỐT MÁU + LÀM CHẬM BOT

**File thực thi:** `src_game/scripts/characters/hero_knight_3d.gd`, `src_game/scripts/vfx/kaykit_vfx_manager.gd`, `src_game/scripts/enemies/enemy_minion_3d.gd`

### 1. Giới hạn tầm ném tối đa, chống ném xuyên tường & Bắt dính mặt sàn đa tầng (`hero_knight_3d.gd`):
- Thêm biến quản lý hồi chiêu cho phím `E`:
  ```gdscript
  const COOLDOWN_E: float = 6.0
  const MAX_E_THROW_RANGE: float = 7.5
  var _cd_e_timer: float = 0.0
  ```
- Khi người chơi nhấn phím `E` (và `_cd_e_timer <= 0.0`):
  1. **Xoay mặt tức thời về hướng chuột** (gọi `_snap_to_aim_direction(aim_dir)`).
  2. **Tính toán điểm rơi an toàn (`_compute_clamped_bomb_target`):**
     ```gdscript
     func _compute_clamped_bomb_target(raw_cursor_pos: Vector3) -> Vector3:
         var space_state := get_world_3d().direct_space_state
         var flat_offset := Vector3(raw_cursor_pos.x - global_position.x, 0.0, raw_cursor_pos.z - global_position.z)
         var dist := flat_offset.length()
         if dist > MAX_E_THROW_RANGE:
             flat_offset = flat_offset.normalized() * MAX_E_THROW_RANGE
         elif dist < 0.5:
             flat_offset = _get_forward_dir() * 1.5

         var candidate_xz := global_position + flat_offset

         # 1. Bắn tia ngang ở độ cao ngực (Y + 1.0m) để không ném xuyên qua tường biên
         var wall_ray := PhysicsRayQueryParameters3D.create(
             global_position + Vector3(0.0, 1.0, 0.0),
             candidate_xz + Vector3(0.0, 1.0, 0.0),
             1 # Layer 1: Environment/Walls
         )
         wall_ray.exclude = [get_rid()]
         var wall_hit := space_state.intersect_ray(wall_ray)
         if not wall_hit.is_empty():
             # Lùi điểm rơi cách mặt tường 0.6m
             candidate_xz = wall_hit["position"] + wall_hit["normal"] * 0.6

         # 2. Bắn tia từ trên cao xuống để bắt dính chính xác mặt sàn đa tầng (Y = 0m, 4m, 8m hoặc mặt cầu thang)
         var floor_ray := PhysicsRayQueryParameters3D.create(
             Vector3(candidate_xz.x, maxf(global_position.y, raw_cursor_pos.y) + 10.0, candidate_xz.z),
             Vector3(candidate_xz.x, -2.0, candidate_xz.z),
             1
         )
         floor_ray.exclude = [get_rid()]
         var floor_hit := space_state.intersect_ray(floor_ray)
         if not floor_hit.is_empty():
             return floor_hit["position"] + Vector3(0.0, 0.05, 0.0)
         return Vector3(candidate_xz.x, global_position.y, candidate_xz.z)
     ```

### 2. Tạo Vùng Độc Lôi Vụ (`Thunder Smoke Hazard Zone`) gây Sát Thương Đốt (DoT) & Làm Chậm $55\%$ (`kaykit_vfx_manager.gd` & `enemy_minion_3d.gd`):
- Khi quả bom `smokebomb.gltf` bay theo đường cong Parabol ($0.22\text{s}$) chạm tới `target_pos`:
  1. **Sát thương nổ tức thì:** Gây **`20.0` sát thương** cho toàn bộ Bot trong bán kính **`3.2m`**.
  2. **Khởi tạo Vùng Khói Lôi Vụ (`Duration = 4.0s`, `Radius = 3.2m`):**
     - Dùng `Decal` chiếu vòng ấn chú `circle_04.png` + `scorch_03.png` màu Tím Điện (`Color(0.65, 0.25, 1.0, 0.85)`) ôm sát mặt sàn/cầu thang để người chơi nhìn rõ phạm vi `3.2m`.
     - Kết hợp 2 hệ `GPUParticles3D`: Đám mây khói tím-đen (`smoke_04.png`, `smoke_07.png`) là là mặt đất và tia chớp hồ quang (`spark_06.png`, `spark_07.png`) giật liên tục bên trong đám khói.
     - **Vòng lặp sát thương & làm chậm mỗi `0.5s` (Tổng cộng 8 nhịp trong `4.0s`):**
       - Quét các Bot trong nhóm `"enemies"` có khoảng cách ngang $\le 3.2\text{m}$ và chênh lệch độ cao $\le 1.8\text{m}$ so với tâm vùng khói:
         - Gọi `bot.take_dot_damage(8.0, Color(0.75, 0.35, 1.0))` (trừ **`8 HP`/nhịp**, hiện chữ nhảy sát thương `-8` màu tím sáng, không gây giật ngắt hoạt ảnh quá mức nhưng nháy tia điện ở ngực Bot).
         - Gọi `bot.apply_slow_debuff(0.45, 1.0)` (giảm tốc độ di chuyển của Bot xuống còn **$45\%$**, tức làm chậm **$55\%$**, duy trì thêm $1.0\text{s}$ sau khi bước ra khỏi khói).
- **Cập nhật trong `enemy_minion_3d.gd`:**
  - Thêm biến `_slow_multiplier: float = 1.0` và `_slow_timer: float = 0.0`.
  - Trong `_physics_process(delta)`:
    ```gdscript
    if _slow_timer > 0.0:
        _slow_timer -= delta
        if _slow_timer <= 0.0:
            _slow_multiplier = 1.0
            _set_status_tint(Color.WHITE)
    # Nhân tốc độ di chuyển thực tế với _slow_multiplier:
    var effective_speed := move_speed * _slow_multiplier
    ```
  - Khi đang bị làm chậm (`_slow_timer > 0.0`), phủ nhẹ ánh màu Xanh Tím Điện (`Color(0.55, 0.75, 1.35)`) lên vật liệu của Bot để người chơi nhìn bằng mắt thường thấy ngay Bot đang bị dính hiệu ứng Làm Chậm!

---

## ⏱️ TASK 21.2: KHÓA COOLDOWN CHIÊU Q ($5.0\text{s}$), BỘ ĐỆM THAO TÁC (INPUT BUFFERING) & HIỂN THỊ HUD

**File thực thi:** `src_game/scripts/characters/hero_knight_3d.gd`, `src_game/scripts/ui/strict_qa_hud.gd`

1. **Khóa Cooldown Chiêu Q & Chống Spam Tuyệt Đối:**
   - Trong `hero_knight_3d.gd`:
     ```gdscript
     const COOLDOWN_Q: float = 5.0
     const COOLDOWN_RMB: float = 3.5
     var _cd_q_timer: float = 0.0
     var _cd_rmb_timer: float = 0.0
     var _buffered_action: String = ""
     var _buffer_timer: float = 0.0
     ```
   - Trong mỗi frame `_physics_process(delta)`:
     - Giảm dần `_cd_q_timer = maxf(0.0, _cd_q_timer - delta)`, `_cd_rmb_timer = maxf(0.0, _cd_rmb_timer - delta)`, `_cd_e_timer = maxf(0.0, _cd_e_timer - delta)`.
     - Chỉ cho phép kích hoạt `Q` khi `_cd_q_timer <= 0.0` và `not _is_spinning_q`. Ngay khi kích hoạt, gán `_cd_q_timer = COOLDOWN_Q`.
   - **Cải tiến Bộ Đệm Nút Bấm (`0.18s Input Buffer`):** Nếu người chơi bấm `Q`, `RMB` hoặc `E` khi thời gian hồi chiêu chỉ còn $\le 0.18\text{s}$ (hoặc đang ở những frame cuối của đòn đánh trước), lưu tên phím vào `_buffered_action` trong $0.18\text{s}$ để tự động tung chiêu ngay khoảnh khắc Cooldown chạm $0.0\text{s}$.
   - **Cải tiến Lực Hút Nhẹ Cho Chiêu Q (`Whirlwind Vacuum Pull`):** Trong 3 nhịp chém đầu của vòng xoay kiếm `Q`, kéo nhẹ các Bot trong bán kính `3.4m` về phía nhân vật một đoạn `0.35m` để Bot không bị trượt ra rìa ngoài, và ở nhịp chém thứ 4 cuối cùng mới hất văng Bot ra xa!

2. **Hiển thị Thanh Trạng Thái Cooldown Trực Quan Trên HUD (`strict_qa_hud.gd`):**
   - Bổ sung thanh hiển thị 4 kỹ năng rõ nét ở cạnh dưới màn hình (đặt `mouse_filter = Control.MOUSE_FILTER_IGNORE` để không bao giờ chặn chuột):
     - `[LMB] Liên Trảm: SẴN SÀNG`
     - `[RMB] Phá Không Trảm: SẴN SÀNG` (hoặc đếm ngược màu vàng cam `CD: 2.4s`)
     - `[Q] Cuồng Phong 360°: SẴN SÀNG` (hoặc đếm ngược `CD: 4.1s`)
     - `[E] Bom Lôi Vụ (7.5m): SẴN SÀNG` (hoặc đếm ngược `CD: 5.2s`)

---

## ⚡ TASK 21.3: ĐẠI TU NÚT CHUỘT PHẢI (`RMB`) — TUYỆT KỸ MỚI "THÁNH KIẾM PHÁ KHÔNG TRẢM" (`SOLAR CROSS-CLEAVE`)

**File thực thi:** `src_game/scripts/characters/hero_knight_3d.gd`, `src_game/scripts/vfx/kaykit_vfx_manager.gd`

Thay thế hoàn toàn chiêu giơ khiên cũ bằng một kỹ năng chủ động tầm trung uy lực, bùng nổ thị giác và có chiều sâu chiến thuật:

### 1. Thông số & Cơ chế Chiến đấu (`COOLDOWN_RMB = 3.5s`):
- **Tổng sát thương:** **`55.0 Damage`** chia làm 2 giai đoạn liên hoàn (mạnh gấp $2.2$ lần đòn đánh thường `25.0 Damage`):
  - **Giai đoạn 1 ($t = 0.0\text{s} \rightarrow 0.14\text{s}$ — Lướt Chém Chữ Thập `X-Cleave`):**
    - Nhân vật lập tức xoay mặt theo hướng con trỏ chuột (`_snap_to_aim_direction`), lướt thần tốc về phía trước **`2.2m`** (bám sát mặt đất/mặt dốc cầu thang qua `move_and_slide()`, không bay lơ lửng) và tung nhát chém chéo đôi gây **`25.0` sát thương** + khựng đòn cho toàn bộ kẻ địch trong vùng quạt rộng `3.5m` trước mặt.
  - **Giai đoạn 2 ($t = 0.14\text{s}$ — Sóng Kiếm Khí Phá Không & Địa Chấn):**
    - Tại điểm kết thúc cú lướt, hai vệt kiếm khí chữ **X** giao nhau phát nổ và phóng một **Lưỡi Sóng Năng Lượng Mặt Trời** trượt dọc mặt đất dài **`4.8m`** về phía trước, gây thêm **`30.0` sát thương**, đẩy lùi Bot **`2.2m`** và làm choáng (`Hit-stun = 0.65s`).

### 2. Kiến trúc Đồ họa 3D 4 Lớp (`spawn_rmb_solar_cross_cleave` trong `kaykit_vfx_manager.gd` — $0\%$ Khối Thô):
1. **Lớp 1 — Song Kiếm Khí Chữ Thập 3D (`Dual Crossed SlashArcRibbon3D`):**
   - Sử dụng bộ tạo lưới `ArrayMesh` cung trăng 3D kết hợp `vfx_stylized_slash.gdshader` để sinh ra **2 dải kiếm khí uốn cong đan chéo nhau ở góc $+38^\circ$ và $-38^\circ$** tạo thành hình chữ **X** rực rỡ trước ngực `HeroKnight3D`:
     - `core_color`: Trắng Kim Cương HDR `Color(4.5, 4.2, 3.5, 1.0)`
     - `main_color`: Vàng Thái Dương `Color(1.0, 0.72, 0.05, 1.0)`
     - `edge_color`: Đỏ Hỏa Ngục `Color(0.95, 0.12, 0.02, 1.0)`
2. **Lớp 2 — Lưỡi Sóng Kiếm Khí Càn Quét Mặt Đất (`Forward Traveling Crescent Wave`):**
   - Một dải `ArrayMesh` hình bán nguyệt nghiêng về phía trước phóng dọc theo hướng chuột `4.8m` trong `0.22s`, kéo theo luồng hạt `slash_03.png`, `flame_04.png` và tia lửa `spark_05.png`.
3. **Lớp 3 — Ấn Chú & Vết Nứt Mặt Đất (`Ground Impact Decal`):**
   - Chiếu `Decal` kết hợp `circle_02.png` (vòng cổ ngữ vàng cam) và `scorch_02.png` (vết cháy nứt mặt đất) ngay tại điểm giao cắt chữ X.
4. **Lớp 4 — Phản Hồi Cảm Giác Đánh Hạng Nặng (`Heavy Combat Feel`):**
   - Kích hoạt chớp sáng `OmniLight3D` màu vàng cam trong `0.15s` và rung nhẹ Camera (`0.12m` trong `0.14s`) khi sóng kiếm chạm trúng Bot.

---

## 🛡️ TASK 21.4: ĐỆM CHỐNG LÚN/CHE KHUẤT KHI ĐI SÁT TƯỜNG & XÓA SỔ $100\%$ GÓC LAG BẬC THANG

**File thực thi:** `src_game/scripts/characters/hero_knight_3d.gd`, `src_game/scripts/enemies/enemy_minion_3d.gd`, `src_game/scripts/world/kaykit_multitier_arena.gd`, `src_game/scripts/core/isometric_camera_3d.gd`

### 1. Chống nhân vật đi sát tường/tượng bị lún hoặc bị che khuất (`Wall Micro-Buffer & Camera Occlusion Fade`):
- **A. Mở rộng vùng đệm vật lý & Lực đẩy đàn hồi siêu nhỏ (`hero_knight_3d.gd` & `enemy_minion_3d.gd`):**
  - Tăng bán kính `CapsuleShape3D.radius` từ `0.38m` lên **`0.46m`** và đặt `safe_margin = 0.05` để phần vai, khiên và vũ khí của nhân vật không bao giờ chạm xuyên vào mặt tường hay chân tượng.
  - Bổ sung hàm `_apply_wall_micro_separation(delta: float)` gọi cuối `_physics_process(delta)`:
    ```gdscript
    func _apply_wall_micro_separation(_delta: float) -> void:
        var space_state := get_world_3d().direct_space_state
        var chest_origin := global_position + Vector3(0.0, 0.85, 0.0)
        var min_safe_dist := 0.52
        # Bắn 8 tia ngang quanh thân nhân vật kiểm tra Layer 1 (Tường/Tượng)
        for i in range(8):
            var angle := float(i) * (TAU / 8.0)
            var dir := Vector3(cos(angle), 0.0, sin(angle))
            var query := PhysicsRayQueryParameters3D.create(chest_origin, chest_origin + dir * min_safe_dist, 1)
            query.exclude = [get_rid()]
            var hit := space_state.intersect_ray(query)
            if not hit.is_empty():
                var normal: Vector3 = hit["normal"]
                # Chỉ đẩy tách với các bề mặt tường/vật cản đứng (normal.y < 0.35), không đẩy mặt dốc cầu thang!
                if absf(normal.y) < 0.35:
                    var hit_dist := Vector2(chest_origin.x - hit["position"].x, chest_origin.z - hit["position"].z).length()
                    if hit_dist < min_safe_dist:
                        var push_vec := Vector3(normal.x, 0.0, normal.z).normalized() * (min_safe_dist - hit_dist)
                        global_position += push_vec * 0.65
    ```
  - *(Lưu ý cực kỳ quan trọng: Điều kiện `absf(normal.y) < 0.35` đảm bảo lực đẩy chỉ tác động lên tường thẳng đứng, tuyệt đối không đẩy lùi nhân vật khi đang leo mặt dốc cầu thang!)*

- **B. Đề xuất cải tiến: Tự động làm mờ nhẹ Tường/Tượng khi che khuất tầm nhìn Camera (`isometric_camera_3d.gd`):**
  - Trong góc nhìn Isometric $45^\circ$, khi nhân vật đi sát vào phía Bắc (phía sau) của một bức tượng cao hoặc vách tường tầng trên, mô hình tượng có thể che ngang người nhân vật.
  - Trong `isometric_camera_3d.gd`: Mỗi frame bắn 1 tia Raycast từ `Camera3D.global_position` tới ngực `HeroKnight3D` (`global_position + Vector3(0, 1.0, 0)`). Nếu tia chạm phải một prop trang trí hoặc tường chắn nằm giữa Camera và Nhân vật, tự động đặt `transparency = 0.65` cho `MeshInstance3D` của vật cản đó, và trả lại `transparency = 0.0` ngay khi nhân vật bước ra khỏi vùng bị che!

### 2. Giải pháp Kết Cấu Cầu Thang Nguyên Khối Kín Khít (`Watertight Stair Monolith`) xóa sổ $100\%$ góc lag và lỗi đi xuyên hông bậc thang (`kaykit_multitier_arena.gd`):
- **Phân tích nguyên nhân gốc rễ:**
  - Hiện tại cầu thang chỉ có 1 tấm ván nghiêng mỏng (`SmoothStairRampCollider`), còn **2 bên thành cầu thang (trái/phải)** và **khoảng rỗng dưới gầm cầu thang** đang hở, cộng thêm mép giao giữa chân cầu thang và tường tầng tạo ra khe hẹp chữ V. Khi nhân vật hoặc Bot đi chéo từ hai bên hông vào cầu thang sẽ bị lọt xuyên qua sườn thang hoặc kẹt ở góc tiếp giáp!
- **Triển khai hàm `build_watertight_stair_assembly(...)` cho MỌI cầu thang trên bản đồ:**
  1. **Tắt hoàn toàn va chạm Trimesh răng cưa gốc của mô hình `stairs_wide.gltf.glb`** để không gây vấp chân.
  2. **Lắp Mặt Dốc Chính Mở Rộng (`Main Smooth Ramp`):** Nối liền mạch từ mặt sàn tầng dưới (`bottom_pos`) lên mép sàn tầng trên (`top_pos`), đầu dưới và đầu trên vát phẳng ăn sâu vào mặt sàn `0.25m` để không có gờ khấc.
  3. **Đóng Khối Đặc Dưới Gầm Cầu Thang (`Under-Stair Solid Block Collider`):** Tạo một `CollisionShape3D` (`BoxShape3D`) lấp đầy toàn bộ thể tích bên dưới gầm cầu thang và nối khít $100\%$ vào bức tường đá của tầng cao. Nhân vật đi từ phía sau hay hai bên hông vào gầm thang sẽ gặp một bức tường đá phẳng lì, tuyệt đối không thể chui vào gầm thang!
  4. **Dựng 2 Thành Lan Can Vô Hình Dọc Sườn Thang (`Left & Right Side Cheek Colliders`):** Đặt 2 tấm chắn vật lý phẳng (`dày 0.35m, cao 2.4m`) ôm sát hai mép trái và phải của cầu thang.
  5. **Gắn 2 Cánh Phễu Vát Góc $35^\circ$ Ở Chân & Đỉnh Cầu Thang (`Corner Funnel Bevels`):** Tại 2 góc ngoài của chân cầu thang và 2 góc giao với tường tầng trên, đặt các khối vát góc nghiêng $35^\circ$ để khi nhân vật chạy ép sát tường rồi rẽ lên cầu thang (hoặc đi chéo từ hông vào), thân nhân vật sẽ **trượt êm theo mặt vát vào đúng lòng cầu thang**, xóa vĩnh viễn mọi góc lag!

---

## 🧭 TASK 21.5: ĐỒNG BỘ $100\%$ HƯỚNG XOAY MẶT NHÂN VẬT & HƯỚNG ĐÁNH THƯỜNG (`COMBAT AIM-FACING SYNC`)

**File thực thi:** `src_game/scripts/characters/hero_knight_3d.gd`

### 1. Phân tích lỗi bất đồng bộ hiện tại:
- Khi người chơi vừa giữ `WASD` chạy sang hướng A vừa bấm Chuột Trái (`LMB`) chém sang hướng B, mô hình nhân vật (`visual_root.rotation.y`) đang xoay chậm hoặc giữ hướng chạy A, trong khi vệt kiếm khí lại phóng ra ở hướng B.

### 2. Cơ chế Đồng Bộ Tức Thời 3 Bước (`Instant Combat Aim-Facing Sync`):
1. **Bước 1 — Hàm tính hướng ngắm ổn định có Vùng Chết Tâm Chuột (`_get_stable_aim_direction`):**
   - Tránh hiện tượng con trỏ chuột đặt ngay trên người nhân vật làm góc xoay bị giật $180^\circ$:
   ```gdscript
   func _get_stable_aim_direction() -> Vector3:
       var raw_cursor := _get_mouse_world_pos()
       var diff := Vector3(raw_cursor.x - global_position.x, 0.0, raw_cursor.z - global_position.z)
       # Nếu con trỏ chuột đặt quá sát tâm chân nhân vật (< 0.42m), giữ nguyên hướng mặt hiện tại
       if diff.length() < 0.42:
           return Vector3(sin(_facing_angle), 0.0, cos(_facing_angle)).normalized()
       return diff.normalized()
   ```
2. **Bước 2 — Xoay Mặt Tức Thời Ngay Frame Bấm Đánh & Khóa Hướng Chém (`_snap_to_aim_direction`):**
   - Ngay khoảnh khắc người chơi nhấn `LMB` (Đánh thường), `RMB` (Phá Không Trảm), hoặc `E` (Ném Bom):
   ```gdscript
   func _snap_to_aim_direction(aim_dir: Vector3, lock_duration: float = 0.30) -> void:
       if aim_dir.length_squared() > 0.001:
           _facing_angle = atan2(aim_dir.x, aim_dir.z)
           if visual_root != null:
               visual_root.rotation.y = _facing_angle
       _combat_facing_lock_timer = maxf(_combat_facing_lock_timer, lock_duration)
   ```
3. **Bước 3 — Đồng bộ $100\%$ Bước Nhấp Tấn Công (`Attack Lunge`), Hitbox & Vệt Kiếm 3D Theo Đúng Hướng Mặt Đã Khóa:**
   - Khi tung đòn `LMB` hoặc `RMB`, lấy trực tiếp vector hướng mặt chuẩn:
     ```gdscript
     var locked_attack_dir := Vector3(sin(_facing_angle), 0.0, cos(_facing_angle)).normalized()
     ```
   - Truyền chính xác `locked_attack_dir` này cho:
     1. Bước nhấp chân tấn công (`_lunge_dir = locked_attack_dir`).
     2. Góc xoay của dải kiếm khí 3D (`SlashArcRibbon3D` trong `KayKitVFXManager`).
     3. Hình nón quét sát thương (`Hitbox Cone`).
   - **Ưu tiên góc xoay trong `_physics_process(delta)`:**
     - Khi `_combat_facing_lock_timer > 0.0`: Giảm `_combat_facing_lock_timer -= delta` và **giữ nguyên `visual_root.rotation.y = _facing_angle`** (tuyệt đối không cho nhánh di chuyển `WASD` xoay mặt nhân vật đi hướng khác trong lúc kiếm đang vung!).
     - Ngay khi `_combat_facing_lock_timer <= 0.0` (nhịp vung kiếm đã hoàn tất) và người chơi đang giữ `WASD` để chạy: Nhân vật xoay mặt mượt mà (`lerp_angle(_facing_angle, move_yaw, 18.0 * delta)`) theo hướng di chuyển.

---

## 🧪 TASK 21.6: KIỂM THỬ TỰ ĐỘNG 6 BÀI TEST NGHIÊM NGẶT & PUSH GITHUB (`AGENT-06`)

1. Tạo và chạy script kiểm thử tự động `src_game/tests/test_phase_21_all_upgrades.gd` kiểm định 6 tiêu chuẩn bắt buộc:
   - **Test 21.1 (Chiêu E — Giới hạn $7.5\text{m}$ + DoT + Làm chậm Bot):** Giả lập con trỏ chuột ở khoảng cách `22.0m`, kích hoạt phím `E` $\rightarrow$ Xác nhận điểm rơi thực tế của bom cách nhân vật $\le 7.55\text{m}$, `_cd_e_timer == 6.0`, Bot đứng trong vùng khói bị giảm máu theo nhịp DoT và tốc độ di chuyển giảm còn $45\%$ (`_slow_multiplier == 0.45`).
   - **Test 21.2 (Chiêu Q — Khóa Cooldown $5.0\text{s}$):** Kích hoạt phím `Q`, sau `0.4s` gọi tiếp phím `Q` lần 2 $\rightarrow$ Xác nhận lần gọi thứ 2 bị chặn hoàn toàn và `_cd_q_timer > 4.0`.
   - **Test 21.3 (Chiêu RMB Mới — Thánh Kiếm Phá Không Trảm):** Đặt Bot cách `2.8m` trước mặt, kích hoạt `RMB` $\rightarrow$ Xác nhận sinh 2 dải kiếm khí chữ X + sóng mặt đất (`0% Primitive Mesh`), Bot mất đủ `55 HP`, bị đẩy lùi và `_cd_rmb_timer == 3.5`.
   - **Test 21.4 (Chống Lún Tường & Quét 16 Góc Bậc Thang):** Cho nhân vật chạy ép sát vào tường/tượng và lao vào hai bên hông cầu thang từ 16 góc độ khác nhau $\rightarrow$ Xác nhận khoảng cách tâm tới tường luôn $\ge 0.46\text{m}$, $0\%$ lọt gầm cầu thang, $0\%$ kẹt góc và tự động trượt êm lên mặt cầu thang.
   - **Test 21.5 (Đồng Bộ Xoay Mặt & Hướng Chém LMB):** Cho nhân vật đang chạy hướng Tây `(-1, 0, 0)` rồi bấm `LMB` nhắm hướng Bắc `(0, 0, -1)` $\rightarrow$ Xác nhận ngay trong frame đánh, góc `visual_root.rotation.y` trùng khít $100\%$ với hướng vệt kiếm `(0, 0, -1)` (sai số $< 0.005\text{ rad}$).
   - **Test 21.6 (Zero Primitive Mesh Audit):** Quét toàn bộ cây Scene khi đang nổ đồng thời cả 4 chiêu `LMB`, `RMB`, `Q`, `E` $\rightarrow$ Xác nhận `PRIMITIVE MESHES == 0`.
2. Chụp ảnh màn hình thực tế trên GPU RTX 4060 lưu vào `docs/QA_REPORTS/screenshots/`, cập nhật `docs/CURRENT_CODE_SNAPSHOT.md`, sau đó chạy `git add .`, `git commit -m "feat(phase21): E range clamp & DoT/slow zone, Q cooldown & vacuum, RMB Solar Cross-Cleave overhaul, watertight stair colliders, wall buffer, and instant aim-facing sync"` và `git push` lên `https://github.com/NhutPham19/GameWizad`.