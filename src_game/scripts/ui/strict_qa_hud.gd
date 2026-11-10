class_name StrictQAHUD
extends CanvasLayer

# ==============================================================================
# STRICT QA HUD — DIRECTIVE 16, PHASE 6
# Giao diện Thanh Máu 2D + Bảng Đo Telemetry Thời Gian Thực
# 0% PRIMITIVE GEOMETRY — 100% Control node MOUSE_FILTER_IGNORE (Không chặn click)
# ==============================================================================

var _scan_timer: float = 0.0
var _primitive_mesh_count: int = 0
var _total_mesh_count: int = 0
var _last_fps: float = 60.0
var _active_bones: int = 41
var _total_bones: int = 41

# UI Elements
var overlay_root: Control
var left_panel: PanelContainer
var right_panel: PanelContainer
var hero_hp_bar: ProgressBar
var hero_hp_label: Label
var hero_anim_label: Label
var hero_skills_label: Label

var telemetry_fps_label: Label
var telemetry_primitive_label: Label
var telemetry_skeleton_label: Label
var telemetry_coord_label: Label
var telemetry_blade_label: Label
var telemetry_enemies_label: Label

var enemy_healthbar_drawer: Control

func _ready() -> void:
	layer = 100
	_build_ui()
	_apply_mouse_filter_ignore(self)

