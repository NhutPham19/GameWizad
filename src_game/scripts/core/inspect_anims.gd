extends SceneTree

func _init() -> void:
	var paths = [
		"res://assets/characters/Mage.glb",
		"res://assets/characters/Rogue_Hooded.glb",
		"res://assets/characters/Barbarian.glb",
		"res://assets/characters/Knight.glb"
	]
	for p in paths:
		if ResourceLoader.exists(p):
			var sc = ResourceLoader.load(p) as PackedScene
			var inst = sc.instantiate()
			var players = inst.find_children("*", "AnimationPlayer", true, false)
			if players.size() > 0:
				print("=== Animations for ", p, " ===")
				var list = players[0].get_animation_list()
				for a in list:
					print("  - ", a)
			else:
				print("No AnimationPlayer in ", p)
			inst.queue_free()
	quit(0)
