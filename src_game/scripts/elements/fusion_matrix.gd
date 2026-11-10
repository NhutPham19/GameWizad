class_name FusionMatrix
extends RefCounted

# ==============================================================================
# FUSION MATRIX - MA TRẬN 10 KỸ NĂNG DUNG HỢP NGUYÊN TỐ (PHÍM E)
# ==============================================================================

const FUSION_SPELLS := {
	"fire+wind": {
		"id": "firestorm_vortex",
		"name_vi": "Hỏa Phong Bạo",
		"desc": "Phễu lốc xoáy rực lửa cam-đỏ hút quái vào tâm và phát nổ",
		"icon_color": Color(1.0, 0.4, 0.1),
		"cooldown": 7.0,
		"script_path": "res://scripts/combat/fusion_spells/fusion_firestorm_vortex_3d.gd"
	},
	"fire+lightning": {
		"id": "plasma_overdrive",
		"name_vi": "Pháo Điện Từ",
		"desc": "Tia laser plasma 15m xuyên thấu phát tia hồ quang điện",
		"icon_color": Color(1.0, 0.2, 0.8),
		"cooldown": 6.5,
		"script_path": "res://scripts/combat/fusion_spells/fusion_plasma_overdrive_3d.gd"
	},
	"fire+earth": {
		"id": "magma_eruption",
		"name_vi": "Nham Thạch Phun Trào",
		"desc": "Dải đá nứt nẻ dung nham trồi lên để lại vùng lửa cháy",
		"icon_color": Color(0.9, 0.3, 0.1),
		"cooldown": 7.5,
		"script_path": "res://scripts/combat/fusion_spells/fusion_magma_eruption_3d.gd"
	},
	"fire+water": {
		"id": "scalding_steam",
		"name_vi": "Bão Hơi Nước Áp Suất",
		"desc": "Vụ nổ sương mù hơi nước nóng làm chậm 45% + sát thương đốt",
		"icon_color": Color(0.8, 0.85, 1.0),
		"cooldown": 6.5,
		"script_path": "res://scripts/combat/fusion_spells/fusion_scalding_steam_3d.gd"
	},
	"wind+lightning": {
		"id": "thunder_cyclone",
		"name_vi": "Lôi Vân Cuồng Phong",
		"desc": "Lốc xoáy bạc phóng tia sét vàng zic-zac làm choáng",
		"icon_color": Color(0.9, 0.95, 0.3),
		"cooldown": 7.0,
		"script_path": "res://scripts/combat/fusion_spells/fusion_thunder_cyclone_3d.gd"
	},
	"wind+earth": {
		"id": "sandstorm_shrapnel",
		"name_vi": "Bão Cát Sa Mạc",
		"desc": "Vòng xoáy cát đá vàng cam đẩy lùi và bào mòn giáp quái",
		"icon_color": Color(0.85, 0.65, 0.25),
		"cooldown": 6.0,
		"script_path": "res://scripts/combat/fusion_spells/fusion_sandstorm_shrapnel_3d.gd"
	},
	"wind+water": {
		"id": "blizzard_maelstrom",
		"name_vi": "Bão Tuyết Vĩnh Cửu",
		"desc": "Lốc xoáy băng lam đóng băng cứng quái vật sau 1.5s",
		"icon_color": Color(0.5, 0.85, 1.0),
		"cooldown": 8.0,
		"script_path": "res://scripts/combat/fusion_spells/fusion_blizzard_maelstrom_3d.gd"
	},
	"earth+lightning": {
		"id": "magnetic_monolith",
		"name_vi": "Trụ Đá Từ Trường",
		"desc": "Triệu hồi 3 cột đá nối tia sét khóa đường di chuyển của quái",
		"icon_color": Color(0.7, 0.45, 0.9),
		"cooldown": 8.5,
		"script_path": "res://scripts/combat/fusion_spells/fusion_magnetic_monolith_3d.gd"
	},
	"lightning+water": {
		"id": "electrified_tide",
		"name_vi": "Đại Dương Dẫn Điện",
		"desc": "Quả cầu nước bọc tia điện vàng làm choáng dây chuyền",
		"icon_color": Color(0.3, 0.7, 1.0),
		"cooldown": 6.5,
		"script_path": "res://scripts/combat/fusion_spells/fusion_electrified_tide_3d.gd"
	},
	"earth+water": {
		"id": "quagmire_spikes",
		"name_vi": "Đầm Lầy Thạch Nhũ",
		"desc": "Vùng bùn giữ chân quái rồi đâm hàng loạt gai đá thạch nhũ từ dưới lên",
		"icon_color": Color(0.3, 0.65, 0.4),
		"cooldown": 7.5,
		"script_path": "res://scripts/combat/fusion_spells/fusion_quagmire_spikes_3d.gd"
	}
}

