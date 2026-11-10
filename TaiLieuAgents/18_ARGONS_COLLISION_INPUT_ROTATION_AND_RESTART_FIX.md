# 👑 CHỈ ĐẠO SỐ 18 TỪ ARGONS: SỬA DỨT ĐIỂM 6 LỖI THỰC TẾ (CHẶN XUYÊN TƯỜNG/TƯỢNG, XÓA GÓC BUG CẦU THANG, XÓA THANH MÁU ĐÔI CỦA BOT, SỬA KẸT NÚT DI CHUYỂN, THÊM NÚT CHƠI LẠI & ĐỒNG BỘ XOAY MẶT 360°)

- **Người chỉ đạo (Chief Architect):** ARGONS
- **Đơn vị thực thi:** ANTIGRAVITY IDE
- **Kho GitHub chính thức:** `https://github.com/NhutPham19/GameWizad`
- **Mục tiêu bắt buộc hoàn thành 100% trong lượt này:**
  1. **Fix lỗi 1 (Tường & Tượng bị đi xuyên nhẹ / che nhân vật):** Mở rộng bán kính va chạm vật lý của Nhân vật và bọc khung va chạm dày (`Padded Solid Colliders`) cho toàn bộ tường, cột, tượng, đá, cây cối để cản nhân vật dừng lại trước khi vai/khiên/kiếm lọt vào mô hình.
  2. **Fix lỗi 2 (Góc bug đi xuyên ngang tại bậc thang & kẹt góc map):** Đóng khối đặc (`Solid Tier Volume`) cho toàn bộ Tầng 2, Tầng 3 và dựng Tường Chắn Hông Cầu Thang (`Stair Flank Guardrails`) hai bên trái/phải của mọi bậc thang, đảm bảo 0% góc kẹt cho cả Nhân vật và Bot.
  3. **Fix lỗi 3 (Bot có 2 thanh máu):** Dọn sạch code tạo trùng thanh máu trong `enemy_minion_3d.gd`, đảm bảo mỗi Bot chỉ hiển thị duy nhất 1 thanh máu rõ nét trên đầu.
  4. **Fix lỗi 4 (Kẹt nút di chuyển WASD không thể dừng):** Chuyển sang đọc trực tiếp trạng thái phím vật lý (`Input.is_physical_key_pressed`) mỗi frame kết hợp tự động xả Action bị kẹt (do bộ gõ tiếng Việt Unikey/EVKey hoặc mất sự kiện nhả phím) và dừng vận tốc ngay lập tức khi thả tay.
  5. **Fix lỗi 5 (Thêm nút "Chơi Lại" ở phía trên màn hình):** Tạo nút bấm trực quan **`🔄 CHƠI LẠI (Phím R)`** nằm ngay trên đỉnh màn hình để khi đang test hoặc lỡ chết có thể bấm làm mới lại toàn bộ màn chơi tức thì.
  6. **Fix lỗi 6 (Nhân vật xoay đa hướng mượt mà, không bị nhìn hướng này mà đi hướng khác):** Khóa `self.rotation = Vector3.ZERO` và đồng bộ góc xoay 360° của `visual_root` theo đúng vector di chuyển thực tế.

---

## 🧱 TASK 18.1 (FIX LỖI 1 & LỖI 2): CHẶN TUYỆT ĐỐI XUYÊN TƯỜNG/TƯỢNG & XÓA SẠCH 100% GÓC BUG BẬC THANG

