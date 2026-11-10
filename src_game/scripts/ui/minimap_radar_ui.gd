class_name MinimapRadarUI
extends Control

# ==============================================================================
# MINIMAP RADAR UI - LA BÀN MA THUẬT THỜI GIAN THỰC (Argons Directive 08 Task 8.5)
# Quét người chơi, quái thường, Boss/Elite, Lõi nguyên tố và Cổng dịch chuyển
# ==============================================================================

@export var radar_world_radius: float = 38.0 # Bán kính quét 38m quanh nhân vật

func _ready() -> void:
	name = "MinimapRadarUI"
	custom_minimum_size = Vector2(190, 190)
	size = Vector2(190, 190)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.46

	# 1. Nền la bàn ma thuật bán trong suốt & Vòng đồng tâm
	draw_circle(center, radius, Color(0.04, 0.06, 0.10, 0.82))
	draw_arc(center, radius * 0.5, 0.0, TAU, 36, Color(0.3, 0.45, 0.65, 0.3), 1.0)
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.92, 0.76, 0.35, 0.95), 2.5) # Viền vàng cổ ngữ

	# Dấu chữ thập hướng la bàn
	draw_line(center - Vector2(radius * 0.9, 0), center + Vector2(radius * 0.9, 0), Color(0.4, 0.55, 0.7, 0.25), 1.0)
	draw_line(center - Vector2(0, radius * 0.9), center + Vector2(0, radius * 0.9), Color(0.4, 0.55, 0.7, 0.25), 1.0)

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or not is_instance_valid(player):
		return
	var p_pos := player.global_position

	# 2. Vẽ Cổng Dịch Chuyển (🌀 Vòng xoáy lam)
	for portal in get_tree().get_nodes_in_group("portal_gate"):
		if portal is Node3D and is_instance_valid(portal):
			var pt := _world_to_radar(p_pos, (portal as Node3D).global_position, center, radius)
			draw_circle(pt, 5.5, Color(0.2, 0.85, 1.0, 0.95))
			draw_arc(pt, 7.5, 0.0, TAU, 16, Color(0.7, 0.95, 1.0, 0.9), 1.5)

	# 3. Vẽ Lõi Nguyên Tố (🔶 Điểm vàng rực)
	for core in get_tree().get_nodes_in_group("elemental_core"):
		if core is Node3D and is_instance_valid(core):
			var pt := _world_to_radar(p_pos, (core as Node3D).global_position, center, radius)
			draw_circle(pt, 4.5, Color(1.0, 0.82, 0.2, 1.0))

	# 4. Vẽ Hạt Tinh Thể EXP (🔹 Điểm xanh ngọc nhỏ)
	for exp_node in get_tree().get_nodes_in_group("exp_crystals"):
		if exp_node is Node3D and is_instance_valid(exp_node):
			var pt := _world_to_radar(p_pos, (exp_node as Node3D).global_position, center, radius)
			draw_circle(pt, 2.2, Color(0.3, 0.9, 1.0, 0.85))

	# 5. Vẽ Quái Thường (🔴 Chấm đỏ) & Boss/Tinh Anh (💀 Điểm đỏ lớn viền vàng)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D and is_instance_valid(enemy):
			var e_node := enemy as Node3D
			var pt := _world_to_radar(p_pos, e_node.global_position, center, radius)
			var is_boss_or_elite: bool = e_node.is_in_group("boss") or (e_node.get("is_elite") == true) or (e_node.get("max_hp") != null and float(e_node.get("max_hp")) >= 250.0)
			if is_boss_or_elite:
				draw_circle(pt, 6.5, Color(1.0, 0.15, 0.2, 1.0))
				draw_arc(pt, 8.0, 0.0, TAU, 16, Color(1.0, 0.88, 0.3, 1.0), 1.8)
			else:
				draw_circle(pt, 3.2, Color(0.95, 0.25, 0.25, 0.9))

	# 6. Vẽ Người Chơi Ở Tâm (🟢 Mũi tên xanh lá chỉ hướng nhìn)
	draw_circle(center, 4.5, Color(0.2, 1.0, 0.45, 1.0))
	var aim_dir := Vector3.FORWARD
	if "aim_direction" in player:
		aim_dir = player.aim_direction
	var aim_2d := Vector2(aim_dir.x, aim_dir.z).rotated(deg_to_rad(-45.0)).normalized()
	draw_line(center, center + aim_2d * 11.0, Color(0.3, 1.0, 0.5, 1.0), 2.2)

func _world_to_radar(origin: Vector3, target: Vector3, center: Vector2, radius: float) -> Vector2:
	var diff := Vector2(target.x - origin.x, target.z - origin.z)
	# Xoay -45 độ để khớp với Camera Isometric
	var rotated := diff.rotated(deg_to_rad(-45.0))
	var norm := (rotated / radar_world_radius)
	if norm.length() > 0.92:
		norm = norm.normalized() * 0.92
	return center + norm * radius
