# 🔴 CHỈ ĐẠO PHẪU THUẬT LÕI DÀNH RIÊNG CHO CLAUDE OPUS 4.6 (CHỈ VIẾT 3 FILE LÕI PHASE 3 & PHASE 5 — TỐI ƯU TOKEN)

- **Người chỉ đạo (Chief Architect):** ARGONS
- **Model thực thi:** **CLAUDE OPUS 4.6**
- **Quy tắc tiết kiệm Token tuyệt đối cho Opus 4.6:**
  - **KHÔNG** quét toàn bộ thư mục dự án, **KHÔNG** chạy các vòng lặp kiểm thử dài dòng trên Terminal.
  - Mọi tài nguyên đã được chuẩn bị sẵn trong `res://assets/characters/Knight.glb` (đã tích hợp sẵn 75 animations bên trong file `.glb`), `res://assets/weapons/sword_1handed.gltf`, `res://assets/weapons/shield_square_color.gltf`, `res://assets/weapons/arrow.gltf`, `res://assets/weapons/smokebomb.gltf` và `res://assets/vfx_textures/` (Kenney Particle Pack).
  - Opus 4.6 **CHỈ TẬP TRUNG VIẾT CHÍNH XÁC 100% 3 FILE LÕI DƯỚI ĐÂY** để giải quyết dứt điểm chuyển động xương `Skeleton3D`, hệ tọa độ đa tầng và hiệu ứng VFX `0% Hình Khối`.

---

## 📄 FILE LÕI SỐ 1: `src_game/scripts/characters/kaykit_animation_binder.gd`
**Mục tiêu:** Sửa triệt để lỗi nhân vật bị đơ / trượt lướt ván và lỗi cầm chồng vũ khí của mô hình KayKit.

### Yêu cầu kỹ thuật bắt buộc trong `kaykit_animation_binder.gd`:
1. **Xóa bỏ mọi `AnimationTree` gây khóa xương** và tìm đúng `Skeleton3D` cùng `AnimationPlayer` tích hợp sẵn bên trong `Knight.glb` (75 animations).
2. **Chuẩn hóa lại đường dẫn từng Track xương (`_remap_tracks_to_skeleton`):**
   - Tính đường dẫn tương đối chính xác từ `anim_player.get_node(anim_player.root_node)` tới `Skeleton3D`:
     ```gdscript
     var root_ref := anim_player.get_node(anim_player.root_node)
     var exact_skel_path := String(root_ref.get_path_to(skel))
     ```
   - Duyệt qua toàn bộ 75 animations trong `AnimationPlayer`:
     - Đặt `loop_mode = Animation.LOOP_LINEAR` cho các animation có tên chứa `"idle"`, `"walk"`, `"running"` (như `Idle`, `Walking_A`, `Running_A`) và `Animation.LOOP_NONE` cho các đòn đánh/nhảy/né.
     - Với mỗi track `i`, lấy tên khớp xương `subnames = track_path.get_concatenated_subnames()`. Nếu `skel.find_bone(subnames) != -1`, ghi đè đường dẫn track bằng `NodePath(exact_skel_path + ":" + subnames)` để **100% khớp xương cử động thật**.
3. **Dọn sạch vũ khí thừa & Gắn Vũ khí kèm `BladeCenterMarker` / `BladeTipMarker`:**
   - Hàm `clear_all_hand_slots(skel: Skeleton3D)`: Duyệt mọi `BoneAttachment3D` con của `Skeleton3D` và xóa sạch (`free()`) toàn bộ mesh vũ khí gắn sẵn mặc định trong `.glb`.
   - Hàm `attach_weapon_to_bone(skel: Skeleton3D, bone_name: String, gltf_path: String, add_blade_markers: bool) -> Node3D`:
     - Tìm hoặc tạo `BoneAttachment3D` gắn vào `bone_name` (`handslot.r` hoặc `handslot.l`).
     - Instantiate file `.gltf` vũ khí với `position = Vector3.ZERO`, `rotation = Vector3.ZERO`, `scale = Vector3.ONE`.
     - Nếu `add_blade_markers == true` (dành cho thanh kiếm `sword_1handed.gltf`), tạo 2 `Marker3D` làm con trực tiếp của thanh kiếm:
       - `BladeCenterMarker` tại `Vector3(0.0, 0.45, 0.0)`
       - `BladeTipMarker` tại `Vector3(0.0, 0.88, 0.0)`
       *(Hai Marker này sẽ di chuyển theo đúng quỹ đạo vung kiếm 3D của bàn tay phải để phát hạt VFX ở File số 2!).*

---

## 📄 FILE LÕI SỐ 2: `src_game/scripts/vfx/kaykit_vfx_manager.gd`
**Mục tiêu:** Cung cấp hệ thống VFX thuần khiết với **tọa độ chính xác tuyệt đối** và **0% Hình Khối Cơ Bản**.

