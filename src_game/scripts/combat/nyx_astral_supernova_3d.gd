class_name NyxAstralSupernova3D
extends Node3D

# ==============================================================================
# NYX ASTRAL SUPERNOVA 3D - NYX ULTIMATE Q (BÃO ĐIỆN TỪ NGÂN HÀ)
# Argons Directive 12 - Task 12.3
# ==============================================================================

const AstralThunderShader = preload("res://shaders/vfx_astral_thunder_zone.gdshader")
const ChainLightning3D = preload("res://scripts/combat/chain_lightning_3d.gd")
const VFXImpactExplosion3D = preload("res://scripts/combat/vfx_impact_explosion_3d.gd")
const VFXMasterFactory = preload("res://scripts/combat/vfx_master_factory.gd")
const SynthAudio = preload("res://scripts/core/synth_audio.gd")

var caster: HeroBase3D = null
var duration: float = 3.6
var elapsed: float = 0.0
var radius: float = 5.0 # 10m diameter
var damage: float = 90.0

var thunder_zone_mesh: MeshInstance3D = null
var circle_mesh_1: MeshInstance3D = null
var circle_mesh_2: MeshInstance3D = null
var light: OmniLight3D = null
var stardust_particles: GPUParticles3D = null

var lightning_strikes_spawned: int = 0
var lightning_strike_timer: float = 0.0

func setup(p_caster: HeroBase3D, p_target_pos: Vector3) -> void:
	caster = p_caster
	global_position = p_target_pos
	global_position.y = 0.04
	
	_create_ground_astral_zone()
	_create_meteor_stardust_shower()
	_create_light()
	
	SynthAudio.play_cast()

func _create_ground_astral_zone() -> void:
	# 1. Base 10m Plane with vfx_astral_thunder_zone.gdshader
	thunder_zone_mesh = MeshInstance3D.new()
	var q_zone = QuadMesh.new()
	q_zone.size = Vector2(10.0, 10.0)
	q_zone.orientation = PlaneMesh.FACE_Y
	thunder_zone_mesh.mesh = q_zone
	
	var mat_zone = ShaderMaterial.new()
	mat_zone.shader = AstralThunderShader
	mat_zone.set_shader_parameter("core_color", Color(0.0, 0.9, 1.0, 1.0))
	mat_zone.set_shader_parameter("outer_color", Color(0.55, 0.15, 0.95, 1.0))
	mat_zone.set_shader_parameter("emission_strength", 3.2)
	thunder_zone_mesh.material_override = mat_zone
	thunder_zone_mesh.position.y = 0.04
	add_child(thunder_zone_mesh)
	
	# 2. Magic Circle 1 (circle_04.png)
	var circle_tex = ResourceLoader.load("res://assets/vfx_textures/circle_04.png") as Texture2D
	circle_mesh_1 = MeshInstance3D.new()
	var q1 = QuadMesh.new()
	q1.size = Vector2(9.2, 9.2)
	q1.orientation = PlaneMesh.FACE_Y
	circle_mesh_1.mesh = q1
	
	var cmat1 = StandardMaterial3D.new()
	cmat1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cmat1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cmat1.cull_mode = BaseMaterial3D.CULL_DISABLED
	cmat1.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	cmat1.albedo_color = Color(0.0, 0.85, 1.0, 0.9)
	cmat1.albedo_texture = circle_tex
	circle_mesh_1.material_override = cmat1
	circle_mesh_1.position.y = 0.05
	add_child(circle_mesh_1)
	
	# 3. Magic Circle 2 (magic_05.png)
	var magic_tex = ResourceLoader.load("res://assets/vfx_textures/magic_05.png") as Texture2D
	circle_mesh_2 = MeshInstance3D.new()
	var q2 = QuadMesh.new()
	q2.size = Vector2(8.0, 8.0)
	q2.orientation = PlaneMesh.FACE_Y
	circle_mesh_2.mesh = q2
	
	var cmat2 = StandardMaterial3D.new()
	cmat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cmat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cmat2.cull_mode = BaseMaterial3D.CULL_DISABLED
	cmat2.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	cmat2.albedo_color = Color(0.7, 0.25, 1.0, 0.85)
	cmat2.albedo_texture = magic_tex
	circle_mesh_2.material_override = cmat2
	circle_mesh_2.position.y = 0.06
	add_child(circle_mesh_2)

