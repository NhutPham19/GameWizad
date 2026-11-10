class_name ElementalCore3D
extends Node3D

# ==============================================================================
# ELEMENTAL CORE 3D - 5 LÕI NGUYÊN TỐ RƠI REAL-TIME (KHÔNG DỪNG GAME)
# Argons Directive 07 - Sprint 2
# ==============================================================================

const SynthAudio = preload("res://scripts/core/synth_audio.gd")
const DamageNumber3D = preload("res://scripts/ui/damage_number_3d.gd")

@export var element_type: String = "fire"

var core_mesh: MeshInstance3D = null
var satellite_ring: MeshInstance3D = null
var point_light: OmniLight3D = null

var elapsed: float = 0.0
var spawn_arming_timer: float = 0.3
var is_homing: bool = false
var homing_speed: float = 11.0
var magnet_radius: float = 4.0
var pickup_radius: float = 0.7
var is_collected: bool = false
var current_hero: Node3D = null

const CORE_PROPERTIES := {
	"fire": {
		"color": Color(1.0, 0.28, 0.05),
		"name_vi": "LÕI HỎA DIỆM",
		"icon_symbol": "🔥"
	},
	"wind": {
		"color": Color(0.2, 0.95, 0.65),
		"name_vi": "LÕI CUỒNG PHONG",
		"icon_symbol": "🌪️"
	},
	"lightning": {
		"color": Color(0.85, 0.4, 1.0),
		"name_vi": "LÕI LÔI ĐIỆN",
		"icon_symbol": "⚡"
	},
	"earth": {
		"color": Color(0.9, 0.7, 0.25),
		"name_vi": "LÕI ĐỊA NGUYÊN",
		"icon_symbol": "⛰️"
	},
	"water": {
		"color": Color(0.15, 0.8, 1.0),
		"name_vi": "LÕI HÀN BĂNG",
		"icon_symbol": "❄️"
	}
}

func setup(p_element: String, p_pos: Vector3) -> void:
	element_type = p_element
	global_position = p_pos
	_build_core_visuals()
	_start_spawn_bounce()

func _ready() -> void:
	if not core_mesh:
		_build_core_visuals()
	_start_spawn_bounce()

