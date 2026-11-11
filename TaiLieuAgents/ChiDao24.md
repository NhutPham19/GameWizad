# 👑 CHỈ ĐẠO SỐ 24 TỪ ARGONS: KHÓA SPAM LƯỚT (SPACE COOLDOWN 1.0S) & GIẢI PHÁP CHẮC CHẮN 100% XÓA VĨNH VIỄN LỖI ĐI XUYÊN / GÓC LAG TẠI CẦU THANG

- **Người chỉ đạo (Chief Architect):** ARGONS
- **Đơn vị thực thi:** ANTIGRAVITY IDE (`Claude Opus 4.6` / `Gemini 3.8 Flash`)
- **Kho GitHub dự án:** `https://github.com/NhutPham19/GameWizad`
- **Nguyên tắc thực thi bắt buộc:**
  1. **Giữ nguyên 100%** tốc độ tung chiêu nhanh nhạy, khả năng kết hợp chuỗi chiêu `U - I - O - P` và độ mượt $165\text{Hz}+$ hiện tại.
  2. **Khóa spam nút `Space` (Lướt):** Bổ sung thời gian hồi chiêu `COOLDOWN_DASH = 1.0` giây (tính từ lúc bấm Lướt) và hiển thị rõ trên thanh HUD dưới đáy màn hình.
  3. **Giải quyết dứt điểm 100% lỗi đi xuyên một phần cầu thang & góc lag tại cầu thang ngay trong 1 lần sửa duy nhất:** Thực hiện đầy đủ cả **4 Lớp Kỹ Thuật** trong **Task 24.2** dưới đây, tuyệt đối không bỏ sót bất kỳ bước nào.

---

## 🔍 PHÂN TÍCH CHÍNH XÁC TẠI SAO CẦU THANG VẪN BỊ ĐI XUYÊN & KẸT GÓC LAG TRONG CODE HIỆN TẠI

Qua kiểm tra trực tiếp file `CURRENT_CODE_SNAPSHOT_2.md`, đây là **4 nguyên nhân kỹ thuật thực sự** khiến các lần sửa trước chưa dứt điểm:

1. **Nguyên nhân 1 — Gán cứng chiều rộng cầu thang $4.0\text{m}$ nhỏ hơn mô hình 3D thật:**
   - Trong `kaykit_arena_builder.gd`, hàm `_compute_world_aabb()` được viết ra nhưng **không hề được gọi**, mà code lại gán cứng `actual_width = 4.0`. Trong thực tế, mô hình `stairs_wide.gltf.glb` (tính cả 2 bờ tường đá lan can hai bên) phình rộng hơn $4.0\text{m}$, dẫn tới việc khung va chạm nằm thụt vào trong so với mặt đá hiển thị $\rightarrow$ **Nhân vật đi từ hai bên hông vẫn lún một phần cơ thể vào trong thành đá cầu thang!**
2. **Nguyên nhân 2 — Mũi mặt dốc nghiêng (`WalkableRampSurface`) thò ra ngoài vách chắn hông:**
   - Mặt dốc nghiêng đang kéo dài tới `max_z + 0.35` ($Z = -11.65\text{m}$), trong khi 2 vách thành bên (`StairSideBalustrade_L/R`) lại chỉ dừng ở $Z = -12.025\text{m}$. Đoạn chênh lệch $0.375\text{m}$ này làm **2 góc chéo của tấm dốc nghiêng $45^\circ$ thò lộ thiên ra ngoài hành lang**, khiến nhân vật đi ngang qua mép dưới cầu thang bị vướng vào cạnh nghiêng và lún vào bậc thang dưới cùng!
