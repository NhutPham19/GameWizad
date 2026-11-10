class_name KayKitArenaBuilder
extends Node3D

# ==============================================================================
# KAYKIT MULTI-TIER ARENA BUILDER - DIRECTIVE 14 & 15A (PHASE 2)
# 100% KAYKIT MODELS (.GLB/.GLTF) - ZERO PRIMITIVE GEOMETRY
# 3 Tier Elevations:
#   Tier 1: Y = 0.0m  (Central Valley Plaza 32m x 32m)
#   Tier 2: Y = 4.0m  (Northern Terrace 32m x 12m, with 2 Wide Stairs)
#   Tier 3: Y = 8.0m  (Ancient Citadel Summit 16m x 12m, with 1 Wide Stair)
# Colliders: Trimesh for floors/stairs/walls, Convex for props (Layer 1)
# Seamless NavigationRegion3D bridging all 3 tiers
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

func _ready() -> void:
	build_arena()

func build_arena() -> void:
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
# Vách đá dọc Z = -16.0 chừa 2 Cầu Thang Rộng tại X = -6.0m và X = +6.0m
# ------------------------------------------------------------------------------
func _build_tier_2_terrace() -> void:
	# 1. Mặt sàn Tầng 2 (3 hàng Z: -18, -22, -26)
	for row in range(3):
		var z := -18.0 - (row * TILE_SIZE) # -18, -22, -26 (Z in [-28, -16])
		for col in range(8):
			var x := -14.0 + (col * TILE_SIZE) # X in [-16, 16]
			_spawn_trimesh_piece(KayKitAssetRegistry.TILE_FLOOR, Vector3(x, TIER_HEIGHT, z), Vector3.ZERO, ground_container)
			
	# 2. Hai cầu thang rộng nối Tầng 1 lên Tầng 2
	# Local Z: 4.0 (chân cầu thang tại Z = -12.0, Y = 0.0m), Local Z: 0.0 (đỉnh tại Z = -16.0, Y = 4.0m)
	_spawn_trimesh_piece(KayKitAssetRegistry.STAIRS_WIDE, Vector3(-6.0, 0.0, -16.0), Vector3.ZERO, stairs_container)
	_spawn_trimesh_piece(KayKitAssetRegistry.STAIRS_WIDE, Vector3(6.0, 0.0, -16.0), Vector3.ZERO, stairs_container)
	
	# 3. Vách đá chắn sườn đồi dọc theo Z = -16.0 (chừa khe cầu thang tại X = ±6.0)
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
# Vách đá dọc Z = -28.0 chừa 1 Cầu Thang Rộng ở chính giữa X = 0.0m
# ------------------------------------------------------------------------------
func _build_tier_3_citadel() -> void:
	# 1. Mặt sàn Tầng 3 (4 cột X in [-8, 8], 3 hàng Z in [-40, -28])
	for row in range(3):
		var z := -30.0 - (row * TILE_SIZE) # -30, -34, -38 (Z in [-40, -28])
		for col in range(4):
			var x := -6.0 + (col * TILE_SIZE) # -6, -2, 2, 6 (X in [-8, 8])
			_spawn_trimesh_piece(KayKitAssetRegistry.TILE_FLOOR, Vector3(x, TIER_HEIGHT * 2.0, z), Vector3.ZERO, ground_container)
			
	# 2. Một cầu thang rộng ở giữa nối Tầng 2 lên Tầng 3
	# Local Z: 4.0 (chân tại Z = -24.0, Y = 4.0m), Local Z: 0.0 (đỉnh tại Z = -28.0, Y = 8.0m)
	_spawn_trimesh_piece(KayKitAssetRegistry.STAIRS_WIDE, Vector3(0.0, TIER_HEIGHT, -28.0), Vector3.ZERO, stairs_container)
	
	# 3. Vách đá bao quanh chân Tầng 3 (độ cao Y = 4.0m)
	# Vách phía Nam (Z = -28.0, chừa cầu thang ở X = 0)
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
# BỐ TRÍ VẬT CẢN & TRANG TRÍ KAYKIT (0% PRIMITIVE MESH)
# ------------------------------------------------------------------------------
func _place_props_and_obstacles() -> void:
	# 1. Hàng Cột Đá (Pillars) tại các vị trí trang trọng bên cầu thang
	# Cột dưới chân cầu thang Tầng 1
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-9.8, 0.0, -12.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-2.2, 0.0, -12.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(2.2, 0.0, -12.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(9.8, 0.0, -12.0), Vector3.ZERO, props_container)
	
	# Cột trên đỉnh cầu thang Tầng 2
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-9.8, TIER_HEIGHT, -16.5), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-2.2, TIER_HEIGHT, -16.5), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(2.2, TIER_HEIGHT, -16.5), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(9.8, TIER_HEIGHT, -16.5), Vector3.ZERO, props_container)
	
	# Cột hai bên cầu thang Tầng 3
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-3.8, TIER_HEIGHT, -24.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(3.8, TIER_HEIGHT, -24.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(-3.8, TIER_HEIGHT * 2.0, -28.5), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_PILLAR, Vector3(3.8, TIER_HEIGHT * 2.0, -28.5), Vector3.ZERO, props_container)

	# 2. Đuốc lửa (Torches with warm OmniLight3D)
	_spawn_torch_with_light(Vector3(-10.5, 0.0, -12.0), props_container)
	_spawn_torch_with_light(Vector3(10.5, 0.0, -12.0), props_container)
	_spawn_torch_with_light(Vector3(-4.5, TIER_HEIGHT, -24.0), props_container)
	_spawn_torch_with_light(Vector3(4.5, TIER_HEIGHT, -24.0), props_container)
	_spawn_torch_with_light(Vector3(-4.5, TIER_HEIGHT * 2.0, -38.0), props_container)
	_spawn_torch_with_light(Vector3(4.5, TIER_HEIGHT * 2.0, -38.0), props_container)

	# 3. Rương báu cổ tại đỉnh Tầng 3 (Summit Reward)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_CHEST, Vector3(0.0, TIER_HEIGHT * 2.0, -36.0), Vector3(0, 180, 0), props_container)

	# 4. Thùng gỗ (Barrels) theo cụm
	_spawn_convex_piece(KayKitAssetRegistry.PROP_BARREL, Vector3(-13.5, 0.0, 13.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_BARREL, Vector3(-12.2, 0.0, 13.8), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_BARREL, Vector3(13.2, 0.0, 13.2), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_BARREL, Vector3(14.0, 0.0, 12.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_BARREL, Vector3(-13.5, TIER_HEIGHT, -22.0), Vector3.ZERO, props_container)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_BARREL, Vector3(13.5, TIER_HEIGHT, -22.0), Vector3.ZERO, props_container)

	# 5. Cây cối (Trees Nature Pack) quanh rìa Tầng 1 và trên Tầng 2
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_A, Vector3(-14.5, 0.0, 6.0), Vector3(0, 25, 0), props_container, 2.5)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_B, Vector3(-14.8, 0.0, -4.0), Vector3(0, -40, 0), props_container, 2.8)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_A, Vector3(14.5, 0.0, 6.0), Vector3(0, 60, 0), props_container, 2.5)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_B, Vector3(14.8, 0.0, -4.0), Vector3(0, 15, 0), props_container, 2.8)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_A, Vector3(-10.0, 0.0, 14.5), Vector3(0, 80, 0), props_container, 2.6)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_B, Vector3(10.0, 0.0, 14.5), Vector3(0, -70, 0), props_container, 2.6)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_A, Vector3(-14.0, TIER_HEIGHT, -25.5), Vector3(0, 45, 0), props_container, 2.4)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_TREE_B, Vector3(14.0, TIER_HEIGHT, -25.5), Vector3(0, -30, 0), props_container, 2.4)

	# 6. Tảng đá (Rocks Nature Pack)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_ROCK_A, Vector3(-13.0, 0.0, 11.5), Vector3(0, 35, 0), props_container, 3.5)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_ROCK_B, Vector3(13.0, 0.0, 11.5), Vector3(0, -60, 0), props_container, 3.5)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_ROCK_A, Vector3(-13.0, TIER_HEIGHT, -18.5), Vector3(0, 120, 0), props_container, 3.0)
	_spawn_convex_piece(KayKitAssetRegistry.PROP_ROCK_B, Vector3(13.0, TIER_HEIGHT, -18.5), Vector3(0, -45, 0), props_container, 3.0)

