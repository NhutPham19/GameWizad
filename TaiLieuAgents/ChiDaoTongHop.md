# 👑 CHỈ ĐẠO TỔNG HỢP SỐ 23 TỪ ARGONS: XÓA SẠCH VẬT THỂ TÀNG HÌNH & GÓC LAG CẦU THANG, CHẶN XUYÊN TƯỜNG 100%, LƯỚT LÊN CẦU THANG MƯỢT MÀ, CHUYỂN ĐỔI PHÍM KỸ NĂNG U-I-O-P & TỐI ƯU 165HZ KHÔNG GIẬT LAG

* **Người chỉ đạo (Chief Architect):** ARGONS
* **Đơn vị thực thi:** ANTIGRAVITY IDE (`Claude Opus 4.6` / `Gemini 3.8 Flash`)
* **Kho GitHub dự án:** `https://github.com/NhutPham19/GameWizad`
* **Luật Thép Bất Di Bất Dịch:**
  1. **Tuyệt đối $0\%$ Khối Hình Học Thô (`PRIMITIVE MESHES == 0`):** Nghiêm cấm khởi tạo `BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PrismMesh`, `TorusMesh`.
  2. **Làm kỹ lưỡng, chính xác từng dòng code theo đúng 6 Task dưới đây** để giải quyết dứt điểm toàn bộ các lỗi phát sinh trong thực tế.

---

## 🔍 BẢNG CHẨN ĐOÁN GỐC RỄ TOÀN BỘ LỖI TỪ MÃ NGUỒN & ẢNH CHỤP THỰC TẾ

| STT | Lỗi thực tế người chơi gặp phải | Nguyên nhân gốc rễ trong code hiện tại (`CURRENT_CODE_SNAPSHOT.md`) | Giải pháp khắc phục triệt để 100% |
| :--- | :--- | :--- | :--- |
| **1** | **Có nhiều vật thể tàng hình quanh cầu thang làm nhân vật bị kẹt + Đi xuyên vào hai bên thành cầu thang.** | • Trong `kaykit_arena_builder.gd`, hàm `create_leakproof_stair_assembly` xoay nghiêng node cha `ramp_body` góc $45^\circ$ (`look_at_from_position`), rồi lại gắn 6 hộp con (`side_col`, `under_col`, `bevel_col`, `bevel_top_col`) vào node cha đang nghiêng đó $\rightarrow$ Các hộp con bị chổng ngược $45^\circ$ đâm ra ngoài hành lang thành **bẫy vật thể tàng hình**.<br>• Cầu thang `stairs_wide.gltf.glb` rộng $4.0\text{m}$ nhưng code đặt `ramp_width = 5.0`, làm vách chắn lệch ra ngoài $0.68\text{m}$ khiến nhân vật lọt vào trong thành đá cầu thang.<br>• Cột đá (`PROP_PILLAR`) đặt tại $X = \pm 2.5, \pm 3.5$ kèm đệm `0.28m` chèn sát mép cầu thang tạo khe kẹp chữ V. | • **Task 23.1:** Xóa toàn bộ các hộp nghiêng. Giữ `stair_body.rotation = Vector3.ZERO` (World-Aligned), đo chính xác `AABB` của cầu thang thật ($4.0\text{m} \times 4.0\text{m} \times 4.0\text{m}$) để bọc kín 2 thành lan can đá hai bên và chỉ xoay duy nhất tấm dốc ở lòng giữa.<br>• Dời các cột đá cạnh cầu thang ra xa ($X = \pm 11.5$ ở Tầng 1–2; $X = \pm 5.5$ ở Tầng 3) và bỏ đệm thừa. |
| **2** | **Khi bấm Lướt (`Space`) từ dưới đi lên chạm cầu thang bị chặn/kẹt cứng.** | • Khối `under_col` bị xoay nghiêng trồi cạnh hộp lên ngay chân cầu thang.<br>• Trong `hero_knight_3d.gd`, khi đang Dash (`_dash_timer > 0.0`), hàm `_apply_stair_step_up` bị tắt hoàn toàn, `floor_block_on_wall = true`, và vector vận tốc Dash chỉ đi ngang `(X, 0, Z)` nên đâm thẳng vào gờ chân dốc. | • **Task 23.2:** Vát âm đầu dưới của mặt dốc cầu thang xuống $-0.08\text{m}$ ăn liền với sàn.<br>• Khi Dash gặp cầu thang, tự động tắt tạm thời `floor_block_on_wall`, bật hỗ trợ bước gờ và chiếu vector vận tốc Dash dọc theo độ dốc cầu thang (`slope_y`) với tốc độ cân bằng. |
| **3** | **Tường chưa cản lại sớm, nhân vật đi xuyên vào tường và bị che mất một phần cơ thể.** | • Tại vách Tầng 2 ($Z = -16.0$), tường đặt ở `[-14.0, -10.5, 0.0, 10.5, 14.0]` để hở khe $0.5\text{m}$ sát cạnh cầu thang ($X = \pm 8.0 \rightarrow \pm 8.5$) và hở $2.0\text{m}$ ở giữa.<br>• Tường dùng `create_trimesh_collision()` mỏng $0\text{mm}$, trong khi đầu/vai/khiên nhân vật vươn ra $0.62\text{m}$ lớn hơn `CapsuleShape3D.radius = 0.46m`. | • **Task 23.3:** Xếp tường khít tuyệt đối `[-14.0, -10.0, -2.0, 2.0, 10.0, 14.0]` ($0.00\text{m}$ khe hở).<br>• Bọc mọi bức tường bằng khối `ThickWallCollider` dày thêm $+0.40\text{m}$ về phía người chơi + tăng `CapsuleShape3D.radius = 0.50m` để cơ thể dừng cách mặt gạch $15\text{cm}$. |
| **4** | **Chưa chuyển đổi bộ nút kỹ năng qua `U - I - O - P`.** | • `hero_knight_3d.gd` chỉ mới kiểm tra `skill_lmb`, `skill_rmb`, `skill_q`, `skill_e`.<br>• Nhãn HUD góc trái trên vẫn ghi cũ `"RMB: Khiên Phản Kích"`. | • **Task 23.4:** Ánh xạ trực tiếp phím cứng `KEY_U`, `KEY_I`, `KEY_O`, `KEY_P` (chống Unikey chặn phím) cho 4 kỹ năng, hỗ trợ định hướng thông minh theo hướng chạy/quái gần nhất khi bấm phím `U-I-O-P`, và đồng bộ toàn bộ chữ trên HUD. |
| **5** | **Màn hình 165 FPS vẫn bị cảm giác lag & Dòng `Blade Tip` nhảy số liên tục.** | • `telemetry_blade_label` trong `strict_qa_hud.gd` in tọa độ mũi kiếm 165 lần/giây làm UI tính lại layout liên tục.<br>• `_apply_wall_micro_separation()` cộng thẳng `global_position` sau `move_and_slide()` gây giật vị trí.<br>• Vật lý và Camera đang chạy ở `_physics_process` ($60\text{Hz}$) lệch với màn hình $165\text{Hz}$, cộng thêm `_update_occlusion_fade()` gọi `find_children()` mỗi frame. | • **Task 23.5:** Xóa hẳn dòng `Blade Tip`, khóa HUD chỉ cập nhật chữ $4\text{ lần/giây}$.<br>• Tắt hoàn toàn `_apply_wall_micro_separation()`.<br>• Đồng bộ `physics_ticks_per_second = 165`, chuyển Camera sang `_process(delta)` và cache raycast occlusion. |

