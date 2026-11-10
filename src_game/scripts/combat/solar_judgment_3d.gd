class_name SolarJudgment3D
extends Node3D

# ==============================================================================
# SOLAR JUDGMENT 3D - SOLARIS ULTIMATE Q (THIÊN PHẠT THÁNH KIẾM)
# Argons Directive 12 - Task 12.2
# ==============================================================================

const LavaFissureShader = preload("res://shaders/vfx_lava_fissure.gdshader")
const VFXMasterFactory = preload("res://scripts/combat/vfx_master_factory.gd")
const VFXImpactExplosion3D = preload("res://scripts/combat/vfx_impact_explosion_3d.gd")
const SynthAudio = preload("res://scripts/core/synth_audio.gd")

var caster: HeroBase3D = null
var duration: float = 3.5
var elapsed: float = 0.0
var damage: float = 85.0
var radius: float = 4.5 # 9m diameter

var magic_circle_mesh: MeshInstance3D = null
var light_pillar: MeshInstance3D = null
var star_flare: MeshInstance3D = null
var light_source: OmniLight3D = null
var fire_particles: GPUParticles3D = null
var smoke_particles: GPUParticles3D = null
var fissures: Array[MeshInstance3D] = []

func setup(p_caster: HeroBase3D, p_pos: Vector3) -> void:
	caster = p_caster
	global_position = p_pos
	
	_create_ground_fissures_and_circle()
	_create_sky_light_pillar()
	_create_particles()
	_apply_aoe_damage()
	
	SynthAudio.play_explosion()

func _create_ground_fissures_and_circle() -> void:
	# 1. Big Magic Circle (circle_05.png - 9m diameter)
	var circle_tex = ResourceLoader.load("res://assets/vfx_textures/circle_05.png") as Texture2D
	magic_circle_mesh = MeshInstance3D.new()
	var q_circle = QuadMesh.new()
	q_circle.size = Vector2(9.0, 9.0)
	q_circle.orientation = PlaneMesh.FACE_Y
	magic_circle_mesh.mesh = q_circle
	
	var c_mat = StandardMaterial3D.new()
	c_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	c_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	c_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	c_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	c_mat.albedo_color = Color(1.0, 0.75, 0.2, 0.95)
	c_mat.albedo_texture = circle_tex
	magic_circle_mesh.material_override = c_mat
	magic_circle_mesh.position.y = 0.03
	add_child(magic_circle_mesh)
	
	# 2. 4-Branch Lava Fissure (vfx_lava_fissure.gdshader)
	var angles = [0.0, PI * 0.5, PI, PI * 1.5]
	for a in angles:
		var fiss = MeshInstance3D.new()
		var q_fiss = QuadMesh.new()
		q_fiss.size = Vector2(4.5, 1.4)
		q_fiss.orientation = PlaneMesh.FACE_Y
		fiss.mesh = q_fiss
		
		var f_mat = ShaderMaterial.new()
		f_mat.shader = LavaFissureShader
		f_mat.set_shader_parameter("magma_bright", Color(1.0, 0.85, 0.25, 1.0))
		f_mat.set_shader_parameter("magma_mid", Color(0.95, 0.28, 0.05, 1.0))
		f_mat.set_shader_parameter("emission_power", 3.5)
		f_mat.set_shader_parameter("life_fade", 1.0)
		fiss.material_override = f_mat
		
		fiss.position = Vector3(cos(a) * 2.2, 0.04, sin(a) * 2.2)
		fiss.rotation.y = -a
		add_child(fiss)
		fissures.append(fiss)

func _create_sky_light_pillar() -> void:
	var light_tex = ResourceLoader.load("res://assets/vfx_textures/light_03.png") as Texture2D
	var star_tex = ResourceLoader.load("res://assets/vfx_textures/star_08.png") as Texture2D
	
	# Giant Vertical Light Column (height 18m, diameter 3.2m)
	light_pillar = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.8
	cyl.bottom_radius = 1.8
	cyl.height = 18.0
	cyl.radial_segments = 24
	cyl.cap_top = false
	cyl.cap_bottom = false
	light_pillar.mesh = cyl
	
	var p_mat = StandardMaterial3D.new()
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	p_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	p_mat.albedo_color = Color(1.0, 0.85, 0.35, 0.85)
	p_mat.albedo_texture = light_tex
	light_pillar.material_override = p_mat
	light_pillar.position.y = 9.0
	add_child(light_pillar)
	
	# Star Flare at ground impact
	star_flare = MeshInstance3D.new()
	var q_star = QuadMesh.new()
	q_star.size = Vector2(5.5, 5.5)
	q_star.orientation = PlaneMesh.FACE_Y
	star_flare.mesh = q_star
	
	var s_mat = StandardMaterial3D.new()
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	s_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	s_mat.albedo_color = Color(1.0, 0.95, 0.6, 0.9)
	s_mat.albedo_texture = star_tex
	star_flare.material_override = s_mat
	star_flare.position.y = 0.06
	add_child(star_flare)
	
	# Controlled Dynamic OmniLight3D (clamped <= 1.0 to prevent bloom blowout)
	light_source = OmniLight3D.new()
	light_source.light_color = Color(1.0, 0.72, 0.2)
	light_source.omni_range = 6.0
	light_source.light_energy = 1.0
	light_source.position.y = 1.5
	add_child(light_source)

