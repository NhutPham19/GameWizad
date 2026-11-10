class_name FloatingHPBar3D
extends Node3D

# ==============================================================================
# FLOATING HP BAR 3D - THANH MÁU NỔI TRÊN ĐẦU QUÁI VẬT
# ==============================================================================

var bg_mesh: MeshInstance3D = null
var fill_mesh: MeshInstance3D = null
var max_width: float = 1.0
var height: float = 0.12

func _ready() -> void:
	# Background (Dark Red/Black)
	bg_mesh = MeshInstance3D.new()
	var q_bg = QuadMesh.new()
	q_bg.size = Vector2(max_width + 0.04, height + 0.04)
	bg_mesh.mesh = q_bg
	var bg_mat = StandardMaterial3D.new()
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.albedo_color = Color(0.12, 0.02, 0.02, 0.9)
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_mesh.material_override = bg_mat
	add_child(bg_mesh)
	
	# Fill Bar (Bright Red/Green)
	fill_mesh = MeshInstance3D.new()
	var q_fill = QuadMesh.new()
	q_fill.size = Vector2(max_width, height)
	fill_mesh.mesh = q_fill
	var fill_mat = StandardMaterial3D.new()
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.albedo_color = Color(0.9, 0.18, 0.15)
	fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fill_mesh.material_override = fill_mat
	add_child(fill_mesh)

func update_hp(current_hp: float, max_hp: float) -> void:
	if not fill_mesh:
		return
	var ratio = clamp(current_hp / max_hp, 0.0, 1.0)
	var q: QuadMesh = fill_mesh.mesh
	q.size.x = max_width * ratio
	fill_mesh.position.x = - (max_width * (1.0 - ratio)) * 0.5
