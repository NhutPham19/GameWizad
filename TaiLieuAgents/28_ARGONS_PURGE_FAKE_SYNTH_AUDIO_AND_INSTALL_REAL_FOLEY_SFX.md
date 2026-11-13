# 👑 CHỈ ĐẠO SỐ 28 TỪ ARGONS: XÓA SẠCH 100% ÂM THANH TỔNG HỢP LỖI (BÍP ĐIỆN TỬ / RÈ NHIỄU SÓNG / Ù NỀN) & THAY THẾ BẰNG HỆ THỐNG THU ÂM FOLEY THỰC TẾ ĐA LỚP (`KENNEY RPG & IMPACT AUDIO`)

* **Người chỉ đạo (Chief Architect):** ARGONS
* **Đơn vị thực thi:** ANTIGRAVITY IDE (`Claude Opus 4.6` / `Gemini 3.8 Flash`)
* **Kho GitHub dự án:** `https://github.com/NhutPham19/GameWizad`
* **Trạng thái nền tảng:** Đồ họa, Vật lý Cầu thang và Hào quang Nộ 6 Lớp (Phase 24–27) đã đạt chuẩn 100%. Cần thay thế toàn bộ hệ thống âm thanh đang bị lỗi.

---

## 🚨 CHẨN ĐOÁN 4 LỖI ÂM THANH NGHIÊM TRỌNG TRONG PHASE 27 BẮT BUỘC PHẢI XÓA BỎ NGAY

Qua kiểm tra trực tiếp mã nguồn `src_game/scripts/audio/kaykit_audio_director.gd` và `DANH_SACH_FILE_AM_THANH.txt`, đây là 4 nguyên nhân khiến âm thanh nghe như **tiếng bíp điện tử, tiếng rè radio và tiếng ù ù giả tạo**:

1. **Lỗi 1 — Tiếng ù ù liên tục suốt trận (`_synth_battle_pulse_loop`):**
   * Hàm `_synth_battle_pulse_loop` đang phát lặp vô tận 3 sóng `sin(220Hz) + sin(261.63Hz) + sin(329.63Hz)` trộn `sin(65Hz)`. Sóng hình sin thuần túy phát kéo dài tạo ra tiếng ù điện cực kỳ khó chịu.
   * **Lệnh xử lý:** **XÓA BỎ HOÀN TOÀN** `_synth_battle_pulse_loop` và tắt tự động phát nhạc nền giả tạo!
2. **Lỗi 2 — Tiếng "chíu... bíp..." điện tử 8-bit khi vung kiếm (`_synth_slash`, `_synth_rage_slash`, `_synth_metallic_cross`):**
   * Việc dùng công thức `sin(TAU * lerpf(f_start, f_end, prog) * t)` và `fmod(420.0 * t, 1.0)` trong code tạo ra sóng trượt tần số giống hệt máy điện tử băng 4 nút, hoàn toàn không giống tiếng kiếm chém hay tiếng sét.
   * **Lệnh xử lý:** **XÓA SẠCH 100%** toàn bộ 16 hàm `_synth_*` trong `kaykit_audio_director.gd` và 4 hàm `_generate_*` trong `synth_audio.gd`!
3. **Lỗi 3 — Tiếng rè nhiễu sóng radio (`_synth_whoosh`, `_synth_whirlwind`, `_synth_thunder_explosion`):**
   * Gọi `randf_range(-0.6, 0.6)` trực tiếp ở `44,100 Hz` tạo ra nhiễu trắng (`White Noise`) nguyên bản — phát ra loa chính là tiếng "xè xè / xoẹt xoẹt" như tivi mất đài.
4. **Lỗi 4 — Kho âm thanh hiện tại mới chỉ có bộ UI (`click`, `switch`, `rollover`) và các file `slash.wav`, `dash.wav`, `hit.wav` tự sinh bằng script cũ:**
   * Trong `assets_staging/gamedev_resources/audio_sfx/` hiện mới chỉ có `kenney_interface_sounds` và `kenney_ui_audio`, chưa nạp gói âm thanh chiến đấu thực tế (`kenney-rpg-audio` và `kenney-impact-sounds`).

---

## 🛡️ 3 LUẬT THÉP VỀ ÂM THANH TRONG CHỈ ĐẠO SỐ 28

1. **CẤM 100% TỰ VIẾT CODE SINH SÓNG ÂM (`0% PROCEDURAL SINE/NOISE SYNTHESIS`):**
   * Nghiêm cấm sử dụng `PackedByteArray`, `encode_s16`, `sin(TAU * freq * t)` hay `randf_range()` để tự chế âm thanh trong GDScript hay Python!
   * 100% âm thanh phát ra trong game bắt buộc phải là **file thu âm thực tế (`.ogg` / `.wav`)** được nạp từ ổ cứng qua `ResourceLoader.load()`.