3. **Nguyên nhân 3 — Gộp chung Vách Hông Cầu Thang vào Group `"stairs"` gây kích hoạt nhầm `_apply_stair_step_up()`:**
   - Cả 2 vách chắn hông cầu thang (`StairSideBalustrade_L/R`) đang gắn chung vào node `stair_body` có `add_to_group("stairs")`. Khi nhân vật đứng ở **bên ngoài sườn cầu thang** và đi ép vào vách hông, tia Raycast ở bàn chân thấy `col_obj.is_in_group("stairs") == true` nên **liên tục nhấc độ cao $Y$ của nhân vật nhảy lên vách đứng** rồi rơi xuống, tạo ra hiện tượng kẹt góc lag!
4. **Nguyên nhân 4 — Đoạn code `Anti-Stuck Depenetration Guard` trong `hero_knight_3d.gd` tự động giật lùi $0.15\text{m}$ mỗi $0.35\text{s}$:**
   - Tại dòng 601–617 của `hero_knight_3d.gd` (và dòng 356–372 của `enemy_minion_3d.gd`), khi nhân vật đi ép vào góc chữ L nơi sườn cầu thang giao với bức tường đá (`get_slide_collision_count() >= 2`), đoạn code này cứ mỗi $0.35\text{s}$ lại dịch chuyển cứng `global_position += push_dir.normalized() * 0.15`, làm nhân vật bị giật khấc liên tục tại góc cầu thang!

---

## ⚡ TASK 24.1: KHÓA SPAM NÚT `SPACE` (LƯỚT) VỚI THỜI GIAN HỒI CHIÊU `1.0 GIÂY`

**File thực thi:** `src_game/scripts/characters/hero_knight_3d.gd` và `src_game/scripts/ui/strict_qa_hud.gd`

### 1. Trong `src_game/scripts/characters/hero_knight_3d.gd`:
- **Bước 1:** Khai báo hằng số `COOLDOWN_DASH` (cùng chỗ với `COOLDOWN_Q`, `COOLDOWN_RMB`, `COOLDOWN_E`) và biến đếm `_cd_dash_timer`:
  ```gdscript
  const COOLDOWN_DASH: float = 1.0
  ```
  Và trong danh sách biến trạng thái (`State`):
  ```gdscript
  var _cd_dash_timer: float = 0.0
  var _prev_space_phys_down: bool = false
  ```
- **Bước 2:** Thêm hàm đọc phím `Space` phần cứng chống lặp phím (đặt ngay dưới hàm `_is_skill_key_just_pressed`):
  ```gdscript
  func _is_dash_just_pressed() -> bool:
  	var has_focus := true
  	var win := get_window()
  	if win and DisplayServer.get_name() != "headless":
  		has_focus = win.has_focus()
  	if not has_focus:
  		_prev_space_phys_down = false
  		return false
  	var space_down := Input.is_physical_key_pressed(KEY_SPACE)
  	var space_just_pressed := space_down and not _prev_space_phys_down
  	_prev_space_phys_down = space_down
  	return space_just_pressed or Input.is_action_just_pressed("dash")
  ```
- **Bước 3:** Trong `_physics_process(delta)` (khu vực giảm các biến Cooldown):
  ```gdscript
  	_cd_dash_timer = maxf(0.0, _cd_dash_timer - delta)
  ```
- **Bước 4:** Thay thế đoạn kiểm tra `if Input.is_action_just_pressed("dash"):` trong `_physics_process(delta)` bằng điều kiện có khóa Cooldown $1.0\text{s}$:
  ```gdscript
  	# --- Space: Instant Dash-Cancel có khóa Cooldown 1.0s chống spam (Task 24.1) ---
  	if _is_dash_just_pressed():
  		if _cd_dash_timer <= 0.0 and _dash_timer <= 0.0:
  			_action_lock_timer = 0.0
  			_is_spinning_q = false
  			_is_throwing_e = false
  			_lunge_timer = 0.0
  			_rmb_cleave_timer = 0.0
  			_do_dodge()
  			return
  ```
