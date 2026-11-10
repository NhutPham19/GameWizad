class_name CombatHUD
extends CanvasLayer

# ==============================================================================
# STYLIZED ARCANE HUD (COMBAT HUD) - STYLIZED AAA HADES 2 / WIZARD OF LEGEND 2
# Argons Directive 07 - Sprint 2
# ==============================================================================

const LiveDiagnosticsHUD = preload("res://scripts/ui/live_diagnostics_hud.gd")
const SkewedHealthBarShader = preload("res://shaders/ui_skewed_health_bar.gdshader")
const DiamondSlotShader = preload("res://shaders/ui_diamond_skill_slot.gdshader")
const MinimapRadarUIScript = preload("res://scripts/ui/minimap_radar_ui.gd")
const PauseMenuUIScript = preload("res://scripts/ui/pause_menu_ui.gd")

# EXP & Minimap UI (Argons Directive 08 Task 8.4 & 8.5)
var exp_bar_rect: ColorRect = null
var exp_bar_fill: ColorRect = null
var exp_label: Label = null
var minimap_radar: Control = null
var pause_menu: CanvasLayer = null

# Hero Stats UI
var hero_name_label: Label = null
var hero_hp_mat: ShaderMaterial = null
var hero_hp_rect: ColorRect = null
var hero_hp_label: Label = null
var shield_rect: ColorRect = null
var shield_label: Label = null

# Boss Stats UI
var boss_container: VBoxContainer = null
var boss_name_label: Label = null
var boss_hp_mat: ShaderMaterial = null
var boss_hp_rect: ColorRect = null
var boss_hp_label: Label = null

# Biome Header
var biome_label: Label = null

# Core Notification Banner
var banner_panel: PanelContainer = null
var banner_label: Label = null
var banner_tween: Tween = null

# Core Tray
var core_tray_label: Label = null
var core_levels := {
	"fire": 1,
	"wind": 0,
	"lightning": 0,
	"earth": 0,
	"water": 0
}

# Diamond Skill Slots
var skill_slots := {} # "dash", "lmb", "rmb", "q", "e"
var slot_materials := {}

var active_hero: HeroBase3D = null
var delayed_hp: float = 100.0
var target_hp: float = 100.0
var max_hp: float = 100.0

var boss_delayed_hp: float = 1000.0
var boss_target_hp: float = 1000.0
var boss_max_hp: float = 1000.0

func _ready() -> void:
	add_to_group("hud")
	_build_stylized_hud()
	_disable_mouse_filtering(self)
	_ensure_diagnostics_hud()
	_ensure_pause_menu()

func _ensure_pause_menu() -> void:
	if not is_inside_tree() or not get_tree():
		return
	if get_tree().get_nodes_in_group("pause_menu").size() == 0:
		pause_menu = PauseMenuUIScript.new()
		pause_menu.name = "PauseMenuUI"
		pause_menu.add_to_group("pause_menu")
		get_parent().call_deferred("add_child", pause_menu)

func _ensure_diagnostics_hud() -> void:
	if not is_inside_tree() or not get_tree():
		return
	if get_tree().get_nodes_in_group("diagnostics_hud").size() == 0:
		var diag = LiveDiagnosticsHUD.new()
		diag.name = "LiveDiagnosticsHUD"
		diag.add_to_group("diagnostics_hud")
		get_parent().call_deferred("add_child", diag)

