# 🟢 CHỈ ĐẠO TỔNG HỢP CUỐI CÙNG CHO GEMINI 3.8 FLASH: KẾ THỪA KẾT QUẢ CỦA OPUS 4.6 & HOÀN THIỆN TRỌN VẸN PHASE 4 + PHASE 6

- **Người chỉ đạo (Chief Architect):** ARGONS
- **Model thực thi duy nhất từ bước này:** **GEMINI 3.8 FLASH**
- **Căn cứ hiện trạng (`15C_OPUS_COMPLETION_REPORT.md`):**
  - **Phase 1 & Phase 2:** Đã hoàn thành (`kaykit_multitier_arena.tscn`, `KayKitAssetRegistry`).
  - **Phase 3 & Phase 5 (Do Opus 4.6 thực hiện):** Đã hoàn thành 100% và PASS kiểm thử tự động (`Exit code: 0`):
    1. `src_game/scripts/characters/kaykit_animation_binder.gd` (Đã remap 76 animations, dọn tay, gắn vũ khí + `BladeCenterMarker` / `BladeTipMarker`).
    2. `src_game/scripts/vfx/kaykit_vfx_manager.gd` (VFX thuần hạt + `Decal` + Đạn 3D thật, **0% Hình Khối**).
    3. `src_game/scripts/characters/hero_knight_3d.gd` (Đã tích hợp vào `kaykit_multitier_arena.tscn` với 12 hoạt ảnh chuẩn KayKit).

---

## ⚠️ 3 QUY TẮC BẤT KHẢ XÂM PHẠM KHI GEMINI FLASH TIẾP QUẢN TỪ OPUS 4.6

1. **BẢO TỒN 100% CODE LÕI CỦA OPUS 4.6:**
   - **TUYỆT ĐỐI KHÔNG** viết đè làm hỏng logic ánh xạ xương trong `kaykit_animation_binder.gd`, hệ thống hạt trong `kaykit_vfx_manager.gd` và bộ điều khiển trong `hero_knight_3d.gd`.
   - Chỉ được đọc `hero_knight_3d.gd` để kiểm tra tên group kẻ địch (ví dụ `"enemies"`) và chữ ký hàm nhận sát thương `take_damage(...)` để viết `enemy_minion_3d.gd` khớp 100% với code của Opus!
2. **LUẬT THÉP `ZERO PRIMITIVE GEOMETRY` (0% HÌNH KHỐI):**
   - Nghiêm cấm sử dụng `BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PrismMesh`, `TorusMesh` ở bất kỳ đâu trong Phase 4 và Phase 6 (kể cả làm thanh máu 3D trên đầu lính — thanh máu trên đầu lính bắt buộc dùng `Sprite3D` hoặc vẽ trên `CanvasLayer` 2D HUD!).
3. **TÁI SỬ DỤNG 100% `KayKitAnimationBinder` & `KayKitVFXManager`:**
   - Lính đối kháng ở Phase 4 bắt buộc gọi lại chính các hàm của `KayKitAnimationBinder` và `KayKitVFXManager` mà Opus 4.6 đã viết.

---

## 💀 NHIỆM VỤ 1 (PHASE 4): XÂY DỰNG LÍNH ĐỐI KHÁNG ĐA TẦNG (`enemy_minion_3d.gd`) & KHỚP NỐI CHIẾN ĐẤU 2 CHIỀU

### 1.1. Kiểm tra & Đồng bộ Giao diện Sát thương với `hero_knight_3d.gd`:
Trước khi viết `enemy_minion_3d.gd`, Gemini Flash hãy đọc file `src_game/scripts/characters/hero_knight_3d.gd` do Opus 4.6 viết để kiểm tra:
- `HeroKnight3D` đang tìm kẻ địch qua group nào (đảm bảo `EnemyMinion3D` gọi `add_to_group("enemies")` và `add_to_group("enemy")`).
- `HeroKnight3D` gọi hàm `take_damage` của kẻ địch với mấy tham số (hỗ trợ mặc định `func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO) -> void` để dù gọi 1 hay 2 tham số đều chạy hoàn hảo 100%).

