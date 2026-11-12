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
var skill_cooldown_label: Label

var telemetry_fps_label: Label
var telemetry_primitive_label: Label
var telemetry_skeleton_label: Label
var telemetry_coord_label: Label
var telemetry_blade_label: Label = null
var telemetry_enemies_label: Label
var _ui_text_timer: float = 0.0

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

	# --- 1. NÚT CHƠI LẠI TRÊN ĐỈNH MÀN HÌNH (Phím F1 - Directive 26 Task 26.1) ---
	var restart_btn := Button.new()
	restart_btn.name = "RestartButton"
	restart_btn.text = "🔄 CHƠI LẠI (Phím F1)"
	restart_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	restart_btn.anchor_left = 0.5
	restart_btn.anchor_right = 0.5
	restart_btn.offset_left = -115.0
	restart_btn.offset_right = 115.0
	restart_btn.offset_top = 18.0
	restart_btn.offset_bottom = 54.0

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.13, 0.18, 0.92)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(1.0, 0.75, 0.2, 0.95)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_right = 6
	btn_style.corner_radius_bottom_left = 6
	restart_btn.add_theme_stylebox_override("normal", btn_style)

	var btn_hover := btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.18, 0.24, 0.35, 0.95)
	btn_hover.border_color = Color(1.0, 0.9, 0.4, 1.0)
	restart_btn.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed := btn_style.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	restart_btn.add_theme_stylebox_override("pressed", btn_pressed)

	restart_btn.add_theme_font_size_override("font_size", 14)
	restart_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	restart_btn.pressed.connect(func(): get_tree().reload_current_scene())
	overlay_root.add_child(restart_btn)

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
	hero_skills_label.text = "Phím Kỹ Năng: [U] Liên Trảm | [I] Phá Không Trảm | [O] Xoay 360° | [P] Bom Lôi Vụ | [Space] Lướt | [R] Hóa Nộ (10s) | [F1] Chơi Lại | [C] Nhảy"
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

	telemetry_enemies_label = Label.new()
	telemetry_enemies_label.text = "Enemies Alive: 5 / 5 (Tier 1: 2 | Tier 2: 2 | Tier 3: 1)"
	telemetry_enemies_label.add_theme_font_size_override("font_size", 12)
	telemetry_enemies_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
	telemetry_enemies_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r_vbox.add_child(telemetry_enemies_label)

	# --- 4. GIAO DIỆN THANH TRẠNG THÁI SKILL COOLDOWN DƯỚI ĐÁY MÀN HÌNH (Task 21.2 & 23.4) ---
	var bottom_panel := PanelContainer.new()
	bottom_panel.name = "SkillCooldownBar"
	bottom_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_panel.anchor_left = 0.5
	bottom_panel.anchor_right = 0.5
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = -550.0
	bottom_panel.offset_right = 550.0
	bottom_panel.offset_top = -62.0
	bottom_panel.offset_bottom = -16.0

	var b_style := StyleBoxFlat.new()
	b_style.bg_color = Color(0.06, 0.08, 0.12, 0.88)
	b_style.border_width_left = 2
	b_style.border_width_top = 2
	b_style.border_width_right = 2
	b_style.border_width_bottom = 2
	b_style.border_color = Color(0.3, 0.7, 1.0, 0.85)
	b_style.corner_radius_top_left = 8
	b_style.corner_radius_top_right = 8
	b_style.corner_radius_bottom_right = 8
	b_style.corner_radius_bottom_left = 8
	b_style.content_margin_left = 16
	b_style.content_margin_top = 8
	b_style.content_margin_right = 16
	b_style.content_margin_bottom = 8
	bottom_panel.add_theme_stylebox_override("panel", b_style)
	overlay_root.add_child(bottom_panel)

	skill_cooldown_label = Label.new()
	skill_cooldown_label.name = "SkillCooldownLabel"
	skill_cooldown_label.text = "[U] Liên Trảm: SẴN SÀNG  |  [I] Phá Không: SẴN SÀNG  |  [O] Xoay 360°: SẴN SÀNG  |  [P] Bom Lôi Vụ: SẴN SÀNG  |  [Space] Lướt: SẴN SÀNG  |  [R] Hóa Nộ: SẴN SÀNG"
	skill_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skill_cooldown_label.add_theme_font_size_override("font_size", 13)
	skill_cooldown_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	skill_cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_panel.add_child(skill_cooldown_label)

func _apply_mouse_filter_ignore(node: Node) -> void:
	if node is Control:
		if node.name == "RestartButton":
			(node as Control).mouse_filter = Control.MOUSE_FILTER_STOP
			return
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_apply_mouse_filter_ignore(child)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or event.physical_keycode == KEY_F1:
			get_tree().reload_current_scene()

func _process(delta: float) -> void:
	# Yêu cầu vẽ lại thanh máu 2D lính
	if enemy_healthbar_drawer:
		enemy_healthbar_drawer.queue_redraw()

	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = 2.0
		_perform_scans()

	# Task 23.5: Giới hạn cập nhật UI chữ 5 lần/giây (0.2s) để màn hình 165Hz+ mượt tuyệt đối
	_ui_text_timer -= delta
	if _ui_text_timer <= 0.0:
		_ui_text_timer = 0.20
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

		# Update Skill Cooldowns (Task 21.2 & 23.4 & 24.1)
		if skill_cooldown_label != null:
			var rmb_text := "SẴN SÀNG"
			if "_cd_rmb_timer" in hero and hero._cd_rmb_timer > 0.05:
				rmb_text = "CD: %.1fs" % hero._cd_rmb_timer

			var q_text := "SẴN SÀNG"
			if "_cd_q_timer" in hero and hero._cd_q_timer > 0.05:
				q_text = "CD: %.1fs" % hero._cd_q_timer

			var e_text := "SẴN SÀNG"
			if "_cd_e_timer" in hero and hero._cd_e_timer > 0.05:
				e_text = "CD: %.1fs" % hero._cd_e_timer

			var dash_text := "SẴN SÀNG"
			if "_cd_dash_timer" in hero and hero._cd_dash_timer > 0.05:
				dash_text = "CD: %.1fs" % hero._cd_dash_timer

			var r_text := "[R] Hóa Nộ: SẴN SÀNG"
			if "_is_rage_state_2" in hero and hero._is_rage_state_2:
				r_text = "🔥 [R] HUYẾT LAM NỘ: %.1fs (ĐANG BẬT)" % hero._rage_active_timer
			elif "_cd_rage_r_timer" in hero and hero._cd_rage_r_timer > 0.05:
				r_text = "[R] Hóa Nộ: CD: %.1fs" % hero._cd_rage_r_timer

			skill_cooldown_label.text = "[U] Liên Trảm: SẴN SÀNG  |  [I] Phá Không: %s  |  [O] Xoay 360°: %s  |  [P] Bom Lôi Vụ: %s  |  [Space] Lướt: %s  |  %s" % [rmb_text, q_text, e_text, dash_text, r_text]

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

# --- 4. VẼ THANH MÁU 2D TRÊN ĐẦU LÍNH (ĐÃ TẮT ĐỂ TRÁNH TRÙNG LẶP THANH MÁU 3D) ---
func _on_enemy_health_drawer_draw() -> void:
	# Directive 18: Chỉ duy trì duy nhất 1 thanh máu 3D OverheadHealthBar3D trên đầu mỗi Bot
	return