2. **SỬ DỤNG KỸ THUẬT PHỐI ÂM ĐA LỚP PHÒNG THU (`MULTI-LAYER REAL FOLEY COMPOSITING`):**
   * Một chiêu thức mạnh không bao giờ chỉ phát 1 file âm thanh đơn lẻ. Mỗi kỹ năng (`U1`, `U2`, `U3`, `I`, `O`, `P`, `R`) sẽ kết hợp **2 đến 3 lớp file thu âm vật lý thật** (Ví dụ: *Lớp 1: Tiếng vải/gió vút qua không trung* + *Lớp 2: Tiếng lưỡi thép sắc lẹm cắt gió* + *Lớp 3: Tiếng đá vỡ/va chạm kim loại trầm hùng*) với độ trễ (`delay_ms`) và cao độ (`pitch_scale`) tinh chỉnh chính xác.
3. **TÍCH HỢP BỘ LỌC STUDIO TRÊN AUDIO BUS (`LOW-PASS FILTER + COMPRESSOR`):**
   * Tạo nhánh âm thanh chuyên biệt có gắn `AudioEffectLowPassFilter` (cắt bỏ dải tần chói tai `> 6800 Hz`) và `AudioEffectCompressor` (nén âm lượng mượt mà, chống rè vỡ tiếng khi nhiều đòn đánh nổ cùng lúc).

---

## 📦 TASK 28.1: TẢI & TÍCH HỢP 2 GÓI ÂM THANH CHIẾN ĐẤU THẬT CỦA KENNEY (`kenney-rpg-audio` & `kenney-impact-sounds`)

Sử dụng thư mục `E:\DoAnCaNhan\ThuVienGame\GameWizad\assets_staging\gamedev_resources\audio_sfx\` (đã được User cấp phép lưu trữ tài nguyên âm thanh từ Giai đoạn 11.2):

1. **Chạy lệnh Git Clone tải 2 bộ thu âm Foley thật 100% CC0 của Kenney từ GitHub `Calinou`:**
   ```powershell
   git clone --depth 1 https://github.com/Calinou/kenney-rpg-audio.git "E:/DoAnCaNhan/ThuVienGame/GameWizad/assets_staging/gamedev_resources/audio_sfx/rpg_audio"
   git clone --depth 1 https://github.com/Calinou/kenney-impact-sounds.git "E:/DoAnCaNhan/ThuVienGame/GameWizad/assets_staging/gamedev_resources/audio_sfx/impact_sounds"
   ```
2. **Sao chép các file âm thanh thực tế vào thư mục dự án Godot (`src_game/assets/audio/`):**
   * Tạo 3 thư mục con sạch sẽ trong `src_game/assets/audio/`:
     * `src_game/assets/audio/rpg/` $\leftarrow$ Copy toàn bộ file `.wav` / `.ogg` từ `rpg_audio/addons/kenney_rpg_audio/` (gồm: `knifeSlice.wav`, `knifeSlice2.wav`, `chop.wav`, `drawKnife1.wav`, `drawKnife2.wav`, `drawKnife3.wav`, `cloth1.wav`, `cloth2.wav`, `cloth3.wav`, `cloth4.wav`, `footstep00.wav` .. `footstep09.wav`, `metalPot1.wav` .. `metalPot3.wav`, `heavyPunch.wav`...).
     * `src_game/assets/audio/impact/` $\leftarrow$ Copy toàn bộ file `.ogg` / `.wav` từ `impact_sounds/addons/kenney_impact_sounds/` (gồm: `impactMetal_heavy_000..004.ogg`, `impactMetal_medium_000..004.ogg`, `impactMetal_light_000..004.ogg`, `impactMining_000..004.ogg`, `impactPunch_heavy_000..004.ogg`, `impactPunch_medium_000..004.ogg`, `impactBell_heavy_000..004.ogg`, `impactPlate_heavy_000..004.ogg`, `impactSoft_heavy_000..004.ogg`, `footstep_concrete_000..004.ogg`).
     * `src_game/assets/audio/ui/` $\leftarrow$ Copy các file hiệu ứng chọn lọc từ `kenney_interface_sounds` (`bong_001.wav`, `glass_001..006.wav`, `drop_001..004.wav`, `pluck_001..002.wav`, `confirmation_001..002.wav`).
3. **Xóa bỏ các file `.wav` giả tạo cũ trong `src_game/assets/audio/`:**
   * Ghi đè `src_game/assets/audio/slash.wav` bằng file thật `knifeSlice.wav` của Kenney RPG Audio.
   * Ghi đè `src_game/assets/audio/dash.wav` bằng file thật `cloth1.wav` của Kenney RPG Audio.
   * Ghi đè `src_game/assets/audio/hit.wav` bằng file thật `impactPunch_heavy_000.ogg` (hoặc `.wav`).
4. **Chạy lệnh Headless Import 1 lượt để Godot 4.3 nhận diện 100% file `.ogg` / `.wav` mới:**
   ```powershell
   D:\GameEngines\Godot\Godot_v4.3-stable_win64_console.exe --path src_game --import --headless
   ```

---

## 🎛️ TASK 28.2: VIẾT LẠI HOÀN TOÀN `KayKitAudioDirector` (`src_game/scripts/audio/kaykit_audio_director.gd`) — 100% FILE THU ÂM THẬT + HÒA ÂM ĐA LỚP + BỘ LỌC STUDIO

Thay thế **toàn bộ** nội dung file `src_game/scripts/audio/kaykit_audio_director.gd` bằng mã nguồn chuẩn dưới đây (Tuyệt đối **0% hàm `_synth_*`**, **0% tiếng ù BGM**, sử dụng **Bộ Phối Âm Đa Lớp Foley Thật** và **Bộ Lọc Âm Trầm Ấm Áp `CombatSFX` Bus**):

```gdscript
class_name KayKitAudioDirector
extends Node