### 1.2. Viết kịch bản `src_game/scripts/enemies/enemy_minion_3d.gd`:
Tạo kịch bản điều khiển Lính đối kháng sử dụng mô hình **`Barbarian.glb`** (từ `KayKitAssetRegistry.ENEMY_MINION`) và vũ khí **`axe_1handed.gltf`** (`KayKitAssetRegistry.WEAPON_AXE`):

```gdscript
class_name EnemyMinion3D
extends CharacterBody3D

@export var max_hp: float = 80.0
@export var move_speed: float = 4.2
@export var attack_range: float = 1.9
@export var aggro_range: float = 24.0
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 1.35

var hp: float = 80.0
var is_dead: bool = false
var _action_lock_timer: float = 0.0
var _attack_cd_timer: float = 0.0
var _damage_dealt_in_swing: bool = false
var _is_attacking: bool = false
var _knockback_vel: Vector3 = Vector3.ZERO
var _current_anim: String = ""

var visual_root: Node3D
var model_inst: Node3D
var skeleton: Skeleton3D
var anim_player: AnimationPlayer
var nav_agent: NavigationAgent3D
var weapon_inst: Node3D
var blade_center_marker: Marker3D
var blade_tip_marker: Marker3D
var axe_trails: Array[GPUParticles3D] = []

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	add_to_group("enemy")

	# 1. Cấu hình Vật lý & Leo cầu thang 3 tầng khớp chuẩn với HeroKnight3D
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(52.0)
	floor_stop_on_slope = true
	floor_constant_speed = true

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.75
	col.shape = cap
	col.position = Vector3(0.0, 0.875, 0.0)
	add_child(col)

	# 2. Cấu hình NavigationAgent3D tìm đường qua cầu thang đa tầng
	nav_agent = NavigationAgent3D.new()
	nav_agent.path_desired_distance = 0.6
	nav_agent.target_desired_distance = 1.5
	nav_agent.path_max_distance = 5.0
	add_child(nav_agent)

	# 3. Khởi tạo Mô hình Barbarian.glb + Ánh xạ 75 Animations bằng KayKitAnimationBinder của Opus
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)

	var model_path := "res://assets/characters/Barbarian.glb"
	if not ResourceLoader.exists(model_path):
		model_path = "res://assets/characters/Knight.glb"
	var packed := load(model_path) as PackedScene
	if packed != null:
		model_inst = packed.instantiate() as Node3D
		visual_root.add_child(model_inst)

		# Gọi bộ Binder chuẩn của Opus 4.6
		if KayKitAnimationBinder.has_method("setup_and_bind_internal_animations"):
			anim_player = KayKitAnimationBinder.setup_and_bind_internal_animations(model_inst)
		skeleton = KayKitAnimationBinder.find_skeleton_3d(model_inst) if KayKitAnimationBinder.has_method("find_skeleton_3d") else _find_skel_fallback(model_inst)

		if skeleton != null:
			KayKitAnimationBinder.clear_all_hand_slots(skeleton)
			var axe_path := "res://assets/weapons/axe_1handed.gltf"
			if not ResourceLoader.exists(axe_path):
				axe_path = "res://assets/weapons/sword_1handed.gltf"
			weapon_inst = KayKitAnimationBinder.attach_weapon_to_bone(skeleton, "handslot.r", axe_path, true)
			if weapon_inst != null:
				blade_center_marker = weapon_inst.get_node_or_null("BladeCenterMarker") as Marker3D
				blade_tip_marker = weapon_inst.get_node_or_null("BladeTipMarker") as Marker3D
				if blade_center_marker != null and blade_tip_marker != null:
					axe_trails = KayKitVFXManager.attach_sword_trail_particles(blade_center_marker, blade_tip_marker)

	_play_anim_safe("Spawn_Ground")
	_action_lock_timer = 0.65

func _find_skel_fallback(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for c in node.get_children():
		var s := _find_skel_fallback(c)
		if s != null:
			return s
	return null

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = 0.0

	if _attack_cd_timer > 0.0:
		_attack_cd_timer -= delta

	# Xử lý lực đẩy lùi khi trúng đòn
	_knockback_vel = _knockback_vel.move_toward(Vector3.ZERO, 18.0 * delta)

	if _action_lock_timer > 0.0:
		_action_lock_timer -= delta
		# Gây sát thương ở giữa nhịp vung rìu
		if _is_attacking and not _damage_dealt_in_swing and _action_lock_timer <= 0.25:
			_damage_dealt_in_swing = true
			_try_hit_player()
		if _action_lock_timer <= 0.0:
			_is_attacking = false
			_set_axe_trails(false)
		velocity.x = _knockback_vel.x
		velocity.z = _knockback_vel.z
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or not is_instance_valid(player):
		_play_anim_safe("Idle")
		return

	var to_player := player.global_position - global_position
	var dist_3d := to_player.length()
	var flat_to_player := Vector3(to_player.x, 0.0, to_player.z)
	var flat_dist := flat_to_player.length()

	# Nếu trong tầm đánh & cùng tầng độ cao (chênh lệch Y < 1.3m)
	if flat_dist <= attack_range and absf(to_player.y) < 1.35:
		velocity.x = _knockback_vel.x
		velocity.z = _knockback_vel.z
		if flat_dist > 0.05:
			var aim_dir := flat_to_player.normalized()
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(aim_dir.x, aim_dir.z), 18.0 * delta)
		if _attack_cd_timer <= 0.0:
			_start_melee_attack()
		else:
			_play_anim_safe("Idle")
	elif dist_3d <= aggro_range:
		# Tìm đường qua cầu thang đa tầng bằng NavigationAgent3D
		nav_agent.target_position = player.global_position
		var next_pos := nav_agent.get_next_path_position()
		var move_vec := next_pos - global_position
		move_vec.y = 0.0
		if move_vec.length_squared() < 0.01:
			move_vec = flat_to_player
		var move_dir := move_vec.normalized()
		velocity.x = move_dir.x * move_speed + _knockback_vel.x
		velocity.z = move_dir.z * move_speed + _knockback_vel.z
		if move_dir.length_squared() > 0.01:
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(move_dir.x, move_dir.z), 14.0 * delta)
		_play_anim_safe("Running_A")
	else:
		velocity.x = _knockback_vel.x
		velocity.z = _knockback_vel.z
		_play_anim_safe("Idle")

	move_and_slide()

func _start_melee_attack() -> void:
	_is_attacking = true
	_damage_dealt_in_swing = false
	_action_lock_timer = 0.52
	_attack_cd_timer = attack_cooldown
	_set_axe_trails(true)
	var atk_anim := "1H_Melee_Attack_Chop" if randf() < 0.5 else "1H_Melee_Attack_Slice_Horizontal"
	_play_anim_safe(atk_anim)

func _try_hit_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or not is_instance_valid(player):
		return
	var diff := player.global_position - global_position
	if Vector2(diff.x, diff.z).length() <= attack_range + 0.45 and absf(diff.y) < 1.4:
		var dir := Vector3(diff.x, 0.0, diff.z).normalized()
		if player.has_method("take_damage"):
			player.take_damage(attack_damage, dir)
		KayKitVFXManager.spawn_hit_impact_at_chest(player)

func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	hp = maxf(0.0, hp - amount)
	_is_attacking = false
	_set_axe_trails(false)
	KayKitVFXManager.spawn_hit_impact_at_chest(self)

	if knockback_dir.length_squared() > 0.001:
		var flat_kb := Vector3(knockback_dir.x, 0.0, knockback_dir.z).normalized()
		_knockback_vel = flat_kb * 6.5

	if hp <= 0.0:
		is_dead = true
		collision_layer = 0
		collision_mask = 1
		_play_anim_safe("Death_A")
		var tw := create_tween()
		tw.tween_interval(1.8)
		tw.tween_callback(queue_free)
	else:
		_action_lock_timer = 0.32
		_play_anim_safe("Hit_A")

func _set_axe_trails(active: bool) -> void:
	for p in axe_trails:
		if is_instance_valid(p):
			p.emitting = active

func _play_anim_safe(anim_name: String) -> void:
	if anim_player == null:
		return
	var actual_name := anim_name
	if not anim_player.has_animation(actual_name):
		if anim_name == "Running_A" and anim_player.has_animation("Walk"):
			actual_name = "Walk"
		elif anim_name == "Spawn_Ground" and anim_player.has_animation("Idle"):
			actual_name = "Idle"
		else:
			return
	if _current_anim != actual_name:
		_current_anim = actual_name
		anim_player.play(actual_name, 0.12)
```

