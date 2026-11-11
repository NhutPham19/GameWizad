# 👑 CHỈ ĐẠO SỐ 19 TỪ ARGONS: SỬA DỨT ĐIỂM KẸT GÓC ĐUỐC TẦNG CAO, CÂN BẰNG TỐC ĐỘ LƯỚT CẦU THANG, CƠ CHẾ LƯỚT ĐỤNG BOT VĂNG RA, TUNG CHIÊU LINH HOẠT & AI BOT TỰ ĐI ĐƯỜNG VÒNG TRÁNH VẬT CẢN

* **Người chỉ đạo (Chief Architect):** ARGONS
* **Đơn vị thực thi:** ANTIGRAVITY IDE
* **Kho GitHub chính thức:** `https://github.com/NhutPham19/GameWizad`
* **5 Mục tiêu cốt lõi bắt buộc hoàn thành 100% trong bản chỉ đạo này:**
  1. **Mục tiêu 1 (Xóa góc kẹt tại cây đuốc / góc tường như ảnh chụp thực tế):** Gỡ bỏ hoàn toàn va chạm vật lý cứng (`StaticBody3D`) trên các đạo cụ trang trí nhỏ (Đuốc sàn `torch_lit`, cỏ, hoa), làm phẳng tuyệt đối mặt trong của tường biên và đảm bảo mọi vật cản lớn (Rương, Cột) cách tường tối thiểu $2.2\text{m}$.
  2. **Mục tiêu 2 (Cân bằng tốc độ Lướt `Space` trên bậc thang):** Tắt hoàn toàn lực nâng bậc thang `_apply_stair_step_up()` trong lúc đang Dash và kẹp cứng độ dài vector vận tốc 3D trên mặt dốc cầu thang bằng đúng tốc độ lướt trên mặt phẳng.
  3. **Mục tiêu 3 (Chống Bot chặn cứng lối đi trong góc + Lướt đụng quái là Văng Lại, KHÔNG xuyên qua):** Áp dụng 3 lớp vật lý chuẩn ARPG: Bot giữ khoảng cách dừng chiến đấu $1.45\text{m}$ + tự tách đội hình vòng cung; khi người chơi bấm `Space` Lướt đụng trúng Bot thì **nhân vật dội ngược lại $0.8\text{m}$ còn con Bot bị húc văng lùi ra xa $2.0\text{m}$** (tuyệt đối không lướt xuyên qua người Bot).
  4. **Mục tiêu 4 (Tung chiêu linh hoạt, không bị đứng khựng ăn đòn oan, 0% trượt chân):**
     * Đòn `LMB` & `RMB`: Áp dụng **Bước Tấn Công (`Attack Step-Lunge`) + Cắt sớm hoạt ảnh thu kiếm thừa ở giây $0.24\text{s}$ (`Early Walk-Cancel`)** để vừa vung kiếm xong là guồng chân chạy `Running_A` ngay lập tức.
     * Chiêu `Q` (Xoay Kiếm $360^\circ$) & `E` (Ném Bom Khói): Cho phép vừa di chuyển vừa tung chiêu mượt mà kèm Giảm $60\%$ sát thương (`Hyper-Armor`).
     * Bấm `Space` hủy mọi đòn đánh tức thì (`Dash-Cancel`) + Chém trúng Bot làm Bot bị khựng (`Hit-Stun Interrupt` $0.35\text{s}$) ngắt ngay đòn bổ rìu của Bot.
  5. **Mục tiêu 5 (Sửa lỗi Bot ở xa nhìn chằm chằm vào người chơi và đâm đầu kẹt vào vật cản không biết đi đường vòng):** Trang bị hệ thống **Định Tuyến Trạm Cầu Thang Đa Tầng (`Multi-Tier Waypoint Graph`) + Cảm Biến 7 Tia Râu Đi Vòng Vật Cản (`7-Ray Context Steering Avoidance`) + Tự Động Gỡ Kẹt (`Unstuck Sidestep`) + Xoay Mặt Theo Hướng Bước Đi Thực Tế (`Velocity-Aligned Facing`)**.

---

## 🧱 TASK 19.1 (FIX Ý 1): XÓA TRIỆT ĐỂ GÓC KẸT TẠI CHẬU LỬA / ĐUỐC SÀN & TƯỜNG BIÊN TẦNG CAO

