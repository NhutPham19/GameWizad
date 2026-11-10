class_name Hurtbox3D
extends Area3D

# ==============================================================================
# HURTBOX 3D - Receives damage and forwards to owner character
# ==============================================================================

signal damage_taken(damage_data: DamageData)

@export var team: String = "hero" # "hero" or "enemy"
@export var is_invulnerable: bool = false

func _ready() -> void:
	collision_layer = 4 # Hurtbox layer
	collision_mask = 8  # Hitbox layer

func take_damage(data: DamageData) -> void:
	if is_invulnerable:
		return
	damage_taken.emit(data)
