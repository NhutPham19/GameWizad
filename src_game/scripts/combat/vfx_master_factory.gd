class_name VFXMasterFactory
extends RefCounted

# ==============================================================================
# VFX MASTER FACTORY - ZERO-FAKE AUTHENTIC 3D VFX SYSTEM
# Argons Directive 07 - Sprint 3
# ==============================================================================

const UberShader = preload("res://shaders/vfx_master_uber.gdshader")
const ShockwaveShader = preload("res://shaders/vfx_shockwave_distortion.gdshader")
const GroundCrackShader = preload("res://shaders/vfx_ground_cracks_decal.gdshader")

static var _cached_noise_primary: NoiseTexture2D = null
static var _cached_noise_secondary: NoiseTexture2D = null

static func get_primary_noise() -> NoiseTexture2D:
	if _cached_noise_primary:
		return _cached_noise_primary
	_cached_noise_primary = NoiseTexture2D.new()
	_cached_noise_primary.seamless = true
	var fnl = FastNoiseLite.new()
	fnl.noise_type = FastNoiseLite.TYPE_CELLULAR
	fnl.frequency = 0.035
	fnl.fractal_octaves = 3
	_cached_noise_primary.noise = fnl
	return _cached_noise_primary

static func get_secondary_noise() -> NoiseTexture2D:
	if _cached_noise_secondary:
		return _cached_noise_secondary
	_cached_noise_secondary = NoiseTexture2D.new()
	_cached_noise_secondary.seamless = true
	var fnl = FastNoiseLite.new()
	fnl.noise_type = FastNoiseLite.TYPE_PERLIN
	fnl.frequency = 0.05
	fnl.fractal_octaves = 2
	_cached_noise_secondary.noise = fnl
	return _cached_noise_secondary

static func create_uber_material(core_col: Color, edge_col: Color, emission: float = 2.8, scroll1: Vector2 = Vector2(1.2, 0.8), scroll2: Vector2 = Vector2(-0.7, 1.4), erosion: float = 0.22) -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = UberShader
	mat.set_shader_parameter("noise_tex_primary", get_primary_noise())
	mat.set_shader_parameter("noise_tex_secondary", get_secondary_noise())
	mat.set_shader_parameter("core_color", core_col)
	mat.set_shader_parameter("edge_color", edge_col)
	# Argons Directive 08: Absolute emission clamp <= 3.5 (prevents bloom blowout!)
	mat.set_shader_parameter("emission_power", clampf(emission, 1.0, 3.5))
	mat.set_shader_parameter("scroll_speed_1", scroll1)
	mat.set_shader_parameter("scroll_speed_2", scroll2)
	mat.set_shader_parameter("erosion_threshold", erosion)
	mat.set_shader_parameter("proximity_fade_dist", 0.45)
	return mat

static func attach_dynamic_light(target: Node3D, light_color: Color, range_dist: float = 5.5, energy: float = 1.8) -> OmniLight3D:
	var light = OmniLight3D.new()
	light.name = "DynamicSpellLight"
	light.light_color = light_color
	light.omni_range = range_dist
	light.light_energy = clampf(energy, 0.5, 2.4)
	target.add_child(light)
	return light

static func spawn_ground_cracks(parent: Node, pos: Vector3, crack_color: Color, radius: float = 3.2, duration: float = 2.5) -> void:
	if not parent:
		return
	var decal = Decal.new()
	decal.name = "GroundCrackDecal"
	decal.size = Vector3(radius * 2.0, 1.5, radius * 2.0)
	decal.position = pos + Vector3(0, 0.5, 0)
	decal.modulate = crack_color
	
	# Fade out after duration
	parent.add_child(decal)
	var tw = decal.create_tween()
	tw.tween_interval(duration * 0.7)
	tw.tween_property(decal, "modulate:a", 0.0, duration * 0.3)
	tw.tween_callback(decal.queue_free)

static func spawn_distortion_shockwave(parent: Node, pos: Vector3, radius: float = 3.0) -> void:
	if not parent:
		return
	var wave = MeshInstance3D.new()
	wave.name = "DistortionShockwave"
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	wave.mesh = sphere
	wave.position = pos
	
	var mat = ShaderMaterial.new()
	mat.shader = ShockwaveShader
	mat.set_shader_parameter("shockwave_radius", 0.0)
	wave.material_override = mat
	parent.add_child(wave)
	
	var tw = wave.create_tween()
	tw.tween_property(wave, "scale", Vector3(radius, radius, radius), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(v: float): mat.set_shader_parameter("shockwave_radius", v), 0.0, 1.0, 0.35)
	tw.tween_callback(wave.queue_free)