static func get_fusion_key(elem_a: String, elem_b: String) -> String:
	var a = elem_a.to_lower()
	var b = elem_b.to_lower()
	var pair1 = a + "+" + b
	if FUSION_SPELLS.has(pair1):
		return pair1
	var pair2 = b + "+" + a
	if FUSION_SPELLS.has(pair2):
		return pair2
	return ""

static func get_fusion_data(elem_a: String, elem_b: String) -> Dictionary:
	var key = get_fusion_key(elem_a, elem_b)
	if key != "":
		return FUSION_SPELLS[key]
	return {}

static func get_fusion_id(elem_a: String, elem_b: String) -> String:
	var data = get_fusion_data(elem_a, elem_b)
	return data.get("id", "")

static func get_fusion_spell_data(spell_id: String) -> Dictionary:
	for k in FUSION_SPELLS:
		if FUSION_SPELLS[k].get("id", "") == spell_id:
			return FUSION_SPELLS[k]
	return {}

const VFXMasterFactory = preload("res://scripts/combat/vfx_master_factory.gd")

static func cast_fusion_spell(hero: Node3D, spell_id: String, origin: Vector3, dir: Vector3) -> Node3D:
	var clamped_target = origin + dir * 5.0
	if hero and hero.has_method("get_clamped_cast_target"):
		clamped_target = hero.get_clamped_cast_target(9.5)
		clamped_target.y = origin.y
		
	if hero and hero.get_parent():
		VFXMasterFactory.spawn_distortion_shockwave(hero.get_parent(), clamped_target, 4.2)
		VFXMasterFactory.spawn_ground_cracks(hero.get_parent(), clamped_target, Color(1.0, 0.6, 0.2), 3.2, 2.5)
		var vp = hero.get_viewport()
		var cam = vp.get_camera_3d() if vp else null
		if cam and cam.has_method("add_shake"):
			cam.add_shake(0.35)
		
	match spell_id:
		"firestorm_vortex":
			var node = FusionFirestormVortex3D.new()
			hero.get_parent().add_child(node)
			node.setup(clamped_target)
			return node
		"plasma_overdrive":
			var node = FusionPlasmaOverdrive3D.new()
			hero.get_parent().add_child(node)
			node.setup(origin, dir)
			return node
		"magma_eruption":
			var node = FusionMagmaEruption3D.new()
			hero.get_parent().add_child(node)
			node.setup(origin, dir)
			return node
		"scalding_steam":
			var node = FusionScaldingSteam3D.new()
			hero.get_parent().add_child(node)
			node.setup(clamped_target)
			return node
		"thunder_cyclone":
			var node = FusionThunderCyclone3D.new()
			hero.get_parent().add_child(node)
			node.setup(origin, dir)
			return node
		"sandstorm_shrapnel":
			var node = FusionSandstormShrapnel3D.new()
			hero.get_parent().add_child(node)
			node.setup(clamped_target)
			return node
		"blizzard_maelstrom":
			var node = FusionBlizzardMaelstrom3D.new()
			hero.get_parent().add_child(node)
			node.setup(clamped_target)
			return node
		"magnetic_monolith":
			var node = FusionMagneticMonolith3D.new()
			hero.get_parent().add_child(node)
			node.setup(clamped_target)
			return node
		"electrified_tide":
			var node = FusionElectrifiedTide3D.new()
			hero.get_parent().add_child(node)
			node.setup(origin, dir)
			return node
		"quagmire_spikes":
			var node = FusionQuagmireSpikes3D.new()
			hero.get_parent().add_child(node)
			node.setup(clamped_target)
			return node
	return null
