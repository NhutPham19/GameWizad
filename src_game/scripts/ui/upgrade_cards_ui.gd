class_name UpgradeCardsUI
extends CanvasLayer

# ==============================================================================
# UPGRADE CARDS UI - GIAO DIỆN 3 THẺ BÀI CHỌN NGUYÊN TỐ / DUNG HỢP (BULLET-TIME)
# Task 2.4B: Hàng Đợi (Queue), Chống Click Nhầm 0.45s, Safe Pulse 3.2m & I-Frames 1.0s
# ==============================================================================

signal upgrade_selected(choice_data: Dictionary)

var current_hero: Node3D = null
var current_pillar: Node3D = null
var current_element: String = ""
var cards_data: Array[Dictionary] = []

var pending_upgrade_queue: Array[Dictionary] = []
var opened_ticks_msec: int = 0
const INPUT_GRACE_PERIOD_MS: int = 450 # 0.45s Lock to prevent accidental misclick

var panel_container: PanelContainer = null
var title_label: Label = null
var cards_box: HBoxContainer = null
var card_panels: Array[Panel] = []

func _ready() -> void:
	add_to_group("upgrade_ui")
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED # Task 5.1: Disabled when hidden to never block mouse
	if not cards_box:
		_build_ui()
	_set_mouse_filter_recursive(self, Control.MOUSE_FILTER_IGNORE)

func _set_mouse_filter_recursive(node: Node, filter: int) -> void:
	if node is Control:
		if not (node is Button and visible):
			node.mouse_filter = filter
	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)

func _build_ui() -> void:
	if cards_box:
		return
	# Fullscreen overlay dimmer
	var overlay = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.04, 0.05, 0.08, 0.8)
	add_child(overlay)
	
	# Center container
	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)
	
	# Title
	title_label = Label.new()
	title_label.text = "✦ CHỌN PHƯỚC LÀNH CỔ ĐẠI ✦"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	vbox.add_child(title_label)
	
	var subtitle = Label.new()
	subtitle.text = "Nhấp chuột hoặc bấm phím [1] [2] [3] để chọn (Khóa thao tác 0.45s chống click nhầm)"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.8))
	vbox.add_child(subtitle)
	
	# Cards HBox
	cards_box = HBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 32)
	vbox.add_child(cards_box)

func enqueue_or_present(hero: Node3D, crystal_element: String, pillar: Node3D) -> void:
	if visible:
		# Already presenting! Enqueue to prevent time_scale override conflict
		pending_upgrade_queue.append({
			"hero": hero,
			"element": crystal_element,
			"pillar": pillar
		})
		if pillar and is_instance_valid(pillar):
			pillar.visible = false
		print("📦 [UPGRADE QUEUE] Enqueued crystal. Pending in queue: ", pending_upgrade_queue.size())
		return
		
	present_choices(hero, crystal_element, pillar)

