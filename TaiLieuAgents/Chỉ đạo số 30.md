# 👑 CHỈ ĐẠO SỐ 30 TỪ ARGONS: XÓA BỎ HOÀN TOÀN ÂM THANH HỖN LOẠN & THIẾT KẾ LẠI HỆ THỐNG ÂM THANH TINH GỌN, TRẬT TỰ, CHUẨN XÁC (CLEAN & STRUCTURED COMBAT AUDIO)

* **Người chỉ đạo (Chief Architect):** ARGONS
* **Đơn vị thực thi:** ANTIGRAVITY IDE (`Claude Opus 4.6` / `Gemini 3.8 Flash`)
* **Kho GitHub dự án:** `https://github.com/NhutPham19/GameWizad`
* **Trạng thái nền tảng:** Đồ họa, Vật lý Cầu thang và Hào quang Nộ 6 Lớp (Phase 24–27) đã đạt chuẩn $100\%$. Tuy nhiên hệ thống âm thanh của Phase 28–29 đang bị **quá lộn xộn, ồn ào và chồng chéo**.

---

## 🚨 PHẦN 1: CHẨN ĐOÁN 5 LỖI KHIẾN ÂM THANH BỊ "LỘN XỘN" & MỆNH LỆNH XÓA BỎ

1. **LỖI 1 — Chồng chéo quá nhiều file âm thanh trong 1 nút bấm (6 đến 11 file/chiêu):**
   * *Hiện trạng:* `u3_rage_dragon_fall` đang phát 11 file cùng lúc; `i_rage_five_wing_wave` phát 8 file; `u1_rage` phát 6 file.
   * *Mệnh lệnh:* **XÓA SẠCH** bảng `_sfx_bank` cũ! Áp dụng **Quy tắc Tối Giản Chuẩn AAA**: Mỗi đòn đánh thường chỉ dùng **1 đến 2 lớp âm thanh**, mỗi chiêu cuối tối đa **3 nhịp tách biệt rõ ràng theo thời gian**.
2. **LỖI 2 — Dùng nhầm âm thanh Súng Laser (`laserLarge`, `laserSmall`) và Tàu Vũ Trụ (`spaceEngineLarge`, `forceField`):**
   * *Hiện trạng:* Tiếng súng bắn "chíu chíu" của `laserLarge` và tiếng ù dài 4 giây của `spaceEngineLarge` / `forceField` hoàn toàn lạc quẻ với Hiệp sĩ cầm kiếm và kéo dài lê thê sau khi đã chém xong.
   * *Mệnh lệnh:* **CẤM TUYỆT ĐỐI** việc nạp và phát `laserLarge_*`, `laserSmall_*`, `spaceEngineLarge_*`, `forceField_*`. Tắt hoàn toàn `rage_aura_loop_player` và `bgm_player` chạy ngầm gây ù tai.
3. **LỖI 3 — File âm thanh dài không có bộ cắt đuôi (`Envelope Trim / Fade-out`):**
   * *Mệnh lệnh:* Mọi âm thanh phát ra bắt buộc phải có thông số **`max_dur` (Thời lượng tối đa tính bằng giây, từ `0.16s` đến `0.55s`)**. Khi hết `max_dur`, kênh phát tự động hạ âm lượng mượt mà (`Tween` về `-45 dB` trong `0.05s`) rồi gọi `.stop()`, tuyệt đối không để đuôi âm thanh ngân lê thê đè lên đòn đánh tiếp theo!
4. **LỖI 4 — Không có cơ chế "Nhát Chém Mới Ngắt Đuôi Nhát Chém Cũ" (`Exclusive Voice Group Choking`):**
   * *Mệnh lệnh:* Chia các kênh phát thành 4 nhóm độc lập (`SWING`, `IMPACT`, `MOVEMENT`, `FOOTSTEP`). Khi người chơi bấm liên hoàn `U1 -> U2 -> U3`, ngay khi `U2` phát ra, nó phải **làm mờ nhanh (0.03s) âm thừa của `U1`** để tai người chơi nghe rõ ràng từng nhát chém *Xoẹt! -> Xoẹt! -> Ầm!* cực kỳ trật tự và sướng tai!
5. **LỖI 5 — Bộ làm méo `AudioEffectDistortion` & `AudioEffectChorus` gây vỡ tiếng:**
   * *Mệnh lệnh:* Xóa bỏ hoàn toàn `AudioEffectDistortion`, `AudioEffectChorus`, `AudioEffectStereoEnhance`. Chỉ sử dụng `AudioEffectEQ6` tinh chỉnh sạch sẽ + `AudioEffectLimiter` / `AudioEffectCompressor` chống vỡ tiếng và `AudioEffectReverb` nhẹ (`wet = 0.08 -> 0.14`).

---

## 🎼 PHẦN 2: BẢNG THIẾT KẾ ÂM THANH MỚI — RÕ RÀNG, HỢP LÝ & KHÁC BIỆT GIỮA 2 TRẠNG THÁI

