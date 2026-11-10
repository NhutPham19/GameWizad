class_name ExpCrystal3D
extends Node3D

# ==============================================================================
# EXP CRYSTAL 3D - HẠT TINH THỂ KINH NGHIỆM (Argons Directive 08 Task 8.4)
# Rơi 100% từ quái thường khi chết, tự hút ở 6.0m, tăng điểm thanh EXP dưới đáy HUD
# Tuyệt đối KHÔNG hiện banner che màn hình!
# ==============================================================================

const SynthAudio = preload("res://scripts/core/synth_audio.gd")

var exp_value: float = 25.0
var magnet_radius: float = 6.0
var magnet_speed: float = 9.0
var current_hero: HeroBase3D = null
var is_collected: bool = false
var elapsed: float = 0.0

var crystal_mesh: MeshInstance3D = null

func _ready() -> void:
	add_to_group("exp_crystals")
	
	# 1. Octahedron / Diamond Crystal Mesh
	crystal_mesh = MeshInstance3D.new()
	var prism := CylinderMesh.new()
	prism.top_radius = 0.02
	prism.bottom_radius = 0.16
	prism.height = 0.35
	prism.radial_segments = 6
	crystal_mesh.mesh = prism
	crystal_mesh.position.y = 0.25
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.25, 0.85, 1.0) # Bright turquoise EXP crystal
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 1.0)
	mat.emission_energy_multiplier = 1.8
	crystal_mesh.material_override = mat
	add_child(crystal_mesh)
	
	# Light
	var light := OmniLight3D.new()
	light.light_color = Color(0.3, 0.85, 1.0)
	light.light_energy = 1.2
	light.omni_range = 3.5
	light.position.y = 0.25
	add_child(light)

func _process(delta: float) -> void:
	if is_collected:
		return
		
	elapsed += delta
	if crystal_mesh:
		crystal_mesh.rotate_y(delta * 4.5)
		crystal_mesh.position.y = 0.25 + sin(elapsed * 5.0) * 0.06
		
	# Find closest hero for magnetic attraction
	if not current_hero or not is_instance_valid(current_hero):
		var heroes := get_tree().get_nodes_in_group("heroes")
		if heroes.size() > 0 and is_instance_valid(heroes[0]):
			current_hero = heroes[0] as HeroBase3D
			
	if current_hero and is_instance_valid(current_hero):
		var to_hero := current_hero.global_position - global_position
		to_hero.y = 0.0
		var dist := to_hero.length()
		
		if dist <= magnet_radius:
			magnet_speed += delta * 22.0
			global_position = global_position.move_toward(current_hero.global_position + Vector3(0, 0.6, 0), magnet_speed * delta)
			
			if dist <= 0.8:
				_collect_crystal()

func _collect_crystal() -> void:
	if is_collected:
		return
	is_collected = true
	
	if current_hero and is_instance_valid(current_hero):
		if current_hero.has_method("add_exp"):
			current_hero.add_exp(exp_value)
		SynthAudio.play_crystal()
		
	# Quick shrink tween
	if is_inside_tree():
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3.ZERO, 0.12)
		tw.tween_callback(queue_free)
	else:
		queue_free()
