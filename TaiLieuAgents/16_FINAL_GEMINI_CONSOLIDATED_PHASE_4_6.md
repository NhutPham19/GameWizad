# 👑 CHỈ ĐẠO TỔNG HỢP TOÀN DIỆN TỪ ARGONS: HOÀN THIỆN GAMEWIZAD (SỬA LEO BẬC THANG CHO HERO & BOT QUÁI, ĐÁNH THƯỜNG MẤT MÁU 100%, CHẶN RƠI RÌA MAP, QA HUD & TỰ ĐỘNG PUSH LÊN GITHUB)

- **Người chỉ đạo (Chief Architect):** ARGONS
- **Đơn vị thực thi:** ANTIGRAVITY IDE
- **Kho GitHub chính thức:** `https://github.com/NhutPham19/GameWizad`
- **Tình trạng hiện tại:**
  - Chuyển động xương (`Skeleton3D` + `AnimationPlayer` 76 hoạt ảnh KayKit) của nhân vật đã hoạt động rất mượt mà (**BẮT BUỘC GIỮ NGUYÊN, TUYỆT ĐỐI KHÔNG LÀM HỎNG**).
  - Cần giải quyết triệt để **4 vấn đề kỹ thuật còn tồn đọng** và **đẩy toàn bộ code hoàn chỉnh lên GitHub** ngay sau khi kiểm thử PASS 100%.

---

## ⛔ 4 LUẬT THÉP BẮT BUỘC TUÂN THỦ

1. **BẢO TỒN 100% HỆ THỐNG XƯƠNG & CHUYỂN ĐỘNG ĐANG TỐT:** Tuyệt đối không xóa hay làm hỏng logic remap xương trong `kaykit_animation_binder.gd` và hệ thống hạt/Decal trong `kaykit_vfx_manager.gd`.
2. **LUẬT `ZERO PRIMITIVE GEOMETRY` (0% HÌNH KHỐI HIỂN THỊ):** Không được tạo bất kỳ `MeshInstance3D` nào dùng `BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PrismMesh`, `TorusMesh`. (Các `CollisionShape3D` dùng `BoxShape3D` / `CapsuleShape3D` bên trong `StaticBody3D` / `CharacterBody3D` chỉ làm khung va chạm vật lý vô hình thì hoàn toàn hợp lệ).
3. **KIỂM TRA ĐỒNG THỜI CẢ 2 ĐỐI TƯỢNG (`HeroKnight3D` & `EnemyMinion3D`):** Mọi bản sửa lỗi leo cầu thang, giữ hoạt ảnh chạy trên dốc và chống rơi rìa map đều phải áp dụng và kiểm chứng cho **cả Nhân vật chính lẫn Bot Quái**.
4. **HOÀN TẤT PHẢI ĐẨY LÊN GIT (`AUTO GIT PUSH`):** Sau khi chạy kiểm thử tự động PASS 100%, bắt buộc xuất file `docs/CURRENT_CODE_SNAPSHOT.md` và chạy `git add .`, `git commit`, `git push origin main` lên repo `https://github.com/NhutPham19/GameWizad`.

---

## 🪜 NHIỆM VỤ 1: SỬA TRIỆT ĐỂ LỖI LEO BẬC THANG TỰ ĐỘNG CHO CẢ NHÂN VẬT & BOT QUÁI (GIỮ CHUYỂN ĐỘNG MƯỢT MÀ)

### 1.1. Mở thông Cổng Cầu Thang & Tạo Mặt Dốc Vật Lý Phẳng (`SmoothStairRampCollider`) trong Bản Đồ:
Trong script dựng bản đồ đa tầng (`src_game/scripts/levels/kaykit_arena_builder.gd` / `kaykit_multitier_arena.tscn`):
- **Nguyên nhân đang bị chặn ở cầu thang:**
  1. Dãy tường đá nâng tầng (`wall.gltf.glb`) đang đặt đè lên hoặc chắn ngang ngay tại ô đặt cầu thang (`stairs_wide.gltf.glb`), làm nhân vật và quái đâm vào tường ở đầu/cuối cầu thang.
  2. Va chạm `Trimesh` của các bậc thang có gờ vuông góc $90^\circ$ khiến `CharacterBody3D` bị vấp chân.
