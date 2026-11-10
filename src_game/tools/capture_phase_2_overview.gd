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
		
		# Position camera to frame the full multi-tier view (Tiers 1, 2, 3)
		var cam = arena_node.find_child("IsometricCamera3D", true, false) as IsometricCamera3D
		if cam:
			cam.ortho_size = 40.0
			cam.size = 40.0
			cam.camera_distance = 60.0
			# Set target to the center of Tier 2
			var dummy_target = Node3D.new()
			dummy_target.position = Vector3(0.0, 4.0, -18.0)
			arena_node.add_child(dummy_target)
			cam.target_node = dummy_target
			cam.global_position = Vector3(35.0, 48.0, 22.0)

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count > 60 and not captured:
		captured = true
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		var save_path = ProjectSettings.globalize_path("res://../docs/QA_REPORTS/screenshots/phase_2_multitier_overview.png")
		var err = img.save_png(save_path)
		print("Overview screenshot captured to: ", save_path, " Result error code: ", err)
		quit(0)
		return true
	return false