func present_choices(hero: Node3D, crystal_element: String, pillar: Node3D) -> void:
	if not cards_box:
		_build_ui()
	current_hero = hero
	current_element = crystal_element
	current_pillar = pillar
	
	# Record unscaled time for anti-missclick grace period
	opened_ticks_msec = Time.get_ticks_msec()
	
	# Bullet-time slowdown
	Engine.time_scale = 0.15
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_generate_cards_data()
	_render_cards()
	
	# Scale animation for cards
	for p in card_panels:
		p.scale = Vector2(0.85, 0.85)
		p.pivot_offset = p.custom_minimum_size / 2.0
		var tw = p.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(p, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _generate_cards_data() -> void:
	cards_data.clear()
	var hero_elem = current_hero.element_type if (current_hero and "element_type" in current_hero) else "fire"
	var current_lv = current_hero.element_level if (current_hero and "element_level" in current_hero) else 1
	var next_lv = current_lv + 1
	
	# Card 1: Upgrade Hero's Current Core Element
	var c1 = {
		"type": "upgrade_element",
		"title": "CƯỜNG HÓA: " + hero_elem.to_upper(),
		"tag": "Cấp " + str(next_lv) + " (Lv." + str(next_lv) + ")",
		"desc": "+30% Sát thương, +35% Kích thước chiêu 3D, -20% Hồi chiêu",
		"accent_color": Color(1.0, 0.7, 0.2),
		"element": hero_elem
	}
	cards_data.append(c1)
	
	# Card 2: Fusion Spell (Hero Element + Crystal Element)
	var fusion = FusionMatrix.get_fusion_data(hero_elem, current_element)
	if fusion.is_empty():
		var other_elems = ["fire", "wind", "lightning", "earth", "water"]
		other_elems.erase(hero_elem)
		var rand_other = other_elems[randi() % other_elems.size()]
		fusion = FusionMatrix.get_fusion_data(hero_elem, rand_other)
		
	var c2 = {
		"type": "fusion_spell",
		"title": "DUNG HỢP: " + fusion.get("name_vi", "Tuyệt Kỹ"),
		"tag": "[Phím E] Dung Hợp",
		"desc": fusion.get("desc", ""),
		"accent_color": fusion.get("icon_color", Color(0.4, 0.9, 1.0)),
		"spell_id": fusion.get("id", ""),
		"spell_data": fusion
	}
	cards_data.append(c2)
	
	# Card 3: Vitality or Arcane Resonance
	var c3 = {
		"type": "vitality_infusion",
		"title": "TIỂU KHÍ NGUYÊN TỐ",
		"tag": "[Nội Tại] Sinh Mệnh",
		"desc": "Hồi phục ngay 40 HP & Tăng vĩnh viễn 15% Tốc độ di chuyển",
		"accent_color": Color(0.3, 0.95, 0.5),
		"heal_amount": 40.0,
		"speed_boost": 1.15
	}
	cards_data.append(c3)

func _render_cards() -> void:
	for child in cards_box.get_children():
		child.queue_free()
	card_panels.clear()
	
	for i in range(cards_data.size()):
		var data = cards_data[i]
		var card = _create_card_widget(i, data)
		cards_box.add_child(card)
		card_panels.append(card)

func _create_card_widget(index: int, data: Dictionary) -> Panel:
	var p = Panel.new()
	p.custom_minimum_size = Vector2(290, 390)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.16, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = data.get("accent_color", Color.WHITE)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	p.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	p.add_child(margin)
	
	var cvbox = VBoxContainer.new()
	cvbox.add_theme_constant_override("separation", 14)
	margin.add_child(cvbox)
	
	var key_badge = Label.new()
	key_badge.text = "[" + str(index + 1) + "]"
	key_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_badge.add_theme_font_size_override("font_size", 22)
	key_badge.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	cvbox.add_child(key_badge)
	
	var tag_lbl = Label.new()
	tag_lbl.text = data.get("tag", "")
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_size_override("font_size", 14)
	tag_lbl.add_theme_color_override("font_color", data.get("accent_color", Color.WHITE))
	cvbox.add_child(tag_lbl)
	
	var t_lbl = Label.new()
	t_lbl.text = data.get("title", "")
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t_lbl.add_theme_font_size_override("font_size", 18)
	t_lbl.add_theme_color_override("font_color", Color.WHITE)
	cvbox.add_child(t_lbl)
	
	var hs = HSeparator.new()
	cvbox.add_child(hs)
	
	var d_lbl = Label.new()
	d_lbl.text = data.get("desc", "")
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	d_lbl.add_theme_font_size_override("font_size", 14)
	d_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	cvbox.add_child(d_lbl)
	
	var btn = Button.new()
	btn.text = "Chọn Thẻ [" + str(index + 1) + "]"
	btn.custom_minimum_size = Vector2(0, 44)
	btn.pressed.connect(_on_card_selected.bind(index))
	cvbox.add_child(btn)
	
	return p

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	# Block input during 0.45s grace period
	if Time.get_ticks_msec() - opened_ticks_msec < INPUT_GRACE_PERIOD_MS:
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("hero_1"):
		_on_card_selected(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hero_2"):
		_on_card_selected(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hero_3"):
		_on_card_selected(2)
		get_viewport().set_input_as_handled()

func _on_card_selected(index: int) -> void:
	if not visible:
		return
		
	# Anti-missclick guard
	if Time.get_ticks_msec() - opened_ticks_msec < INPUT_GRACE_PERIOD_MS:
		return
		
	if index < 0 or index >= cards_data.size():
		return
		
	var choice = cards_data[index]
	_apply_choice(choice)
	
	# Clean up pillar
	if current_pillar and is_instance_valid(current_pillar):
		current_pillar.queue_free()
		current_pillar = null
		
	upgrade_selected.emit(choice)
	print("✨ [UPGRADE CARDS UI] Applied choice: ", choice.get("title", ""))
	
	# Execute Post-Upgrade Safe Pulse (3.2m shockwave + 1.0s I-frames)
	_execute_post_upgrade_safe_pulse()
	
	# Check PickupQueue
	if pending_upgrade_queue.size() > 0:
		visible = false
		var next_item = pending_upgrade_queue.pop_front()
		# Open next after 0.3s
		if is_inside_tree() and get_tree():
			var tw = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_interval(0.3)
			tw.tween_callback(func():
				if is_instance_valid(next_item.hero) and is_instance_valid(next_item.pillar):
					next_item.pillar.visible = true
					present_choices(next_item.hero, next_item.element, next_item.pillar)
				else:
					Engine.time_scale = 1.0
			)
		else:
			if is_instance_valid(next_item.hero) and is_instance_valid(next_item.pillar):
				next_item.pillar.visible = true
				present_choices(next_item.hero, next_item.element, next_item.pillar)
	else:
		Engine.time_scale = 1.0
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		_set_mouse_filter_recursive(self, Control.MOUSE_FILTER_IGNORE)

func _execute_post_upgrade_safe_pulse() -> void:
	if not current_hero or not is_instance_valid(current_hero):
		return
		
	# 1.0s I-frames for hero
	if current_hero.has_method("grant_invulnerability"):
		current_hero.grant_invulnerability(1.0)
		
	if not is_inside_tree() or not get_tree():
		return
		
	# 3.2m Shockwave pushback on surrounding enemies
	var center = current_hero.global_position
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e is CharacterBody3D:
			var diff = e.global_position - center
			diff.y = 0.0
			var dist = diff.length()
			if dist <= 3.2:
				var push_dir = diff.normalized() if dist > 0.05 else Vector3.FORWARD
				e.velocity += push_dir * 14.0
				
	# Visual Shockwave Ring 3D
	var shock_mesh = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.4
	torus.outer_radius = 0.7
	shock_mesh.mesh = torus
	shock_mesh.global_position = center + Vector3(0, 0.1, 0)
	
	var s_mat = StandardMaterial3D.new()
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s_mat.albedo_color = Color(1.0, 0.9, 0.4, 0.9)
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shock_mesh.material_override = s_mat
	
	current_hero.get_parent().add_child(shock_mesh)
	
	var tw = shock_mesh.create_tween()
	tw.tween_property(shock_mesh, "scale", Vector3(4.5, 1.0, 4.5), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s_mat, "albedo_color:a", 0.0, 0.35)
	tw.tween_callback(shock_mesh.queue_free)

func _apply_choice(choice: Dictionary) -> void:
	if not current_hero or not is_instance_valid(current_hero):
		return
		
	match choice.get("type", ""):
		"upgrade_element":
			if "element_level" in current_hero:
				current_hero.element_level += 1
			if "base_damage" in current_hero:
				current_hero.base_damage *= 1.3
			print("⭐ Hero upgraded to Lv.", current_hero.element_level)
		"fusion_spell":
			var spell_id = choice.get("spell_id", "")
			var spell_data = choice.get("spell_data", {})
			if current_hero.has_method("equip_fusion_spell"):
				current_hero.equip_fusion_spell(spell_id, spell_data)
			if is_inside_tree() and get_tree():
				var huds = get_tree().get_nodes_in_group("hud")
				if huds.size() > 0:
					huds[0].update_fusion_slot(spell_data)
		"vitality_infusion":
			if "current_hp" in current_hero and "max_hp" in current_hero:
				current_hero.current_hp = min(current_hero.max_hp, current_hero.current_hp + choice.get("heal_amount", 40.0))
			if "move_speed" in current_hero:
				current_hero.move_speed *= choice.get("speed_boost", 1.15)
