class_name SlashArc3D
extends Node3D

const VFXImpactExplosion3D = preload("res://scripts/combat/vfx_impact_explosion_3d.gd")
const SynthAudio = preload("res://scripts/core/synth_audio.gd")
const VFXMasterFactory = preload("res://scripts/combat/vfx_master_factory.gd")

# ==============================================================================
# SLASH ARC 3D - MELEE WEAPON SWING & CLEAVE SYSTEM
# Wizard of Legend 2 Melee Combat Architecture
# ==============================================================================

@export var damage: float = 20.0
@export var element: String = "wind"
@export var radius: float = 2.6
@export var arc_degrees: float = 120.0
@export var knockback_force: float = 7.0
@export var slash_color: Color = Color(0.2, 1.0, 0.8)
@export var combo_step: int = 1
@export var custom_texture: Texture2D = null
@export var emission_energy: float = 2.4
@export var spawn_blade_sparks: bool = false

var caster: Node3D = null
var aim_direction: Vector3 = Vector3.FORWARD
var visual_mesh: MeshInstance3D = null
var duration: float = 0.22
var elapsed: float = 0.0
var hit_targets: Array[Node3D] = []

func setup(p_caster: Node3D, p_aim_dir: Vector3, p_damage: float, p_elem: String, p_color: Color, p_radius: float = 2.6, p_arc_deg: float = 120.0, p_combo: int = 1, p_tex: Texture2D = null, p_emission: float = 2.4, p_sparks: bool = false) -> void:
	caster = p_caster
	aim_direction = p_aim_dir.normalized()
	damage = p_damage
	element = p_elem
	slash_color = p_color
	radius = p_radius
	arc_degrees = p_arc_deg
	combo_step = p_combo
	custom_texture = p_tex
	emission_energy = p_emission
	spawn_blade_sparks = p_sparks
	
	global_position = p_caster.global_position + Vector3(0, 1.05, 0) # Locked muzzle height
	
	if aim_direction.length_squared() > 0.001 and not aim_direction.is_equal_approx(Vector3.UP):
		transform.basis = Basis.looking_at(aim_direction, Vector3.UP)
		
	_create_arc_visual()
	_perform_melee_hit_detection()
	_play_slash_sound()

func _create_arc_visual() -> void:
	visual_mesh = MeshInstance3D.new()
	var arr_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	var segments = 36 # Argons Directive 08: 36 segments for ultra-smooth spline!
	var half_angle = deg_to_rad(arc_degrees * 0.5)
	var start_angle = -half_angle
	var angle_step = (half_angle * 2.0) / float(segments)
	
	# Alternate swing direction based on combo step
	var flip = -1.0 if (combo_step % 2 == 0) else 1.0
	
	for i in range(segments + 1):
		var frac = float(i) / float(segments)
		var taper = sin(frac * PI) # Taper blade width to razor tip at both ends!
		var inner_r = radius * (0.65 - 0.35 * taper)
		var outer_r = radius * (0.85 + 0.15 * taper)
		
		var ang = (start_angle + i * angle_step) * flip
		var cos_a = sin(ang) # Local X is right, local -Z is forward
		var sin_a = -cos(ang)
		
		# Inner vertex (fade to transparent)
		vertices.append(Vector3(cos_a * inner_r, 0.0, sin_a * inner_r))
		uvs.append(Vector2(frac, 0.0))
		colors.append(Color(slash_color.r, slash_color.g, slash_color.b, 0.0))
		
		# Outer vertex (sharp razor edge)
		vertices.append(Vector3(cos_a * outer_r, 0.0, sin_a * outer_r))
		uvs.append(Vector2(frac, 1.0))
		colors.append(Color(slash_color.r, slash_color.g, slash_color.b, 0.85 * taper))
		
	for i in range(segments):
		var i0 = i * 2
		var i1 = i * 2 + 1
		var i2 = (i + 1) * 2
		var i3 = (i + 1) * 2 + 1
		
		indices.append(i0)
		indices.append(i1)
		indices.append(i2)
		
		indices.append(i2)
		indices.append(i1)
		indices.append(i3)
		
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	visual_mesh.mesh = arr_mesh
	
	if custom_texture:
		var st_mat = StandardMaterial3D.new()
		st_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		st_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		st_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		st_mat.albedo_texture = custom_texture
		st_mat.albedo_color = slash_color
		st_mat.emission_enabled = true
		st_mat.emission = slash_color
		st_mat.emission_energy_multiplier = emission_energy
		visual_mesh.material_override = st_mat
	else:
		# Clamped emission power 2.4 (prevents blinding bloom blowout!)
		var mat = VFXMasterFactory.create_uber_material(Color(1.0, 1.0, 1.0), slash_color, 2.4, Vector2(2.0, 0.5), Vector2(-1.2, 0.9), 0.18)
		visual_mesh.material_override = mat
		
	add_child(visual_mesh)
	
	# Layer 2: Dynamic OmniLight3D (moderate energy, clamped <= 1.0 to prevent bloom blowout)
	VFXMasterFactory.attach_dynamic_light(self, slash_color, 2.8, 0.8)
	
	# Sparks along the blade (Kenney spark_01 & flame_02)
	if spawn_blade_sparks:
		_spawn_blade_particles()
	
	# Finisher slam creates ground cracks & screen shake
	if combo_step >= 3 or arc_degrees >= 300.0:
		VFXMasterFactory.spawn_ground_cracks(get_parent(), global_position, slash_color, radius * 0.9, 1.8)
		VFXMasterFactory.spawn_distortion_shockwave(get_parent(), global_position, radius * 1.1)
	
	# Smooth scale up tween
	var tw = create_tween().set_parallel(true)
	tw.tween_property(visual_mesh, "scale", Vector3(1.15, 1.0, 1.15), duration)
	tw.chain().tween_callback(queue_free)

