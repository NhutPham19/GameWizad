class_name ArcaneCircle3D
extends Node3D

# ==============================================================================
# ARCANE CIRCLE 3D / ASTRAL THUNDER ZONE - AETHEL RMB (Task 8.1 & 8.2)
# Pháp trận cổ ngữ Tinh Tú xoay tròn (vfx_astral_thunder_zone.gdshader)
# Giáng các cột sét zic-zac từ Y = 8.0m xuống làm choáng quái. Tuyệt đối KHÔNG Magenta!
# ==============================================================================

const ThunderZoneShader = preload("res://shaders/vfx_astral_thunder_zone.gdshader")

var duration: float = 4.2
var elapsed: float = 0.0
var strike_timer: float = 0.0
var strike_interval: float = 0.45
var strike_damage: float = 24.0
var circle_radius: float = 4.0

var caster: Node3D = null
var circle_mesh: MeshInstance3D = null

func setup(p_pos: Vector3, p_caster: Node3D = null) -> void:
	global_position = p_pos
	global_position.y = 0.03 # Float just above ground
	caster = p_caster
	
	# 1. 3D Glowing Rune Circle (PlaneMesh with polar coordinate shader)
	circle_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(circle_radius * 2.0, circle_radius * 2.0)
	circle_mesh.mesh = plane
	
	var mat := ShaderMaterial.new()
	mat.shader = ThunderZoneShader
	mat.set_shader_parameter("core_color", Color(0.4, 0.75, 1.0, 1.0))
	mat.set_shader_parameter("outer_color", Color(0.65, 0.3, 1.0, 1.0))
	mat.set_shader_parameter("emission_strength", 2.6) # Clamped safely!
	circle_mesh.material_override = mat
	add_child(circle_mesh)
	
	# 2. Dynamic OmniLight3D
	var light := OmniLight3D.new()
	light.light_color = Color(0.5, 0.7, 1.0)
	light.light_energy = 2.4
	light.omni_range = circle_radius * 1.8
	light.position.y = 1.0
	add_child(light)

func _process(delta: float) -> void:
	elapsed += delta
	strike_timer += delta
	
	# Slow tactical rotation of rune circle
	if circle_mesh:
		circle_mesh.rotate_y(delta * 0.6)
		
	# Periodic lightning strikes from above
	if strike_timer >= strike_interval:
		strike_timer = 0.0
		_call_sky_lightning_strike()
		
	if elapsed >= duration:
		queue_free()

func _call_sky_lightning_strike() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var targets_hit := 0
	
	for e in enemies:
		if not is_instance_valid(e) or not ("global_position" in e):
			continue
		var to_e: Vector3 = e.global_position - global_position
		to_e.y = 0.0
		if to_e.length() <= circle_radius:
			_spawn_vertical_lightning(e.global_position)
			if e.has_node("Hurtbox3D"):
				var hb = e.get_node("Hurtbox3D") as Hurtbox3D
				if hb:
					var dmg = DamageData.new(strike_damage, DamageData.DamageType.LIGHTNING, caster)
					hb.take_damage(dmg)
			if "velocity" in e:
				e.velocity *= 0.1 # Stun effect: halt velocity!
			targets_hit += 1
			if targets_hit >= 3:
				break
				
	# If no enemy in circle, strike center ground for ambience
	if targets_hit == 0:
		_spawn_vertical_lightning(global_position + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2)))

func _spawn_vertical_lightning(hit_pos: Vector3) -> void:
	# Vertical lightning bolt beam from Y = 8.0 down to ground
	var bolt := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.12
	cyl.height = 8.0
	bolt.mesh = cyl
	bolt.position = hit_pos + Vector3(0.0, 4.0, 0.0)
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.8, 0.95, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.8, 1.0)
	mat.emission_energy_multiplier = 3.2
	bolt.material_override = mat
	
	get_parent().add_child(bolt)
	
	var tw := bolt.create_tween()
	tw.tween_property(bolt, "scale:x", 0.0, 0.15)
	tw.parallel().tween_property(bolt, "scale:z", 0.0, 0.15)
	tw.tween_callback(bolt.queue_free)