func _disable_mouse_filtering(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_disable_mouse_filtering(child)

func _process(delta: float) -> void:
	# Catch-up animation for hero health bar
	if delayed_hp > target_hp:
		delayed_hp = max(target_hp, delayed_hp - delta * (max_hp * 0.35))
		if hero_hp_mat:
			hero_hp_mat.set_shader_parameter("delayed_hp_ratio", delayed_hp / max(1.0, max_hp))
			
	# Catch-up animation for boss health bar
	if boss_delayed_hp > boss_target_hp:
		boss_delayed_hp = max(boss_target_hp, boss_delayed_hp - delta * (boss_max_hp * 0.25))
		if boss_hp_mat:
			boss_hp_mat.set_shader_parameter("delayed_hp_ratio", boss_delayed_hp / max(1.0, boss_max_hp))
			
	# Update skill slots cooldowns
	_update_slot_cooldowns(delta)
	
	# Update shield display
	if active_hero and is_instance_valid(active_hero) and "current_shield" in active_hero and shield_label:
		var sh = int(active_hero.current_shield)
		shield_label.text = "%d Giáp" % sh
		if shield_rect:
			shield_rect.visible = (sh > 0)
			shield_label.visible = (sh > 0)
	elif shield_label and shield_rect:
		shield_rect.visible = false
		shield_label.visible = false

# ==============================================================================
# UI CONSTRUCTION (STYLIZED AAA LAYOUT)
# ==============================================================================

func _build_stylized_hud() -> void:
	var root = Control.new()
	root.name = "HUD_Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	
	_build_bottom_left_hero_dock(root)
	_build_top_boss_bar(root)
	_build_bottom_right_diamond_dock(root)
	_build_notification_banner(root)
	_build_bottom_exp_bar(root)
	_build_top_right_minimap(root)

func _build_bottom_exp_bar(root: Control) -> void:
	var exp_container = Control.new()
	exp_container.name = "ExpContainer"
	exp_container.position = Vector2(290, 1052)
	exp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(exp_container)
	
	# Background track (1340px x 8px)
	exp_bar_rect = ColorRect.new()
	exp_bar_rect.custom_minimum_size = Vector2(1340, 8)
	exp_bar_rect.size = Vector2(1340, 8)
	exp_bar_rect.color = Color(0.08, 0.12, 0.18, 0.85)
	exp_bar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exp_container.add_child(exp_bar_rect)
	
	# Fill bar
	exp_bar_fill = ColorRect.new()
	exp_bar_fill.custom_minimum_size = Vector2(0, 8)
	exp_bar_fill.size = Vector2(0, 8)
	exp_bar_fill.color = Color(0.25, 0.85, 1.0, 0.95) # Turquoise glow
	exp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exp_container.add_child(exp_bar_fill)
	
	# Text Label
	exp_label = Label.new()
	exp_label.text = "CẤP ĐỘ [Lv.1] — KINH NGHIỆM: 0 / 100 EXP (0%)"
	exp_label.position = Vector2(0, -22)
	exp_label.size = Vector2(1340, 20)
	exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_label.add_theme_font_size_override("font_size", 12)
	exp_label.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
	exp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exp_container.add_child(exp_label)

func _build_top_right_minimap(root: Control) -> void:
	minimap_radar = MinimapRadarUIScript.new()
	minimap_radar.position = Vector2(1706, 18)
	minimap_radar.custom_minimum_size = Vector2(190, 190)
	minimap_radar.size = Vector2(190, 190)
	minimap_radar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(minimap_radar)

# ------------------------------------------------------------------------------
# 1. BOTTOM-LEFT: HERO DOCK (SKEWED HEALTH BAR & BADGE)
# ------------------------------------------------------------------------------
func _build_bottom_left_hero_dock(root: Control) -> void:
	var hero_dock = Control.new()
	hero_dock.name = "HeroDock"
	hero_dock.position = Vector2(30, 900)
	hero_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hero_dock)
	
	# Slanted Hero Name Label
	hero_name_label = Label.new()
	hero_name_label.text = "IGNIS — HỎA LONG PHÁP SƯ"
	hero_name_label.position = Vector2(90, -42)
	hero_name_label.add_theme_font_size_override("font_size", 22)
	hero_name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	hero_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	hero_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_dock.add_child(hero_name_label)
	
	# Slanted Avatar Frame (Diamond Octagon)
	var avatar_rect = ColorRect.new()
	avatar_rect.name = "HeroAvatar"
	avatar_rect.custom_minimum_size = Vector2(72, 72)
	avatar_rect.position = Vector2(0, -32)
	avatar_rect.color = Color(0.12, 0.1, 0.18, 0.9)
	avatar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_dock.add_child(avatar_rect)
	
	var avatar_icon = TextureRect.new()
	avatar_icon.custom_minimum_size = Vector2(56, 56)
	avatar_icon.position = Vector2(8, 8)
	avatar_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_icon.texture = load("res://assets/icons/fire_core.svg")
	avatar_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_rect.add_child(avatar_icon)
	
	# Slanted Health Bar 2-Layer with Shader
	hero_hp_rect = ColorRect.new()
	hero_hp_rect.name = "SkewedHPBar"
	hero_hp_rect.custom_minimum_size = Vector2(380, 32)
	hero_hp_rect.position = Vector2(90, -8)
	hero_hp_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	hero_hp_mat = ShaderMaterial.new()
	hero_hp_mat.shader = SkewedHealthBarShader
	hero_hp_mat.set_shader_parameter("current_hp_ratio", 1.0)
	hero_hp_mat.set_shader_parameter("delayed_hp_ratio", 1.0)
	hero_hp_mat.set_shader_parameter("skew_angle", -0.26)
	hero_hp_mat.set_shader_parameter("hp_color_bright", Color(1.0, 0.25, 0.22))
	hero_hp_mat.set_shader_parameter("hp_color_dark", Color(0.6, 0.05, 0.12))
	hero_hp_rect.material = hero_hp_mat
	hero_dock.add_child(hero_hp_rect)
	
	# HP Text Display
	hero_hp_label = Label.new()
	hero_hp_label.text = "100 / 100 HP"
	hero_hp_label.position = Vector2(480, -2)
	hero_hp_label.add_theme_font_size_override("font_size", 16)
	hero_hp_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.8))
	hero_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_dock.add_child(hero_hp_label)
	
	# Shield Bar (Slanted beneath HP Bar)
	shield_rect = ColorRect.new()
	shield_rect.name = "ShieldBar"
	shield_rect.custom_minimum_size = Vector2(260, 12)
	shield_rect.position = Vector2(90, 30)
	shield_rect.color = Color(0.2, 0.7, 1.0, 0.85)
	shield_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_dock.add_child(shield_rect)
	
	shield_label = Label.new()
	shield_label.text = "40 Giáp"
	shield_label.position = Vector2(360, 26)
	shield_label.add_theme_font_size_override("font_size", 14)
	shield_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	shield_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_dock.add_child(shield_label)
	
	# Keyboard Shortcut Help Tooltip
	var shortcut_label = Label.new()
	shortcut_label.text = "[1: Solaris | 2: Nyx | X: Đổi Vũ Khí | M: Chọn Tướng | F1-F3: Đổi Ải]"
	shortcut_label.position = Vector2(90, 52)
	shortcut_label.add_theme_font_size_override("font_size", 13)
	shortcut_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.8))
	shortcut_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_dock.add_child(shortcut_label)

