extends SceneTree

var frame_count := 0
var captured := false
var arena_node: Node = null

func _init() -> void:
	var sc = ResourceLoader.load("res://scenes/levels/kaykit_multitier_arena.tscn") as PackedScene
	if sc:
		arena_node = sc.instantiate()
		root.add_child(arena_node)
		if arena_node.has_method("build_arena"):
			arena_node.build_arena()

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count > 60 and not captured:
		captured = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_path = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/phase_2_multitier_arena.png")
		var err = img.save_png(save_path)
		print("Screenshot captured to: ", save_path, " Result error code: ", err)
		quit(0)
		return true
	return false
