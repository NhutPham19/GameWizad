extends SceneTree

const KayKitAssetRegistry = preload("res://scripts/core/kaykit_asset_registry.gd")

func _init() -> void:
	var sc = ResourceLoader.load(KayKitAssetRegistry.STAIRS_WIDE) as PackedScene
	var inst = sc.instantiate()
	var mi = inst.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var mesh = mi.mesh
	print("Stairs Wide Mesh Details:")
	print("AABB: ", mesh.get_aabb())
	var mdt = MeshDataTool.new()
	var arr_mesh = mesh as ArrayMesh
	if arr_mesh:
		mdt.create_from_surface(arr_mesh, 0)
		var min_y = 999.0
		var max_y = -999.0
		var min_z = 999.0
		var max_z = -999.0
		for i in range(mdt.get_vertex_count()):
			var v = mdt.get_vertex(i)
			if v.y < min_y: min_y = v.y
			if v.y > max_y: max_y = v.y
			if v.z < min_z: min_z = v.z
			if v.z > max_z: max_z = v.z
		print("Vertex Y range: [", min_y, ", ", max_y, "]")
		print("Vertex Z range: [", min_z, ", ", max_z, "]")
	quit(0)
