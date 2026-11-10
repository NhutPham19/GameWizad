class_name DamageData
extends RefCounted

# ==============================================================================
# DAMAGE DATA CONTAINER - GAMEWIZAD COMBAT ENGINE
# Argons Directive 08: Universal Robustness (Supports Strings, Enums & Overloaded Signatures)
# ==============================================================================

enum DamageType { PHYSICAL, FIRE, WIND, LIGHTNING, EARTH, WATER }

var amount: float = 10.0
var element: String = "physical" # "fire", "wind", "lightning", "earth", "water", "physical"
var knockback: Vector3 = Vector3.ZERO
var status_effect: String = "none" # "burn", "slow", "freeze", "stun", "none"
var status_duration: float = 0.0
var source: Node3D = null

func _init(p_amount: float = 10.0, p_element: Variant = "physical", p_param3: Variant = Vector3.ZERO, p_status: String = "none", p_duration: float = 0.0, p_source: Node3D = null) -> void:
	amount = p_amount
	if p_element is int:
		match p_element:
			DamageType.FIRE: element = "fire"
			DamageType.WIND: element = "wind"
			DamageType.LIGHTNING: element = "lightning"
			DamageType.EARTH: element = "earth"
			DamageType.WATER: element = "water"
			_: element = "physical"
	elif p_element is String:
		element = p_element
	else:
		element = "physical"
		
	# Overload support: if param3 is Node3D (e.g. caster passed as 3rd arg)
	if p_param3 is Node3D:
		source = p_param3
		knockback = Vector3.ZERO
	elif p_param3 is Vector3:
		knockback = p_param3
	else:
		knockback = Vector3.ZERO
		
	status_effect = p_status
	status_duration = p_duration
	if p_source != null:
		source = p_source