# ------------------------------------------------------------------------------
# 2. TOP-CENTER: BOSS HP BAR & BIOME TITLE
# ------------------------------------------------------------------------------
func _build_top_boss_bar(root: Control) -> void:
	var center_top = Control.new()
	center_top.name = "CenterTop"
	center_top.position = Vector2(560, 20)
	center_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center_top)
	
	biome_label = Label.new()
	biome_label.text = "🌲 ẢI 1/3: RỪNG CỔ THỤ & DÒNG SÔNG U MINH"
	biome_label.position = Vector2(0, 0)
	biome_label.custom_minimum_size = Vector2(800, 30)
	biome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	biome_label.add_theme_font_size_override("font_size", 18)
	biome_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	biome_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_top.add_child(biome_label)
	
	boss_container = VBoxContainer.new()
	boss_container.name = "BossContainer"
	boss_container.position = Vector2(50, 36)
	boss_container.custom_minimum_size = Vector2(700, 70)
	boss_container.visible = false
	boss_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_top.add_child(boss_container)
	
	boss_name_label = Label.new()
	boss_name_label.text = "☠️ CỔ THẠCH HỘ PHÁP (ANCIENT MOSS TITAN)   [PHASE 1/2]"
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 17)
	boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.25))
	boss_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_container.add_child(boss_name_label)
	
	boss_hp_rect = ColorRect.new()
	boss_hp_rect.custom_minimum_size = Vector2(700, 24)
	boss_hp_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_mat = ShaderMaterial.new()
	boss_hp_mat.shader = SkewedHealthBarShader
	boss_hp_mat.set_shader_parameter("current_hp_ratio", 1.0)
	boss_hp_mat.set_shader_parameter("delayed_hp_ratio", 1.0)
	boss_hp_mat.set_shader_parameter("skew_angle", -0.18)
	boss_hp_mat.set_shader_parameter("hp_color_bright", Color(1.0, 0.15, 0.18))
	boss_hp_mat.set_shader_parameter("hp_color_dark", Color(0.55, 0.02, 0.08))
	boss_hp_rect.material = boss_hp_mat
	boss_container.add_child(boss_hp_rect)
	
	boss_hp_label = Label.new()
	boss_hp_label.text = "2,500 / 2,500 HP"
	boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_label.add_theme_font_size_override("font_size", 13)
	boss_hp_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.8))
	boss_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_container.add_child(boss_hp_label)

