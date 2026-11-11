class_name KayKitArenaBuilder
extends Node3D

# ==============================================================================
# KAYKIT MULTI-TIER ARENA BUILDER - DIRECTIVE 16 (PHASE 4 & 6)
# 100% KAYKIT MODELS (.GLB/.GLTF) - ZERO PRIMITIVE GEOMETRY
# 3 Tier Elevations:
#   Tier 1: Y = 0.0m  (Central Valley Plaza 32m x 32m)
#   Tier 2: Y = 4.0m  (Northern Terrace 32m x 12m, with 2 Wide Stairs)
#   Tier 3: Y = 8.0m  (Ancient Citadel Summit 16m x 12m, with 1 Wide Stair)
# Colliders: SmoothStairRampCollider for seamless stair climbing,
#            Invisible boundary colliders & KayKit perimeter walls to prevent falls.
# ==============================================================================

const KayKitAssetRegistry = preload("res://scripts/core/kaykit_asset_registry.gd")
const EnemyMinion3D = preload("res://scripts/enemies/enemy_minion_3d.gd")

const TILE_SIZE := 4.0
const TIER_HEIGHT := 4.0

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $DirectionalLight3D
@onready var camera: IsometricCamera3D = $IsometricCamera3D

# Container nodes for clean hierarchy
var ground_container: Node3D = null
var walls_container: Node3D = null
var stairs_container: Node3D = null
var props_container: Node3D = null
var boundaries_container: Node3D = null
var _is_built: bool = false

func _ready() -> void:
	var screen_rate := DisplayServer.screen_get_refresh_rate()
	var target_hz := int(round(screen_rate)) if screen_rate > 60.0 else 165
	Engine.physics_ticks_per_second = clampi(target_hz, 120, 240)
	Engine.max_physics_steps_per_frame = 8
	build_arena()

func build_arena() -> void:
	if _is_built:
		return
	_is_built = true
	if not nav_region:
		nav_region = get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	if not nav_region:
		nav_region = NavigationRegion3D.new()
		nav_region.name = "NavigationRegion3D"
		add_child(nav_region)

	_setup_containers()
	_build_tier_1_plaza()
	_build_tier_2_terrace()
	_build_tier_3_citadel()
	_place_props_and_obstacles()
	_build_perimeter_walls_and_colliders()
	_setup_stair_links()
	_setup_lighting_and_environment()
	_setup_navigation()
	_spawn_enemies()

func _setup_containers() -> void:
	if ground_container != null and is_instance_valid(ground_container):
		return

	ground_container = Node3D.new()
	ground_container.name = "GroundTiles"
	nav_region.add_child(ground_container)

	walls_container = Node3D.new()
	walls_container.name = "ElevationWalls"
	nav_region.add_child(walls_container)

	stairs_container = Node3D.new()
	stairs_container.name = "Stairs"
	nav_region.add_child(stairs_container)

	props_container = Node3D.new()
	props_container.name = "Props"
	nav_region.add_child(props_container)

	boundaries_container = Node3D.new()
	boundaries_container.name = "Boundaries"
	nav_region.add_child(boundaries_container)

# ------------------------------------------------------------------------------
# TẦNG 1: QUẢNG TRƯỜNG THUNG LŨNG (Y = 0.0m, 32m x 32m, 8x8 TILE_FLOOR)
# ------------------------------------------------------------------------------
func _build_tier_1_plaza() -> void:
	for row in range(8):
		var z := -14.0 + (row * TILE_SIZE) # -14, -10, -6, -2, 2, 6, 10, 14 (Z in [-16, 16])
		for col in range(8):
			var x := -14.0 + (col * TILE_SIZE) # -14, -10, -6, -2, 2, 6, 10, 14 (X in [-16, 16])
			_spawn_trimesh_piece(KayKitAssetRegistry.TILE_FLOOR, Vector3(x, 0.0, z), Vector3.ZERO, ground_container)