### Nguyên nhân từ ảnh chụp thực tế tại Tầng 3 ($Y = 8.05\text{m}$):
* Cây đuốc sàn (`torch_lit.gltf.glb`) được đặt gần mép tường phía Đông của tầng cao và đang bị gắn `PaddedSolidCollider`. Khe hẹp giữa cây đuốc và khung va chạm tường biên có kích thước $\approx 0.9\text{m}$ (xấp xỉ đường kính `CapsuleShape3D` của Hiệp sĩ), tạo thành "cái phễu kẹp" khiến nhân vật bước vào giữa đuốc và tường là bị khóa cứng!

### Cách khắc phục bắt buộc trong `src_game/scripts/world/kaykit_multitier_arena.gd`:
1. **Tuyệt đối KHÔNG gắn va chạm vật lý (`StaticBody3D`) cho Đuốc và Đạo cụ trang trí nhỏ:**
   * Trong hàm dựng đạo cụ bản đồ, nếu tên file hoặc tên node chứa `"torch"`, `"light"`, `"grass"`, `"pebble"`, `"banner"`, `"flag"`: **BỎ QUA 100% việc tạo `StaticBody3D` / `PaddedSolidCollider`**. Nhân vật và Bot đi ngang qua đuốc sàn hoàn toàn tự do, không bao giờ bị đuốc cản đường.
2. **Quy tắc Khoảng Cách An Toàn Tối Thiểu (`Minimum Clearance` $= 2.2\text{m}$) cho Rương & Cột Đá:**
   * Đối với các vật cản có va chạm thật (`chest`, `barrel`, `pillar`, `rock`):
     * Nếu đặt ở sát mép tường/rìa tầng: Phải đặt **ép sát khít vào tường (khoảng hở $= 0.0\text{m}$)** và gộp chung vào mặt phẳng tường.
     * Nếu đặt rời bên trong sân: Khoảng cách từ mép collider của vật cản đến bất kỳ bức tường hoặc cầu thang nào phải $\ge 2.2\text{m}$ (gấp hơn 2 lần bề rộng nhân vật) để nhân vật và Bot luôn chạy lọt qua dễ dàng.
3. **Làm phẳng tuyệt đối Khung Va Chạm Tường Biên & Rìa Tầng (`Continuous Flat Wall Planes`):**
   * Không tạo từng hộp va chạm rời rạc trên từng viên gạch tường hay từng cây cột góc (vì các gờ nối chữ L sẽ giữ chân nhân vật).
   * Mỗi cạnh rìa của Tầng 1, Tầng 2, Tầng 3 chỉ sử dụng **1 khối `BoxShape3D` phẳng dài liên tục** có bề mặt trong nhẵn bóng 100%, giúp nhân vật khi chạy chéo ép vào tường sẽ trượt dọc theo mặt tường mượt mà (`Wall-Gliding`).

---

## ⚡ TASK 19.2 (FIX Ý 2): CÂN BẰNG TỐC ĐỘ LƯỚT (`SPACE`) TRÊN BẬC THANG BẰNG VỚI MẶT PHẲNG

### Nguyên nhân:
* Khi bấm `Space` (Dash) tại cầu thang, vận tốc ngang `DASH_SPEED` đang bị cộng dồn với hàm nâng độ cao `_apply_stair_step_up()` và phép chiếu mặt nghiêng của `move_and_slide()`, làm vận tốc thực tế vọt lên gấp đôi.

### Cách khắc phục bắt buộc trong `src_game/scripts/characters/hero_knight_3d.gd`:
1. **Bật chế độ giữ nguyên tốc độ trên mặt dốc trong `_ready()`:**
   ```gdscript
   floor_constant_speed = true
   floor_max_angle = deg_to_rad(50.0)
   floor_snap_length = 0.35
   ```
2. **Khóa hàm `_apply_stair_step_up()` khi đang Lướt (`_dash_timer > 0.0`):**
   * Ngay dòng đầu tiên của hàm `_apply_stair_step_up(move_dir: Vector3, delta: float)`:
     ```gdscript
     if _dash_timer > 0.0:
         return # Tuyệt đối không cộng thêm Y thủ công khi đang Dash!
     ```