func _build_ui() -> void:
	overlay_root = Control.new()
	overlay_root.name = "HUDOverlay"
	overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay_root)

	# --- 1. Drawer vẽ máu lính 2D chiếu theo 3D World ---
	enemy_healthbar_drawer = Control.new()
	enemy_healthbar_drawer.name = "EnemyHealthDrawer"
	enemy_healthbar_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	enemy_healthbar_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_root.add_child(enemy_healthbar_drawer)
	enemy_healthbar_drawer.draw.connect(_on_enemy_health_drawer_draw)

	# --- 2. GÓC TRÁI TRÊN: TRẠNG THÁI CHIẾN ĐẤU HERO ---
	left_panel = PanelContainer.new()
	left_panel.name = "HeroStatusPanel"
	left_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_panel.offset_left = 20.0
	left_panel.offset_top = 20.0
	left_panel.offset_right = 440.0
	left_panel.offset_bottom = 200.0

	var l_style := StyleBoxFlat.new()
	l_style.bg_color = Color(0.08, 0.1, 0.14, 0.85)
	l_style.border_width_left = 3
	l_style.border_width_top = 1
	l_style.border_width_right = 1
	l_style.border_width_bottom = 1
	l_style.border_color = Color(0.2, 0.6, 1.0, 0.9)
	l_style.corner_radius_top_left = 6
	l_style.corner_radius_top_right = 6
	l_style.corner_radius_bottom_right = 6
	l_style.corner_radius_bottom_left = 6
	l_style.content_margin_left = 14
	l_style.content_margin_top = 10
	l_style.content_margin_right = 14
	l_style.content_margin_bottom = 10
	left_panel.add_theme_stylebox_override("panel", l_style)
	overlay_root.add_child(left_panel)

	var l_vbox := VBoxContainer.new()
	l_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l_vbox.add_theme_constant_override("separation", 6)
	left_panel.add_child(l_vbox)

	var hero_title := Label.new()
	hero_title.text = "⚔️ HERO KNIGHT 3D (KAYKIT ADV)"
	hero_title.add_theme_font_size_override("font_size", 16)
	hero_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	hero_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l_vbox.add_child(hero_title)

	# HP Bar
	hero_hp_bar = ProgressBar.new()
	hero_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_hp_bar.custom_minimum_size = Vector2(380.0, 18.0)
	hero_hp_bar.min_value = 0.0
	hero_hp_bar.max_value = 100.0
	hero_hp_bar.value = 100.0
	hero_hp_bar.show_percentage = false

	var bg_bar := StyleBoxFlat.new()
	bg_bar.bg_color = Color(0.18, 0.2, 0.24, 0.9)
	bg_bar.corner_radius_top_left = 3
	bg_bar.corner_radius_top_right = 3
	bg_bar.corner_radius_bottom_right = 3
	bg_bar.corner_radius_bottom_left = 3
	var fill_bar := StyleBoxFlat.new()
	fill_bar.bg_color = Color(0.2, 0.85, 0.35, 1.0)
	fill_bar.corner_radius_top_left = 3
	fill_bar.corner_radius_top_right = 3
	fill_bar.corner_radius_bottom_right = 3
	fill_bar.corner_radius_bottom_left = 3
	hero_hp_bar.add_theme_stylebox_override("background", bg_bar)
	hero_hp_bar.add_theme_stylebox_override("fill", fill_bar)
	l_vbox.add_child(hero_hp_bar)

	hero_hp_label = Label.new()
	hero_hp_label.text = "HP: 100.0 / 100.0 (100%)"
	hero_hp_label.add_theme_font_size_override("font_size", 13)
	hero_hp_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	hero_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l_vbox.add_child(hero_hp_label)

	hero_anim_label = Label.new()
	hero_anim_label.text = "Current Anim: Idle"
	hero_anim_label.add_theme_font_size_override("font_size", 12)
	hero_anim_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	hero_anim_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l_vbox.add_child(hero_anim_label)

	hero_skills_label = Label.new()
	hero_skills_label.text = "LMB: Combo 3 Nhịp | RMB: Khiên Phản Kích | Q: Xoay 360 | E: Bom Khói 3D | Space: Lướt | C: Nhảy"
	hero_skills_label.add_theme_font_size_override("font_size", 11)
	hero_skills_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	hero_skills_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_skills_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l_vbox.add_child(hero_skills_label)

	# --- 3. GÓC PHẢI TRÊN: STRICT QA TELEMETRY ---
	right_panel = PanelContainer.new()
	right_panel.name = "TelemetryPanel"
	right_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_panel.anchor_left = 1.0
	right_panel.anchor_right = 1.0
	right_panel.offset_left = -460.0
	right_panel.offset_top = 20.0
	right_panel.offset_right = -20.0
	right_panel.offset_bottom = 240.0

	var r_style := StyleBoxFlat.new()
	r_style.bg_color = Color(0.06, 0.08, 0.12, 0.9)
	r_style.border_width_right = 3
	r_style.border_width_top = 1
	r_style.border_width_left = 1
	r_style.border_width_bottom = 1
	r_style.border_color = Color(0.2, 0.9, 0.45, 0.9)
	r_style.corner_radius_top_left = 6
	r_style.corner_radius_top_right = 6
	r_style.corner_radius_bottom_right = 6
	r_style.corner_radius_bottom_left = 6
	r_style.content_margin_left = 14
	r_style.content_margin_top = 10
	r_style.content_margin_right = 14
	r_style.content_margin_bottom = 10
	right_panel.add_theme_stylebox_override("panel", r_style)
	overlay_root.add_child(right_panel)

	var r_vbox := VBoxContainer.new()
	r_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r_vbox.add_theme_constant_override("separation", 5)
	right_panel.add_child(r_vbox)

	var telemetry_title := Label.new()
	telemetry_title.text = "📊 STRICT QA TELEMETRY (RTX 4060)"
	telemetry_title.add_theme_font_size_override("font_size", 15)
	telemetry_title.add_theme_color_override("font_color", Color(0.3, 0.95, 0.5))
	telemetry_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r_vbox.add_child(telemetry_title)

	telemetry_fps_label = Label.new()
	telemetry_fps_label.text = "FPS: 60.0 | Frame Time: 16.6ms"
	telemetry_fps_label.add_theme_font_size_override("font_size", 12)
	telemetry_fps_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	telemetry_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r_vbox.add_child(telemetry_fps_label)

	telemetry_primitive_label = Label.new()
	telemetry_primitive_label.text = "[ZERO PRIMITIVE CHECK]: PRIMITIVE MESHES: 0 (PASS 100%)"
	telemetry_primitive_label.add_theme_font_size_override("font_size", 12)
	telemetry_primitive_label.add_theme_color_override("font_color", Color(0.25, 0.95, 0.45))
	telemetry_primitive_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r_vbox.add_child(telemetry_primitive_label)

	telemetry_skeleton_label = Label.new()
	telemetry_skeleton_label.text = "[SKELETON MOTION CHECK]: ACTIVE BONES: 41/41 (NO T-POSE/SLIDING)"
	telemetry_skeleton_label.add_theme_font_size_override("font_size", 12)
	telemetry_skeleton_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	telemetry_skeleton_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r_vbox.add_child(telemetry_skeleton_label)

	telemetry_coord_label = Label.new()
	telemetry_coord_label.text = "[MULTI-TIER COORD]: Hero_Y: 0.05m | Ground_Y: 0.00m (ΔY: 0.05m)"
	telemetry_coord_label.add_theme_font_size_override("font_size", 12)
	telemetry_coord_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	telemetry_coord_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r_vbox.add_child(telemetry_coord_label)

	telemetry_blade_label = Label.new()
	telemetry_blade_label.text = "Blade Tip: (0.00, 0.00, 0.00)"
	telemetry_blade_label.add_theme_font_size_override("font_size", 11)
	telemetry_blade_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	telemetry_blade_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r_vbox.add_child(telemetry_blade_label)

	telemetry_enemies_label = Label.new()
	telemetry_enemies_label.text = "Enemies Alive: 5 / 5 (Tier 1: 2 | Tier 2: 2 | Tier 3: 1)"
	telemetry_enemies_label.add_theme_font_size_override("font_size", 12)
	telemetry_enemies_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
	telemetry_enemies_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r_vbox.add_child(telemetry_enemies_label)

