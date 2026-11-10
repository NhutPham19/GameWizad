class_name Hitbox3D
extends Area3D

# ==============================================================================
# HITBOX 3D - Deals damage to overlapping Hurtbox3D
# ==============================================================================

signal hit_landed(target: Hurtbox3D, damage_data: DamageData)

@export var damage_amount: float = 15.0
@export var element_type: String = "physical"
@export var knockback_force: float = 4.0
@export var status_effect: String = "none"
@export var status_duration: float = 0.0
@export var team: String = "hero" # "hero" or "enemy"

var owner_node: Node3D = null

func _ready() -> void:
	collision_layer = 8 # Hitbox layer
	collision_mask = 4  # Hurtbox layer
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area is Hurtbox3D:
		var hurtbox: Hurtbox3D = area
		if hurtbox.team != team:
			var knock_dir = (hurtbox.global_position - global_position).normalized()
			knock_dir.y = 0.2
			var kb = knock_dir * knockback_force
			var dmg = DamageData.new(damage_amount, element_type, kb, status_effect, status_duration, owner_node)
			hurtbox.take_damage(dmg)
			hit_landed.emit(hurtbox, dmg)