- **Cách sửa bắt buộc trong `kaykit_arena_builder.gd`:**
  1. **Mở thông 100% tường chắn tại mọi vị trí đặt cầu thang:** Tại tất cả các tọa độ $X$ đặt cầu thang nối Tầng 1 $\leftrightarrow$ Tầng 2 (ví dụ $X = -6.0\text{m}$ và $X = +6.0\text{m}$) và cầu thang nối Tầng 2 $\leftrightarrow$ Tầng 3 (ví dụ $X = 0.0\text{m}$), **TUYỆT ĐỐI KHÔNG sinh `wall.gltf.glb` hay bất kỳ vật cản nào trong phạm vi rộng $4.5\text{m}$ quanh lối vào và lối ra của cầu thang**!
  2. **Kiểm tra đúng chiều xoay của `stairs_wide.gltf.glb`:** Đầu bậc thấp nhất phải chạm sàn tầng dưới ($Y_{\text{bottom}}$), đầu bậc cao nhất phải hướng về phía sàn tầng trên ($Y_{\text{top}}$).
  3. **Tắt va chạm răng cưa của Mesh cầu thang và gắn Mặt Dốc Vật Lý Êm Ái (`SmoothStairRampCollider`):**
     - Khi instantiate `stairs_wide.gltf.glb`, **KHÔNG** gọi `create_trimesh_collision()` trực tiếp lên các bậc răng cưa. Thay vào đó, gọi hàm tạo mặt phẳng nghiêng vật lý vô hình nối liền từ mặt sàn tầng dưới lên đúng mép mặt sàn tầng trên:
     ```gdscript
     static func create_smooth_stair_ramp(parent: Node3D, bottom_center: Vector3, top_center: Vector3, ramp_width: float = 4.0) -> void:
     	var ramp_body := StaticBody3D.new()
     	ramp_body.name = "SmoothStairRampCollider"
     	ramp_body.collision_layer = 1
     	ramp_body.collision_mask = 0
     	parent.add_child(ramp_body)

     	var diff := top_center - bottom_center
     	var ramp_len := diff.length()
     	var mid_pos := (bottom_center + top_center) * 0.5

     	var col := CollisionShape3D.new()
     	var box := BoxShape3D.new()
     	box.size = Vector3(ramp_width, 0.25, ramp_len + 0.5)
     	col.shape = box
     	ramp_body.add_child(col)

     	ramp_body.global_position = mid_pos - Vector3(0.0, 0.12, 0.0)
     	ramp_body.look_at(top_center, Vector3.UP)
     ```
  4. **Lưu danh sách Tọa Độ Cổng Cầu Thang (`stair_links`) vào Group/Meta của Arena:**
     - Lưu các cặp tọa độ `(bottom_pos, top_pos)` của từng cầu thang để Bot Quái có thể đọc và tự động tìm đường leo tầng!

### 1.2. Tích hợp Hàm Tự Bước Lên Bậc Thang (`_apply_stair_step_up`) & Giữ Hoạt Ảnh Chạy Mượt cho CẢ `HeroKnight3D` và `EnemyMinion3D`:
Trong **cả 2 file** `src_game/scripts/characters/hero_knight_3d.gd` VÀ `src_game/scripts/enemies/enemy_minion_3d.gd`:
1. **Cấu hình `CharacterBody3D` chuẩn leo dốc/cầu thang trong `_ready()`:**
   ```gdscript
   floor_snap_length = 0.60
   floor_max_angle = deg_to_rad(58.0)
   floor_stop_on_slope = true
   floor_constant_speed = true
   floor_block_on_wall = true
   ```
