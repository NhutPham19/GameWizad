class_name VFXImpactExplosion3D
extends Node3D

# ==============================================================================
# VFX IMPACT EXPLOSION 3D - 3-LAYER EXPANDING SHOCKWAVE & PARTICLE BURST
# Task 5.6: Layer 1 Flash + Layer 2 Shockwave Distortion + Layer 3 Debris Burst
# ==============================================================================

var elapsed: float = 0.0
var life_time: float = 0.45
var max_radius: float = 2.4
var impact_color: Color = Color(1.0, 0.45, 0.1)

var flash_mesh: MeshInstance3D = null
var shockwave_mesh: MeshInstance3D = null
var shockwave_mat: ShaderMaterial = null
var particles: GPUParticles3D = null

func setup(p_pos: Vector3, p_color: Color, p_radius: float = 2.4) -> void:
	global_position = p_pos
	impact_color = p_color
	max_radius = max(1.2, p_radius)
	_build_layers()

func _build_layers() -> void:
	# Layer 1: Core Flash Sphere
	flash_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	flash_mesh.mesh = sphere
	
	var f_mat = StandardMaterial3D.new()
	f_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	f_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.95)
	f_mat.emission_enabled = true
	f_mat.emission = impact_color
	f_mat.emission_energy_multiplier = 8.0
	flash_mesh.material_override = f_mat
	add_child(flash_mesh)
	
	# Layer 2: Horizontal Shockwave Ring (Quad with vfx_shockwave_distortion.gdshader)
	shockwave_mesh = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(max_radius * 2.0, max_radius * 2.0)
	quad.orientation = PlaneMesh.FACE_Y
	shockwave_mesh.mesh = quad
	
	var shader = load("res://shaders/vfx_shockwave_distortion.gdshader") as Shader
	if shader:
		shockwave_mat = ShaderMaterial.new()
		shockwave_mat.shader = shader
		shockwave_mat.set_shader_parameter("shockwave_color", impact_color)
		shockwave_mat.set_shader_parameter("emission_energy", 6.5)
		shockwave_mat.set_shader_parameter("ring_radius", 0.1)
		shockwave_mat.set_shader_parameter("fade_progress", 0.0)
		shockwave_mesh.material_override = shockwave_mat
	add_child(shockwave_mesh)
	
	# Layer 3: GPUParticles3D Debris Burst
	particles = GPUParticles3D.new()
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3.UP
	p_mat.spread = 180.0
	p_mat.initial_velocity_min = 4.0
	p_mat.initial_velocity_max = 9.0
	p_mat.gravity = Vector3(0, -12.0, 0)
	p_mat.damping_min = 3.0
	p_mat.damping_max = 5.0
	p_mat.scale_min = 0.12
	p_mat.scale_max = 0.28
	p_mat.color = impact_color
	particles.process_material = p_mat
	
	var d_mesh = SphereMesh.new()
	d_mesh.radius = 0.08
	d_mesh.height = 0.16
	d_mesh.radial_segments = 6
	d_mesh.rings = 3
	var d_mat = StandardMaterial3D.new()
	d_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	d_mat.albedo_color = impact_color
	d_mat.emission_enabled = true
	d_mat.emission = impact_color
	d_mat.emission_energy_multiplier = 2.4 # Clamped emission!
	d_mesh.material = d_mat
	particles.draw_pass_1 = d_mesh
	
	particles.amount = 16
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.emitting = true
	add_child(particles)

func _process(delta: float) -> void:
	elapsed += delta
	var progress = clamp(elapsed / life_time, 0.0, 1.0)
	
	# Scale down flash
	if flash_mesh:
		var f_scale = (1.0 - progress) * 1.5
		flash_mesh.scale = Vector3(f_scale, f_scale, f_scale)
		
	# Expand shockwave ring
	if shockwave_mat:
		shockwave_mat.set_shader_parameter("ring_radius", progress * 0.95)
		shockwave_mat.set_shader_parameter("fade_progress", progress)
		
	if elapsed >= life_time:
		queue_free()