- **Bước 5:** Trong hàm `_do_dodge()`, khóa ngay `_cd_dash_timer = COOLDOWN_DASH` ở dòng đầu tiên:
  ```gdscript
  func _do_dodge() -> void:
  	if _cd_dash_timer > 0.0:
  		return
  	_cd_dash_timer = COOLDOWN_DASH
  ```

### 2. Trong `src_game/scripts/ui/strict_qa_hud.gd`:
- Cập nhật thanh Cooldown dưới đáy màn hình (`skill_cooldown_label`) để hiển thị thêm bộ đếm hồi chiêu của `[Space] Lướt`:
  ```gdscript
  			var dash_text := "SẴN SÀNG"
  			if "_cd_dash_timer" in hero and hero._cd_dash_timer > 0.05:
  				dash_text = "CD: %.1fs" % hero._cd_dash_timer

  			skill_cooldown_label.text = "[U] Liên Trảm: SẴN SÀNG  |  [I] Phá Không: %s  |  [O] Xoay 360°: %s  |  [P] Bom Lôi Vụ: %s  |  [Space] Lướt: %s" % [rmb_text, q_text, e_text, dash_text]
  ```

---

## 🛡️ TASK 24.2 (TRỌNG TÂM SỐ 1): GIẢI PHÁP 4 LỚP CHẮC CHẮN 100% XÓA SẠCH LỖI ĐI XUYÊN & GÓC LAG CẦU THANG

### LỚP 1 — Đo Trực Tiếp Đỉnh Mesh Thực Tế Của `stairs_wide.gltf.glb` & Tách Đôi Thành 2 `StaticBody3D` Độc Lập (`src_game/scripts/levels/kaykit_arena_builder.gd`)

1. **Trong `_build_tier_2_terrace()` và `_build_tier_3_citadel()` của `kaykit_arena_builder.gd`:**
   - **XÓA** các dòng `if s1: s1.add_to_group("stairs")`, `if s2: s2.add_to_group("stairs")`, `if s3: s3.add_to_group("stairs")` (Node visual tuyệt đối không được nằm trong group `"stairs"`).
   - Truyền trực tiếp node visual `s1`, `s2`, `s3` vào hàm tạo va chạm cầu thang:
     - Tại `_build_tier_2_terrace()`:
       ```gdscript
       create_bulletproof_stair_assembly(boundaries_container, s1, Vector3(-6.0, 0.0, -12.0), Vector3(-6.0, 4.0, -16.0))
       create_bulletproof_stair_assembly(boundaries_container, s2, Vector3(6.0, 0.0, -12.0), Vector3(6.0, 4.0, -16.0))
       ```
     - Tại `_build_tier_3_citadel()`:
       ```gdscript
       create_bulletproof_stair_assembly(boundaries_container, s3, Vector3(0.0, 4.0, -24.0), Vector3(0.0, 8.0, -28.0))
       ```

2. **Thay thế hàm `_compute_world_aabb` và `create_leakproof_stair_assembly` trong `kaykit_arena_builder.gd` bằng đoạn code chuẩn xác dưới đây:**