# ------------------------------------------------------------------------------
# TẦNG 2: ĐÀI CAO PHÍA BẮC (Y = 4.0m, 32m x 12m, 8x3 TILE_FLOOR)
# Vách đá dọc Z = -16.0 chừa 2 Cầu Thang Rộng tại X = -6.0m và X = +6.0m (Mở thông 100%)
# ------------------------------------------------------------------------------
func _build_tier_2_terrace() -> void:
	# 1. Mặt sàn Tầng 2 (3 hàng Z: -18, -22, -26)
	for row in range(3):
		var z := -18.0 - (row * TILE_SIZE) # -18, -22, -26 (Z in [-28, -16])
		for col in range(8):
			var x := -14.0 + (col * TILE_SIZE) # X in [-16, 16]
			_spawn_trimesh_piece(KayKitAssetRegistry.TILE_FLOOR, Vector3(x, TIER_HEIGHT, z), Vector3.ZERO, ground_container)

	# 2. Hai cầu thang rộng nối Tầng 1 lên Tầng 2 (Visual only, flat ramp physics)
	var s1 := _spawn_visual_only_piece(KayKitAssetRegistry.STAIRS_WIDE, Vector3(-6.0, 0.0, -16.0), Vector3.ZERO, stairs_container)
	var s2 := _spawn_visual_only_piece(KayKitAssetRegistry.STAIRS_WIDE, Vector3(6.0, 0.0, -16.0), Vector3.ZERO, stairs_container)

	# Gắn Cầu thang kín 2-Body chống lọt gầm & thành bảo vệ hai bên (BulletproofStairAssembly, Task 24.2)
	create_bulletproof_stair_assembly(boundaries_container, s1, Vector3(-6.0, 0.0, -12.0), Vector3(-6.0, 4.0, -16.0))
	create_bulletproof_stair_assembly(boundaries_container, s2, Vector3(6.0, 0.0, -12.0), Vector3(6.0, 4.0, -16.0))

	# 3. Vách đá chắn sườn đồi dọc theo Z = -16.0:
	# TUYỆT ĐỐI CHỪA THÔNG ĐỘ RỘNG 4.0m quanh X = -6.0 và X = +6.0
	# Đặt tường tại các vị trí không chạm vào cầu thang (Task 23.3: xếp khít 100% không còn khe hở)
	var wall_x_cols = [-14.0, -10.0, -2.0, 2.0, 10.0, 14.0]
	for wx in wall_x_cols:
		_spawn_trimesh_piece(KayKitAssetRegistry.WALL_ELEVATION, Vector3(wx, 0.0, -16.0), Vector3.ZERO, walls_container)

	# 4. Vách đá hai bên sườn Tây (X = -16.0) và sườn Đông (X = +16.0) của Tầng 2
	for row in range(3):
		var wz := -18.0 - (row * TILE_SIZE)
		_spawn_trimesh_piece(KayKitAssetRegistry.WALL_ELEVATION, Vector3(-16.0, 0.0, wz), Vector3(0, 90, 0), walls_container)
		_spawn_trimesh_piece(KayKitAssetRegistry.WALL_ELEVATION, Vector3(16.0, 0.0, wz), Vector3(0, -90, 0), walls_container)

# ------------------------------------------------------------------------------
# TẦNG 3: ĐỈNH ĐÀI CỔ PHÍA BẮC (Y = 8.0m, 16m x 12m, 4x3 TILE_FLOOR)
# Vách đá dọc Z = -28.0 chừa 1 Cầu Thang Rộng ở chính giữa X = 0.0m (Mở thông 100%)
# ------------------------------------------------------------------------------
func _build_tier_3_citadel() -> void:
	# 1. Mặt sàn Tầng 3 (4 cột X in [-8, 8], 3 hàng Z in [-40, -28])
	for row in range(3):
		var z := -30.0 - (row * TILE_SIZE) # -30, -34, -38 (Z in [-40, -28])
		for col in range(4):
			var x := -6.0 + (col * TILE_SIZE) # -6, -2, 2, 6 (X in [-8, 8])
			_spawn_trimesh_piece(KayKitAssetRegistry.TILE_FLOOR, Vector3(x, TIER_HEIGHT * 2.0, z), Vector3.ZERO, ground_container)

	# 2. Cầu thang rộng ở giữa nối Tầng 2 lên Tầng 3 (Visual only, flat ramp physics)
	var s3 := _spawn_visual_only_piece(KayKitAssetRegistry.STAIRS_WIDE, Vector3(0.0, TIER_HEIGHT, -28.0), Vector3.ZERO, stairs_container)
	create_bulletproof_stair_assembly(boundaries_container, s3, Vector3(0.0, 4.0, -24.0), Vector3(0.0, 8.0, -28.0))

	# 3. Vách đá bao quanh chân Tầng 3 (độ cao Y = 4.0m)
	# Vách phía Nam (Z = -28.0, chừa cầu thang thông thoáng ở X = 0)
	_spawn_trimesh_piece(KayKitAssetRegistry.WALL_ELEVATION, Vector3(-6.0, TIER_HEIGHT, -28.0), Vector3.ZERO, walls_container)
	_spawn_trimesh_piece(KayKitAssetRegistry.WALL_ELEVATION, Vector3(6.0, TIER_HEIGHT, -28.0), Vector3.ZERO, walls_container)

	# Vách phía Tây (X = -8.0) và phía Đông (X = +8.0) của Tầng 3
	for row in range(3):
		var wz := -30.0 - (row * TILE_SIZE)
		_spawn_trimesh_piece(KayKitAssetRegistry.WALL_ELEVATION, Vector3(-8.0, TIER_HEIGHT, wz), Vector3(0, 90, 0), walls_container)
		_spawn_trimesh_piece(KayKitAssetRegistry.WALL_ELEVATION, Vector3(8.0, TIER_HEIGHT, wz), Vector3(0, -90, 0), walls_container)

	# Vách phía Bắc (Z = -40.0) của Tầng 3
	for col in range(4):
		var wx := -6.0 + (col * TILE_SIZE)
		_spawn_trimesh_piece(KayKitAssetRegistry.WALL_ELEVATION, Vector3(wx, TIER_HEIGHT, -40.0), Vector3(0, 180, 0), walls_container)

