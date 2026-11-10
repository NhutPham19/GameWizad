class_name Projectile3D
extends Node3D

const VFXImpactExplosion3D = preload("res://scripts/combat/vfx_impact_explosion_3d.gd")
const SynthAudio = preload("res://scripts/core/synth_audio.gd")
const VFXMasterFactory = preload("res://scripts/combat/vfx_master_factory.gd")

# ==============================================================================
# PROJECTILE 3D - GAMEWIZAD SPELL LAUNCHER (VFX 3.0 OVERHAUL)
# Task 5.6: Procedural Energy Shader + Particle Trail + 3-Layer Impact Explosion
# ==============================================================================

@export var speed: float = 16.0
@export var lifetime: float = 3.0
@export var damage: float = 18.0
@export var element: String = "fire"
@export var knockback_force: float = 5.0
@export var pierce: int = 1
@export var explosion_radius: float = 0.0
@export var status_effect: String = "none"
@export var status_duration: float = 0.0

var direction: Vector3 = Vector3.FORWARD
var elapsed: float = 0.0
var hits_count: int = 0
var hitbox: Hitbox3D = null
var projectile_color: Color = Color(1.0, 0.45, 0.1)

var trail_particles: GPUParticles3D = null

func setup(p_dir: Vector3, p_damage: float, p_elem: String, p_speed: float = 16.0, p_color: Color = Color(1.0, 0.4, 0.1)) -> void:
	direction = p_dir.normalized()
	damage = p_damage
	element = p_elem
	speed = p_speed
	projectile_color = p_color
	
	# Muzzle height lock: Ensure projectile is at chest level, not submerged!
	if global_position.y < 0.90:
		global_position.y = 1.05
	
	if direction.length_squared() > 0.001 and not direction.is_equal_approx(Vector3.UP) and not direction.is_equal_approx(Vector3.DOWN):
		transform.basis = Basis.looking_at(direction, Vector3.UP)
		
	# 1. Visual Energy Core using vfx_master_uber.gdshader (Authentic Multi-Layer Noise & Soft Fade)
	var mesh_inst = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.32
	sphere_mesh.height = 0.64
	mesh_inst.mesh = sphere_mesh
	
	# Emission clamped safely to 2.8 under Tonemap ACES!
	var uber_mat = VFXMasterFactory.create_uber_material(Color(1.0, 0.95, 0.8), p_color, 2.8)
	mesh_inst.material_override = uber_mat
	add_child(mesh_inst)
	
	# Layer 2: Dynamic OmniLight3D (Authentic lighting illuminating ground & walls)
	VFXMasterFactory.attach_dynamic_light(self, p_color, 4.5, 1.8)
	
	# 2. Particle Trail (Energy sparks trailing behind)
	trail_particles = GPUParticles3D.new()
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = -direction
	p_mat.spread = 25.0
	p_mat.initial_velocity_min = 1.0
	p_mat.initial_velocity_max = 3.5
	p_mat.gravity = Vector3.ZERO
	p_mat.scale_min = 0.08
	p_mat.scale_max = 0.18
	p_mat.color = p_color
	trail_particles.process_material = p_mat
	
	var spark_mesh = SphereMesh.new()
	spark_mesh.radius = 0.08
	spark_mesh.height = 0.16
	var sp_mat = StandardMaterial3D.new()
	sp_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sp_mat.albedo_color = p_color
	spark_mesh.material = sp_mat
	trail_particles.draw_pass_1 = spark_mesh
	
	trail_particles.amount = 12
	trail_particles.lifetime = 0.22
	trail_particles.emitting = true
	add_child(trail_particles)
	
	# 3. Setup Hitbox
	hitbox = Hitbox3D.new()
	hitbox.damage_amount = damage
	hitbox.element_type = element
	hitbox.knockback_force = knockback_force
	hitbox.status_effect = status_effect
	hitbox.status_duration = status_duration
	hitbox.team = "hero"
	
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.38
	col.shape = shape
	hitbox.add_child(col)
	add_child(hitbox)
	
	hitbox.hit_landed.connect(_on_hit_landed)