```gdscript
## Đo chính xác AABB cục bộ chuyển sang tọa độ Arena của mô hình cầu thang (hoạt động chính xác 100% ngay cả trước khi node vào SceneTree)
static func _compute_exact_stair_bounds(stair_visual_node: Node3D, nominal_center_x: float, min_y: float, max_y: float, min_z: float, max_z: float) -> AABB:
	var fallback_aabb := AABB(
		Vector3(nominal_center_x - 2.35, min_y, min_z - 0.20),
		Vector3(4.70, max_y - min_y + 0.60, (max_z - min_z) + 0.40)
	)
	if stair_visual_node == null:
		return fallback_aabb

	var root_xf := Transform3D(Basis.from_euler(stair_visual_node.rotation), stair_visual_node.position).scaled_local(stair_visual_node.scale)
	var merged := AABB()
	var has_mesh := false

	for child in stair_visual_node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi and mi.mesh:
			var rel_xf := Transform3D.IDENTITY
			var cur: Node = mi
			while cur != null and cur != stair_visual_node:
				if cur is Node3D:
					rel_xf = (cur as Node3D).transform * rel_xf
				cur = cur.get_parent()
			var w_aabb: AABB = (root_xf * rel_xf) * mi.get_aabb()
			if not has_mesh:
				merged = w_aabb
				has_mesh = true
			else:
				merged = merged.merge(w_aabb)

	if not has_mesh:
		return fallback_aabb
	return merged.merge(fallback_aabb)


static func create_bulletproof_stair_assembly(
	parent: Node3D,
	stair_visual_node: Node3D,
	bottom_center: Vector3,
	top_center: Vector3
) -> StaticBody3D:
	var min_y := minf(bottom_center.y, top_center.y)
	var max_y := maxf(bottom_center.y, top_center.y)
	var rise_height := max_y - min_y
	var min_z := minf(bottom_center.z, top_center.z) # Đỉnh cầu thang (Z = -16.0 hoặc -28.0)
	var max_z := maxf(bottom_center.z, top_center.z) # Chân cầu thang (Z = -12.0 hoặc -24.0)
	var center_x := (bottom_center.x + top_center.x) * 0.5

	# Đo biên thực tế của mesh cầu thang + mở rộng thêm đệm an toàn
	var exact_bounds := _compute_exact_stair_bounds(stair_visual_node, center_x, min_y, max_y, min_z, max_z)
	var outer_min_x := minf(exact_bounds.position.x - 0.15, center_x - 2.45)
	var outer_max_x := maxf(exact_bounds.end.x + 0.15, center_x + 2.45)
	var outer_min_z := minf(exact_bounds.position.z - 0.40, min_z - 0.60)
	var outer_max_z := maxf(exact_bounds.end.z + 0.10, max_z + 0.25)

	# Lòng rãnh bước đi ở chính giữa cầu thang: rộng 2.30m (từ center_x - 1.15m đến center_x + 1.15m)
	var walk_half_w := 1.15

	# ==========================================================================
	# BODY 1: KHỐI TƯỜNG ĐẶC BẢO VỆ HÔNG, GẦM & GÓC GIAO CẦU THANG
	# (TUYỆT ĐỐI KHÔNG thuộc group "stairs" -> Đi chạm vào 2 bên sườn cầu thang
	#  hoạt động 100% giống chạm vào bức tường phẳng, 0% đi xuyên, 0% giật góc!)
	# ==========================================================================
	var shell_body := StaticBody3D.new()
	shell_body.name = "StairSolidWallShell"
	shell_body.collision_layer = 1
	shell_body.collision_mask = 0
	parent.add_child(shell_body)
	shell_body.global_position = Vector3.ZERO
	shell_body.rotation = Vector3.ZERO

	var wall_height := rise_height + 3.2
	var side_z_len := outer_max_z - outer_min_z
	var side_z_mid := (outer_min_z + outer_max_z) * 0.5

	# 1A. Thành Đá Chắn Hông Trái (-X) — Phủ kín từ lòng rãnh (center_x - 1.15) ra tận mép ngoài (outer_min_x)
	var left_inner_x := center_x - walk_half_w
	var left_w := maxf(1.25, left_inner_x - outer_min_x)
	var left_col := CollisionShape3D.new()
	left_col.name = "StairSideWall_Left"
	var left_box := BoxShape3D.new()
	left_box.size = Vector3(left_w, wall_height, side_z_len)
	left_col.shape = left_box
	left_col.position = Vector3((outer_min_x + left_inner_x) * 0.5, min_y + wall_height * 0.5, side_z_mid)
	shell_body.add_child(left_col)

	# 1B. Thành Đá Chắn Hông Phải (+X) — Phủ kín từ lòng rãnh (center_x + 1.15) ra tận mép ngoài (outer_max_x)
	var right_inner_x := center_x + walk_half_w
	var right_w := maxf(1.25, outer_max_x - right_inner_x)
	var right_col := CollisionShape3D.new()
	right_col.name = "StairSideWall_Right"
	var right_box := BoxShape3D.new()
	right_box.size = Vector3(right_w, wall_height, side_z_len)
	right_col.shape = right_box
	right_col.position = Vector3((right_inner_x + outer_max_x) * 0.5, min_y + wall_height * 0.5, side_z_mid)
	shell_body.add_child(right_col)

	# 1C. Khối Đặc Lấp Kín Toàn Bộ Gầm Cầu Thang (UnderStairSolidCore)
	var under_col := CollisionShape3D.new()
	under_col.name = "UnderStairSolidCore"
	var under_box := BoxShape3D.new()
	var under_depth := (max_z - min_z) * 0.75
	under_box.size = Vector3(outer_max_x - outer_min_x, rise_height, under_depth)
	under_col.shape = under_box
	under_col.position = Vector3(center_x, min_y + rise_height * 0.5, min_z + under_depth * 0.5 - 0.25)
	shell_body.add_child(under_col)

	# 1D. Hai Khối Nêm Vát Phẳng Góc Chữ L Nơi Sườn Cầu Thang Giao Với Bức Tường Đá (Corner Glide Wedges)
	# Xóa sổ hoàn toàn hốc vuông 90 độ sát tường để nhân vật chạy ép vào góc sẽ tự trượt êm ra ngoài!
	for side in [-1.0, 1.0]:
		var wedge_col := CollisionShape3D.new()
		wedge_col.name = "CornerGlideWedge_" + ("L" if side < 0.0 else "R")
		var wedge_box := BoxShape3D.new()
		wedge_box.size = Vector3(1.10, wall_height, 1.80)
		wedge_col.shape = wedge_box
		var edge_x := outer_min_x if side < 0.0 else outer_max_x
		wedge_col.position = Vector3(edge_x + float(side) * 0.12, min_y + wall_height * 0.5, min_z + 0.70)
		wedge_col.rotation.y = deg_to_rad(38.0 * float(side))
		shell_body.add_child(wedge_col)

	# ==========================================================================
	# BODY 2: MẶT DỐC BƯỚC ĐI NẰM LỌT THỎM GIỮA 2 THÀNH HÔNG
	# (Chỉ duy nhất Body này thuộc group "stairs"! Chiều rộng 2.24m và chiều dài Z
	#  nằm gọn 100% bên trong lòng 2 thành hông của Body 1, không có bất kỳ cạnh nghiêng nào thò ra ngoài!)
	# ==========================================================================
	var ramp_body := StaticBody3D.new()
	ramp_body.name = "SmoothStairRampCollider"
	ramp_body.collision_layer = 1
	ramp_body.collision_mask = 0
	ramp_body.add_to_group("stairs")
	parent.add_child(ramp_body)
	ramp_body.global_position = Vector3.ZERO
	ramp_body.rotation = Vector3.ZERO

	var walkable_width := (walk_half_w * 2.0) - 0.06 # Rộng 2.24m nằm lọt lòng giữa 2 thành hông 2.30m
	var smooth_bot := Vector3(center_x, min_y - 0.06, max_z + 0.18) # Ngắn hơn đầu thành hông (max_z + 0.25) nên 0% thò góc nghiêng!
	var smooth_top := Vector3(center_x, max_y - 0.02, min_z - 0.08)
	var slope_len := smooth_top.distance_to(smooth_bot)
	var slope_mid := (smooth_bot + smooth_top) * 0.5

	var ramp_col := CollisionShape3D.new()
	ramp_col.name = "WalkableRampSurface"
	var ramp_box := BoxShape3D.new()
	ramp_box.size = Vector3(walkable_width, 0.24, slope_len)
	ramp_col.shape = ramp_box
	ramp_body.add_child(ramp_col)
	ramp_col.global_position = slope_mid - Vector3(0.0, 0.12, 0.0)
	ramp_col.look_at_from_position(ramp_col.global_position, smooth_top - Vector3(0.0, 0.12, 0.0), Vector3.UP)

	return ramp_body


static func create_leakproof_stair_assembly(parent: Node3D, bottom_center: Vector3, top_center: Vector3, _ramp_width: float = 4.0) -> StaticBody3D:
	return create_bulletproof_stair_assembly(parent, null, bottom_center, top_center)
```

