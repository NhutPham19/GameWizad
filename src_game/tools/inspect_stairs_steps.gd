extends SceneTree

const KayKitAssetRegistry = preload("res://scripts/core/kaykit_asset_registry.gd")

func _init() -> void:
	var sc = ResourceLoader.load(KayKitAssetRegistry.STAIRS_WIDE) as PackedScene
	var inst = sc.instantiate()
	var mi = inst.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var mesh = mi.mesh as ArrayMesh
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	
	# For each horizontal face, find center Y and Z
	var steps = []
	for i in range(mdt.get_face_count()):
		var n = mdt.get_face_normal(i)
		if n.y > 0.9:
			var center = Vector3.ZERO
			for k in range(3):
				center += mdt.get_vertex(mdt.get_face_vertex(i, k))
			center /= 3.0
			steps.append(center)
			
	steps.sort_custom(func(a, b): return a.y < b.y)
	for s in steps:
		print("Step at Y = %.2f, Z = %.2f, X = %.2f" % [s.y, s.z, s.x])
	quit(0)