func _create_meteor_stardust_shower() -> void:
	var star_tex = ResourceLoader.load("res://assets/vfx_textures/star_09.png") as Texture2D
	var slash_tex = ResourceLoader.load("res://assets/vfx_textures/slash_04.png") as Texture2D
	var light_tex = ResourceLoader.load("res://assets/vfx_textures/light_01.png") as Texture2D
	
	stardust_particles = GPUParticles3D.new()
	var pmat = ParticleProcessMaterial.new()
	# Diagonal meteor shower
	pmat.direction = Vector3(0.5, -1.0, 0.3).normalized()
	pmat.spread = 15.0
	pmat.initial_velocity_min = 12.0
	pmat.initial_velocity_max = 18.0
	pmat.gravity = Vector3(0, -9.8, 0)
	pmat.scale_min = 0.35
	pmat.scale_max = 0.85
	pmat.color = Color(0.0, 0.9, 1.0, 0.95)
	stardust_particles.process_material = pmat
	
	var qmesh = QuadMesh.new()
	qmesh.size = Vector2(0.65, 0.65)
	var smat = StandardMaterial3D.new()
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.cull_mode = BaseMaterial3D.CULL_DISABLED
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	smat.albedo_texture = star_tex if star_tex else slash_tex
	qmesh.material = smat
	stardust_particles.draw_pass_1 = qmesh
	stardust_particles.amount = 45
	stardust_particles.lifetime = 0.8
	stardust_particles.position.y = 8.5
	stardust_particles.emitting = true
	add_child(stardust_particles)

func _create_light() -> void:
	light = OmniLight3D.new()
	light.light_color = Color(0.2, 0.8, 1.0)
	light.omni_range = 6.0
	light.light_energy = 1.0
	light.position.y = 1.5
	add_child(light)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
		
	# Rotate magic circles
	if circle_mesh_1:
		circle_mesh_1.rotate_y(delta * 1.5)
	if circle_mesh_2:
		circle_mesh_2.rotate_y(-delta * 2.2)
		
	# Spawn 12 Arc Lightning Strikes sequentially
	if lightning_strikes_spawned < 12:
		lightning_strike_timer += delta
		if lightning_strike_timer >= 0.16:
			lightning_strike_timer = 0.0
			_spawn_lightning_strike()
			lightning_strikes_spawned += 1
			if lightning_strikes_spawned == 12:
				_trigger_final_supernova_explosion()
				
	# Fade out
	var rem = duration - elapsed
	if rem < 0.8:
		var fade = rem / 0.8
		if circle_mesh_1 and circle_mesh_1.material_override:
			circle_mesh_1.material_override.albedo_color.a = fade * 0.9
		if circle_mesh_2 and circle_mesh_2.material_override:
			circle_mesh_2.material_override.albedo_color.a = fade * 0.85
		if light:
			light.light_energy = fade * 3.2