---

## 🪜 TASK 23.1 (ƯU TIÊN SỐ 1): ĐẬP ĐI XÂY LẠI VA CHẠM CẦU THANG CHUẨN WORLD-ALIGNED (XÓA 100% VẬT THỂ TÀNG HÌNH & LỖI ĐI XUYÊN THÀNH THANG)

**File thực thi:** `src_game/scripts/levels/kaykit_arena_builder.gd`

### 1. Chuẩn hóa hàm tạo va chạm cầu thang `create_leakproof_stair_assembly`:
Trong `kaykit_arena_builder.gd`, **xóa hoàn toàn** nội dung hàm `create_leakproof_stair_assembly` cũ (vốn xoay nghiêng node cha `ramp_body` làm 6 khối hộp con biến thành vật thể tàng hình chổng ngược ra đường) và thay thế bằng hàm chuẩn hệ trục Thế giới (`World-Aligned`, `ramp_width = 4.0` khớp đúng kích thước $4.0\text{m}$ của `stairs_wide.gltf.glb`) dưới đây:

```gdscript
static func _compute_world_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var found := false
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi and mi.mesh:
			var mesh_aabb := mi.global_transform * mi.get_aabb()
			if not found:
				result = mesh_aabb
				found = true
			else:
				result = result.merge(mesh_aabb)
	return result

static func create_leakproof_stair_assembly(parent: Node3D, bottom_center: Vector3, top_center: Vector3, ramp_width: float = 4.0) -> StaticBody3D:
	# QUAN TRỌNG: Node StaticBody3D gốc giữ nguyên rotation = Vector3.ZERO (World-Aligned 100%, 0% hộp con bị chổng ngược!)
	var stair_body := StaticBody3D.new()
	stair_body.name = "SmoothStairRampCollider"
	stair_body.collision_layer = 1
	stair_body.collision_mask = 0
	stair_body.add_to_group("stairs")
	parent.add_child(stair_body)
	stair_body.global_position = Vector3.ZERO
	stair_body.rotation = Vector3.ZERO

	# Chiều rộng thực tế của mô hình stairs_wide.gltf.glb là 4.0m (X từ center - 2.0 đến center + 2.0)
	var actual_width := 4.0
	var half_w := actual_width * 0.5
	var min_y := minf(bottom_center.y, top_center.y)
	var max_y := maxf(bottom_center.y, top_center.y)
	var rise_height := max_y - min_y
	var min_z := minf(bottom_center.z, top_center.z) # Đỉnh cầu thang (Z nhỏ hơn, phía Bắc)
	var max_z := maxf(bottom_center.z, top_center.z) # Chân cầu thang (Z lớn hơn, phía Nam)
	var total_depth := max_z - min_z
	var center_x := (bottom_center.x + top_center.x) * 0.5
	var center_z := (min_z + max_z) * 0.5

	# 1. HAI KHỐI THÀNH ĐÁ LAN CAN HAI BÊN CẦU THANG (World-Aligned, thẳng đứng 100%)
	# Phủ trùm toàn bộ độ dày thành đá hai bên cầu thang (từ mép 2.0m vào lòng 1.35m và đệm ra ngoài +0.18m)
	# Nhân vật đi từ hai bên hông vào sẽ chạm mặt phẳng đứng êm ái, 0% đi xuyên vào thành cầu thang như trong ảnh chụp!
	var rail_thickness := 0.85
	for side in [-1.0, 1.0]:
		var rail_col := CollisionShape3D.new()
		rail_col.name = "StairSideBalustrade_" + ("L" if side < 0.0 else "R")
		var rail_box := BoxShape3D.new()
		rail_box.size = Vector3(rail_thickness, rise_height + 2.4, total_depth + 0.15)
		rail_col.shape = rail_box
		var rail_center_x := center_x + side * (half_w - rail_thickness * 0.5 + 0.18)
		rail_col.position = Vector3(rail_center_x, min_y + (rise_height + 2.4) * 0.5, center_z)
		stair_body.add_child(rail_col)

	# 2. MẶT DỐC PHẲNG Ở LÒNG GIỮA CẦU THANG (Chỉ xoay duy nhất node CollisionShape3D này!)
	# Mở rộng chân dốc ra phía trước +0.35m và hạ nhẹ -0.08m dưới mặt sàn để khi đi bộ hoặc Lướt (Space) từ dưới lên không có bất kỳ gờ cản nào!
	var walkable_width := actual_width - 1.10 # Rộng 2.90m nằm lọt giữa 2 thành đá
	var smooth_bot := Vector3(center_x, min_y - 0.08, max_z + 0.35)
	var smooth_top := Vector3(center_x, max_y - 0.02, min_z - 0.10)
	var slope_len := smooth_top.distance_to(smooth_bot)
	var slope_mid := (smooth_bot + smooth_top) * 0.5

	var ramp_col := CollisionShape3D.new()
	ramp_col.name = "WalkableRampSurface"
	var ramp_box := BoxShape3D.new()
	ramp_box.size = Vector3(walkable_width, 0.22, slope_len)
	ramp_col.shape = ramp_box
	stair_body.add_child(ramp_col)
	ramp_col.global_position = slope_mid - Vector3(0.0, 0.11, 0.0)
	ramp_col.look_at_from_position(ramp_col.global_position, smooth_top - Vector3(0.0, 0.11, 0.0), Vector3.UP)

	# 3. KHỐI ĐẶC LẤP GẦM NỬA SAU CẦU THANG (World-Aligned, nằm gọn ở nửa sau cầu thang, 0% nhô ra chân thang)
	var under_col := CollisionShape3D.new()
	under_col.name = "UnderStairBackCore"
	var under_box := BoxShape3D.new()
	under_box.size = Vector3(actual_width + 0.30, rise_height, total_depth * 0.52)
	under_col.shape = under_box
	under_col.position = Vector3(center_x, min_y + rise_height * 0.5, min_z + total_depth * 0.26)
	stair_body.add_child(under_col)

	return stair_body
```

