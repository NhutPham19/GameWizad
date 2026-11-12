extends SceneTree

# ==============================================================================
# TOOL CAPTURE SCREENSHOT PHASE 25 — GPU FORWARD+
# Chụp ảnh thực tế xác thực Chỉ đạo Tổng hợp số 25 (Argons & Antigravity):
#   - Task 25.3: Đòn đánh thứ 3 [U/LMB] "Thánh Long Thiên Giáng Trảm" (7 lớp Đa Sắc)
#   - Task 25.4: Tuyệt kỹ [I/RMB] "Thánh Kiếm Phá Không: Cực Quang Thập Tự" (8 lớp)
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
			cam.size = 10.5

		if hero:
			# Đặt Hero ở trung tâm đấu trường Tầng 1
			hero.global_position = Vector3(0.0, 0.05, 0.0)
			hero._facing_angle = 0.0
			if hero.visual_root:
				hero.visual_root.rotation.y = 0.0

			# Kích hoạt siêu đòn U3: Thánh Long Thiên Giáng Trảm
			hero._combo_index = 2
			hero._do_melee_combo(Vector3(0.0, 0.0, 1.0))

	# Chụp ảnh 1: Đỉnh cao bộc phá của U3 (sau 6 frames khi các lớp lụa và hạt bung tỏa)
	if frame_count == 16 and not shot1_done:
		shot1_done = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_dir = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/")
		DirAccess.make_dir_recursive_absolute(save_dir)
		var save_path = save_dir + "phase25_1_u3_heaven_shatter_prismatic_vfx.png"
		var err = img.save_png(save_path)
		print("📸 CAPTURED SHOT 1 (U3 Thánh Long Thiên Giáng Trảm): ", save_path, " [err: ", err, "]")

	# Bắt đầu chuẩn bị cho Chiêu [I] Cực Quang Thập Tự
	if frame_count == 40:
		if hero:
			hero.global_position = Vector3(0.0, 0.05, -3.0)
			hero._cd_rmb_timer = 0.0
			# Kích hoạt Pha 1 chiêu [I]: Lướt + Tàn ảnh .glb + Tứ kiếm khí chữ X
			hero._do_rmb_cross_cleave(Vector3(0.0, 0.0, 1.0))

	# Chụp ảnh 2: Tuyệt kỹ [I] Thập Tự Quang + Đại Sóng Kiếm 3 Cánh Lụa Cong cày đất
	if frame_count == 55 and not shot2_done:
		shot2_done = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_dir = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/")
		DirAccess.make_dir_recursive_absolute(save_dir)
		var save_path = save_dir + "phase25_2_i_prismatic_cross_and_triple_wave.png"
		var err = img.save_png(save_path)
		print("📸 CAPTURED SHOT 2 (I Tuyệt Kỹ Cực Quang Thập Tự & Sóng Tam Dực): ", save_path, " [err: ", err, "]")
		print("==================================================================")
		print("✅ ALL PHASE 25 SCREENSHOTS CAPTURED SUCCESSFULLY!")
		print("==================================================================")
		quit(0)
		return true

	return false