> ⛔ **LUẬT CẤM TUYỆT ĐỐI:** Nghiêm cấm viết từ khóa `BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PrismMesh`, `TorusMesh` ở bất kỳ dòng nào trong `kaykit_vfx_manager.gd`!

### Cấu trúc 4 hàm VFX chuẩn xác trong `KayKitVFXManager`:
1. **Hàm tạo Vật liệu Hạt Không Lộ Viền Vuông (`_create_additive_particle_mat(tex_path: String, tint: Color)`):**
   - Dùng `StandardMaterial3D` với:
     - `transparency = BaseMaterial3D.TRANSPARENCY_ALPHA`
     - `blend_mode = BaseMaterial3D.BLEND_MODE_ADD` *(Cộng sáng giúp nền đen/trong suốt của ảnh Kenney biến mất 100%, không bao giờ lộ khung vuông)*
     - `shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED`
     - `billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES`
     - `vertex_color_use_as_albedo = true`
     - `albedo_color = tint`
     - Nạp texture từ `res://assets/vfx_textures/` (`slash_01.png`, `spark_02.png`, `flame_02.png`, `smoke_04.png`, `star_04.png`).
2. **`attach_sword_trail_particles(blade_center: Marker3D, blade_tip: Marker3D) -> Array[GPUParticles3D]`:**
   - Tạo 2 node `GPUParticles3D` (`emitting = false`, `local_coords = false`, `amount = 32`, `lifetime = 0.16`) gắn trực tiếp làm con của `blade_center` (dùng `slash_01.png` màu vàng kim) và `blade_tip` (dùng `spark_02.png` màu cam sáng).
   - Khi `Knight` vung kiếm, chỉ cần bật `emitting = true` trong khoảng thời gian chém (`0.28s`): luồng hạt sẽ tự động vẽ ra vệt kiếm khí 3D bám khít 100% theo lưỡi kiếm thật!
3. **`spawn_hit_impact_at_chest(target_node: Node3D)`:**
   - Tọa độ nổ chính xác tại ngực mục tiêu: `var hit_pos := target_node.global_position + Vector3(0.0, 0.95, 0.0)`.
   - Tạo `GPUParticles3D` (`one_shot = true`, `explosiveness = 0.95`, `amount = 18`, `lifetime = 0.35`) dùng texture `spark_05.png` / `star_04.png` bung ra tại đúng `hit_pos` rồi tự xóa (`finished.connect(queue_free)`).
4. **`spawn_ground_decal_shockwave(parent: Node, ground_pos: Vector3, radius: float, color: Color)` & `spawn_kaykit_3d_projectile(...)`:**
   - **Ấn chú mặt đất đa tầng:** Dùng node **`Decal`** nguyên bản của Godot 4 đặt tại `ground_pos` với `size = Vector3(radius * 2.0, 3.5, radius * 2.0)`, `texture_albedo = load("res://assets/vfx_textures/circle_01.png")`, `modulate = color`. Dùng `Tween` phóng nhẹ bán kính và giảm dần `modulate.a` về `0.0` trong `0.6s` rồi `queue_free()`. Node `Decal` tự động in khớp lên bậc cầu thang và mặt sàn đa tầng mà không tạo ra bất kỳ khối 3D nào!
   - **Đạn 3D thật của KayKit:** Phóng mô hình thật `res://assets/weapons/smokebomb.gltf` (bay vòng cung tới điểm chuột rồi bung cụm hạt khói `smoke_04.png`) hoặc `res://assets/weapons/arrow.gltf` (mũi tên 3D bay thẳng từ tay nhân vật).

---

## 📄 FILE LÕI SỐ 3: `src_game/scripts/characters/hero_knight_3d.gd`
**Mục tiêu:** Điều khiển duy nhất 1 Nhân vật `Knight.glb` chuyển động mượt mà đủ 12 kiểu dáng, leo cầu thang 3 tầng chính xác và ngắm chuột Raycast 3D đa tầng.

### Yêu cầu kỹ thuật bắt buộc trong `HeroKnight3D` (`CharacterBody3D`):
1. **Cấu hình Vật lý & Leo Cầu Thang Đa Tầng:**
   - Thêm vào group `"player"`. Đặt `collision_layer = 2`, `collision_mask = 1 | 4`.
   - Khởi tạo `CollisionShape3D` với `CapsuleShape3D` (`radius = 0.38`, `height = 1.75`) tại `position = Vector3(0.0, 0.875, 0.0)` để đáy Capsule chạm đúng `Y = 0.00m` ngang đế giày của `Knight.glb`.
   - Đặt `floor_snap_length = 0.45`, `floor_max_angle = deg_to_rad(52.0)`, `floor_stop_on_slope = true`, `floor_constant_speed = true`.
