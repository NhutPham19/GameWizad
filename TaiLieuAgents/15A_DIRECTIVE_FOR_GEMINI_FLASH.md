# 🟢 CHỈ ĐẠO THỰC THI DÀNH RIÊNG CHO GEMINI 3.8 FLASH (HOÀN TẤT PHASE 1, XÂY BẢN ĐỒ ĐA TẦNG PHASE 2, LÍNH PHASE 4 & QA PHASE 6)

- **Người chỉ đạo (Chief Architect):** ARGONS
- **Model thực thi:** **GEMINI 3.8 FLASH**
- **Phạm vi công việc của Gemini Flash:**
  1. **Nghiệm thu & Chốt phương án Phase 1** (Dùng `Barbarian.glb` có sẵn 75 animations làm Lính đối kháng thay cho `Skeleton_Warrior.glb` bị thiếu).
  2. **Thực thi trọn vẹn Phase 2:** Xây dựng Bản đồ Đa Tầng 3 Độ Cao (`kaykit_multitier_arena.tscn` + `kaykit_arena_builder.gd`) 100% từ mảnh ghép `.glb/.gltf` của KayKit.
  3. **Thực thi Phase 4 & Phase 6** *(Sau khi Claude Opus 4.6 viết xong 3 file lõi của Phase 3 & Phase 5)*.

---

## ✅ PHẦN 1: PHÊ DUYỆT KẾ HOẠCH PHASE 1 & GIẢI QUYẾT CHỐT CHẶN LÍNH ĐỐI KHÁNG

1. **Phê duyệt Total Purge & `KayKitAssetRegistry`:**
   - Đồng ý 100% với kế hoạch xóa sạch các file nhân vật cũ, biome cũ và quái cũ dùng hình khối trong `implementation_plan.md`.
2. **Quyết định chính thức cho Mục `[STOP-AND-ASK GATE]` về Lính Test:**
   - Vì trong kho hiện tại chưa có `Skeleton_Warrior.glb`, **CHỐT PHƯƠNG ÁN 2**: Sử dụng ngay mô hình **`Barbarian.glb`** (từ gói *KayKit Adventurers* có sẵn, chứa đầy đủ 41 khớp xương và 75 animations chuẩn) làm **Lính Chiến Binh Đối Kháng (`EnemyMinion`)**!
   - Hãy copy `Barbarian.glb` vào `res://assets/characters/Barbarian.glb` và copy thêm `axe_1handed.gltf` (cùng file `.bin` và texture) vào `res://assets/weapons/axe_1handed.gltf`.
   - Bổ sung vào `src_game/scripts/core/kaykit_asset_registry.gd`:
     ```gdscript
     const ENEMY_MINION := "res://assets/characters/Barbarian.glb"
     const WEAPON_AXE := "res://assets/weapons/axe_1handed.gltf"
     ```
   - Chạy ngay test kiểm định Phase 1 (`test_phase_1_registry.gd`) đảm bảo 100% đường dẫn trong `KayKitAssetRegistry` trả về `ResourceLoader.exists(path) == true`.

---

## 🏔️ PHẦN 2: THỰC THI PHASE 2 — XÂY DỰNG BẢN ĐỒ ĐA TẦNG KAYKIT (`KayKit_MultiTier_Arena`)

> ⛔ **LUẬT CẤM HÌNH KHỐI (`ZERO PRIMITIVE GEOMETRY`):** Tuyệt đối không khởi tạo bất kỳ `BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PrismMesh`, `TorusMesh` nào trong toàn bộ bản đồ! 100% sàn, bậc thang, tường vách, cột đá, thùng gỗ, cây cối, tảng đá phải nạp từ `KayKitAssetRegistry`.

### 2.1. Đo kích thước thật (`AABB`) & Khóa Lưới Tọa Độ 3 Tầng (`src_game/scripts/levels/kaykit_arena_builder.gd`):
1. **Đo kích thước tự động từ Mesh thật của KayKit:**
   - Khi nạp `TILE_FLOOR` (`floor_tile_large.gltf.glb`) và `STAIRS_WIDE` (`stairs_wide.gltf.glb`), hãy lấy `AABB` thực tế của Mesh (chuẩn KayKit: mảnh sàn lớn kích thước ngang $4.0\text{m} \times 4.0\text{m}$, chiều cao mỗi tầng cầu thang `TIER_HEIGHT` khớp chính xác với `stairs_aabb.size.y`, thường là $2.0\text{m}$ hoặc $1.0\text{m}$).