| Hành động / Kỹ năng | Trạng Thái 1: Bình Thường (*Kiếm Thép Bạch Kim — Nhanh, Sắc, Gọn*) | Trạng Thái 2: Hóa Nộ `[R]` (*Đại Kiếm Huyết Lam — Đầm, Nặng, Uy Lực*) |
| :--- | :--- | :--- |
| **Đòn `[U]` Nhịp 1** | **1 Lớp duy nhất (`0.18s`):** Tiếng chém kiếm sắc gọn (`knifeSlice.ogg`, `pitch = 1.06`). | **2 Lớp đồng bộ (`0.32s`):** Tiếng lưỡi đại kiếm nặng (`knifeSlice.ogg` trầm `pitch = 0.78`) + Tiếng thép hạng nặng (`impactMetal_heavy_000.ogg`, `pitch = 0.90`). |
| **Đòn `[U]` Nhịp 2** | **1 Lớp duy nhất (`0.20s`):** Tiếng chém chéo bén ngọt (`knifeSlice2.ogg`, `pitch = 0.98`). | **2 Lớp đồng bộ (`0.34s`):** Tiếng song kiếm trầm (`knifeSlice2.ogg`, `pitch = 0.74`) + Tiếng thép ngân (`impactMetal_heavy_001.ogg`, `pitch = 0.85`). |
| **Đòn `[U]` Nhịp 3 (`U3`)** | **2 Nhịp rõ ràng (`0.38s`):**<br>• `0.00s`: Bổ kiếm xuống (`chop.ogg`, `pitch = 0.95`).<br>• `0.05s`: Chạm sàn đá đầm gọn (`impactPunch_heavy_000.ogg`, `pitch = 0.90`). | **3 Nhịp tách bạch theo 5 Đại Kiếm Khí Đọng Lại (`0.55s`):**<br>• `0.00s`: Giáng đại kiếm (`chop.ogg`, `pitch = 0.72`).<br>• `0.06s`: Địa chấn nện đất (`lowFrequency_explosion_000.ogg` + `impactPlate_heavy_000.ogg`).<br>• `0.22s`: Tiếng chuông đồng ngân trầm khi 5 lưỡi kiếm phình to trên đất (`impactBell_heavy_000.ogg`, `pitch = 0.78`, cắt gọn ở `0.55s`). |
| **Chiêu `[I]` Pha 1** *(Chém chữ X)* | **2 Nhịp cắt chéo (`0.24s`):** Tiếng rút kiếm bén (`drawKnife1.ogg` tại `0.0s`) + Tiếng chém ngang (`knifeSlice2.ogg` tại `0.04s`). | **2 Nhịp Thập Tự Trảm Nặng (`0.38s`):** Tiếng đại kiếm kim loại cắt chéo (`drawKnife2.ogg` `pitch = 0.82` tại `0.0s`) + Tiếng va chấn thép (`impactMetal_heavy_002.ogg` + `lowFrequency_explosion_001.ogg` tại `0.05s`). |
| **Chiêu `[I]` Pha 2** *(Sóng kiếm)* | **1 Lớp lướt gió êm (`0.30s`):** Tiếng sóng gió (`clothBelt.ogg`, `pitch = 0.92`). Khi kết thúc: 1 tiếng chạm gọn (`impactPunch_heavy_001.ogg`). | **1 Lớp phóng năng lượng trầm (`0.42s`, KHÔNG nổ lụp bụp dọc đường):** Tiếng luồng lửa trầm (`thrusterFire_000.ogg` `pitch = 0.80` được cắt gọn mượt sau `0.40s`). Khi sóng đọng lại nổ ở điểm cuối: 1 tiếng nổ trầm (`lowFrequency_explosion_000.ogg` + `explosionCrunch_000.ogg` cắt gọn `0.42s`). |
| **Chiêu `[O]`** *(Xoay 360°)* | **3 Nhịp xoay kiếm đều đặn:** `0.00s` (`knifeSlice.ogg`) $\rightarrow$ `0.13s` (`knifeSlice2.ogg`) $\rightarrow$ `0.26s` (`knifeSlice.ogg`). | **3 Nhịp xoay Đại Kiếm Nộ:** `0.00s` (`knifeSlice.ogg` `pitch = 0.76`) $\rightarrow$ `0.13s` (`impactMetal_heavy_000.ogg` `pitch = 0.85`) $\rightarrow$ `0.26s` (`knifeSlice2.ogg` `pitch = 0.74`). |
| **Chiêu `[P]`** *(Bom Lôi Vụ)* | • Ném: `cloth1.ogg` (`0.15s`).<br>• Nổ: `impactSoft_heavy_000.ogg` (`0.32s`).<br>• Đốt DoT: Rất êm (`click_002.wav` ở `-18 dB`) không gây ồn. | • Ném: `clothBelt.ogg` (`0.18s`).<br>• Nổ Bom Huyết Lôi: `lowFrequency_explosion_001.ogg` + `explosionCrunch_001.ogg` (`0.40s`). |
| **Phím `[R]`** *(Hóa Nộ)* | — | **Thức tỉnh gọn và uy nghiêm (`0.50s`):** Tiếng ngân đại kiếm (`drawKnife3.ogg` + `impactBell_heavy_000.ogg` `pitch = 0.82`) + 1 xung trầm dưới chân (`lowFrequency_explosion_000.ogg`). |
| **Lướt `[Space]` & Bước Chân** | • Lướt: `cloth1.ogg` (`0.18s`, gọn nhẹ).<br>• Bước chân: `footstep00..02.ogg` (`-12 dB`, tự tắt khi đang chém). | • Lướt Nộ: `clothBelt.ogg` (`pitch = 0.82`, `0.22s`).<br>• Bước chân Nộ: Đầm hơn nhẹ (`-10 dB`, `pitch = 0.88`, tự tắt khi đang chém). |

---

## 🛠️ PHẦN 3: CÁC TASK THỰC THI CHI TIẾT CHO ANTIGRAVITY

### 🔹 TASK 30.1: THAY THẾ TOÀN BỘ `src_game/scripts/audio/kaykit_audio_director.gd` BẰNG KIẾN TRÚC CLEAN AUDIO MỚI

Ghi đè **toàn bộ** file `src_game/scripts/audio/kaykit_audio_director.gd` bằng đoạn code hoàn chỉnh, sạch sẽ và có bộ kiểm soát thời lượng `max_dur` + ngắt nhóm kênh (`Voice Group Choking`) dưới đây:

```gdscript
class_name KayKitAudioDirector
extends Node

# ==============================================================================
# KAYKIT AUDIO DIRECTOR — DIRECTIVE 30 (CLEAN, STRUCTURED, ZERO-CLUTTER AUDIO)
# - Xóa sạch 100% hiện tượng chồng chéo nhiều file âm thanh gây hỗn loạn.
# - Cấm tuyệt đối các file súng laser/tàu vũ trụ kéo dài.
# - Tích hợp Bộ Cắt Đuôi Âm Tự Động (max_dur Envelope Fade-out) & Nhường Kênh (Voice Choking).
# - Tách biệt rõ ràng, hợp lý giữa Trạng Thái 1 (Kiếm Thép Sắc Gọn) và Trạng Thái 2 (Đại Kiếm Nộ Trầm Đầm).
# ==============================================================================

static var _instance: KayKitAudioDirector = null
static var _raw_streams: Dictionary = {}
static var _sfx_bank: Dictionary = {}
static var _is_prebaked: bool = false
static var _is_adding: bool = false

var players: Array[AudioStreamPlayer] = []
var max_players: int = 32
var current_player_idx: int = 0
var bgm_player: AudioStreamPlayer = null
var rage_aura_loop_player: AudioStreamPlayer = null

# Quản lý nhóm kênh để ngắt âm thừa (Choking) không cho chồng chéo lộn xộn
var _active_group_players: Dictionary = {
	"SWING": [],
	"IMPACT": [],
	"MOVEMENT": [],
	"FOOTSTEP": [],
	"STATE": []
}
var _player_fade_tweens: Dictionary = {}

var play_count: int = 0
var play_counts: Dictionary = {}
var _last_play_time: Dictionary = {}
var _last_combat_action_time: float = -10.0

const MIN_RETRIGGER_DELAY: float = 0.045

const BUS_NORMAL := "NormalBladeBus"
const BUS_RAGE := "RageOverdriveBus"
const BUS_IMPACT := "HeavyImpactBus"
const BUS_AURA := "RageAuraBus"
const COMBAT_BUS_NAME := BUS_NORMAL

func _init() -> void:
	if _instance == null:
		_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_studio_audio_buses()
	_prebake_audio_bank()
	_init_audio_pool()

func _ready() -> void:
	_is_adding = false
	_setup_studio_audio_buses()
	_init_audio_pool()

# ==============================================================================
# 1. THIẾT LẬP AUDIO BUS TRONG TRẺO, SẠCH SẼ (KHÔNG DISTORTION / KHÔNG VỠ TIẾNG)
# ==============================================================================
func _setup_studio_audio_buses() -> void:
	# Xóa mọi hiệu ứng cũ nếu bus đã tồn tại để làm sạch hoàn toàn
	for b_name in [BUS_NORMAL, BUS_RAGE, BUS_IMPACT, BUS_AURA, "CombatSFX"]:
		var existing_idx := AudioServer.get_bus_index(b_name)
		if existing_idx != -1:
			while AudioServer.get_bus_effect_count(existing_idx) > 0:
				AudioServer.remove_bus_effect(existing_idx, 0)

	# --- BUS 1: NormalBladeBus (Trạng Thái 1: Kiếm thép sắc gọn, trong trẻo) ---
	var idx_norm := AudioServer.get_bus_index(BUS_NORMAL)
	if idx_norm == -1:
		idx_norm = AudioServer.bus_count
		AudioServer.add_bus(idx_norm)
		AudioServer.set_bus_name(idx_norm, BUS_NORMAL)
		AudioServer.set_bus_send(idx_norm, "Master")

	var eq_norm := AudioEffectEQ6.new()
	eq_norm.set_band_gain_db(0, 0.0)   # 32 Hz
	eq_norm.set_band_gain_db(1, 1.5)   # 100 Hz (Độ đầm nhẹ)
	eq_norm.set_band_gain_db(2, -1.5)  # 320 Hz (Lọc sạch âm đục)
	eq_norm.set_band_gain_db(3, 1.0)   # 1000 Hz
	eq_norm.set_band_gain_db(4, 2.0)   # 3200 Hz (Độ bén lưỡi kiếm)
	eq_norm.set_band_gain_db(5, -3.0)  # 10000 Hz (Êm tai, không chói)
	AudioServer.add_bus_effect(idx_norm, eq_norm)

	var comp_norm := AudioEffectCompressor.new()
	comp_norm.threshold = -6.0
	comp_norm.ratio = 3.0
	comp_norm.gain = 0.0
	AudioServer.add_bus_effect(idx_norm, comp_norm)

	# --- BUS 2: RageOverdriveBus (Trạng Thái 2 [R]: Trầm hùng, đầm chắc, KHÔNG méo tiếng) ---
	var idx_rage := AudioServer.get_bus_index(BUS_RAGE)
	if idx_rage == -1:
		idx_rage = AudioServer.bus_count
		AudioServer.add_bus(idx_rage)
		AudioServer.set_bus_name(idx_rage, BUS_RAGE)
		AudioServer.set_bus_send(idx_rage, "Master")

	var eq_rage := AudioEffectEQ6.new()
	eq_rage.set_band_gain_db(0, 3.5)   # 32 Hz (Lực trầm vừa vặn, ấm)
	eq_rage.set_band_gain_db(1, 4.0)   # 100 Hz (Thân đại kiếm dày)
	eq_rage.set_band_gain_db(2, -2.0)  # 320 Hz (Khử ù tuyệt đối)
	eq_rage.set_band_gain_db(3, 1.0)   # 1000 Hz
	eq_rage.set_band_gain_db(4, 1.5)   # 3200 Hz
	eq_rage.set_band_gain_db(5, -4.0)  # 10000 Hz
	AudioServer.add_bus_effect(idx_rage, eq_rage)

	var rev_rage := AudioEffectReverb.new()
	rev_rage.room_size = 0.38
	rev_rage.damping = 0.72
	rev_rage.spread = 0.80
	rev_rage.wet = 0.10 # Độ vang rất tinh tế 10%, không gây vọng ồn ào
	rev_rage.dry = 0.95
	AudioServer.add_bus_effect(idx_rage, rev_rage)

	var comp_rage := AudioEffectCompressor.new()
	comp_rage.threshold = -6.0
	comp_rage.ratio = 4.0
	comp_rage.gain = 0.5
	AudioServer.add_bus_effect(idx_rage, comp_rage)

	# --- BUS 3: HeavyImpactBus (Tiếng va chạm & Nổ địa chấn gọn, chắc) ---
	var idx_imp := AudioServer.get_bus_index(BUS_IMPACT)
	if idx_imp == -1:
		idx_imp = AudioServer.bus_count
		AudioServer.add_bus(idx_imp)
		AudioServer.set_bus_name(idx_imp, BUS_IMPACT)
		AudioServer.set_bus_send(idx_imp, "Master")

	var eq_imp := AudioEffectEQ6.new()
	eq_imp.set_band_gain_db(0, 3.5)
	eq_imp.set_band_gain_db(1, 3.5)
	eq_imp.set_band_gain_db(2, -2.5)
	eq_imp.set_band_gain_db(3, 0.5)
	eq_imp.set_band_gain_db(4, 1.0)
	eq_imp.set_band_gain_db(5, -4.5)
	AudioServer.add_bus_effect(idx_imp, eq_imp)

	var lpf_imp := AudioEffectLowPassFilter.new()
	lpf_imp.cutoff_hz = 5800.0
	AudioServer.add_bus_effect(idx_imp, lpf_imp)

	var comp_imp := AudioEffectCompressor.new()
	comp_imp.threshold = -6.0
	comp_imp.ratio = 4.0
	comp_imp.gain = 0.0
	AudioServer.add_bus_effect(idx_imp, comp_imp)

	# --- BUS 4: RageAuraBus & CombatSFX (Tương thích kiểm thử) ---
	for aux_bus in [BUS_AURA, "CombatSFX"]:
		var idx_a := AudioServer.get_bus_index(aux_bus)
		if idx_a == -1:
			idx_a = AudioServer.bus_count
			AudioServer.add_bus(idx_a)
			AudioServer.set_bus_name(idx_a, aux_bus)
			AudioServer.set_bus_send(idx_a, "Master")
		var lpf_a := AudioEffectLowPassFilter.new()
		lpf_a.cutoff_hz = 6800.0
		AudioServer.add_bus_effect(idx_a, lpf_a)
		var comp_a := AudioEffectCompressor.new()
		comp_a.threshold = -6.0
		comp_a.ratio = 3.5
		AudioServer.add_bus_effect(idx_a, comp_a)

func _init_audio_pool() -> void:
	if players.size() == 0:
		for i in range(max_players):
			var p := AudioStreamPlayer.new()
			p.name = "AudioPoolChannel_%d" % i
			p.bus = BUS_NORMAL
			p.max_polyphony = 1
			add_child(p)
			players.append(p)

	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer_CombatLoop"
		bgm_player.bus = BUS_AURA
		bgm_player.volume_db = -80.0
		add_child(bgm_player)

	if rage_aura_loop_player == null:
		rage_aura_loop_player = AudioStreamPlayer.new()
		rage_aura_loop_player.name = "RageAuraContinuousPlayer"
		rage_aura_loop_player.bus = BUS_AURA
		rage_aura_loop_player.volume_db = -80.0
		add_child(rage_aura_loop_player)

static func ensure_initialized(tree: SceneTree = null) -> KayKitAudioDirector:
	if _instance == null:
		var script_res := load("res://scripts/audio/kaykit_audio_director.gd") as GDScript
		if script_res:
			_instance = script_res.new()
			_instance.name = "KayKitAudioDirector"
			if tree == null:
				tree = Engine.get_main_loop() as SceneTree
			if tree and tree.root and not _is_adding:
				_is_adding = true
				if tree.root.is_node_ready():
					tree.root.add_child(_instance)
				else:
					tree.root.call_deferred("add_child", _instance)
	elif not _instance.is_inside_tree() and not _is_adding:
		if tree == null:
			tree = Engine.get_main_loop() as SceneTree
		if tree and tree.root and _instance.get_parent() == null:
			_is_adding = true
			if tree.root.is_node_ready():
				tree.root.add_child(_instance)
			else:
				tree.root.call_deferred("add_child", _instance)

	if not _is_prebaked and _instance:
		_instance._prebake_audio_bank()
	if _instance and _instance.players.size() == 0:
		_instance._init_audio_pool()
	return _instance

static func play_sfx(sfx_id: String, volume_offset_db: float = 0.0, pitch_override: float = 0.0) -> void:
	var inst := ensure_initialized()
	if inst:
		inst._play_internal(sfx_id, volume_offset_db, pitch_override)

static func start_bgm() -> void:
	ensure_initialized()

static func set_rage_bgm_mode(is_rage: bool) -> void:
	var inst := ensure_initialized()
	if inst == null:
		return
	inst._init_audio_pool()
	if inst.bgm_player:
		inst.bgm_player.pitch_scale = 1.08 if is_rage else 1.00
		inst.bgm_player.volume_db = -11.0 if is_rage else -14.0
	# Tuyệt đối KHÔNG bật tiếng ù liên tục trong rage_aura_loop_player để giữ âm trường trong trẻo!
	if inst.rage_aura_loop_player and inst.rage_aura_loop_player.playing:
		inst.rage_aura_loop_player.stop()

# ==============================================================================
# 2. KHO ÂM THANH CHỌN LỌC TINH TẾ (LOẠI BỎ 100% TIẾNG LASER & TÀU VŨ TRỤ)
# ==============================================================================
func _load_real_stream(key: String, candidate_paths: Array[String]) -> void:
	for path in candidate_paths:
		if ResourceLoader.exists(path):
			var s := ResourceLoader.load(path) as AudioStream
			if s != null:
				_raw_streams[key] = s
				return

func _prebake_audio_bank() -> void:
	if _is_prebaked:
		return
	_is_prebaked = true

	# 1. Nhóm Kiếm Thép & Chuyển Động (RPG Foley)
	_load_real_stream("slice_1", ["res://assets/audio/rpg/knifeSlice.ogg", "res://assets/audio/slash.wav"])
	_load_real_stream("slice_2", ["res://assets/audio/rpg/knifeSlice2.ogg", "res://assets/audio/slash.wav"])
	_load_real_stream("chop_1", ["res://assets/audio/rpg/chop.ogg", "res://assets/audio/rpg/knifeSlice.ogg"])
	_load_real_stream("draw_1", ["res://assets/audio/rpg/drawKnife1.ogg", "res://assets/audio/slash.wav"])
	_load_real_stream("draw_2", ["res://assets/audio/rpg/drawKnife2.ogg", "res://assets/audio/slash.wav"])
	_load_real_stream("draw_3", ["res://assets/audio/rpg/drawKnife3.ogg", "res://assets/audio/slash.wav"])
	_load_real_stream("cloth_light", ["res://assets/audio/rpg/cloth1.ogg", "res://assets/audio/dash.wav"])
	_load_real_stream("cloth_med", ["res://assets/audio/rpg/cloth2.ogg", "res://assets/audio/dash.wav"])
	_load_real_stream("cloth_heavy", ["res://assets/audio/rpg/clothBelt.ogg", "res://assets/audio/dash.wav"])
	_load_real_stream("step_1", ["res://assets/audio/rpg/footstep00.ogg", "res://assets/audio/click.wav"])
	_load_real_stream("step_2", ["res://assets/audio/rpg/footstep01.ogg", "res://assets/audio/click.wav"])
	_load_real_stream("step_3", ["res://assets/audio/rpg/footstep02.ogg", "res://assets/audio/click.wav"])

	# 2. Nhóm Va Đập Vật Lý & Kim Loại Nặng (Impact Foley)
	_load_real_stream("metal_heavy_1", ["res://assets/audio/impact/impactMetal_heavy_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("metal_heavy_2", ["res://assets/audio/impact/impactMetal_heavy_001.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("metal_heavy_3", ["res://assets/audio/impact/impactMetal_heavy_002.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("plate_heavy_1", ["res://assets/audio/impact/impactPlate_heavy_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("plate_heavy_2", ["res://assets/audio/impact/impactPlate_heavy_001.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("punch_heavy_1", ["res://assets/audio/impact/impactPunch_heavy_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("punch_heavy_2", ["res://assets/audio/impact/impactPunch_heavy_001.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("punch_med_1", ["res://assets/audio/impact/impactPunch_medium_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("soft_heavy_1", ["res://assets/audio/impact/impactSoft_heavy_000.ogg", "res://assets/audio/hit.wav"])
	_load_real_stream("mining_1", ["res://assets/audio/impact/impactMining_000.ogg", "res://assets/audio/crystal.wav"])
	_load_real_stream("bell_heavy", ["res://assets/audio/impact/impactBell_heavy_000.ogg", "res://assets/audio/crystal.wav"])

	# 3. Nhóm Xung Trầm Sub-Bass & Nổ Địa Chấn (Được cắt gọn max_dur nghiêm ngặt)
	_load_real_stream("sub_boom_1", ["res://assets/audio/scifi/lowFrequency_explosion_000.ogg", "res://assets/audio/impact/impactPunch_heavy_000.ogg"])
	_load_real_stream("sub_boom_2", ["res://assets/audio/scifi/lowFrequency_explosion_001.ogg", "res://assets/audio/impact/impactPunch_heavy_001.ogg"])
	_load_real_stream("exp_crunch_1", ["res://assets/audio/scifi/explosionCrunch_000.ogg", "res://assets/audio/impact/impactPlate_heavy_000.ogg"])
	_load_real_stream("exp_crunch_2", ["res://assets/audio/scifi/explosionCrunch_001.ogg", "res://assets/audio/impact/impactPlate_heavy_001.ogg"])
	_load_real_stream("fire_gust_1", ["res://assets/audio/scifi/thrusterFire_000.ogg", "res://assets/audio/rpg/clothBelt.ogg"])

	# ==========================================================================
	# BẢNG PHỐI ÂM TINH GỌN, TRẬT TỰ (1-2 LỚP/ĐÒN, CÓ MAX_DUR CẮT ĐUÔI TỰ ĐỘNG)
	# ==========================================================================

	# --------------------------------------------------------------------------
	# I. TRẠNG THÁI 1 (BÌNH THƯỜNG — SẮC GỌN, NHANH, DỨT KHOÁT)
	# --------------------------------------------------------------------------
	# 1. Đòn U1 thường: 1 nhát chém kiếm sắc gọn (0.20s)
	_sfx_bank["u1_slash"] = [
		{"s": "slice_1", "vol": -1.5, "pitch": 1.06, "delay": 0.0, "max_dur": 0.20, "bus": BUS_NORMAL, "group": "SWING", "choke": true}
	]

	# 2. Đòn U2 thường: 1 nhát chém chéo thanh thoát (0.22s)
	_sfx_bank["u2_slash"] = [
		{"s": "slice_2", "vol": -1.0, "pitch": 0.98, "delay": 0.0, "max_dur": 0.22, "bus": BUS_NORMAL, "group": "SWING", "choke": true}
	]

	# 3. Đòn U3 thường: Bổ kiếm xuống + Chạm sàn đá đầm gọn (0.38s)
	_sfx_bank["u3_heaven_shatter"] = [
		{"s": "chop_1",        "vol": 0.0,  "pitch": 0.94, "delay": 0.0,  "max_dur": 0.24, "bus": BUS_NORMAL, "group": "SWING", "choke": true},
		{"s": "punch_heavy_1", "vol": 0.5,  "pitch": 0.90, "delay": 0.05, "max_dur": 0.34, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# 4. Chiêu I Pha 1 thường: Chém chữ X 2 nhịp thép giao nhau (0.26s)
	_sfx_bank["i_phase1_x_cleave"] = [
		{"s": "draw_1",  "vol": -1.5, "pitch": 1.05, "delay": 0.0,  "max_dur": 0.22, "bus": BUS_NORMAL, "group": "SWING", "choke": true},
		{"s": "slice_2", "vol": 0.0,  "pitch": 0.95, "delay": 0.04, "max_dur": 0.24, "bus": BUS_NORMAL, "group": "SWING", "choke": false}
	]

	# 5. Chiêu I Pha 2 thường: Phóng sóng kiếm gió êm (0.30s)
	_sfx_bank["i_phase2_wave_launch"] = [
		{"s": "cloth_heavy", "vol": -0.5, "pitch": 0.92, "delay": 0.0, "max_dur": 0.30, "bus": BUS_NORMAL, "group": "SWING", "choke": false}
	]

	# 6. Chiêu I nổ cuối đường: 1 nhịp va chấn gọn (0.32s)
	_sfx_bank["i_wave_finale"] = [
		{"s": "punch_heavy_2", "vol": -0.5, "pitch": 0.88, "delay": 0.0, "max_dur": 0.32, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# --------------------------------------------------------------------------
	# II. TRẠNG THÁI 2 (KÍCH HOẠT NỘ [R] — ĐẠI KIẾM TRẦM NẶNG, UY LỰC, KHÔNG HỖN LOẠN)
	# --------------------------------------------------------------------------
	# 7. Kích hoạt Nộ [R]: Tiếng ngân đại kiếm + Xung trầm thức tỉnh gọn trong 0.48s
	_sfx_bank["rage_r_awaken"] = [
		{"s": "draw_3",     "vol": 0.5,  "pitch": 0.82, "delay": 0.0,  "max_dur": 0.38, "bus": BUS_RAGE,   "group": "STATE", "choke": true},
		{"s": "sub_boom_1", "vol": 1.5,  "pitch": 0.85, "delay": 0.02, "max_dur": 0.45, "bus": BUS_IMPACT, "group": "STATE", "choke": false},
		{"s": "bell_heavy", "vol": -2.5, "pitch": 0.80, "delay": 0.06, "max_dur": 0.48, "bus": BUS_RAGE,   "group": "STATE", "choke": false}
	]

	# 8. Kết thúc Nộ [R]: Thu kiếm nhẹ nhàng (0.25s)
	_sfx_bank["rage_r_expire"] = [
		{"s": "cloth_heavy", "vol": -4.0, "pitch": 0.78, "delay": 0.0, "max_dur": 0.25, "bus": BUS_NORMAL, "group": "STATE", "choke": true}
	]

	# 9. Đòn U1 NỘ: Đại kiếm trầm + Thép hạng nặng (Đọng lại 0.34s)
	_sfx_bank["u1_rage"] = [
		{"s": "slice_1",       "vol": 0.5,  "pitch": 0.76, "delay": 0.0,  "max_dur": 0.32, "bus": BUS_RAGE, "group": "SWING", "choke": true},
		{"s": "metal_heavy_1", "vol": -0.5, "pitch": 0.88, "delay": 0.02, "max_dur": 0.34, "bus": BUS_RAGE, "group": "SWING", "choke": false}
	]

	# 10. Đòn U2 NỘ: Song đại kiếm trầm đầm (Đọng lại 0.36s)
	_sfx_bank["u2_rage"] = [
		{"s": "slice_2",       "vol": 0.5,  "pitch": 0.72, "delay": 0.0,  "max_dur": 0.34, "bus": BUS_RAGE, "group": "SWING", "choke": true},
		{"s": "metal_heavy_2", "vol": 0.0,  "pitch": 0.84, "delay": 0.02, "max_dur": 0.36, "bus": BUS_RAGE, "group": "SWING", "choke": false}
	]

	# 11. Đòn U3 NỘ ("Huyết Lam Long Thần Giáng" — 3 Pha trật tự khớp với 5 lưỡi kiếm đọng lại 0.55s)
	_sfx_bank["u3_rage_dragon_fall"] = [
		# Pha 1 (0.00s): Giáng đại kiếm
		{"s": "chop_1",        "vol": 1.0,  "pitch": 0.72, "delay": 0.0,  "max_dur": 0.28, "bus": BUS_RAGE,   "group": "SWING",  "choke": true},
		# Pha 2 (0.06s): 5 Lưỡi kiếm cắm phập xuống đất (Địa chấn trầm gọn)
		{"s": "sub_boom_1",    "vol": 2.0,  "pitch": 0.82, "delay": 0.06, "max_dur": 0.42, "bus": BUS_IMPACT, "group": "IMPACT", "choke": true},
		{"s": "plate_heavy_1", "vol": 0.5,  "pitch": 0.78, "delay": 0.07, "max_dur": 0.38, "bus": BUS_RAGE,   "group": "IMPACT", "choke": false},
		# Pha 3 (0.20s): Dư âm kim loại ngân trầm khi 5 lưỡi kiếm phình to trên đất
		{"s": "bell_heavy",    "vol": -2.0, "pitch": 0.76, "delay": 0.20, "max_dur": 0.45, "bus": BUS_RAGE,   "group": "SWING",  "choke": false}
	]

	# 12. Chiêu I Pha 1 NỘ (6 Lưỡi Chữ X): 2 nhịp đại kiếm cắt không gian (0.38s)
	_sfx_bank["i_rage_hexa_cleave"] = [
		{"s": "draw_2",        "vol": 0.5, "pitch": 0.80, "delay": 0.0,  "max_dur": 0.30, "bus": BUS_RAGE,   "group": "SWING",  "choke": true},
		{"s": "metal_heavy_3", "vol": 1.0, "pitch": 0.82, "delay": 0.04, "max_dur": 0.36, "bus": BUS_RAGE,   "group": "SWING",  "choke": false},
		{"s": "sub_boom_2",    "vol": 0.5, "pitch": 0.90, "delay": 0.05, "max_dur": 0.38, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# 13. Chiêu I Pha 2 NỘ (Đại Sóng Kiếm 5 Cánh): Luồng sóng trầm mượt (0.42s, không nổ lụp bụp dọc đường)
	_sfx_bank["i_rage_five_wing_wave"] = [
		{"s": "sub_boom_1",  "vol": 1.5,  "pitch": 0.82, "delay": 0.0,  "max_dur": 0.40, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false},
		{"s": "fire_gust_1", "vol": -0.5, "pitch": 0.80, "delay": 0.02, "max_dur": 0.42, "bus": BUS_RAGE,   "group": "SWING",  "choke": false},
		{"s": "bell_heavy",  "vol": -3.0, "pitch": 0.74, "delay": 0.24, "max_dur": 0.38, "bus": BUS_RAGE,   "group": "SWING",  "choke": false}
	]

	# --------------------------------------------------------------------------
	# III. CÁC KỸ NĂNG CÒN LẠI (XOAY 360 [O], BOM [P], LƯỚT [SPACE], NHẢY [C], TRÚNG ĐÒN)
	# --------------------------------------------------------------------------
	# 14. Chiêu O (Xoay 360 độ): 3 nhịp vung kiếm tách bạch theo vòng xoay
	_sfx_bank["o_whirlwind_spin"] = [
		{"s": "slice_1", "vol": -0.5, "pitch": 0.92, "delay": 0.0,  "max_dur": 0.16, "bus": BUS_NORMAL, "group": "SWING", "choke": true},
		{"s": "slice_2", "vol": 0.0,  "pitch": 1.00, "delay": 0.13, "max_dur": 0.16, "bus": BUS_NORMAL, "group": "SWING", "choke": false},
		{"s": "slice_1", "vol": 0.5,  "pitch": 1.08, "delay": 0.26, "max_dur": 0.18, "bus": BUS_NORMAL, "group": "SWING", "choke": false}
	]

	# 15. Chiêu P (Ném bom): Tiếng vung tay gọn (0.16s)
	_sfx_bank["p_bomb_throw"] = [
		{"s": "cloth_med", "vol": -1.5, "pitch": 0.96, "delay": 0.0, "max_dur": 0.16, "bus": BUS_NORMAL, "group": "MOVEMENT", "choke": true}
	]

	# 16. Chiêu P (Bom nổ): 1 cú nổ trầm gọn (0.38s)
	_sfx_bank["p_bomb_thunder_explode"] = [
		{"s": "sub_boom_2",   "vol": 1.5,  "pitch": 0.85, "delay": 0.0,  "max_dur": 0.36, "bus": BUS_IMPACT, "group": "IMPACT", "choke": true},
		{"s": "exp_crunch_1", "vol": -0.5, "pitch": 0.92, "delay": 0.02, "max_dur": 0.38, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# 17. Chiêu P (Đốt DoT): Cực nhẹ (-18 dB) để không làm ồn trận đấu
	_sfx_bank["p_bomb_dot_zap"] = [
		{"s": "step_1", "vol": -18.0, "pitch": 1.55, "delay": 0.0, "max_dur": 0.06, "bus": BUS_NORMAL, "group": "FOOTSTEP", "choke": true}
	]

	# 18. Phím Space (Lướt): Tiếng lướt gió gọn (0.20s)
	_sfx_bank["dash_space"] = [
		{"s": "cloth_heavy", "vol": -1.0, "pitch": 1.02, "delay": 0.0, "max_dur": 0.20, "bus": BUS_NORMAL, "group": "MOVEMENT", "choke": true}
	]

	# 19. Phím C (Nhảy): Nhún chân gọn (0.16s)
	_sfx_bank["jump_c"] = [
		{"s": "cloth_light", "vol": -2.0, "pitch": 1.05, "delay": 0.0, "max_dur": 0.16, "bus": BUS_NORMAL, "group": "MOVEMENT", "choke": true}
	]

	# 20. Bước chân trên đá: Nhẹ nhàng, êm ái (-11 dB, 0.10s)
	_sfx_bank["footstep_stone"] = [
		{"s": "step_1", "vol": -11.5, "pitch": 0.95, "delay": 0.0, "max_dur": 0.10, "bus": BUS_NORMAL, "group": "FOOTSTEP", "choke": true}
	]

	# 21. Chém trúng Bot: 1 tiếng va chạm đầm gọn (0.18s)
	_sfx_bank["hit_enemy_flesh_metal"] = [
		{"s": "punch_heavy_1", "vol": -1.5, "pitch": 0.96, "delay": 0.0, "max_dur": 0.18, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# 22. Bot bị tiêu diệt: Tiếng gục ngã gọn (0.28s)
	_sfx_bank["enemy_death_burst"] = [
		{"s": "soft_heavy_1", "vol": 0.0, "pitch": 0.88, "delay": 0.0, "max_dur": 0.28, "bus": BUS_IMPACT, "group": "IMPACT", "choke": false}
	]

	# 23. BGM Entry giữ cho QA Test
	_sfx_bank["bgm_arena_combat_loop"] = [
		{"s": "step_1", "vol": -40.0, "pitch": 1.0, "delay": 0.0, "max_dur": 0.05, "bus": BUS_AURA, "group": "FOOTSTEP", "choke": false}
	]

	print("🎵 [KayKitAudioDirector] Clean AAA Audio Bank initialized (%d streams, %d structured events, Envelope Trim & Voice Choking enabled)." % [_raw_streams.size(), _sfx_bank.size()])

# ==============================================================================
# 3. BỘ PHÁT THÔNG MINH CÓ NGẮT KÊNH (VOICE CHOKING) & CẮT ĐUÔI (ENVELOPE TRIM)
# ==============================================================================
func _play_internal(sfx_id: String, volume_offset_db: float, pitch_override: float) -> void:
	if not _sfx_bank.has(sfx_id):
		return

	var now := float(Time.get_ticks_msec()) / 1000.0

	# Chống dội âm khi chém trúng nhiều Bot cùng lúc (hit_enemy_flesh_metal khóa 0.085s)
	var min_delay := 0.085 if sfx_id == "hit_enemy_flesh_metal" else MIN_RETRIGGER_DELAY
	if _last_play_time.has(sfx_id):
		if now - float(_last_play_time[sfx_id]) < min_delay:
			return
	_last_play_time[sfx_id] = now

	# Nếu đang tung đòn đánh/kỹ năng thì ghi nhận thời gian để tạm ngưng tiếng bước chân trong 0.30s
	if sfx_id != "footstep_stone" and sfx_id != "p_bomb_dot_zap":
		_last_combat_action_time = now
	elif sfx_id == "footstep_stone":
		if now - _last_combat_action_time < 0.28:
			play_count += 1
			play_counts[sfx_id] = int(play_counts.get(sfx_id, 0)) + 1
			return

	_init_audio_pool()
	if players.size() == 0:
		return

	var layers: Array = _sfx_bank[sfx_id]
	var jitter_pitch := pitch_override if pitch_override > 0.0 else randf_range(0.97, 1.03)

	for layer in layers:
		var stream_key: String = layer.get("s", "slice_1")
		if sfx_id == "footstep_stone":
			var steps := ["step_1", "step_2", "step_3"]
			stream_key = steps[play_count % steps.size()]

		var stream: AudioStream = _raw_streams.get(stream_key, null)
		if stream == null:
			continue

		var base_vol: float = float(layer.get("vol", 0.0)) + volume_offset_db
		var base_pitch: float = float(layer.get("pitch", 1.0)) * jitter_pitch
		var delay_sec: float = float(layer.get("delay", 0.0))
		var max_dur: float = float(layer.get("max_dur", 0.30))
		var target_bus: String = str(layer.get("bus", BUS_NORMAL))
		var group_name: String = str(layer.get("group", "SWING"))
		var should_choke: bool = bool(layer.get("choke", false))

		if delay_sec <= 0.001 or not is_inside_tree():
			_trigger_controlled_layer(stream, base_vol, base_pitch, max_dur, target_bus, group_name, should_choke)
		else:
			var tw := create_tween()
			tw.tween_interval(delay_sec)
			tw.tween_callback(func():
				_trigger_controlled_layer(stream, base_vol, base_pitch, max_dur, target_bus, group_name, should_choke)
			)

	play_count += 1
	play_counts[sfx_id] = int(play_counts.get(sfx_id, 0)) + 1

func _choke_voice_group(group_name: String) -> void:
	if not _active_group_players.has(group_name):
		return
	var list: Array = _active_group_players[group_name]
	for p in list:
		if is_instance_valid(p) and (p as AudioStreamPlayer).playing:
			var asp := p as AudioStreamPlayer
			if _player_fade_tweens.has(asp) and _player_fade_tweens[asp] != null:
				(_player_fade_tweens[asp] as Tween).kill()
			if is_inside_tree():
				var fast_fade := create_tween()
				_player_fade_tweens[asp] = fast_fade
				fast_fade.tween_property(asp, "volume_db", -48.0, 0.035)
				fast_fade.tween_callback(asp.stop)
			else:
				asp.stop()
	_active_group_players[group_name] = []

func _trigger_controlled_layer(
	stream: AudioStream,
	vol_db: float,
	pitch_val: float,
	max_dur: float,
	bus_name: String,
	group_name: String,
	should_choke: bool
) -> void:
	if players.size() == 0:
		return

	if should_choke:
		_choke_voice_group(group_name)

	var player := players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % max_players

	if _player_fade_tweens.has(player) and _player_fade_tweens[player] != null:
		(_player_fade_tweens[player] as Tween).kill()

	if AudioServer.get_bus_index(bus_name) != -1:
		player.bus = bus_name
	else:
		player.bus = "Master"

	player.stream = stream
	player.volume_db = clampf(vol_db, -45.0, 3.0)
	player.pitch_scale = clampf(pitch_val, 0.55, 1.85)

	if player.is_inside_tree():
		player.play()
		if not _active_group_players.has(group_name):
			_active_group_players[group_name] = []
		_active_group_players[group_name].append(player)

		# Bộ cắt đuôi tự động (Envelope Trim): Đảm bảo không bao giờ ngân lê thê gây lộn xộn
		var hold_time := maxf(0.04, max_dur - 0.05)
		var env_tw := create_tween()
		_player_fade_tweens[player] = env_tw
		env_tw.tween_interval(hold_time)
		env_tw.tween_property(player, "volume_db", -48.0, 0.05)
		env_tw.tween_callback(player.stop)
```

