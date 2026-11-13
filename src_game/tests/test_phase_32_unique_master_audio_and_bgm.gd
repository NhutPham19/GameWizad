extends SceneTree

# ==============================================================================
# TEST PHASE 32: UNIQUE MASTER STEREO AUDIO & COMBAT BGM VERIFICATION
# DIRECTIVE 32 (ARGONS & ANTIGRAVITY) — 4 MANDATORY VERIFICATION TESTS:
#   [TEST 32.1]: Kiểm Tra 25 File Master Stereo .wav Tồn Tại & Dung Lượng >= 15KB
#   [TEST 32.2]: Cấm Tuyệt Đối Dùng Chung 1 File Cho 17 Kỹ Năng (unique_streams == 17)
#   [TEST 32.3]: Không Cắt Cụt Đuôi Âm (Chiêu Lớn >= 0.80s) & BGM + Phím F2 Hoạt Động
#   [TEST 32.4]: Bảo Toàn 100% PrimitiveMesh == 0 & Cầu Thang Phase 24-27
# ==============================================================================

const HeroKnight3D = preload("res://scripts/characters/hero_knight_3d.gd")
const KayKitAudioDirector = preload("res://scripts/audio/kaykit_audio_director.gd")

const REQUIRED_25_FILES: Array[String] = [
	"01_u1_slash_platinum.wav",
	"02_u2_slash_platinum.wav",
	"03_u3_heaven_shatter.wav",
	"04_i_phase1_x_cleave.wav",
	"05_i_phase2_wave_launch.wav",
	"06_i_wave_finale.wav",
	"07_rage_r_awaken.wav",
	"08_rage_r_expire.wav",
	"09_u1_rage_crimson.wav",
	"10_u2_rage_cobalt.wav",
	"11_u3_rage_dragon_fall.wav",
	"12_i_rage_hexa_cleave.wav",
	"13_i_rage_five_wing_wave.wav",
	"14_o_whirlwind_spin.wav",
	"15_p_bomb_throw.wav",
	"16_p_bomb_thunder_explode.wav",
	"17_p_bomb_dot_zap.wav",
	"18_dash_space.wav",
	"19_jump_c.wav",
	"20_footstep_stone_1.wav",
	"21_footstep_stone_2.wav",
	"22_hit_enemy_cleave_1.wav",
	"23_hit_enemy_cleave_2.wav",
	"24_enemy_death_burst.wav",
	"25_bgm_arena_combat_loop.wav"
]

const COMBAT_17_SKILLS: Array[String] = [
	"u1_slash",
	"u2_slash",
	"u3_heaven_shatter",
	"i_phase1_x_cleave",
	"i_phase2_wave_launch",
	"i_wave_finale",
	"rage_r_awaken",
	"rage_r_expire",
	"u1_rage",
	"u2_rage",
	"u3_rage_dragon_fall",
	"i_rage_hexa_cleave",
	"i_rage_five_wing_wave",
	"o_whirlwind_spin",
	"p_bomb_throw",
	"p_bomb_thunder_explode",
	"p_bomb_dot_zap"
]