### 2. Dời các Cột Đá (`PROP_PILLAR`) ra xa Hông Cầu Thang và giảm đệm thừa:
- Trong hàm `_place_props_and_obstacles()` của `kaykit_arena_builder.gd`:
  - **Sửa vị trí cột Tầng 1 (`Z = -12.0`) và Tầng 2 (`Z = -17.0`):** Thay các tọa độ `X = -9.5, -2.5, 2.5, 9.5` (đang đứng sát mép cầu thang gây kẹt) thành 2 cột trang trí ở xa cầu thang: **`X = -12.0` và `X = +12.0`** (bỏ 2 cột ở `±2.5` để hành lang trước cầu thang thông thoáng tuyệt đối).
  - **Sửa vị trí cột chân và đỉnh cầu thang Tầng 3 (`Z = -24.0` và `Z = -28.5`):** Dời từ `X = ±3.5` ra **`X = ±6.0`** (cách mép cầu thang `4.0m`, xóa vĩnh viễn góc lag kẹp giữa cột và cầu thang trong ảnh chụp!).
- Trong hàm `_spawn_convex_piece`: Đổi dòng `attach_padded_obstacle_collider(inst, 0.28, 3.5)` thành **`attach_padded_obstacle_collider(inst, 0.04, 3.0)`** để khung va chạm ôm sát đúng thân cột/thùng gỗ thật, không phình to tạo vật cản tàng hình.

