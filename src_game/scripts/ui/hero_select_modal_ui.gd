class_name HeroSelectModalUI
extends CanvasLayer

# ==============================================================================
# HERO SELECT MODAL UI - BẢNG CHỌN 2 NHÂN VẬT MỚI (PHÍM M HOẶC CLICK)
# Argons Directive 12: Đóng băng tướng cũ, nổi bật Solaris & Nyx
# ==============================================================================

signal hero_chosen(index: int)

var hero_manager: HeroManager = null
var cards_box: HBoxContainer = null
var overlay: ColorRect = null

const HEROES_DATA := [
	{
		"index": 1,
		"name": "SOLARIS",
		"title": "Thánh Kỵ Sĩ Thái Dương",
		"element": "THÁI DƯƠNG (SOLAR PALADIN)",
		"color": Color(1.0, 0.75, 0.18),
		"icon": "res://assets/ui/icons/icon_solaris_avatar.svg",
		"stats": "HP: 120 | Tốc: 6.0 | Sát thương: 22.0",
		"weapons": "Bộ 1: Đại Kiếm [2H] | Bộ 2: Kiếm & Khiên [1H+Shield]",
		"lmb": "Thánh Quang Liên Trảm (Combo 3 nhịp vàng cam)",
		"rmb": "Khiên Lửa Thái Dương (Vòng lửa 4.5m + Giáp ảo)",
		"q": "Thiên Phạt Thánh Kiếm (Dung nham 9m + Cột sáng)"
	},
	{
		"index": 2,
		"name": "NYX",
		"title": "Thợ Săn Tinh Không",
		"element": "TINH KHÔNG (ASTRAL HUNTER)",
		"color": Color(0.0, 0.9, 1.0),
		"icon": "res://assets/ui/icons/icon_nyx_avatar.svg",
		"stats": "HP: 95 | Tốc: 6.8 | Sát thương: 19.0",
		"weapons": "Bộ 1: Đại Nỏ [2H] | Bộ 2: Pháp Khí & Đũa Phép [1H]",
		"lmb": "Tiễn Ánh Sao Xuyên Thấu (3 tiễn hình thoi + Sét nảy)",
		"rmb": "Bẫy Xoáy Không Gian (Lùi bóng mờ + Hút quái)",
		"q": "Bão Điện Từ Ngân Hà (Trận pháp 10m + 12 sét)"
	}
]

func _ready() -> void:
	add_to_group("hero_select_ui")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_update_mouse_filters()

func _update_mouse_filters() -> void:
	if overlay:
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE

func _build_ui() -> void:
	# Fullscreen overlay dimmer
	overlay = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.04, 0.05, 0.08, 0.88)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	# Header
	var title = Label.new()
	title.text = "✦ ĐẤU TRƯỜNG CHỌN 2 NHÂN VẬT MỚI: SOLARIS & NYX ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Bấm phím số [1] SOLARIS | [2] NYX | Phím [X] Đổi 2 Bộ Vũ Khí (KayKit 3D) | [M] Đóng menu"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(subtitle)
	
	cards_box = HBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 32)
	vbox.add_child(cards_box)
	
	for hero in HEROES_DATA:
		var card = _create_hero_card(hero)
		cards_box.add_child(card)

func _create_hero_card(data: Dictionary) -> Panel:
	var p = Panel.new()
	p.custom_minimum_size = Vector2(340, 480)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = data["color"]
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	p.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	p.add_child(margin)
	
	var cvbox = VBoxContainer.new()
	cvbox.add_theme_constant_override("separation", 10)
	margin.add_child(cvbox)
	
	# Key & Avatar Row
	var top_hbox = HBoxContainer.new()
	cvbox.add_child(top_hbox)
	
	var key_lbl = Label.new()
	key_lbl.text = "PHÍM [" + str(data["index"]) + "]"
	key_lbl.add_theme_font_size_override("font_size", 22)
	key_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	key_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(key_lbl)
	
	if ResourceLoader.exists(data.get("icon", "")):
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(40, 40)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = load(data["icon"])
		top_hbox.add_child(icon_rect)
	
	var name_lbl = Label.new()
	name_lbl.text = data["name"]
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", data["color"])
	cvbox.add_child(name_lbl)
	
	var title_lbl = Label.new()
	title_lbl.text = data["title"] + "  (" + data["element"] + ")"
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	cvbox.add_child(title_lbl)
	
	cvbox.add_child(HSeparator.new())
	
	var stats_lbl = Label.new()
	stats_lbl.text = data["stats"]
	stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_lbl.add_theme_font_size_override("font_size", 13)
	stats_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 0.7))
	cvbox.add_child(stats_lbl)
	
	var wep_lbl = Label.new()
	wep_lbl.text = "Vũ Khí [Phím X]: " + data.get("weapons", "")
	wep_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wep_lbl.add_theme_font_size_override("font_size", 12)
	wep_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	cvbox.add_child(wep_lbl)
	
	cvbox.add_child(HSeparator.new())
	
	var skills_title = Label.new()
	skills_title.text = "BỘ KỸ NĂNG NGUYÊN TỐ:"
	skills_title.add_theme_font_size_override("font_size", 13)
	skills_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	cvbox.add_child(skills_title)
	
	var lmb_lbl = Label.new()
	lmb_lbl.text = "• LMB: " + data["lmb"]
	lmb_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lmb_lbl.add_theme_font_size_override("font_size", 12)
	cvbox.add_child(lmb_lbl)
	
	var rmb_lbl = Label.new()
	rmb_lbl.text = "• RMB: " + data["rmb"]
	rmb_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rmb_lbl.add_theme_font_size_override("font_size", 12)
	cvbox.add_child(rmb_lbl)
	
	var q_lbl = Label.new()
	q_lbl.text = "• Q: " + data["q"]
	q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q_lbl.add_theme_font_size_override("font_size", 12)
	q_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cvbox.add_child(q_lbl)
	
	var btn = Button.new()
	btn.text = "Chọn " + data["name"] + " [Phím " + str(data["index"]) + "]"
	btn.custom_minimum_size = Vector2(0, 42)
	btn.pressed.connect(_select_hero.bind(data["index"]))
	cvbox.add_child(btn)
	
	return p

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("hero_select_menu"):
		toggle_visibility()
		get_viewport().set_input_as_handled()
		return
		
	if not visible:
		return
		
	if event.is_action_pressed("hero_1"):
		_select_hero(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hero_2"):
		_select_hero(2)
		get_viewport().set_input_as_handled()

func toggle_visibility() -> void:
	visible = not visible
	_update_mouse_filters()
	if visible:
		Engine.time_scale = 0.15
	else:
		Engine.time_scale = 1.0

func _select_hero(index: int) -> void:
	visible = false
	_update_mouse_filters()
	Engine.time_scale = 1.0
	
	if not hero_manager or not is_instance_valid(hero_manager):
		var mgrs = get_tree().get_nodes_in_group("hero_manager")
		if mgrs.size() > 0:
			hero_manager = mgrs[0]
			
	if hero_manager and is_instance_valid(hero_manager):
		hero_manager.switch_to_hero(index)
		
	hero_chosen.emit(index)
	print("🧙 [HERO SELECT] Selected hero #", index)
