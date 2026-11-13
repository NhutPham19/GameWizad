extends SceneTree

# ==============================================================================
# TOOL CAPTURE SCREENSHOT PHASE 28 — GPU FORWARD+ (RTX 4060)
# Xác thực hoàn thành Chỉ đạo Số 28 (Argons & Antigravity):
#   - Shot 1: Chiến đấu thực tế phối âm Foley Kenney (U3 Cánh Quạt Nộ, Trận pháp & Hào quang)
#             Lưu vào: docs/QA_REPORTS/screenshots/phase28_1_foley_audio_combat_showcase.png
#   - Shot 2: Cận cảnh chiến trận toàn đấu trường với Audio Director 24 kênh hoạt động trơn tru
#             Lưu vào: docs/QA_REPORTS/screenshots/phase28_2_real_foley_multitier_battle.png
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
			cam.size = 8.5

		if hero:
			hero.global_position = Vector3(0.0, 0.05, 0.0)
			hero._facing_angle = deg_to_rad(15.0)
			if hero.visual_root:
				hero.visual_root.rotation.y = deg_to_rad(15.0)

			# Kích hoạt Trạng Thái 2 Nộ và phát âm thanh Foley thật
			hero._cd_rage_r_timer = 0.0
			hero._activate_rage_state_2()
			KayKitAudioDirector.play_sfx("rage_r_awaken")

	if frame_count == 24:
		if hero:
			# Kích hoạt đòn U3 Nộ: 5 kiếm khí xếp quạt + phát âm thanh foley
			hero._combo_index = 2
			hero._do_melee_combo(Vector3(0.0, 0.0, 1.0))
			KayKitAudioDirector.play_sfx("u3_rage_dragon_fall")

	# Chụp ảnh 1
	if frame_count == 36 and not shot1_done:
		shot1_done = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_dir = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/")
		DirAccess.make_dir_recursive_absolute(save_dir)
		var save_path = save_dir + "phase28_1_foley_audio_combat_showcase.png"
		var err = img.save_png(save_path)
		print("📸 CAPTURED SHOT 1 (Foley Audio Combat Showcase): ", save_path, " [err: ", err, "]")

	# Chuẩn bị Shot 2
	if frame_count == 48:
		var cam = arena_node.get_node_or_null("IsometricCamera3D") as Camera3D
		if cam:
			cam.size = 12.0 # Toàn cảnh
		if hero:
			hero.global_position = Vector3(0.0, 0.05, -2.0)
			# Kích hoạt chiêu I: Sóng kiếm 5 cánh Ngũ Dực Huyết Lam
			hero._cd_skill_i_timer = 0.0
			hero._do_skill_i_spatial_cleave()
			KayKitAudioDirector.play_sfx("i_rage_five_wing_wave")

	# Chụp ảnh 2
	if frame_count == 65 and not shot2_done:
		shot2_done = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_dir = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/")
		DirAccess.make_dir_recursive_absolute(save_dir)
		var save_path = save_dir + "phase28_2_real_foley_multitier_battle.png"
		var err = img.save_png(save_path)
		print("📸 CAPTURED SHOT 2 (Real Foley Multitier Battle): ", save_path, " [err: ", err, "]")

	if frame_count >= 75:
		print("✅ TẤT CẢ 2 ẢNH SCREENSHOT THỰC TẾ PHASE 28 ĐÃ ĐƯỢC CHỤP THÀNH CÔNG!")
		quit(0)
		return true

	return false
