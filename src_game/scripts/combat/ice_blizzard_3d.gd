class_name IceBlizzard3D
extends Node3D

# ==============================================================================
# ICE BLIZZARD 3D - NEREUS ULTIMATE (PHÍM Q) - TUYỆT ĐỐI KHÔNG ĐỘ
# Tạo cơn sóng thần băng giá quét hình quạt 180°, đóng băng cứng (Freeze 3s)
# ==============================================================================

var wave_radius: float = 9.0
var wave_damage: float = 35.0
var caster_direction: Vector3 = Vector3.FORWARD
var caster: Node3D = null

const VFXMasterFactory = preload("res://scripts/combat/vfx_master_factory.gd")

func setup(p_origin: Vector3, p_dir: Vector3, p_caster: Node3D = null) -> void:
	global_position = p_origin
	caster_direction = p_dir.normalized()
	caster = p_caster
	
	# 3D Visual Frost Fan Mesh with Uber Shader
	var mesh_inst = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = wave_radius
	cyl.bottom_radius = wave_radius * 0.4
	cyl.height = 0.25
	mesh_inst.mesh = cyl
	mesh_inst.position.y = 0.2
	
	var mat = VFXMasterFactory.create_uber_material(Color(1.0, 1.0, 1.0), Color(0.2, 0.8, 1.0), 5.5, Vector2(2.5, 1.0), Vector2(-1.5, 2.0), 0.15)
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	# Dynamic Lighting & Ground Cracks
	VFXMasterFactory.attach_dynamic_light(self, Color(0.3, 0.85, 1.0), 8.5, 3.0)
	if get_parent():
		VFXMasterFactory.spawn_ground_cracks(get_parent(), global_position, Color(0.3, 0.9, 1.0), wave_radius * 0.8, 2.8)
		VFXMasterFactory.spawn_distortion_shockwave(get_parent(), global_position, wave_radius)
	
	# Expand and freeze logic
	var tween = create_tween()
	mesh_inst.scale = Vector3(0.1, 1.0, 0.1)
	tween.tween_property(mesh_inst, "scale", Vector3(1.0, 1.0, 1.0), 0.3)
	tween.tween_interval(0.4)
	tween.tween_property(mesh_inst, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
	
	_freeze_enemies_in_fan()

func _freeze_enemies_in_fan() -> void:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = wave_radius
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4 # Hurtbox layer
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var to_target = (collider.global_position - global_position).normalized()
			to_target.y = 0.0
			# 180 degree fan check (dot product >= 0.0)
			if to_target.dot(caster_direction) >= -0.1:
				collider.take_damage(DamageData.new(wave_damage, "ice", Vector3.ZERO, "freeze", 3.0, caster))