func _spawn_lightning_strike() -> void:
	var rand_angle = randf() * TAU
	var rand_dist = randf() * (radius * 0.8)
	var strike_target = global_position + Vector3(cos(rand_angle) * rand_dist, 0.0, sin(rand_angle) * rand_dist)
	var strike_sky = strike_target + Vector3(0, 8.5, 0)
	
	var spark_tex = ResourceLoader.load("res://assets/vfx_textures/spark_06.png") as Texture2D
	var beam = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.16
	cyl.height = 8.5
	beam.mesh = cyl
	
	var bmat = StandardMaterial3D.new()
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bmat.albedo_color = Color(0.3, 0.9, 1.0, 0.95)
	bmat.albedo_texture = spark_tex
	beam.material_override = bmat
	
	add_child(beam)
	beam.global_position = strike_target + Vector3(0, 4.25, 0)
	
	# Lightning flash
	SynthAudio.play_player_hit()
	
	# Damage targets near strike
	_damage_near_strike(strike_target, 2.0, 15.0)
	
	var tw = beam.create_tween()
	tw.tween_interval(0.12)
	tw.tween_property(bmat, "albedo_color:a", 0.0, 0.08)
	tw.tween_callback(beam.queue_free)

func _damage_near_strike(pos: Vector3, strike_rad: float, dmg: float) -> void:
	if not is_inside_tree(): return
	var space_state = get_world_3d().direct_space_state
	if not space_state: return
	
	var shape_query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = strike_rad
	shape_query.shape = sphere
	shape_query.transform = Transform3D(Basis(), pos)
	shape_query.collision_mask = 4
	
	var hits = space_state.intersect_shape(shape_query)
	for h in hits:
		var col = h.collider
		if col is Hurtbox3D and col.team != "hero":
			col.take_damage(DamageData.new(dmg, "lightning", Vector3.ZERO, "stun", 0.35, caster))
			
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_node := enemy as Node3D
		if not enemy_node or enemy_node == caster:
			continue
		var to_e = enemy_node.global_position - pos
		to_e.y = 0.0
		if to_e.length() <= strike_rad:
			if enemy_node.has_method("take_damage"):
				enemy_node.take_damage(DamageData.new(dmg, "lightning", Vector3.ZERO, "stun", 0.35, caster))
			elif enemy_node.has_node("Hurtbox3D"):
				var hb = enemy_node.get_node("Hurtbox3D")
				if hb and hb is Hurtbox3D:
					hb.take_damage(DamageData.new(dmg, "lightning", Vector3.ZERO, "stun", 0.35, caster))

func _trigger_final_supernova_explosion() -> void:
	if not get_parent(): return
	# Big crescendo explosion & full-screen shockwave
	var explosion = VFXImpactExplosion3D.new()
	get_parent().add_child(explosion)
	explosion.setup(global_position + Vector3(0, 1.0, 0), Color(0.0, 0.9, 1.0), 3.5)
	
	VFXMasterFactory.spawn_distortion_shockwave(get_parent(), global_position, radius * 1.4)
	SynthAudio.play_explosion()
	
	# Final burst damage to all remaining in zone
	if not is_inside_tree(): return
	var space_state = get_world_3d().direct_space_state
	if not space_state: return
	
	var shape_query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = radius
	shape_query.shape = sphere
	shape_query.transform = Transform3D(Basis(), global_position)
	shape_query.collision_mask = 4
	
	var hits = space_state.intersect_shape(shape_query)
	for h in hits:
		var col = h.collider
		if col is Hurtbox3D and col.team != "hero":
			var kb = (col.global_position - global_position).normalized() * 14.0
			col.take_damage(DamageData.new(damage, "astral", kb, "stun", 1.5, caster))
			
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_node := enemy as Node3D
		if not enemy_node or enemy_node == caster:
			continue
		var to_e = enemy_node.global_position - global_position
		to_e.y = 0.0
		if to_e.length() <= radius:
			var kb = to_e.normalized() * 14.0 if to_e.length() > 0.01 else Vector3.UP * 10.0
			if enemy_node.has_method("take_damage"):
				enemy_node.take_damage(DamageData.new(damage, "astral", kb, "stun", 1.5, caster))
			elif enemy_node.has_node("Hurtbox3D"):
				var hb = enemy_node.get_node("Hurtbox3D")
				if hb and hb is Hurtbox3D:
					hb.take_damage(DamageData.new(damage, "astral", kb, "stun", 1.5, caster))
