class_name ShaderPrewarmer
extends Node

# ==============================================================================
# SHADER PREWARMER - VULKAN PSO PIPELINE CACHE ACCELERATOR
# Eliminates initial shader compilation stutter (0ms lag entering map)
# ==============================================================================

const SHADERS_TO_PREWARM := [
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

static func prewarm(parent_node: Node) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var script = load("res://scripts/core/shader_prewarmer.gd") as GDScript
	if script:
		var prewarmer = script.new()
		parent_node.add_child(prewarmer)

func _ready() -> void:
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
				var box = BoxMesh.new()
				box.size = Vector3(0.1, 0.1, 0.1)
				mi.mesh = box
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
				var box = BoxMesh.new()
				box.size = Vector3(0.1, 0.1, 0.1)
				mi.mesh = box
				mi.material_override = mat
				vp.add_child(mi)
				count += 1
				
	print("🔥 [VULKAN PSO PREWARM] Pre-warmed ", count, " shaders & materials into GPU cache.")
	queue_free()