---

## ⚡ TASK 23.2 (ƯU TIÊN SỐ 2): SỬA DỨT ĐIỂM LỖI LƯỚT (`SPACE`) TỪ DƯỚI ĐI LÊN ĐỤNG CẦU THANG BỊ KẸT

**File thực thi:** `src_game/scripts/characters/hero_knight_3d.gd`

1. **Cho phép `_apply_stair_step_up` hỗ trợ nâng chân khi bắt đầu Lướt vào chân cầu thang:**
   - Sửa chữ ký hàm `_apply_stair_step_up`:
     ```gdscript
     func _apply_stair_step_up(move_dir: Vector3, delta: float, is_dashing: bool = false) -> void:
         if _dash_timer > 0.0 and not is_dashing:
             return
     ```
2. **Cập nhật khối `if _dash_timer > 0.0:` trong `_physics_process(delta)` của `hero_knight_3d.gd`:**
   - Khi người chơi bấm `Space` Lướt từ sàn phẳng đụng vào chân cầu thang (hoặc đang ở trên cầu thang), tự động tắt tạm thời `floor_block_on_wall` trong lúc trượt và hướng vector vận tốc `velocity.y` bám dọc theo mặt dốc cầu thang để nhân vật lướt vọt lên cầu thang êm ru mà không bị khựng:
   ```gdscript
	# --- Dash Override (Task 23.2: Lướt mượt từ dưới lên cầu thang 0% bị chặn) ---
	if _dash_timer > 0.0:
		_dash_timer -= delta
		var stair_state := _detect_stair_slope_ahead(_dash_dir)
		var is_on_stairs: bool = stair_state["on_stairs"]
		var slope_dy: float = stair_state["slope_dy"]

		if is_on_stairs:
			floor_block_on_wall = false
			var effective_dash_speed := DASH_SPEED * 0.78
			velocity.x = _dash_dir.x * effective_dash_speed
			velocity.z = _dash_dir.z * effective_dash_speed
			# Nếu đang lướt theo chiều đi lên dốc cầu thang (slope_dy > 0), cấp vận tốc Y bám theo mặt dốc
			if slope_dy > 0.02:
				velocity.y = clampf((slope_dy / 0.85) * effective_dash_speed, 2.5, effective_dash_speed * 0.72)
			elif slope_dy < -0.02:
				velocity.y = clampf((slope_dy / 0.85) * effective_dash_speed, -effective_dash_speed * 0.72, -1.0)
			_apply_stair_step_up(Vector3(velocity.x, 0.0, velocity.z), delta, true)
		else:
			floor_block_on_wall = true
			velocity.x = _dash_dir.x * DASH_SPEED
			velocity.z = _dash_dir.z * DASH_SPEED

		move_and_slide()
		floor_block_on_wall = true
		_check_dash_impact_against_enemies()
		return
   ```
