class_name FusionMagmaEruption3D
extends Node3D

# ==============================================================================
# FUSION 3: NHAM THẠCH PHUN TRÀO (MAGMA ERUPTION) - LỬA + ĐẤT (PHÍM E)
# Dải đá tảng 3D nứt nẻ dung nham trồi lên để lại hồ lửa đốt sàn
# ==============================================================================

var duration: float = 5.0
var elapsed: float = 0.0
var tick_timer: float = 0.0
var tick_rate: float = 0.35
var magma_damage: float = 9.0

var area: Area3D = null
var pool_mesh: MeshInstance3D = null
var rocks: Array[MeshInstance3D] = []

func setup(p_pos: Vector3, _p_dir: Vector3 = Vector3.ZERO) -> void:
	global_position = p_pos
	
	# Lava Pool Floor Decal/Cylinder
	pool_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 4.2
	cyl.bottom_radius = 4.2
	cyl.height = 0.08
	pool_mesh.mesh = cyl
	pool_mesh.position.y = 0.04
	
	var shader = load("res://shaders/vfx_ground_cracks_decal.gdshader") as Shader
	if shader:
		var smat = ShaderMaterial.new()
		smat.shader = shader
		smat.set_shader_parameter("crack_glow_color", Color(1.0, 0.35, 0.05, 1.0))
		smat.set_shader_parameter("emission_energy", 6.0)
		smat.set_shader_parameter("crack_scale", 10.0)
		pool_mesh.material_override = smat
	else:
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.28, 0.05, 0.85)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.3, 0.05)
		mat.emission_energy_multiplier = 4.0
		pool_mesh.material_override = mat
	add_child(pool_mesh)
	
	# 3 Craggy Magma Rocks rising from center
	for i in range(3):
		var rock = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(1.2, 1.8 + i * 0.4, 1.2)
		rock.mesh = box
		
		var r_mat = StandardMaterial3D.new()
		r_mat.albedo_color = Color(0.35, 0.18, 0.12)
		r_mat.emission_enabled = true
		r_mat.emission = Color(1.0, 0.35, 0.0)
		r_mat.emission_energy_multiplier = 2.0
		rock.material_override = r_mat
		
		var ang = (PI * 2.0 / 3.0) * i
		rock.position = Vector3(cos(ang) * 1.5, 0.9, sin(ang) * 1.5)
		add_child(rock)
		rocks.append(rock)
		
	# Trigger Area
	area = Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 4
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 4.2
	shape.height = 2.0
	col.shape = shape
	col.position.y = 1.0
	area.add_child(col)
	add_child(area)

func _process(delta: float) -> void:
	elapsed += delta
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		_burn_overlapping()
		
	if elapsed >= duration:
		queue_free()

func _burn_overlapping() -> void:
	if not area:
		return
	for body in area.get_overlapping_areas():
		if body is Hurtbox3D and body.team != "hero":
			body.take_damage(DamageData.new(magma_damage, "fire", Vector3.ZERO, "burn", 2.0, self))