2. **Bổ sung hàm `_apply_stair_step_up(move_dir: Vector3, delta: float)` gọi ngay trước `move_and_slide()` trong `_physics_process(delta)`:**
   ```gdscript
   func _apply_stair_step_up(move_dir: Vector3, delta: float) -> void:
   	if move_dir.length_squared() < 0.01:
   		return
   	var space_state := get_world_3d().direct_space_state
   	var horiz_dir := Vector3(move_dir.x, 0.0, move_dir.z).normalized()

   	# Tia 1: Quét ngang ở độ cao cổ chân (0.12m) đến đầu gối (0.45m) xem có gặp bậc thang không
   	var foot_from := global_position + Vector3(0.0, 0.15, 0.0)
   	var foot_to := foot_from + horiz_dir * 0.70
   	var foot_query := PhysicsRayQueryParameters3D.create(foot_from, foot_to, 1)
   	foot_query.exclude = [get_rid()]
   	var foot_hit := space_state.intersect_ray(foot_query)

   	if not foot_hit.is_empty():
   		# Tia 2: Bắn từ phía trước ở độ cao 0.85m thẳng xuống để tìm mặt trên của bậc thang
   		var step_from := global_position + horiz_dir * 0.60 + Vector3(0.0, 0.85, 0.0)
   		var step_to := global_position + horiz_dir * 0.60 + Vector3(0.0, 0.02, 0.0)
   		var down_query := PhysicsRayQueryParameters3D.create(step_from, step_to, 1)
   		down_query.exclude = [get_rid()]
   		var down_hit := space_state.intersect_ray(down_query)

   		if not down_hit.is_empty():
   			var target_y: float = down_hit["position"].y
   			var step_h: float = target_y - global_position.y
   			var normal: Vector3 = down_hit["normal"]
   			# Nếu gặp bậc cao từ 0.02m đến 0.65m và bề mặt đi được
   			if step_h > 0.02 and step_h <= 0.65 and normal.y >= 0.55:
   				global_position.y = move_toward(global_position.y, target_y + 0.02, 12.0 * delta)
   				velocity.y = maxf(velocity.y, 0.0)
   ```
3. **Đảm bảo Chuyển Động Chân (`Running_A`) Mượt Mà 100% Khi Leo Bậc Thang:**
   - Khi nhân vật hoặc Bot quái đang di chuyển trên mặt dốc cầu thang, nhờ `floor_snap_length = 0.60` và `_apply_stair_step_up`, đối tượng luôn giữ trạng thái chạm sàn (`is_on_floor() == true`).
   - Tuyệt đối không kích hoạt hoạt ảnh rơi (`Jump_Idle`) khi đang chạy lên hoặc chạy xuống cầu thang; bắt buộc giữ nguyên hoạt ảnh bước chạy `Running_A` nhịp nhàng và xoay mặt đúng hướng di chuyển `atan2(move_dir.x, move_dir.z)`!

### 1.3. AI Bot Quái Tự Động Tìm Cầu Thang Để Leo Lên / Leo Xuống Đuổi Đánh Hero (`Multi-Tier Stair Waypoint AI`):
Trong `src_game/scripts/enemies/enemy_minion_3d.gd`:
- Khi Bot quái (`EnemyMinion3D`) phát hiện `HeroKnight3D` đang đứng ở tầng độ cao khác ($\left|\text{player.global\_position.y} - \text{global\_position.y}\right| > 0.75\text{m}$):
  - Thay vì lao thẳng vào vách tường đá dưới chân tầng cao, Bot quái sẽ tự động tìm **Điểm Vào Cầu Thang Gần Nhất (`_get_nearest_stair_waypoint(global_position.y, player.global_position.y)`)**:
    - Nếu Bot ở Tầng 1 ($Y \approx 0$) còn Hero ở Tầng 2 ($Y \approx 2$): Bot nhắm tới chân cầu thang Tầng 1 gần nhất (ví dụ `Vector3(-6.0, 0.0, -12.0)` hoặc `Vector3(6.0, 0.0, -12.0)`), chạy thẳng lên đỉnh cầu thang Tầng 2 (`Z = -17.0`), rồi lao vào chém Hero!
    - Ngược lại, nếu Bot ở Tầng 2 hoặc Tầng 3 mà Hero ở tầng dưới: Bot tự động chạy ra đầu cầu thang, bước xuống cầu thang để truy đuổi Hero!

---

## ⚔️ NHIỆM VỤ 2: SỬA DỨT ĐIỂM ĐÒN ĐÁNH THƯỜNG (`CHUỘT TRÁI - LMB`) & KỸ NĂNG TRỪ MÁU QUÁI 100%

