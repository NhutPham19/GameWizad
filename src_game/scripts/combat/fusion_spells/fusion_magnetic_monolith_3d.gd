class_name FusionMagneticMonolith3D
extends Node3D

# ==============================================================================
# FUSION 8: TRỤ ĐÁ TỪ TRƯỜNG (MAGNETIC MONOLITH) - SÉT + ĐẤT (PHÍM E)
# Triệu hồi 3 cột đá 3D nối tia sét khóa đường di chuyển của quái và giật điện liên tục
# ==============================================================================

var duration: float = 4.5
var elapsed: float = 0.0
var triangle_radius: float = 4.5
var shock_timer: float = 0.0
var shock_rate: float = 0.3
var shock_damage: float = 14.0

var pillars: Array[MeshInstance3D] = []
var arc_beams: Array[MeshInstance3D] = []

func setup(p_pos: Vector3) -> void:
	global_position = p_pos
	
	# Spawn 3 stone pillars in equilateral triangle
	for i in range(3):
		var pillar = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.9, 3.2, 0.9)
		pillar.mesh = box
		var angle = i * (TAU / 3.0)
		pillar.position = Vector3(cos(angle) * triangle_radius, 1.6, sin(angle) * triangle_radius)
		
		# Stone pillar material with glowing runic bands
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.28, 0.26)
		mat.emission_enabled = true
		mat.emission = Color(0.85, 0.4, 1.0)
		mat.emission_energy_multiplier = 3.0
		pillar.material_override = mat
		add_child(pillar)
		pillars.append(pillar)
		
	# Create 3 laser/lightning connection beams between the 3 pillars
	for i in range(3):
		var next_idx = (i + 1) % 3
		var p1 = pillars[i].position
		var p2 = pillars[next_idx].position
		var mid = (p1 + p2) * 0.5
		var length = p1.distance_to(p2)
		
		var beam = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.08
		cyl.height = length
		beam.mesh = cyl
		beam.position = mid
		beam.position.y = 1.6
		
		var b_mat = StandardMaterial3D.new()
		b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		b_mat.albedo_color = Color(1.0, 0.95, 0.3)
		b_mat.emission_enabled = true
		b_mat.emission = Color(0.9, 0.5, 1.0)
		b_mat.emission_energy_multiplier = 4.0
		beam.material_override = b_mat
		add_child(beam)
		
		# Align cylinder to the edge between p1 and p2
		var edge_dir = (p2 - p1).normalized()
		if edge_dir.length_squared() > 0.01:
			beam.transform.basis = Basis.looking_at(edge_dir, Vector3.UP)
			beam.rotate_object_local(Vector3.RIGHT, PI / 2.0)
		arc_beams.append(beam)

func _physics_process(delta: float) -> void:
	elapsed += delta
	
	# Magnetic vibration
	for p in pillars:
		p.position.y = 1.6 + sin(elapsed * 12.0) * 0.08
		
	shock_timer += delta
	if shock_timer >= shock_rate:
		shock_timer = 0.0
		_shock_enclosed_enemies()
		
	if elapsed >= duration:
		queue_free()

func _shock_enclosed_enemies() -> void:
	if not is_inside_tree() or not get_world_3d():
		return
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = triangle_radius * 1.15
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var enemy = collider.get_parent()
			if enemy is CharacterBody3D:
				# Magnetic pull towards center
				var pull_dir = (global_position - enemy.global_position).normalized()
				pull_dir.y = 0.0
				enemy.velocity += pull_dir * 8.0
			collider.take_damage(DamageData.new(shock_damage, "lightning", Vector3.ZERO, "stun", 0.6, self))