### 1. Chặn lỗi nhân vật bị lọt nhẹ / bị che khi đụng Tường và Tượng (Fix Lỗi 1):
- **Nguyên nhân:** Bán kính `CapsuleShape3D` hiện tại (`0.38m`) nhỏ hơn bề ngang hai vai, khiên và thanh kiếm của `Knight.glb` (`~0.58m`), đồng thời các mô hình Tường (`wall.gltf.glb`), Cột/Tượng (`pillar.gltf.glb`), Đá (`rock_single_*.gltf`) đang dùng va chạm mỏng sát mép mesh.
- **Cách khắc phục bắt buộc:**
  1. **Tăng bán kính va chạm vật lý của `HeroKnight3D` và `EnemyMinion3D`:**
     - Trong `src_game/scripts/characters/hero_knight_3d.gd` và `src_game/scripts/enemies/enemy_minion_3d.gd`:
     - Tăng `CapsuleShape3D.radius` từ `0.38` lên **`0.52`** (`height = 1.80`, `position = Vector3(0.0, 0.90, 0.0)`).
     - Đặt `safe_margin = 0.04`, `wall_min_slide_angle = deg_to_rad(10.0)`, `floor_block_on_wall = true`.
  2. **Bọc Khung Va Chạm Dày Có Đệm (`Padded Solid StaticBody3D`) cho mọi Tường, Cột, Tượng và Vật Cản trong `kaykit_multitier_arena.gd`:**
     - Viết hàm bọc va chạm tự động có độ dày đệm mở rộng thêm **`+0.28m` mỗi chiều ngang (`padding = 0.28`)** và chiều cao tối thiểu `3.5m` cho mọi vật cản tĩnh (Tường, Cột trụ, Tượng, Tảng đá, Cây cối, Thùng gỗ):
     ```gdscript
     static func attach_padded_obstacle_collider(prop_node: Node3D, extra_padding: float = 0.28, min_height: float = 3.5) -> void:
         # Tính AABB tổng hợp của toàn bộ MeshInstance3D bên trong prop_node
         var combined_aabb := AABB(Vector3(-0.6, 0.0, -0.6), Vector3(1.2, 2.5, 1.2))
         var first := true
         for child in prop_node.find_children("*", "MeshInstance3D", true, false):
             var mi := child as MeshInstance3D
             if mi.mesh != null:
                 var local_aabb := mi.transform * mi.get_aabb()
                 if first:
                     combined_aabb = local_aabb
                     first = false
                 else:
                     combined_aabb = combined_aabb.merge(local_aabb)

         var body := StaticBody3D.new()
         body.name = "PaddedSolidCollider"
         body.collision_layer = 1
         body.collision_mask = 0
         prop_node.add_child(body)

         var col := CollisionShape3D.new()
         var box := BoxShape3D.new()
         box.size = Vector3(
             combined_aabb.size.x + extra_padding * 2.0,
             maxf(combined_aabb.size.y, min_height),
             combined_aabb.size.z + extra_padding * 2.0
         )
         col.shape = box
         col.position = Vector3(
             combined_aabb.get_center().x,
             box.size.y * 0.5,
             combined_aabb.get_center().z
         )
         body.add_child(col)
     ```
  3. **Giới hạn hàm `_apply_stair_step_up` chỉ chạy trong vùng Cầu Thang:**
     - Gắn toàn bộ node Cầu Thang và Mặt Dốc Cầu Thang (`SmoothStairRampCollider`) vào group `"stairs"`.
     - Trong `_apply_stair_step_up()`, kiểm tra nếu vật thể phía trước **KHÔNG** thuộc group `"stairs"` (tức là Tường, Tượng, Cột đá), lập tức `return` (tuyệt đối không nâng `global_position.y` khi đụng vào chân tường hay chân tượng!).

### 2. Xóa sạch Góc Bug đi xuyên ngang tại Bậc Thang & Rà soát toàn bộ Map (Fix Lỗi 2):
- **Nguyên nhân:**
  1. Tại hai bên sườn ngang (trái và phải) của mô hình `stairs_wide.gltf.glb` và tại khe tiếp giáp giữa bậc thang với vách tường Tầng 2 (`Y = 2.0m`) / Tầng 3 (`Y = 4.0m`), đang có khoảng hở tam giác dưới gầm cầu thang khiến nhân vật đi từ phía ngang có thể lọt xuyên qua sườn cầu thang hoặc chui vào lòng sàn Tầng 2/Tầng 3!
  2. Tầng 2 và Tầng 3 nếu chỉ xếp tường bao rỗng bên ngoài sẽ tạo ra khoảng rỗng bên trong lòng tầng khiến nhân vật/bot nếu lọt qua khe cầu thang sẽ bị kẹt vĩnh viễn bên trong.
