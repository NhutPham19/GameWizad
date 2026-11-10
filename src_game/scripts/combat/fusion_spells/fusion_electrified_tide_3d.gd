class_name FusionElectrifiedTide3D
extends Node3D

# ==============================================================================
# FUSION 9: ĐẠI DƯƠNG DẪN ĐIỆN (ELECTRIFIED TIDE) - SÉT + NƯỚC (PHÍM E)
# Quả cầu nước 3D bọc tia điện vàng làm choáng dây chuyền và đẩy lùi quái
# ==============================================================================

var duration: float = 3.5
var elapsed: float = 0.0
var move_dir: Vector3 = Vector3.FORWARD
var speed: float = 7.0
var tide_radius: float = 2.5
var shock_timer: float = 0.0
var shock_rate: float = 0.25
var impact_damage: float = 38.0
var shock_damage: float = 12.0

var sphere_mesh: MeshInstance3D = null
var lightning_ring: MeshInstance3D = null

func setup(p_pos: Vector3, p_dir: Vector3) -> void:
	global_position = p_pos
	move_dir = p_dir.normalized()
	
	# Translucent cyan water orb
	sphere_mesh = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = 1.4
	sph.height = 2.8
	sphere_mesh.mesh = sph
	sphere_mesh.position.y = 1.4
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.1, 0.6, 0.95, 0.75)
	mat.roughness = 0.1
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.7, 1.0)
	mat.emission_energy_multiplier = 2.0
	sphere_mesh.material_override = mat
	add_child(sphere_mesh)
	
	# Electric spark torus rotating on orb equator
	lightning_ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.45
	torus.outer_radius = 1.7
	lightning_ring.mesh = torus
	lightning_ring.position.y = 1.4
	
	var l_mat = StandardMaterial3D.new()
	l_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	l_mat.albedo_color = Color(1.0, 0.95, 0.2)
	l_mat.emission_enabled = true
	l_mat.emission = Color(1.0, 0.9, 0.1)
	l_mat.emission_energy_multiplier = 4.0
	lightning_ring.material_override = l_mat
	add_child(lightning_ring)

func _physics_process(delta: float) -> void:
	elapsed += delta
	global_position += move_dir * speed * delta
	
	if sphere_mesh:
		sphere_mesh.rotate_x(delta * 8.0)
	if lightning_ring:
		lightning_ring.rotate_y(delta * 18.0)
		lightning_ring.rotate_z(delta * 12.0)
		
	shock_timer += delta
	if shock_timer >= shock_rate:
		shock_timer = 0.0
		_conduct_chain_shock()
		
	if elapsed >= duration:
		queue_free()

func _conduct_chain_shock() -> void:
	if not is_inside_tree() or not get_world_3d():
		return
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = tide_radius * 1.5
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var knock = move_dir * 9.0 + Vector3.UP * 4.0
			collider.take_damage(DamageData.new(shock_damage, "lightning", knock, "stun", 1.2, self))
