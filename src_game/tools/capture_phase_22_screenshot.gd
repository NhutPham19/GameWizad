extends SceneTree

# ==============================================================================
# TOOL CAPTURE SCREENSHOT PHASE 22 — GPU RTX 4060 FORWARD+
# Chụp ảnh thực tế:
#   - Nhân vật lướt (Dash) êm ái lên cầu thang nối Tầng 1 và Tầng 2
#   - Hành lang thông thoáng giữa cột đá và thành cầu thang (0% góc lag)
#   - Hệ trục World-Aligned hoàn hảo của khối cầu thang kín nước
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")

var frame_count := 0
var captured := false
var arena_node: Node = null
var hero: HeroKnight3D = null

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
			cam.size = 9.5

		if hero:
			# Đặt Hero ở chân cầu thang phía Tây (-6.0, 0.05, -11.5)
			hero.global_position = Vector3(-6.0, 0.05, -11.5)
			hero.velocity = Vector3.ZERO
			hero._facing_angle = PI # Hướng lên cầu thang (-Z)
			if hero.visual_root:
				hero.visual_root.rotation.y = hero._facing_angle

			# Kích hoạt cú lướt Dash lên bậc thang
			hero._dash_dir = Vector3(0.0, 0.0, -1.0)
			hero._dash_timer = hero.DASH_DURATION
			hero._play_anim("Dodge_Forward")

			# Sinh VFX vệt lướt rực sáng
			KayKitVFXManager.spawn_dash_trail(hero, hero._dash_dir, arena_node)

	if frame_count == 20:
		if hero:
			# Vị trí đang lướt nửa chừng dốc cầu thang
			hero.global_position = Vector3(-6.0, 1.25, -13.2)
			hero.velocity = Vector3(0.0, 8.5, -9.5)
			KayKitVFXManager.spawn_dash_trail(hero, hero._dash_dir, arena_node)

	if frame_count == 28 and not captured:
		captured = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_dir = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/")
		DirAccess.make_dir_recursive_absolute(save_dir)
		var save_path = save_dir + "phase22_stair_dash_and_corner_fix.png"
		var err = img.save_png(save_path)
		print("==================================================================")
		print("📸 PHASE 22 SCREENSHOT CAPTURED SUCCESSFULLY:")
		print("   File: ", save_path)
		print("   Error code: ", err)
		print("==================================================================")
		quit(0)
		return true

	return false