### 2.1. Sửa Hàm Quét Sát Thương Cận Chiến trong `src_game/scripts/characters/hero_knight_3d.gd`:
- **Nguyên nhân đánh thường chưa mất máu:**
  - Phép kiểm tra góc hình quạt đang bị ngược dấu trục mặt trước `+Z` của mô hình KayKit, hoặc hàm `take_damage` bị lệch tham số, hoặc giới hạn độ cao `Y` quá hẹp khiến đứng chênh bậc thang không đánh trúng.
- **Cách khắc phục bắt buộc trong `hero_knight_3d.gd`:**
  - Tạo một hàm thống nhất `_apply_melee_hit_detection(damage: float, hit_radius: float = 2.8, full_circle: bool = false) -> int` và gọi hàm này trong **CẢ 3 NHỊP ĐÁNH THƯỜNG (`LMB`)**, **ĐỠ KHIÊN PHẢN KÍCH (`RMB`)**, và **XOAY KIẾM 360 ĐỘ (`Phím Q`)**:
  ```gdscript
  func _apply_melee_hit_detection(damage: float, hit_radius: float = 2.8, full_circle: bool = false) -> int:
  	var hit_enemies: Array[Node] = []
  	# Hướng mặt thực tế của Knight theo trục +Z của KayKit
  	var facing_dir := Vector3(sin(visual_root.rotation.y), 0.0, cos(visual_root.rotation.y)).normalized()
  	# Tâm vùng lưỡi kiếm nằm phía trước mặt Hiệp sĩ 1.1m
  	var blade_zone_center := global_position + facing_dir * 1.15
  	if is_instance_valid(blade_center_marker):
  		blade_zone_center = blade_center_marker.global_position

  	# 1. Gom toàn bộ quái từ cả group "enemies", "enemy" VÀ Physics Sphere Query (Layer 4)
  	var candidates: Array[Node] = []
  	for g_name in ["enemies", "enemy"]:
  		for node in get_tree().get_nodes_in_group(g_name):
  			if is_instance_valid(node) and node != self and not candidates.has(node):
  				candidates.append(node)

  	var space_state := get_world_3d().direct_space_state
  	var sphere := SphereShape3D.new()
  	sphere.radius = hit_radius + 0.5
  	var query := PhysicsShapeQueryParameters3D.new()
  	query.shape = sphere
  	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0.0, 0.9, 0.0))
  	query.collision_mask = 4
  	for hit_dict in space_state.intersect_shape(query, 16):
  		var col_obj = hit_dict.get("collider")
  		if is_instance_valid(col_obj) and col_obj != self and not candidates.has(col_obj):
  			candidates.append(col_obj)

  	# 2. Kiểm tra khoảng cách và trừ máu trực tiếp
  	for target in candidates:
  		if not (target is Node3D) or not target.has_method("take_damage"):
  			continue
  		var t_node := target as Node3D
  		var t_pos := t_node.global_position
  		# Cho phép chênh lệch độ cao lên tới 2.0m (đánh trúng cả trên cầu thang)
  		if absf(t_pos.y - global_position.y) > 2.0:
  			continue

  		var flat_diff := Vector3(t_pos.x - global_position.x, 0.0, t_pos.z - global_position.z)
  		var dist_to_hero := flat_diff.length()
  		var dist_to_blade := Vector2(t_pos.x - blade_zone_center.x, t_pos.z - blade_zone_center.z).length()

  		var is_valid_hit := false
  		if full_circle:
  			is_valid_hit = (dist_to_hero <= hit_radius)
  		else:
  			var dir_to_target := flat_diff.normalized() if dist_to_hero > 0.001 else facing_dir
  			var dot_val := facing_dir.dot(dir_to_target)
  			# Trúng đòn nếu: đứng sát người (<= 1.5m), hoặc gần lưỡi kiếm (<= 1.8m), hoặc trong cung quạt 160 độ phía trước
  			is_valid_hit = (dist_to_hero <= 1.5) or (dist_to_blade <= 1.85) or (dist_to_hero <= hit_radius and dot_val >= -0.25)

  		if is_valid_hit:
  			var kb_dir := flat_diff.normalized() if dist_to_hero > 0.01 else facing_dir
  			target.take_damage(damage, kb_dir)
  			KayKitVFXManager.spawn_hit_impact_at_chest(t_node)
  			hit_enemies.append(target)

  	return hit_enemies.size()
  ```
  - **Đảm bảo kích hoạt ngay khi vung kiếm (`LMB`):** Ngay khi bấm Chuột Trái (`LMB`), gọi `_apply_melee_hit_detection(25.0, 2.8, false)` để quái trúng đòn ngay lập tức mà không bị trượt nhịp!

