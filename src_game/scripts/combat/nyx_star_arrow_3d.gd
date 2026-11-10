class_name NyxStarArrow3D
extends Node3D

# ==============================================================================
# NYX STAR ARROW 3D - NYX LMB (TIỄN ÁNH SAO XUYÊN THẤU)
# Argons Directive 12 - Task 12.3
# ==============================================================================

const VFXImpactExplosion3D = preload("res://scripts/combat/vfx_impact_explosion_3d.gd")
const SynthAudio = preload("res://scripts/core/synth_audio.gd")
const VFXMasterFactory = preload("res://scripts/combat/vfx_master_factory.gd")

var speed: float = 24.0
var lifetime: float = 2.5
var damage: float = 16.0
var knockback_force: float = 5.0
var direction: Vector3 = Vector3.FORWARD
var caster: Node3D = null
var elapsed: float = 0.0

var projectile_mesh: MeshInstance3D = null
var trail_particles: GPUParticles3D = null
var light: OmniLight3D = null

func setup(p_caster: Node3D, p_dir: Vector3, p_damage: float) -> void:
	caster = p_caster
	direction = p_dir.normalized()
	damage = p_damage
	
	global_position = p_caster.global_position + Vector3(0, 1.05, 0)
	if direction.length_squared() > 0.001 and not direction.is_equal_approx(Vector3.UP):
		transform.basis = Basis.looking_at(direction, Vector3.UP)
		
	_create_rhombic_mesh()
	_create_stardust_trail()
	_create_dynamic_light()
	
	SynthAudio.play_cast()

func _create_rhombic_mesh() -> void:
	# Rhombic Diamond Energy Arrow
	projectile_mesh = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(0.32, 0.75, 0.22)
	projectile_mesh.mesh = prism
	projectile_mesh.rotation.x = -PI * 0.5 # Point forward along -Z
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.0, 0.9, 1.0, 0.95)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.2, 1.0)
	mat.emission_energy_multiplier = 3.5
	projectile_mesh.material_override = mat
	add_child(projectile_mesh)

func _create_stardust_trail() -> void:
	var star_tex = ResourceLoader.load("res://assets/vfx_textures/star_04.png") as Texture2D
	var light_tex = ResourceLoader.load("res://assets/vfx_textures/light_02.png") as Texture2D
	
	trail_particles = GPUParticles3D.new()
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = -direction
	p_mat.spread = 20.0
	p_mat.initial_velocity_min = 1.0
	p_mat.initial_velocity_max = 3.0
	p_mat.gravity = Vector3.ZERO
	p_mat.scale_min = 0.2
	p_mat.scale_max = 0.45
	p_mat.color = Color(0.0, 0.9, 1.0, 0.85)
	trail_particles.process_material = p_mat
	
	var qmesh = QuadMesh.new()
	qmesh.size = Vector2(0.35, 0.35)
	var qmat = StandardMaterial3D.new()
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qmat.albedo_texture = star_tex if star_tex else light_tex
	qmesh.material = qmat
	trail_particles.draw_pass_1 = qmesh
	trail_particles.amount = 18
	trail_particles.lifetime = 0.3
	trail_particles.emitting = true
	add_child(trail_particles)

func _create_dynamic_light() -> void:
	light = OmniLight3D.new()
	light.light_color = Color(0.0, 0.9, 1.0)
	light.omni_range = 4.5
	light.light_energy = 1.0
	add_child(light)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
		
	# Direct Spatial Hit Scan across group "enemies" (Directive 13 Task 13.4)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_node := enemy as Node3D
		if not enemy_node or enemy_node == caster:
			continue
		var to_enemy = (enemy_node.global_position - global_position)
		to_enemy.y = 0.0
		if to_enemy.length() <= 1.25:
			var kb = direction * knockback_force
			if enemy_node.has_method("take_damage"):
				enemy_node.take_damage(DamageData.new(damage, "astral", kb, "none", 0.0, caster))
			elif enemy_node.has_node("Hurtbox3D"):
				var hb = enemy_node.get_node("Hurtbox3D")
				if hb and hb is Hurtbox3D:
					hb.take_damage(DamageData.new(damage, "astral", kb, "none", 0.0, caster))
			_explode_impact_ring(global_position)
			queue_free()
			return
		
	var step_dist = speed * delta
	var next_pos = global_position + direction * step_dist
	
	if _check_collision(next_pos):
		return
		
	global_position = next_pos

