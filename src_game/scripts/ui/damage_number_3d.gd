class_name DamageNumber3D
extends Node3D

# ==============================================================================
# DAMAGE NUMBER 3D - CHỮ NHẢY SÁT THƯƠNG NỔI 3D (WIZARD OF LEGEND 2 STYLE)
# ==============================================================================

var label: Label3D = null
var velocity: Vector3 = Vector3.UP * 2.5
var lifetime: float = 0.65
var elapsed: float = 0.0

func setup(amount: float, pos: Vector3, is_crit: bool = false, elem_color: Color = Color(1.0, 0.9, 0.2)) -> void:
	global_position = pos + Vector3(randf_range(-0.3, 0.3), 1.2, randf_range(-0.3, 0.3))
	
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.007
	label.font_size = 32 if is_crit else 24
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.modulate = Color(1.0, 0.3, 0.2) if is_crit else elem_color
	label.text = str(int(amount)) + ("!" if is_crit else "")
	add_child(label)
	
	velocity = Vector3(randf_range(-0.8, 0.8), randf_range(2.0, 3.2), randf_range(-0.8, 0.8))

func _process(delta: float) -> void:
	elapsed += delta
	global_position += velocity * delta
	velocity.y -= 4.0 * delta # Slight gravity arc
	
	if label:
		var fade = 1.0 - (elapsed / lifetime)
		label.modulate.a = max(0.0, fade)
		
	if elapsed >= lifetime:
		queue_free()
