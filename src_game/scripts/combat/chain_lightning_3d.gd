class_name ChainLightning3D
extends Node3D

# ==============================================================================
# CHAIN LIGHTNING 3D - AETHEL RMB (Song Lôi Liên Kết)
# Phóng 2 luồng sét vàng rực rỡ nối trực tiếp sang 2 quái gần trỏ chuột, gây stun nhẹ và rút máu trong 2.5s
# ==============================================================================

var duration: float = 2.5
var elapsed: float = 0.0
var tick_timer: float = 0.0
var tick_rate: float = 0.25
var tick_damage: float = 5.5

var source_node: Node3D = null
var target_positions: Array[Vector3] = []
var beam_meshes: Array[MeshInstance3D] = []

const VFXMasterFactory = preload("res://scripts/combat/vfx_master_factory.gd")

func setup(p_source: Node3D, p_targets: Array[Vector3]) -> void:
	source_node = p_source
	target_positions = p_targets
	
	for i in range(target_positions.size()):
		var beam = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.08
		beam.mesh = cyl
		
		var mat = VFXMasterFactory.create_uber_material(Color(1.0, 1.0, 0.7), Color(0.85, 0.35, 1.0), 6.5, Vector2(5.0, 1.0), Vector2(-4.0, 2.0), 0.12)
		beam.material_override = mat
		
		add_child(beam)
		beam_meshes.append(beam)
		
		VFXMasterFactory.attach_dynamic_light(beam, Color(0.9, 0.75, 1.0), 4.5, 2.5)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration or not is_instance_valid(source_node):
		queue_free()
		return
		
	var start_pos = source_node.global_position + Vector3(0, 0.9, 0)
	for i in range(beam_meshes.size()):
		if i < target_positions.size():
			var end_pos = target_positions[i]
			var mid = (start_pos + end_pos) * 0.5
			var beam = beam_meshes[i]
			beam.global_position = mid
			
			var diff = end_pos - start_pos
			var length = diff.length()
			if length > 0.01:
				var cyl: CylinderMesh = beam.mesh
				cyl.height = length
				beam.look_at(end_pos, Vector3.UP)
				beam.rotate_object_local(Vector3.RIGHT, PI / 2.0)
				
	# Tick damage
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		_apply_lightning_tick()

func _apply_lightning_tick() -> void:
	var space_state = get_world_3d().direct_space_state
	for tgt in target_positions:
		var shape_query = PhysicsShapeQueryParameters3D.new()
		var sphere = SphereShape3D.new()
		sphere.radius = 1.5
		shape_query.shape = sphere
		shape_query.transform = Transform3D(Basis(), tgt)
		shape_query.collision_mask = 4 # Hurtbox layer
		
		var hits = space_state.intersect_shape(shape_query)
		for h in hits:
			var collider = h.collider
			if collider is Hurtbox3D and collider.team != "hero":
				collider.take_damage(DamageData.new(tick_damage, "lightning", Vector3.ZERO, "stun", 0.3, source_node))
