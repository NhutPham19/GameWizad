extends SceneTree

# ==============================================================================
# TOOL CAPTURE SCREENSHOT PHASE 26 — GPU FORWARD+ (RTX 4060)
# Chụp ảnh thực tế xác thực Chỉ đạo Tổng hợp số 26 (Argons & Antigravity):
#   - Shot 1: Trạng Thái 2 [R] Huyết Lam Nộ + Đòn U3 (5 Đại Kiếm Khí Xếp Quạt & 4 Cột Lốc Xoáy)
#   - Shot 2: Trạng Thái 2 [R] Chiêu [I] (6 Kiếm Khí Chữ X Đa Tầng & Đại Sóng Kiếm Ngũ Dực 5 Cánh)
#   - Tuyệt đối 0% PrimitiveMesh (100% ArrayMesh & GLB sau kiểm định)
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")

var frame_count := 0
var arena_node: Node = null
var hero: HeroKnight3D = null
var shot1_done := false
var shot2_done := false

func _init() -> void:
	var sc = ResourceLoader.load("res://scenes/levels/kaykit_multitier_arena.tscn") as PackedScene
	if sc:
		arena_node = sc.instantiate()
		root.add_child(arena_node)

func _process(_delta: float) -> bool:
	frame_count += 1

	if frame_count == 10:
		hero = arena_node.get_node_or_null("HeroKnight3D") as HeroKnight3D
		var cam = arena_node.get_node_or_null("IsometricCamera3D") as Camera3D
		if cam:
			cam.size = 11.0

		if hero:
			# Đặt Hero ở trung tâm đấu trường Tầng 1
			hero.global_position = Vector3(0.0, 0.05, 0.0)
			hero._facing_angle = 0.0
			if hero.visual_root:
				hero.visual_root.rotation.y = 0.0

			# Kích hoạt Trạng Thái 2: Huyết Lam Cuồng Nộ [R]
			hero._cd_rage_r_timer = 0.0
			hero._activate_rage_state_2()

			# Kích hoạt siêu đòn U3 Nộ: 5 Đại Kiếm Khí Xếp Quạt Đỏ - Xanh
			hero._combo_index = 2
			hero._do_melee_combo(Vector3(0.0, 0.0, 1.0))

	# Chụp ảnh 1: Đỉnh cao bộc phá của U3 Nộ (sau 8 frames khi 5 kiếm khí, 3 vòng xoáy và 4 cột lụa bung tỏa)
	if frame_count == 18 and not shot1_done:
		shot1_done = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_dir = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/")
		DirAccess.make_dir_recursive_absolute(save_dir)
		var save_path = save_dir + "phase26_1_rage_mode_u3_five_blades.png"
		var err = img.save_png(save_path)
		print("📸 CAPTURED SHOT 1 (Trạng Thái 2 [R] + Đòn U3 Ngũ Đại Kiếm Khí Đỏ-Xanh): ", save_path, " [err: ", err, "]")

	# Bắt đầu chuẩn bị cho Chiêu [I] Trạng Thái 2
	if frame_count == 42:
		if hero:
			hero.global_position = Vector3(0.0, 0.05, -3.2)
			hero._cd_rmb_timer = 0.0
			hero._is_rage_state_2 = true

			# Kích hoạt Pha 1 chiêu [I]: 4 tàn ảnh .glb Đỏ-Xanh + 6 Kiếm Khí Chữ X Tách 3 Tầng
			hero._do_rmb_cross_cleave(Vector3(0.0, 0.0, 1.0))

	# Chụp ảnh 2: Chiêu [I] Nộ với 6 Kiếm Khí Chữ X & Đại Sóng Kiếm Ngũ Dực 5 Cánh cày đất
	if frame_count == 58 and not shot2_done:
		shot2_done = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_dir = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/")
		DirAccess.make_dir_recursive_absolute(save_dir)
		var save_path = save_dir + "phase26_2_rage_mode_i_hexa_x_and_five_winged_wave.png"
		var err = img.save_png(save_path)
		print("📸 CAPTURED SHOT 2 (Trạng Thái 2 [R] + Chiêu I Lục Kiếm Khí Chữ X & Sóng Ngũ Dực): ", save_path, " [err: ", err, "]")
		print("==================================================================")
		print("✅ ALL PHASE 26 SCREENSHOTS CAPTURED SUCCESSFULLY!")
		print("==================================================================")
		quit(0)
		return true

	return false