3. **Thêm hàm cảm biến dốc cầu thang phía trước `_detect_stair_slope_ahead(dir: Vector3)` vào `hero_knight_3d.gd`:**
   ```gdscript
   func _detect_stair_slope_ahead(dir: Vector3) -> Dictionary:
       var on_stairs := false
       var slope_dy := 0.0
       if is_on_floor() and get_floor_normal().y < 0.96:
           on_stairs = true
       var space_state := get_world_3d().direct_space_state
       var horiz := Vector3(dir.x, 0.0, dir.z).normalized()
       if horiz.length_squared() > 0.01:
           # Tia 1: Quét ngang mũi giày (0.15m) và ống đồng (0.45m) phía trước 1.2m
           for h_y in [0.15, 0.45]:
               var from_p := global_position + Vector3(0.0, h_y, 0.0)
               var q_fwd := PhysicsRayQueryParameters3D.create(from_p, from_p + horiz * 1.2, 1)
               q_fwd.exclude = [get_rid()]
               var hit_fwd := space_state.intersect_ray(q_fwd)
               if not hit_fwd.is_empty():
                   var col_obj = hit_fwd.get("collider", null)
                   if (col_obj is Node and (col_obj as Node).is_in_group("stairs")) or (hit_fwd["normal"].y > 0.45 and hit_fwd["normal"].y < 0.96):
                       on_stairs = true
                       break
           # Tia 2: Đo độ chênh lệch độ cao mặt đất/dốc ở điểm phía trước 0.85m
           var top_probe := global_position + horiz * 0.85 + Vector3(0.0, 1.4, 0.0)
           var bot_probe := global_position + horiz * 0.85 + Vector3(0.0, -1.2, 0.0)
           var q_down := PhysicsRayQueryParameters3D.create(top_probe, bot_probe, 1)
           q_down.exclude = [get_rid()]
           var hit_down := space_state.intersect_ray(q_down)
           if not hit_down.is_empty():
               var down_col = hit_down.get("collider", null)
               if (down_col is Node and (down_col as Node).is_in_group("stairs")) or (hit_down["normal"].y > 0.45 and hit_down["normal"].y < 0.96):
                   on_stairs = true
               slope_dy = hit_down["position"].y - global_position.y
       return {"on_stairs": on_stairs, "slope_dy": slope_dy}
   ```

---

## 🧱 TASK 23.3 (ƯU TIÊN SỐ 3): BỊT KÍN KHE HỞ TƯỜNG CẠNH CẦU THANG & BỌC TƯỜNG ĐẶC DÀY CHỐNG XUYÊN / CHE CƠ THỂ 100%

**File thực thi:** `src_game/scripts/levels/kaykit_arena_builder.gd`, `src_game/scripts/characters/hero_knight_3d.gd`

### 1. Xếp khít 100% Tường Ngăn Tầng 2 (`Z = -16.0`) không còn khe hở cạnh cầu thang:
- Trong hàm `_build_tier_2_terrace()` của `kaykit_arena_builder.gd`:
  - Hai cầu thang rộng $4.0\text{m}$ đặt tại $X = -6.0$ (chiếm $[-8.0, -4.0]$) và $X = +6.0$ (chiếm $[+4.0, +8.0]$).
  - Sửa mảng tọa độ đặt tường từ `var wall_x_cols = [-14.0, -10.5, 0.0, 10.5, 14.0]` thành:
    ```gdscript
    var wall_x_cols = [-14.0, -10.0, -2.0, 2.0, 10.0, 14.0]
    ```
    *(Mỗi mảnh tường rộng $4.0\text{m}$: `-14` và `-10` phủ kín $[-16, -8]$; `-2` và `+2` phủ kín $[-4, +4]$; `+10` và `+14` phủ kín $[+8, +16]$. Khớp khít tuyệt đối với 2 cầu thang, xóa sạch khe hở đen cạnh cầu thang trong ảnh chụp!)*

### 2. Bọc Khối Hộp Va Chạm Đặc Dày (`ThickWallCollider`) cho MỌI Bức Tường (`WALL_ELEVATION`):
- Trong `kaykit_arena_builder.gd`, bên trong hàm `_spawn_trimesh_piece(path: String, pos: Vector3, rot_deg: Vector3, parent: Node)`:
  - Nếu `path == KayKitAssetRegistry.WALL_ELEVATION`, ngoài hoặc thay cho va chạm `Trimesh` mỏng, **bắt buộc gắn thêm một `StaticBody3D` chứa `BoxShape3D` dày $1.35\text{m}$ (rộng $4.2\text{m}$, cao $5.5\text{m}$)** để mặt phẳng va chạm vươn ra phía trước mặt gạch $+0.38\text{m}$:
  ```gdscript
	if path == KayKitAssetRegistry.WALL_ELEVATION:
		var wall_sb := StaticBody3D.new()
		wall_sb.name = "ThickWallCollider"
		wall_sb.collision_layer = 1
		wall_sb.collision_mask = 0
		inst.add_child(wall_sb)
		var wall_col := CollisionShape3D.new()
		var wall_box := BoxShape3D.new()
		# Rộng 4.2m (nối chồng khít các mảnh tường), Cao 5.5m, Dày 1.36m (đệm ra mỗi mặt tường +0.38m)
		wall_box.size = Vector3(4.20, 5.50, 1.36)
		wall_col.shape = wall_box
		wall_col.position = Vector3(0.0, 2.75, 0.0)
		wall_sb.add_child(wall_col)
  ```
- **Cập nhật `_build_solid_tier_cores()` trong `kaykit_arena_builder.gd`:**
  - Mở rộng `Solid_Core_Tier2` thành `Vector3(33.2, 4.0, 13.0)` tại `Vector3(0.0, 2.0, -21.8)` (mặt trước vươn ra tới $Z = -15.3$).
  - Mở rộng `Solid_Core_Tier3` thành `Vector3(17.2, 8.0, 13.0)` tại `Vector3(0.0, 4.0, -33.8)` (mặt trước vươn ra tới $Z = -27.3$).