func _create_particles() -> void:
	var flame_tex = ResourceLoader.load("res://assets/vfx_textures/flame_06.png") as Texture2D
	var smoke_tex = ResourceLoader.load("res://assets/vfx_textures/smoke_04.png") as Texture2D
	
	# 40 Fire Particles (flame_06.png)
	fire_particles = GPUParticles3D.new()
	var f_pmat = ParticleProcessMaterial.new()
	f_pmat.direction = Vector3.UP
	f_pmat.spread = 35.0
	f_pmat.initial_velocity_min = 3.0
	f_pmat.initial_velocity_max = 7.0
	f_pmat.gravity = Vector3(0, 2.0, 0)
	f_pmat.scale_min = 0.4
	f_pmat.scale_max = 1.0
	f_pmat.color = Color(1.0, 0.6, 0.1, 0.85)
	fire_particles.process_material = f_pmat
	
	var f_qmesh = QuadMesh.new()
	f_qmesh.size = Vector2(0.8, 0.8)
	var f_mat = StandardMaterial3D.new()
	f_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	f_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	f_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	f_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	f_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	f_mat.albedo_texture = flame_tex
	f_qmesh.material = f_mat
	fire_particles.draw_pass_1 = f_qmesh
	fire_particles.amount = 40
	fire_particles.lifetime = 1.2
	fire_particles.emitting = true
	add_child(fire_particles)
	
	# 40 Smoke Particles (smoke_04.png)
	smoke_particles = GPUParticles3D.new()
	var s_pmat = ParticleProcessMaterial.new()
	s_pmat.direction = Vector3.UP
	s_pmat.spread = 45.0
	s_pmat.initial_velocity_min = 1.5
	s_pmat.initial_velocity_max = 4.5
	s_pmat.gravity = Vector3(0, 1.2, 0)
	s_pmat.scale_min = 0.6
	s_pmat.scale_max = 1.4
	s_pmat.color = Color(0.2, 0.15, 0.12, 0.5)
	smoke_particles.process_material = s_pmat
	
	var s_qmesh = QuadMesh.new()
	s_qmesh.size = Vector2(1.2, 1.2)
	var s_mat = StandardMaterial3D.new()
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	s_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	s_mat.albedo_texture = smoke_tex
	s_qmesh.material = s_mat
	smoke_particles.draw_pass_1 = s_qmesh
	smoke_particles.amount = 40
	smoke_particles.lifetime = 1.6
	smoke_particles.emitting = true
	add_child(smoke_particles)

func _apply_aoe_damage() -> void:
	if not is_inside_tree(): return
	var space_state = get_world_3d().direct_space_state
	if not space_state: return
	
	var shape_query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = radius
	shape_query.shape = sphere
	shape_query.transform = Transform3D(Basis(), global_position)
	shape_query.collision_mask = 4 # Hurtbox layer
	
	var hits = space_state.intersect_shape(shape_query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var enemy_pos = collider.global_position
			var push_dir = (enemy_pos - global_position).normalized()
			if push_dir.length_squared() < 0.01:
				push_dir = Vector3.UP
			var kb = push_dir * 15.0
			collider.take_damage(DamageData.new(damage, "solar", kb, "burn", 4.0, caster))
			
	# Direct Spatial Query across group "enemies" (Directive 13 Task 13.4)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_node := enemy as Node3D
		if not enemy_node or enemy_node == caster:
			continue
		var to_enemy = (enemy_node.global_position - global_position)
		to_enemy.y = 0.0
		var dist = to_enemy.length()
		if dist <= radius:
			var push_dir = to_enemy.normalized() if dist > 0.01 else Vector3.UP
			var kb = push_dir * 15.0
			if enemy_node.has_method("take_damage"):
				enemy_node.take_damage(DamageData.new(damage, "solar", kb, "burn", 4.0, caster))
			elif enemy_node.has_node("Hurtbox3D"):
				var hb = enemy_node.get_node("Hurtbox3D")
				if hb and hb is Hurtbox3D:
					hb.take_damage(DamageData.new(damage, "solar", kb, "burn", 4.0, caster))
			
	# Ground cracks & distortion shockwave
	if get_parent():
		VFXMasterFactory.spawn_ground_cracks(get_parent(), global_position, Color(1.0, 0.7, 0.1), radius * 0.9, 3.0)
		VFXMasterFactory.spawn_distortion_shockwave(get_parent(), global_position, radius * 1.2)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
		
	# Rotate magic circle & star flare
	if magic_circle_mesh:
		magic_circle_mesh.rotate_y(delta * 1.2)
	if star_flare:
		star_flare.rotate_y(-delta * 2.5)
	if light_pillar:
		light_pillar.rotate_y(delta * 0.8)
		
	# Fade out towards the end
	var rem = duration - elapsed
	if rem < 1.0:
		var fade = rem / 1.0
		if magic_circle_mesh and magic_circle_mesh.material_override:
			magic_circle_mesh.material_override.albedo_color.a = fade * 0.95
		if star_flare and star_flare.material_override:
			star_flare.material_override.albedo_color.a = fade * 0.9
		if light_pillar and light_pillar.material_override:
			light_pillar.material_override.albedo_color.a = fade * 0.85
		if light_source:
			light_source.light_energy = fade * 3.2
		for fiss in fissures:
			if fiss.material_override is ShaderMaterial:
				fiss.material_override.set_shader_parameter("life_fade", fade)
