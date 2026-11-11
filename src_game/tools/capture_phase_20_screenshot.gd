extends SceneTree

# ==============================================================================
# TOOL CAPTURE SCREENSHOT PHASE 20 — GPU RTX 4060 FORWARD+
# Chụp ảnh thực tế dải kiếm khí lưỡi liềm 3 tầng màu + Bot thanh máu Đỏ Huyết
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")
const KayKitVFXManager = preload("res://scripts/vfx/kaykit_vfx_manager.gd")

var frame_count := 0
var captured := false
var arena_node: Node = null
var hero: HeroKnight3D = null
var minion: EnemyMinion3D = null

func _init() -> void:
	var sc = ResourceLoader.load("res://scenes/levels/kaykit_multitier_arena.tscn") as PackedScene
	if sc:
		arena_node = sc.instantiate()
		root.add_child(arena_node)

func _process(delta: float) -> bool:
	frame_count += 1

	if frame_count == 10:
		hero = arena_node.get_node_or_null("HeroKnight3D") as HeroKnight3D
		var enemies := get_nodes_in_group("enemies")
		if enemies.size() > 0:
			minion = enemies[0] as EnemyMinion3D

		var cam = arena_node.get_node_or_null("IsometricCamera3D") as Camera3D
		if cam:
			cam.size = 8.5 # Zoom cận cảnh hành động chiến đấu

		if hero and minion:
			# Đặt vị trí Hero và Minion đối diện nhau ở góc nhìn camera Isometric đẹp nhất
			hero.global_position = Vector3(0.0, 0.05, 0.0)
			hero.velocity = Vector3.ZERO
			if hero.visual_root:
				hero.visual_root.rotation.y = deg_to_rad(45.0) # Nhìn thẳng về phía Bot

			minion.global_position = Vector3(1.1, 0.05, 1.1)
			minion.velocity = Vector3.ZERO
			if minion.visual_root:
				minion.visual_root.rotation.y = deg_to_rad(225.0) # Nhìn lại Hero

			# Cho Bot nhận sát thương để lộ rõ cả vạch Đỏ Huyết (#E61E2A) và vạch Trắng Vàng Tụt Trễ
			minion.take_damage(28.0)

	if frame_count == 24:
		if hero:
			# Kích hoạt đòn chém LMB Nhịp 1 vung dải kiếm khí Lõi Trắng - Thân Cyan - Viền Cam
			hero._combo_index = 0
			hero._do_melee_combo()

	if frame_count == 29 and not captured:
		captured = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_dir = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/")
		DirAccess.make_dir_recursive_absolute(save_dir)
		var save_path = save_dir + "phase20_ultimate_slash_vfx.png"
		var err = img.save_png(save_path)
		print("==================================================================")
		print("📸 PHASE 20 SCREENSHOT CAPTURED SUCCESSFULLY:")
		print("   File: ", save_path)
		print("   Error code: ", err)
		print("==================================================================")
		quit(0)
		return true

	return false