# ==============================================================================
# KAYKIT AUDIO DIRECTOR — DIRECTIVE 28 (AUTHENTIC STUDIO FOLEY OVERHAUL)
# - TUYỆT ĐỐI 0% SÓNG SIN ĐIỆN TỬ, 0% NHIỄU TRẮNG RÈ, 0% NHẠC NỀN Ù Ù!
# - 100% SỬ DỤNG FILE THU ÂM FOLEY THẬT (.OGG / .WAV) TỪ KENNEY RPG & IMPACT PACKS
# - KỸ THUẬT HÒA ÂM ĐA LỚP (MULTI-LAYER COMPOSITE FOLEY) + STUDIO LOW-PASS & COMPRESSOR
# ==============================================================================

static var _instance: KayKitAudioDirector = null
static var _raw_streams: Dictionary = {}
static var _sfx_bank: Dictionary = {} # Giữ tương thích cho các bài test kiểm tra _sfx_bank.size()
static var _is_prebaked: bool = false
static var _is_adding: bool = false

var players: Array[AudioStreamPlayer] = []
var max_players: int = 24
var current_player_idx: int = 0
var bgm_player: AudioStreamPlayer = null

var play_count: int = 0
var play_counts: Dictionary = {}
var _last_play_time: Dictionary = {}
var _footstep_cycle_idx: int = 0
var _hit_cycle_idx: int = 0

const MIN_RETRIGGER_DELAY: float = 0.04
const COMBAT_BUS_NAME: String = "CombatSFX"

