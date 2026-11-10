class_name NyxVortexTrap3D
extends Node3D

# ==============================================================================
# NYX VORTEX TRAP 3D - NYX RMB (BẪY XOÁY KHÔNG GIAN)
# Argons Directive 12 - Task 12.3
# ==============================================================================

const SynthAudio = preload("res://scripts/core/synth_audio.gd")

var caster: HeroBase3D = null
var duration: float = 3.0
var elapsed: float = 0.0
var pull_radius: float = 5.5
var pull_force: float = 7.5
var tick_timer: float = 0.0
var tick_rate: float = 0.3
var tick_damage: float = 5.0

var layer_twirl: MeshInstance3D = null
var layer_circle: MeshInstance3D = null
var light: OmniLight3D = null

func setup(p_caster: HeroBase3D, p_target_pos: Vector3) -> void:
	caster = p_caster
	global_position = p_target_pos
	global_position.y = 0.04
	
	_create_vortex_layers()
	_create_light()
	
	SynthAudio.play_cast()

func _create_vortex_layers() -> void:
	var twirl_tex = ResourceLoader.load("res://assets/vfx_textures/twirl_02.png") as Texture2D
	var circle_tex = ResourceLoader.load("res://assets/vfx_textures/circle_03.png") as Texture2D
	
	# Layer 1: twirl_02.png (rotates clockwise)
	layer_twirl = MeshInstance3D.new()
	var q1 = QuadMesh.new()
	q1.size = Vector2(5.5, 5.5)
	q1.orientation = PlaneMesh.FACE_Y
	layer_twirl.mesh = q1
	
	var mat1 = StandardMaterial3D.new()
	mat1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat1.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat1.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat1.albedo_color = Color(0.0, 0.9, 1.0, 0.9) # Cyan
	mat1.albedo_texture = twirl_tex
	layer_twirl.material_override = mat1
	layer_twirl.position.y = 0.04
	add_child(layer_twirl)
	
	# Layer 2: circle_03.png (rotates counter-clockwise)
	layer_circle = MeshInstance3D.new()
	var q2 = QuadMesh.new()
	q2.size = Vector2(4.8, 4.8)
	q2.orientation = PlaneMesh.FACE_Y
	layer_circle.mesh = q2
	
	var mat2 = StandardMaterial3D.new()
	mat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat2.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat2.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat2.albedo_color = Color(0.65, 0.2, 1.0, 0.85) # Mystic Purple
	mat2.albedo_texture = circle_tex
	layer_circle.material_override = mat2
	layer_circle.position.y = 0.05
	add_child(layer_circle)

func _create_light() -> void:
	light = OmniLight3D.new()
	light.light_color = Color(0.3, 0.6, 1.0)
	light.omni_range = 4.0
	light.light_energy = 0.8
	add_child(light)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
		
	# Rotate layers in opposite directions
	if layer_twirl:
		layer_twirl.rotate_y(delta * 2.8)
	if layer_circle:
		layer_circle.rotate_y(-delta * 3.4)
		
	# Suction and slow logic
	_apply_vortex_suction(delta)
	
	# Tick damage
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		_apply_tick_damage()
		
	# Fade out near end
	var rem = duration - elapsed
	if rem < 0.6:
		var fade = rem / 0.6
		if layer_twirl and layer_twirl.material_override:
			layer_twirl.material_override.albedo_color.a = fade * 0.9
		if layer_circle and layer_circle.material_override:
			layer_circle.material_override.albedo_color.a = fade * 0.85
		if light:
			light.light_energy = fade * 2.2

func _apply_vortex_suction(delta: float) -> void:
	if not is_inside_tree(): return
	var space_state = get_world_3d().direct_space_state
	if not space_state: return
	
	var shape_query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = pull_radius
	shape_query.shape = sphere
	shape_query.transform = Transform3D(Basis(), global_position)
	shape_query.collision_mask = 4 # Hurtbox layer
	
	var hits = space_state.intersect_shape(shape_query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var enemy_body = collider.owner if collider.owner else collider.get_parent()
			if enemy_body and "velocity" in enemy_body:
				var pull_dir = (global_position - collider.global_position)
				pull_dir.y = 0.0
				var dist = pull_dir.length()
				if dist > 0.1:
					enemy_body.velocity += pull_dir.normalized() * (pull_force * (1.0 - dist / pull_radius) * delta * 12.0)
					
				# Apply 60% slow (movement multiplier 0.40)
				if "speed_multiplier" in enemy_body:
					enemy_body.speed_multiplier = min(enemy_body.speed_multiplier, 0.40)
				elif "move_speed" in enemy_body and not enemy_body.has_meta("original_speed"):
					enemy_body.set_meta("original_speed", enemy_body.move_speed)
					enemy_body.move_speed *= 0.40
					var tw = create_tween()
					tw.tween_interval(3.0)
					tw.tween_callback(func():
						if is_instance_valid(enemy_body) and enemy_body.has_meta("original_speed"):
							enemy_body.move_speed = enemy_body.get_meta("original_speed")
							enemy_body.remove_meta("original_speed")
					)

func _apply_tick_damage() -> void:
	if not is_inside_tree(): return
	var space_state = get_world_3d().direct_space_state
	if not space_state: return
	
	var shape_query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = pull_radius
	shape_query.shape = sphere
	shape_query.transform = Transform3D(Basis(), global_position)
	shape_query.collision_mask = 4 # Hurtbox layer
	
	var hits = space_state.intersect_shape(shape_query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			collider.take_damage(DamageData.new(tick_damage, "astral", Vector3.ZERO, "slow", 3.0, caster))
			
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
		if to_enemy.length() <= pull_radius:
			if enemy_node.has_method("take_damage"):
				enemy_node.take_damage(DamageData.new(tick_damage, "astral", Vector3.ZERO, "slow", 3.0, caster))
			elif enemy_node.has_node("Hurtbox3D"):
				var hb = enemy_node.get_node("Hurtbox3D")
				if hb and hb is Hurtbox3D:
					hb.take_damage(DamageData.new(tick_damage, "astral", Vector3.ZERO, "slow", 3.0, caster))
