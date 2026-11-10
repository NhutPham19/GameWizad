extends SceneTree

func _init() -> void:
	var nav_mesh = NavigationMesh.new()
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.2
	nav_mesh.agent_max_climb = 0.5
	nav_mesh.agent_max_slope = 52.0
	print("Nav mesh created successfully with cell_size=", nav_mesh.cell_size, " max_climb=", nav_mesh.agent_max_climb)
	quit(0)