3. **Kẹp cứng Độ Dài Vector Vận Tốc 3D khi Lướt trên Cầu Thang / Mặt Dốc:**
   * Trong đoạn xử lý Dash của `_physics_process(delta)`:
     ```gdscript
     if _dash_timer > 0.0:
         var effective_dash_speed := DASH_SPEED
         # Kiểm tra nếu đang ở trên mặt dốc cầu thang (pháp tuyến sàn nghiêng hoặc chạm group "stairs")
         var on_stair_slope := false
         if is_on_floor() and get_floor_normal().y < 0.96:
             on_stair_slope = true
         else:
             for i in range(get_slide_collision_count()):
                 var col_obj := get_slide_collision(i).get_collider()
                 if col_obj is Node and (col_obj as Node).is_in_group("stairs"):
                     on_stair_slope = true
                     break

         if on_stair_slope:
             # Giảm hệ số lướt trên dốc cầu thang để tốc độ 3D bằng đúng cảm giác lướt trên mặt phẳng
             effective_dash_speed = DASH_SPEED * 0.72
             velocity.x = _dash_dir.x * effective_dash_speed
             velocity.z = _dash_dir.z * effective_dash_speed
             velocity.y = clampf(velocity.y, -4.0, effective_dash_speed * 0.35)
         else:
             velocity.x = _dash_dir.x * effective_dash_speed
             velocity.z = _dash_dir.z * effective_dash_speed
     ```

---

## 🛡️ TASK 19.3 (FIX Ý 3): 3 LỚP CHỐNG BOT CHẶN ĐƯỜNG TRONG GÓC & CƠ CHẾ LƯỚT ĐỤNG QUÁI VĂNG LẠI (0% XUYÊN QUA)

> ⚠️ **NGUYÊN TẮC BẮT BUỘC:** Nhân vật bấm `Space` Lướt **KHÔNG ĐƯỢC XUYÊN QUA QUÁI**. Khi đang Lướt mà đụng trúng Quái: Nhân vật bị dội nảy ngược lại một nhịp ngắn, đồng thời húc văng con Quái lùi ra xa để phá vòng vây!

### Lớp 1 — Khoảng Cách Dừng Chiến Đấu ($1.45\text{m}$) & Tự Tách Đội Hình Vòng Cung (`Boids Separation`) trong `enemy_minion_3d.gd`:
1. **Bot không bao giờ ủi sát vào tâm người chơi:**
   * Trong `EnemyMinion3D._physics_process(delta)`:
   * Tính khoảng cách ngang `horiz_dist` từ Bot đến `HeroKnight3D`.
   * Nếu `horiz_dist <= 1.45` và cùng tầng độ cao ($\Delta Y < 1.2\text{m}$):
     * **Dừng tiến tới ngay lập tức** (`desired_move_vel = Vector3.ZERO`).
     * Nếu `horiz_dist < 1.10` (quá sát người chơi, dễ gây kẹt góc): Bot **tự động lùi nhẹ ra sau** với vận tốc `-dir_to_hero * 2.8` để trả lại không gian thở cho người chơi!
2. **Lực đẩy tách bầy đàn giữa các Bot (`Boids Separation Force`):**
   * Mỗi con Bot kiểm tra các Bot khác trong group `"enemies"` ở bán kính $< 1.35\text{m}$:
     ```gdscript
     var separation_vec := Vector3.ZERO
     for other in get_tree().get_nodes_in_group("enemies"):
         if other == self or not is_instance_valid(other):
             continue
         var diff: Vector3 = global_position - other.global_position
         diff.y = 0.0
         var d := diff.length()
         if d > 0.001 and d < 1.35:
             separation_vec += diff.normalized() * ((1.35 - d) / 1.35) * 4.5
     ```
   * Cộng `separation_vec` vào vận tốc di chuyển của Bot để các Bot tự dàn thành hình vòng cung vây quanh thay vì dồn cục chặn kín góc tường.

### Lớp 2 — Vật Lý Lướt (`Space`) Đụng Quái: Nhân Vật Dội Lại + Quái Văng Ra Xa (`Dash Impact & Rebound`):
Trong `src_game/scripts/characters/hero_knight_3d.gd`:
1. Thêm biến trạng thái dội ngược sau va chạm Dash:
   ```gdscript
   var _rebound_timer: float = 0.0
   var _rebound_vel: Vector3 = Vector3.ZERO
   ```
