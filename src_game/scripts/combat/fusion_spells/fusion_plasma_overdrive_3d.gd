class_name FusionPlasmaOverdrive3D
extends Node3D

# ==============================================================================
# FUSION 2: PHÁO ĐIỆN TỪ (PLASMA OVERDRIVE) - LỬA + SÉT (PHÍM E)
# Trụ tia laser năng lượng dài 15m xuyên thấu toàn bản đồ, để lại vệt hồ quang điện
# ==============================================================================

var beam_length: float = 16.0
var beam_width: float = 0.9
var beam_damage: float = 55.0
var duration: float = 0.6
var elapsed: float = 0.0

var beam_mesh: MeshInstance3D = null

func setup(p_origin: Vector3, p_dir: Vector3) -> void:
	global_position = p_origin + Vector3(0, 1.0, 0)
	var dir = p_dir.normalized()
	if dir.length_squared() > 0.001 and not dir.is_equal_approx(Vector3.UP):
		transform.basis = Basis.looking_at(dir, Vector3.UP)
		
	# 3D Beam Cylinder
	beam_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = beam_width
	cyl.bottom_radius = beam_width
	cyl.height = beam_length
	beam_mesh.mesh = cyl
	beam_mesh.position = Vector3(0, 0, -beam_length * 0.5)
	beam_mesh.rotation_degrees = Vector3(90, 0, 0)
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.15, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.45, 0.9)
	mat.emission_energy_multiplier = 6.0
	beam_mesh.material_override = mat
	add_child(beam_mesh)
	
	_deal_piercing_damage()

func _process(delta: float) -> void:
	elapsed += delta
	if beam_mesh:
		var alpha = 1.0 - (elapsed / duration)
		var mat: StandardMaterial3D = beam_mesh.material_override
		mat.albedo_color.a = alpha * 0.9
		
	if elapsed >= duration:
		queue_free()

func _deal_piercing_damage() -> void:
	if not is_inside_tree() or not get_world_3d():
		return
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(beam_width * 2.5, 2.0, beam_length)
	query.shape = box
	query.transform = global_transform.translated(Vector3(0, 0, -beam_length * 0.5))
	query.collision_mask = 4 # Hurtbox layer
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var knock = -global_transform.basis.z * 12.0
			collider.take_damage(DamageData.new(beam_damage, "lightning", knock, "stun", 0.8, self))