# Danh mục các đường dẫn file thu âm thật của Kenney
const SAMPLE_PATHS: Dictionary = {
	# 1. Vũ khí & Chém kiếm (Kenney RPG Audio)
	"slice_1": ["res://assets/audio/rpg/knifeSlice.ogg", "res://assets/audio/rpg/knifeSlice.wav", "res://assets/audio/slash.wav"],
	"slice_2": ["res://assets/audio/rpg/knifeSlice2.ogg", "res://assets/audio/rpg/knifeSlice2.wav", "res://assets/audio/slash.wav"],
	"chop": ["res://assets/audio/rpg/chop.ogg", "res://assets/audio/rpg/chop.wav", "res://assets/audio/slash.wav"],
	"draw_blade_1": ["res://assets/audio/rpg/drawKnife1.ogg", "res://assets/audio/rpg/drawKnife1.wav"],
	"draw_blade_2": ["res://assets/audio/rpg/drawKnife2.ogg", "res://assets/audio/rpg/drawKnife2.wav"],
	"draw_blade_3": ["res://assets/audio/rpg/drawKnife3.ogg", "res://assets/audio/rpg/drawKnife3.wav"],

	# 2. Tiếng gió vút / Áo choàng lướt (Kenney RPG Cloth Foley)
	"cloth_1": ["res://assets/audio/rpg/cloth1.ogg", "res://assets/audio/rpg/cloth1.wav", "res://assets/audio/dash.wav"],
	"cloth_2": ["res://assets/audio/rpg/cloth2.ogg", "res://assets/audio/rpg/cloth2.wav"],
	"cloth_3": ["res://assets/audio/rpg/cloth3.ogg", "res://assets/audio/rpg/cloth3.wav"],
	"cloth_4": ["res://assets/audio/rpg/cloth4.ogg", "res://assets/audio/rpg/cloth4.wav"],

	# 3. Va chạm Kim loại, Đá vỡ, Nện đất & Chuông trầm (Kenney Impact Sounds)
	"metal_heavy_0": ["res://assets/audio/impact/impactMetal_heavy_000.ogg", "res://assets/audio/impact/impactMetal_heavy_000.wav"],
	"metal_heavy_1": ["res://assets/audio/impact/impactMetal_heavy_001.ogg", "res://assets/audio/impact/impactMetal_heavy_001.wav"],
	"metal_heavy_2": ["res://assets/audio/impact/impactMetal_heavy_002.ogg", "res://assets/audio/impact/impactMetal_heavy_002.wav"],
	"metal_med_0": ["res://assets/audio/impact/impactMetal_medium_000.ogg", "res://assets/audio/impact/impactMetal_medium_000.wav"],
	"metal_med_1": ["res://assets/audio/impact/impactMetal_medium_001.ogg", "res://assets/audio/impact/impactMetal_medium_001.wav"],
	"metal_light_0": ["res://assets/audio/impact/impactMetal_light_000.ogg", "res://assets/audio/impact/impactMetal_light_000.wav"],

	"rock_slam_0": ["res://assets/audio/impact/impactMining_000.ogg", "res://assets/audio/impact/impactMining_000.wav"],
	"rock_slam_1": ["res://assets/audio/impact/impactMining_001.ogg", "res://assets/audio/impact/impactMining_001.wav"],
	"rock_slam_2": ["res://assets/audio/impact/impactMining_002.ogg", "res://assets/audio/impact/impactMining_002.wav"],
	"rock_slam_3": ["res://assets/audio/impact/impactMining_003.ogg", "res://assets/audio/impact/impactMining_003.wav"],

	"punch_heavy_0": ["res://assets/audio/impact/impactPunch_heavy_000.ogg", "res://assets/audio/impact/impactPunch_heavy_000.wav", "res://assets/audio/hit.wav"],
	"punch_heavy_1": ["res://assets/audio/impact/impactPunch_heavy_001.ogg", "res://assets/audio/impact/impactPunch_heavy_001.wav"],
	"punch_heavy_2": ["res://assets/audio/impact/impactPunch_heavy_002.ogg", "res://assets/audio/impact/impactPunch_heavy_002.wav"],
	"punch_heavy_3": ["res://assets/audio/impact/impactPunch_heavy_003.ogg", "res://assets/audio/impact/impactPunch_heavy_003.wav"],

	"soft_boom_0": ["res://assets/audio/impact/impactSoft_heavy_000.ogg", "res://assets/audio/impact/impactSoft_heavy_000.wav"],
	"soft_boom_1": ["res://assets/audio/impact/impactSoft_heavy_001.ogg", "res://assets/audio/impact/impactSoft_heavy_001.wav"],
	"soft_boom_2": ["res://assets/audio/impact/impactSoft_heavy_002.ogg", "res://assets/audio/impact/impactSoft_heavy_002.wav"],

	"plate_heavy_0": ["res://assets/audio/impact/impactPlate_heavy_000.ogg", "res://assets/audio/impact/impactPlate_heavy_000.wav"],
	"plate_heavy_1": ["res://assets/audio/impact/impactPlate_heavy_001.ogg", "res://assets/audio/impact/impactPlate_heavy_001.wav"],

	"bell_heavy_0": ["res://assets/audio/impact/impactBell_heavy_000.ogg", "res://assets/audio/impact/impactBell_heavy_000.wav"],
	"bell_heavy_1": ["res://assets/audio/impact/impactBell_heavy_001.ogg", "res://assets/audio/impact/impactBell_heavy_001.wav"],

	# 4. Bước chân trên sàn đá (Kenney Impact & RPG Footsteps)
	"step_0": ["res://assets/audio/impact/footstep_concrete_000.ogg", "res://assets/audio/rpg/footstep00.ogg", "res://assets/audio/rpg/footstep00.wav"],
	"step_1": ["res://assets/audio/impact/footstep_concrete_001.ogg", "res://assets/audio/rpg/footstep01.ogg", "res://assets/audio/rpg/footstep01.wav"],
	"step_2": ["res://assets/audio/impact/footstep_concrete_002.ogg", "res://assets/audio/rpg/footstep02.ogg", "res://assets/audio/rpg/footstep02.wav"],
	"step_3": ["res://assets/audio/impact/footstep_concrete_003.ogg", "res://assets/audio/rpg/footstep03.ogg", "res://assets/audio/rpg/footstep03.wav"],
	"step_4": ["res://assets/audio/impact/footstep_concrete_004.ogg", "res://assets/audio/rpg/footstep04.ogg", "res://assets/audio/rpg/footstep04.wav"],

	# 5. Hiệu ứng tinh thể / tia điện nhẹ (Kenney Interface)
	"glass_crack": ["res://assets/audio/ui/glass_004.wav", "res://assets/audio/crystal.wav"],
	"bong_low": ["res://assets/audio/ui/bong_001.wav", "res://assets/audio/pickup_health.wav"]
}