---

### LỚP 2 — Khóa Hành Lang Trung Tâm Khi Leo Cầu Thang (`Stair Corridor Gate` trong `hero_knight_3d.gd` & `enemy_minion_3d.gd`)

Trong cả `src_game/scripts/characters/hero_knight_3d.gd` VÀ `src_game/scripts/enemies/enemy_minion_3d.gd`:
1. **Thêm hàm kiểm tra nhân vật có đang thực sự ở trong lòng rãnh bước đi của cầu thang hay không:**
```gdscript
func _is_in_stair_walk_corridor(pos: Vector3, move_dir: Vector3) -> bool:
	var horiz := Vector2(move_dir.x, move_dir.z)
	if horiz.length_squared() < 0.001:
		return false
	# Chỉ kích hoạt khi hướng di chuyển có thành phần đi lên/xuống dọc theo trục Z của cầu thang
	if absf(horiz.normalized().y) < 0.30:
		return false

	# Tọa độ X của nhân vật phải nằm lọt trong lòng rãnh giữa cầu thang (center_x ± 1.18m):
	# 1. Cầu thang Tây (Tầng 1 <-> 2): center_x = -6.0, Z từ -17.0 đến -11.0
	if absf(pos.x - (-6.0)) <= 1.18 and pos.z >= -17.0 and pos.z <= -11.0:
		return true
	# 2. Cầu thang Đông (Tầng 1 <-> 2): center_x = +6.0, Z từ -17.0 đến -11.0
	if absf(pos.x - 6.0) <= 1.18 and pos.z >= -17.0 and pos.z <= -11.0:
		return true
	# 3. Cầu thang Giữa (Tầng 2 <-> 3): center_x = 0.0, Z từ -29.0 đến -23.0
	if absf(pos.x - 0.0) <= 1.18 and pos.z >= -29.0 and pos.z <= -23.0:
		return true

	return false
```
2. **Đặt chốt chặn ở dòng đầu tiên của `_apply_stair_step_up()` (trong cả 2 file) và `_detect_stair_slope_ahead()` (trong `hero_knight_3d.gd`):**
   - Đầu hàm `_apply_stair_step_up`:
     ```gdscript
     	if not _is_in_stair_walk_corridor(global_position, move_dir):
     		return
     ```
   - Đầu hàm `_detect_stair_slope_ahead(dir: Vector3)`:
     ```gdscript
     	if not _is_in_stair_walk_corridor(global_position, dir):
     		return {"on_stairs": false, "slope_dy": 0.0}
     ```
   *(Hiệu quả: Khi nhân vật đứng ở hai bên sườn ngoài cầu thang, mọi tia quét nâng độ cao $Y$ đều tắt 100%, không bao giờ xảy ra lỗi nhấc chân nhân vật lên thành cầu thang!)*