2. Trong `_physics_process(delta)`, khi đang Dash (`_dash_timer > 0.0`):
   * Kiểm tra va chạm sau `move_and_slide()` (hoặc quét khoảng cách $< 1.05\text{m}$ phía trước theo hướng `_dash_dir` với các Bot còn sống trong group `"enemies"`):
   * Ngay khi phát hiện đụng trúng một `EnemyMinion3D`:
     ```gdscript
     # 1. Chấm dứt đà tiến của cú Lướt ngay lập tức (KHÔNG XUYÊN QUA BOT!)
     _dash_timer = 0.0

     # 2. Nhân vật bị dội nảy ngược lại phía sau ~0.8m trong 0.16 giây
     _rebound_timer = 0.16
     _rebound_vel = -_dash_dir * 6.2
     velocity.x = _rebound_vel.x
     velocity.z = _rebound_vel.z

     # 3. Húc văng con Bot bị đụng (và các Bot đứng sát cạnh nó trong bán kính 1.8m) lùi ra xa 2.0m!
     for enemy in get_tree().get_nodes_in_group("enemies"):
         if is_instance_valid(enemy) and enemy.has_method("apply_dash_impact_knockback"):
             if enemy == hit_enemy or enemy.global_position.distance_to(hit_enemy.global_position) <= 1.8:
                 var push_dir := (enemy.global_position - global_position)
                 push_dir.y = 0.0
                 if push_dir.length_squared() < 0.01:
                     push_dir = _dash_dir
                 enemy.apply_dash_impact_knockback(push_dir.normalized() * 14.5, 0.38)

     # 4. Nổ tia lửa va chạm vật lý ngay giữa 2 bên
     if vfx_manager != null:
         vfx_manager.spawn_hit_sparks(global_position + _dash_dir * 0.6 + Vector3(0.0, 1.0, 0.0))
     ```
3. Trong `enemy_minion_3d.gd`, viết hàm `apply_dash_impact_knockback(impulse: Vector3, stun_duration: float)`:
   * Đặt `_knockback_vel = impulse`, `_hit_stun_timer = maxf(_hit_stun_timer, stun_duration)`, ngắt ngay đòn đánh đang vung của Bot và phát hoạt ảnh `Hit_A`.

### Lớp 3 — Cơ Chế "Chen Vai" Đẩy Mềm Khi Đi Bộ Trong Góc Hẹp (`Corner Crowd Shove`):
* Nếu người chơi đang nhấn giữ `WASD` đi bộ mà bị chạm đồng thời vào Tường và Bot, tự động truyền một lực đẩy ngang (`move_dir * 6.5`) sang con Bot đang chắn mặt để con Bot bị đẩy dạt sang một bên, đảm bảo người chơi luôn lách ra được kể cả khi chưa hồi xong `Space`.

---

## ⚔️ TASK 19.4 (FIX Ý 4): TUNG CHIÊU LINH HOẠT CHUẨN STUDIO HÀNH ĐỘNG (0% ĐỨNG KHỰNG, 0% TRƯỢT CHÂN)

### 1. Kỹ thuật A — Đòn Đánh Thường (`LMB` Combo 3 Nhịp) & Khiên Phản Kích (`RMB`): Bước Tấn Công + Cắt Sớm Hoạt Ảnh Thu Kiếm (`Attack Lunge + Early Walk-Cancel`)
Trong `src_game/scripts/characters/hero_knight_3d.gd`:
* **Tăng tốc độ vung kiếm dứt khoát:** Khi phát hoạt ảnh đánh (`1H_Melee_Attack_Slice_Horizontal`, `Slice_Diagonal`, `Chop`, `Shield_Dash`), đặt `anim_player.speed_scale = 1.45` (khi quay về `Idle` / `Running_A` thì trả `anim_player.speed_scale = 1.0`).
* **Chia đòn đánh cận chiến làm 3 pha khớp 100% với bước chân (Thời gian tổng chỉ $0.24\text{s}$):**
  1. **Pha 1 ($0.00\text{s} \rightarrow 0.14\text{s}$ — Bước Chân Tấn Công / `Attack Step-Lunge`):**
     * Đúng lúc hoạt ảnh KayKit nhấc chân bước tới vung kiếm, cho nhân vật lướt bước tấn ngắn (`lunge_speed = 6.2 m/s`) theo hướng người chơi đang bấm `WASD` (hoặc hướng trỏ chuột nếu không bấm `WASD`).
  2. **Pha 2 ($0.14\text{s} \rightarrow 0.24\text{s}$ — Chân Đặt Xuống Sàn & Chém Trúng Đích):**
     * Bàn chân nhân vật trong hoạt ảnh vừa chạm đất, lưỡi kiếm quét qua mục tiêu gây sát thương. Trong $0.10\text{s}$ cực ngắn này, chân đứng trụ vững (`velocity.x = 0, velocity.z = 0`) — **cam kết 0% hiện tượng trượt chân!**
  3. **Pha 3 (Từ giây $0.24\text{s}$ trở đi — Cắt Bỏ Phần Thu Kiếm Thừa Để Chạy Tiếp Ngay / `Early Walk-Cancel`):**
     * Thay vì khóa nhân vật đứng im $0.55\text{s}$ chờ thu kiếm về như trước, chỉ đặt `_action_lock_timer = 0.24`.
     * Ngay tại giây $0.24\text{s}$ (sau khi đã gây sát thương xong), nếu người chơi đang nhấn giữ `WASD`, lập tức chuyển mượt (`blend = 0.10s`) sang hoạt ảnh bước chạy `Running_A` và cho phép nhân vật chạy đi với **100% tốc độ** ngay lập tức!