# ------------------------------------------------------------------------------
# HÀM TẠO CẦU THANG KÍN CHỐNG LỌT GẦM & THÀNH BẢO VỆ HAI BÊN (TASK 23.1 WORLD-ALIGNED)
# ------------------------------------------------------------------------------
## Đo chính xác AABB cục bộ chuyển sang tọa độ Arena của mô hình cầu thang (hoạt động chính xác 100% ngay cả trước khi node vào SceneTree)
static func _compute_exact_stair_bounds(stair_visual_node: Node3D, nominal_center_x: float, min_y: float, max_y: float, min_z: float, max_z: float) -> AABB:
	var fallback_aabb := AABB(
		Vector3(nominal_center_x - 2.35, min_y, min_z - 0.20),
		Vector3(4.70, max_y - min_y + 0.60, (max_z - min_z) + 0.40)
	)
	if stair_visual_node == null:
		return fallback_aabb

	var root_xf := Transform3D(Basis.from_euler(stair_visual_node.rotation), stair_visual_node.position).scaled_local(stair_visual_node.scale)
	var merged := AABB()
	var has_mesh := false

	for child in stair_visual_node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi and mi.mesh:
			var rel_xf := Transform3D.IDENTITY
			var cur: Node = mi
			while cur != null and cur != stair_visual_node:
				if cur is Node3D:
					rel_xf = (cur as Node3D).transform * rel_xf
				cur = cur.get_parent()
			var w_aabb: AABB = (root_xf * rel_xf) * mi.get_aabb()
			if not has_mesh:
				merged = w_aabb
				has_mesh = true
			else:
				merged = merged.merge(w_aabb)

	if not has_mesh:
		return fallback_aabb
	return merged.merge(fallback_aabb)


static func create_bulletproof_stair_assembly(
	parent: Node3D,
	stair_visual_node: Node3D,
	bottom_center: Vector3,
	top_center: Vector3
) -> StaticBody3D:
	var min_y := minf(bottom_center.y, top_center.y)
	var max_y := maxf(bottom_center.y, top_center.y)
	var rise_height := max_y - min_y
	var min_z := minf(bottom_center.z, top_center.z) # Đỉnh cầu thang (Z = -16.0 hoặc -28.0)
	var max_z := maxf(bottom_center.z, top_center.z) # Chân cầu thang (Z = -12.0 hoặc -24.0)
	var center_x := (bottom_center.x + top_center.x) * 0.5

	# Đo biên thực tế của mesh cầu thang + mở rộng thêm đệm an toàn
	var exact_bounds := _compute_exact_stair_bounds(stair_visual_node, center_x, min_y, max_y, min_z, max_z)
	var outer_min_x := minf(exact_bounds.position.x - 0.15, center_x - 2.45)
	var outer_max_x := maxf(exact_bounds.end.x + 0.15, center_x + 2.45)
	var outer_min_z := minf(exact_bounds.position.z - 0.40, min_z - 0.60)
	var outer_max_z := maxf(exact_bounds.end.z + 0.10, max_z + 0.25)

	# Lòng rãnh bước đi ở chính giữa cầu thang: rộng 2.30m (từ center_x - 1.15m đến center_x + 1.15m)
	var walk_half_w := 1.15

	# ==========================================================================
	# BODY 1: KHỐI TƯỜNG ĐẶC BẢO VỆ HÔNG, GẦM & GÓC GIAO CẦU THANG
	# (TUYỆT ĐỐI KHÔNG thuộc group "stairs" -> Đi chạm vào 2 bên sườn cầu thang
	#  hoạt động 100% giống chạm vào bức tường phẳng, 0% đi xuyên, 0% giật góc!)
	# ==========================================================================
	var shell_body := StaticBody3D.new()
	shell_body.name = "StairSolidWallShell"
	shell_body.collision_layer = 1
	shell_body.collision_mask = 0
	parent.add_child(shell_body)
	shell_body.global_position = Vector3.ZERO
	shell_body.rotation = Vector3.ZERO

	var wall_height := rise_height + 3.2
	var side_z_len := outer_max_z - outer_min_z
	var side_z_mid := (outer_min_z + outer_max_z) * 0.5

	# 1A. Thành Đá Chắn Hông Trái (-X) — Phủ kín từ lòng rãnh (center_x - 1.15) ra tận mép ngoài (outer_min_x)
	var left_inner_x := center_x - walk_half_w
	var left_w := maxf(1.25, left_inner_x - outer_min_x)
	var left_col := CollisionShape3D.new()
	left_col.name = "StairSideWall_Left"
	var left_box := BoxShape3D.new()
	left_box.size = Vector3(left_w, wall_height, side_z_len)
	left_col.shape = left_box
	left_col.position = Vector3((outer_min_x + left_inner_x) * 0.5, min_y + wall_height * 0.5, side_z_mid)
	shell_body.add_child(left_col)

	# 1B. Thành Đá Chắn Hông Phải (+X) — Phủ kín từ lòng rãnh (center_x + 1.15) ra tận mép ngoài (outer_max_x)
	var right_inner_x := center_x + walk_half_w
	var right_w := maxf(1.25, outer_max_x - right_inner_x)
	var right_col := CollisionShape3D.new()
	right_col.name = "StairSideWall_Right"
	var right_box := BoxShape3D.new()
	right_box.size = Vector3(right_w, wall_height, side_z_len)
	right_col.shape = right_box
	right_col.position = Vector3((right_inner_x + outer_max_x) * 0.5, min_y + wall_height * 0.5, side_z_mid)
	shell_body.add_child(right_col)

	# 1C. Khối Đặc Lấp Kín Toàn Bộ Gầm Cầu Thang (UnderStairSolidCore)
	var under_col := CollisionShape3D.new()
	under_col.name = "UnderStairSolidCore"
	var under_box := BoxShape3D.new()
	var under_depth := (max_z - min_z) * 0.75
	under_box.size = Vector3(outer_max_x - outer_min_x, rise_height, under_depth)
	under_col.shape = under_box
	under_col.position = Vector3(center_x, min_y + rise_height * 0.5, min_z + under_depth * 0.5 - 0.25)
	shell_body.add_child(under_col)

	# 1D. Hai Khối Nêm Vát Phẳng Góc Chữ L Nơi Sườn Cầu Thang Giao Với Bức Tường Đá (Corner Glide Wedges)
	# Xóa sổ hoàn toàn hốc vuông 90 độ sát tường để nhân vật chạy ép vào góc sẽ tự trượt êm ra ngoài!
	for side in [-1.0, 1.0]:
		var wedge_col := CollisionShape3D.new()
		wedge_col.name = "CornerGlideWedge_" + ("L" if side < 0.0 else "R")
		var wedge_box := BoxShape3D.new()
		wedge_box.size = Vector3(1.10, wall_height, 1.80)
		wedge_col.shape = wedge_box
		var edge_x: float = outer_min_x if side < 0.0 else outer_max_x
		wedge_col.position = Vector3(edge_x + float(side) * 0.12, min_y + wall_height * 0.5, min_z + 0.70)
		wedge_col.rotation.y = deg_to_rad(38.0 * float(side))
		shell_body.add_child(wedge_col)

	# ==========================================================================
	# BODY 2: MẶT DỐC BƯỚC ĐI NẰM LỌT THỎM GIỮA 2 THÀNH HÔNG
	# (Chỉ duy nhất Body này thuộc group "stairs"! Chiều rộng 2.24m và chiều dài Z
	#  nằm gọn 100% bên trong lòng 2 thành hông của Body 1, không có bất kỳ cạnh nghiêng nào thò ra ngoài!)
	# ==========================================================================
	var ramp_body := StaticBody3D.new()
	ramp_body.name = "SmoothStairRampCollider"
	ramp_body.collision_layer = 1
	ramp_body.collision_mask = 0
	ramp_body.add_to_group("stairs")
	parent.add_child(ramp_body)
	ramp_body.global_position = Vector3.ZERO
	ramp_body.rotation = Vector3.ZERO

	var walkable_width := (walk_half_w * 2.0) - 0.06 # Rộng 2.24m nằm lọt lòng giữa 2 thành hông 2.30m
	var smooth_bot := Vector3(center_x, min_y - 0.06, max_z + 0.18) # Ngắn hơn đầu thành hông (max_z + 0.25) nên 0% thò góc nghiêng!
	var smooth_top := Vector3(center_x, max_y - 0.02, min_z - 0.08)
	var slope_len := smooth_top.distance_to(smooth_bot)
	var slope_mid := (smooth_bot + smooth_top) * 0.5

	var ramp_col := CollisionShape3D.new()
	ramp_col.name = "WalkableRampSurface"
	var ramp_box := BoxShape3D.new()
	ramp_box.size = Vector3(walkable_width, 0.24, slope_len)
	ramp_col.shape = ramp_box
	ramp_body.add_child(ramp_col)
	ramp_col.global_position = slope_mid - Vector3(0.0, 0.12, 0.0)
	ramp_col.look_at_from_position(ramp_col.global_position, smooth_top - Vector3(0.0, 0.12, 0.0), Vector3.UP)

	return ramp_body