# ------------------------------------------------------------------------------
# HÀM TẠO VA CHẠM VẬT LÝ TRIMESH CHO SÀN, BẬC THANG, VÁCH TẦNG (LAYER 1)
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
	
	# Duyệt đệ quy tạo trimesh collision cho mọi MeshInstance3D
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
# HÀM TẠO VA CHẠM VẬT LÝ CONVEX CHO VẬT CẢN (LAYER 1)
# ------------------------------------------------------------------------------
func _spawn_convex_piece(path: String, pos: Vector3, rot_deg: Vector3, parent: Node, scale_factor: float = 1.0) -> Node3D:
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
					
	return inst

# ------------------------------------------------------------------------------
# ĐUỐC KÈM ÁNH SÁNG OMNILIGHT3D ẤM ÁP
# ------------------------------------------------------------------------------
func _spawn_torch_with_light(pos: Vector3, parent: Node) -> void:
	var torch_inst := _spawn_convex_piece(KayKitAssetRegistry.PROP_TORCH, pos, Vector3.ZERO, parent, 1.8)
	if torch_inst:
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
# THIẾT LẬP NAVIGATION MESH (BẮT BUỘC KẾT NỐI LIỀN MẠCH 3 TẦNG & CẦU THANG)
# ------------------------------------------------------------------------------
func _setup_navigation() -> void:
	var nav_mesh := NavigationMesh.new()
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.25
	nav_mesh.agent_height = 1.6
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_max_climb = 0.5 # Bậc thang KayKit cao 0.5m mỗi bậc
	nav_mesh.agent_max_slope = 52.0
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
# SINH 5 LÍNH ĐỐI KHÁNG ĐA TẦNG (PHASE 4)
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
