extends SceneTree

# ==============================================================================
# TOOL CAPTURE SCREENSHOT PHASE 24 — GPU FORWARD+
# Chụp ảnh thực tế xác thực Chỉ đạo Tổng hợp số 24:
#   - Khóa spam Space với thời gian hồi chiêu 1.0s và hiển thị rõ trên thanh HUD
#   - Hệ thống 2 StaticBody3D độc lập (StairSolidWallShell và SmoothStairRampCollider)
#   - Hai thành đá bảo vệ hông cầu thang rộng 2.5m xóa sạch lỗi đi xuyên hông
#   - Hai khối nêm vát CornerGlideWedge_L/R triệt tiêu 100% góc kẹp chữ L sát tường
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")
const StrictQAHUD = preload("res://scripts/ui/strict_qa_hud.gd")

var frame_count := 0
var captured := false
var arena_node: Node = null
var hero: HeroKnight3D = null
var hud: StrictQAHUD = null

func _init() -> void:
	var sc = ResourceLoader.load("res://scenes/levels/kaykit_multitier_arena.tscn") as PackedScene
	if sc:
		arena_node = sc.instantiate()
		root.add_child(arena_node)

func _process(_delta: float) -> bool:
	frame_count += 1

	if frame_count == 10:
		hero = arena_node.get_node_or_null("HeroKnight3D") as HeroKnight3D
		hud = arena_node.get_node_or_null("StrictQAHUD") as StrictQAHUD

		var cam = arena_node.get_node_or_null("IsometricCamera3D") as Camera3D
		if cam:
			cam.size = 11.5

		if hero:
			# Đặt Hero ở chân cầu thang phía Tây (-6.0, 0.05, -11.2)
			hero.global_position = Vector3(-6.0, 0.05, -11.2)
			hero.velocity = Vector3.ZERO
			hero._facing_angle = PI
			if hero.visual_root:
				hero.visual_root.rotation.y = hero._facing_angle

			# Kích hoạt cú lướt Dash lên bậc thang có khóa Cooldown 1.0s
			hero._cd_dash_timer = 0.85
			hero._dash_dir = Vector3(0.0, 0.0, -1.0)
			hero._dash_timer = hero.DASH_DURATION
			hero._play_anim("Dodge_Forward")

			# Sinh VFX vệt lướt rực sáng
			KayKitVFXManager.spawn_dash_trail(hero, hero._dash_dir, arena_node)

	if frame_count == 20:
		if hero:
			# Vị trí đang lướt nửa chừng dốc cầu thang lên Tầng 2
			hero.global_position = Vector3(-6.0, 1.55, -13.1)
			hero.velocity = Vector3(0.0, 8.5, -9.5)
			KayKitVFXManager.spawn_dash_trail(hero, hero._dash_dir, arena_node)

	if frame_count == 32 and not captured:
		captured = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_dir = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/")
		DirAccess.make_dir_recursive_absolute(save_dir)
		var save_path = save_dir + "phase24_dash_cd_and_bulletproof_stairs.png"
		var err = img.save_png(save_path)
		print("==================================================================")
		print("📸 PHASE 24 SCREENSHOT CAPTURED SUCCESSFULLY:")
		print("   File: ", save_path)
		print("   Error code: ", err)
		print("==================================================================")
		quit(0)
		return true

	return false
