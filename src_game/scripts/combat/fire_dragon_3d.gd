class_name FireDragon3D
extends Node3D

# ==============================================================================
# INFERNO DRAGON 3D - IGNIS ULTIMATE (PHÍM Q) - HỎA LONG CUỒNG NỘ
# Argons Directive 08 Task 8.1 & 8.2 (Sửa lỗi bậc thang trắng & cháy sáng)
# 1 Rồng Lửa 3D uốn lượn hình sin, đầu rồng góc cạnh, đuôi lửa GPUTrail 5.0m
# ==============================================================================

const GPUTrailScript = preload("res://addons/GPUTrail/GPUTrail3D.gd")

var speed: float = 16.0
var lifetime: float = 2.8
var elapsed: float = 0.0
var damage: float = 65.0
var base_direction: Vector3 = Vector3.FORWARD
var wave_frequency: float = 5.0
var wave_amplitude: float = 1.4

var head_mesh: MeshInstance3D = null
var caster: Node3D = null
var pierced_enemies: Array[Node3D] = []

func setup(p_origin: Vector3, p_dir: Vector3, p_caster: Node3D = null) -> void:
	position = p_origin
	position.y = maxf(position.y, 1.05) # Muzzle height lock!
	base_direction = Vector3(p_dir.x, 0.0, p_dir.z).normalized()
	caster = p_caster
	
	if base_direction.length_squared() > 0.01:
		look_at(global_position + base_direction, Vector3.UP)
		
	# 1. 3D Faceted Dragon Head (ArrayMesh built with SurfaceTool)
	head_mesh = MeshInstance3D.new()
	head_mesh.mesh = _build_dragon_head_mesh()
	
	var mat := StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(1.0, 0.45, 0.1)
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.55, 0.15)
	mat.emission_energy_multiplier = 3.0 # Clamped safe emission!
	head_mesh.material_override = mat
	add_child(head_mesh)
	
	# 2. Glowing Eyes
	var eye_left := _create_dragon_eye(Vector3(-0.35, 0.25, 0.6))
	var eye_right := _create_dragon_eye(Vector3(0.35, 0.25, 0.6))
	head_mesh.add_child(eye_left)
	head_mesh.add_child(eye_right)
	
	# 3. Dynamic OmniLight3D
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.15)
	light.light_energy = 2.8
	light.omni_range = 7.5
	add_child(light)
	
	# 4. GPUTrail Dragon Body Ribbon (5.0m tail)
	var tail = GPUTrailScript.new()
	tail.name = "DragonBodyTrail"
	tail.length = 36
	
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 0.2, 0.0, 0.0), Color(1.0, 0.5, 0.05, 0.8), Color(1.0, 0.9, 0.3, 1.0)])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var grad_tex = GradientTexture1D.new()
	grad_tex.gradient = grad
	tail.color_ramp = grad_tex
	
	var cv = Curve.new()
	cv.add_point(Vector2(0.0, 0.2))
	cv.add_point(Vector2(0.5, 1.2))
	cv.add_point(Vector2(1.0, 1.6))
	var cv_tex = CurveTexture.new()
	cv_tex.curve = cv
	tail.curve = cv_tex
	
	add_child(tail)

func _create_dragon_eye(offset: Vector3) -> MeshInstance3D:
	var eye := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	eye.mesh = sphere
	eye.position = offset
	var e_mat := StandardMaterial3D.new()
	e_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	e_mat.albedo_color = Color(1.0, 1.0, 0.4)
	eye.material_override = e_mat
	return eye

func _build_dragon_head_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Faceted Dragon Snout & Horns
	var snout := Vector3(0.0, 0.0, 1.4)
	var top_head := Vector3(0.0, 0.6, 0.0)
	var jaw := Vector3(0.0, -0.4, 0.3)
	var left_horn := Vector3(-0.6, 0.8, -0.8)
	var right_horn := Vector3(0.6, 0.8, -0.8)
	var left_cheek := Vector3(-0.7, 0.0, 0.0)
	var right_cheek := Vector3(0.7, 0.0, 0.0)
	
	# Top snout facets
	_add_tri(st, snout, top_head, left_cheek)
	_add_tri(st, snout, right_cheek, top_head)
	# Bottom jaw facets
	_add_tri(st, snout, left_cheek, jaw)
	_add_tri(st, snout, jaw, right_cheek)
	# Horns facets
	_add_tri(st, top_head, left_horn, left_cheek)
	_add_tri(st, top_head, right_cheek, right_horn)
	
	st.generate_normals()
	return st.commit()

func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var norm := (b - a).cross(c - a).normalized()
	st.set_normal(norm)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)

func _physics_process(delta: float) -> void:
	elapsed += delta
	
	# Sinusoidal lateral slither motion
	var lateral_dir := Vector3(-base_direction.z, 0.0, base_direction.x).normalized()
	var wave_offset := lateral_dir * sin(elapsed * wave_frequency) * wave_amplitude * delta * speed
	
	global_position += (base_direction * speed * delta) + wave_offset
	
	# Check penetration damage on enemies
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e) or e in pierced_enemies:
			continue
		var to_e: Vector3 = e.global_position - global_position
		to_e.y = 0.0
		if to_e.length() <= 2.2:
			pierced_enemies.append(e)
			if e.has_node("Hurtbox3D"):
				var hb = e.get_node("Hurtbox3D") as Hurtbox3D
				if hb:
					var dmg = DamageData.new(damage, DamageData.DamageType.FIRE, caster)
					hb.take_damage(dmg)
			if "velocity" in e:
				e.velocity += base_direction * 18.0
				
	if elapsed >= lifetime:
		_detonate_and_free()

func _detonate_and_free() -> void:
	# End-of-flight shockwave explosion
	if is_inside_tree() and get_parent():
		var enemies := get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if not is_instance_valid(e) or not ("global_position" in e):
				continue
			var d: float = (e.global_position - global_position).length()
			if d <= 4.0:
				if e.has_node("Hurtbox3D"):
					var hb = e.get_node("Hurtbox3D") as Hurtbox3D
					if hb:
						var dmg = DamageData.new(damage * 0.6, DamageData.DamageType.FIRE, caster)
						hb.take_damage(dmg)
	queue_free()