static func create_leakproof_stair_assembly(parent: Node3D, bottom_center: Vector3, top_center: Vector3, _ramp_width: float = 4.0) -> StaticBody3D:
	return create_bulletproof_stair_assembly(parent, null, bottom_center, top_center)

static func build_watertight_stair_assembly(parent: Node3D, bottom_center: Vector3, top_center: Vector3, _ramp_width: float = 4.0) -> StaticBody3D:
	return create_bulletproof_stair_assembly(parent, null, bottom_center, top_center)

static func create_smooth_stair_ramp(parent: Node3D, bottom_center: Vector3, top_center: Vector3, _ramp_width: float = 4.0) -> StaticBody3D:
	return create_bulletproof_stair_assembly(parent, null, bottom_center, top_center)

# ------------------------------------------------------------------------------
# BỌC KÍN RÌA BẢN ĐỒ BẰNG TƯỜNG THÀNH KAYKIT & KHUNG VA CHẠM BIÊN VÔ HÌNH
# ------------------------------------------------------------------------------
func _build_perimeter_walls_and_colliders() -> void:
	# 1. Tường & Cột đá KayKit hiển thị quanh rìa phía Nam của Tầng 1 (Z = 16.0)
	for col in range(8):
		var wx := -14.0 + (col * TILE_SIZE)
		_spawn_trimesh_piece(KayKitAssetRegistry.WALL_ELEVATION, Vector3(wx, 0.0, 16.0), Vector3(0, 180, 0), walls_container)
	# Cột đá tại các góc Tầng 1
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-16.0, 0.0, 16.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(16.0, 0.0, 16.0), Vector3.ZERO, props_container)

	# 2. Tường rìa phía Tây (X = -16.0) và phía Đông (X = 16.0) của Tầng 1
	for row in range(8):
		var wz := -14.0 + (row * TILE_SIZE)
		_spawn_trimesh_piece(KayKitAssetRegistry.WALL_ELEVATION, Vector3(-16.0, 0.0, wz), Vector3(0, 90, 0), walls_container)
		_spawn_trimesh_piece(KayKitAssetRegistry.WALL_ELEVATION, Vector3(16.0, 0.0, wz), Vector3(0, -90, 0), walls_container)

	# 3. Tường thành vai bắc Tầng 2 (Z = -28.0) ở hai bên ngoài Tầng 3
	var t2_north_x = [-14.0, -10.0, 10.0, 14.0]
	for nx in t2_north_x:
		_spawn_trimesh_piece(KayKitAssetRegistry.WALL_ELEVATION, Vector3(nx, TIER_HEIGHT, -28.0), Vector3(0, 180, 0), walls_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-16.0, TIER_HEIGHT, -28.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(16.0, TIER_HEIGHT, -28.0), Vector3.ZERO, props_container)

	# 4. KHUNG VA CHẠM VẬT LÝ VÔ HÌNH CHẶN BIÊN TUYỆT ĐỐI (INVISIBLE BOUNDARY COLLIDERS)
	# Chu vi Tầng 1
	_create_boundary_box(boundaries_container, "Boundary_South_T1", Vector3(0.0, 8.0, 16.8), Vector3(38.0, 20.0, 2.0))
	_create_boundary_box(boundaries_container, "Boundary_West_T1", Vector3(-16.8, 8.0, 0.0), Vector3(2.0, 20.0, 36.0))
	_create_boundary_box(boundaries_container, "Boundary_East_T1", Vector3(16.8, 8.0, 0.0), Vector3(2.0, 20.0, 36.0))

	# Chu vi Tầng 2
	_create_boundary_box(boundaries_container, "Boundary_West_T2", Vector3(-16.8, 10.0, -22.0), Vector3(2.0, 20.0, 16.0))
	_create_boundary_box(boundaries_container, "Boundary_East_T2", Vector3(16.8, 10.0, -22.0), Vector3(2.0, 20.0, 16.0))
	_create_boundary_box(boundaries_container, "Boundary_North_Shoulder_W", Vector3(-12.5, 10.0, -28.8), Vector3(9.0, 20.0, 2.0))
	_create_boundary_box(boundaries_container, "Boundary_North_Shoulder_E", Vector3(12.5, 10.0, -28.8), Vector3(9.0, 20.0, 2.0))

	# Chu vi Tầng 3
	_create_boundary_box(boundaries_container, "Boundary_West_T3", Vector3(-8.8, 14.0, -34.0), Vector3(2.0, 20.0, 16.0))
	_create_boundary_box(boundaries_container, "Boundary_East_T3", Vector3(8.8, 14.0, -34.0), Vector3(2.0, 20.0, 16.0))
	_create_boundary_box(boundaries_container, "Boundary_North_T3", Vector3(0.0, 14.0, -40.8), Vector3(20.0, 20.0, 2.0))

	# 5. Khung va chạm bảo vệ mép vực giữa các tầng (Chỉ chừa trống lối vào cầu thang)
	# Mép vực Tầng 2 -> Tầng 1 (Z = -16.0, Y = 4.0): chừa khe X = ±6.0
	_create_boundary_box(boundaries_container, "Ledge_Guard_T2_West", Vector3(-12.5, 5.0, -16.0), Vector3(7.0, 4.0, 0.8))
	_create_boundary_box(boundaries_container, "Ledge_Guard_T2_Center", Vector3(0.0, 5.0, -16.0), Vector3(6.5, 4.0, 0.8))
	_create_boundary_box(boundaries_container, "Ledge_Guard_T2_East", Vector3(12.5, 5.0, -16.0), Vector3(7.0, 4.0, 0.8))

	# Mép vực Tầng 3 -> Tầng 2 (Z = -28.0, Y = 8.0): chừa khe X = 0.0
	_create_boundary_box(boundaries_container, "Ledge_Guard_T3_West", Vector3(-5.5, 9.0, -28.0), Vector3(5.0, 4.0, 0.8))
	_create_boundary_box(boundaries_container, "Ledge_Guard_T3_East", Vector3(5.5, 9.0, -28.0), Vector3(5.0, 4.0, 0.8))

	# 6. KHỐI ĐẶC 100% LÕI TẦNG 2 VÀ TẦNG 3 (SOLID TIER VOLUMES - CHẶN HOÀN TOÀN XUYÊN NGANG)
	_build_solid_tier_cores()