2. **Thiết kế 3 Tầng Độ Cao Rõ Rệt (Multi-Tiered Architecture):**
   - **Tầng 1 (Thung lũng Trung tâm — $Y = 0.0\text{m}$):**
     - Lát lưới sàn $8 \times 8$ mảnh `TILE_FLOOR` (tạo quảng trường $32\text{m} \times 32\text{m}$ từ $X \in [-16, 16]$, $Z \in [-16, 16]$).
   - **Tầng 2 (Đài Cao Phía Bắc & Phía Đông — $Y = 1 \times \text{TIER\_HEIGHT}$):**
     - Lát sàn `TILE_FLOOR` ở độ cao $Y = \text{TIER\_HEIGHT}$ bao phủ khu vực phía Bắc ($Z \in [-28, -16]$, $X \in [-16, 16]$).
     - Dọc theo mép nối giữa Tầng 1 và Tầng 2 ($Z = -16$), đặt dãy tường đá `WALL_ELEVATION` (`wall.gltf.glb`) làm vách chắn sườn đồi, chừa trống 2 ô để đặt **2 Cầu Thang Rộng (`STAIRS_WIDE`)** tại $X = -6.0\text{m}$ và $X = +6.0\text{m}$.
     - Chân cầu thang chạm khít mặt sàn Tầng 1 ($Y = 0.0\text{m}$), đỉnh cầu thang chạm khít mép sàn Tầng 2 ($Y = \text{TIER\_HEIGHT}$), sai số $= 0.00\text{m}$.
   - **Tầng 3 (Đỉnh Đài Cổ Phía Bắc — $Y = 2 \times \text{TIER\_HEIGHT}$):**
     - Lát sàn `TILE_FLOOR` ở độ cao $Y = 2 \times \text{TIER\_HEIGHT}$ tại khu vực $Z \in [-40, -28]$, $X \in [-8, 8]$.
     - Dựng vách đá `WALL_ELEVATION` bao quanh và đặt **1 Cầu Thang Rộng (`STAIRS_WIDE`)** ở chính giữa ($X = 0.0\text{m}$) nối từ Tầng 2 lên Tầng 3.

### 2.2. Đặt Vật Cản KayKit & Tạo Va Chạm Vật Lý Chính Xác (`Collision Layer = 1`):
- Trên cả 3 tầng, bố trí hợp lý các vật cản từ `KayKitAssetRegistry`:
  - `PROP_TREE_A`, `PROP_TREE_B` (Cây cối quanh rìa quảng trường và trên đài cao).
  - `PROP_ROCK_A`, `PROP_ROCK_B` (Tảng đá chắn góc).
  - `PROP_PILLAR` (Hàng cột đá hai bên đầu cầu thang Tầng 2 và Tầng 3).
  - `PROP_BARREL`, `PROP_CHEST`, `PROP_TORCH` (Thùng gỗ, rương báu, đuốc sáng kèm `OmniLight3D` ấm áp đặt cạnh chân cầu thang và đỉnh đài).
- **Hàm tạo va chạm vật lý bắt buộc cho mọi mảnh ghép KayKit:**
  - Duyệt đệ quy mọi `MeshInstance3D` bên trong mô hình `.glb`/`.gltf` vừa instantiate:
    - Đối với `TILE_FLOOR`, `STAIRS_WIDE`, `STAIRS_NORMAL`, `WALL_ELEVATION`: Gọi `mesh_inst.create_trimesh_collision()` để bậc thang và mặt sàn có khung va chạm chuẩn xác từng centimet. Đảm bảo `StaticBody3D` sinh ra có `collision_layer = 1`, `collision_mask = 0`.
    - Đối với `PROP_TREE_*`, `PROP_ROCK_*`, `PROP_PILLAR`, `PROP_BARREL`, `PROP_CHEST`: Gọi `mesh_inst.create_convex_collision()`, đặt `collision_layer = 1`.
- Bọc toàn bộ địa hình trong `NavigationRegion3D` có `NavigationMesh` (`cell_size = 0.25`, `cell_height = 0.2`, `agent_max_climb = 0.5`, `agent_max_slope = 52.0`) để kết nối đường đi liền mạch giữa Tầng 1 $\leftrightarrow$ Tầng 2 $\leftrightarrow$ Tầng 3.

### 2.3. Thiết lập Camera Isometric $45^\circ$ & Hàm Raycast Chuột Đa Tầng:
- Tạo `src_game/scripts/core/isometric_camera_3d.gd` góc nghiêng Pitch $-48^\circ$, Yaw $45^\circ$, luôn bám mượt theo node đầu tiên trong group `"player"`.
- Lưu cảnh chính thành `res://scenes/levels/kaykit_multitier_arena.tscn` và cập nhật `run/main_scene` trong `project.godot`.