# Ma trận Hòa Âm Đa Lớp (Multi-Layer Foley Recipes) cho 23 Sự kiện Âm thanh
const FOLEY_RECIPES: Dictionary = {
	# --- ĐÒN ĐÁNH THƯỜNG [U] TRẠNG THÁI 1 ---
	"u1_slash": [
		{"sample": "cloth_1", "vol_db": -5.0, "pitch": 1.05, "delay": 0.0},
		{"sample": "slice_1", "vol_db": -2.5, "pitch": 1.00, "delay": 0.015}
	],
	"u2_slash": [
		{"sample": "slice_2", "vol_db": -3.0, "pitch": 0.96, "delay": 0.0},
		{"sample": "slice_1", "vol_db": -2.0, "pitch": 1.12, "delay": 0.045},
		{"sample": "draw_blade_1", "vol_db": -9.0, "pitch": 1.18, "delay": 0.02}
	],
	"u3_heaven_shatter": [
		{"sample": "slice_2", "vol_db": -1.5, "pitch": 0.76, "delay": 0.0},
		{"sample": "rock_slam_0", "vol_db": 0.5, "pitch": 0.82, "delay": 0.05},
		{"sample": "soft_boom_0", "vol_db": 1.0, "pitch": 0.70, "delay": 0.05},
		{"sample": "bell_heavy_0", "vol_db": -6.5, "pitch": 0.92, "delay": 0.06}
	],

	# --- ĐÒN ĐÁNH [U] TRẠNG THÁI 2 (HÓA NỘ ĐỎ-XANH) ---
	"u1_rage": [
		{"sample": "slice_1", "vol_db": -1.5, "pitch": 0.85, "delay": 0.0},
		{"sample": "draw_blade_2", "vol_db": -5.5, "pitch": 0.95, "delay": 0.01},
		{"sample": "soft_boom_1", "vol_db": -3.5, "pitch": 0.82, "delay": 0.02}
	],
	"u2_rage": [
		{"sample": "slice_2", "vol_db": -1.5, "pitch": 0.82, "delay": 0.0},
		{"sample": "slice_1", "vol_db": -1.0, "pitch": 0.98, "delay": 0.04},
		{"sample": "metal_heavy_0", "vol_db": -4.0, "pitch": 0.88, "delay": 0.03}
	],
	"u3_rage_dragon_fall": [
		{"sample": "slice_2", "vol_db": 0.0, "pitch": 0.68, "delay": 0.0},
		{"sample": "rock_slam_1", "vol_db": 1.5, "pitch": 0.72, "delay": 0.04},
		{"sample": "soft_boom_2", "vol_db": 2.0, "pitch": 0.62, "delay": 0.04},
		{"sample": "metal_heavy_1", "vol_db": -2.0, "pitch": 0.78, "delay": 0.06},
		{"sample": "bell_heavy_1", "vol_db": -4.5, "pitch": 0.78, "delay": 0.07}
	],

	# --- TUYỆT KỸ [I] PHÁ KHÔNG TRẢM (THƯỜNG & NỘ) ---
	"i_phase1_x_cleave": [
		{"sample": "cloth_2", "vol_db": -4.0, "pitch": 1.10, "delay": 0.0},
		{"sample": "slice_1", "vol_db": -2.0, "pitch": 1.05, "delay": 0.01},
		{"sample": "slice_2", "vol_db": -1.5, "pitch": 0.92, "delay": 0.05},
		{"sample": "draw_blade_1", "vol_db": -6.0, "pitch": 1.05, "delay": 0.03}
	],
	"i_phase2_wave_launch": [
		{"sample": "cloth_4", "vol_db": -2.0, "pitch": 0.75, "delay": 0.0},
		{"sample": "slice_2", "vol_db": -2.5, "pitch": 0.80, "delay": 0.02},
		{"sample": "rock_slam_2", "vol_db": -3.5, "pitch": 0.90, "delay": 0.03}
	],
	"i_wave_finale": [
		{"sample": "soft_boom_0", "vol_db": 0.0, "pitch": 0.78, "delay": 0.0},
		{"sample": "rock_slam_3", "vol_db": -1.5, "pitch": 0.85, "delay": 0.01},
		{"sample": "plate_heavy_0", "vol_db": -4.0, "pitch": 0.88, "delay": 0.02}
	],
	"i_rage_hexa_cleave": [
		{"sample": "slice_1", "vol_db": -1.0, "pitch": 0.86, "delay": 0.0},
		{"sample": "slice_2", "vol_db": -0.5, "pitch": 0.78, "delay": 0.04},
		{"sample": "metal_heavy_2", "vol_db": -2.5, "pitch": 0.85, "delay": 0.02},
		{"sample": "draw_blade_3", "vol_db": -4.5, "pitch": 0.90, "delay": 0.05}
	],
	"i_rage_five_wing_wave": [
		{"sample": "cloth_4", "vol_db": -0.5, "pitch": 0.65, "delay": 0.0},
		{"sample": "soft_boom_1", "vol_db": 0.5, "pitch": 0.70, "delay": 0.01},
		{"sample": "rock_slam_0", "vol_db": -1.0, "pitch": 0.76, "delay": 0.03}
	],

	# --- KỸ NĂNG [O] XOAY 360 ĐỘ ---
	"o_whirlwind_spin": [
		{"sample": "slice_1", "vol_db": -3.0, "pitch": 0.92, "delay": 0.00},
		{"sample": "cloth_1", "vol_db": -4.0, "pitch": 0.90, "delay": 0.02},
		{"sample": "slice_2", "vol_db": -2.5, "pitch": 1.00, "delay": 0.11},
		{"sample": "slice_1", "vol_db": -2.5, "pitch": 1.08, "delay": 0.22},
		{"sample": "slice_2", "vol_db": -2.0, "pitch": 1.15, "delay": 0.33}
	],

	# --- KỸ NĂNG [P] BOM LÔI VỤ ---
	"p_bomb_throw": [
		{"sample": "cloth_3", "vol_db": -3.5, "pitch": 1.12, "delay": 0.0},
		{"sample": "chop", "vol_db": -6.0, "pitch": 1.20, "delay": 0.01}
	],
	"p_bomb_thunder_explode": [
		{"sample": "soft_boom_2", "vol_db": 1.5, "pitch": 0.65, "delay": 0.0},
		{"sample": "rock_slam_1", "vol_db": 0.0, "pitch": 0.78, "delay": 0.01},
		{"sample": "glass_crack", "vol_db": -4.5, "pitch": 0.72, "delay": 0.02}
	],
	"p_bomb_dot_zap": [
		{"sample": "metal_light_0", "vol_db": -12.0, "pitch": 1.45, "delay": 0.0}
	],

	# --- TRẠNG THÁI 2 [R] HÓA NỘ ---
	"rage_r_awaken": [
		{"sample": "soft_boom_0", "vol_db": 2.0, "pitch": 0.62, "delay": 0.0},
		{"sample": "draw_blade_3", "vol_db": -1.5, "pitch": 0.78, "delay": 0.02},
		{"sample": "bell_heavy_0", "vol_db": -2.0, "pitch": 0.74, "delay": 0.03},
		{"sample": "rock_slam_2", "vol_db": -1.0, "pitch": 0.75, "delay": 0.04}
	],
	"rage_r_expire": [
		{"sample": "cloth_4", "vol_db": -4.5, "pitch": 0.78, "delay": 0.0},
		{"sample": "bong_low", "vol_db": -8.0, "pitch": 0.82, "delay": 0.02}
	],

	# --- DI CHUYỂN & VA CHẠM ---
	"dash_space": [
		{"sample": "cloth_1", "vol_db": -3.0, "pitch": 0.88, "delay": 0.0},
		{"sample": "chop", "vol_db": -5.5, "pitch": 0.95, "delay": 0.01}
	],
	"jump_c": [
		{"sample": "cloth_2", "vol_db": -4.5, "pitch": 1.08, "delay": 0.0},
		{"sample": "step_0", "vol_db": -8.0, "pitch": 0.85, "delay": 0.0}
	],
	"footstep_stone": [
		{"sample": "step_0", "vol_db": -12.5, "pitch": 1.0, "delay": 0.0}
	],
	"hit_enemy_flesh_metal": [
		{"sample": "punch_heavy_0", "vol_db": -2.5, "pitch": 0.96, "delay": 0.0},
		{"sample": "metal_med_0", "vol_db": -5.5, "pitch": 0.92, "delay": 0.01}
	],
	"enemy_death_burst": [
		{"sample": "punch_heavy_2", "vol_db": -1.0, "pitch": 0.75, "delay": 0.0},
		{"sample": "plate_heavy_1", "vol_db": -3.0, "pitch": 0.78, "delay": 0.03},
		{"sample": "soft_boom_1", "vol_db": -2.5, "pitch": 0.72, "delay": 0.04}
	]
}