- **Cách khắc phục bắt buộc trong `kaykit_multitier_arena.gd`:**
  1. **Đổ Đặc Lõi Vật Lý Của Toàn Bộ Tầng 2 và Tầng 3 (`Solid Tier Volume BoxShape3D`):**
     - Thay vì để rỗng bên dưới mặt sàn Tầng 2 (`Y = 2.0m`) và Tầng 3 (`Y = 4.0m`), hãy tạo các khối `StaticBody3D` + `BoxShape3D` **ĐẶC RUỘT 100%** lấp đầy toàn bộ thể tích từ `Y = 0.0m -> 2.0m` (cho khu vực Tầng 2) và từ `Y = 0.0m -> 4.0m` (cho khu vực Tầng 3).
     - Nhờ lõi tầng đặc ruột 100%, không tồn tại bất kỳ "khoang rỗng" nào bên dưới hay bên cạnh tầng để nhân vật và bot có thể đi xuyên vào!
  2. **Dựng Vách Chắn Hai Bên Hông Cầu Thang (`StairSideFlankColliders`):**
     - Trong hàm `create_smooth_stair_ramp(...)` (hoặc hàm đặt cầu thang `stairs_wide.gltf.glb`), bắt buộc tạo **Khối Nêm Đặc Dưới Gầm Cầu Thang + 2 Tường Chắn Dọc Hai Bên Sườn Cầu Thang (Trái & Phải)**:
     ```gdscript
     static func create_leakproof_stair_assembly(parent: Node3D, bottom_pos: Vector3, top_pos: Vector3, stair_width: float = 3.8) -> void:
         var stair_body := StaticBody3D.new()
         stair_body.name = "LeakproofStairCollider"
         stair_body.collision_layer = 1
         stair_body.collision_mask = 0
         stair_body.add_to_group("stairs")
         parent.add_child(stair_body)

         var horiz_vec := Vector3(top_pos.x - bottom_pos.x, 0.0, top_pos.z - bottom_pos.z)
         var run_len := horiz_vec.length()
         var rise_height := top_pos.y - bottom_pos.y
         var mid_xz := ( Vector3(bottom_pos.x, 0.0, bottom_pos.z) + Vector3(top_pos.x, 0.0, top_pos.z) ) * 0.5

         stair_body.global_position = Vector3(mid_xz.x, bottom_pos.y, mid_xz.z)
         stair_body.look_at(Vector3(top_pos.x, bottom_pos.y, top_pos.z), Vector3.UP)

         # 1. Mặt dốc chính nối từ sàn dưới lên sàn trên (Nhân vật & Bot chạy lên xuống)
         var ramp_col := CollisionShape3D.new()
         var ramp_box := BoxShape3D.new()
         var slope_len := sqrt(run_len * run_len + rise_height * rise_height)
         ramp_box.size = Vector3(stair_width, 0.35, slope_len + 0.3)
         ramp_col.shape = ramp_box
         ramp_col.position = Vector3(0.0, rise_height * 0.5 - 0.12, 0.0)
         ramp_col.rotation.x = atan2(rise_height, run_len)
         stair_body.add_child(ramp_col)

         # 2. Hai vách chắn kín hai bên hông cầu thang (Chặn 100% đi xuyên từ phía ngang vào gầm thang)
         for side in [-1.0, 1.0]:
             var side_col := CollisionShape3D.new()
             var side_box := BoxShape3D.new()
             side_box.size = Vector3(0.45, rise_height + 1.2, run_len + 0.4)
             side_col.shape = side_box
             side_col.position = Vector3(side * (stair_width * 0.5 + 0.22), (rise_height + 1.2) * 0.5, 0.0)
             stair_body.add_child(side_col)
     ```
  3. **Hàm Tự Động Giải Cứu Khỏi Góc Kẹt (`Anti-Stuck Depenetration Guard`):**
     - Trong cả `HeroKnight3D` và `EnemyMinion3D`: Nếu nhân vật bị ép sát vào góc tường hoặc `get_slide_collision_count() >= 3` mà tốc độ di chuyển thực tế `< 0.05m/s` trong `0.4s`, tự động đẩy nhẹ nhân vật `0.15m` theo vector tổng pháp tuyến (`combined_wall_normal`) ra phía ngoài mặt sàn thoáng để không bao giờ bị kẹt cứng ở bất kỳ góc nào!