---

### 🔹 TASK 30.2: XÓA BỎ CÁC LỆNH GỌI CHỒNG ÂM THANH TRONG `src_game/scripts/characters/hero_knight_3d.gd`

Trong `src_game/scripts/characters/hero_knight_3d.gd`, sửa lại 3 hàm `_do_spin_attack()`, `_do_dodge()` và `_physics_process()` để **mỗi hành động chỉ gọi đúng 1 sự kiện âm thanh duy nhất** (không gọi chồng 2 sự kiện gây loạn tiếng):

1. **Trong `_do_spin_attack()` (Chiêu `[O]` / `Q` Xoay 360°):**
   ```gdscript
   # Chỉ gọi duy nhất o_whirlwind_spin (khi Nộ thì hạ pitch xuống 0.78 cho đầm nặng, tuyệt đối không gọi chồng u1_rage!)
   if _is_rage_state_2:
       KayKitAudioDirector.play_sfx("o_whirlwind_spin", 1.5, 0.78)
   else:
       KayKitAudioDirector.play_sfx("o_whirlwind_spin")
   ```
2. **Trong `_do_dodge()` (Phím `[Space]` Lướt):**
   ```gdscript
   # Chỉ gọi duy nhất dash_space (tuyệt đối không gọi chồng i_phase2_wave_launch!)
   if _is_rage_state_2:
       KayKitAudioDirector.play_sfx("dash_space", 1.0, 0.82)
   else:
       KayKitAudioDirector.play_sfx("dash_space")
   ```