### 2. Kỹ thuật B — Chiêu `Q` (Xoay Kiếm $360^\circ$) & Chiêu `E` (Ném Bom Khói): Vừa Di Chuyển Vừa Tung Chiêu Mượt Mà
1. **Chiêu `Q` (`2H_Melee_Attack_Spinning` — Cơn Lốc Kiếm $360^\circ$):**
   * Trong suốt $0.45\text{s}$ xoay kiếm $360^\circ$ (`anim_player.speed_scale = 1.55`), **KHÔNG khóa đứng im**! Cho phép người chơi điều khiển cơn lốc kiếm di chuyển theo hướng `WASD` với **80% tốc độ chạy (`move_speed * 0.80`)**.
   * Đồng thời cấp **Giảm 60% Sát Thương Nhận Vào (`Hyper-Armor`)** trong lúc xoay kiếm.
2. **Chiêu `E` (`Throw` — Ném Bom Khói Làm Mù & Chậm Bot):**
   * Rút ngắn thời gian vung tay ném xuống **$0.18\text{s}$** (`anim_player.speed_scale = 1.75`) và cho phép nhân vật vừa di chuyển theo `WASD` vừa ném. Ngay sau $0.18\text{s}$, đôi chân lập tức trở lại hoạt ảnh `Running_A`.
   * Khi quả bom khói (`smokebomb.gltf`) nổ trên mặt đất, mọi con Bot đứng trong bán kính $4.0\text{m}$ của đám khói bị **Làm Chậm 60% tốc độ chạy và ngắt đòn đánh trong $2.5\text{s}$**.

### 3. Kỹ thuật C — Hủy Đòn Tức Thì Bằng `Space` (`Dash-Cancel`) & Làm Khựng Quái Khi Trúng Kiếm (`Hit-Stun Interrupt`)
1. **Hủy mọi đòn đánh bằng `Space` (`Instant Dash-Cancel`):**
   * Trong `hero_knight_3d.gd`: Kiểm tra nút `Space` (Dash) **TRƯỚC** khi kiểm tra `_action_lock_timer`.
   * Bất kỳ khoảnh khắc nào người chơi đang vung kiếm `LMB`, đâm khiên `RMB`, xoay `Q` hay ném `E` mà thấy Bot sắp bổ rìu, bấm `Space` sẽ **lập tức xóa `_action_lock_timer = 0.0`**, hủy ngay hoạt ảnh đánh để Lướt né đòn kèm **$0.35\text{s}$ Bất Tử (I-Frames)**!
2. **Chém trúng Bot làm Bot bị Khựng & Ngắt Đòn (`Enemy Hit-Stun Interrupt`):**
   * Trong `enemy_minion_3d.gd`: Khi Bot nhận sát thương từ bất kỳ đòn đánh nào của người chơi (`take_damage()`):
     * Lập tức đặt `_hit_stun_timer = 0.35` giây và **reset bộ đếm vung rìu của Bot** (`_attack_windup_timer = 0.0`, `_is_winding_up_attack = false`).
     * Đẩy lùi con Bot $0.65\text{m}$ theo hướng nhát chém và phát hoạt ảnh giật mình `Hit_A`.

---

## 🧭 TASK 19.5 (FIX Ý 5 - MỚI BỔ SUNG): TRÍ TUỆ NHÂN TẠO ĐỊNH TUYẾN ĐA TẦNG, CẢM BIẾN 7 TIA ĐI VÒNG TRÁNH VẬT CẢN & XOAY MẶT THEO HƯỚNG BƯỚC ĐI CHO BOT

