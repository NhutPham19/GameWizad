class_name FusionScaldingSteam3D
extends Node3D

# ==============================================================================
# FUSION 4: BÃO HƠI NƯỚC ÁP SUẤT (SCALDING STEAM) - LỬA + NƯỚC (PHÍM E)
# Vụ nổ sương mù hơi nước áp suất cao bán trong suốt làm chậm 45% + đốt cháy
# ==============================================================================

var duration: float = 4.0
var elapsed: float = 0.0
var steam_radius: float = 6.0
var tick_timer: float = 0.0
var tick_rate: float = 0.3
var tick_damage: float = 7.0
var burst_damage: float = 25.0

var steam_cloud_mesh: MeshInstance3D = null

func setup(p_pos: Vector3) -> void:
	global_position = p_pos
	
	# Translucent expanding steam hemisphere
	steam_cloud_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 2.0
	sphere.height = 3.0
	steam_cloud_mesh.mesh = sphere
	steam_cloud_mesh.position.y = 1.0
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 0.92, 1.0, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.2) # Scalding heat core
	mat.emission_energy_multiplier = 2.0
	steam_cloud_mesh.material_override = mat
	add_child(steam_cloud_mesh)
	
	# Initial burst damage on spawn
	_initial_burst()

func _initial_burst() -> void:
	if not is_inside_tree() or not get_world_3d():
		return
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = steam_radius * 0.8
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			collider.take_damage(DamageData.new(burst_damage, "fire", Vector3.ZERO, "burn", 3.0, self))

func _physics_process(delta: float) -> void:
	elapsed += delta
	
	# Expanding pulse
	if steam_cloud_mesh:
		var target_scale = lerp(1.0, steam_radius / 2.0, min(1.0, elapsed / 1.0))
		steam_cloud_mesh.scale = Vector3(target_scale, target_scale * 0.7, target_scale)
		steam_cloud_mesh.rotate_y(delta * 0.5)
	
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		_apply_tick_steam()
		
	if elapsed >= duration:
		queue_free()

func _apply_tick_steam() -> void:
	if not is_inside_tree() or not get_world_3d():
		return
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = steam_radius
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			# High temp burn + wet slow
			collider.take_damage(DamageData.new(tick_damage, "water", Vector3.ZERO, "slow", 1.5, self))
			var enemy = collider.get_parent()
			if enemy is CharacterBody3D:
				enemy.velocity *= 0.55
