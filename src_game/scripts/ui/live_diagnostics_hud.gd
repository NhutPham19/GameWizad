class_name LiveDiagnosticsHUD
extends CanvasLayer

# ==============================================================================
# LIVE DIAGNOSTICS HUD & AUTO BUG LOGGER
# Task 5.3: Real-time Performance & Input Matrix Monitor (Tab/F12 to Toggle)
# ==============================================================================

var panel: PanelContainer = null
var perf_label: Label = null
var status_box: VBoxContainer = null
var action_log_label: Label = null

# Input Matrix Indicators (7 items)
var ind_lmb: Label = null
var ind_rmb: Label = null
var ind_q: Label = null
var ind_e: Label = null
var ind_space: Label = null
var ind_wasd: Label = null
var ind_cam: Label = null

# Rolling frame spike tracker (5 seconds)
var frame_times: Array[float] = [] # in milliseconds
var frame_time_stamps: Array[float] = [] # seconds
var max_spike_5s: float = 0.0
var last_log_time: float = -10.0

var tracked_hero: HeroBase3D = null
var tracked_camera: IsometricCamera3D = null

const LOG_FILE_PATH: String = "res://../docs/LIVE_BUG_AND_LAG_LOG.md"

func _ready() -> void:
	layer = 120 # Always on top
	_build_ui()
	_init_log_file()
	_disable_mouse_filtering(self)

func _disable_mouse_filtering(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_disable_mouse_filtering(child)

var is_expanded: bool = false
var compact_label: Label = null
var detail_container: VBoxContainer = null

func _build_ui() -> void:
	panel = PanelContainer.new()
	# ARGONS HOTFIX 10.3: Chuyển sang Top-Center/Left X=460, giải phóng hoàn toàn bầu trời nửa phải X>960!
	panel.position = Vector2(460, 16)
	panel.custom_minimum_size = Vector2(380, 34)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.11, 0.82)
	style.border_color = Color(0.2, 0.6, 0.9, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_theme_constant_override("separation", 4)
	panel.add_child(main_vbox)
	
	# Compact single-line bar (Default View)
	compact_label = Label.new()
	compact_label.text = "⚡ FPS: -- | Frame: -- ms | [F12] Chi Tiết"
	compact_label.add_theme_font_size_override("font_size", 12)
	compact_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	compact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(compact_label)
	
	# Detail Container (Expanded View on F12/Tab)
	detail_container = VBoxContainer.new()
	detail_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_container.add_theme_constant_override("separation", 4)
	detail_container.visible = false
	main_vbox.add_child(detail_container)
	
	var sep = HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_container.add_child(sep)
	
	perf_label = Label.new()
	perf_label.text = "FPS: -- | Frame: -- ms | Spike 5s: -- ms | Nodes: --"
	perf_label.add_theme_font_size_override("font_size", 11)
	perf_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_container.add_child(perf_label)
	
	# Matrix Grid
	var grid = GridContainer.new()
	grid.columns = 2
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 3)
	detail_container.add_child(grid)
	
	ind_lmb = _create_ind(grid, "[LMB] Đánh Thường: IDLE")
	ind_rmb = _create_ind(grid, "[RMB] Kỹ Năng 2: IDLE")
	ind_q = _create_ind(grid, "[Q] Chiêu Cuối: IDLE")
	ind_e = _create_ind(grid, "[E] Dung Hợp: IDLE")
	ind_space = _create_ind(grid, "[Space] Dash: IDLE")
	ind_wasd = _create_ind(grid, "[WASD] Di Chuyển: IDLE")
	
	ind_cam = _create_ind(detail_container, "[Camera] Bám Mục Tiêu: ĐANG TÌM...")
	
	action_log_label = Label.new()
	action_log_label.text = "Trạng thái: Sẵn sàng chiến đấu."
	action_log_label.add_theme_font_size_override("font_size", 11)
	action_log_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	action_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_container.add_child(action_log_label)

func _create_ind(parent: Control, init_text: String) -> Label:
	var lbl = Label.new()
	lbl.text = init_text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	return lbl

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_F12:
			is_expanded = not is_expanded
			if detail_container:
				detail_container.visible = is_expanded
			if panel:
				panel.custom_minimum_size = Vector2(420, 230) if is_expanded else Vector2(380, 34)
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not visible:
		return
		
	_update_performance_stats(delta)
	_ensure_active_hero_tracking()
	_ensure_camera_tracking()
	_update_wasd_indicator()

func _update_performance_stats(delta: float) -> void:
	var fps = Engine.get_frames_per_second()
	var frame_ms = delta * 1000.0
	var now = Time.get_ticks_msec() / 1000.0
	
	frame_times.append(frame_ms)
	frame_time_stamps.append(now)
	
	# Purge frames older than 5.0 seconds
	while frame_time_stamps.size() > 0 and (now - frame_time_stamps[0]) > 5.0:
		frame_time_stamps.pop_front()
		frame_times.pop_front()
		
	max_spike_5s = 0.0
	for ft in frame_times:
		if ft > max_spike_5s:
			max_spike_5s = ft
			
	var node_count = get_tree().get_node_count() if get_tree() else 0
	
	if compact_label:
		compact_label.text = "⚡ FPS: %d | Frame: %.1fms | [F12] Bảng Chi Tiết" % [fps, frame_ms]
	if perf_label:
		perf_label.text = "FPS: %d | Frame: %.1fms | Spike 5s: %.1fms | Nodes: %d" % [fps, frame_ms, max_spike_5s, node_count]
	
	if max_spike_5s > 33.3:
		perf_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25)) # Red
		_log_issue("FRAME_SPIKE", "Phát hiện Spike giật lag: %.1f ms (> 33.3ms / 30fps)" % max_spike_5s)
	elif max_spike_5s > 25.0:
		perf_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) # Yellow
	else:
		perf_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5)) # Green

