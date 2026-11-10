class_name FusionQuagmireSpikes3D
extends Node3D

# ==============================================================================
# FUSION 10: ĐẦM LẦY THẠCH NHŨ (QUAGMIRE SPIKES) - ĐẤT + NƯỚC (PHÍM E)
# Vùng bùn nước dưới sàn giữ chân quái rồi đâm hàng loạt gai đá/thạch nhũ 3D từ dưới lên
# ==============================================================================

var duration: float = 3.6
var elapsed: float = 0.0
var spike_delay: float = 1.0
var spikes_erupted: bool = false
var quagmire_radius: float = 5.5
var tick_timer: float = 0.0
var tick_rate: float = 0.25
var tick_damage: float = 5.0
var spike_damage: float = 48.0

var mud_pool_mesh: MeshInstance3D = null
var spikes: Array[MeshInstance3D] = []

func setup(p_pos: Vector3) -> void:
	global_position = p_pos
	
	# Dark Mud / Swamp Decal Pool Mesh
	mud_pool_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = quagmire_radius
	cyl.bottom_radius = quagmire_radius
	cyl.height = 0.06
	mud_pool_mesh.mesh = cyl
	mud_pool_mesh.position.y = 0.03
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.25, 0.2, 0.14, 0.85)
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.35, 0.2) # Murky greenish-brown swamp glow
	mat.emission_energy_multiplier = 1.2
	mud_pool_mesh.material_override = mat
	add_child(mud_pool_mesh)

func _physics_process(delta: float) -> void:
	elapsed += delta
	
	# Mud bubble pulse
	if mud_pool_mesh:
		mud_pool_mesh.scale = Vector3(1.0 + sin(elapsed * 6.0) * 0.03, 1.0, 1.0 + cos(elapsed * 6.0) * 0.03)
		
	# Mud snare ticks
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		_process_mud_snare()
		
	# Erupt spikes at delay
	if elapsed >= spike_delay and not spikes_erupted:
		spikes_erupted = true
		_erupt_stalagmite_spikes()
		
	if elapsed >= duration:
		queue_free()

func _process_mud_snare() -> void:
	if not is_inside_tree() or not get_world_3d():
		return
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = quagmire_radius
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			collider.take_damage(DamageData.new(tick_damage, "earth", Vector3.ZERO, "slow", 1.0, self))
			var enemy = collider.get_parent()
			if enemy is CharacterBody3D:
				enemy.velocity *= 0.2 # 80% heavy snare

func _erupt_stalagmite_spikes() -> void:
	if not is_inside_tree() or not get_world_3d():
		return
	
	# 7 Sharp Earth & Stalagmite Spikes erupt from ground
	for i in range(7):
		var spike = MeshInstance3D.new()
		var prism = PrismMesh.new()
		prism.size = Vector3(0.8, 3.2, 0.8)
		spike.mesh = prism
		var angle = i * (TAU / 7.0)
		var rad = randf_range(1.0, quagmire_radius * 0.75)
		spike.position = Vector3(cos(angle) * rad, 1.6, sin(angle) * rad)
		spike.rotation = Vector3(randf_range(-0.15, 0.15), randf_range(0, TAU), randf_range(-0.15, 0.15))
		
		var s_mat = StandardMaterial3D.new()
		s_mat.albedo_color = Color(0.38, 0.32, 0.26)
		s_mat.emission_enabled = true
		s_mat.emission = Color(0.4, 0.7, 0.5)
		s_mat.emission_energy_multiplier = 2.0
		spike.material_override = s_mat
		add_child(spike)
		spikes.append(spike)
		
	# Deal massive burst damage and knockup
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = quagmire_radius
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var knockup = Vector3.UP * 12.0
			collider.take_damage(DamageData.new(spike_damage, "earth", knockup, "stun", 1.8, self))