func _start_spawn_bounce() -> void:
	var tw = create_tween()
	var base_y = global_position.y
	tw.tween_property(self, "global_position:y", base_y + 0.6, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:y", base_y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _build_core_visuals() -> void:
	var prop = CORE_PROPERTIES.get(element_type, CORE_PROPERTIES["fire"])
	var col: Color = prop["color"]
	
	# 1. Polyhedral Core Mesh (distinct per element)
	core_mesh = MeshInstance3D.new()
	core_mesh.name = "CoreMesh"
	
	match element_type:
		"fire":
			var sphere = SphereMesh.new()
			sphere.radius = 0.32
			sphere.height = 0.64
			sphere.radial_segments = 8
			sphere.rings = 6
			core_mesh.mesh = sphere
		"wind":
			var prism = PrismMesh.new()
			prism.size = Vector3(0.55, 0.8, 0.4)
			core_mesh.mesh = prism
		"lightning":
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = 0.05
			cylinder.bottom_radius = 0.45
			cylinder.height = 0.75
			cylinder.radial_segments = 6
			core_mesh.mesh = cylinder
		"earth":
			var crystal = CylinderMesh.new()
			crystal.top_radius = 0.2
			crystal.bottom_radius = 0.4
			crystal.height = 0.75
			crystal.radial_segments = 6 # Faceted earth crystal
			core_mesh.mesh = crystal
		"water":
			var sphere = SphereMesh.new()
			sphere.radius = 0.34
			sphere.height = 0.68
			sphere.radial_segments = 12
			sphere.rings = 8
			core_mesh.mesh = sphere
			
	core_mesh.position.y = 0.7
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 4.5
	core_mesh.material_override = mat
	add_child(core_mesh)
	
	# 2. Orbiting Satellite Ring
	satellite_ring = MeshInstance3D.new()
	satellite_ring.name = "SatelliteRing"
	var torus = TorusMesh.new()
	torus.inner_radius = 0.48
	torus.outer_radius = 0.58
	torus.rings = 16
	torus.ring_segments = 6
	satellite_ring.mesh = torus
	satellite_ring.position.y = 0.7
	satellite_ring.rotation.x = deg_to_rad(40.0)
	
	var r_mat = StandardMaterial3D.new()
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r_mat.albedo_color = col.lightened(0.3)
	satellite_ring.material_override = r_mat
	add_child(satellite_ring)
	
	# 3. Dynamic OmniLight3D (Layer 2 Authentic Lighting)
	point_light = OmniLight3D.new()
	point_light.name = "CoreLight"
	point_light.light_color = col
	point_light.light_energy = 2.8
	point_light.omni_range = 5.5
	point_light.position.y = 0.7
	add_child(point_light)

func _physics_process(delta: float) -> void:
	if is_collected:
		return
		
	elapsed += delta
	
	# Rotate core and orbiting ring
	if core_mesh:
		core_mesh.rotate_y(delta * 2.8)
		core_mesh.rotate_x(delta * 1.2)
		core_mesh.position.y = 0.7 + sin(elapsed * 4.0) * 0.12
	if satellite_ring:
		satellite_ring.rotate_y(-delta * 3.5)
		satellite_ring.rotate_z(delta * 2.0)
		
	if spawn_arming_timer > 0.0:
		spawn_arming_timer = max(0.0, spawn_arming_timer - delta)
		return
		
	# Find hero
	if not current_hero or not is_instance_valid(current_hero):
		var heroes = get_tree().get_nodes_in_group("heroes")
		if heroes.size() > 0:
			current_hero = heroes[0]
			
	if not current_hero or not is_instance_valid(current_hero):
		return
		
	var target_chest = current_hero.global_position + Vector3(0, 1.1, 0)
	var dist = global_position.distance_to(target_chest)
	
	# Magnet check (4.0m)
	if not is_homing and dist <= magnet_radius:
		is_homing = true
		
	if is_homing:
		homing_speed = min(24.0, homing_speed + 28.0 * delta)
		var fly_dir = (target_chest - global_position).normalized()
		global_position += fly_dir * homing_speed * delta
		
		if dist <= pickup_radius or global_position.distance_to(target_chest) <= pickup_radius:
			_collect_core()

func _collect_core() -> void:
	if is_collected:
		return
	is_collected = true
	
	SynthAudio.play_crystal_pickup()
	
	var prop = CORE_PROPERTIES.get(element_type, CORE_PROPERTIES["fire"])
	var col: Color = prop["color"]
	var core_name: String = prop["name_vi"]
	var symbol: String = prop["icon_symbol"]
	
	# 1. Level up or apply core to Hero in real-time
	var new_lvl = 1
	var hero = current_hero as HeroBase3D
	if hero:
		if hero.element_type == element_type:
			hero.element_level += 1
			new_lvl = hero.element_level
			hero.base_damage *= 1.15
			hero.max_hp += 15.0
			hero.current_hp = min(hero.max_hp, hero.current_hp + 20.0)
			hero.health_changed.emit(hero.current_hp, hero.max_hp)
		else:
			# Check fusion spell unlock
			var fusion_id = _check_fusion_unlock(hero.element_type, element_type)
			if fusion_id != "":
				var fdata = FusionMatrix.get_fusion_spell_data(fusion_id)
				hero.equip_fusion_spell(fusion_id, fdata)
				
	# 2. Spawn Floating 3D Text rising above Hero
	var text_label = symbol + " + " + core_name + " (Lv." + str(new_lvl) + ")!"
	_spawn_floating_text(text_label, col)
	
	# 3. Energy Shockwave: Push back nearby monsters (Radius 2.5m)
	_trigger_safe_shockwave(2.5)
	
	# 4. Notify StylizedArcaneHUD (real-time notification banner)
	if is_inside_tree() and get_tree():
		var huds = get_tree().get_nodes_in_group("hud")
		for h in huds:
			if h.has_method("notify_core_pickup"):
				h.notify_core_pickup(element_type, new_lvl, text_label, col)
			
	# Quick shrink dissolve
	if is_inside_tree():
		var tw = create_tween()
		tw.tween_property(self, "scale", Vector3.ZERO, 0.15)
		tw.tween_callback(queue_free)
	else:
		queue_free()

func _check_fusion_unlock(hero_elem: String, core_elem: String) -> String:
	return FusionMatrix.get_fusion_id(hero_elem, core_elem)

func _spawn_floating_text(text: String, col: Color) -> void:
	if not current_hero or not get_parent():
		return
	var dmg_num = DamageNumber3D.new()
	get_parent().add_child(dmg_num)
	dmg_num.global_position = current_hero.global_position + Vector3(0, 1.8, 0)
	if dmg_num.has_method("setup"):
		dmg_num.setup(0.0, dmg_num.global_position, true, col)
		var lbl = dmg_num.get_node_or_null("Label3D") as Label3D
		if lbl:
			lbl.text = text
			lbl.modulate = col
			lbl.font_size = 28

func _trigger_safe_shockwave(radius: float) -> void:
	if not is_inside_tree() or not get_tree():
		return
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e) or not ("global_position" in e):
			continue
		var to_enemy = e.global_position - global_position
		to_enemy.y = 0.0
		var d = to_enemy.length()
		if d <= radius and d > 0.01:
			var push_dir = to_enemy.normalized()
			if "velocity" in e:
				e.velocity += push_dir * 12.0