### 1.3. Đặt 5 Lính `EnemyMinion3D` lên 3 Tầng Bản Đồ (`kaykit_multitier_arena.tscn` / `kaykit_arena_builder.gd`):
- Sinh tự động 5 Lính `EnemyMinion3D` tại 3 độ cao để kiểm tra khả năng leo cầu thang đa tầng và chiến đấu:
  - **2 Lính ở Tầng 1 ($Y = 0.05\text{m}$):** Tại `Vector3(-6.0, 0.05, -4.0)` và `Vector3(6.0, 0.05, -4.0)`.
  - **2 Lính ở Tầng 2 ($Y = \text{TIER\_HEIGHT} + 0.05\text{m}$):** Ngay trên đài cao Tầng 2 phía sau cầu thang.
  - **1 Lính Thủ Lĩnh ở Tầng 3 ($Y = 2 \times \text{TIER\_HEIGHT} + 0.05\text{m}$, `max_hp = 150.0`):** Trên đỉnh đài cao Tầng 3.

---

## 🔬 NHIỆM VỤ 2 (PHASE 6): BẢNG ĐO THÔNG SỐ `StrictQAHUD`, THANH MÁU 2D & KIỂM ĐỊNH 5 ẢNH GPU RTX 4060

### 2.1. Tạo `src_game/scripts/ui/strict_qa_hud.gd` (Giao diện Thanh máu + Telemetry Kiểm định):
- Gắn 1 `CanvasLayer` (`StrictQAHUD`) vào `kaykit_multitier_arena.tscn`.
- **LƯU Ý QUAN TRỌNG:** Đặt `mouse_filter = Control.MOUSE_FILTER_IGNORE` cho **100% các node Control/Label/Panel/ProgressBar** trên HUD để tuyệt đối không bao giờ chặn Chuột Trái (`LMB`) và Chuột Phải (`RMB`) của `HeroKnight3D`!
- **Các thông tin hiển thị trực quan trên `StrictQAHUD`:**
  1. **Góc Trái Trên — Trạng thái Chiến Đấu:**
     - Thanh máu `HeroKnight3D` (`HP: 100/100`), Tên Hoạt Ảnh hiện tại (`Current Anim`), Trạng thái Kỹ năng (`LMB: Combo 3 Nhịp | RMB: Khiên Phản Kích | Q: Xoay Kiếm 360 | E: Bom Khói 3D | Space: Lướt | C: Nhảy`).
     - Vẽ thanh máu 2D nhỏ gọn chiếu theo tọa độ màn hình (`cam.unproject_position(enemy.global_position + Vector3(0, 2.1, 0))`) cho từng `EnemyMinion3D` đang sống (nhờ vẽ trên `CanvasLayer` 2D nên đảm bảo **0% Hình Khối 3D** và cực kỳ sắc nét).
  2. **Góc Phải Trên — Bảng Kiểm Định Kỹ Thuật Thời Gian Thực (`STRICT QA TELEMETRY`):**
     - `FPS` & `Frame Time (ms)`.
     - **`[ZERO PRIMITIVE CHECK]`:** Quét Scene Tree mỗi $0.5\text{s}$ kiểm tra `MeshInstance3D` nào dùng `BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PrismMesh`, `TorusMesh`. Hiển thị xanh lá: **`PRIMITIVE MESHES: 0 (PASS 100%)`**.
     - **`[SKELETON MOTION CHECK]`:** Đếm số khớp xương trong `HeroKnight3D.skeleton` có góc xoay `get_bone_pose_rotation()` thay đổi khi chạy/đánh. Hiển thị: **`ACTIVE BONES: 41/41 (NO T-POSE/SLIDING)`**.
     - **`[MULTI-TIER COORDINATE CHECK]`:** Hiển thị tọa độ chân `Hero_Y`, độ cao sàn Raycast `Ground_Y` (sai số $\Delta Y \le 0.02\text{m}$), tọa độ mũi kiếm `BladeTipMarker` và số lượng Lính còn sống (`Enemies Alive: X/5`).