### Nguyên nhân Bot bị kẹt khi ở xa người chơi hiện tại:
1. Khi `HeroKnight3D` đứng ở khoảng cách xa (khác tầng hoặc bị ngăn cách bởi tường tầng, lan can cầu thang, cột đá, rương gỗ), Bot chỉ tính vector đường chim bay `dir = (hero.global_position - global_position).normalized()` và cắm đầu đi thẳng vào bức tường/vật cản trước mặt.
2. Góc xoay của Bot (`visual_root.rotation.y`) đang bị khóa cứng nhìn về phía `HeroKnight3D`, gây ra cảnh Bot vừa nhìn chằm chằm vào nhân vật vừa ủi mặt vào tường mà không biết quay sang hướng đường vòng.

### Cách khắc phục triệt để bằng Hệ Thống 3 Tầng Điều Hướng Thông Minh trong `src_game/scripts/enemies/enemy_minion_3d.gd`:

#### Tầng 1 — Định Tuyến Qua Trạm Cầu Thang Khi Khác Độ Cao (`Multi-Tier Stair Waypoint Router`):
* Thay vì lấy thẳng tọa độ của `HeroKnight3D` làm đích đến khi khác tầng, hàm `_get_smart_navigation_target(hero_pos: Vector3) -> Vector3` phải kiểm tra độ cao:
  * **Tầng 1:** $Y \approx 0.0\text{m}$ | **Tầng 2:** $Y \approx 4.0\text{m}$ | **Tầng 3:** $Y \approx 8.05\text{m}$.
  * Nếu chênh lệch độ cao giữa Bot và Hero là $|\text{hero\_pos}.y - \text{global\_position}.y| > 1.15\text{m}$:
    * Nếu Bot đang ở trên mặt dốc cầu thang rồi: Đặt mục tiêu đi thẳng dọc theo trục cầu thang tới đỉnh/chân cầu thang.
    * Nếu Bot đang ở trên sàn phẳng khác tầng với Hero: Tự động chọn **Điểm Cửa Cầu Thang (`Stair Entry Waypoint`)** nối từ tầng hiện tại của Bot lên/xuống tầng của Hero (lấy từ danh sách các node cầu thang trong group `"stairs"` hoặc tọa độ chân/đỉnh cầu thang chuẩn của map).
    * Nhờ đó, khi bạn đứng trên Tầng 3 còn Bot ở Tầng 1, Bot sẽ tự động chạy vòng ra chân cầu thang Tầng 1 $\rightarrow$ leo lên Tầng 2 $\rightarrow$ chạy sang cầu thang Tầng 2 $\rightarrow$ leo lên Tầng 3 để tìm bạn, chứ không bao giờ đứng dưới chân vách đá Tầng 3 nhìn lên!