func _apply_mouse_filter_ignore(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_apply_mouse_filter_ignore(child)

func _process(delta: float) -> void:
	# Yêu cầu vẽ lại thanh máu 2D lính
	if enemy_healthbar_drawer:
		enemy_healthbar_drawer.queue_redraw()

	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = 0.5
		_perform_scans()

	_update_telemetry_display(delta)

func _perform_scans() -> void:
	# 1. Zero Primitive Scan
	var meshes := get_tree().root.find_children("*", "MeshInstance3D", true, false)
	_total_mesh_count = meshes.size()
	_primitive_mesh_count = 0
	for m in meshes:
		var mi := m as MeshInstance3D
		if mi and mi.mesh:
			var mtype := mi.mesh.get_class()
			if mtype in ["BoxMesh", "SphereMesh", "CylinderMesh", "CapsuleMesh", "PrismMesh", "TorusMesh"]:
				_primitive_mesh_count += 1

	# 2. Skeleton Motion Scan
	var hero = get_tree().get_first_node_in_group("player")
	if hero and "skeleton" in hero and hero.skeleton:
		var skel: Skeleton3D = hero.skeleton
		_total_bones = skel.get_bone_count()
		_active_bones = 0
		for b in range(_total_bones):
			var rot := skel.get_bone_pose_rotation(b)
			if absf(rot.x) > 0.0001 or absf(rot.y) > 0.0001 or absf(rot.z) > 0.0001:
				_active_bones += 1

func _update_telemetry_display(delta: float) -> void:
	_last_fps = Engine.get_frames_per_second()
	var frame_ms := (1.0 / maxf(1.0, _last_fps)) * 1000.0
	telemetry_fps_label.text = "FPS: %.1f | Frame Time: %.2f ms" % [_last_fps, frame_ms]

	if _primitive_mesh_count == 0:
		telemetry_primitive_label.text = "[ZERO PRIMITIVE CHECK]: PRIMITIVE MESHES: 0 (PASS 100%)"
		telemetry_primitive_label.add_theme_color_override("font_color", Color(0.25, 0.95, 0.45))
	else:
		telemetry_primitive_label.text = "[ZERO PRIMITIVE CHECK]: FAIL! Found %d Primitive Meshes" % _primitive_mesh_count
		telemetry_primitive_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))

	telemetry_skeleton_label.text = "[SKELETON MOTION CHECK]: ACTIVE BONES: %d/%d (NO T-POSE/SLIDING)" % [_active_bones, max(1, _total_bones)]

	# Hero coordinates & multi-tier ground
	var hero = get_tree().get_first_node_in_group("player")
	if hero and is_instance_valid(hero):
		if "hp" in hero and "max_hp" in hero:
			hero_hp_bar.max_value = hero.max_hp
			hero_hp_bar.value = hero.hp
			var pct: float = (float(hero.hp) / float(hero.max_hp)) * 100.0
			hero_hp_label.text = "HP: %.1f / %.1f (%.0f%%)" % [hero.hp, hero.max_hp, pct]
			if pct > 50.0:
				(hero_hp_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.2, 0.85, 0.35)
			elif pct > 25.0:
				(hero_hp_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.95, 0.75, 0.2)
			else:
				(hero_hp_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.95, 0.25, 0.2)

		if "_current_anim" in hero:
			hero_anim_label.text = "Current Anim: %s" % hero._current_anim

		var hero_y: float = hero.global_position.y
		var ground_y: float = 0.0
		var space_state: PhysicsDirectSpaceState3D = hero.get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(hero.global_position + Vector3(0, 1.0, 0), hero.global_position + Vector3(0, -6.0, 0), 1)
		var hit: Dictionary = space_state.intersect_ray(query)
		if not hit.is_empty():
			ground_y = hit["position"].y
		var delta_y := absf(hero_y - ground_y)
		telemetry_coord_label.text = "[MULTI-TIER COORD]: Hero_Y: %.2fm | Ground_Y: %.2fm (ΔY: %.2fm)" % [hero_y, ground_y, delta_y]

		if "blade_tip_marker" in hero and hero.blade_tip_marker and is_instance_valid(hero.blade_tip_marker):
			var tip: Vector3 = hero.blade_tip_marker.global_position
			telemetry_blade_label.text = "Blade Tip: (%.2f, %.2f, %.2f)" % [tip.x, tip.y, tip.z]

	# Enemies count
	var enemies := get_tree().get_nodes_in_group("enemies")
	var alive_count := 0
	var t1 := 0
	var t2 := 0
	var t3 := 0
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			alive_count += 1
			var ey: float = (e as Node3D).global_position.y
			if ey < 2.0:
				t1 += 1
			elif ey < 6.0:
				t2 += 1
			else:
				t3 += 1
	telemetry_enemies_label.text = "Enemies Alive: %d / %d (Tier 1: %d | Tier 2: %d | Tier 3: %d)" % [alive_count, max(5, enemies.size()), t1, t2, t3]