func _build_solid_tier_cores() -> void:
	# Lõi đặc 100% bên dưới sàn Tầng 2: Y từ 0.0 -> 4.0m (Cao 4m, tâm Y = 2.0m)
	# Mở rộng mặt trước vươn ra tới Z = -15.3 (Task 23.3)
	_create_boundary_box(boundaries_container, "Solid_Core_Tier2", Vector3(0.0, 2.0, -21.8), Vector3(33.2, 4.0, 13.0))

	# Lõi đặc 100% bên dưới sàn Tầng 3: Y từ 0.0 -> 8.0m (Cao 8m, tâm Y = 4.0m)
	# Mở rộng mặt trước vươn ra tới Z = -27.3 (Task 23.3)
	_create_boundary_box(boundaries_container, "Solid_Core_Tier3", Vector3(0.0, 4.0, -33.8), Vector3(17.2, 8.0, 13.0))

static func _create_boundary_box(parent: Node3D, b_name: String, pos: Vector3, size: Vector3) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = b_name
	sb.collision_layer = 1
	sb.collision_mask = 0
	parent.add_child(sb)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	col.shape = box
	sb.add_child(col)
	sb.position = pos
	return sb

# ------------------------------------------------------------------------------
# LƯU DANH SÁCH TỌA ĐỘ CẦU THANG CHO AI BOT QUÁI
# ------------------------------------------------------------------------------
func _setup_stair_links() -> void:
	var links = [
		{"bottom": Vector3(-6.0, 0.0, -12.0), "top": Vector3(-6.0, 4.0, -16.0), "tier_bottom": 1, "tier_top": 2},
		{"bottom": Vector3(6.0, 0.0, -12.0), "top": Vector3(6.0, 4.0, -16.0), "tier_bottom": 1, "tier_top": 2},
		{"bottom": Vector3(0.0, 4.0, -24.0), "top": Vector3(0.0, 8.0, -28.0), "tier_bottom": 2, "tier_top": 3}
	]
	set_meta("stair_links", links)