#### Tầng 2 — Cảm Biến 7 Tia Râu Đi Vòng Vật Cản & Ghi Nhớ Hướng Lách (`7-Ray Context Steering Whisker Avoidance` + `Unstuck Detector`):
Trong `enemy_minion_3d.gd`, thêm các biến trạng thái điều hướng:
```gdscript
var _avoid_commit_timer: float = 0.0
var _avoid_commit_sign: float = 1.0 # +1.0 (lách phải) hoặc -1.0 (lách trái)
var _stuck_check_timer: float = 0.0
var _last_stuck_check_pos: Vector3 = Vector3.ZERO
var _unstuck_recovery_timer: float = 0.0
var _unstuck_move_dir: Vector3 = Vector3.ZERO
```
Viết hàm `_compute_obstacle_avoidance_direction(desired_dir: Vector3, dist_to_target: float, delta: float) -> Vector3`:
```gdscript
func _compute_obstacle_avoidance_direction(desired_dir: Vector3, dist_to_target: float, delta: float) -> Vector3:
	if desired_dir.length_squared() < 0.001:
		return Vector3.ZERO
	var space_state := get_world_3d().direct_space_state
	var ray_origin := global_position + Vector3(0.0, 0.55, 0.0) # Độ cao ngang hông để phát hiện tường, rương, cột, lan can
	var probe_dist := clampf(dist_to_target, 1.4, 2.6)

	# 1. Nếu đang trong trạng thái Tự Gỡ Kẹt (Unstuck Recovery) thì ưu tiên đi theo hướng thoát kẹt
	if _unstuck_recovery_timer > 0.0:
		_unstuck_recovery_timer -= delta
		return _unstuck_move_dir

	# 2. Kiểm tra tia chính diện (0 độ) và 2 tia vai (-22 độ, +22 độ) xem có vướng vật cản Layer 1 không
	var front_blocked := false
	for check_deg in [0.0, -22.0, 22.0]:
		var check_dir := desired_dir.rotated(Vector3.UP, deg_to_rad(check_deg))
		var q := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + check_dir * probe_dist, 1)
		q.exclude = [get_rid()]
		var hit := space_state.intersect_ray(q)
		if not hit.is_empty():
			var hit_normal: Vector3 = hit["normal"]
			# Nếu mặt va chạm là tường đứng / vật cản (không phải mặt dốc cầu thang đi lên được)
			if hit_normal.y < 0.55:
				front_blocked = true
				break

	if not front_blocked and _avoid_commit_timer <= 0.0:
		return desired_dir

	# 3. Nếu phía trước bị chắn bởi tường/cột/rương: Quét 8 góc râu cảm biến hai bên để tìm lối đi vòng thông thoáng nhất!
	if _avoid_commit_timer > 0.0:
		_avoid_commit_timer -= delta

	var candidate_angles := [35.0, -35.0, 65.0, -65.0, 95.0, -95.0, 130.0, -130.0]
	# Nếu đã cam kết lách sang một bên (_avoid_commit_sign), ưu tiên thử các góc cùng phía trước để không bị lắc qua lắc lại!
	if _avoid_commit_timer > 0.0:
		candidate_angles.sort_custom(func(a, b): return (signf(a) == _avoid_commit_sign) and (signf(b) != _avoid_commit_sign))

	var best_dir := desired_dir
	var best_score := -999.0

	for deg in candidate_angles:
		var test_dir := desired_dir.rotated(Vector3.UP, deg_to_rad(deg)).normalized()
		var q := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + test_dir * (probe_dist + 0.6), 1)
		q.exclude = [get_rid()]
		var hit := space_state.intersect_ray(q)
		var clearance := probe_dist + 0.6
		if not hit.is_empty() and hit["normal"].y < 0.55:
			clearance = ray_origin.distance_to(hit["position"])

		# Điểm số = Độ thông thoáng + Độ ưu tiên hướng về mục tiêu + Độ ổn định hướng đã chọn
		var align_score := test_dir.dot(desired_dir) * 1.2
		var commit_bonus := 0.65 if (signf(deg) == _avoid_commit_sign and _avoid_commit_timer > 0.0) else 0.0
		var total_score := clearance + align_score + commit_bonus
		if total_score > best_score and clearance > 1.15:
			best_score = total_score
			best_dir = test_dir
			if front_blocked and _avoid_commit_timer <= 0.0:
				_avoid_commit_sign = signf(deg)
				_avoid_commit_timer = 0.65 # Giữ hướng đi vòng qua vật cản tối thiểu 0.65s

	return best_dir
```
* **Bộ Tự Động Gỡ Kẹt (`Stuck Detector` mỗi $0.35\text{s}$):**
  * Trong `_physics_process(delta)`: Nếu Bot đang trong trạng thái cần di chuyển mà sau $0.35\text{s}$ quãng đường dịch chuyển thực tế `(global_position - _last_stuck_check_pos).length() < 0.12`:
    * Đảo chiều `_avoid_commit_sign = -_avoid_commit_sign`.
    * Đặt `_unstuck_recovery_timer = 0.55` và cho Bot bước ngang/lùi chéo góc $105^\circ$ (`desired_dir.rotated(Vector3.UP, deg_to_rad(105.0 * _avoid_commit_sign))`) để lập tức thoát khỏi góc tường/vật cản!