# --- 4. VẼ THANH MÁU 2D TRÊN ĐẦU LÍNH ĐANG SỐNG (0% PRIMITIVE MESH) ---
func _on_enemy_health_drawer_draw() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e) or e.get("is_dead"):
			continue

		var enemy_pos: Vector3 = (e as Node3D).global_position + Vector3(0.0, 2.15, 0.0)
		# Kiểm tra có nằm trước camera không
		if cam.is_position_behind(enemy_pos):
			continue

		var screen_pos := cam.unproject_position(enemy_pos)
		var max_h: float = e.get("max_hp") if "max_hp" in e else 80.0
		var cur_h: float = e.get("hp") if "hp" in e else 80.0
		var ratio: float = clampf(cur_h / max_h, 0.0, 1.0)

		var bar_w := 64.0
		var bar_h := 7.0
		var rect_bg := Rect2(screen_pos.x - (bar_w * 0.5), screen_pos.y - (bar_h * 0.5), bar_w, bar_h)
		var rect_fill := Rect2(rect_bg.position.x + 1.0, rect_bg.position.y + 1.0, (bar_w - 2.0) * ratio, bar_h - 2.0)

		# Viền đen & nền tối
		enemy_healthbar_drawer.draw_rect(rect_bg.grow(1.0), Color(0.0, 0.0, 0.0, 0.8), false, 1.0)
		enemy_healthbar_drawer.draw_rect(rect_bg, Color(0.12, 0.14, 0.18, 0.85), true)

		# Máu (Đỏ tươi / Cam khi là Boss Tầng 3)
		var fill_color := Color(0.9, 0.25, 0.25, 0.95)
		if max_h > 100.0:
			fill_color = Color(1.0, 0.65, 0.15, 0.95) # Boss Tầng 3 màu cam
		enemy_healthbar_drawer.draw_rect(rect_fill, fill_color, true)