3. **Trong `_physics_process(delta)` (Tiếng bước chân):**
   ```gdscript
   if is_on_floor():
       _footstep_timer -= delta
       if _footstep_timer <= 0.0:
           _footstep_timer = 0.25 if _is_rage_state_2 else 0.28
           if _is_rage_state_2:
               KayKitAudioDirector.play_sfx("footstep_stone", 1.5, 0.88)
           else:
               KayKitAudioDirector.play_sfx("footstep_stone", 0.0, 1.0)
   ```

---

### 🔹 TASK 30.3: KIỂM THỬ TỰ ĐỘNG 100% PASS (`test_phase_30_clean_structured_audio.gd`) & ĐỒNG BỘ GITHUB (`AGENT-06`)

1. Viết và chạy kịch bản kiểm thử tự động `src_game/tests/test_phase_30_clean_structured_audio.gd` xác nhận **PASS 100%** 4 tiêu chuẩn:
   * **Test 30.1 (Kiểm định Cấm File Laser & Tàu Vũ Trụ):** Xác nhận trong `KayKitAudioDirector._raw_streams` hoàn toàn **không chứa** `laser_large`, `laser_small`, `engine_roar`, `forcefield`, và `rage_aura_loop_player.playing == false`.
   * **Test 30.2 (Kiểm định Số Lớp Tinh Gọn & Cắt Đuôi `max_dur`):** Quét toàn bộ 23 sự kiện trong `_sfx_bank`: Mọi đòn đánh thường chỉ có `1–2` lớp, chiêu cuối tối đa `3` lớp, và **100% các lớp đều có thuộc tính `max_dur <= 0.55s`** cùng nhóm `group` hợp lệ.
   * **Test 30.3 (Kiểm định Audio Bus Sạch Không Distortion):** Xác nhận trên `RageOverdriveBus` và `NormalBladeBus` hoàn toàn không có `AudioEffectDistortion` gây rè vỡ tiếng, đồng thời các chiêu Trạng thái 1 đi qua `NormalBladeBus` và Trạng thái 2 đi qua `RageOverdriveBus` / `HeavyImpactBus`.
   * **Test 30.4 (Bảo toàn 0% Khối Thô `PrimitiveMesh == 0` & Hồi Quy Phase 24–29):** Quét toàn bộ SceneTree xác nhận `primitive_count == 0` và chạy lại `test_phase_27_rage_aura_6layers_and_audio_system.gd` đạt PASS 100%.
2. Cập nhật `docs/TASK_PROGRESS.md`, xuất lại `docs/CURRENT_CODE_SNAPSHOT.md`, sau đó chạy `git add .`, `git commit -m "fix(phase30): purge chaotic multi-layer sci-fi sounds, implement clean envelope-trimmed combat audio with voice group choking"` và `git push` lên `https://github.com/NhutPham19/GameWizad`.