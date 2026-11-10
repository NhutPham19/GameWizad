class_name FusionBlizzardMaelstrom3D
extends Node3D

# ==============================================================================
# FUSION 7: BÃO TUYẾT VĨNH CỬU (BLIZZARD MAELSTROM) - GIÓ + NƯỚC (PHÍM E)
# Lốc xoáy băng lam đóng băng cứng quái vật sau 1.5s (Freeze 3.0s)
# ==============================================================================

var duration: float = 3.8
var elapsed: float = 0.0
var freeze_delay: float = 1.5
var freeze_triggered: bool = false
var blizzard_radius: float = 6.0
var tick_timer: float = 0.0
var tick_rate: float = 0.25
var tick_damage: float = 6.0
var freeze_damage: float = 35.0

var maelstrom_mesh: MeshInstance3D = null
var ice_crystals: Array[MeshInstance3D] = []

func setup(p_pos: Vector3) -> void:
	global_position = p_pos
	
	# Ice Blue / White Rotating Cone
	maelstrom_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 3.0
	cyl.bottom_radius = 0.8
	cyl.height = 4.0
	maelstrom_mesh.mesh = cyl
	maelstrom_mesh.position.y = 2.0
	
	var shader = load("res://shaders/vfx_elemental_energy.gdshader") as Shader
	if shader:
		var smat = ShaderMaterial.new()
		smat.shader = shader
		smat.set_shader_parameter("core_color", Color(0.4, 0.85, 1.0, 0.8))
		smat.set_shader_parameter("rim_color", Color(0.9, 0.98, 1.0, 1.0))
		smat.set_shader_parameter("emission_energy", 5.5)
		smat.set_shader_parameter("scroll_speed_v", 3.2)
		maelstrom_mesh.material_override = smat
	else:
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.65, 0.9, 1.0, 0.65)
		mat.emission_enabled = true
		mat.emission = Color(0.4, 0.85, 1.0)
		mat.emission_energy_multiplier = 3.2
		maelstrom_mesh.material_override = mat
	add_child(maelstrom_mesh)
	
	# Ground frost circle
	var ground_ring = MeshInstance3D.new()
	var cyl_ring = CylinderMesh.new()
	cyl_ring.top_radius = blizzard_radius
	cyl_ring.bottom_radius = blizzard_radius
	cyl_ring.height = 0.05
	ground_ring.mesh = cyl_ring
	ground_ring.position.y = 0.05
	var g_mat = StandardMaterial3D.new()
	g_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g_mat.albedo_color = Color(0.5, 0.85, 1.0, 0.35)
	ground_ring.material_override = g_mat
	add_child(ground_ring)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if maelstrom_mesh:
		maelstrom_mesh.rotate_y(delta * 16.0)
		
	# Tick slow damage
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		_process_blizzard_tick()
		
	# Trigger Hard Freeze at 1.5s
	if elapsed >= freeze_delay and not freeze_triggered:
		freeze_triggered = true
		_trigger_deep_freeze()
		
	if elapsed >= duration:
		queue_free()

func _process_blizzard_tick() -> void:
	if not is_inside_tree() or not get_world_3d():
		return
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = blizzard_radius
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			collider.take_damage(DamageData.new(tick_damage, "ice", Vector3.ZERO, "slow", 1.5, self))
			var enemy = collider.get_parent()
			if enemy is CharacterBody3D:
				enemy.velocity *= 0.3 # 70% slow

func _trigger_deep_freeze() -> void:
	if not is_inside_tree() or not get_world_3d():
		return
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = blizzard_radius * 1.1
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4
	
	# Spawn 6 sharp 3D Ice Shards jutting from ground
	for i in range(6):
		var shard = MeshInstance3D.new()
		var prism = PrismMesh.new()
		prism.size = Vector3(0.6, 2.5, 0.6)
		shard.mesh = prism
		var angle = i * (PI / 3.0)
		var rad = randf_range(1.5, blizzard_radius * 0.8)
		shard.position = Vector3(cos(angle) * rad, 1.25, sin(angle) * rad)
		shard.rotation = Vector3(randf_range(-0.3, 0.3), randf_range(0, TAU), randf_range(-0.3, 0.3))
		
		var s_mat = StandardMaterial3D.new()
		s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		s_mat.albedo_color = Color(0.8, 0.95, 1.0, 0.85)
		s_mat.emission_enabled = true
		s_mat.emission = Color(0.5, 0.9, 1.0)
		s_mat.emission_energy_multiplier = 3.5
		shard.material_override = s_mat
		add_child(shard)
		
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			collider.take_damage(DamageData.new(freeze_damage, "ice", Vector3.ZERO, "freeze", 3.0, self))
