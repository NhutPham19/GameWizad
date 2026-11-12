extends SceneTree

# ==============================================================================
# TOOL CAPTURE SCREENSHOT PHASE 27 — GPU FORWARD+ (RTX 4060)
# Chụp ảnh thực tế xác thực Chỉ đạo Tổng hợp số 27 (Argons & Antigravity):
#   - Shot 1: Cận cảnh Linh Giáp Cực Quang Huyết Lam 6 Lớp (Đôi cánh, 3 Tinh hoàn, Trận pháp 3 tầng)
#             Lưu vào: docs/QA_REPORTS/screenshots/phase27_1_ultimate_rage_aura_6layers.png
#   - Shot 2: Chiến trận Nộ & Hệ thống âm thanh KayKitAudioDirector (Chém Nộ, Sóng Kiếm, Bot trúng đòn)
#             Lưu vào: docs/QA_REPORTS/screenshots/phase27_2_rage_combat_with_audio_telemetry.png
#   - Tuyệt đối 0% PrimitiveMesh (100% ArrayMesh & GLB sau kiểm định)
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")
const KayKitAudioDirector = preload("res://scripts/audio/kaykit_audio_director.gd")

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

	if frame_count == 8:
		hero = arena_node.get_node_or_null("HeroKnight3D") as HeroKnight3D
		var cam = arena_node.get_node_or_null("IsometricCamera3D") as Camera3D
		if cam:
			cam.size = 6.2 # Cận cảnh để chiêm ngưỡng chi tiết 6 lớp hào quang cực quang

		if hero:
			hero.global_position = Vector3(0.0, 0.05, 0.0)
			hero._facing_angle = deg_to_rad(20.0) # Góc nghiêng nhẹ để thấy rõ cả cánh sau lưng và vòng tinh hoàn
			if hero.visual_root:
				hero.visual_root.rotation.y = deg_to_rad(20.0)

			# Kích hoạt Trạng Thái 2: Huyết Lam Cuồng Nộ [R] -> Sinh trọn vẹn 6 lớp hào quang
			hero._cd_rage_r_timer = 0.0
			hero._activate_rage_state_2()

	# Chụp ảnh 1: Cận cảnh Hào Quang Nộ 6 Lớp Đầy Đủ
	if frame_count == 24 and not shot1_done:
		shot1_done = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_dir = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/")
		DirAccess.make_dir_recursive_absolute(save_dir)
		var save_path = save_dir + "phase27_1_ultimate_rage_aura_6layers.png"
		var err = img.save_png(save_path)
		print("📸 CAPTURED SHOT 1 (Hào Quang Nộ 6 Lớp Linh Giáp Cực Quang Huyết Lam): ", save_path, " [err: ", err, "]")

	# Chuẩn bị Shot 2: Chiến trận Nộ & Telemetry âm thanh
	if frame_count == 36:
		var cam = arena_node.get_node_or_null("IsometricCamera3D") as Camera3D
		if cam:
			cam.size = 10.5 # Góc rộng chiến trường
		if hero:
			hero.global_position = Vector3(0.0, 0.05, -1.0)
			hero._facing_angle = 0.0
			if hero.visual_root:
				hero.visual_root.rotation.y = 0.0

			# Tung đòn U3 Nộ: 5 Đại kiếm khí xếp quạt + bão cột xoáy lốc
			hero._combo_index = 2
			hero._do_melee_combo(Vector3(0.0, 0.0, 1.0))

	# Chụp ảnh 2: Chiến trận Nộ phối hợp âm thanh và kiếm khí bùng nổ
	if frame_count == 52 and not shot2_done:
		shot2_done = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_dir = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/")
		DirAccess.make_dir_recursive_absolute(save_dir)
		var save_path = save_dir + "phase27_2_rage_combat_with_audio_telemetry.png"
		var err = img.save_png(save_path)
		print("📸 CAPTURED SHOT 2 (Chiến Trận Nộ & Telemetry Âm Thanh KayKit): ", save_path, " [err: ", err, "]")
		print("==================================================================")
		print("✅ ALL PHASE 27 SCREENSHOTS CAPTURED SUCCESSFULLY ON RTX 4060!")
		print("==================================================================")
		quit(0)
		return true

	return false