func _ensure_active_hero_tracking() -> void:
	if not tracked_hero or not is_instance_valid(tracked_hero):
		var heroes = get_tree().get_nodes_in_group("heroes")
		for h in heroes:
			if is_instance_valid(h) and (h as Node3D).visible:
				_bind_hero(h as HeroBase3D)
				break

func _bind_hero(hero: HeroBase3D) -> void:
	if tracked_hero and is_instance_valid(tracked_hero):
		if tracked_hero.skill_cast_attempted.is_connected(_on_skill_attempted):
			tracked_hero.skill_cast_attempted.disconnect(_on_skill_attempted)
			
	tracked_hero = hero
	if tracked_hero and is_instance_valid(tracked_hero):
		if not tracked_hero.skill_cast_attempted.is_connected(_on_skill_attempted):
			tracked_hero.skill_cast_attempted.connect(_on_skill_attempted)

func _ensure_camera_tracking() -> void:
	if not tracked_camera or not is_instance_valid(tracked_camera):
		var vp = get_viewport()
		var cam = vp.get_camera_3d() if vp else null
		if cam is IsometricCamera3D:
			tracked_camera = cam
			
	if tracked_camera and is_instance_valid(tracked_camera):
		var target = tracked_camera.target_node
		if target and is_instance_valid(target):
			var t_name = target.hero_name if "hero_name" in target else target.name
			ind_cam.text = "[Camera] Bám Mục Tiêu: OK (%s)" % t_name
			ind_cam.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		else:
			ind_cam.text = "[Camera] Bám Mục Tiêu: CẢNH BÁO (Target Null)"
			ind_cam.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			_log_issue("CAMERA_TARGET_LOST", "Camera target_node bị Null hoặc mất đối tượng!")
	else:
		ind_cam.text = "[Camera] Đang khởi tạo..."

func _update_wasd_indicator() -> void:
	var is_moving = false
	if tracked_hero and is_instance_valid(tracked_hero):
		is_moving = tracked_hero.velocity.length_squared() > 0.05
	else:
		is_moving = (
			Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") or
			Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward")
		)
		
	if is_moving:
		ind_wasd.text = "[WASD] Di Chuyển: RUNNING"
		ind_wasd.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	else:
		ind_wasd.text = "[WASD] Di Chuyển: IDLE"
		ind_wasd.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))

func _on_skill_attempted(skill_name: String, success: bool, reason: String) -> void:
	var target_label: Label = null
	match skill_name:
		"lmb": target_label = ind_lmb
		"rmb": target_label = ind_rmb
		"q": target_label = ind_q
		"e": target_label = ind_e
		"dash": target_label = ind_space
		
	if not target_label:
		return
		
	if success:
		target_label.text = "[%s]: OK (%s)" % [skill_name.to_upper(), reason]
		target_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5)) # Green
		action_log_label.text = "✓ %s: Kích hoạt thành công [%s]" % [skill_name.to_upper(), reason]
		action_log_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6))
	else:
		target_label.text = "[%s]: %s" % [skill_name.to_upper(), reason]
		if "Cooldown" in reason or "Dashing" in reason:
			target_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) # Yellow (Normal CD)
		else:
			target_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25)) # Red (Error/Blocked)
			action_log_label.text = "✗ LỖI NÚT [%s]: %s" % [skill_name.to_upper(), reason]
			action_log_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			_log_issue("INPUT_BLOCKED", "Nút [%s] bị chặn hoặc thất bại: %s" % [skill_name.to_upper(), reason])

func _init_log_file() -> void:
	var abs_path = ProjectSettings.globalize_path(LOG_FILE_PATH)
	if not FileAccess.file_exists(abs_path):
		var file = FileAccess.open(abs_path, FileAccess.WRITE)
		if file:
			file.store_line("# 📋 NHẬT KÝ LỖI & GIẬT LAG TỰ ĐỘNG (LIVE BUG AND LAG LOG)")
			file.store_line("Dự án: GameWizad | Tạo tự động bởi LiveDiagnosticsHUD\n")
			file.store_line("| Thời Gian (s) | Loại Sự Kiện | Nhân Vật | Mô Tả Chi Tiết |")
			file.store_line("| :--- | :--- | :--- | :--- |")
			file.close()

func _log_issue(event_type: String, details: String) -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_log_time < 1.0:
		return # Debounce 1.0s to avoid disk flood
	last_log_time = now
	
	var hero_name_str = tracked_hero.hero_name if (tracked_hero and is_instance_valid(tracked_hero)) else "Unknown"
	var abs_path = ProjectSettings.globalize_path(LOG_FILE_PATH)
	var file = FileAccess.open(abs_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_line("| %.2fs | `%s` | %s | %s |" % [now, event_type, hero_name_str, details])
		file.close()
