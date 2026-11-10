extends SceneTree

const KayKitAssetRegistry = preload("res://scripts/core/kaykit_asset_registry.gd")

func _init() -> void:
	var sc = ResourceLoader.load(KayKitAssetRegistry.STAIRS_WIDE) as PackedScene
	var inst = sc.instantiate()
	var mi = inst.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var mesh = mi.mesh as ArrayMesh
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	
	# Check vertices near Z=0 and Z=4
	var min_z_verts = []
	var max_z_verts = []
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		if v.z < 0.2: min_z_verts.append(v)
		if v.z > 3.8: max_z_verts.append(v)
		
	print("At Z ~ 0 (bottom or top?): sample Y = ", min_z_verts[0].y if min_z_verts.size() > 0 else "none")
	print("At Z ~ 4 (bottom or top?): sample Y = ", max_z_verts[0].y if max_z_verts.size() > 0 else "none")
	quit(0)
