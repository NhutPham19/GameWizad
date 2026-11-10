class_name KayKitAnimationBinder
extends RefCounted

# ==============================================================================
# KAYKIT ANIMATION BINDER — DIRECTIVE 15B, FILE LÕI SỐ 1
# Sửa triệt để lỗi nhân vật bị đơ / trượt lướt ván và lỗi cầm chồng vũ khí.
# - Xóa mọi AnimationTree gây khóa xương
# - Tìm đúng Skeleton3D + AnimationPlayer tích hợp sẵn trong .glb
# - Chuẩn hóa đường dẫn Track xương (_remap_tracks_to_skeleton)
# - Dọn sạch vũ khí thừa & gắn vũ khí mới kèm Blade Markers
# ==============================================================================

# --- Danh sách animation cần loop ---
static var LOOP_KEYWORDS: Array[String] = [
	"idle", "walk", "running", "run", "blocking", "spellcasting"
]


## Tìm Skeleton3D bên trong scene root (đệ quy)
static func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


## Tìm AnimationPlayer bên trong scene root (đệ quy)
static func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


## Xóa tất cả AnimationTree gây khóa xương (đệ quy)
static func _remove_all_animation_trees(node: Node) -> void:
	for child in node.get_children():
		if child is AnimationTree:
			child.active = false
			child.queue_free()
		else:
			_remove_all_animation_trees(child)


## Chuẩn hóa đường dẫn Track xương cho toàn bộ animations
static func _remap_tracks_to_skeleton(anim_player: AnimationPlayer, skel: Skeleton3D) -> void:
	# Tính đường dẫn tương đối chính xác từ root_node của AnimationPlayer tới Skeleton3D
	var root_ref: Node = anim_player.get_node(anim_player.root_node)
	var exact_skel_path: String = String(root_ref.get_path_to(skel))

	var anim_list: PackedStringArray = anim_player.get_animation_list()
	for anim_name in anim_list:
		var anim: Animation = anim_player.get_animation(anim_name)
		if anim == null:
			continue

		# --- Đặt loop_mode ---
		var lower_name: String = anim_name.to_lower()
		var should_loop: bool = false
		for keyword in LOOP_KEYWORDS:
			if lower_name.contains(keyword):
				should_loop = true
				break
		anim.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE

		# --- Remap track paths ---
		for i in range(anim.get_track_count()):
			var track_path: NodePath = anim.track_get_path(i)
			var subnames: String = track_path.get_concatenated_subnames()
			if subnames.is_empty():
				continue
			# Kiểm tra subnames có phải là tên bone hợp lệ
			if skel.find_bone(subnames) != -1:
				var new_path := NodePath(exact_skel_path + ":" + subnames)
				anim.track_set_path(i, new_path)


## Hàm chính: Setup & Bind toàn bộ animations nội bộ của model .glb
## Trả về Dictionary { "skeleton": Skeleton3D, "anim_player": AnimationPlayer }
static func setup_and_bind_internal_animations(model_root: Node) -> Dictionary:
	# 1. Xóa mọi AnimationTree
	_remove_all_animation_trees(model_root)

	# 2. Tìm Skeleton3D
	var skel: Skeleton3D = _find_skeleton(model_root)
	if skel == null:
		push_error("[KayKitAnimationBinder] Skeleton3D not found in model!")
		return {}

	# 3. Tìm AnimationPlayer
	var anim_player: AnimationPlayer = _find_animation_player(model_root)
	if anim_player == null:
		push_error("[KayKitAnimationBinder] AnimationPlayer not found in model!")
		return {}

	# 4. Remap tracks
	_remap_tracks_to_skeleton(anim_player, skel)

	return {
		"skeleton": skel,
		"anim_player": anim_player,
	}


## Dọn sạch toàn bộ mesh vũ khí mặc định gắn sẵn trong BoneAttachment3D
static func clear_all_hand_slots(skel: Skeleton3D) -> void:
	for child in skel.get_children():
		if child is BoneAttachment3D:
			# Xóa tất cả con của BoneAttachment3D (mesh vũ khí mặc định)
			for weapon_child in child.get_children():
				weapon_child.queue_free()


## Gắn vũ khí vào bone, tùy chọn tạo BladeCenterMarker & BladeTipMarker
## Trả về Node3D gốc của vũ khí đã gắn
static func attach_weapon_to_bone(
	skel: Skeleton3D,
	bone_name: String,
	gltf_path: String,
	add_blade_markers: bool = false
) -> Node3D:
	# Tìm hoặc tạo BoneAttachment3D cho bone_name
	var bone_attach: BoneAttachment3D = null
	for child in skel.get_children():
		if child is BoneAttachment3D and child.bone_name == bone_name:
			bone_attach = child as BoneAttachment3D
			break

	if bone_attach == null:
		bone_attach = BoneAttachment3D.new()
		bone_attach.bone_name = bone_name
		skel.add_child(bone_attach)

	# Instantiate weapon model
	var weapon_scene: PackedScene = load(gltf_path) as PackedScene
	if weapon_scene == null:
		push_error("[KayKitAnimationBinder] Failed to load weapon: %s" % gltf_path)
		return null

	var weapon_instance: Node3D = weapon_scene.instantiate() as Node3D
	weapon_instance.position = Vector3.ZERO
	weapon_instance.rotation = Vector3.ZERO
	weapon_instance.scale = Vector3.ONE
	bone_attach.add_child(weapon_instance)

	# Tạo Blade Markers cho thanh kiếm
	if add_blade_markers:
		var blade_center := Marker3D.new()
		blade_center.name = "BladeCenterMarker"
		blade_center.position = Vector3(0.0, 0.45, 0.0)
		weapon_instance.add_child(blade_center)

		var blade_tip := Marker3D.new()
		blade_tip.name = "BladeTipMarker"
		blade_tip.position = Vector3(0.0, 0.88, 0.0)
		weapon_instance.add_child(blade_tip)

	return weapon_instance