- **Tăng bán kính `CapsuleShape3D` của `HeroKnight3D` lên `0.50m` (`hero_knight_3d.gd`):**
  - Trong `_ready()` của `hero_knight_3d.gd`, đặt `capsule.radius = 0.50`. Kết hợp với `ThickWallCollider`, đầu, vai và khiên của nhân vật luôn dừng trước mặt tường gạch một khoảng an toàn, **không bao giờ đi lún vào tường hay bị tường che mất một phần cơ thể**!

---

## ⌨️ TASK 23.4 (ƯU TIÊN SỐ 4): CHUYỂN ĐỔI BỘ NÚT KỸ NĂNG SANG `U - I - O - P` & ĐỒNG BỘ GIAO DIỆN HUD

**File thực thi:** `src_game/scripts/characters/hero_knight_3d.gd`, `src_game/scripts/ui/strict_qa_hud.gd`

### 1. Ánh xạ trực tiếp 4 Phím Kỹ Năng `U - I - O - P` bằng Mã Phím Vật Lý (Chống Unikey nuốt phím):
- Trong `hero_knight_3d.gd`, thêm bộ đọc phím vật lý `KEY_U`, `KEY_I`, `KEY_O`, `KEY_P` và hàm lấy hướng đánh thông minh khi dùng bàn phím:
```gdscript
var _prev_skill_phys_keys: Dictionary = {
	KEY_U: false,
	KEY_I: false,
	KEY_O: false,
	KEY_P: false
}

func _is_skill_key_just_pressed(phys_key: Key, action_name: String) -> Dictionary:
	if not get_window().has_focus():
		_prev_skill_phys_keys[phys_key] = false
		return {"pressed": false, "from_keyboard": false}
	var key_down := Input.is_physical_key_pressed(phys_key)
	var was_down: bool = _prev_skill_phys_keys.get(phys_key, false)
	_prev_skill_phys_keys[phys_key] = key_down
	var kb_just_pressed := key_down and not was_down
	var action_just_pressed := Input.is_action_just_pressed(action_name)
	return {
		"pressed": kb_just_pressed or action_just_pressed,
		"from_keyboard": kb_just_pressed
	}

## Khi bấm U / I / P trên bàn phím: Ưu tiên nhắm vào Bot gần nhất trong tầm đánh trước mặt, hoặc đánh theo hướng chạy WASD / hướng mặt hiện tại
func _get_smart_keyboard_aim_direction(max_auto_aim_range: float = 4.2) -> Vector3:
	var move_vec := _get_movement_input_vector()
	var base_dir := move_vec if move_vec.length_squared() > 0.01 else _get_forward_dir()

	var best_bot_dir := Vector3.ZERO
	var best_dist := max_auto_aim_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy is Node3D and not enemy.get("is_dead"):
			var diff: Vector3 = (enemy as Node3D).global_position - global_position
			if absf(diff.y) <= 2.2:
				diff.y = 0.0
				var d := diff.length()
				if d > 0.05 and d <= best_dist:
					var dir_to_bot := diff.normalized()
					if base_dir.dot(dir_to_bot) >= -0.15 or d <= 2.2:
						best_dist = d
						best_bot_dir = dir_to_bot
	if best_bot_dir.length_squared() > 0.01:
		return best_bot_dir
	return base_dir
```

### 2. Thay thế cụm kiểm tra nút chiến đấu trong `_physics_process(delta)` của `hero_knight_3d.gd`:
- **Phím `U` (hoặc `LMB`) — Liên Trảm (Combo 3 Nhịp):**
  ```gdscript
	var trig_u := _is_skill_key_just_pressed(KEY_U, "skill_lmb")
	var trig_i := _is_skill_key_just_pressed(KEY_I, "skill_rmb")
	var trig_o := _is_skill_key_just_pressed(KEY_O, "skill_q")
	var trig_p := _is_skill_key_just_pressed(KEY_P, "skill_e")

	if trig_i["pressed"]:
		var aim_i := _get_smart_keyboard_aim_direction(5.5) if trig_i["from_keyboard"] else _get_stable_aim_direction()
		if can_act and _cd_rmb_timer <= 0.0:
			_do_rmb_cross_cleave(aim_i)
			return
		elif _cd_rmb_timer <= 0.18 or _action_lock_timer <= 0.18:
			_buffered_action = "skill_rmb"
			_buffer_timer = 0.18

	if trig_o["pressed"]:
		var aim_o := _get_smart_keyboard_aim_direction(4.0) if trig_o["from_keyboard"] else _get_stable_aim_direction()
		if can_act and _cd_q_timer <= 0.0 and not _is_spinning_q:
			_do_spin_attack(aim_o)
			return
		elif _cd_q_timer <= 0.18 or _action_lock_timer <= 0.18:
			_buffered_action = "skill_q"
			_buffer_timer = 0.18

	if trig_p["pressed"]:
		if can_act and _cd_e_timer <= 0.0 and not _is_throwing_e:
			if trig_p["from_keyboard"]:
				var throw_dir := _get_smart_keyboard_aim_direction(7.5)
				_do_ranged_throw(global_position + throw_dir * 4.8)
			else:
				_do_ranged_throw()
			return
		elif _cd_e_timer <= 0.18 or _action_lock_timer <= 0.18:
			_buffered_action = "skill_e"
			_buffer_timer = 0.18

	if can_act:
		if trig_u["pressed"]:
			var aim_u := _get_smart_keyboard_aim_direction(3.5) if trig_u["from_keyboard"] else _get_stable_aim_direction()
			_do_melee_combo(aim_u)
			return
  ```