### 2.2. Chuẩn Hóa Nhận Sát Thương, Thanh Máu Trên Đầu & Số Sát Thương Nảy Lên trong `enemy_minion_3d.gd`:
- Trong `EnemyMinion3D`:
  - Khai báo hàm `func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO) -> void:` (tham số thứ 2 luôn có giá trị mặc định `Vector3.ZERO`).
  - Tạo sẵn 1 `Label3D` nổi phía trên đầu mỗi Bot quái (`position = Vector3(0.0, 2.25, 0.0)`, `billboard = BaseMaterial3D.BILLBOARD_ENABLED`, `no_depth_test = true`, `font_size = 42`, `outline_size = 10`) hiển thị rõ:
    `[████████] 80/80 HP`
  - Mỗi khi bị `HeroKnight3D` đánh trúng:
    1. Trừ máu: `hp = maxf(0.0, hp - amount)`.
    2. Cập nhật ngay lập tức thanh máu `Label3D` trên đầu và thanh máu 2D trên `StrictQAHUD`.
    3. Sinh ra 1 chữ nhảy sát thương `Label3D` (`"-25"` màu vàng cam rực rỡ) bay vọt từ ngực quái lên cao $2.8\text{m}$ rồi mờ dần trong $0.55\text{s}$.
    4. Phát hoạt ảnh giật người `Hit_A`, đẩy lùi nhẹ theo `knockback_dir`, và khi `hp <= 0` thì phát `Death_A` ngã gục!

---

## 🛡️ NHIỆM VỤ 3: ĐÓNG KHUNG RÌA BẢN ĐỒ & CHỐNG RƠI XUỐNG VỰC 100%

Trong `src_game/scripts/levels/kaykit_arena_builder.gd` và cả 2 script nhân vật (`hero_knight_3d.gd`, `enemy_minion_3d.gd`):
1. **Xây Tường Thành & Cột Đá KayKit Khép Kín Rìa Bản Đồ (`Visual Perimeter Walls`):**
   - Dọc theo toàn bộ 4 mép ngoài cùng của Tầng 1, Tầng 2 và Tầng 3: Đặt liên tiếp các mô hình `wall.gltf.glb`, `pillar.gltf.glb` và `rock_single_A.gltf` / `rock_single_B.gltf` tạo thành hàng rào thành lũy kiên cố bao bọc kín 100% chu vi bản đồ.
2. **Dựng Khung Va Chạm Vật Lý Chặn Biên Tuyệt Đối (`Invisible Boundary Colliders`):**
   - Dựng các `StaticBody3D` (`collision_layer = 1`, chứa `BoxShape3D` cao $16.0\text{m}$, dày $2.0\text{m}$) ôm khít toàn bộ 4 cạnh biên ngoài của Tầng 1, Tầng 2, Tầng 3 và hai bên thành cầu thang.
   - Tại mép giao giữa Tầng 2 với Tầng 1 và giữa Tầng 3 với Tầng 2: Đặt tường va chạm bảo vệ dọc theo mép vực (chỉ mở trống đúng ô cổng cầu thang rộng $4.2\text{m}$), đảm bảo nhân vật và quái chỉ có thể đi lên/xuống qua cầu thang chứ không bao giờ bước hụt rơi khỏi mép sàn!
