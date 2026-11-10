class_name EarthBarrier3D
extends Node3D

# ==============================================================================
# EARTH BARRIER 3D - KAEL RMB (Gai Đá Bọc Thân - Argons Directive 08 Task 8.1)
# 8 mũi gai đá thạch anh nhọn hoắt đa diện trồi lên quanh chân & khiên đá xoay
# Tăng 35% giáp, phản đòn và đẩy lùi quái chạm vào. Tuyệt đối KHÔNG dùng BoxMesh!
# ==============================================================================

var duration: float = 5.0
var elapsed: float = 0.0
var max_shield: float = 80.0
var current_shield: float = 80.0
var burst_damage: float = 32.0

var owner_hero: HeroBase3D = null
var rock_spikes: Array[MeshInstance3D] = []
var rock_mat: StandardMaterial3D = null

func setup(p_hero: HeroBase3D) -> void:
	owner_hero = p_hero
	_init_material()
	
	# Spawn 8 faceted jagged rock spikes around Kael
	var num_spikes := 8
	var angle_step := TAU / float(num_spikes)
	
	for i in range(num_spikes):
		var angle := i * angle_step
		var spike_mesh := _build_jagged_rock_spike_mesh(0.42, 1.25)
		var spike_inst := MeshInstance3D.new()
		spike_inst.mesh = spike_mesh
		spike_inst.material_override = rock_mat
		
		# Position on ring around hero
		var radius := 1.45
		spike_inst.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		# Tilt outward 25 degrees
		spike_inst.rotation = Vector3(sin(angle) * 0.44, -angle, cos(angle) * 0.44)
		
		add_child(spike_inst)
		rock_spikes.append(spike_inst)
		
		# Emerge tween from underground
		var start_y := -1.0
		var target_y := spike_inst.position.y
		spike_inst.position.y = start_y
		var tw := create_tween()
		tw.tween_property(spike_inst, "position:y", target_y, 0.22 + i * 0.03).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _init_material() -> void:
	rock_mat = StandardMaterial3D.new()
	rock_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	rock_mat.albedo_color = Color(0.28, 0.22, 0.18) # Dark granite rock
	rock_mat.roughness = 0.85
	rock_mat.metallic = 0.15
	rock_mat.emission_enabled = true
	rock_mat.emission = Color(0.95, 0.45, 0.1) # Magma glowing veins
	rock_mat.emission_energy_multiplier = 2.4 # Safe clamped emission!

func _build_jagged_rock_spike_mesh(radius: float, height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var apex := Vector3(0.0, height, 0.0)
	var sides := 6
	var base_pts: Array[Vector3] = []
	
	for s in range(sides):
		var a := (float(s) / float(sides)) * TAU
		# Slight irregular variation for authentic jagged look
		var r_var := radius * (0.85 + 0.3 * sin(a * 3.0))
		base_pts.append(Vector3(cos(a) * r_var, 0.0, sin(a) * r_var))
		
	# Side triangles connecting base to apex
	for s in range(sides):
		var next_s := (s + 1) % sides
		var normal := (base_pts[next_s] - base_pts[s]).cross(apex - base_pts[s]).normalized()
		st.set_normal(normal)
		st.set_uv(Vector2(float(s) / float(sides), 0.0))
		st.add_vertex(base_pts[s])
		st.set_uv(Vector2(float(next_s) / float(sides), 0.0))
		st.add_vertex(base_pts[next_s])
		st.set_uv(Vector2(0.5, 1.0))
		st.add_vertex(apex)
		
	st.generate_normals()
	return st.commit()

func _process(delta: float) -> void:
	elapsed += delta
	if not is_instance_valid(owner_hero) or elapsed >= duration:
		_burst_and_free()
		return
		
	global_position = owner_hero.global_position
	
	# Slow tactical rotation of defensive rock ring
	rotate_y(delta * 1.8)
	
	# Push back any mob trying to touch Kael
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e) or not ("global_position" in e):
			continue
		var to_e: Vector3 = e.global_position - global_position
		to_e.y = 0.0
		var dist := to_e.length()
		if dist <= 2.2 and dist > 0.1:
			var push := to_e.normalized()
			if "velocity" in e:
				e.velocity += push * 14.0
			if e.has_node("Hurtbox3D"):
				var hb = e.get_node("Hurtbox3D") as Hurtbox3D
				if hb:
					var dmg = DamageData.new(8.0 * delta, DamageData.DamageType.PHYSICAL, owner_hero)
					hb.take_damage(dmg)

func absorb_damage(amount: float) -> float:
	current_shield -= amount
	if current_shield <= 0.0:
		var excess := -current_shield
		_burst_and_free()
		return excess
	return 0.0

func _burst_and_free() -> void:
	# Shatter into physics shrapnel shockwave
	if is_inside_tree() and get_parent():
		var enemies := get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if not is_instance_valid(e) or not ("global_position" in e):
				continue
			var d: float = (e.global_position - global_position).length()
			if d <= 4.5:
				if e.has_node("Hurtbox3D"):
					var hb = e.get_node("Hurtbox3D") as Hurtbox3D
					if hb:
						var dmg = DamageData.new(burst_damage, DamageData.DamageType.EARTH, owner_hero)
						hb.take_damage(dmg)
				if "velocity" in e:
					e.velocity += (e.global_position - global_position).normalized() * 18.0
	queue_free()