### 2.2. Cập nhật `PLAY_GAME_WIZAD.bat` ở thư mục gốc `E:\DoAnCaNhan\ThuVienGame\GameWizad\`:
- Đảm bảo file `PLAY_GAME_WIZAD.bat` trỏ thẳng vào cảnh chính `res://scenes/levels/kaykit_multitier_arena.tscn` ở độ phân giải cửa sổ `1600x900` để User nhấp đúp chuột là vào điều khiển ngay `HeroKnight3D` đánh 5 Lính `Barbarian` trên bản đồ 3 tầng.

### 2.3. Chạy Kiểm Thử Tự Động & Xuất 5 Bức Ảnh Thực Tế Trên GPU RTX 4060:
1. Viết script `src_game/tests/test_phase_4_6_full_combat.gd` chạy kiểm tra:
   - Xác nhận có mặt `HeroKnight3D` và 5 `EnemyMinion3D` trên 3 tầng bản đồ.
   - Giả lập `HeroKnight3D` chém `LMB`, tung chiêu `RMB`, `Q`, `E` vào `EnemyMinion3D` $\rightarrow$ Xác nhận máu lính giảm thực tế (`hp < max_hp`), phát hoạt ảnh `Hit_A` và nổ hạt VFX tại ngực.
   - Xác nhận `Primitive Mesh Count == 0`.
