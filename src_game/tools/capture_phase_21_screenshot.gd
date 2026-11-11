extends SceneTree

# ==============================================================================
# TOOL CAPTURE SCREENSHOT PHASE 21 — GPU RTX 4060 FORWARD+
# Chụp ảnh thực tế:
#   - Thánh Kiếm Phá Không Trảm (RMB Solar Cross-Cleave)
#   - Vùng DoT Lôi Vụ Tím (E Hazard Zone)
#   - Bot dính hiệu ứng Debuff tím & Thanh máu Crimson Red
#   - HUD Cooldown Bar ở góc dưới màn hình
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

func _process(_delta: float) -> bool:
	frame_count += 1

	if frame_count == 10:
		hero = arena_node.get_node_or_null("HeroKnight3D") as HeroKnight3D
		var enemies := get_nodes_in_group("enemies")
		if enemies.size() > 0:
			minion = enemies[0] as EnemyMinion3D

		var cam = arena_node.get_node_or_null("IsometricCamera3D") as Camera3D
		if cam:
			cam.size = 9.2 # Tầm nhìn chuẩn Isometric góc chiến đấu

		if hero and minion:
			hero.global_position = Vector3(0.0, 0.05, 0.0)
			hero.velocity = Vector3.ZERO
			hero._facing_angle = deg_to_rad(45.0)
			if hero.visual_root:
				hero.visual_root.rotation.y = hero._facing_angle

			minion.global_position = Vector3(2.2, 0.05, 2.2)
			minion.velocity = Vector3.ZERO
			if minion.visual_root:
				minion.visual_root.rotation.y = deg_to_rad(225.0)

			# Bot chịu DoT và làm chậm tím
			minion.take_dot_damage(16.0, Color(0.75, 0.35, 1.0))
			minion.apply_slow_debuff(0.45, 3.0)

			# Sinh Vùng khói Lôi Vụ tím (E Hazard Zone) xung quanh khu vực giao tranh
			KayKitVFXManager.spawn_smoke_bomb_hazard_zone(arena_node, hero.global_position, minion.global_position)

			# Kích hoạt RMB Solar Cross-Cleave rực lửa
			hero._cd_rmb_timer = 3.5
			hero._cd_q_timer = 2.4
			hero._cd_e_timer = 5.8
			hero._snap_to_aim_direction(Vector3(1.0, 0.0, 1.0).normalized(), 0.40)
			KayKitVFXManager.spawn_rmb_solar_cross_cleave(hero.global_position, hero._facing_angle, arena_node)

	if frame_count == 28 and not captured:
		captured = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_dir = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/")
		DirAccess.make_dir_recursive_absolute(save_dir)
		var save_path = save_dir + "phase21_combat_upgrades.png"
		var err = img.save_png(save_path)
		print("==================================================================")
		print("📸 PHASE 21 SCREENSHOT CAPTURED SUCCESSFULLY:")
		print("   File: ", save_path)
		print("   Error code: ", err)
		print("==================================================================")
		quit(0)
		return true

	return false
