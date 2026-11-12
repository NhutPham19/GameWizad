class_name ShaderPrewarmer
extends Node

const KayKitAudioDirector = preload("res://scripts/audio/kaykit_audio_director.gd")

# ==============================================================================
# SHADER PREWARMER - VULKAN PSO PIPELINE CACHE ACCELERATOR (Directive 25)
# 100% ZERO PRIMITIVE MESHES (Uses get_safe_particle_quad_mesh)
# Eliminates initial shader compilation stutter (165Hz+ zero-stutter)
# ==============================================================================

const SHADERS_TO_PREWARM := [
	"res://shaders/vfx_stylized_slash.gdshader",
	"res://shaders/vfx_elemental_energy.gdshader",
	"res://shaders/vfx_ground_cracks_decal.gdshader",
	"res://shaders/vfx_shockwave_distortion.gdshader",
]

const MATERIALS_TO_PREWARM := [
	"res://materials/outline_pass.tres",
	"res://materials/ground_moss.tres",
	"res://materials/water_river_purple.tres",
	"res://materials/magic_glow_statue_eyes.tres",
	"res://materials/water_sanctum_turquoise.tres",
]

const KENNEY_TEXTURES_TO_PREWARM := [
	"res://assets/vfx_textures/kenney_particles/star_07.png",
	"res://assets/vfx_textures/kenney_particles/light_01.png",
	"res://assets/vfx_textures/kenney_particles/circle_02.png",
	"res://assets/vfx_textures/kenney_particles/circle_04.png",
	"res://assets/vfx_textures/kenney_particles/scorch_02.png",
	"res://assets/vfx_textures/kenney_particles/spark_05.png",
	"res://assets/vfx_textures/flame_04.png",
	"res://assets/vfx_textures/spark_06.png",
]

static func prewarm(parent_node: Node) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var script = load("res://scripts/core/shader_prewarmer.gd") as GDScript
	if script:
		var prewarmer = script.new()
		parent_node.add_child(prewarmer)

func _ready() -> void:
	# Pre-cache Prismatic Color Ramp, Rage Red-Blue Ramp & Kenney Textures (Task 25.5 & 26.5)
	KayKitVFXManager._get_prismatic_color_ramp()
	KayKitVFXManager._get_rage_crimson_cobalt_ramp()
	for tex_path in KENNEY_TEXTURES_TO_PREWARM:
		KayKitVFXManager._load_cached_tex(tex_path)

	# Pre-bake và khởi tạo Audio Pool vào RAM (Task 27.2)
	KayKitAudioDirector.ensure_initialized(get_tree())

	var vp = SubViewport.new()
	vp.size = Vector2i(2, 2)
	add_child(vp)
	
	var cam = Camera3D.new()
	cam.position = Vector3(0, 0, 2)
	vp.add_child(cam)
	
	var count = 0
	for s_path in SHADERS_TO_PREWARM:
		if ResourceLoader.exists(s_path):
			var shader = ResourceLoader.load(s_path) as Shader
			if shader:
				var mi = MeshInstance3D.new()
				mi.mesh = KayKitVFXManager.get_safe_particle_quad_mesh(Vector2(0.1, 0.1))
				var smat = ShaderMaterial.new()
				smat.shader = shader
				mi.material_override = smat
				vp.add_child(mi)
				count += 1
				
	for m_path in MATERIALS_TO_PREWARM:
		if ResourceLoader.exists(m_path):
			var mat = ResourceLoader.load(m_path) as Material
			if mat:
				var mi = MeshInstance3D.new()
				mi.mesh = KayKitVFXManager.get_safe_particle_quad_mesh(Vector2(0.1, 0.1))
				mi.material_override = mat
				vp.add_child(mi)
				count += 1
				
	print("🔥 [VULKAN PSO PREWARM] Pre-warmed ", count, " shaders & materials into GPU cache (0% PrimitiveMesh).")
	queue_free()