#### Tầng 3 — Sửa Dứt Điểm Lỗi Xoay Mặt Của Bot (`Velocity-Aligned Facing When Moving` vs `Target-Facing In Melee`):
* **Tuyệt đối KHÔNG để Bot vừa đi vòng vừa nhìn chằm chằm vào người chơi ở xa!**
* Quy tắc xoay mặt `visual_root.rotation.y` bắt buộc trong `enemy_minion_3d.gd`:
  1. **Khi Bot đang di chuyển tìm đường hoặc ở xa người chơi (`horiz_dist > 2.1` hoặc đang tránh vật cản `_avoid_commit_timer > 0.0`):**
     * Bot **BẮT BUỘC xoay mặt theo đúng vector hướng bước chân thực tế (`move_velocity_horiz = Vector3(velocity.x, 0.0, velocity.z)`)**!
     ```gdscript
     var horiz_vel := Vector3(velocity.x, 0.0, velocity.z)
     if horiz_vel.length_squared() > 0.15 and (horiz_dist > 2.1 or _avoid_commit_timer > 0.0 or _unstuck_recovery_timer > 0.0):
         var walk_yaw := atan2(horiz_vel.x, horiz_vel.z)
         visual_root.rotation.y = lerp_angle(visual_root.rotation.y, walk_yaw, 14.0 * delta)
     ```
     * *Kết quả:* Khi Bot rẽ trái để đi vòng qua cái rương hoặc bức tường, mặt và mũi chân của Bot xoay hẳn sang bên trái theo đúng hướng đường vòng nhìn cực kỳ thông minh và tự nhiên!
  2. **Chỉ khi Bot đã áp sát vào tầm cận chiến (`horiz_dist <= 2.1`, cùng tầng và không bị kẹt tường):**
     * Lúc này Bot mới xoay mặt trực diện về phía `HeroKnight3D` (`atan2(dir_to_hero.x, dir_to_hero.z)`) để vung rìu tấn công.

---

## 🧪 TASK 19.6: KIỂM THỬ TỰ ĐỘNG 5 TÌNH HUỐNG & ĐẨY CODE LÊN GITHUB

1. **Viết script kiểm thử tự động `src_game/tests/test_phase_19_corners_dash_and_fluid_combat.gd` kiểm chứng 5 tiêu chuẩn:**
   * **Test 1 (No Torch/Corner Stuck at Tier 3 $Y = 8.05\text{m}$):** Đặt `HeroKnight3D` tại góc phía Đông Tầng 3 cạnh cây đuốc `(4.8, 8.05, -39.5)` và cho di chuyển qua lại $\rightarrow$ Xác nhận nhân vật đi qua thông thoáng 100%, không bị chặn bởi đuốc.
   * **Test 2 (Balanced Stair Dash Speed):** Đo quãng đường 3D dịch chuyển khi bấm `Space` trên cầu thang so với trên mặt phẳng $\rightarrow$ Xác nhận tốc độ 3D trên cầu thang không vượt quá $1.05\times$ tốc độ Dash trên mặt phẳng.
   * **Test 3 (Dash Into Bot Rebounds & Knocks Bot Back - Zero Phase-Through):** Đặt `HeroKnight3D` trước mặt `EnemyMinion3D` cách $1.5\text{m}$, kích hoạt `Space` Lướt thẳng vào Bot $\rightarrow$ Xác nhận nhân vật **KHÔNG đi xuyên qua tọa độ của Bot**, nhân vật có vận tốc dội ngược lại và con Bot bị đẩy lùi về phía sau $\ge 1.5\text{m}$.
   * **Test 4 (Fluid Combat Walk-Cancel & Enemy Hit-Stun):** Kích hoạt đòn đánh `LMB` trong khi giữ phím di chuyển $\rightarrow$ Xác nhận sau $0.25\text{s}$ nhân vật đã chuyển sang `Running_A` và di chuyển bình thường; đồng thời Bot trúng đòn bị ngắt trạng thái tấn công (`_hit_stun_timer > 0`).
   * **Test 5 (Bot Long-Range Obstacle Detour & Velocity-Aligned Facing):** Đặt một vật cản (`StaticBody3D` tường/rương rộng $2.5\text{m}$) chắn ngay chính giữa `EnemyMinion3D` và `HeroKnight3D` ở khoảng cách $12.0\text{m}$ (và test trường hợp khác tầng) $\rightarrow$ Giả lập vật lý trong $3.5\text{s}$, xác nhận Bot tự động bẻ lái đi vòng qua vật cản để tiến gần Hero, đồng thời góc xoay mặt `visual_root.rotation.y` của Bot khớp với hướng vector vận tốc bước đi (`dot >= 0.85`).
2. **Cập nhật `docs/CURRENT_CODE_SNAPSHOT.md` và đẩy lên GitHub:**
   * Chạy lệnh cập nhật snapshot và thực hiện `git add .`, `git commit -m "feat(phase19): fix tier3 torch corner trap, stair dash speed, dash impact rebound, fluid combat, and smart bot obstacle detour"`, sau đó `git push` lên `https://github.com/NhutPham19/GameWizad`.