func _check_collision(next_pos: Vector3) -> bool:
	if not is_inside_tree(): return false
	var space_state = get_world_3d().direct_space_state
	if not space_state: return false
	
	var ray = PhysicsRayQueryParameters3D.new()
	ray.from = global_position
	ray.to = next_pos
	ray.collision_mask = 5 # World & Hurtbox layers
	
	var hit = space_state.intersect_ray(ray)
	if hit:
		var col = hit.collider
		var hit_pos = hit.position
		global_position = hit_pos
		
		if col is Hurtbox3D and col.team != "hero":
			var kb = direction * knockback_force
			col.take_damage(DamageData.new(damage, "astral", kb, "none", 0.0, caster))
			_on_hit_target(hit_pos, col)
		else:
			_explode_impact_ring(hit_pos)
			
		queue_free()
		return true
		
	return false

func _on_hit_target(hit_pos: Vector3, primary_hit: Hurtbox3D) -> void:
	_explode_impact_ring(hit_pos)
	_chain_lightning_to_nearby(hit_pos, primary_hit)

func _explode_impact_ring(pos: Vector3) -> void:
	if not get_parent(): return
	var magic_tex = ResourceLoader.load("res://assets/vfx_textures/magic_04.png") as Texture2D
	var spark_tex = ResourceLoader.load("res://assets/vfx_textures/spark_03.png") as Texture2D
	
	# Flash ring mesh
	var ring = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(2.4, 2.4)
	q.orientation = PlaneMesh.FACE_Y
	ring.mesh = q
	
	var rmat = StandardMaterial3D.new()
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	rmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rmat.albedo_color = Color(0.0, 0.9, 1.0, 0.95)
	rmat.albedo_texture = magic_tex if magic_tex else spark_tex
	ring.material_override = rmat
	
	get_parent().add_child(ring)
	ring.global_position = pos + Vector3(0, 0.05, 0)
	
	var tw = ring.create_tween()
	tw.tween_property(ring, "scale", Vector3(1.6, 1.0, 1.6), 0.22)
	tw.parallel().tween_property(rmat, "albedo_color:a", 0.0, 0.22)
	tw.tween_callback(ring.queue_free)
	
	SynthAudio.play_player_hit()

func _chain_lightning_to_nearby(pos: Vector3, primary_hit: Hurtbox3D) -> void:
	if not is_inside_tree(): return
	var space_state = get_world_3d().direct_space_state
	if not space_state: return
	
	var shape_query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 5.5
	shape_query.shape = sphere
	shape_query.transform = Transform3D(Basis(), pos)
	shape_query.collision_mask = 4 # Hurtbox layer
	
	var hits = space_state.intersect_shape(shape_query)
	var chained_count = 0
	for h in hits:
		var c = h.collider
		if c is Hurtbox3D and c != primary_hit and c.team != "hero":
			c.take_damage(DamageData.new(damage * 0.65, "lightning", Vector3.ZERO, "stun", 0.2, caster))
			_spawn_chain_beam(pos, c.global_position)
			chained_count += 1
			if chained_count >= 2:
				break

func _spawn_chain_beam(from_pos: Vector3, to_pos: Vector3) -> void:
	if not get_parent(): return
	var spark_tex = ResourceLoader.load("res://assets/vfx_textures/spark_06.png") as Texture2D
	
	var beam = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.06
	var diff = to_pos - from_pos
	var len = diff.length()
	cyl.height = max(0.1, len)
	beam.mesh = cyl
	
	var bmat = StandardMaterial3D.new()
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bmat.albedo_color = Color(0.4, 0.8, 1.0, 0.95)
	bmat.albedo_texture = spark_tex
	beam.material_override = bmat
	
	get_parent().add_child(beam)
	beam.global_position = (from_pos + to_pos) * 0.5
	if diff.length_squared() > 0.001:
		beam.look_at(to_pos, Vector3.UP)
		beam.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		
	var tw = beam.create_tween()
	tw.tween_interval(0.18)
	tw.tween_property(bmat, "albedo_color:a", 0.0, 0.08)
	tw.tween_callback(beam.queue_free)