# ------------------------------------------------------------------------------
# BỐ TRÍ VẬT CẢN & TRANG TRÍ KAYKIT (0% PRIMITIVE MESH)
# ------------------------------------------------------------------------------
func _place_props_and_obstacles() -> void:
	# Cột trang trọng bên ngoài hành lang cầu thang Tầng 1 (X = ±12.0, xóa bỏ các cột cũ sát thang - Task 23.1)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-12.0, 0.0, -12.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(12.0, 0.0, -12.0), Vector3.ZERO, props_container)

	# Cột trên đỉnh cầu thang Tầng 2 (X = ±12.0, thông thoáng lối đi - Task 23.1)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-12.0, TIER_HEIGHT, -17.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(12.0, TIER_HEIGHT, -17.0), Vector3.ZERO, props_container)

	# Cột hai bên cầu thang Tầng 3 (Dời ra X = ±6.0 để xóa kẹp hông - Task 23.1)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-6.0, TIER_HEIGHT, -24.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(6.0, TIER_HEIGHT, -24.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-6.0, TIER_HEIGHT * 2.0, -28.5), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(6.0, TIER_HEIGHT * 2.0, -28.5), Vector3.ZERO, props_container)

	# Đuốc lửa (Torches with warm OmniLight3D)
	_spawn_torch_with_light(Vector3(-10.5, 0.0, -12.0), props_container)
	_spawn_torch_with_light(Vector3(10.5, 0.0, -12.0), props_container)
	_spawn_torch_with_light(Vector3(-4.5, TIER_HEIGHT, -24.0), props_container)
	_spawn_torch_with_light(Vector3(4.5, TIER_HEIGHT, -24.0), props_container)
	_spawn_torch_with_light(Vector3(-4.5, TIER_HEIGHT * 2.0, -38.0), props_container)
	_spawn_torch_with_light(Vector3(4.5, TIER_HEIGHT * 2.0, -38.0), props_container)

	# Rương báu cổ tại đỉnh Tầng 3
	_spawn_convex_piece(KayKitAssetRegistry.PROP_CHEST, Vector3(0.0, TIER_HEIGHT * 2.0, -36.0), Vector3(0, 180, 0), props_container)

	# Thùng gỗ (Barrels)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_BARREL, Vector3(-13.5, 0.0, 13.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_BARREL, Vector3(-12.2, 0.0, 13.8), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_BARREL, Vector3(13.2, 0.0, 13.2), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_BARREL, Vector3(14.0, 0.0, 12.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_BARREL, Vector3(-13.5, TIER_HEIGHT, -22.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_BARREL, Vector3(13.5, TIER_HEIGHT, -22.0), Vector3.ZERO, props_container)

	# Cây cối
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_A, Vector3(-14.5, 0.0, 6.0), Vector3(0, 25, 0), props_container, 2.5)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_B, Vector3(-14.8, 0.0, -4.0), Vector3(0, -40, 0), props_container, 2.8)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_A, Vector3(14.5, 0.0, 6.0), Vector3(0, 60, 0), props_container, 2.5)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_B, Vector3(14.8, 0.0, -4.0), Vector3(0, 15, 0), props_container, 2.8)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_A, Vector3(-10.0, 0.0, 14.5), Vector3(0, 80, 0), props_container, 2.6)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_B, Vector3(10.0, 0.0, 14.5), Vector3(0, -70, 0), props_container, 2.6)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_A, Vector3(-14.0, TIER_HEIGHT, -25.5), Vector3(0, 45, 0), props_container, 2.4)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_B, Vector3(14.0, TIER_HEIGHT, -25.5), Vector3(0, -30, 0), props_container, 2.4)

	# Tảng đá
	_spawn_convex_piece(KayKitAssetRegistry.PROP_ROCK_A, Vector3(-13.0, 0.0, 11.5), Vector3(0, 35, 0), props_container, 3.5)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_ROCK_B, Vector3(13.0, 0.0, 11.5), Vector3(0, -60, 0), props_container, 3.5)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_ROCK_A, Vector3(-13.0, TIER_HEIGHT, -18.5), Vector3(0, 120, 0), props_container, 3.0)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_ROCK_B, Vector3(13.0, TIER_HEIGHT, -18.5), Vector3(0, -45, 0), props_container, 3.0)

