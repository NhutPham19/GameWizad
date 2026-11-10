class_name Tornado3D
extends Node3D

# ==============================================================================
# TORNADO 3D / BLADE CYCLONE - ZEPHYR RMB (Task 8.1 & 8.2)
# 3 phễu gió chân không rỗng tâm (cap_top/bottom = false) + lưỡi kiếm khí xoay
# Nhìn rõ nhân vật bên trong, emission = 2.4, TUYỆT ĐỐI KHÔNG CHÁY SÁNG LÓA MẮT!
# ==============================================================================

var duration: float = 3.2
var elapsed: float = 0.0
var pull_radius: float = 4.8
var pull_strength: float = 8.5
var tick_timer: float = 0.0
var tick_rate: float = 0.22
var tick_damage: float = 7.5

var funnel_rings: Array[MeshInstance3D] = []
var caster: Node3D = null

func setup(p_target_pos: Vector3, p_caster: Node3D = null) -> void:
	global_position = p_target_pos
	caster = p_caster
	
	# 3 Hollow funnel rings of increasing radius
	var radii := [[0.8, 1.6, 2.2], [1.2, 2.2, 3.2], [1.6, 2.8, 4.0]]
	for i in range(3):
		var ring := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = radii[i][1]
		cyl.bottom_radius = radii[i][0]
		cyl.height = radii[i][2]
		cyl.cap_top = false
		cyl.cap_bottom = false
		ring.mesh = cyl
		ring.position.y = cyl.height * 0.5
		
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		# Soft jade wind with high transparency (70% see-through)
		mat.albedo_color = Color(0.3, 0.95, 0.65, 0.28 + i * 0.06)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.85, 0.5)
		mat.emission_energy_multiplier = 2.4 # Clamped safe emission!
		ring.material_override = mat
		
		add_child(ring)
		funnel_rings.append(ring)
		
	# Dynamic OmniLight3D (moderate energy)
	var light := OmniLight3D.new()
	light.light_color = Color(0.3, 0.9, 0.6)
	light.light_energy = 1.8
	light.omni_range = 6.0
	light.position.y = 1.5
	add_child(light)

func _physics_process(delta: float) -> void:
	elapsed += delta
	
	# Counter-rotating funnel layers
	for i in range(funnel_rings.size()):
		var dir := 1.0 if (i % 2 == 0) else -1.0
		funnel_rings[i].rotate_y(delta * (12.0 + i * 4.0) * dir)
		
	tick_timer += delta
	var should_deal_damage := false
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		should_deal_damage = true
		
	# Vacuum vortex: pull all enemies towards center
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not ("global_position" in enemy):
			continue
		var to_center: Vector3 = global_position - enemy.global_position
		to_center.y = 0.0
		var dist := to_center.length()
		
		if dist <= pull_radius and dist > 0.1:
			var pull_dir := to_center.normalized()
			if "velocity" in enemy:
				enemy.velocity += pull_dir * pull_strength * delta * 50.0
				
			if should_deal_damage and enemy.has_node("Hurtbox3D"):
				var hurt = enemy.get_node("Hurtbox3D") as Hurtbox3D
				if hurt:
					var dmg = DamageData.new(tick_damage, DamageData.DamageType.WIND, caster)
					hurt.take_damage(dmg)
					
	if elapsed >= duration:
		queue_free()