- Đồng thời đăng ký thêm `KEY_U`, `KEY_I`, `KEY_O`, `KEY_P` vào `InputMap` trong `_ready()` của `hero_knight_3d.gd` (cho các action `"skill_lmb"`, `"skill_rmb"`, `"skill_q"`, `"skill_e"`) để mọi trình test tự động đều nhận diện được.

### 3. Cập nhật hiển thị `U - I - O - P` đồng nhất trên `StrictQAHUD` (`strict_qa_hud.gd`):
- Sửa dòng `hero_skills_label.text` (góc trái trên) thành:
  `"Phím Kỹ Năng: [U] Liên Trảm | [I] Phá Không Trảm | [O] Xoay 360° | [P] Bom Lôi Vụ | [Space] Lướt | [C] Nhảy"`
- Sửa dòng `skill_cooldown_label.text` (thanh Cooldown dưới đáy màn hình) thành:
  `"[U] Liên Trảm: SẴN SÀNG   |   [I] Phá Không Trảm: %s   |   [O] Cuồng Phong 360°: %s   |   [P] Bom Lôi Vụ (7.5m): %s"`

---

## 🖥️ TASK 23.5 (ƯU TIÊN SỐ 5): XÓA BỎ DÒNG `BLADE TIP` NHẢY SỐ LIÊN TỤC & TỐI ƯU ĐỘ MƯỢT TUYỆT ĐỐI CHO MÀN HÌNH 165HZ+

**File thực thi:** `src_game/scripts/ui/strict_qa_hud.gd`, `src_game/scripts/characters/hero_knight_3d.gd`, `src_game/scripts/enemies/enemy_minion_3d.gd`, `src_game/scripts/core/isometric_camera_3d.gd`, `src_game/scripts/levels/kaykit_arena_builder.gd`

### 1. Xóa dòng `Blade Tip` nhảy số liên tục & Giảm tần suất cập nhật chữ UI (`strict_qa_hud.gd`):
- Trong `src_game/scripts/ui/strict_qa_hud.gd`:
  - **Xóa hoàn toàn `telemetry_blade_label`** (không tạo node này trong `_build_ui()` và xóa đoạn đọc `blade_tip_marker.global_position` trong `_update_telemetry_display()`).
  - Thêm biến `var _ui_text_timer: float = 0.0` trong `strict_qa_hud.gd`. Trong `_process(delta)`:
    ```gdscript
    _ui_text_timer -= delta
    if _ui_text_timer <= 0.0:
        _ui_text_timer = 0.20 # Chỉ cập nhật chuỗi chữ UI 5 lần/giây thay vì 165 lần/giây!
        _update_telemetry_display(delta)
    ```
  - Tăng chu kỳ quét `_scan_timer` từ `0.5s` lên **`2.0s`**.

### 2. Tắt hàm dịch chuyển cứng `_apply_wall_micro_separation` gây rung giật vị trí (`hero_knight_3d.gd` & `enemy_minion_3d.gd`):
- Trong cả `hero_knight_3d.gd` và `enemy_minion_3d.gd`, sửa hàm `_apply_wall_micro_separation` thành hàm rỗng:
  ```gdscript
  func _apply_wall_micro_separation(_delta: float) -> void:
      pass
  ```
  *(Bởi vì việc bắn 8 tia Raycast mỗi frame rồi cộng thẳng `global_position += push_vec * 0.65` sau khi `move_and_slide()` đã chạy xong chính là thủ phạm làm nhân vật và Camera bị giật khấc liên tục khi đi gần tường/cầu thang!)*