---

### LỚP 3 — Xóa Bỏ Khối Code Tự Giật Lùi `Anti-Stuck Depenetration Guard` & Đặt `wall_min_slide_angle = 0.0`

1. **Trong `src_game/scripts/characters/hero_knight_3d.gd`:**
   - Trong `_ready()`: Đổi `wall_min_slide_angle = deg_to_rad(10.0)` thành:
     ```gdscript
     	wall_min_slide_angle = 0.0
     ```
   - Tại dòng 601–617 trong `_physics_process(delta)`: **XÓA BỎ HOÀN TOÀN** khối code `Anti-Stuck Depenetration Guard` (`if get_slide_collision_count() >= 2:` cộng `global_position += push_dir.normalized() * 0.15`), vì đây chính là đoạn code làm nhân vật bị giật lùi $15\text{cm}$ liên tục khi đi vào góc giao giữa cầu thang và tường đá!
2. **Trong `src_game/scripts/enemies/enemy_minion_3d.gd`:**
   - Trong `_ready()`: Đổi `wall_min_slide_angle = deg_to_rad(10.0)` thành:
     ```gdscript
     	wall_min_slide_angle = 0.0
     ```
   - Tại dòng 356–372 trong `_physics_process(delta)`: **XÓA BỎ HOÀN TOÀN** khối code `if get_slide_collision_count() >= 2:` dịch chuyển `global_position += push_dir.normalized() * 0.15`.

