class_name FireWall3D
extends Node3D

# ==============================================================================
# FIRE WALL 3D / LAVA FISSURE - IGNIS RMB (Argons Directive 08 Task 8.1 & 8.2)
# Dải vết nứt địa chấn dung nham dài 8.0m x rộng 1.6m (vfx_lava_fissure.gdshader)
# Phun trào các cột lửa cuộn trào cao 2.2m. Tuyệt đối KHÔNG dùng BoxMesh cam!
# ==============================================================================

const FissureShader = preload("res://shaders/vfx_lava_fissure.gdshader")

var duration: float = 3.8
var elapsed: float = 0.0
var damage_tick_timer: float = 0.0
var tick_rate: float = 0.35
var wall_damage: float = 12.0

var area: Area3D = null
var fissure_mat: ShaderMaterial = null
var flame_pillars: Array[MeshInstance3D] = []

func setup(p_position: Vector3, p_direction: Vector3) -> void:
	position = p_position
	position.y = 0.03 # Float just above ground to eliminate z-fighting
	
	# Rotate along cast direction
	var forward := Vector3(p_direction.x, 0.0, p_direction.z).normalized()
	if forward.length_squared() > 0.01:
		look_at(global_position + forward, Vector3.UP)
		
	# 1. Ground Crack PlaneMesh (8.0m long x 1.8m wide)
	var plane_inst := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 1.8)
	plane_inst.mesh = plane
	plane_inst.position = Vector3(0.0, 0.0, 4.0) # Extend forward 8m
	
	fissure_mat = ShaderMaterial.new()
	fissure_mat.shader = FissureShader
	fissure_mat.set_shader_parameter("magma_bright", Color(1.0, 0.85, 0.3, 1.0))
	fissure_mat.set_shader_parameter("magma_mid", Color(0.98, 0.35, 0.05, 1.0))
	fissure_mat.set_shader_parameter("crust_dark", Color(0.12, 0.05, 0.03, 1.0))
	fissure_mat.set_shader_parameter("emission_power", 3.0) # Clamped safely!
	fissure_mat.set_shader_parameter("life_fade", 1.0)
	plane_inst.material_override = fissure_mat
	add_child(plane_inst)
	
	# 2. Rising Flame Pillars along fissure length
	var num_pillars := 5
	for i in range(num_pillars):
		var pillar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.55
		cyl.height = 2.2
		cyl.cap_top = false
		cyl.cap_bottom = false
		pillar.mesh = cyl
		pillar.position = Vector3(randf_range(-0.3, 0.3), 1.1, 1.2 + i * 1.4)
		
		var p_mat := StandardMaterial3D.new()
		p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		p_mat.albedo_color = Color(1.0, 0.45, 0.1, 0.75)
		p_mat.emission_enabled = true
		p_mat.emission = Color(1.0, 0.5, 0.1)
		p_mat.emission_energy_multiplier = 2.6
		pillar.material_override = p_mat
		
		add_child(pillar)
		flame_pillars.append(pillar)
		
	# 3. Dynamic OmniLight3D
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.5, 0.1)
	light.light_energy = 2.8
	light.omni_range = 9.0
	light.position = Vector3(0.0, 1.2, 4.0)
	add_child(light)
	
	# 4. Trigger Area
	area = Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 4
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(2.2, 2.5, 8.2)
	col.shape = box_shape
	col.position = Vector3(0.0, 1.2, 4.0)
	area.add_child(col)
	add_child(area)

func _process(delta: float) -> void:
	elapsed += delta
	damage_tick_timer += delta
	
	# Animated rising & swirling flame columns
	for i in range(flame_pillars.size()):
		var p := flame_pillars[i]
		p.rotate_y(delta * (6.0 + i * 1.5))
		p.scale.y = 1.0 + 0.25 * sin(elapsed * 12.0 + i)
		
	# Fade out during last 0.8s
	if elapsed >= duration - 0.8:
		var fade := (duration - elapsed) / 0.8
		if fissure_mat:
			fissure_mat.set_shader_parameter("life_fade", clampf(fade, 0.0, 1.0))
			
	if damage_tick_timer >= tick_rate:
		damage_tick_timer = 0.0
		_apply_burn_to_overlapping()
		
	if elapsed >= duration:
		queue_free()

func _apply_burn_to_overlapping() -> void:
	if not area:
		return
	var bodies := area.get_overlapping_areas()
	for b in bodies:
		if b is Hurtbox3D:
			var dmg := DamageData.new(wall_damage, DamageData.DamageType.FIRE)
			(b as Hurtbox3D).take_damage(dmg)
