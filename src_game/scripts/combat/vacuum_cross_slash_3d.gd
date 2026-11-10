class_name VacuumCrossSlash3D
extends Node3D

# ==============================================================================
# VACUUM CROSS SLASH 3D - ZEPHYR ULTIMATE (PHÍM Q) - TRẢM KHÔNG ĐOẠT MỆNH
# Argons Directive 08 Task 8.1 & 8.2 (2 vết cắt chữ X màu lục bảo nổ chân không)
# ==============================================================================

var duration: float = 0.45
var elapsed: float = 0.0
var damage: float = 55.0
var caster: Node3D = null
var cut_slash_1: MeshInstance3D = null
var cut_slash_2: MeshInstance3D = null

func setup(p_center: Vector3, p_aim_dir: Vector3, p_caster: Node3D = null) -> void:
	global_position = p_center
	global_position.y = maxf(global_position.y, 1.10) # Lock height at chest level!
	caster = p_caster
	
	var forward := Vector3(p_aim_dir.x, 0.0, p_aim_dir.z).normalized()
	if forward.length_squared() > 0.01:
		look_at(global_position + forward, Vector3.UP)
		
	# 2 Cross intersecting blade ribbons (X-Shape)
	cut_slash_1 = _create_blade_line(Vector3(-2.8, 1.4, 0.0), Vector3(2.8, -1.4, 0.0))
	cut_slash_2 = _create_blade_line(Vector3(-2.8, -1.4, 0.0), Vector3(2.8, 1.4, 0.0))
	add_child(cut_slash_1)
	add_child(cut_slash_2)
	
	# Light
	var light := OmniLight3D.new()
	light.light_color = Color(0.2, 1.0, 0.7)
	light.light_energy = 2.4
	light.omni_range = 6.0
	add_child(light)

func _create_blade_line(p_start: Vector3, p_end: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.08
	cyl.height = p_start.distance_to(p_end)
	mi.mesh = cyl
	
	mi.position = (p_start + p_end) * 0.5
	mi.look_at(mi.global_position + (p_end - p_start).normalized(), Vector3.UP)
	mi.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	
	var mat := StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.7, 1.0, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 1.0, 0.7)
	mat.emission_energy_multiplier = 2.8
	mi.material_override = mat
	return mi

func _process(delta: float) -> void:
	elapsed += delta
	
	# Tremble vibration before detonation
	var shake := Vector3(randf_range(-0.06, 0.06), randf_range(-0.06, 0.06), 0.0)
	if cut_slash_1: cut_slash_1.position += shake
	if cut_slash_2: cut_slash_2.position -= shake
	
	if elapsed >= duration:
		_detonate_vacuum_implosion()
		queue_free()

func _detonate_vacuum_implosion() -> void:
	if is_inside_tree() and get_parent():
		# Sound / Shockwave / Damage in 4.5m radius
		var enemies := get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if not is_instance_valid(e) or not ("global_position" in e):
				continue
			var d: float = (e.global_position - global_position).length()
			if d <= 4.8:
				if e.has_node("Hurtbox3D"):
					var hb = e.get_node("Hurtbox3D") as Hurtbox3D
					if hb:
						var dmg = DamageData.new(damage, DamageData.DamageType.WIND, caster)
						hb.take_damage(dmg)
				if "velocity" in e:
					e.velocity += (e.global_position - global_position).normalized() * 16.0
