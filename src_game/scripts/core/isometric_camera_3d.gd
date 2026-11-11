class_name IsometricCamera3D
extends Camera3D

# ==============================================================================
# ISOMETRIC CAMERA 3D - DIRECTIVE 14 & 15A
# Pitch -48°, Yaw 45°, Smooth follow locked to Player
# Exact 3D Physics Raycast on Collision Layer 1 (Multi-Tier Ground / Stairs)
# ==============================================================================

@export var target_node: Node3D = null
@export var follow_speed: float = 8.5
@export var camera_distance: float = 24.0
@export var ortho_size: float = 16.0

var shake_intensity: float = 0.0
var shake_decay: float = 5.0
var _faded_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	add_to_group("camera")
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = ortho_size
	rotation_degrees = Vector3(-48.0, 45.0, 0.0)

func _process(delta: float) -> void:
	if shake_intensity > 0.0:
		shake_intensity = max(0.0, shake_intensity - (shake_decay * delta))

	if not is_instance_valid(target_node):
		var p = get_tree().get_first_node_in_group("player") as Node3D
		if p and is_instance_valid(p) and p.visible:
			target_node = p

	if not is_instance_valid(target_node):
		return

	# Isometric offset locked to target center with pitch -48°, yaw 45°
	var rad_pitch := deg_to_rad(48.0)
	var rad_yaw := deg_to_rad(45.0)
	var offset_y := sin(rad_pitch) * camera_distance
	var horiz := cos(rad_pitch) * camera_distance
	var offset_x := sin(rad_yaw) * horiz
	var offset_z := cos(rad_yaw) * horiz
	var isometric_offset := Vector3(offset_x, offset_y, offset_z)
	var desired_pos: Vector3 = target_node.global_position + isometric_offset

	if shake_intensity > 0.0:
		var shake_offset := Vector3(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		desired_pos += shake_offset

	# Tối ưu độ mượt tần số quét cao 144Hz–240Hz: Frame-rate independent exponential smoothing
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired_pos, weight)

func _physics_process(_delta: float) -> void:
	_update_occlusion_fade()

func _update_occlusion_fade() -> void:
	if not is_instance_valid(target_node):
		_restore_faded_meshes()
		return

	var target_chest: Vector3 = target_node.global_position + Vector3(0.0, 1.0, 0.0)
	var cam_pos: Vector3 = global_position
	var diff: Vector3 = target_chest - cam_pos
	var dist := diff.length()
	if dist < 0.5:
		_restore_faded_meshes()
		return

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(cam_pos, target_chest, 1)
	if target_node is CollisionObject3D:
		query.exclude = [(target_node as CollisionObject3D).get_rid()]

	var hit := space_state.intersect_ray(query)
	var new_faded: Array[MeshInstance3D] = []

	if not hit.is_empty():
		var hit_pos: Vector3 = hit["position"]
		if hit_pos.distance_to(target_chest) > 0.4:
			var collider = hit["collider"]
			if collider is Node:
				var node := collider as Node
				var meshes: Array[Node] = []
				if node is MeshInstance3D:
					meshes.append(node)
				meshes.append_array(node.find_children("*", "MeshInstance3D", true, false))
				if node.get_parent() != null and node.get_parent() != get_tree().current_scene:
					meshes.append_array(node.get_parent().find_children("*", "MeshInstance3D", true, false))

				for m in meshes:
					var mi := m as MeshInstance3D
					if is_instance_valid(mi) and not new_faded.has(mi):
						new_faded.append(mi)
						mi.transparency = 0.65

	for old_m in _faded_meshes:
		if is_instance_valid(old_m) and not new_faded.has(old_m):
			old_m.transparency = 0.0

	_faded_meshes = new_faded

func _restore_faded_meshes() -> void:
	for m in _faded_meshes:
		if is_instance_valid(m):
			m.transparency = 0.0
	_faded_meshes.clear()

func add_screen_shake(amount: float) -> void:
	shake_intensity = clamp(shake_intensity + amount, 0.0, 1.5)

func add_shake(amount: float) -> void:
	add_screen_shake(amount)

## Tọa độ chuột chính xác trên sàn/cầu thang bằng 3D Physics Raycast (Directive 14 & 15A)
func get_accurate_ground_cursor_pos(viewport: Viewport, fallback_y: float = 0.0) -> Vector3:
	var mouse_pos := viewport.get_mouse_position()
	var ray_origin := project_ray_origin(mouse_pos)
	var ray_dir := project_ray_normal(mouse_pos)
	var ray_end := ray_origin + ray_dir * 500.0
	
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1) # Layer 1: Ground/Stairs/Walls
	var hit := space_state.intersect_ray(query)
	if not hit.is_empty():
		return hit["position"]
		
	var plane := Plane(Vector3.UP, fallback_y)
	var pos = plane.intersects_ray(ray_origin, ray_dir)
	return pos if pos != null else Vector3.ZERO