func _init() -> void:
	if _instance == null:
		_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_studio_audio_bus()
	_prebake_audio_bank()

func _ready() -> void:
	_is_adding = false
	_setup_studio_audio_bus()
	_init_audio_pool()

static func _setup_studio_audio_bus() -> void:
	var bus_idx := AudioServer.get_bus_index(COMBAT_BUS_NAME)
	if bus_idx == -1:
		AudioServer.add_bus()
		bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_idx, COMBAT_BUS_NAME)
		AudioServer.set_bus_send(bus_idx, "Master")
		AudioServer.set_bus_volume_db(bus_idx, -1.5)

		# 1. Bộ lọc Low-Pass cắt bỏ hoàn toàn dải tần chói tai (> 6800 Hz), giữ âm thanh ấm và đầm
		var lpf := AudioEffectLowPassFilter.new()
		lpf.cutoff_hz = 6800.0
		lpf.resonance = 0.38
		AudioServer.add_bus_effect(bus_idx, lpf)

		# 2. Bộ nén Compressor chống vỡ tiếng khi nhiều chiêu nổ cùng lúc
		var comp := AudioEffectCompressor.new()
		comp.threshold = -8.0
		comp.ratio = 4.0
		comp.attack_us = 50.0
		comp.release_ms = 120.0
		AudioServer.add_bus_effect(bus_idx, comp)

