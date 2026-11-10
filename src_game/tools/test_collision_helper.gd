extends SceneTree

const KayKitAssetRegistry = preload("res://scripts/core/kaykit_asset_registry.gd")

func _init() -> void:
	var sc = ResourceLoader.load(KayKitAssetRegistry.TILE_FLOOR) as PackedScene
	var inst = sc.instantiate()
	var mi = inst.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	mi.create_trimesh_collision()
	print("Children of mi after create_trimesh_collision: ", mi.get_children())
	for c in mi.get_children():
		if c is StaticBody3D:
			print("StaticBody3D layer before: ", c.collision_layer, " mask: ", c.collision_mask)
			c.collision_layer = 1
			c.collision_mask = 0
			print("StaticBody3D layer after: ", c.collision_layer, " mask: ", c.collision_mask)
	inst.queue_free()
	quit(0)