# ------------------------------------------------------------------------------
# HÀM BỌC KHUNG VA CHẠM DÀY CÓ ĐỆM (PADDED SOLID STATIC BODY)
# ------------------------------------------------------------------------------
static func attach_padded_obstacle_collider(prop_node: Node3D, extra_padding: float = 0.28, min_height: float = 3.5) -> void:
	var combined_aabb := AABB(Vector3(-0.6, 0.0, -0.6), Vector3(1.2, 2.5, 1.2))
	var first := true
	for child in prop_node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh != null:
			var local_aabb := mi.transform * mi.get_aabb()
			if first:
				combined_aabb = local_aabb
				first = false
			else:
				combined_aabb = combined_aabb.merge(local_aabb)

	var s := maxf(0.001, prop_node.scale.x)
	var pad := extra_padding / s
	var min_h := min_height / s

	var body := StaticBody3D.new()
	body.name = "PaddedSolidCollider"
	body.collision_layer = 1
	body.collision_mask = 0
	prop_node.add_child(body)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(
		combined_aabb.size.x + pad * 2.0,
		maxf(combined_aabb.size.y, min_h),
		combined_aabb.size.z + pad * 2.0
	)
	col.shape = box
	col.position = Vector3(
		combined_aabb.get_center().x,
		box.size.y * 0.5,
		combined_aabb.get_center().z
	)
	body.add_child(col)

# ------------------------------------------------------------------------------
# HÀM TẠO VA CHẠM VẬT LÝ TRIMESH CHO SÀN, VÁCH TẦNG (LAYER 1)
# ------------------------------------------------------------------------------
func _spawn_trimesh_piece(path: String, pos: Vector3, rot_deg: Vector3, parent: Node) -> Node3D:
	var sc: PackedScene = ResourceLoader.load(path) as PackedScene
	if sc == null:
		push_error("Failed to load trimesh piece: " + path)
		return null

	var inst: Node3D = sc.instantiate() as Node3D
	inst.position = pos
	inst.rotation_degrees = rot_deg
	parent.add_child(inst)

	var mesh_nodes := inst.find_children("*", "MeshInstance3D", true, false)
	for mn in mesh_nodes:
		var mi := mn as MeshInstance3D
		if mi and mi.mesh:
			mi.create_trimesh_collision()
			for c in mi.get_children():
				if c is StaticBody3D:
					var sb := c as StaticBody3D
					sb.collision_layer = 1
					sb.collision_mask = 0

	# Task 23.3: Bọc Khối Hộp Va Chạm Đặc Dày (ThickWallCollider) dày 1.36m cho MỌI Bức Tường
	if path == KayKitAssetRegistry.WALL_ELEVATION:
		var wall_sb := StaticBody3D.new()
		wall_sb.name = "ThickWallCollider"
		wall_sb.collision_layer = 1
		wall_sb.collision_mask = 0
		inst.add_child(wall_sb)
		var wall_col := CollisionShape3D.new()
		var wall_box := BoxShape3D.new()
		# Rộng 4.2m (nối chồng khít các mảnh tường), Cao 5.5m, Dày 1.36m (đệm ra mỗi mặt tường +0.38m)
		wall_box.size = Vector3(4.20, 5.50, 1.36)
		wall_col.shape = wall_box
		wall_col.position = Vector3(0.0, 2.75, 0.0)
		wall_sb.add_child(wall_col)

	return inst

# ------------------------------------------------------------------------------
# HÀM SPAWN PIECE CHỈ DÀNH CHO HIỂN THỊ (KHÔNG TẠO VA CHẠM TRIMESH RĂNG CƯA)
# ------------------------------------------------------------------------------
func _spawn_visual_only_piece(path: String, pos: Vector3, rot_deg: Vector3, parent: Node) -> Node3D:
	var sc: PackedScene = ResourceLoader.load(path) as PackedScene
	if sc == null:
		push_error("Failed to load visual piece: " + path)
		return null

	var inst: Node3D = sc.instantiate() as Node3D
	inst.position = pos
	inst.rotation_degrees = rot_deg
	parent.add_child(inst)
	return inst

