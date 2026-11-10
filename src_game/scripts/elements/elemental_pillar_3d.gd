class_name ElementalPillar3D
extends Node3D

const SynthAudio = preload("res://scripts/core/synth_audio.gd")

# ==============================================================================
# ELEMENTAL PILLAR 3D - TRỤ TINH THỂ NGUYÊN TỐ TỰ ĐỘNG TỪ TRƯỜNG (AUTO-MAGNETIC)
# Task 2.4B: Không cần bấm F, Bán kính 4.0m, Vận tốc 10->22m/s, Trễ 0.7s, Chờ Dash
# ==============================================================================

@export var element_type: String = "fire"

var crystal_mesh: MeshInstance3D = null
var ground_rune: MeshInstance3D = null

var elapsed: float = 0.0
var spawn_arming_timer: float = 0.7 # 0.7s Arming delay
var is_homing: bool = false
var homing_speed: float = 10.0
var magnet_radius: float = 4.0
var pickup_radius: float = 0.65
var is_waiting_dash: bool = false
var is_collected: bool = false

var current_hero: Node3D = null

const ELEMENT_COLORS := {
	"fire": Color(1.0, 0.3, 0.08),       # Đỏ Cam
	"wind": Color(0.2, 0.95, 0.7),       # Xanh Ngọc
	"lightning": Color(0.85, 0.4, 1.0),   # Tím Vàng
	"earth": Color(0.9, 0.65, 0.2),      # Vàng Đất
	"water": Color(0.15, 0.7, 1.0)       # Xanh Lam
}

const ELEMENT_VI_NAMES := {
	"fire": "Hỏa Thần Thạch",
	"wind": "Phong Tinh Thạch",
	"lightning": "Lôi Quang Thạch",
	"earth": "Địa Mạch Thạch",
	"water": "Thủy Ngọc Thạch"
}

func setup(p_element: String, p_pos: Vector3) -> void:
	element_type = p_element
	global_position = p_pos
	if not crystal_mesh:
		_create_crystal_visuals()
	_start_spawn_bounce()

func _ready() -> void:
	if not crystal_mesh:
		_create_crystal_visuals()
	_start_spawn_bounce()

func _start_spawn_bounce() -> void:
	var tw = create_tween()
	var base_y = global_position.y
	tw.tween_property(self, "global_position:y", base_y + 0.8, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:y", base_y, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _create_crystal_visuals() -> void:
	var elem_color = ELEMENT_COLORS.get(element_type, Color.WHITE)
	
	# Floating Polyhedron Crystal
	crystal_mesh = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(0.85, 1.5, 0.85)
	crystal_mesh.mesh = prism
	crystal_mesh.position.y = 1.4
	crystal_mesh.rotation.z = PI # Point downwards for diamond crystal shape
	
	var mat = StandardMaterial3D.new()
	mat.roughness = 0.15
	mat.metallic = 0.4
	mat.albedo_color = elem_color
	mat.emission_enabled = true
	mat.emission = elem_color
	mat.emission_energy_multiplier = 4.2 # Vivid Bloom
	crystal_mesh.material_override = mat
	add_child(crystal_mesh)
	
	# Ground Rotating Runic Circle
	ground_rune = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.2
	torus.outer_radius = 1.45
	ground_rune.mesh = torus
	ground_rune.position.y = 0.04
	
	var r_mat = StandardMaterial3D.new()
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r_mat.albedo_color = elem_color
	r_mat.emission_enabled = true
	r_mat.emission = elem_color
	r_mat.emission_energy_multiplier = 3.0
	ground_rune.material_override = r_mat
	add_child(ground_rune)

func _physics_process(delta: float) -> void:
	if is_collected:
		return
		
	elapsed += delta
	
	# 1. Arming Delay (0.7s)
	if spawn_arming_timer > 0.0:
		spawn_arming_timer = max(0.0, spawn_arming_timer - delta)
		if crystal_mesh:
			crystal_mesh.rotate_y(delta * 2.0)
		if ground_rune:
			ground_rune.rotate_y(-delta * 1.5)
		return
		
	# 2. Acquire Hero Target
	if not current_hero or not is_instance_valid(current_hero):
		var heroes = get_tree().get_nodes_in_group("heroes")
		if heroes.size() > 0:
			current_hero = heroes[0]
			
	if not current_hero or not is_instance_valid(current_hero):
		return
		
	var target_chest = current_hero.global_position + Vector3(0, 1.1, 0)
	var dist = global_position.distance_to(target_chest)
	
	# 3. Check Magnetic Attraction (Radius 4.0m)
	if not is_homing and dist <= magnet_radius:
		is_homing = true
		if ground_rune:
			# Fade out ground rune once crystal takes flight
			var r_tw = create_tween()
			r_tw.tween_property(ground_rune, "scale", Vector3.ZERO, 0.2)
			r_tw.tween_callback(ground_rune.queue_free)
			ground_rune = null
			
	if is_homing:
		# Accelerate speed from 10.0m/s to 22.0m/s
		homing_speed = min(22.0, homing_speed + 24.0 * delta)
		var fly_dir = (target_chest - global_position).normalized()
		global_position += fly_dir * homing_speed * delta
		
		if crystal_mesh:
			crystal_mesh.rotate_y(delta * 10.0)
			crystal_mesh.scale = crystal_mesh.scale.move_toward(Vector3(0.6, 0.6, 0.6), delta * 0.8)
			
		# Check collection threshold (< 0.65m)
		if dist <= pickup_radius or global_position.distance_to(target_chest) <= pickup_radius:
			# If hero is dashing, wait for dash to finish!
			if ("is_dashing" in current_hero) and current_hero.is_dashing:
				is_waiting_dash = true
				global_position = target_chest
			else:
				_trigger_auto_collection()
	else:
		# Idle bobbing and spinning
		if crystal_mesh:
			crystal_mesh.position.y = 1.4 + sin(elapsed * 3.0) * 0.2
			crystal_mesh.rotate_y(delta * 2.5)
		if ground_rune:
			ground_rune.rotate_y(-delta * 1.5)

func _trigger_auto_collection() -> void:
	if is_collected:
		return
	is_collected = true
	
	SynthAudio.play_crystal_pickup()
	print("🧲 [AUTO-PICKUP] Crystal collected real-time: ", element_type)
	
	if current_hero and current_hero.has_method("apply_elemental_crystal"):
		current_hero.apply_elemental_crystal(element_type)
	elif current_hero is HeroBase3D:
		var hero = current_hero as HeroBase3D
		if hero.element_type == element_type:
			hero.element_level += 1
		else:
			var fid = FusionMatrix.get_fusion_id(hero.element_type, element_type)
			if fid != "":
				var fdata = FusionMatrix.get_fusion_spell_data(fid)
				hero.equip_fusion_spell(fid, fdata)
				
	# Real-time HUD banner notification
	var huds = get_tree().get_nodes_in_group("hud")
	var elem_color = ELEMENT_COLORS.get(element_type, Color.WHITE)
	for h in huds:
		if h.has_method("notify_core_pickup"):
			h.notify_core_pickup(element_type, 1, "+ LÕI " + element_type.to_upper(), elem_color)
			
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.15)
	tw.tween_callback(queue_free)
