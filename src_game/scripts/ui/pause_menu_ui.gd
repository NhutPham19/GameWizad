class_name PauseMenuUI
extends CanvasLayer

# ==============================================================================
# PAUSE MENU UI - MENU TẠM DỪNG & CHƠI LẠI PHÍM [ESC] (Argons Directive 08 Task 8.6)
# ==============================================================================

var panel_container: PanelContainer = null
var is_menu_open: bool = false

func _ready() -> void:
	layer = 150 # On top of everything
	process_mode = Node.PROCESS_MODE_ALWAYS # Runs even when tree paused
	_build_ui()
	_close_menu()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if is_menu_open:
			_resume_game()
		else:
			_open_menu()
		get_viewport().set_input_as_handled()

func _open_menu() -> void:
	is_menu_open = true
	get_tree().paused = true
	if panel_container:
		panel_container.visible = true
		_set_mouse_filter_recursive(panel_container, Control.MOUSE_FILTER_STOP)

func _close_menu() -> void:
	is_menu_open = false
	if panel_container:
		panel_container.visible = false
		_set_mouse_filter_recursive(panel_container, Control.MOUSE_FILTER_IGNORE)

func _resume_game() -> void:
	_close_menu()
	get_tree().paused = false
	Engine.time_scale = 1.0

func _restart_run() -> void:
	_close_menu()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _open_hero_select() -> void:
	_close_menu()
	get_tree().paused = false
	var modals = get_tree().get_nodes_in_group("hero_select_ui")
	if modals.size() > 0:
		modals[0].open_modal()

func _quit_game() -> void:
	get_tree().quit(0)

func _set_mouse_filter_recursive(node: Node, filter_mode: Control.MouseFilter) -> void:
	if node is Control:
		node.mouse_filter = filter_mode
	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter_mode)

func _build_ui() -> void:
	panel_container = PanelContainer.new()
	panel_container.name = "PausePanel"
	panel_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel_container)
	
	# Dark transparent backdrop
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.1, 0.78)
	panel_container.add_child(bg)
	
	# Center box
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_container.add_child(center)
	
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 480)
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	
	# Title
	var title = Label.new()
	title.text = "⏸️ TRÒ CHƠI TẠM DỪNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	box.add_child(title)
	
	var sub = Label.new()
	sub.text = "Bấm [ESC] để tiếp tục chiến đấu"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	box.add_child(sub)
	
	var sep = HSeparator.new()
	box.add_child(sep)
	
	# 5 Action Buttons
	var btn_resume = _create_button("▶ TIẾP TỤC CHIẾN ĐẤU (Resume)", Color(0.2, 0.85, 0.5), _resume_game)
	box.add_child(btn_resume)
	
	var btn_restart = _create_button("🔄 CHƠI LẠI TỪ ĐẦU (Restart)", Color(0.95, 0.75, 0.25), _restart_run)
	box.add_child(btn_restart)
	
	var btn_hero = _create_button("🧙 ĐỔI PHÁP SƯ (Hero Select - Phím M)", Color(0.4, 0.7, 1.0), _open_hero_select)
	box.add_child(btn_hero)
	
	var btn_diag = _create_button("📊 BẬT/TẮT THÔNG SỐ (F12 / Tab)", Color(0.7, 0.5, 0.95), func():
		var diags = get_tree().get_nodes_in_group("diagnostics_hud")
		for d in diags:
			if "visible" in d:
				d.visible = not d.visible
	)
	box.add_child(btn_diag)
	
	var btn_quit = _create_button("🚪 THOÁT TRÒ CHƠI (Quit Game)", Color(0.95, 0.3, 0.3), _quit_game)
	box.add_child(btn_quit)

func _create_button(text: String, col: Color, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(380, 52)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", col)
	btn.pressed.connect(callback)
	return btn