---

## ❤️ TASK 18.2 (FIX LỖI 3): XÓA TRIỆT ĐỂ LỖI BOT CÓ 2 THANH MÁU

### Nguyên nhân & Cách sửa bắt buộc trong `src_game/scripts/enemies/enemy_minion_3d.gd`:
- **Nguyên nhân:** Trong `enemy_minion_3d.gd`, có 2 nơi cùng khởi tạo node hiển thị máu trên đầu Bot (ví dụ: vừa tạo `Sprite3D`/`SubViewport` thanh máu vừa tạo thêm 1 `Label3D` hoặc gọi hàm tạo thanh máu 2 lần).
- **Cách khắc phục bắt buộc:**
  1. Kiểm tra toàn bộ file `src_game/scripts/enemies/enemy_minion_3d.gd`.
  2. Trước khi tạo thanh máu trong `_ready()`, xóa sạch mọi node thanh máu cũ nếu có:
     ```gdscript
     for child in get_children():
         if child.name.begins_with("HealthBar") or child.name.begins_with("HPBar") or child.name.begins_with("OverheadHP"):
             child.queue_free()
     ```
  3. **Chỉ giữ lại DUY NHẤT 1 node thanh máu (`OverheadHealthBar3D`)** đặt ở độ cao `Vector3(0.0, 2.35, 0.0)` trên đầu Bot (sử dụng 1 `Sprite3D` hiển thị `SubViewport` vẽ khung viền đen + nền xám + thanh máu đỏ tươi co giãn theo `current_hp / max_hp`).
  4. Tuyệt đối không tạo thêm thanh máu thứ 2 dưới bất kỳ hình thức nào. Khi `current_hp <= 0`, ẩn ngay thanh máu đó (`overhead_health_bar.visible = false`).

---

## ⌨️ TASK 18.3 (FIX LỖI 4 & LỖI 6): SỬA DỨT ĐIỂM LỖI KẸT NÚT DI CHUYỂN & ĐỒNG BỘ XOAY MẶT ĐA HƯỚNG 360° MƯỢT MÀ

### 1. Sửa lỗi ấn nút di chuyển bị kẹt, chạy mãi về hướng đó không dừng được (Fix Lỗi 4):
- **Nguyên nhân cốt lõi:**
  1. Khi người chơi bật bộ gõ tiếng Việt (Unikey / EVKey) trên Windows và bấm `W, A, S, D` (phím `W` bị biến thành chữ `ư`, phím `S` thành dấu sắc, phím `D` thành chữ `đ`), hệ thống `InputMap` của Godot nhận sự kiện nhấn phím nhưng **bị mất sự kiện nhả phím (`Key Release`)**, làm `Input.is_action_pressed("move_...")` bị kẹt ở giá trị `true` mãi mãi!
  2. Hoặc trong `hero_knight_3d.gd`, biến hướng di chuyển / vận tốc `velocity.x, velocity.z` không được ép về `0.0` ngay lập tức khi không có phím nào được giữ.