func _init_audio_pool() -> void:
	var target_bus := COMBAT_BUS_NAME if AudioServer.get_bus_index(COMBAT_BUS_NAME) != -1 else "Master"
	if players.size() == 0:
		for i in range(max_players):
			var p := AudioStreamPlayer.new()
			p.name = "AudioPoolChannel_%d" % i
			p.bus = target_bus
			p.max_polyphony = 4
			add_child(p)
			players.append(p)

	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer_CombatLoop"
		bgm_player.bus = "Master"
		bgm_player.volume_db = -14.0
		add_child(bgm_player)
		# TUYỆT ĐỐI KHÔNG tự phát sóng sin ù ù! Chỉ phát nếu có file nhạc .ogg thật
		if ResourceLoader.exists("res://assets/audio/bgm_arena.ogg"):
			bgm_player.stream = load("res://assets/audio/bgm_arena.ogg")
			bgm_player.play()

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
				tree.root.call_deferred("add_child", _instance)
	elif not _instance.is_inside_tree() and not _is_adding:
		if tree == null:
			tree = Engine.get_main_loop() as SceneTree
		if tree and tree.root and _instance.get_parent() == null:
			_is_adding = true
			tree.root.call_deferred("add_child", _instance)

	if not _is_prebaked and _instance:
		_instance._prebake_audio_bank()
	return _instance

static func play_sfx(sfx_id: String, volume_offset_db: float = 0.0, pitch_override: float = 0.0) -> void:
	var inst := ensure_initialized()
	if inst:
		inst._play_internal(sfx_id, volume_offset_db, pitch_override)

static func start_bgm() -> void:
	var inst := ensure_initialized()
	if inst and inst.bgm_player and inst.bgm_player.stream != null:
		if not inst.bgm_player.playing:
			inst.bgm_player.play()

static func set_rage_bgm_mode(is_rage: bool) -> void:
	var inst := ensure_initialized()
	if inst and inst.bgm_player:
		inst.bgm_player.pitch_scale = 1.08 if is_rage else 1.00
		inst.bgm_player.volume_db = -11.0 if is_rage else -14.0

func _prebake_audio_bank() -> void:
	if _is_prebaked:
		return
	_is_prebaked = true

	# 1. Nạp toàn bộ các file thu âm thật (.ogg / .wav) từ ổ cứng vào RAM
	for sample_key in SAMPLE_PATHS:
		var candidate_list: Array = SAMPLE_PATHS[sample_key]
		for path in candidate_list:
			if ResourceLoader.exists(path):
				var stream := ResourceLoader.load(path) as AudioStream
				if stream != null:
					_raw_streams[sample_key] = stream
					break

	# Fallback an toàn nếu thiếu bất kỳ key phụ nào: trỏ về file thu âm thật gần nhất
	var default_real_stream: AudioStream = _raw_streams.get("slice_1", null)
	if default_real_stream == null and ResourceLoader.exists("res://assets/audio/click.wav"):
		default_real_stream = ResourceLoader.load("res://assets/audio/click.wav") as AudioStream

	for sample_key in SAMPLE_PATHS:
		if not _raw_streams.has(sample_key) and default_real_stream != null:
			_raw_streams[sample_key] = default_real_stream

	# 2. Ánh xạ 23 sự kiện vào _sfx_bank bằng các AudioStream thật
	for recipe_id in FOLEY_RECIPES:
		var layers: Array = FOLEY_RECIPES[recipe_id]
		if layers.size() > 0:
			var primary_sample: String = layers[0]["sample"]
			_sfx_bank[recipe_id] = _raw_streams.get(primary_sample, default_real_stream)

	_sfx_bank["bgm_arena_combat_loop"] = default_real_stream

func _play_internal(sfx_id: String, volume_offset_db: float, pitch_override: float) -> void:
	if not FOLEY_RECIPES.has(sfx_id) and not _sfx_bank.has(sfx_id):
		return

	var now := float(Time.get_ticks_msec()) / 1000.0
	if _last_play_time.has(sfx_id):
		if now - float(_last_play_time[sfx_id]) < MIN_RETRIGGER_DELAY:
			return
	_last_play_time[sfx_id] = now

	_init_audio_pool()
	if players.size() == 0:
		return

	play_count += 1
	play_counts[sfx_id] = int(play_counts.get(sfx_id, 0)) + 1

	# Luân phiên 5 mẫu bước chân thật trên đá để nghe tự nhiên 100%
	if sfx_id == "footstep_stone":
		var step_key := "step_%d" % (_footstep_cycle_idx % 5)
		_footstep_cycle_idx += 1
		var step_stream: AudioStream = _raw_streams.get(step_key, null)
		if step_stream:
			_trigger_single_layer(step_stream, -12.5 + volume_offset_db, randf_range(0.94, 1.06))
		return

	# Luân phiên 4 mẫu va chạm thịt/giáp thật khi chém trúng Bot
	if sfx_id == "hit_enemy_flesh_metal":
		var punch_key := "punch_heavy_%d" % (_hit_cycle_idx % 4)
		var metal_key := "metal_med_%d" % (_hit_cycle_idx % 2)
		_hit_cycle_idx += 1
		var p_stream: AudioStream = _raw_streams.get(punch_key, null)
		var m_stream: AudioStream = _raw_streams.get(metal_key, null)
		if p_stream:
			_trigger_single_layer(p_stream, -2.5 + volume_offset_db, randf_range(0.94, 1.05))
		if m_stream:
			_trigger_single_layer(m_stream, -6.0 + volume_offset_db, randf_range(0.92, 1.04))
		return

	# Phát tổ hợp Đa Lớp Foley Thật (Multi-Layer Composite Foley)
	if FOLEY_RECIPES.has(sfx_id):
		var layers: Array = FOLEY_RECIPES[sfx_id]
		var jitter := randf_range(0.96, 1.04)
		for layer in layers:
			var sample_name: String = layer.get("sample", "slice_1")
			var stream: AudioStream = _raw_streams.get(sample_name, null)
			if stream == null:
				continue
			var layer_vol: float = float(layer.get("vol_db", 0.0)) + volume_offset_db
			var base_pitch: float = float(layer.get("pitch", 1.0))
			var final_pitch: float = pitch_override if pitch_override > 0.0 else (base_pitch * jitter)
			var delay_sec: float = float(layer.get("delay", 0.0))

			if delay_sec <= 0.001 or not is_inside_tree():
				_trigger_single_layer(stream, layer_vol, final_pitch)
			else:
				var tw := create_tween()
				tw.tween_interval(delay_sec)
				tw.tween_callback(_trigger_single_layer.bind(stream, layer_vol, final_pitch))