# ------------------------------------------------------------------------------
# HÀM TẠO VA CHẠM VẬT LÝ CONVEX CHO VẬT CẢN (LAYER 1)
# Bỏ qua 100% va chạm cho Đuốc và Đạo cụ nhỏ trang trí (Task 19.1)
# ------------------------------------------------------------------------------
func _spawn_convex_piece(path: String, pos: Vector3, rot_deg: Vector3, parent: Node, scale_factor: float = 1.0) -> Node3D:
	var path_lower := path.to_lower()
	for skip_token in ["torch", "light", "grass", "pebble", "banner", "flag"]:
		if path_lower.contains(skip_token):
			var visual_piece := _spawn_visual_only_piece(path, pos, rot_deg, parent)
			if visual_piece and scale_factor != 1.0:
				visual_piece.scale = Vector3.ONE * scale_factor
			return visual_piece

	var sc: PackedScene = ResourceLoader.load(path) as PackedScene
	if sc == null:
		push_error("Failed to load convex piece: " + path)
		return null

	var inst: Node3D = sc.instantiate() as Node3D
	inst.position = pos
	inst.rotation_degrees = rot_deg
	if scale_factor != 1.0:
		inst.scale = Vector3.ONE * scale_factor
	parent.add_child(inst)

	var mesh_nodes := inst.find_children("*", "MeshInstance3D", true, false)
	for mn in mesh_nodes:
		var mi := mn as MeshInstance3D
		if mi and mi.mesh:
			mi.create_convex_collision()
			for c in mi.get_children():
				if c is StaticBody3D:
					var sb := c as StaticBody3D
					sb.collision_layer = 1
					sb.collision_mask = 0

	# Task 23.1: Đổi đệm thừa 0.28m -> 0.04m để khung va chạm ôm sát thân cột thật, không tạo vật cản tàng hình
	attach_padded_obstacle_collider(inst, 0.04, 3.0)
	return inst

# ------------------------------------------------------------------------------
# ĐUỐC KÈM ÁNH SÁNG OMNILIGHT3D ẤM ÁP (HOÀN TOÀN VISUAL ONLY - 0% VA CHẠM)
# ------------------------------------------------------------------------------
func _spawn_torch_with_light(pos: Vector3, parent: Node) -> void:
	var torch_inst := _spawn_visual_only_piece(KayKitAssetRegistry.PROP_TORCH, pos, Vector3.ZERO, parent)
	if torch_inst:
		torch_inst.scale = Vector3.ONE * 1.8
		var light := OmniLight3D.new()
		light.name = "TorchLight"
		light.light_color = Color(1.0, 0.72, 0.35)
		light.light_energy = 2.4
		light.omni_range = 7.5
		light.omni_attenuation = 1.2
		light.shadow_enabled = true
		light.position = Vector3(0.0, 1.8, 0.0)
		torch_inst.add_child(light)

# ------------------------------------------------------------------------------
# THIẾT LẬP NAVIGATION MESH (KẾT NỐI LIỀN MẠCH 3 TẦNG & CẦU THANG)
# ------------------------------------------------------------------------------
func _setup_navigation() -> void:
	var nav_mesh := NavigationMesh.new()
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.25
	nav_mesh.agent_height = 1.6
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_max_climb = 0.5
	nav_mesh.agent_max_slope = 58.0
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = 1

	nav_region.navigation_mesh = nav_mesh
	nav_region.bake_navigation_mesh()

# ------------------------------------------------------------------------------
# THIẾT LẬP ÁNH SÁNG & MÔI TRƯỜNG CHUẨN ISOMETRIC CEL-SHADED
# ------------------------------------------------------------------------------
func _setup_lighting_and_environment() -> void:
	if sun_light:
		sun_light.rotation_degrees = Vector3(-55.0, 40.0, 0.0)
		sun_light.light_color = Color(1.0, 0.96, 0.88)
		sun_light.light_energy = 1.4
		sun_light.shadow_enabled = true
		sun_light.directional_shadow_max_distance = 120.0
		sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS

	if world_env and world_env.environment:
		var env := world_env.environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.12, 0.14, 0.18)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.45, 0.5, 0.58)
		env.ambient_light_energy = 0.85
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

# ------------------------------------------------------------------------------
# SINH 5 LÍNH ĐỐI KHÁNG ĐA TẦNG (PHASE 4 & 6)
# ------------------------------------------------------------------------------
func _spawn_enemies() -> void:
	var enemies_container := get_node_or_null("Enemies") as Node3D
	if enemies_container != null:
		return
	enemies_container = Node3D.new()
	enemies_container.name = "Enemies"
	add_child(enemies_container)

	# 2 Lính ở Tầng 1 (Y = 0.05m)
	_spawn_single_minion(Vector3(-6.0, 0.05, -4.0), 80.0, enemies_container)
	_spawn_single_minion(Vector3(6.0, 0.05, -4.0), 80.0, enemies_container)

	# 2 Lính ở Tầng 2 (Y = 4.05m)
	_spawn_single_minion(Vector3(-6.0, TIER_HEIGHT + 0.05, -20.0), 80.0, enemies_container)
	_spawn_single_minion(Vector3(6.0, TIER_HEIGHT + 0.05, -20.0), 80.0, enemies_container)

	# 1 Lính Thủ Lĩnh ở Tầng 3 (Y = 8.05m, 150 HP)
	_spawn_single_minion(Vector3(0.0, (TIER_HEIGHT * 2.0) + 0.05, -34.0), 150.0, enemies_container)

func _spawn_single_minion(pos: Vector3, health: float, parent: Node) -> EnemyMinion3D:
	var minion := EnemyMinion3D.new()
	minion.position = pos
	minion.max_hp = health
	minion.hp = health
	parent.add_child(minion)
	return minion
