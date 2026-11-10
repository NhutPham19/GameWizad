class_name HeroManager
extends Node3D

# ==============================================================================
# HERO MANAGER - SWITCH BETWEEN 2 NEW HEROES (KEYS 1 & 2)
# Argons Directive 12: Freezes Heroes 1-5, Active Pool: Solaris (1) & Nyx (2)
# ==============================================================================

signal hero_switched(new_hero: HeroBase3D)

const SCENES := {
	1: preload("res://scenes/characters/hero_solaris.tscn"),
	2: preload("res://scenes/characters/hero_nyx.tscn")
}

var _hero_pool: Dictionary = {}
var _hero_switched_once: Dictionary = {}
var active_hero: HeroBase3D = null
var current_hero_index: int = 1

@export var camera: IsometricCamera3D = null

func _ready() -> void:
	add_to_group("hero_manager")
	_init_hero_pool()

func _init_hero_pool() -> void:
	# Check if a hero was already placed in the scene tree
	var preplaced_hero: HeroBase3D = null
	for child in get_children():
		if child is HeroBase3D:
			preplaced_hero = child
			break
			
	for idx in SCENES.keys():
		var hero_instance: HeroBase3D = null
		if preplaced_hero and (
			(idx == 1 and preplaced_hero.hero_name.to_lower() == "solaris") or
			(idx == 2 and preplaced_hero.hero_name.to_lower() == "nyx")
		):
			hero_instance = preplaced_hero
		else:
			hero_instance = SCENES[idx].instantiate()
			add_child(hero_instance)
			
		hero_instance.visible = false
		hero_instance.process_mode = Node.PROCESS_MODE_DISABLED
		hero_instance.collision_layer = 0
		hero_instance.collision_mask = 0
		if hero_instance.has_node("Hurtbox3D"):
			var hb = hero_instance.get_node("Hurtbox3D")
			hb.monitoring = false
			hb.monitorable = false
			
		_hero_pool[idx] = hero_instance
		
	# Activate default hero (Hero 1: Solaris)
	switch_to_hero(1)

func _unhandled_input(event: InputEvent) -> void:
	# Lock hero switching if UpgradeCardsUI or Hero Select is active
	var upgrade_uis = get_tree().get_nodes_in_group("upgrade_ui")
	for u in upgrade_uis:
		if is_instance_valid(u) and u.visible:
			return
			
	var select_uis = get_tree().get_nodes_in_group("hero_select_ui")
	for su in select_uis:
		if is_instance_valid(su) and su.visible:
			return
			
	if event.is_action_pressed("hero_1"):
		switch_to_hero(1)
	elif event.is_action_pressed("hero_2"):
		switch_to_hero(2)

func switch_hero(index: int) -> void:
	switch_to_hero(index)

func switch_to_hero(index: int) -> void:
	if not _hero_pool.has(index):
		return
	var new_hero: HeroBase3D = _hero_pool[index]
	if not is_instance_valid(new_hero):
		return
		
	if active_hero == new_hero and active_hero.visible:
		return # Already active
		
	var spawn_pos: Vector3 = Vector3.ZERO
	var hp_ratio: float = 1.0
	var cur_vel: Vector3 = Vector3.ZERO
	var facing_rot: float = 0.0
	
	if is_instance_valid(active_hero) and active_hero != new_hero:
		spawn_pos = active_hero.global_position
		hp_ratio = clamp(active_hero.current_hp / max(1.0, active_hero.max_hp), 0.25, 1.0)
		cur_vel = active_hero.velocity
		if active_hero.visual_root:
			facing_rot = active_hero.visual_root.rotation.y
			
		# Deactivate old hero
		active_hero.visible = false
		active_hero.process_mode = Node.PROCESS_MODE_DISABLED
		active_hero.collision_layer = 0
		active_hero.collision_mask = 0
		if active_hero.is_in_group("player"):
			active_hero.remove_from_group("player")
		if active_hero.has_node("Hurtbox3D"):
			var hb = active_hero.get_node("Hurtbox3D")
			hb.monitoring = false
			hb.monitorable = false
	elif is_instance_valid(active_hero):
		spawn_pos = active_hero.global_position
		
	current_hero_index = index
	active_hero = new_hero
	
	new_hero.global_position = spawn_pos
	new_hero.velocity = cur_vel
	if not _hero_switched_once.has(index):
		_hero_switched_once[index] = true
		new_hero.current_hp = new_hero.max_hp
	elif new_hero.current_hp <= 0.0:
		new_hero.current_hp = new_hero.max_hp
		
	if new_hero.visual_root:
		new_hero.visual_root.rotation.y = facing_rot
		
	new_hero.visible = true
	new_hero.process_mode = Node.PROCESS_MODE_INHERIT
	new_hero.collision_layer = 2 # Player layer
	new_hero.collision_mask = 1 | 4 | 8 # Environment + Enemies + Walls
	if not new_hero.is_in_group("player"):
		new_hero.add_to_group("player")
		
	# Retarget all active enemies to new hero immediately
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and "target_hero" in e:
			e.target_hero = new_hero
	if new_hero.has_node("Hurtbox3D"):
		var hb = new_hero.get_node("Hurtbox3D")
		hb.monitoring = true
		hb.monitorable = true
		hb.is_invulnerable = false
		
	if is_instance_valid(camera):
		camera.target_node = new_hero
		
	hero_switched.emit(new_hero)
	new_hero.health_changed.emit(new_hero.current_hp, new_hero.max_hp)
	print("🧙 [HERO POOL] Instant switched to: ", new_hero.hero_name, " (HP: ", int(new_hero.current_hp), "/", int(new_hero.max_hp), ") [Latency: 0.0ms]")