func _trigger_single_layer(stream: AudioStream, vol_db: float, pitch_val: float) -> void:
	if stream == null or players.size() == 0:
		return
	var player := players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % max_players
	player.stream = stream
	player.volume_db = clampf(vol_db, -40.0, 4.0)
	player.pitch_scale = clampf(pitch_val, 0.45, 2.0)
	player.play()
```

---

## 🧹 TASK 28.3: DỌN SẠCH SÓNG ÂM GIẢ TRONG `src_game/scripts/core/synth_audio.gd`

Trong `src_game/scripts/core/synth_audio.gd`:
* Xóa bỏ hoàn toàn các hàm `_generate_tone`, `_generate_noise_whoosh`, `_generate_explosion_boom`, `_generate_chime` (đang tự sinh sóng `sin` và `saw` ở `22,050 Hz`).
* Chuyển toàn bộ các hàm `play_slash()`, `play_cast()`, `play_dash()`, `play_explosion()`, `play_lightning()`, `play_crystal_pickup()`, `play_health_pickup()` sang nạp trực tiếp các file `.wav`/`.ogg` thật từ `res://assets/audio/` hoặc gọi qua `KayKitAudioDirector.play_sfx(...)`.

---

## 🧪 TASK 28.4: KIỂM THỬ TỰ ĐỘNG XÁC NHẬN 0% SÓNG ÂM GIẢ (`test_phase_28_real_foley_audio_overhaul.gd`) & ĐỒNG BỘ GITHUB (`AGENT-06`)

1. Viết và chạy kịch bản kiểm thử tự động `src_game/tests/test_phase_28_real_foley_audio_overhaul.gd` xác nhận **PASS 100%** 4 bài kiểm tra:
   * **Test 28.1 (Kiểm định Kho File Thu Âm Thật `.ogg` / `.wav`):** Xác nhận các file thu âm thật trong `res://assets/audio/rpg/` (`knifeSlice`, `chop`, `drawKnife1..3`, `cloth1..4`, `footstep00..04`) và `res://assets/audio/impact/` (`impactMetal_heavy_000`, `impactMining_000`, `impactPunch_heavy_000`, `impactSoft_heavy_000`, `impactBell_heavy_000`) đều tồn tại và nạp thành công (`!= null`).
   * **Test 28.2 (Kiểm định 0% Sóng Sin Giả & Tắt Nhạc Nền Ù Ù):**
     * Quét mã nguồn `kaykit_audio_director.gd` xác nhận **không còn bất kỳ hàm `_synth_*` hay `encode_s16` nào**.
     * Xác nhận `bgm_player.playing == false` khi chưa gắn file nhạc thật (triệt tiêu 100% tiếng ù ù nền).
     * Xác nhận Bus `"CombatSFX"` đã được gắn `AudioEffectLowPassFilter` (`cutoff_hz == 6800.0`) và `AudioEffectCompressor`.
   * **Test 28.3 (Kiểm định Hòa Âm Đa Lớp Foley Thật Cho Toàn Bộ Kỹ Năng):** Kích hoạt `U1`, `U2`, `U3` (Thường & Nộ), `I` (Pha 1 & Pha 2), `O`, `P`, `R`, `Space`, `Footstep`, `Hit` $\rightarrow$ Xác nhận mỗi chiêu phát tổ hợp các mẫu thu âm thực tế mượt mà với `0ms` lag.
   * **Test 28.4 (Bảo Toàn 100% Phase 24–27):** Chạy lại `test_phase_27_rage_aura_6layers_and_audio_system.gd` xác nhận vẫn PASS 100% (`PrimitiveMesh == 0`).
2. Xuất lại `docs/CURRENT_CODE_SNAPSHOT.md`, cập nhật `docs/TASK_PROGRESS.md`, `git commit -m "fix(phase28): purge procedural synth beeps/noise and integrate multi-layer real Kenney RPG & Impact foley audio"` và `git push` lên `https://github.com/NhutPham19/GameWizad`.