> 🛑 **ĐIỂM DỪNG BÀN GIAO CHO OPUS 4.6:** Ngay sau khi hoàn tất Phase 1 và Phase 2 (bản đồ 3 tầng hiển thị đẹp, không lỗi), Gemini Flash hãy dừng lại và báo cáo để User chuyển sang **Claude Opus 4.6** chạy File `15B_DIRECTIVE_FOR_CLAUDE_OPUS.md` (Phase 3 & Phase 5).

---

## 💀 PHẦN 3: THỰC THI PHASE 4 (CHỈ CHẠY SAU KHI OPUS 4.6 ĐÃ TẠO XONG PHASE 3 & 5)
**Nhiệm vụ cho Gemini Flash:** Tạo Lính đối kháng `src_game/scripts/enemies/enemy_minion_3d.gd` sử dụng `Barbarian.glb`:
1. Kế thừa `CharacterBody3D` (`collision_layer = 4`, `collision_mask = 1 | 2 | 4`, `floor_snap_length = 0.45`, `floor_max_angle = deg_to_rad(52.0)`).
2. Nạp `KayKitAssetRegistry.ENEMY_MINION` (`Barbarian.glb`), gọi trực tiếp:
   - `KayKitAnimationBinder.setup_and_bind_internal_animations(model_inst)` (Hàm do Opus 4.6 viết ở Phase 3).
   - `KayKitAnimationBinder.clear_all_hand_slots(skel)` và gắn duy nhất 1 vũ khí `KayKitAssetRegistry.WEAPON_AXE` (`axe_1handed.gltf`) vào `handslot.r`.
3. Đặt 5 Lính `EnemyMinion3D` trên bản đồ (2 lính ở Tầng 1, 2 lính ở Tầng 2, 1 lính ở Tầng 3).
4. **Chu trình AI Đa Tầng & Chiến Đấu Thật:**
   - Dùng `NavigationAgent3D` tìm đường đi qua cầu thang đuổi theo `HeroKnight3D` (group `"player"`).
   - Khi di chuyển: Xoay mặt `atan2(dir.x, dir.z)` và phát hoạt ảnh `Running_A` (hoặc `Walking_A`).
   - Khi vào tầm đánh ($\le 1.85\text{m}$): Dừng lại, xoay mặt nhìn `Knight` và phát hoạt ảnh `1H_Melee_Attack_Chop` hoặc `1H_Melee_Attack_Slice_Horizontal`, gây sát thương thật lên `Knight` ở giữa nhịp vung rìu.
   - Khi trúng đòn của `Knight` (`take_damage(amount, knockback_dir)`):
     - Trừ HP, đẩy lùi nhẹ theo `knockback_dir`, phát hoạt ảnh giật người `Hit_A`.
     - Gọi `KayKitVFXManager.spawn_hit_impact_at_chest(self)` (do Opus 4.6 viết) nổ tia lửa ngay ngực.
     - Khi `hp <= 0`: Phát hoạt ảnh `Death_A`, tắt va chạm và xóa sau $1.8\text{s}$.

---

## 🔬 PHẦN 4: THỰC THI PHASE 6 — BẢNG ĐO QA TELEMETRY & CHỤP 5 ẢNH GPU RTX 4060
**Nhiệm vụ cho Gemini Flash:** Tạo `src_game/scripts/ui/strict_qa_hud.gd` hiển thị góc phải trên màn hình:
1. **`[PRIMITIVE MESH COUNT]`:** Quét toàn bộ Scene Tree mỗi $0.5\text{s}$. Đếm mọi `BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PrismMesh`, `TorusMesh` (ngoại trừ `QuadMesh` phẳng dùng cho hạt `GPUParticles3D`). Bắt buộc hiển thị: **`HÌNH KHỐI VI PHẠM: 0 (PASS)`**.
2. **`[ACTIVE SKELETON BONES]`:** Đếm số khớp xương của `Knight` có biến thiên góc xoay giữa các frame khi chạy/chém (`Moving Bones >= 15/41`).
3. **`[ELEVATION & FOOT ACCURACY]`:** Đo độ lệch giữa `knight.global_position.y` và tia Raycast mặt sàn bên dưới chân (`Delta_Y <= 0.02m` trên cả Tầng 1, Cầu thang, Tầng 2, Tầng 3).
4. **Xuất 5 bức ảnh chụp màn hình thực tế trên GPU RTX 4060** vào `docs/QA_REPORTS/screenshots/` chứng minh: Bản đồ 3 tầng KayKit khớp khít, `Knight` và `Barbarian Minion` bước chân/vung vũ khí thật, và VFX bám đúng lưỡi kiếm + mặt đất (0% hình khối).