# 👑 CHỈ ĐẠO SỐ 22 TỪ ARGONS: XÓA GÓC LAG CỘT-CẦU THANG, SỬA KẸT KHI LƯỚT LÊN CẦU THANG, TỐI ƯU ĐỘ MƯỢT TẦN SỐ QUÉT CAO (144Hz–240Hz) & HOÀN THIỆN CHIÊU RMB / E

- **Người chỉ đạo (Chief Architect):** ARGONS
- **Đơn vị thực thi:** ANTIGRAVITY IDE (`Claude Opus 4.6` / `Gemini 3.8 Flash`)
- **Kho GitHub dự án:** `https://github.com/NhutPham19/GameWizad`
- **Luật Thép Bất Di Bất Dịch:** Tuyệt đối **0% khối hình học thô** (`PRIMITIVE MESHES: 0`). Giữ nguyên toàn bộ mô hình `.glb/.gltf` của KayKit, `ArrayMesh` dải lụa kiếm khí 3D, `GPUParticles3D` Kenney Textures và `Decal`.

---

## 🛠️ TASK 22.1 (ƯU TIÊN SỐ 1): XÓA SỔ GÓC LAG GIỮA CỘT ĐÁ & THÀNH CẦU THANG + SỬA HÌNH HỌC DỐC CẦU THANG (`kaykit_arena_builder.gd`)

### 1. Tách riêng Mặt Dốc Nghiêng & Khối Chắn Hệ Trục Thế Giới trong `create_leakproof_stair_assembly`:
- **Nguyên nhân gây kẹt chân cầu thang và góc lag hiện tại:**
  Trong `src_game/scripts/levels/kaykit_arena_builder.gd`, hàm `create_leakproof_stair_assembly` đang gắn `under_col` (khối lấp gầm), `side_col` (thành cầu thang) và `bevel_col` (phễu vát) làm con của `ramp_body` đã bị xoay nghiêng $45^\circ$ bằng `look_at_from_position`. Điều này làm cạnh hộp dưới gầm đâm xuyên lên mặt dốc ở chân thang (chặn đứng cú Dash từ dưới lên) và làm cánh phễu chọc ngang vào cột đá gây góc lag!
- **Cách sửa bắt buộc — Thay thế toàn bộ hàm `create_leakproof_stair_assembly` trong `kaykit_arena_builder.gd` bằng đoạn code chuẩn hệ trục World-Aligned sau:**

```gdscript
static func create_leakproof_stair_assembly(parent: Node3D, bottom_center: Vector3, top_center: Vector3, ramp_width: float = 4.6) -> StaticBody3D:
	# 1. Node StaticBody3D gốc giữ nguyên hệ trục Thế giới (rotation = Vector3.ZERO)
	var stair_body := StaticBody3D.new()
	stair_body.name = "SmoothStairRampCollider"
	stair_body.collision_layer = 1
	stair_body.collision_mask = 0
	stair_body.add_to_group("stairs")
	parent.add_child(stair_body)
	stair_body.global_position = Vector3.ZERO

	# Mở rộng điểm bắt đầu chân dốc ra phía trước 0.45m và hạ nhẹ -0.08m để tiếp tuyến êm 100% với mặt sàn dưới (0mm gờ cản khi Dash lên!)
	var forward_flat_dir := Vector3(top_center.x - bottom_center.x, 0.0, top_center.z - bottom_center.z).normalized()
	var smooth_bottom := bottom_center - forward_flat_dir * 0.45 - Vector3(0.0, 0.08, 0.0)
	var smooth_top := top_center + forward_flat_dir * 0.15 - Vector3(0.0, 0.05, 0.0)

	var ramp_diff := smooth_top - smooth_bottom
	var ramp_len := ramp_diff.length()
	var ramp_mid := (smooth_bottom + smooth_top) * 0.5
	var rise_height := top_center.y - bottom_center.y
	var half_w := ramp_width * 0.5

	# 2. Mặt dốc phẳng nghiêng liên tục (chỉ xoay riêng CollisionShape3D của mặt dốc)
	var ramp_col := CollisionShape3D.new()
	ramp_col.name = "RampSurfaceShape"
	var ramp_box := BoxShape3D.new()
	ramp_box.size = Vector3(ramp_width, 0.20, ramp_len)
	ramp_col.shape = ramp_box
	stair_body.add_child(ramp_col)
	ramp_col.global_position = ramp_mid - Vector3(0.0, 0.10, 0.0)
	ramp_col.look_at_from_position(ramp_col.global_position, smooth_top - Vector3(0.0, 0.10, 0.0), Vector3.UP)

	# 3. Hai vách chắn hông cầu thang thẳng đứng chuẩn hệ trục Thế giới (World-Aligned, không nhô ra ngoài làm hẹp lối đi)
	var center_xz := (bottom_center + top_center) * 0.5
	var horiz_len := Vector2(top_center.x - bottom_center.x, top_center.z - bottom_center.z).length()
	for side in [-1.0, 1.0]:
		var side_col := CollisionShape3D.new()
		var side_box := BoxShape3D.new()
		side_box.size = Vector3(0.24, rise_height + 2.2, horiz_len + 0.2)
		side_col.shape = side_box
		side_col.position = Vector3(
			center_xz.x + side * (half_w + 0.12),
			bottom_center.y + (rise_height + 2.2) * 0.5,
			center_xz.z
		)
		stair_body.add_child(side_col)

	# 4. Khối đặc chặn gầm phía sau cầu thang (World-Aligned, nằm hoàn toàn ở nửa sau cầu thang, tuyệt đối không trồi lên ở chân thang)
	var under_col := CollisionShape3D.new()
	var under_box := BoxShape3D.new()
	under_box.size = Vector3(ramp_width + 0.4, rise_height * 0.55, horiz_len * 0.48)
	under_col.shape = under_box
	under_col.position = Vector3(
		top_center.x,
		bottom_center.y + (rise_height * 0.55) * 0.5,
		lerpf(bottom_center.z, top_center.z, 0.76)
	)
	stair_body.add_child(under_col)

	return stair_body