func _spawn_blade_particles() -> void:
	var spark_tex = ResourceLoader.load("res://assets/vfx_textures/spark_01.png") as Texture2D
	var flame_tex = ResourceLoader.load("res://assets/vfx_textures/flame_02.png") as Texture2D
	if not spark_tex: return
	
	var parts = GPUParticles3D.new()
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = aim_direction
	p_mat.spread = 45.0
	p_mat.initial_velocity_min = 2.0
	p_mat.initial_velocity_max = 5.0
	p_mat.gravity = Vector3(0, -1.5, 0)
	p_mat.scale_min = 0.15
	p_mat.scale_max = 0.35
	p_mat.color = slash_color
	parts.process_material = p_mat
	
	var qmesh = QuadMesh.new()
	qmesh.size = Vector2(0.25, 0.25)
	var qmat = StandardMaterial3D.new()
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qmat.albedo_texture = spark_tex
	qmesh.material = qmat
	parts.draw_pass_1 = qmesh
	parts.amount = 16
	parts.lifetime = 0.25
	parts.one_shot = true
	parts.emitting = true
	add_child(parts)

func _play_slash_sound() -> void:
	if ResourceLoader.exists("res://assets/audio/slash.wav"):
		var stream = ResourceLoader.load("res://assets/audio/slash.wav")
		if stream:
			var player = AudioStreamPlayer3D.new()
			player.stream = stream
			player.max_distance = 25.0
			player.volume_db = -2.0
			add_child(player)
			player.play()
			player.finished.connect(player.queue_free)
			return
	SynthAudio.play_player_hit()

func _perform_melee_hit_detection() -> void:
	if not is_inside_tree():
		return
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return
		
	# Sphere shape cast centered at caster's position
	var shape_query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = radius * 1.1
	shape_query.shape = sphere
	shape_query.transform = global_transform
	shape_query.collision_mask = 4 # Hurtbox layer
	
	var half_arc_rad = deg_to_rad(arc_degrees * 0.5)
	var forward_dir = aim_direction
	forward_dir.y = 0.0
	forward_dir = forward_dir.normalized()
	
	var results = space_state.intersect_shape(shape_query)
	for res in results:
		var collider = res.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var enemy_body = collider.owner if collider.owner else collider.get_parent()
			if enemy_body in hit_targets:
				continue
				
			var to_enemy = (collider.global_position - global_position)
			to_enemy.y = 0.0
			var dist = to_enemy.length()
			
			if dist <= radius and dist > 0.001:
				var angle = forward_dir.angle_to(to_enemy.normalized())
				if angle <= half_arc_rad:
					hit_targets.append(enemy_body)
					_apply_melee_hit(collider, to_enemy.normalized())
					
	# Also hit destructible props within arc
	_hit_destructibles(forward_dir, half_arc_rad)
	
	# Direct Spatial Hit Scan across group "enemies" (Directive 13 Task 13.4)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_node := enemy as Node3D
		if not enemy_node or enemy_node in hit_targets:
			continue
		var to_enemy = (enemy_node.global_position - global_position)
		to_enemy.y = 0.0
		var dist = to_enemy.length()
		if dist <= (radius + 0.5) and dist > 0.001:
			var angle = forward_dir.angle_to(to_enemy.normalized())
			if angle <= (half_arc_rad + 0.3):
				hit_targets.append(enemy_node)
				if enemy_node.has_method("take_damage"):
					enemy_node.take_damage(DamageData.new(damage, element, to_enemy.normalized() * knockback_force, "none", 0.0, caster))
				elif enemy_node.has_node("Hurtbox3D"):
					var hb = enemy_node.get_node("Hurtbox3D")
					if hb and hb is Hurtbox3D:
						_apply_melee_hit(hb, to_enemy.normalized())

func _apply_melee_hit(hurtbox: Hurtbox3D, hit_dir: Vector3) -> void:
	var kb = hit_dir * knockback_force
	hurtbox.take_damage(DamageData.new(damage, element, kb, "none", 0.0, caster))
	
	# Spawn impact sparks
	if get_parent():
		var impact = VFXImpactExplosion3D.new()
		get_parent().add_child(impact)
		impact.setup(hurtbox.global_position, slash_color, 1.6)

func _hit_destructibles(forward_dir: Vector3, half_arc_rad: float) -> void:
	var props = get_tree().get_nodes_in_group("destructible_props")
	for prop in props:
		if not is_instance_valid(prop):
			continue
		var prop_node := prop as Node3D
		if not prop_node:
			continue
		var to_prop = prop_node.global_position - global_position
		to_prop.y = 0.0
		var dist = to_prop.length()
		if dist <= radius and dist > 0.001:
			var angle = forward_dir.angle_to(to_prop.normalized())
			if angle <= half_arc_rad:
				var cur_hp: float = prop.get_meta("hp") if prop.has_meta("hp") else 20.0
				cur_hp -= damage
				if cur_hp <= 0.0:
					_break_prop(prop)
				else:
					prop.set_meta("hp", cur_hp)

func _break_prop(prop: Object) -> void:
	var node := prop as Node3D
	if not node:
		return
	var parent_node := node.get_parent()
	var spawn_pos := node.global_position
	var orb_script = load("res://scripts/elements/health_orb_3d.gd")
	if parent_node and orb_script:
		var orb = orb_script.new()
		parent_node.add_child(orb)
		orb.setup(spawn_pos + Vector3(0, 0.4, 0), 15.0)
	if node.name.begins_with("Collider_") and node.get_parent():
		node.get_parent().queue_free()
	else:
		node.queue_free()
