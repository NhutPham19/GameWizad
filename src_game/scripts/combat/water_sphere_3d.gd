class_name WaterSphere3D
extends Node3D

# ==============================================================================
# WATER SPHERE 3D - NEREUS RMB (THỦY CẦU CUỘN XOÁY) - AUTHENTIC VFX
# Argons Directive 07 - Sprint 3
# ==============================================================================

const VFXMasterFactory = preload("res://scripts/combat/vfx_master_factory.gd")

var speed: float = 9.5
var lifetime: float = 3.0
var elapsed: float = 0.0
var damage: float = 30.0
var direction: Vector3 = Vector3.FORWARD
var sphere_radius: float = 1.6

var sphere_mesh: MeshInstance3D = null
var carried_enemies: Array[CharacterBody3D] = []

func setup(p_origin: Vector3, p_dir: Vector3) -> void:
	global_position = p_origin + Vector3(0, sphere_radius, 0)
	direction = p_dir.normalized()
	
	# 1. 3D Water Sphere with Uber Shader
	sphere_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = sphere_radius
	sphere.height = sphere_radius * 2.0
	sphere_mesh.mesh = sphere
	
	var mat = VFXMasterFactory.create_uber_material(Color(0.8, 0.95, 1.0), Color(0.1, 0.55, 0.95), 5.0, Vector2(1.5, 1.5), Vector2(-1.2, 0.8), 0.18)
	sphere_mesh.material_override = mat
	add_child(sphere_mesh)
	
	# 2. Dynamic OmniLight3D (Layer 2)
	VFXMasterFactory.attach_dynamic_light(self, Color(0.15, 0.75, 1.0), 5.5, 2.8)

func _physics_process(delta: float) -> void:
	elapsed += delta
	global_position += direction * speed * delta
	
	if sphere_mesh:
		sphere_mesh.rotate_object_local(Vector3.RIGHT, delta * 8.0)
		
	# Catch enemies inside the rolling water sphere
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = sphere_radius + 0.3
	query.shape = sphere_shape
	query.transform = global_transform
	query.collision_mask = 4 # Hurtbox layer
	
	var hits = space_state.intersect_shape(query)
	for hit in hits:
		var hurt = hit.collider as Hurtbox3D
		if hurt and hurt.team != "hero":
			var enemy = hurt.get_parent() as CharacterBody3D
			if enemy and not carried_enemies.has(enemy):
				carried_enemies.append(enemy)
				
	for enemy in carried_enemies:
		if is_instance_valid(enemy):
			enemy.global_position = global_position
			
	if elapsed >= lifetime:
		_explode()

func _explode() -> void:
	if is_inside_tree() and get_parent():
		VFXMasterFactory.spawn_distortion_shockwave(get_parent(), global_position, 3.5)
		VFXMasterFactory.spawn_ground_cracks(get_parent(), global_position, Color(0.2, 0.7, 1.0), 2.8, 2.0)
		
		# Explode dealing burst damage and releasing carried enemies
		for enemy in carried_enemies:
			if is_instance_valid(enemy) and enemy.has_node("Hurtbox3D"):
				var hurt = enemy.get_node("Hurtbox3D") as Hurtbox3D
				if hurt:
					var kb = (enemy.global_position - global_position).normalized() * 12.0
					hurt.take_damage(DamageData.new(damage, "water", kb, "wet", 3.0, self))
	queue_free()
