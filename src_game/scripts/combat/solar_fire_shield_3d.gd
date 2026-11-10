class_name SolarFireShield3D
extends Node3D

# ==============================================================================
# SOLAR FIRE SHIELD 3D - SOLARIS RMB (KHIÊN LỬA THÁI DƯƠNG)
# Argons Directive 12 - Task 12.2
# ==============================================================================

var caster: HeroBase3D = null
var duration: float = 3.2
var elapsed: float = 0.0
var radius: float = 4.5
var damage: float = 28.0
var knockback_power: float = 12.0

var ring_1: MeshInstance3D = null
var ring_2: MeshInstance3D = null
var vortex_mesh: MeshInstance3D = null
var light: OmniLight3D = null

func setup(p_caster: HeroBase3D) -> void:
	caster = p_caster
	global_position = p_caster.global_position
	
	_create_rune_circles()
	_create_fire_vortex()
	_create_scorch_decal()
	_apply_knockback_and_damage()
	_apply_virtual_shield()
	
	# Light (clamped <= 1.0 to prevent bloom blowout)
	light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.65, 0.15)
	light.omni_range = 3.5
	light.light_energy = 1.0
	add_child(light)

func _create_rune_circles() -> void:
	var circle_tex = ResourceLoader.load("res://assets/vfx_textures/circle_01.png") as Texture2D
	var magic_tex = ResourceLoader.load("res://assets/vfx_textures/magic_02.png") as Texture2D
	
	# Layer 1: circle_01.png
	ring_1 = MeshInstance3D.new()
	var q1 = QuadMesh.new()
	q1.size = Vector2(4.2, 4.2)
	q1.orientation = PlaneMesh.FACE_Y
	ring_1.mesh = q1
	
	var mat1 = StandardMaterial3D.new()
	mat1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat1.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat1.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat1.albedo_color = Color(1.0, 0.72, 0.15, 0.9)
	mat1.albedo_texture = circle_tex
	ring_1.material_override = mat1
	ring_1.position.y = 0.04
	add_child(ring_1)
	
	# Layer 2: magic_02.png
	ring_2 = MeshInstance3D.new()
	var q2 = QuadMesh.new()
	q2.size = Vector2(3.5, 3.5)
	q2.orientation = PlaneMesh.FACE_Y
	ring_2.mesh = q2
	
	var mat2 = StandardMaterial3D.new()
	mat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat2.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat2.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat2.albedo_color = Color(1.0, 0.45, 0.05, 0.85)
	mat2.albedo_texture = magic_tex
	ring_2.material_override = mat2
	ring_2.position.y = 0.05
	add_child(ring_2)

func _create_fire_vortex() -> void:
	var twirl_tex = ResourceLoader.load("res://assets/vfx_textures/twirl_01.png") as Texture2D
	var flame_tex = ResourceLoader.load("res://assets/vfx_textures/flame_04.png") as Texture2D
	
	vortex_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 2.4
	cyl.bottom_radius = 1.6
	cyl.height = 2.6
	cyl.radial_segments = 24
	cyl.rings = 2
	cyl.cap_top = false
	cyl.cap_bottom = false
	vortex_mesh.mesh = cyl
	
	var vmat = StandardMaterial3D.new()
	vmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	vmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	vmat.albedo_color = Color(1.0, 0.6, 0.1, 0.75)
	vmat.albedo_texture = twirl_tex if twirl_tex else flame_tex
	vortex_mesh.material_override = vmat
	vortex_mesh.position.y = 1.3
	add_child(vortex_mesh)

func _create_scorch_decal() -> void:
	var scorch_tex = ResourceLoader.load("res://assets/vfx_textures/scorch_02.png") as Texture2D
	if not scorch_tex: return
	
	var decal_mesh = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(3.6, 3.6)
	q.orientation = PlaneMesh.FACE_Y
	decal_mesh.mesh = q
	
	var smat = StandardMaterial3D.new()
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.cull_mode = BaseMaterial3D.CULL_DISABLED
	smat.albedo_color = Color(0.12, 0.08, 0.04, 0.8)
	smat.albedo_texture = scorch_tex
	decal_mesh.material_override = smat
	decal_mesh.position.y = 0.02
	if get_parent():
		get_parent().add_child(decal_mesh)
		decal_mesh.global_position = global_position + Vector3(0, 0.02, 0)
		var tw = decal_mesh.create_tween()
		tw.tween_interval(duration)
		tw.tween_property(smat, "albedo_color:a", 0.0, 1.5)
		tw.tween_callback(decal_mesh.queue_free)

func _apply_knockback_and_damage() -> void:
	if not is_inside_tree(): return
	var space_state = get_world_3d().direct_space_state
	if not space_state: return
	
	var shape_query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = radius
	shape_query.shape = sphere
	shape_query.transform = Transform3D(Basis(), global_position)
	shape_query.collision_mask = 4 # Hurtbox layer
	
	var hits = space_state.intersect_shape(shape_query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var enemy_pos = collider.global_position
			var push_dir = (enemy_pos - global_position)
			push_dir.y = 0.0
			if push_dir.length_squared() < 0.01:
				push_dir = Vector3.FORWARD
			else:
				push_dir = push_dir.normalized()
			
			var kb = push_dir * knockback_power
			collider.take_damage(DamageData.new(damage, "solar", kb, "burn", 2.0, caster))
			
	# Direct Spatial Query across group "enemies" (Directive 13 Task 13.4)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_node := enemy as Node3D
		if not enemy_node or enemy_node == caster:
			continue
		var to_enemy = (enemy_node.global_position - global_position)
		to_enemy.y = 0.0
		var dist = to_enemy.length()
		if dist <= radius:
			var push_dir = to_enemy.normalized() if dist > 0.01 else Vector3.FORWARD
			var kb = push_dir * knockback_power
			if enemy_node.has_method("take_damage"):
				enemy_node.take_damage(DamageData.new(damage, "solar", kb, "burn", 2.0, caster))
			elif enemy_node.has_node("Hurtbox3D"):
				var hb = enemy_node.get_node("Hurtbox3D")
				if hb and hb is Hurtbox3D:
					hb.take_damage(DamageData.new(damage, "solar", kb, "burn", 2.0, caster))

func _apply_virtual_shield() -> void:
	if caster and is_instance_valid(caster):
		if "current_shield" in caster:
			caster.current_shield = min(caster.current_shield + 40.0, 80.0)
		caster.invulnerable_timer = max(caster.invulnerable_timer, 0.8)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
		
	# Follow caster smoothly if alive
	if is_instance_valid(caster):
		global_position = caster.global_position
		
	# Rotate rune circles in opposite directions
	if ring_1:
		ring_1.rotate_y(delta * 1.8)
	if ring_2:
		ring_2.rotate_y(-delta * 2.4)
	if vortex_mesh:
		vortex_mesh.rotate_y(delta * 4.5)
		
	# Fade out towards end
	var rem = duration - elapsed
	if rem < 0.8:
		var fade = rem / 0.8
		if ring_1 and ring_1.material_override:
			ring_1.material_override.albedo_color.a = fade * 0.9
		if ring_2 and ring_2.material_override:
			ring_2.material_override.albedo_color.a = fade * 0.85
		if vortex_mesh and vortex_mesh.material_override:
			vortex_mesh.material_override.albedo_color.a = fade * 0.75
		if light:
			light.light_energy = fade * 2.4
