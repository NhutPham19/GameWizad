class_name HealthOrb3D
extends Node3D

const SynthAudio = preload("res://scripts/core/synth_audio.gd")

# ==============================================================================
# HEALTH ORB 3D - NGỌC SINH MỆNH TỰ ĐỘNG HÚT & HỒI MÁU TỨC THÌ
# Task 2.4B: Hút nam châm 5.0m, Hồi 15 HP, nổ hạt sáng KHÔNG bật UI dừng hình
# ==============================================================================

@export var heal_amount: float = 15.0
@export var orb_color: Color = Color(0.2, 1.0, 0.45) # Emerald Green Glow

var orb_mesh: MeshInstance3D = null
var halo_mesh: MeshInstance3D = null

var elapsed: float = 0.0
var homing_speed: float = 12.0
var magnet_radius: float = 5.0
var pickup_radius: float = 0.65
var is_homing: bool = false
var is_collected: bool = false

var current_hero: Node3D = null

func _ready() -> void:
	add_to_group("health_orbs")
	_create_visuals()
	_start_spawn_hop()

func setup(p_pos: Vector3, p_heal: float = 15.0) -> void:
	global_position = p_pos
	heal_amount = p_heal

func _create_visuals() -> void:
	# Core Glowing Orb
	orb_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	orb_mesh.mesh = sphere
	orb_mesh.position.y = 0.6
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = orb_color
	mat.emission_enabled = true
	mat.emission = orb_color
	mat.emission_energy_multiplier = 4.5 # Radiant bloom
	orb_mesh.material_override = mat
	add_child(orb_mesh)
	
	# Orbiting Arcane Ring
	halo_mesh = MeshInstance3D.new()
	var ring = TorusMesh.new()
	ring.inner_radius = 0.32
	ring.outer_radius = 0.38
	halo_mesh.mesh = ring
	halo_mesh.position.y = 0.6
	
	var r_mat = StandardMaterial3D.new()
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r_mat.albedo_color = Color(1.0, 1.0, 0.7, 0.8)
	halo_mesh.material_override = r_mat
	add_child(halo_mesh)

func _start_spawn_hop() -> void:
	var tw = create_tween()
	var base_y = global_position.y
	tw.tween_property(self, "global_position:y", base_y + 0.6, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:y", base_y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	if is_collected:
		return
		
	elapsed += delta
	
	if not current_hero or not is_instance_valid(current_hero):
		var heroes = get_tree().get_nodes_in_group("heroes")
		if heroes.size() > 0:
			current_hero = heroes[0]
			
	if not current_hero or not is_instance_valid(current_hero):
		return
		
	var target_chest = current_hero.global_position + Vector3(0, 1.0, 0)
	var dist = global_position.distance_to(target_chest)
	
	if not is_homing and dist <= magnet_radius:
		is_homing = true
		
	if is_homing:
		homing_speed = min(26.0, homing_speed + 28.0 * delta)
		var fly_dir = (target_chest - global_position).normalized()
		global_position += fly_dir * homing_speed * delta
		
		if orb_mesh:
			orb_mesh.rotate_y(delta * 12.0)
		if halo_mesh:
			halo_mesh.rotate_x(delta * 14.0)
			
		if dist <= pickup_radius or global_position.distance_to(target_chest) <= pickup_radius:
			_collect_orb()
	else:
		if orb_mesh:
			orb_mesh.position.y = 0.6 + sin(elapsed * 4.0) * 0.12
		if halo_mesh:
			halo_mesh.position.y = 0.6 + sin(elapsed * 4.0) * 0.12
			halo_mesh.rotate_y(delta * 3.0)
			halo_mesh.rotate_z(delta * 2.0)

func _collect_orb() -> void:
	if is_collected:
		return
	is_collected = true
	
	SynthAudio.play_health_pickup()
	
	# Heal hero
	if current_hero and is_instance_valid(current_hero):
		if "current_hp" in current_hero and "max_hp" in current_hero:
			current_hero.current_hp = min(current_hero.max_hp, current_hero.current_hp + heal_amount)
			if current_hero.has_signal("health_changed"):
				current_hero.health_changed.emit(current_hero.current_hp, current_hero.max_hp)
				
		# Floating +15 HP Text
		if get_parent():
			var dmg_num = DamageNumber3D.new()
			get_parent().add_child(dmg_num)
			dmg_num.setup(heal_amount, global_position, true, Color(0.2, 1.0, 0.4))
			
		print("💚 [HEALTH ORB] Picked up +", heal_amount, " HP! Hero HP: ", current_hero.current_hp, "/", current_hero.max_hp)
		
	# Quick burst particle visual
	var burst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	burst.mesh = sphere
	burst.global_position = global_position
	
	var b_mat = StandardMaterial3D.new()
	b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	b_mat.albedo_color = Color(0.4, 1.0, 0.6, 0.9)
	burst.material_override = b_mat
	
	if get_parent():
		get_parent().add_child(burst)
		var tw = burst.create_tween()
		tw.tween_property(burst, "scale", Vector3(2.5, 2.5, 2.5), 0.2)
		tw.parallel().tween_property(b_mat, "albedo_color:a", 0.0, 0.2)
		tw.tween_callback(burst.queue_free)
		
	queue_free()
