extends SceneTree

func _init() -> void:
	print("==================================================================")
	print("KIỂM ĐỊNH PHASE 2: KAYKIT MULTI-TIER ARENA VERIFICATION")
	print("==================================================================")
	
	var scene_path := "res://scenes/levels/kaykit_multitier_arena.tscn"
	if not ResourceLoader.exists(scene_path):
		print("[FAIL] Scene file not found: ", scene_path)
		quit(1)
		return
		
	var sc: PackedScene = ResourceLoader.load(scene_path) as PackedScene
	if sc == null:
		print("[FAIL] Failed to load scene: ", scene_path)
		quit(1)
		return
		
	var arena = sc.instantiate()
	root.add_child(arena)
	if arena.has_method("build_arena"):
		arena.build_arena()
	
	print("[INFO] Arena instantiated. Verifying components...")
	
	# 1. Check containers
	var ground = arena.find_child("GroundTiles", true, false)
	var walls = arena.find_child("ElevationWalls", true, false)
	var stairs = arena.find_child("Stairs", true, false)
	var props = arena.find_child("Props", true, false)
	
	var ground_count = ground.get_child_count() if ground else 0
	var walls_count = walls.get_child_count() if walls else 0
	var stairs_count = stairs.get_child_count() if stairs else 0
	var props_count = props.get_child_count() if props else 0
	
	print("[CHECK] Ground Tiles Count: ", ground_count, " (Expected: >= 88 = 64 on Tier 1 + 24 on Tier 2 + 12 on Tier 3)")
	print("[CHECK] Elevation Walls Count: ", walls_count)
	print("[CHECK] Stairs Count: ", stairs_count, " (Expected: 3 = 2 Tier1->Tier2 + 1 Tier2->Tier3)")
	print("[CHECK] Props Count: ", props_count)
	
	# 2. Check Primitive Meshes (LUẬT 1: ZERO PRIMITIVE GEOMETRY)
	var forbidden_primitives = ["BoxMesh", "SphereMesh", "CylinderMesh", "CapsuleMesh", "PrismMesh", "TorusMesh"]
	var all_mesh_instances = arena.find_children("*", "MeshInstance3D", true, false)
	var primitive_violations = 0
	for mi in all_mesh_instances:
		var m = (mi as MeshInstance3D).mesh
		if m != null:
			var m_class = m.get_class()
			if m_class in forbidden_primitives:
				print("[VIOLATION] Found forbidden primitive: ", m_class, " on node: ", mi.name)
				primitive_violations += 1
				
	print("[CHECK] Primitive Violations: ", primitive_violations, " (Target: 0)")
	
	# 3. Check Colliders on Layer 1
	var all_static_bodies = arena.find_children("*", "StaticBody3D", true, false)
	var colliders_on_layer_1 = 0
	var colliders_wrong_layer = 0
	for sb in all_static_bodies:
		var s = sb as StaticBody3D
		if s.collision_layer == 1:
			colliders_on_layer_1 += 1
		else:
			colliders_wrong_layer += 1
			
	print("[CHECK] StaticBody3D Colliders on Layer 1: ", colliders_on_layer_1)
	print("[CHECK] StaticBody3D Wrong Layer: ", colliders_wrong_layer)
	
	# 4. Check Camera and Cursor Raycast
	var cam = arena.find_child("IsometricCamera3D", true, false) as IsometricCamera3D
	var cam_ok = (cam != null and cam.rotation_degrees.x < -40.0)
	print("[CHECK] Isometric Camera 3D: ", "OK (Pitch: %.1f, Yaw: %.1f)" % [cam.rotation_degrees.x, cam.rotation_degrees.y] if cam_ok else "FAIL")
	
	# 5. Check Navigation Region
	var nav_reg = arena.find_child("NavigationRegion3D", true, false) as NavigationRegion3D
	var nav_ok = (nav_reg != null and nav_reg.navigation_mesh != null)
	print("[CHECK] NavigationRegion3D: ", "OK (NavMesh present)" if nav_ok else "FAIL")
	
	var pass_all = (
		ground_count >= 88 and
		stairs_count == 3 and
		primitive_violations == 0 and
		colliders_wrong_layer == 0 and
		colliders_on_layer_1 > 50 and
		cam_ok and
		nav_ok
	)
	
	print("==================================================================")
	if pass_all:
		print(">>> PHASE 2 KIỂM ĐỊNH THÀNH CÔNG 100%! BẢN ĐỒ ĐA TẦNG ĐẠT CHUẨN! <<<")
		arena.free()
		quit(0)
	else:
		print(">>> PHASE 2 CÓ LỖI CHƯA ĐẠT CHUẨN! <<<")
		arena.free()
		quit(1)