2. **Khởi tạo Mô hình, Vũ khí & VFX Lưỡi Kiếm trong `_ready()`:**
   - Instantiate `res://assets/characters/Knight.glb` vào `VisualRoot`.
   - Gọi `KayKitAnimationBinder.setup_and_bind_internal_animations(knight_model)`.
   - Gọi `KayKitAnimationBinder.clear_all_hand_slots(skeleton)`.
   - Gắn `res://assets/weapons/sword_1handed.gltf` vào `handslot.r` (`add_blade_markers = true`) và `res://assets/weapons/shield_square_color.gltf` vào `handslot.l`.
   - Gọi `KayKitVFXManager.attach_sword_trail_particles(blade_center_marker, blade_tip_marker)`.
3. **Hệ Tọa Độ Di Chuyển WASD, Xoay Mặt Trục `+Z` & Raycast Chuột Đa Tầng:**
   - **Chiếu trục Camera cho WASD:** Lấy `screen_right` và `screen_up` từ `Camera3D` để `W` luôn đi Lên, `S` đi Xuống, `A` sang Trái, `D` sang Phải.
   - **Xoay mặt đúng trục `+Z` của KayKit:** Khi di chuyển (và không bị khóa bởi đòn đánh), xoay `visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(move_dir.x, move_dir.z), 16.0 * delta)`.
   - **Hàm `get_accurate_ground_cursor_pos() -> Vector3`:** Dùng `PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1)` (`intersect_ray` vào Layer 1 của mặt sàn/cầu thang) để lấy đúng tọa độ chuột dù con trỏ đang trỏ lên Tầng 1 ($Y=0$), Tầng 2 ($Y=2$) hay Tầng 3 ($Y=4$). Khi tung chiêu, xoay mặt tức thời về phía `cursor_pos` bằng `atan2(aim_dir.x, aim_dir.z)`.
4. **Vận hành mượt mà 12 Hoạt ảnh KayKit (Không bị cắt ngang, không bị đơ):**
   - Dùng biến `_action_lock_timer: float = 0.0`. Khi `_action_lock_timer > 0.0`, tuyệt đối không cho `Idle` hay `Running_A` ghi đè lên hoạt ảnh chiến đấu!
   - **Đứng yên / Đi bộ / Chạy:** `Idle` / `Walking_A` / `Running_A` (cross-fade `0.12s`).
   - **Nhảy (Phím `C`):** `Jump_Start` $\rightarrow$ `Jump_Idle` $\rightarrow$ `Jump_Land` (`velocity.y = 8.5`).
   - **Lướt né (Phím `Space`):** `Dodge_Forward` (`_action_lock_timer = 0.35s`, tốc độ lướt `14.0m/s`).
   - **Combo Chém 3 Nhịp (`Chuột Trái - LMB`):**
     - Nhịp 1: `1H_Melee_Attack_Slice_Horizontal`
     - Nhịp 2: `1H_Melee_Attack_Slice_Diagonal`
     - Nhịp 3: `1H_Melee_Attack_Chop`
     - Khi chém: Bật hạt vệt kiếm trên lưỡi kiếm trong `0.28s`, quét các lính trong tầm hình quạt phía trước (`radius = 2.4m`) để gọi `enemy.take_damage(25.0, aim_dir)` và nổ hạt tại ngực lính.
   - **Đỡ Khiên Phản Kích (`Chuột Phải - RMB`):** Phát `Block` tiếp nối `1H_Melee_Attack_Stab`, gọi `KayKitVFXManager.spawn_ground_decal_shockwave()` dưới chân và đẩy lùi lính xung quanh.
   - **Tuyệt Chiêu Xoay Kiếm 360 Độ (`Phím Q`):** Phát `2H_Melee_Attack_Spinning` (`_action_lock_timer = 0.65s`), bật vệt kiếm rực sáng xoay 360 độ kèm ấn chú `Decal` dưới mặt đất, gây sát thương diện rộng bán kính `3.5m`.
   - **Phóng Đạn 3D KayKit (`Phím E`):** Phát hoạt ảnh `Throw` (hoặc `1H_Ranged_Shoot`), gọi `KayKitVFXManager.spawn_kaykit_3d_projectile()` phóng mô hình 3D thật `smokebomb.gltf` hoặc `arrow.gltf` tới đúng tọa độ chuột đa tầng.
   - **Trúng đòn & Tử trận:** `Hit_A` và `Death_A`.

---

## ✅ ĐIỀU KIỆN BÀN GIAO CỦA OPUS 4.6
Sau khi tạo xong 3 file `.gd` trên (và gắn `HeroKnight3D` vào scene `kaykit_multitier_arena.tscn`), Opus 4.6 dừng lại ngay để tiết kiệm Token và bàn giao lại cho **Gemini 3.8 Flash** chạy nốt Phase 4 (AI Lính `Barbarian.glb`) và Phase 6 (Kiểm thử & Chụp ảnh)!