2. Chạy Godot ở chế độ cửa sổ Render thực tế trên GPU RTX 4060 (không `--headless`), tự động điều khiển nhân vật di chuyển và chiến đấu để chụp **5 bức ảnh `.png`** lưu vào `docs/QA_REPORTS/screenshots/`:
   - `phase6_1_multitier_arena_overview.png`: Toàn cảnh bản đồ KayKit 3 tầng độ cao, cầu thang, cây cối, cột đá, thùng gỗ và `StrictQAHUD`.
   - `phase6_2_knight_climbing_stairs.png`: `HeroKnight3D` đang bước chân chạy lên cầu thang nối Tầng 1 và Tầng 2.
   - `phase6_3_melee_slash_and_hit_vfx.png`: `HeroKnight3D` vung kiếm chém `EnemyMinion3D` với vệt kiếm khí hạt bám theo lưỡi kiếm và tia lửa nổ trước ngực lính.
   - `phase6_4_spin_attack_decal_q.png`: `HeroKnight3D` tung tuyệt chiêu `Q` xoay kiếm 360 độ với ấn chú `Decal` ôm khít mặt sàn/bậc thang.
   - `phase6_5_smokebomb_3d_throw_e.png`: `HeroKnight3D` ném `smokebomb.gltf` 3D nổ khói trên sàn đấu.
3. Xuất báo cáo hoàn tất cuối cùng `16_FINAL_COMPLETION_REPORT.md` xác nhận hoàn thành trọn vẹn cả 6 Phase!