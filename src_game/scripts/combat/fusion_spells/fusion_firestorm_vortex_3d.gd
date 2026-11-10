class_name FusionFirestormVortex3D
extends Node3D

# ==============================================================================
# FUSION 1: HỎA PHONG BẠO (FIRESTORM VORTEX) - LỬA + GIÓ (PHÍM E)
# Phễu lốc xoáy 3D rực lửa cam-đỏ hút quái vào tâm và phát nổ
# ==============================================================================

var duration: float = 3.5
var elapsed: float = 0.0
var pull_radius: float = 7.5
var pull_force: float = 10.0
var tick_timer: float = 0.0
var tick_rate: float = 0.25
var tick_damage: float = 8.0
var explode_damage: float = 32.0

var funnel_mesh: MeshInstance3D = null

func setup(p_pos: Vector3) -> void:
	global_position = p_pos
	
	# 3D Inverted Flaming Cone Mesh
	funnel_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 2.8
	cyl.bottom_radius = 0.5
	cyl.height = 4.0
	funnel_mesh.mesh = cyl
	funnel_mesh.position.y = 2.0
	
	var shader = load("res://shaders/vfx_elemental_energy.gdshader") as Shader
	if shader:
		var smat = ShaderMaterial.new()
		smat.shader = shader
		smat.set_shader_parameter("core_color", Color(1.0, 0.25, 0.05, 0.85))
		smat.set_shader_parameter("rim_color", Color(1.0, 0.85, 0.2, 1.0))
		smat.set_shader_parameter("emission_energy", 6.5)
		smat.set_shader_parameter("scroll_speed_v", 4.0)
		funnel_mesh.material_override = smat
	else:
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.22, 0.05, 0.75)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.45, 0.1)
		mat.emission_energy_multiplier = 4.5
		funnel_mesh.material_override = mat
	add_child(funnel_mesh)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if funnel_mesh:
		funnel_mesh.rotate_y(delta * 18.0)
		
	tick_timer += delta
	var should_tick = false
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		should_tick = true
		
	# Query and pull enemies
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = pull_radius
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4 # Hurtbox layer
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var enemy = collider.get_parent()
			if enemy is CharacterBody3D:
				var pull = (global_position - enemy.global_position)
				pull.y = 0.0
				if pull.length() > 0.5:
					enemy.velocity += pull.normalized() * pull_force * delta * 20.0
			if should_tick:
				collider.take_damage(DamageData.new(tick_damage, "fire", Vector3.ZERO, "burn", 2.0, self))
				
	if elapsed >= duration:
		_explode()

func _explode() -> void:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = pull_radius * 1.2
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var knock = (collider.global_position - global_position).normalized() * 14.0
			collider.take_damage(DamageData.new(explode_damage, "fire", knock, "burn", 3.0, self))
			
	queue_free()