- **Cách khắc phục bắt buộc trong `src_game/scripts/characters/hero_knight_3d.gd`:**
  1. **Viết hàm `_get_raw_physical_movement_input()` đọc trực tiếp mã phím vật lý (`Physical Keycode`) trên bàn phím mỗi frame và tự động xả (`action_release`) các Action bị kẹt:**
     ```gdscript
     func _get_raw_physical_movement_input() -> Vector2:
         # Nếu cửa sổ game mất tiêu điểm (Alt-Tab), dừng ngay lập tức
         if not get_window().has_focus():
             _force_release_all_movement_actions()
             return Vector2.ZERO

         # Đọc trực tiếp phím vật lý trên phần cứng (Bất chấp Unikey/EVKey đang bật tiếng Việt!)
         var p_right := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
         var p_left  := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
         var p_down  := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
         var p_up    := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)

         # Nếu không có phím vật lý nào đang được giữ trên bàn phím -> Xả sạch mọi Action bị kẹt!
         if not (p_right or p_left or p_down or p_up):
             _force_release_all_movement_actions()
             return Vector2.ZERO

         var raw := Vector2(
             (1.0 if p_right else 0.0) - (1.0 if p_left else 0.0),
             (1.0 if p_down else 0.0) - (1.0 if p_up else 0.0)
         )
         return raw.normalized() if raw.length_squared() > 1.0 else raw

     func _force_release_all_movement_actions() -> void:
         for act in ["move_up", "move_down", "move_left", "move_right"]:
             if Input.is_action_pressed(act):
                 Input.action_release(act)
     ```
  2. **Dừng nhân vật NGAY LẬP TỨC khi nhả phím (`input_vec == Vector2.ZERO`):**
     - Trong `HeroKnight3D._physics_process(delta)`:
     - Khi không trong trạng thái Dash (`_dash_timer <= 0.0`) và `input_vec.length_squared() < 0.001`:
       ```gdscript
       velocity.x = 0.0
       velocity.z = 0.0
       if _action_lock_timer <= 0.0 and is_on_floor():
           play_anim_safe("Idle")
       ```
     - Tuyệt đối không lưu giữ `move_dir` của frame cũ sang frame mới khi người chơi đã buông tay khỏi phím!

### 2. Nhân vật xoay chính xác nhiều hướng 360°, mượt mà, không bao giờ nhìn hướng này mà đi hướng khác (Fix Lỗi 6):
- **Nguyên nhân:**
  1. Node vật lý gốc (`self` / `HeroKnight3D`) bị xoay `rotation.y != 0` cộng dồn với `visual_root.rotation.y`, hoặc biến khóa hướng đánh (`_cast_facing_lock_timer` / `_action_lock_timer`) bị kẹt không trả quyền xoay mặt lại cho hướng di chuyển.
  2. Hoặc hoạt ảnh trong `.glb` có chứa track xoay xương gốc (`root` / `hips` rotation Y) làm lệch góc nhìn của mô hình so với `visual_root`.
- **Cách khắc phục bắt buộc trong `hero_knight_3d.gd`:**
  1. **Khóa cứng góc xoay của node vật lý `self.rotation = Vector3.ZERO` ở mọi frame:**
     - Chỉ xoay duy nhất node `visual_root` (`Node3D` chứa mô hình `Knight.glb`).
  2. **Đồng bộ góc xoay 360° theo đúng Vector Di Chuyển thực tế (`move_dir`):**
     - Quy đổi `input_vec` sang không gian mặt đất `XZ` dựa trên góc nhìn thực tế của `Camera3D`:
       ```gdscript
       var cam := get_viewport().get_camera_3d()
       var cam_right := Vector3.RIGHT
       var cam_forward := Vector3.BACK
       if cam != null:
           cam_right = Vector3(cam.global_transform.basis.x.x, 0.0, cam.global_transform.basis.x.z).normalized()
           cam_forward = Vector3(-cam.global_transform.basis.z.x, 0.0, -cam.global_transform.basis.z.z).normalized()
       # input_vec.y < 0 là bấm W (đi tiến theo hướng cam_forward), input_vec.y > 0 là bấm S (đi lùi)
       var move_dir := (cam_right * input_vec.x + cam_forward * (-input_vec.y)).normalized()
       ```
     - Ngay khi `move_dir.length_squared() > 0.001` và nhân vật không đang vung kiếm (`_action_lock_timer <= 0.0`):
       ```gdscript
       # Mô hình KayKit nhìn về trục +Z cục bộ -> Góc chuẩn thế giới là atan2(move_dir.x, move_dir.z)
       var target_yaw := atan2(move_dir.x, move_dir.z)
       visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw, minf(1.0, 24.0 * delta))
       ```
     - Ngay khi đòn đánh kết thúc (`_action_lock_timer` vừa giảm về `0.0`), nếu người chơi đang di chuyển, lập tức cập nhật `visual_root.rotation.y