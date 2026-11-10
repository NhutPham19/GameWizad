extends SceneTree

const KayKitAssetRegistry = preload("res://scripts/core/kaykit_asset_registry.gd")

func _init() -> void:
	var sc = ResourceLoader.load(KayKitAssetRegistry.STAIRS_WIDE) as PackedScene
	var inst = sc.instantiate()
	var mi = inst.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var mesh = mi.mesh as ArrayMesh
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	
	# Find unique horizontal faces (normal.y > 0.9)
	var step_y = {}
	for i in range(mdt.get_face_count()):
		var n = mdt.get_face_normal(i)
		if n.y > 0.9:
			var v0 = mdt.get_vertex(mdt.get_face_vertex(i, 0))
			var rounded_y = snapped(v0.y, 0.05)
			step_y[rounded_y] = true
			
	var sorted_y = step_y.keys()
	sorted_y.sort()
	print("Step horizontal surfaces Y values: ", sorted_y)
	
	# Also let's check wall height:
	var sc_wall = ResourceLoader.load(KayKitAssetRegistry.WALL_ELEVATION) as PackedScene
	var inst_w = sc_wall.instantiate()
	var mi_w = inst_w.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	print("Wall AABB: ", mi_w.mesh.get_aabb())
	
	quit(0)
