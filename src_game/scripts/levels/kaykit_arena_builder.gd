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
	if s1:
		s1.add_to_group("stairs")
	if s2:
		s2.add_to_group("stairs")

	# Gắn Cầu thang kín chống lọt gầm & thành bảo vệ hai bên (LeakproofStairAssembly) cho cả 2 cầu thang (rộng 4.6m)
	create_leakproof_stair_assembly(boundaries_container, Vector3(-6.0, 0.0, -12.0), Vector3(-6.0, 4.0, -16.0), 4.6)
	create_leakproof_stair_assembly(boundaries_container, Vector3(6.0, 0.0, -12.0), Vector3(6.0, 4.0, -16.0), 4.6)

	# 3. Vách đá chắn sườn đồi dọc theo Z = -16.0:
	# TUYỆT ĐỐI CHỪA THÔNG ĐỘ RỘNG 4.5m+ quanh X = -6.0 và X = +6.0
	# Đặt tường tại các vị trí không chạm vào cầu thang (-14.0, -10.5, 0.0, 10.5, 14.0)
	var wall_x_cols = [-14.0, -10.5, 0.0, 10.5, 14.0]
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
	if s3:
		s3.add_to_group("stairs")
	create_leakproof_stair_assembly(boundaries_container, Vector3(0.0, 4.0, -24.0), Vector3(0.0, 8.0, -28.0), 4.6)

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
# HÀM TẠO CẦU THANG KÍN CHỐNG LỌT GẦM & THÀNH BẢO VỆ HAI BÊN (WATERTIGHT STAIR ASSEMBLY - TASK 21.4)
# ------------------------------------------------------------------------------
static func create_leakproof_stair_assembly(parent: Node3D, bottom_center: Vector3, top_center: Vector3, ramp_width: float = 4.6) -> StaticBody3D:
	# 1. Node StaticBody3D gốc giữ nguyên hệ trục Thế giới (rotation = Vector3.ZERO)
	var stair_body := StaticBody3D.new()
	stair_body.name = "SmoothStairRampCollider"
	stair_body.collision_layer = 1
	stair_body.collision_mask = 0
	stair_body.add_to_group("stairs")
	parent.add_child(stair_body)
	stair_body.global_position = Vector3.ZERO

	# Mở rộng điểm bắt đầu chân dốc ra phía trước 0.45m và hạ nhẹ -0.08m để tiếp tuyến êm 100% với mặt sàn dưới (0mm gờ cản khi Dash lên!)
	var forward_flat_dir := Vector3(top_center.x - bottom_center.x, 0.0, top_center.z - bottom_center.z).normalized()
	var smooth_bottom := bottom_center - forward_flat_dir * 0.45 - Vector3(0.0, 0.08, 0.0)
	var smooth_top := top_center + forward_flat_dir * 0.15 - Vector3(0.0, 0.05, 0.0)

	var ramp_diff := smooth_top - smooth_bottom
	var ramp_len := ramp_diff.length()
	var ramp_mid := (smooth_bottom + smooth_top) * 0.5
	var rise_height := top_center.y - bottom_center.y
	var half_w := ramp_width * 0.5

	# 2. Mặt dốc phẳng nghiêng liên tục (chỉ xoay riêng CollisionShape3D của mặt dốc)
	var ramp_col := CollisionShape3D.new()
	ramp_col.name = "RampSurfaceShape"
	var ramp_box := BoxShape3D.new()
	ramp_box.size = Vector3(ramp_width, 0.20, ramp_len)
	ramp_col.shape = ramp_box
	stair_body.add_child(ramp_col)
	ramp_col.global_position = ramp_mid - Vector3(0.0, 0.10, 0.0)
	ramp_col.look_at_from_position(ramp_col.global_position, smooth_top - Vector3(0.0, 0.10, 0.0), Vector3.UP)

	# 3. Hai vách chắn hông cầu thang thẳng đứng chuẩn hệ trục Thế giới (World-Aligned, không nhô ra ngoài làm hẹp lối đi)
	var center_xz := (bottom_center + top_center) * 0.5
	var horiz_len := Vector2(top_center.x - bottom_center.x, top_center.z - bottom_center.z).length()
	for side in [-1.0, 1.0]:
		var side_col := CollisionShape3D.new()
		var side_box := BoxShape3D.new()
		side_box.size = Vector3(0.24, rise_height + 2.2, horiz_len + 0.2)
		side_col.shape = side_box
		side_col.position = Vector3(
			center_xz.x + side * (half_w + 0.12),
			bottom_center.y + (rise_height + 2.2) * 0.5,
			center_xz.z
		)
		stair_body.add_child(side_col)

	# 4. Khối đặc chặn gầm phía sau cầu thang (World-Aligned, nằm hoàn toàn ở nửa sau cầu thang, tuyệt đối không trồi lên ở chân thang)
	var under_col := CollisionShape3D.new()
	var under_box := BoxShape3D.new()
	under_box.size = Vector3(ramp_width + 0.4, rise_height * 0.55, horiz_len * 0.48)
	under_col.shape = under_box
	under_col.position = Vector3(
		top_center.x,
		bottom_center.y + (rise_height * 0.55) * 0.5,
		lerpf(bottom_center.z, top_center.z, 0.76)
	)
	stair_body.add_child(under_col)

	return stair_body

static func build_watertight_stair_assembly(parent: Node3D, bottom_center: Vector3, top_center: Vector3, ramp_width: float = 4.6) -> StaticBody3D:
	return create_leakproof_stair_assembly(parent, bottom_center, top_center, ramp_width)

static func create_smooth_stair_ramp(parent: Node3D, bottom_center: Vector3, top_center: Vector3, ramp_width: float = 4.6) -> StaticBody3D:
	return create_leakproof_stair_assembly(parent, bottom_center, top_center, ramp_width)

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
	# X từ -16.0 -> 16.0 (Rộng 32m), Z từ -16.2 -> -28.0 (Sâu 11.8m, tâm Z = -22.1m)
	_create_boundary_box(boundaries_container, "Solid_Core_Tier2", Vector3(0.0, 2.0, -22.1), Vector3(32.0, 4.0, 11.8))

	# Lõi đặc 100% bên dưới sàn Tầng 3: Y từ 0.0 -> 8.0m (Cao 8m, tâm Y = 4.0m)
	# X từ -8.0 -> 8.0 (Rộng 16m), Z từ -28.2 -> -40.0 (Sâu 11.8m, tâm Z = -34.1m)
	_create_boundary_box(boundaries_container, "Solid_Core_Tier3", Vector3(0.0, 4.0, -34.1), Vector3(16.0, 8.0, 11.8))

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
	# Cột trang trọng bên ngoài hành lang cầu thang Tầng 1 (đặt cách tâm cầu thang > 3.2m)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-9.5, 0.0, -12.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-2.5, 0.0, -12.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(2.5, 0.0, -12.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(9.5, 0.0, -12.0), Vector3.ZERO, props_container)

	# Cột trên đỉnh cầu thang Tầng 2
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-9.5, TIER_HEIGHT, -17.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-2.5, TIER_HEIGHT, -17.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(2.5, TIER_HEIGHT, -17.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(9.5, TIER_HEIGHT, -17.0), Vector3.ZERO, props_container)

	# Cột hai bên cầu thang Tầng 3
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-3.5, TIER_HEIGHT, -24.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(3.5, TIER_HEIGHT, -24.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-3.5, TIER_HEIGHT * 2.0, -28.5), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(3.5, TIER_HEIGHT * 2.0, -28.5), Vector3.ZERO, props_container)

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

	attach_padded_obstacle_collider(inst, 0.28, 3.5)
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
