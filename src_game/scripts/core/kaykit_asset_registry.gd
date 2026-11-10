class_name KayKitAssetRegistry
extends RefCounted

# ==============================================================================
# KAYKIT ASSET REGISTRY - TRÌNH ĐĂNG KÝ TÀI NGUYÊN KAYKIT DUY NHẤT
# TẤT CẢ FILE LÀ MÔ HÌNH .GLB / .GLTF NGUYÊN BẢN CỦA KAYKIT (0% PRIMITIVE MESH)
# ==============================================================================

# 1. Nhân vật Hero & Lính đối kháng
const HERO_KNIGHT := "res://assets/characters/Knight.glb"
const ENEMY_MINION := "res://assets/characters/Barbarian.glb"

# 2. Vũ khí của Hero & Lính
const WEAPON_SWORD := "res://assets/weapons/sword_1handed.gltf"
const WEAPON_SHIELD := "res://assets/weapons/shield_square_color.gltf"
const WEAPON_CROSSBOW := "res://assets/weapons/crossbow_1handed.gltf"
const WEAPON_ARROW := "res://assets/weapons/arrow.gltf"
const WEAPON_SMOKEBOMB := "res://assets/weapons/smokebomb.gltf"
const WEAPON_AXE := "res://assets/weapons/axe_1handed.gltf"

# 3. Địa hình & Cầu thang Đa Tầng (KayKit Dungeon Remastered)
const TILE_FLOOR := "res://assets/environment/dungeon/floor_tile_large.gltf.glb"
const STAIRS_WIDE := "res://assets/environment/dungeon/stairs_wide.gltf.glb"
const STAIRS_NORMAL := "res://assets/environment/dungeon/stairs.gltf.glb"
const WALL_ELEVATION := "res://assets/environment/dungeon/wall.gltf.glb"

# 4. Vật cản & Trang trí
const PROP_PILLAR := "res://assets/environment/dungeon/pillar.gltf.glb"
const PROP_BARREL := "res://assets/environment/dungeon/barrel_large.gltf.glb"
const PROP_TORCH := "res://assets/environment/dungeon/torch_lit.gltf.glb"
const PROP_CHEST := "res://assets/environment/dungeon/chest.glb"
const PROP_TREE_A := "res://assets/environment/nature/tree_single_A.gltf"
const PROP_TREE_B := "res://assets/environment/nature/tree_single_B.gltf"
const PROP_ROCK_A := "res://assets/environment/nature/rock_single_A.gltf"
const PROP_ROCK_B := "res://assets/environment/nature/rock_single_B.gltf"

static func get_all_assets() -> Dictionary:
	return {
		"HERO_KNIGHT": HERO_KNIGHT,
		"ENEMY_MINION": ENEMY_MINION,
		"WEAPON_SWORD": WEAPON_SWORD,
		"WEAPON_SHIELD": WEAPON_SHIELD,
		"WEAPON_CROSSBOW": WEAPON_CROSSBOW,
		"WEAPON_ARROW": WEAPON_ARROW,
		"WEAPON_SMOKEBOMB": WEAPON_SMOKEBOMB,
		"WEAPON_AXE": WEAPON_AXE,
		"TILE_FLOOR": TILE_FLOOR,
		"STAIRS_WIDE": STAIRS_WIDE,
		"STAIRS_NORMAL": STAIRS_NORMAL,
		"WALL_ELEVATION": WALL_ELEVATION,
		"PROP_PILLAR": PROP_PILLAR,
		"PROP_BARREL": PROP_BARREL,
		"PROP_TORCH": PROP_TORCH,
		"PROP_CHEST": PROP_CHEST,
		"PROP_TREE_A": PROP_TREE_A,
		"PROP_TREE_B": PROP_TREE_B,
		"PROP_ROCK_A": PROP_ROCK_A,
		"PROP_ROCK_B": PROP_ROCK_B,
	}

static func verify_all_exist() -> bool:
	var all_ok := true
	var assets := get_all_assets()
	for key in assets:
		var path: String = assets[key]
		if not ResourceLoader.exists(path):
			push_error("[KayKitAssetRegistry] Missing asset: %s at %s" % [key, path])
			all_ok = false
	return all_ok
