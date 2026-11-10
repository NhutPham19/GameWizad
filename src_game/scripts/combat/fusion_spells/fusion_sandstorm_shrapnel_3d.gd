class_name FusionSandstormShrapnel3D
extends Node3D

# ==============================================================================
# FUSION 6: BÃO CÁT SA MẠC (SANDSTORM SHRAPNEL) - GIÓ + ĐẤT (PHÍM E)
# Vòng xoáy cát đá vàng cam đẩy lùi và bào mòn máu quái, phá vỡ giáp
# ==============================================================================

var duration: float = 3.8
var elapsed: float = 0.0
var sand_radius: float = 6.5
var push_force: float = 12.0
var tick_timer: float = 0.0
var tick_rate: float = 0.25
var tick_damage: float = 9.0

var main_cone: MeshInstance3D = null
var rock_debris: Array[MeshInstance3D] = []

func setup(p_pos: Vector3) -> void:
	global_position = p_pos
	
	# Swirling Sand Cylinder
	main_cone = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 3.2
	cyl.bottom_radius = 1.0
	cyl.height = 3.8
	main_cone.mesh = cyl
	main_cone.position.y = 1.9
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.9, 0.72, 0.35, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.95, 0.65, 0.2)
	mat.emission_energy_multiplier = 2.5
	main_cone.material_override = mat
	add_child(main_cone)
	
	# 4 Orbiting sharp rock fragments
	for i in range(4):
		var rock = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.4, 0.4, 0.4)
		rock.mesh = box
		var angle = i * (PI / 2.0)
		rock.position = Vector3(cos(angle) * 2.2, 1.2 + i * 0.4, sin(angle) * 2.2)
		var r_mat = StandardMaterial3D.new()
		r_mat.albedo_color = Color(0.45, 0.32, 0.18)
		rock.material_override = r_mat
		add_child(rock)
		rock_debris.append(rock)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if main_cone:
		main_cone.rotate_y(delta * 14.0)
		
	for i in range(rock_debris.size()):
		var rock = rock_debris[i]
		var angle = elapsed * 10.0 + i * (PI / 2.0)
		var rad = 2.2 + sin(elapsed * 4.0 + i) * 0.5
		rock.position = Vector3(cos(angle) * rad, rock.position.y, sin(angle) * rad)
		rock.rotate_x(delta * 6.0)
		rock.rotate_y(delta * 8.0)
		
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		_process_sandstorm_ticks(delta)
		
	if elapsed >= duration:
		queue_free()

func _process_sandstorm_ticks(delta: float) -> void:
	if not is_inside_tree() or not get_world_3d():
		return
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = sand_radius
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4
	
	var hits = space_state.intersect_shape(query)
	for h in hits:
		var collider = h.collider
		if collider is Hurtbox3D and collider.team != "hero":
			var enemy = collider.get_parent()
			if enemy is CharacterBody3D:
				var push = (enemy.global_position - global_position).normalized()
				push.y = 0.0
				enemy.velocity += push * push_force * 3.0
			collider.take_damage(DamageData.new(tick_damage, "earth", Vector3.ZERO, "vulnerable", 2.0, self))