func _physics_process(delta: float) -> void:
	var move_step := direction * speed * delta
	var target_pos := global_position + move_step
	
	# Raycast against environment obstacles (Collision Layer 1: World / Props / Boundaries)
	if is_inside_tree():
		var space_state := get_world_3d().direct_space_state
		if space_state:
			var ray_query := PhysicsRayQueryParameters3D.create(global_position, target_pos)
			ray_query.collision_mask = 1 # World & Obstacles
			var hit := space_state.intersect_ray(ray_query)
			if hit:
				global_position = hit.position
				_on_environment_hit(hit.collider)
				_explode_and_free()
				return
				
	global_position = target_pos
	elapsed += delta
	if elapsed >= lifetime:
		_explode_and_free()

func _on_environment_hit(collider: Object) -> void:
	if not collider:
		return
	if collider.has_method("take_damage"):
		collider.take_damage(DamageData.new(damage, element, direction * knockback_force, "none", 0.0, self))
	elif collider.has_meta("destructible") and collider.get_meta("destructible"):
		var cur_hp: float = collider.get_meta("hp") if collider.has_meta("hp") else 20.0
		cur_hp -= damage
		if cur_hp <= 0.0:
			_break_destructible(collider)
		else:
			collider.set_meta("hp", cur_hp)

func _break_destructible(prop: Object) -> void:
	var target_node: Node3D = prop as Node3D
	if not target_node:
		return
	var parent_node := target_node.get_parent()
	var spawn_pos := target_node.global_position
	
	var orb_script = load("res://scripts/elements/health_orb_3d.gd")
	if parent_node and orb_script:
		var orb = orb_script.new()
		parent_node.add_child(orb)
		orb.setup(spawn_pos + Vector3(0, 0.4, 0), 15.0)
		
	# Destroy whole prop node (parent if collider is a child)
	if target_node.name.begins_with("Collider_") and target_node.get_parent():
		target_node.get_parent().queue_free()
	else:
		target_node.queue_free()

func _on_hit_landed(_target: Hurtbox3D, _dmg: DamageData) -> void:
	hits_count += 1
	if hits_count >= pierce:
		_explode_and_free()

func _explode_and_free() -> void:
	if is_inside_tree() and get_parent():
		# Spawn 3-Layer VFX Impact Explosion
		var explosion = VFXImpactExplosion3D.new()
		get_parent().add_child(explosion)
		explosion.setup(global_position, projectile_color, max(2.0, explosion_radius))
		SynthAudio.play_explosion()
		
		# Layer 3: Ground Cracks Decal & Distortion Shockwave
		if explosion_radius >= 1.5:
			VFXMasterFactory.spawn_ground_cracks(get_parent(), global_position, projectile_color, explosion_radius)
			VFXMasterFactory.spawn_distortion_shockwave(get_parent(), global_position, explosion_radius * 1.2)
			var vp := get_viewport()
			var cam: Camera3D = vp.get_camera_3d() if vp else null
			if cam and cam.has_method("add_shake"):
				cam.add_shake(0.18)
		
		if explosion_radius > 0.0:
			_trigger_area_splash()
	queue_free()

func _trigger_area_splash() -> void:
	var space_state = get_world_3d().direct_space_state
	var shape_query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = explosion_radius
	shape_query.shape = sphere
	shape_query.transform = global_transform
	shape_query.collision_mask = 4 # Hurtbox layer
	
	var results = space_state.intersect_shape(shape_query)
	for res in results:
		var collider = res.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var knock_dir = (collider.global_position - global_position).normalized()
			var kb = knock_dir * (knockback_force * 1.5)
			collider.take_damage(DamageData.new(damage * 0.8, element, kb, "burn", 2.0, self))
