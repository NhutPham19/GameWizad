class_name WindShield3D
extends Node3D

# ==============================================================================
# WIND SHIELD 3D - ZEPHYR RMB (Phong Thuẫn Phản Xạ - 360° phản xạ đạn phép 1.5s)
# ==============================================================================

var duration: float = 1.5
var elapsed: float = 0.0
var ring_mesh: MeshInstance3D = null

func _ready() -> void:
	ring_mesh = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.6
	torus.outer_radius = 1.9
	ring_mesh.mesh = torus
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.4, 0.95, 0.8, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 1.0, 0.7)
	mat.emission_energy_multiplier = 2.5
	ring_mesh.material_override = mat
	add_child(ring_mesh)
	
	# Area that reflects or negates incoming enemy projectiles
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 8 # Enemy hitboxes
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 2.0
	col.shape = sphere
	area.add_child(col)
	add_child(area)
	area.area_entered.connect(_on_incoming_hazard)

func _process(delta: float) -> void:
	elapsed += delta
	if ring_mesh:
		ring_mesh.rotate_y(delta * 12.0)
	if elapsed >= duration:
		queue_free()

func _on_incoming_hazard(area: Area3D) -> void:
	if area is Hitbox3D and area.team == "enemy":
		# Deflect / destroy enemy projectile
		var proj = area.get_parent()
		if proj:
			proj.queue_free()