# ------------------------------------------------------------------------------
# 3. BOTTOM-RIGHT: DIAMOND ARCANE DOCK & CORE TRAY
# ------------------------------------------------------------------------------
func _build_bottom_right_diamond_dock(root: Control) -> void:
	var right_dock = Control.new()
	right_dock.name = "RightDock"
	right_dock.position = Vector2(1420, 890)
	right_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(right_dock)
	
	# Elemental Cores Tray Header
	core_tray_label = Label.new()
	core_tray_label.name = "CoreTray"
	core_tray_label.text = "💎 LÕI NGUYÊN TỐ: ⟨🔥Lv.1⟩ ⟨🌪️Lv.0⟩ ⟨⚡Lv.0⟩ ⟨⛰️Lv.0⟩ ⟨❄️Lv.0⟩"
	core_tray_label.position = Vector2(-20, -38)
	core_tray_label.add_theme_font_size_override("font_size", 15)
	core_tray_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	core_tray_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_dock.add_child(core_tray_label)
	
	# 5 Diamond Slots: Space, LMB, RMB, Q, E
	var slot_specs = [
		{"id": "dash", "key": "Space", "name": "Lướt", "icon": "res://assets/icons/skill_dash.svg", "col": Color(0.3, 0.9, 1.0)},
		{"id": "lmb",  "key": "LMB",   "name": "Đánh", "icon": "res://assets/icons/skill_fireball.svg", "col": Color(1.0, 0.4, 0.1)},
		{"id": "rmb",  "key": "RMB",   "name": "Chiêu", "icon": "res://assets/icons/skill_fire_wall.svg", "col": Color(1.0, 0.55, 0.2)},
		{"id": "q",    "key": "Phím Q","name": "Nộ",   "icon": "res://assets/icons/skill_dragon.svg", "col": Color(1.0, 0.2, 0.1)},
		{"id": "e",    "key": "Phím E","name": "Hợp",  "icon": "res://assets/icons/skill_fusion.svg", "col": Color(0.8, 0.35, 1.0)}
	]
	
	for i in range(slot_specs.size()):
		var spec = slot_specs[i]
		var x_pos = i * 94
		var slot_ctrl = _create_diamond_slot(spec, Vector2(x_pos, 0))
		right_dock.add_child(slot_ctrl)

func _create_diamond_slot(spec: Dictionary, pos: Vector2) -> Control:
	var slot_id = spec["id"]
	var col = spec["col"]
	
	var container = Control.new()
	container.name = "Slot_" + slot_id
	container.position = pos
	container.custom_minimum_size = Vector2(84, 84)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Diamond Shader Material
	var mat = ShaderMaterial.new()
	mat.shader = DiamondSlotShader
	mat.set_shader_parameter("cooldown_progress", 0.0)
	mat.set_shader_parameter("ready_flash", 0.0)
	mat.set_shader_parameter("element_rim_color", col)
	mat.set_shader_parameter("frame_gold_color", Color(0.92, 0.76, 0.38, 1.0))
	slot_materials[slot_id] = mat
	
	# Diamond Texture Slot Rect
	var slot_rect = TextureRect.new()
	slot_rect.custom_minimum_size = Vector2(80, 80)
	slot_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot_rect.material = mat
	if ResourceLoader.exists(spec["icon"]):
		slot_rect.texture = load(spec["icon"])
	slot_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(slot_rect)
	
	# Key Label (Bottom)
	var key_lbl = Label.new()
	key_lbl.text = spec["key"]
	key_lbl.position = Vector2(0, 84)
	key_lbl.custom_minimum_size = Vector2(80, 20)
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_lbl.add_theme_font_size_override("font_size", 13)
	key_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(key_lbl)
	
	skill_slots[slot_id] = {
		"container": container,
		"rect": slot_rect,
		"cd_remaining": 0.0,
		"cd_total": 1.0,
		"is_on_cd": false
	}
	
	return container

