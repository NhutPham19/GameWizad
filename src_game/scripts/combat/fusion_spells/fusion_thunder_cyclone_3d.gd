class_name FusionThunderCyclone3D
extends Node3D

# ==============================================================================
# FUSION 5: LÔI VÂN CUỒNG PHONG (THUNDER CYCLONE) - GIÓ + SÉT (PHÍM E)
# Lốc xoáy bạc phóng tia sét vàng zic-zac ra xung quanh, làm choáng 2.0s
# ==============================================================================

var duration: float = 3.5
var elapsed: float = 0.0
var move_dir: Vector3 = Vector3.FORWARD
var move_speed: float = 5.0
var bolt_timer: float = 0.0
var bolt_rate: float = 0.4
var bolt_damage: float = 24.0
var cyclone_radius: float = 4.0

var cyclone_mesh: MeshInstance3D = null
var rings: Array[MeshInstance3D] = []

func setup(p_pos: Vector3, p_dir: Vector3) -> void:
	global_position = p_pos
	move_dir = p_dir.normalized()
	
	# Silver / Cyan Cyclone Cylinder
	cyclone_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 2.4
	cyl.bottom_radius = 0.6
	cyl.height = 4.5
	cyclone_mesh.mesh = cyl
	cyclone_mesh.position.y = 2.25
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 0.95, 1.0, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.95, 1.0)
	mat.emission_energy_multiplier = 3.0
	cyclone_mesh.material_override = mat
	add_child(cyclone_mesh)
	
	# 2 Orbiting Lightning Rings
	for i in range(2):
		var ring = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 1.2 + i * 0.7
		torus.outer_radius = 1.4 + i * 0.7
		ring.mesh = torus
		ring.position.y = 1.2 + i * 1.5
		var r_mat = StandardMaterial3D.new()
		r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		r_mat.albedo_color = Color(1.0, 0.95, 0.2)
		r_mat.emission_enabled = true
		r_mat.emission = Color(1.0, 0.9, 0.1)
		r_mat.emission_energy_multiplier = 4.0
		ring.material_override = r_mat
		add_child(ring)
		rings.append(ring)

func _physics_process(delta: float) -> void:
	elapsed += delta
	global_position += move_dir * move_speed * delta
	
	if cyclone_mesh:
		cyclone_mesh.rotate_y(delta * 22.0)
	for i in range(rings.size()):
		rings[i].rotate_y(delta * (15.0 * (1 if i % 2 == 0 else -1)))
		
	# Lightning discharge ticks
	bolt_timer += delta
	if bolt_timer >= bolt_rate:
		bolt_timer = 0.0
		_discharge_lightning()
		
	if elapsed >= duration:
		queue_free()

func _discharge_lightning() -> void:
	if not is_inside_tree() or not get_world_3d():
		return
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = cyclone_radius + 3.0
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var shock_dir = (collider.global_position - global_position).normalized()
			collider.take_damage(DamageData.new(bolt_damage, "lightning", shock_dir * 8.0, "stun", 2.0, self))