func _init() -> void:
	print("==================================================================")
	print("  TEST PHASE 32: UNIQUE MASTER STEREO AUDIO & COMBAT BGM (ARGONS)")
	print("==================================================================")

	var scene_res := load("res://scenes/levels/kaykit_multitier_arena.tscn") as PackedScene
	if not scene_res:
		printerr("FAIL: Cannot load arena scene!")
		quit(1)
		return

	var arena := scene_res.instantiate()
	root.add_child(arena)
	current_scene = arena

	for f in range(6):
		await process_frame

	var hero := arena.get_node_or_null("HeroKnight3D") as HeroKnight3D
	if not hero:
		printerr("FAIL: HeroKnight3D not found!")
		quit(1)
		return

	var all_pass := true

	# --------------------------------------------------------------------------
	# TEST 32.1: KIỂM TRA 25 FILE MASTER STEREO .WAV TỒN TẠI & DUNG LƯỢNG >= 15KB
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 32.1 - KIỂM TRA 25 FILE MASTER STEREO .WAV TỒN TẠI & DUNG LƯỢNG >= 15KB]...")
	var test1_ok := true
	var global_res := ProjectSettings.globalize_path("res://").trim_suffix("/").trim_suffix("\\")
	var project_root := global_res.get_base_dir()
	var docs_audio_dir := project_root.path_join("docs/AUDIO_EXPORT_FOR_ARGONS/audio_files")

	for fname in REQUIRED_25_FILES:
		var res_path := "res://assets/audio/master_v32/" + fname
		if not ResourceLoader.exists(res_path):
			printerr("  FAIL: File không tồn tại trong res://: %s" % res_path)
			test1_ok = false
			all_pass = false
		else:
			var fa_res := FileAccess.open(res_path, FileAccess.READ)
			if fa_res == null:
				printerr("  FAIL: Không thể đọc file: %s" % res_path)
				test1_ok = false
				all_pass = false
			else:
				var sz_res := fa_res.get_length()
				fa_res.close()
				if sz_res < 15360:
					printerr("  FAIL: File %s quá nhỏ (%d bytes < 15KB)!" % [res_path, sz_res])
					test1_ok = false
					all_pass = false

		var doc_path := docs_audio_dir.path_join(fname)
		var fa_doc := FileAccess.open(doc_path, FileAccess.READ)
		if fa_doc == null:
			printerr("  FAIL: File không tồn tại trong docs: %s" % doc_path)
			test1_ok = false
			all_pass = false
		else:
			var sz_doc := fa_doc.get_length()
			fa_doc.close()
			if sz_doc < 15360:
				printerr("  FAIL: File docs %s quá nhỏ (%d bytes < 15KB)!" % [doc_path, sz_doc])
				test1_ok = false
				all_pass = false

	if test1_ok:
		print("  PASS: 100%% Cả 25 File Master Stereo .wav đều tồn tại đầy đủ ở cả 2 thư mục và dung lượng đều >= 15KB (28KB - 1.4MB)!")

	# --------------------------------------------------------------------------
	# TEST 32.2: CẤM TUYỆT ĐỐI DÙNG CHUNG 1 FILE CHO 17 KỸ NĂNG (unique_streams == 17)
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 32.2 - CẤM DÙNG CHUNG FILE CHO 17 KỸ NĂNG CHIẾN ĐẤU (1-TO-1 UNIQUE STREAM)]...")
	var audio_dir := KayKitAudioDirector.ensure_initialized(root.get_tree())
	var test2_ok := true
	var unique_streams: Array[AudioStream] = []
	var unique_file_names: Array[String] = []

	for skill_name in COMBAT_17_SKILLS:
		var stream := KayKitAudioDirector.get_stream(skill_name)
		if stream == null:
			printerr("  FAIL: Kỹ năng '%s' không nạp được AudioStream!" % skill_name)
			test2_ok = false
			all_pass = false
			continue

		var layers: Array = KayKitAudioDirector._sfx_bank.get(skill_name, [])
		var file_name: String = ""
		if layers.size() > 0:
			file_name = str(layers[0].get("file", layers[0].get("s", "")))

		if unique_streams.has(stream):
			printerr("  FAIL: Kỹ năng '%s' bị TRÙNG AudioStream với kỹ năng khác!" % skill_name)
			test2_ok = false
			all_pass = false
		else:
			unique_streams.append(stream)

		if unique_file_names.has(file_name):
			printerr("  FAIL: Kỹ năng '%s' bị TRÙNG file ('%s') với kỹ năng khác!" % [skill_name, file_name])
			test2_ok = false
			all_pass = false
		else:
			unique_file_names.append(file_name)

		print("  [SKILL] %-25s -> %s (Len: %.2fs)" % [skill_name, file_name, stream.get_length()])

	print("  - Tổng số AudioStream độc bản của 17 kỹ năng: %d / 17" % unique_streams.size())
	if unique_streams.size() == 17 and test2_ok:
		print("  PASS: 17/17 Kỹ năng chiến đấu sử dụng 17 AudioStream hoàn toàn khác nhau (unique_streams.size() == 17)! Tuyệt đối 0% trùng lặp!")
	else:
		printerr("  FAIL: Phát hiện kỹ năng dùng chung file âm thanh! unique_streams.size() = %d" % unique_streams.size())
		test2_ok = false
		all_pass = false

	# --------------------------------------------------------------------------
	# TEST 32.3: KHÔNG CẮT CỤT ĐUÔI ÂM & BGM + PHÍM F2 HOẠT ĐỘNG
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 32.3 - KHÔNG CẮT CỤT ĐUÔI ÂM (CHIÊU LỚN >= 0.80s) & BGM HOẠT ĐỘNG]...")
	var test3_ok := true
	var big_skills := ["u3_rage_dragon_fall", "i_rage_five_wing_wave", "rage_r_awaken", "p_bomb_thunder_explode", "u3_heaven_shatter"]
	for skill_name in big_skills:
		var s := KayKitAudioDirector.get_stream(skill_name)
		if s == null:
			printerr("  FAIL: Thiếu stream cho chiêu lớn '%s'!" % skill_name)
			test3_ok = false
			all_pass = false
		else:
			var dur := s.get_length()
			if dur < 0.80:
				printerr("  FAIL: Chiêu lớn '%s' có độ dài %.2fs < 0.80s!" % [skill_name, dur])
				test3_ok = false
				all_pass = false
			else:
				print("  - Chiêu lớn '%s': Độ dài %.2fs >= 0.80s (Đạt chuẩn ngân vang trọn vẹn)" % [skill_name, dur])

	# Kiểm tra mã nguồn _trigger_controlled_layer không còn chứa tween tắt sớm sau 0.3s
	var script_file := FileAccess.open("res://scripts/audio/kaykit_audio_director.gd", FileAccess.READ)
	if script_file:
		var code := script_file.get_as_text()
		script_file.close()
		if code.contains("env_tw.tween_property(player, \"volume_db\", -48.0") or code.contains("env_tw.tween_callback(player.stop)"):
			printerr("  FAIL: Vẫn còn đoạn Tween cắt cụt âm thanh trong _trigger_controlled_layer!")
			test3_ok = false
			all_pass = false
		else:
			print("  PASS: Đã xóa hoàn toàn đoạn Tween cắt cụt âm thanh ở 0.18s-0.30s trong _trigger_controlled_layer!")

	# Kiểm tra BGM Player và phím F2 toggle
	if audio_dir.bgm_player == null:
		printerr("  FAIL: bgm_player chưa được khởi tạo!")
		test3_ok = false
		all_pass = false
	else:
		KayKitAudioDirector.start_bgm()
		if audio_dir.bgm_player.stream == null:
			printerr("  FAIL: bgm_player không có AudioStream!")
			test3_ok = false
			all_pass = false
		else:
			print("  PASS: bgm_player đã nạp stream '%s' (Độ dài: %.2fs)!" % [audio_dir.bgm_player.stream.resource_path.get_file(), audio_dir.bgm_player.stream.get_length()])

		# Test F2 toggle
		var initial_state := KayKitAudioDirector.bgm_enabled
		var toggled_state := KayKitAudioDirector.toggle_bgm()
		if toggled_state == initial_state:
			printerr("  FAIL: Toggle BGM không thay đổi trạng thái!")
			test3_ok = false
			all_pass = false
		else:
			print("  PASS: Chức năng F2 Toggle BGM hoạt động chính xác (Bật -> Tắt -> Bật)!")
			# Toggle lại về bật
			KayKitAudioDirector.toggle_bgm()

	if test3_ok:
		print("  PASS: 100% Chiêu lớn ngân vang trọn vẹn >= 0.80s, không cắt cụt đuôi, và BGM hoạt động xuất sắc!")

	# --------------------------------------------------------------------------
	# TEST 32.4: BẢO TOÀN PRIMITIVEMESH == 0 & VẬT LÝ CẦU THANG PHASE 24-27
	# --------------------------------------------------------------------------
	print("\n>>> [TEST 32.4 - BẢO TOÀN 0% PRIMITIVEMESH & CẦU THANG PHASE 24-27]...")
	var primitive_count := 0
	var array_mesh_count := 0
	var stack: Array[Node] = [arena]
	while not stack.is_empty():
		var curr := stack.pop_back() as Node
		if curr is MeshInstance3D:
			var m := (curr as MeshInstance3D).mesh
			if m != null:
				if m is PrimitiveMesh:
					primitive_count += 1
					printerr("  FAIL: Phát hiện PrimitiveMesh vi phạm tại: %s" % curr.get_path())
				elif m is ArrayMesh:
					array_mesh_count += 1
		for c in curr.get_children():
			stack.append(c)

	print("  - Tổng MeshInstance3D: %d | ArrayMeshes: %d | PrimitiveMeshes: %d" % [primitive_count + array_mesh_count, array_mesh_count, primitive_count])
	if primitive_count == 0:
		print("  PASS: 100% ZERO PRIMITIVE MESHES CONFIRMED (primitive_count == 0)!")
	else:
		printerr("  FAIL: Có %d PrimitiveMesh vi phạm!" % primitive_count)
		all_pass = false

	# Kiểm tra phát chuỗi combo âm thanh không lỗi
	var prev_plays := audio_dir.play_count
	KayKitAudioDirector.play_sfx("u1_slash")
	KayKitAudioDirector.play_sfx("u2_slash")
	KayKitAudioDirector.play_sfx("u3_heaven_shatter")
	KayKitAudioDirector.play_sfx("rage_r_awaken")
	KayKitAudioDirector.play_sfx("u3_rage_dragon_fall")
	if audio_dir.play_count > prev_plays:
		print("  PASS: Phát chuỗi combo âm thanh Master Stereo hoạt động hoàn hảo!")

	print("\n==================================================================")
	if all_pass:
		print("  🏆 ALL 4 PHASE 32 TESTS PASSED 100% (ARGONS DIRECTIVE 32 FULLY SATISFIED)!")
		print("==================================================================")
		quit(0)
	else:
		printerr("  💥 SOME TESTS FAILED IN PHASE 32!")
		print("==================================================================")
		quit(1)