### 3. Đồng bộ Tần Số Vật Lý (`physics_ticks_per_second`) theo Màn Hình 165Hz+ & Đưa Camera Về `_process(delta)`:
- Trong `kaykit_arena_builder.gd` (ngay đầu hàm `_ready()`):
  ```gdscript
  var screen_rate := DisplayServer.screen_get_refresh_rate()
  var target_hz := int(round(screen_rate)) if screen_rate > 60.0 else 165
  Engine.physics_ticks_per_second = clampi(target_hz, 120, 240)
  Engine.max_physics_steps_per_frame = 8
  ```
- Trong `src_game/scripts/core/isometric_camera_3d.gd`:
  - Chuyển toàn bộ logic di chuyển Camera bám theo `target_node` từ `_physics_process(delta)` sang **`_process(delta)`** với công thức làm mượt hàm mũ độc lập tần số quét:
    ```gdscript
    var smooth_weight := 1.0 - exp(-14.0 * delta)
    global_position = global_position.lerp(desired_pos, smooth_weight)
    ```
  - Trong `_update_occlusion_fade()`:
    - Đặt bộ đếm `_occlusion_timer` để chỉ chạy mỗi **`0.15 giây`** (không chạy mỗi frame).
    - Nếu tia Raycast chạm phải mặt sàn hoặc cầu thang (`hit["normal"].y > 0.45` hoặc `(hit["collider"] is Node and (hit["collider"] as Node).is_in_group("stairs"))`), bỏ qua ngay lập tức, **tuyệt đối không gọi `find_children()` trên mặt sàn/cầu thang**!

---

## 🧪 TASK 23.6: KIỂM THỬ TỰ ĐỘNG 5 BÀI TEST NGHIÊM NGẶT & PUSH GITHUB (`AGENT-06`)

1. Tạo và chạy script kiểm thử tự động `src_game/tests/test_phase_23_unified_fixes.gd` kiểm chứng PASS 100% 5 bài test:
   - **Test 23.1 (Zero Invisible Obstacles & Zero Stair Side Clipping):** Đặt `HeroKnight3D` đi dọc hành lang trước chân cầu thang (`Z = -11.5`) và đi ép vào hai bên thành đá cầu thang (`X = -8.2` và `X = -3.8`) $\rightarrow$ Xác nhận không vướng bất kỳ vật thể tàng hình nào ở hành lang, và tâm nhân vật luôn dừng cách thành đá cầu thang $\ge 0.50\text{m}$ (0% lún vào bậc thang như Ảnh 1).
   - **Test 23.2 (Upward Stair Dash Smoothness):** Đặt `HeroKnight3D` ở chân cầu thang (`Vector3(-6.0, 0.05, -11.0)`), kích hoạt `_do_dodge()` lướt thẳng lên cầu thang (`Vector3(0, 0, -1)`) $\rightarrow$ Xác nhận nhân vật lướt vọt lên mặt dốc cầu thang đạt $Y \ge 1.6\text{m}$ trong 1 lần lướt mà không bị chặn ở chân thang.
   - **Test 23.3 (Thick Wall No-Clip & Gap-Free Stair Junction):** Cho `HeroKnight3D` chạy đâm thẳng vào bức tường cạnh cầu thang tại `X = 8.2, Z = -14.2` theo hướng `(0, 0, -1)` (đúng vị trí bị lún nửa người trong Ảnh 2) $\rightarrow$ Xác nhận tường đã kín khít 100% và nhân vật bị chặn dừng lại ở $Z \ge -14.85\text{m}$ (không đi xuyên vào tường).
   - **Test 23.4 (U - I - O - P Skill Keys):** Kiểm tra kích hoạt cả 4 kỹ năng qua phím `KEY_U` (Liên Trảm), `KEY_I` (Phá Không Trảm 55 DMG), `KEY_O` (Cuồng Phong $360^\circ$ CD 5.0s), `KEY_P` (Bom Lôi Vụ $\le 7.5\text{m}$, DoT + Slow 55%) và kiểm tra nhãn HUD hiển thị đúng `[U]`, `[I]`, `[O]`, `[P]`.
   - **Test 23.5 (165Hz Smoothness, No Blade Tip Label & Zero Primitive Meshes):** Xác nhận `Engine.physics_ticks_per_second >= 120`, `telemetry_blade_label == null`, và `PRIMITIVE MESHES == 0`.
2. Cập nhật lại file `docs/CURRENT_CODE_SNAPSHOT.md`, chụp ảnh màn hình thực tế lưu vào `docs/QA_REPORTS/screenshots/`, sau đó chạy `git add .`, `git commit -m "fix(phase23): world-aligned stair colliders, thick wall anti-clip, upward stair dash, U-I-O-P skill keys, and 165Hz zero-stutter"` và `git push` thẳng lên `https://github.com/NhutPham19/GameWizad`.