3. **Chốt Bảo Hiểm Phục Hồi Tọa Độ An Toàn (`Safe Floor Recovery Clamp`):**
   - Trong `_physics_process(delta)` của cả `HeroKnight3D` và `EnemyMinion3D`:
     - Mỗi khi `is_on_floor()` và `global_position.y >= -0.05`, lưu lại `_last_safe_floor_pos = global_position`.
     - Nếu vì bất kỳ lý do gì mà `global_position.y < -1.0`: Lập tức đặt `global_position = _last_safe_floor_pos + Vector3(0.0, 0.15, 0.0)` và `velocity = Vector3.ZERO`. Nhân vật và quái không bao giờ có thể rơi khỏi bản đồ!

---

## 🔬 NHIỆM VỤ 4: KIỂM THỬ TỰ ĐỘNG 4 BÀI TEST, CHỤP ẢNH GPU RTX 4060 & ĐẨY CODE LÊN GITHUB

### 4.1. Viết & Chạy Script Kiểm Thử Tự Động Toàn Diện (`src_game/tests/test_phase_17_full_verification.gd`):
Chạy trên Godot 4.3 Console kiểm chứng **4 bài test bắt buộc đạt `PASS 100%`**:
1. **`[TEST 1 - HERO & MINION STAIR CLIMBING]`:**
   - Đặt `HeroKnight3D` tại chân cầu thang Tầng 1, truyền vận tốc tiến lên cầu thang trong $1.8\text{s}$ vật lý $\rightarrow$ Xác nhận `HeroKnight3D` tự động leo lên đạt độ cao Tầng 2 ($Y \ge 1.8\text{m}$) và hoạt ảnh đang phát là `Running_A`.
   - Kiểm tra `EnemyMinion3D` tự động leo cầu thang giữa các tầng thành công.
2. **`[TEST 2 - LMB NORMAL ATTACK DEALS DAMAGE]`:**
   - Đặt `EnemyMinion3D` đứng trước mặt `HeroKnight3D` ở khoảng cách $1.8\text{m}$, gọi đòn đánh thường `LMB` $\rightarrow$ Xác nhận máu của `EnemyMinion3D` giảm thực tế từ $80.0$ xuống $55.0$ (`hp < max_hp == true`).
3. **`[TEST 3 - MAP PERIMETER BOUNDARY PROTECTION]`:**
   - Cho `HeroKnight3D` chạy thẳng về phía 4 rìa bản đồ trong $2.5\text{s}$ $\rightarrow$ Xác nhận bị tường biên chặn lại và `global_position.y >= 0.0` (không rơi khỏi map).
4. **`[TEST 4 - ZERO PRIMITIVE GEOMETRY CHECK]`:**
   - Quét toàn bộ Scene Tree xác nhận số lượng `MeshInstance3D` dùng khối hình học cơ bản bằng `0`.

### 4.2. Chụp Ảnh Màn Hình Thực Tế Trên GPU RTX 4060:
- Chạy Godot ở chế độ cửa sổ Render thực tế (không `--headless`) và chụp các bức ảnh `.png` lưu vào `docs/QA_REPORTS/screenshots/` ghi lại cảnh:
  1. `HeroKnight3D` và `EnemyMinion3D` đang bước chạy leo trên bậc thang nối Tầng 1 và Tầng 2.
  2. `HeroKnight3D` dùng đòn đánh thường (`LMB`) chém `EnemyMinion3D` văng tia lửa, hiện chữ sát thương `-25` và thanh máu quái tụt xuống.
  3. Toàn cảnh đấu trường 3 tầng KayKit có tường đá và cột trụ bao kín rìa bản đồ kèm `StrictQAHUD`.

### 4.3. Xuất Snapshot Code & Đẩy Toàn Bộ Lên GitHub (`https://github.com/NhutPham19/GameWizad`):
1. Tạo và chạy script `XUAT_CODE_SNAPSHOT.ps1` gom nội dung toàn bộ các file `.gd` và `.tscn` trong `src_game/` vào file `docs/CURRENT_CODE_SNAPSHOT.md`.
2. Thực thi chuỗi lệnh Git tại thư mục gốc `E:\DoAnCaNhan\ThuVienGame\GameWizad\`:
   ```powershell
   git status
   git add .
   git commit -m "feat(phase17): fix auto stair climbing for hero & minions, LMB normal attack damage, and closed map boundaries"
   git push origin main
   ```
3. Xuất báo cáo hoàn tất cuối cùng xác nhận trạng thái `git push` thành công!