---

## 🧪 TASK 24.3: KIỂM THỬ TỰ ĐỘNG NGHIÊM NGẶT & PUSH LÊN GITHUB (`AGENT-06`)

1. Viết và chạy script kiểm thử tự động `src_game/tests/test_phase_24_dash_cd_and_bulletproof_stairs.gd` kiểm chứng PASS 100% cả 3 bài test:
   - **Test 24.1 (Space Dash 1.0s Cooldown Anti-Spam):**
     - Kích hoạt `_do_dodge()` tại `t = 0.0s` $\rightarrow$ Xác nhận `_cd_dash_timer == 1.0` và nhân vật bắt đầu lướt.
     - Giả lập bấm `Space` liên tục ở `t = 0.40s`, `0.65s`, `0.85s` $\rightarrow$ Xác nhận tất cả các lần bấm spam khi `_cd_dash_timer > 0.0` đều bị từ chối.
     - Chờ tới `t = 1.05s` (`_cd_dash_timer <= 0.0`) rồi gọi `_do_dodge()` $\rightarrow$ Xác nhận Lướt lần 2 kích hoạt thành công.
   - **Test 24.2 (Zero Stair Side Clipping & Zero Corner Jitter across All 6 Stair Sides):**
     - Đặt `HeroKnight3D` ở bên ngoài sườn trái/phải của cả 3 cầu thang (ví dụ `Vector3(-9.5, 0.05, -13.8)`, `Vector3(-2.5, 0.05, -13.8)`, và góc giao tường `Vector3(9.2, 0.05, -15.0)`), cho nhân vật chạy ép thẳng vào sườn cầu thang và góc tường trong `60 physics frames`.
     - Xác nhận:
       1. Khoảng cách ngang từ tâm nhân vật tới tâm cầu thang luôn `>= 2.90m` (tức dừng hoàn toàn ở bên ngoài bờ đá lan can cầu thang, **0% đi xuyên vào cầu thang**).
       2. Độ cao `global_position.y` của nhân vật khi ép vào sườn cầu thang và góc tường giữ phẳng tuyệt đối ở `0.05m` (dao động `< 0.005m`, **0% nhấp nhô hay giật lùi**).
   - **Test 24.3 (Smooth Center Stair Walk & Dash Up/Down):**
     - Đặt nhân vật ở chính giữa lòng cầu thang (`X = -6.0, Z = -11.0`), cho chạy bộ và Lướt (`Space`) thẳng lên cầu thang $\rightarrow$ Xác nhận leo lên Tầng 2 đạt `Y >= 1.60m` trong 1 nhịp lướt mượt mà và `PRIMITIVE MESHES == 0`.
2. Xuất lại file `docs/CURRENT_CODE_SNAPSHOT.md`, chụp ảnh màn hình lưu vào `docs/QA_REPORTS/screenshots/`, sau đó chạy `git add .`, `git commit -m "fix(phase24): add 1.0s Space dash cooldown and 2-body bulletproof stair collision with zero corner jitter"` và `git push` lên `https://github.com/NhutPham19/GameWizad`.