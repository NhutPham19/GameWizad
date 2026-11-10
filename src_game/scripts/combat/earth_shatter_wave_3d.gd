class_name EarthShatterWave3D
extends Node3D

# ==============================================================================
# EARTH SHATTER WAVE 3D - KAEL ULTIMATE (PHÍM Q) - ĐỊA CHẤN PHÁ SƠN
# Đập đất tạo ra 2 dải sóng đá tảng 3D trồi lên liên tiếp dài 12m, nghiền nát & hất tung
# ==============================================================================

var direction: Vector3 = Vector3.FORWARD
var total_segments: int = 8
var spawned_segments: int = 0
var segment_spacing: float = 1.5
var spawn_timer: float = 0.0
var spawn_interval: float = 0.08
var wave_damage: float = 38.0

var caster: Node3D = null

func setup(p_origin: Vector3, p_dir: Vector3, p_caster: Node3D = null) -> void:
	global_position = p_origin
	direction = p_dir.normalized()
	caster = p_caster

func _process(delta: float) -> void:
	if spawned_segments < total_segments:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			_spawn_rock_pillar_pair(spawned_segments)
			spawned_segments += 1
	else:
		# Cleanup after pillars decay
		if get_child_count() == 0:
			queue_free()

func _spawn_rock_pillar_pair(idx: int) -> void:
	var forward_offset = direction * (idx * segment_spacing + 1.0)
	var right = Vector3(-direction.z, 0.0, direction.x).normalized()
	
	# Left and right dual wave pillars
	_create_single_pillar(global_position + forward_offset - right * 0.9)
	_create_single_pillar(global_position + forward_offset + right * 0.9)

const VFXMasterFactory = preload("res://scripts/combat/vfx_master_factory.gd")

func _create_single_pillar(pillar_pos: Vector3) -> void:
	var pillar = Node3D.new()
	pillar.global_position = pillar_pos
	add_child(pillar)
	
	# Ground Cracks & Shockwave
	if get_parent():
		VFXMasterFactory.spawn_ground_cracks(get_parent(), pillar_pos, Color(0.9, 0.65, 0.25), 1.6, 2.2)
	
	# 3D Faceted Rock Spire (6-sided jagged stone, NO BoxMesh!)
	var mesh_inst = MeshInstance3D.new()
	var spire = CylinderMesh.new()
	spire.top_radius = 0.15
	spire.bottom_radius = 0.65
	spire.height = 2.4
	spire.radial_segments = 6 # Faceted crystal/rock look
	mesh_inst.mesh = spire
	mesh_inst.position.y = 1.2
	mesh_inst.rotation.y = randf_range(0, TAU)
	mesh_inst.rotation.z = randf_range(-0.15, 0.15)
	
	var mat = VFXMasterFactory.create_uber_material(Color(1.0, 0.9, 0.6), Color(0.85, 0.6, 0.2), 2.8, Vector2(0.5, 0.5), Vector2(-0.4, 0.4), 0.3)
	mesh_inst.material_override = mat
	pillar.add_child(mesh_inst)
	
	# Dynamic Light
	VFXMasterFactory.attach_dynamic_light(pillar, Color(0.9, 0.7, 0.3), 3.5, 2.0)
	
	# Hitbox
	var hitbox = Hitbox3D.new()
	hitbox.damage_amount = wave_damage
	hitbox.element_type = "earth"
	hitbox.knockback_force = 10.0
	hitbox.team = "hero"
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.3, 2.4, 1.3)
	col.shape = shape
	col.position.y = 1.1
	hitbox.add_child(col)
	pillar.add_child(hitbox)
	
	# Pillar lifespan timer: sink into ground and free
	var tween = create_tween()
	tween.tween_property(mesh_inst, "position:y", 1.1, 0.08).from(-1.5)
	tween.tween_interval(1.2)
	tween.tween_property(mesh_inst, "position:y", -2.5, 0.4)
	tween.tween_callback(pillar.queue_free)
