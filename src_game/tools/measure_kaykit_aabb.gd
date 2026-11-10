extends SceneTree

const KayKitAssetRegistry = preload("res://scripts/core/kaykit_asset_registry.gd")

func _init() -> void:
	print("--- MEASURING KAYKIT MESH AABBS ---")
	var models = [
		KayKitAssetRegistry.TILE_FLOOR,
		KayKitAssetRegistry.STAIRS_WIDE,
		KayKitAssetRegistry.STAIRS_NORMAL,
		KayKitAssetRegistry.WALL_ELEVATION,
		KayKitAssetRegistry.PROP_PILLAR,
		KayKitAssetRegistry.PROP_BARREL,
		KayKitAssetRegistry.PROP_TORCH,
		KayKitAssetRegistry.PROP_TREE_A,
		KayKitAssetRegistry.PROP_ROCK_A
	]
	
	for path in models:
		var sc = ResourceLoader.load(path) as PackedScene
		if sc == null:
			print("Could not load: ", path)
			continue
		var inst = sc.instantiate()
		var mesh_insts = inst.find_children("*", "MeshInstance3D", true, false)
		print("\nModel: ", path.get_file())
		for mi in mesh_insts:
			var m = mi as MeshInstance3D
			if m.mesh:
				var aabb = m.mesh.get_aabb()
				print("  Mesh: ", m.name, " AABB: size=", aabb.size, " pos=", aabb.position)
		inst.queue_free()
		
	quit(0)