# ------------------------------------------------------------------------------
# 4. REAL-TIME NOTIFICATION BANNER (NON-PAUSING)
# ------------------------------------------------------------------------------
func _build_notification_banner(root: Control) -> void:
	banner_panel = PanelContainer.new()
	banner_panel.name = "SlantedBanner"
	banner_panel.position = Vector2(1950, 320) # Offscreen to the right
	banner_panel.custom_minimum_size = Vector2(360, 56)
	banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.12, 0.88)
	style.border_color = Color(0.95, 0.8, 0.35, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.skew = Vector2(-0.25, 0.0)
	banner_panel.add_theme_stylebox_override("panel", style)
	
	banner_label = Label.new()
	banner_label.text = "⚡+🌪️ DUNG HỢP MỞ KHÓA: LÔI VÂN CUỒNG PHONG!"
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 14)
	banner_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.add_child(banner_label)
	
	root.add_child(banner_panel)

# ==============================================================================
# REAL-TIME BANNER & CORE PICKUP LOGIC
# ==============================================================================

func notify_core_pickup(element: String, level: int, title: String, col: Color) -> void:
	core_levels[element] = level
	_update_core_tray_text()
	
	# Show sliding banner for 2.2 seconds
	banner_label.text = title
	banner_label.add_theme_color_override("font_color", col.lightened(0.2))
	
	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()
		
	banner_tween = create_tween()
	banner_tween.tween_property(banner_panel, "position:x", 1520.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner_tween.tween_interval(2.2)
	banner_tween.tween_property(banner_panel, "position:x", 1950.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _update_core_tray_text() -> void:
	core_tray_label.text = "💎 LÕI NGUYÊN TỐ: ⟨🔥Lv.%d⟩ ⟨🌪️Lv.%d⟩ ⟨⚡Lv.%d⟩ ⟨⛰️Lv.%d⟩ ⟨❄️Lv.%d⟩" % [
		core_levels.get("fire", 1),
		core_levels.get("wind", 0),
		core_levels.get("lightning", 0),
		core_levels.get("earth", 0),
		core_levels.get("water", 0)
	]

# ==============================================================================
# HERO HOOKS & COOLDOWN LOGIC
# ==============================================================================

func hook_hero(hero: HeroBase3D) -> void:
	if not hero:
		return
		
	# Disconnect previous hero if any
	if active_hero and is_instance_valid(active_hero) and active_hero != hero:
		if active_hero.health_changed.is_connected(_on_hero_health_changed):
			active_hero.health_changed.disconnect(_on_hero_health_changed)
		if active_hero.skill_cooldown_started.is_connected(_on_skill_cooldown_started):
			active_hero.skill_cooldown_started.disconnect(_on_skill_cooldown_started)
		if active_hero.has_signal("exp_changed") and active_hero.exp_changed.is_connected(_on_hero_exp_changed):
			active_hero.exp_changed.disconnect(_on_hero_exp_changed)
		if active_hero.has_signal("level_up_achieved") and active_hero.level_up_achieved.is_connected(_on_hero_level_up):
			active_hero.level_up_achieved.disconnect(_on_hero_level_up)
			
	active_hero = hero
	max_hp = hero.max_hp
	target_hp = hero.current_hp
	delayed_hp = hero.current_hp
	
	var h_name_vi = {
		"solaris": "SOLARIS — THÁNH KỴ SĨ THÁI DƯƠNG",
		"nyx": "NYX — THỢ SĂN TINH KHÔNG",
		"ignis": "IGNIS — HỎA LONG PHÁP SƯ",
		"zephyr": "ZEPHYR — CUỒNG PHONG KIẾM SĨ",
		"aethel": "AETHEL — TINH KHÔNG LÔI PHÁP",
		"kael": "KAEL — THIẾT THẠCH HỘ VỆ",
		"nereus": "NEREUS — HÀN BĂNG THỦY SƯ"
	}.get(hero.hero_name.to_lower(), hero.hero_name.to_upper())
	
	hero_name_label.text = h_name_vi
	hero_hp_label.text = "%d / %d HP" % [int(hero.current_hp), int(hero.max_hp)]
	if hero_hp_mat:
		hero_hp_mat.set_shader_parameter("current_hp_ratio", hero.current_hp / max(1.0, hero.max_hp))
		hero_hp_mat.set_shader_parameter("delayed_hp_ratio", hero.current_hp / max(1.0, hero.max_hp))
		if hero.hero_name.to_lower() == "solaris":
			hero_hp_mat.set_shader_parameter("hp_color_bright", Color(1.0, 0.82, 0.25))
			hero_hp_mat.set_shader_parameter("hp_color_dark", Color(0.65, 0.35, 0.05))
		elif hero.hero_name.to_lower() == "nyx":
			hero_hp_mat.set_shader_parameter("hp_color_bright", Color(0.0, 0.9, 1.0))
			hero_hp_mat.set_shader_parameter("hp_color_dark", Color(0.35, 0.1, 0.65))
			
	var avatar_icon_node = find_child("HeroAvatar", true, false)
	if avatar_icon_node and avatar_icon_node.get_child_count() > 0:
		var avi = avatar_icon_node.get_child(0) as TextureRect
		if avi:
			if hero.hero_name.to_lower() == "solaris" and ResourceLoader.exists("res://assets/ui/icons/icon_solaris_avatar.svg"):
				avi.texture = load("res://assets/ui/icons/icon_solaris_avatar.svg")
			elif hero.hero_name.to_lower() == "nyx" and ResourceLoader.exists("res://assets/ui/icons/icon_nyx_avatar.svg"):
				avi.texture = load("res://assets/ui/icons/icon_nyx_avatar.svg")
		
	_update_slot_icons_for_hero(hero.hero_name.to_lower())
	
	if "current_shield" in hero and shield_label and shield_rect:
		var sh = int(hero.current_shield)
		shield_label.text = "%d Giáp" % sh
		shield_rect.visible = (sh > 0)
		shield_label.visible = (sh > 0)
	elif shield_label and shield_rect:
		shield_rect.visible = false
		shield_label.visible = false
	
	# Connect signals
	if not hero.health_changed.is_connected(_on_hero_health_changed):
		hero.health_changed.connect(_on_hero_health_changed)
	if not hero.skill_cooldown_started.is_connected(_on_skill_cooldown_started):
		hero.skill_cooldown_started.connect(_on_skill_cooldown_started)
	if hero.has_signal("exp_changed") and not hero.exp_changed.is_connected(_on_hero_exp_changed):
		hero.exp_changed.connect(_on_hero_exp_changed)
	if hero.has_signal("level_up_achieved") and not hero.level_up_achieved.is_connected(_on_hero_level_up):
		hero.level_up_achieved.connect(_on_hero_level_up)
		
	# Initial EXP update
	if "exp_current" in hero and "exp_required" in hero:
		_on_hero_exp_changed(hero.exp_current, hero.exp_required, hero.hero_level)

func _on_hero_exp_changed(current: float, required: float, level: int) -> void:
	if exp_bar_fill:
		var ratio = clampf(current / max(1.0, required), 0.0, 1.0)
		exp_bar_fill.size.x = 1340.0 * ratio
	if exp_label:
		var pct = int((current / max(1.0, required)) * 100.0)
		exp_label.text = "CẤP ĐỘ [Lv.%d] — KINH NGHIỆM: %d / %d EXP (%d%%)" % [level, int(current), int(required), pct]

func _on_hero_level_up(new_level: int) -> void:
	notify_core_pickup("gold", new_level, "★ LEVEL UP! ĐẠT CẤP " + str(new_level) + " ★", Color(1.0, 0.85, 0.2))

func _update_slot_icons_for_hero(h_name: String) -> void:
	var icons := {
		"solaris": {
			"lmb": "res://assets/ui/icons/icon_sword_slice.svg",
			"rmb": "res://assets/ui/icons/icon_solaris_shield.svg",
			"q": "res://assets/ui/icons/icon_solaris_judgment.svg",
			"col": Color(1.0, 0.75, 0.18)
		},
		"nyx": {
			"lmb": "res://assets/ui/icons/icon_nyx_crossbow.svg",
			"rmb": "res://assets/ui/icons/icon_nyx_vortex.svg",
			"q": "res://assets/ui/icons/icon_nyx_supernova.svg",
			"col": Color(0.0, 0.9, 1.0)
		},
		"ignis": {
			"lmb": "res://assets/icons/skill_fireball.svg",
			"rmb": "res://assets/icons/skill_fire_wall.svg",
			"q": "res://assets/icons/skill_dragon.svg",
			"col": Color(1.0, 0.35, 0.1)
		},
		"zephyr": {
			"lmb": "res://assets/icons/skill_wind_slash.svg",
			"rmb": "res://assets/icons/skill_tornado.svg",
			"q": "res://assets/icons/skill_tornado.svg",
			"col": Color(0.25, 0.95, 0.7)
		},
		"aethel": {
			"lmb": "res://assets/icons/skill_lightning.svg",
			"rmb": "res://assets/icons/skill_lightning_storm.svg",
			"q": "res://assets/icons/skill_fusion.svg",
			"col": Color(0.85, 0.35, 1.0)
		},
		"kael": {
			"lmb": "res://assets/icons/skill_earth_fist.svg",
			"rmb": "res://assets/icons/earth_core.svg",
			"q": "res://assets/icons/skill_earth_quake.svg",
			"col": Color(0.9, 0.7, 0.25)
		},
		"nereus": {
			"lmb": "res://assets/icons/skill_ice_spear.svg",
			"rmb": "res://assets/icons/skill_water_orb.svg",
			"q": "res://assets/icons/water_core.svg",
			"col": Color(0.15, 0.8, 1.0)
		}
	}
	var set_icons = icons.get(h_name, icons["ignis"])
	for slot_key in ["lmb", "rmb", "q"]:
		if skill_slots.has(slot_key) and set_icons.has(slot_key):
			var tex_path = set_icons[slot_key]
			if ResourceLoader.exists(tex_path):
				skill_slots[slot_key]["rect"].texture = load(tex_path)
			if slot_materials.has(slot_key):
				slot_materials[slot_key].set_shader_parameter("element_rim_color", set_icons["col"])

func _on_hero_health_changed(curr: float, max_val: float) -> void:
	max_hp = max_val
	target_hp = curr
	hero_hp_label.text = "%d / %d HP" % [int(curr), int(max_val)]
	if hero_hp_mat:
		hero_hp_mat.set_shader_parameter("current_hp_ratio", curr / max(1.0, max_val))

func _on_skill_cooldown_started(skill_name: String, duration: float) -> void:
	var k = skill_name.to_lower()
	if skill_slots.has(k):
		var slot = skill_slots[k]
		slot["cd_remaining"] = duration
		slot["cd_total"] = max(0.01, duration)
		slot["is_on_cd"] = true
		if slot_materials.has(k):
			slot_materials[k].set_shader_parameter("cooldown_progress", 1.0)
			slot_materials[k].set_shader_parameter("ready_flash", 0.0)

func _update_slot_cooldowns(delta: float) -> void:
	for slot_id in skill_slots:
		var slot = skill_slots[slot_id]
		if slot["is_on_cd"]:
			slot["cd_remaining"] = max(0.0, slot["cd_remaining"] - delta)
			var ratio = slot["cd_remaining"] / slot["cd_total"]
			if slot_materials.has(slot_id):
				slot_materials[slot_id].set_shader_parameter("cooldown_progress", ratio)
				
			if slot["cd_remaining"] <= 0.0:
				slot["is_on_cd"] = false
				# Ready flash trigger
				_trigger_ready_flash(slot_id)

func _trigger_ready_flash(slot_id: String) -> void:
	if not slot_materials.has(slot_id):
		return
	var mat = slot_materials[slot_id]
	var tw = create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("ready_flash", v), 1.0, 0.0, 0.3)

# ==============================================================================
# BOSS HP BAR HOOKS
# ==============================================================================

func hook_boss(boss_node: Node3D, boss_name: String, max_boss_hp: float) -> void:
	boss_container.visible = true
	boss_name_label.text = "☠️ " + boss_name + "   [PHASE 1/2]"
	boss_max_hp = max_boss_hp
	boss_target_hp = max_boss_hp
	boss_delayed_hp = max_boss_hp
	boss_hp_label.text = "%d / %d HP" % [int(max_boss_hp), int(max_boss_hp)]
	if boss_hp_mat:
		boss_hp_mat.set_shader_parameter("current_hp_ratio", 1.0)
		boss_hp_mat.set_shader_parameter("delayed_hp_ratio", 1.0)
		
	if boss_node.has_signal("health_updated") and not boss_node.health_updated.is_connected(_on_boss_health_updated):
		boss_node.health_updated.connect(_on_boss_health_updated)

func _on_boss_health_updated(curr: float, max_val: float) -> void:
	boss_max_hp = max_val
	boss_target_hp = curr
	boss_hp_label.text = "%d / %d HP" % [int(curr), int(max_val)]
	if boss_hp_mat:
		boss_hp_mat.set_shader_parameter("current_hp_ratio", curr / max(1.0, max_val))
	if curr <= 0.0:
		var tw = create_tween()
		tw.tween_interval(1.5)
		tw.tween_callback(func(): boss_container.visible = false)
