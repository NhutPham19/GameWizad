# 👑 CHỈ ĐẠO SỐ 27 TỪ ARGONS: ĐẠI TU HÀO QUANG HÓA NỘ [R] 6 LỚP RỰC RỠ & TÍCH HỢP HỆ THỐNG ÂM THANH ĐA TẦNG TOÀN DIỆN (HYBRID KENNEY WAV + STUDIO SYNTH 44.1KHZ)

- **Người chỉ đạo (Chief Architect):** ARGONS
- **Đơn vị thực thi:** ANTIGRAVITY IDE (`Claude Opus 4.6` / `Gemini 3.8 Flash`)
- **Kho GitHub dự án:** `https://github.com/NhutPham19/GameWizad`
- **Trạng thái nền tảng:** Phase 26 (Golden Master + Rage State 2) đang hoạt động ổn định 100%.
- **3 LUẬT THÉP BẤT DI BẤT DỊCH:**
  1. **0% KHỐI HÌNH HỌC THÔ (`PrimitiveMesh == 0`):** Tuyệt đối cấm sử dụng `BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PlaneMesh`, `QuadMesh`, `TorusMesh`, `PrismMesh`. Mọi hình khối hào quang 3D mới bắt buộc 100% dùng `build_curved_slash_arc_mesh(..., 36)` và `get_safe_particle_quad_mesh()` kết hợp Kenney Textures (`star_07.png`, `spark_06.png`, `flame_04.png`, `light_01.png`, `circle_01..05.png`).
  2. **0ms AUDIO LAG Ở 165Hz+:** Toàn bộ file âm thanh `.wav` có sẵn trong thư viện và các mẫu âm thanh đa tầng (`AudioStreamWAV` 44,100Hz) **BẮT BUỘC** được nạp và nướng sẵn (Pre-bake) 1 lần duy nhất vào bộ nhớ RAM khi khởi động (`_ready()`), phát qua hệ thống **Audio Pool 24 kênh đa luồng** (`0.00ms` cấp phát trong lúc chiến đấu).
  3. **BẢO TOÀN 100% VẬT LÝ & CẦU THANG PHASE 24–26:** Không chạm vào va chạm cầu thang, tường đá hay bộ khung di chuyển.

---

## 🔥 TASK 27.1: ĐẠI TU HÀO QUANG TRẠNG THÁI NỘ [R] (`RageState2AuraHolder`) TỪ VÒNG TRÒN ĐƠN GIẢN LÊN "LINH GIÁP CỰC QUANG HUYẾT LAM 6 LỚP"

Trong `src_game/scripts/vfx/kaykit_vfx_manager.gd` và `src_game/scripts/characters/hero_knight_3d.gd`, thay thế hoàn toàn hàm `attach_rage_state_continuous_aura(hero: Node3D)` hiện tại bằng kiến trúc **Hào Quang 6 Lớp Đa Sắc Đỏ Huyết - Vàng Kim - Xanh Dương Điện Quang** cực kỳ nổi bật suốt 10 giây:

### 1. Lớp 1 — Đôi Cánh Kiếm Khí Huyết Lam Phía Sau Vai (`Dual Crimson-Cobalt Battle Wings`):
- Gắn 1 node `WingsPivot` tại độ cao lưng nhân vật (`Vector3(0.0, 1.15, -0.25)`).
- Sinh **4 dải lụa kiếm khí cong mượt (`build_curved_slash_arc_mesh(0.95, 0.42, 85.0, 36)`)** mở rộng sang hai bên vai trái/phải như đôi cánh chiến thần:
  - **Cặp cánh trên (Trái & Phải):** Phối màu **Đỏ Huyết Hoàng Kim** (`core = Trắng`, `mid = #FF0824` Đỏ Huyết, `edge = #FFB700` Vàng Lửa, `accent = #FF0055`, `emission_strength = 6.2`, `slash_progress = 0.05`).
  - **Cặp cánh dưới (Trái & Phải):** Phối màu **Xanh Dương Tinh Hà** (`core = Trắng`, `mid = #0066FF` Xanh Dương, `edge = #00F0FF` Lam Băng, `accent = #7700FF` Tím Lôi, `emission_strength = 6.0`, `slash_progress = 0.05`).
- Trong `_process(delta)` của Hào quang: Cho đôi cánh nhịp nhàng vẫy nhẹ theo hàm `sin(t * 7.5) * 0.18` rad để nhìn sống động như sinh vật sống.

### 2. Lớp 2 — Tam Vòng Tinh Hoàn 3D Xoay Chéo Quanh Thân (`Triple Gyroscopic Celestial Rings`):
- Thay vì chỉ có vòng phẳng dưới đất, tạo **3 Vòng Lụa Kiếm Khí 3D (`build_curved_slash_arc_mesh(1.15, 0.28, 310.0, 36)`)** bao quanh cơ thể nhân vật ở độ cao `Y = 0.85m`:
  - **Tinh Hoàn 1 (Nghiêng trục X $+32^\circ$, trục Z $-18^\circ$):** Sắc **Đỏ Huyết Rực `#FF0A24` $\rightarrow$ Cam Vàng `#FF8800`**, tự xoay tốc độ `+4.8 rad/s`.
  - **Tinh Hoàn 2 (Nghiêng trục X $-32^\circ$, trục Z $+18^\circ$):** Sắc **Xanh Dương Điện Quang `#0055FF` $\rightarrow$ Xanh Ngọc `#00FFEE`**, tự xoay ngược chiều `-5.2 rad/s`.
  - **Tinh Hoàn 3 (Nằm ngang ở độ cao `Y = 0.22m`, bán kính lớn `1.55m`):** Sắc **Giao Thoa Đỏ - Lam - Tím Hồng** có đuôi sao lấp lánh (`Sparkle Dissolve`), xoay tốc độ `+6.5 rad/s`.

### 3. Lớp 3 — Đại Trận Pháp Liên Hoa 3 Tầng Dưới Chân (`Tri-Layer Pulsing Ground Sanctum`):
- Nâng cấp mặt đất dưới chân từ vòng tròn đơn điệu thành **3 tầng `Decal` nghệ thuật Kenney xoay ngược chiều và co giãn nhịp nhàng (`Pulse Scale`)**:
  - **Tầng 1 (Ngoài cùng - `circle_04.png`, kích thước `3.6m x 3.6m`):** Màu **Xanh Dương Lam Lôi (`Color(0.05, 0.55, 1.0, 0.9)`)**, `emission_energy = 4.2`, xoay `-1.8 rad/s`.
  - **Tầng 2 (Chính giữa - `circle_02.png`, kích thước `2.7m x 2.7m`):** Màu **Đỏ Huyết Hoàng Kim (`Color(1.0, 0.12, 0.22, 0.95)`)**, `emission_energy = 4.8`, xoay `+2.6 rad/s`.
  - **Tầng 3 (Tâm điểm dưới gót chân - `star_07.png` kết hợp `magic_02.png`, kích thước `1.9m x 1.9m`):** Màu **Trắng Vàng Rực Sáng (`Color(1.0, 0.85, 0.3, 0.95)`)**, `emission_energy = 5.2`, nhịp đập phóng to thu nhỏ `1.0 + 0.14 * sin(t * 9.0)`.

### 4. Lớp 4 — Bão Lửa Đỏ & Hồ Quang Điện Xanh Dương Bốc Quanh Người (`Dual Elemental GPUParticles3D`):
- Gắn **2 hệ thống hạt `GPUParticles3D`** (dùng `get_safe_particle_quad_mesh()` 100% `ArrayMesh`):
  - **Hệ hạt 1 (`RageCrimsonFlameAura`, 28 hạt):** Dùng texture `flame_04.png`, phát ra từ vòng tròn bán kính `0.85m` quanh chân, bay xoáy lên cao `2.2m` với `ColorRamp` chuyển từ **Vàng Trắng $\rightarrow$ Đỏ Huyết `#FF0824` $\rightarrow$ Hồng Tím**.
  - **Hệ hạt 2 (`RageCobaltLightningSparks`, 24 hạt):** Dùng texture `spark_06.png`, phát nổ lách tách quanh ngực, vai và thanh kiếm của nhân vật với màu **Trắng $\rightarrow$ Xanh Dương Điện `#0088FF` $\rightarrow$ Xanh Băng `#00FFFF`**.

### 5. Lớp 5 — Cường Hóa Sắc Độ Giáp & Vũ Khí Trên Tay (`Hero & Weapon Rim Overdrive`) + Đèn Chiếu Sáng Đôi:
- Khi bật Nộ (`_activate_rage_state_2()`), gắn 1 đèn `OmniLight3D` (`shadow_enabled = false`, `omni_range = 5.5m`, `light_energy = 3.2`) trên người nhân vật có màu sắc chuyển động mượt mà giữa **Đỏ Huyết** và **Xanh Dương** (`lerp(Color(1.0, 0.15, 0.25), Color(0.1, 0.55, 1.0), sin(t * 6.0) * 0.5 + 0.5)`).
- Trên thanh vũ khí của nhân vật, gắn 1 chùm tia sáng `star_08.png` + vệt lụa nhỏ phát sáng Đỏ-Xanh ngay tại lưỡi kiếm.

### 6. Lớp 6 — Tàn Ảnh Huyết Lam Tự Động Khi Chạy (`Rage Sprint Afterimage Trail`):
- Trong `hero_knight_3d.gd`: Khi `_is_rage_state_2 == true` và nhân vật đang di chuyển (`velocity.length() > 2.5`), cứ mỗi **`0.16 giây`** tự động gọi `KayKitVFXManager.spawn_prismatic_hero_afterimage()` luân phiên 2 màu **Đỏ Huyết (`#FF0A24`)** và **Xanh Dương (`#0066FF`)** tồn tại `0.25s`. Nhờ đó, chỉ cần chạy trên sân trong lúc Nộ cũng kéo theo một dải bóng mờ Đỏ - Xanh cực kỳ mãn nhãn!

---

## 🔊 TASK 27.2 (TRỌNG TÂM SỐ 2): XÂY DỰNG HỆ THỐNG ÂM THANH TOÀN DIỆN `KayKitAudioDirector` (KẾT HỢP KHO `.WAV` CÓ SẴN + BỘ TỔNG HỢP SÓNG ÂM ĐA TẦNG PRE-BAKED 44.1KHZ)

Tạo mới file **`src_game/scripts/audio/kaykit_audio_director.gd`** (`class_name KayKitAudioDirector`) để quản lý 100% âm thanh của nhân vật, hiệu ứng chiêu thức, quái vật, giao diện và nhạc nền chiến đấu:

### 1. Khai thác 100% Kho File `.wav` Có Sẵn Trong Thư Viện + Tổng Hợp Đa Tầng Chuẩn Studio (`44,100 Hz`, 16-bit PCM):
- Khi `KayKitAudioDirector.ensure_initialized(tree)` được gọi trong `_ready()` của `HeroKnight3D` và `ShaderPrewarmer`:
  1. **Quét và nạp các file `.wav` có sẵn trong thư viện dự án:**
     - Tự động kiểm tra và `ResourceLoader.load()` các file âm thanh thực tế có sẵn trong `res://assets/audio/` (như `slash.wav`, `impact.wav`, `dash.wav`, `explosion.wav`, `lightning.wav`, `pickup.wav`, cùng các file từ gói Kenney Audio trong dự án).
  2. **Bộ Tổng Hợp Âm Thanh Đa Tầng Phong Phú (`Studio Multi-Layered Procedural Synth` - Pre-baked 100% vào `_sfx_bank`):**
     - Để mỗi chiêu thức có âm thanh **độc bản, dày, uy lực và sống động nhất** (thay vì tiếng bíp đơn âm), viết bộ tạo mẫu sóng `44,100 Hz` kết hợp **Sub-Bass Sine Sweep (Lực trầm đập ngực) + Filtered Pink/White Noise (Tiếng gió xé không gian / tiếng nổ) + FM Metallic Bell/Chord Harmonics (Tiếng ngân thanh kiếm thánh & tia sét)** cho **18 sự kiện âm thanh riêng biệt**:
       - **`"u1_slash"`:** Tiếng vung kiếm sắc gọn + tiếng gió cắt ngang cao độ chuẩn (`pitch = 1.0`).
       - **`"u2_slash"`:** Tiếng song kiếm chém chéo giao thoa (`dual-swipe` 2 nhịp cách nhau `35ms`, `pitch = 1.12`).
       - **`"u3_heaven_shatter"`:** Tiếng đại kiếm bổ gió từ trên cao (`0.0s -> 0.08s`) $\rightarrow$ Tiếng nổ địa chấn Sub-Bass `55Hz` nện xuống đất + tiếng đá vỡ & chuông ngân Hoàng Kim (`0.42s`).
       - **`"u1_rage"`, `"u2_rage"`:** Tiếng vung kiếm ở **Trạng Thái 2 (Nộ)** — dày hơn, có thêm lớp trầm `80Hz` + tiếng tia điện xanh phóng qua lưỡi kiếm (`electric crackle overlay`).
       - **`"u3_rage_dragon_fall"`:** Tiếng **Ngũ Đại Kiếm Khí Nộ** — Hợp âm sấm sét rền vang + tiếng nổ địa chấn kép kéo dài `0.65s` tương ứng với thời gian 5 lưỡi kiếm đọng lại trên mặt đất!
       - **`"i_phase1_x_cleave"`:** Tiếng lướt xé gió thần tốc + 2 nhát chém chữ X kim loại ngân vang sắc lẹm.
       - **`"i_phase2_wave_launch"`:** Tiếng phóng sóng kiếm khí năng lượng càn quét mặt đất + tiếng nổ Tinh Vân ở cuối đường bay (`"i_wave_finale"`).
       - **`"i_rage_hexa_cleave"` & `"i_rage_five_wing_wave"`:** Phiên bản Cường Hóa Nộ của chiêu `[I]` với âm trầm uy lực gấp đôi và tiếng gầm năng lượng Huyết Lam.
       - **`"o_whirlwind_spin"`:** Tiếng lốc xoáy kiếm khí quay liên hoàn $360^\circ$ (`whoosh-whoosh-whoosh` 4 nhịp xoáy gió hút chân không).
       - **`"p_bomb_throw"` & `"p_bomb_thunder_explode"` & `"p_bomb_dot_zap"`:** Tiếng ném bom vút qua không trung $\rightarrow$ Tiếng nổ bom khói trầm đục kèm tia sét giật đanh gọn $\rightarrow$ Tiếng điện giật lách tách mỗi `0.5s` khi đốt máu Bot.
       - **`"rage_r_awaken"` (Âm thanh Kích Hoạt Nộ `[R]`):** Tiếng **Long Thần Thức Tỉnh** cực kỳ hoành tráng (Tiếng tụ khí trầm $\rightarrow$ Tiếng nổ xung kích sấm sét Đỏ-Xanh $\rightarrow$ Hợp âm hào quang ngân vang uy nghiêm).
       - **`"rage_r_expire"`:** Tiếng thu hồi năng lượng nhẹ nhàng khi hết 10 giây Nộ.
       - **`"dash_space"` & `"jump_c"` & `"footstep_stone"`:** Tiếng lướt gió êm ái khi bấm `Space`, tiếng bật nhảy khi bấm `C`, và tiếng bước chân giẫm trên nền gạch đá nhịp nhàng khi chạy `WASD` (mỗi `0.28s`/bước, tự đổi cao độ ngẫu nhiên `pitch_scale = randf_range(0.92, 1.08)` để nghe tự nhiên 100%).
       - **`"hit_enemy_flesh_metal"` & `"enemy_death_burst"`:** Tiếng chém trúng mục tiêu cực kỳ "đầm tay" (Hit-confirm punchy impact) và tiếng Bot bị tiêu diệt.
       - **`"bgm_arena_combat_loop"`:** Một bản nhạc nền nhịp trống chiến trận pha giai điệu cổ ngữ trầm hùng (Ambient Battle Pulse Loop, âm lượng vừa phải `-14 dB` để làm nổi bật tiếng chiêu thức), tự động tăng nhịp độ (`pitch_scale = 1.08`, `-11 dB`) trong suốt 10 giây người chơi bật Nộ `[R]`!

### 2. Cơ chế Audio Pool 24 Kênh Chống Nghẽn & Chống Chói Tai (`Polyphonic Voice Limiter`):
- Tạo sẵn **24 node `AudioStreamPlayer`** gắn vào SceneTree root (hoặc `KayKitAudioDirector` singleton node) ngay lúc khởi động.
- Bổ sung cơ chế **Chống chồng âm (`Cooldown Per Sound ID = 0.035s`)** và **Biến thiên cao độ tự nhiên (`pitch_scale = randf_range(0.95, 1.06)`)** để khi chém trúng 5 con Bot cùng lúc, âm thanh nghe dày và đầm chứ không bị rè hay chói tai.

---

## 🔗 TASK 27.3: KẾT NỐI ÂM THANH VÀO TOÀN BỘ CHIÊU THỨC, NHÂN VẬT & BOT (`hero_knight_3d.gd`, `kaykit_vfx_manager.gd`, `enemy_minion_3d.gd`)

1. **Trong `src_game/scripts/characters/hero_knight_3d.gd`:**
   - Trong `_ready()`: Gọi `KayKitAudioDirector.ensure_initialized(get_tree())` và bắt đầu phát nhạc nền đấu trường.
   - Trong `_physics_process(delta)`:
     - Khi nhân vật đang chạy trên mặt sàn (`is_on_floor()` và `horiz_speed > 2.2` và không đang Dash): Đếm nhịp `_footstep_timer` mỗi `0.26s` (hoặc `0.22s` khi đang bật Nộ `[R]`) phát tiếng bước chân `"footstep_stone"`.
     - Khi đang ở Trạng Thái 2 (`_is_rage_state_2 == true`): Tự động sinh tàn ảnh Đỏ - Xanh mỗi `0.16s` khi di chuyển.
   - Khi bấm **`[R]` Kích Hoạt Nộ**: Phát ngay âm thanh `"rage_r_awaken"` đầy uy lực! Khi hết 10 giây Nộ: Phát `"rage_r_expire"`.
   - Khi bấm **`[U]` Liên Trảm**:
     - Nhịp 1: Phát `"u1_rage"` (nếu đang Nộ) hoặc `"u1_slash"` (nếu trạng thái 1).
     - Nhịp 2: Phát `"u2_rage"` (nếu đang Nộ) hoặc `"u2_slash"`.
     - Nhịp 3 (U3): Phát `"u3_rage_dragon_fall"` (nếu đang Nộ) hoặc `"u3_heaven_shatter"`.
   - Khi bấm **`[I]` Phá Không Trảm**:
     - Pha 1 (Chém chữ X): Phát `"i_rage_hexa_cleave"` (nếu đang Nộ) hoặc `"i_phase1_x_cleave"`.
     - Pha 2 (Phóng sóng kiếm): Phát `"i_rage_five_wing_wave"` (nếu đang Nộ) hoặc `"i_phase2_wave_launch"`. Khi sóng kiếm nổ ở cuối hành trình: Phát `"i_wave_finale"`.
   - Khi bấm **`[O]` Xoay 360°**: Phát `"o_whirlwind_spin"`.
   - Khi bấm **`[P]` Bom Lôi Vụ**: Phát `"p_bomb_throw"` lúc ném, `"p_bomb_thunder_explode"` lúc bom chạm đất phát nổ, và `"p_bomb_dot_zap"` ở mỗi nhịp đốt sét DoT.
   - Khi bấm **`[Space]` Lướt**: Phát `"dash_space"`. Khi bấm **`[C]` Nhảy**: Phát `"jump_c"`.
2. **Trong `src_game/scripts/enemies/enemy_minion_3d.gd`:**
   - Trong `take_damage()`: Phát âm thanh trúng đòn `"hit_enemy_flesh_metal"` (và khi máu về 0 thì phát `"enemy_death_burst"`).

---

## 🧪 TASK 27.4: KIỂM THỬ TỰ ĐỘNG 100% PASS, CHỤP ẢNH HÀO QUANG NỘ 6 LỚP & ĐỒNG BỘ GITHUB (`AGENT-06`)

1. Viết và chạy kịch bản kiểm thử tự động `src_game/tests/test_phase_27_rage_aura_6layers_and_audio_system.gd` kiểm chứng 5 hạng mục:
   - **Test 27.1 (Hào Quang Nộ 6 Lớp Đặc Sắc):** Kích hoạt `[R]`, xác nhận `RageState2AuraHolder` chứa đầy đủ: (1) Đôi cánh kiếm khí `WingsPivot` (4 cánh lụa Đỏ-Xanh), (2) 3 Vòng Tinh Hoàn xoay chéo `GyroRings` (`ArrayMesh` 36 phân đoạn), (3) 3 tầng `Decal` Liên Hoa dưới chân, (4) 2 hệ hạt `GPUParticles3D` (Lửa Đỏ & Sét Xanh), (5) Đèn `OmniLight3D` đổi màu Đỏ-Xanh, và (6) Tàn ảnh `.glb` Đỏ-Xanh tự sinh khi chạy.
   - **Test 27.2 (Hệ Thống Âm Thanh Toàn Diện 18+ SFX & Audio Pool):** Xác nhận `KayKitAudioDirector` đã khởi tạo sẵn tối thiểu **18 mẫu âm thanh (`_sfx_bank.size() >= 18`)** và **24 kênh `AudioStreamPlayer`**. Kích hoạt thử toàn bộ kỹ năng (`R`, `U1`, `U2`, `U3`, `I`, `O`, `P`, `Space`, `C`, `Hit`) xác nhận các bộ phát âm thanh chuyển sang trạng thái đang phát (`playing == true` hoặc `play_count > 0`) với `0ms` frame spike!
   - **Test 27.3 (Luật Thép 0% Khối Thô `PrimitiveMesh == 0`):** Quét toàn bộ SceneTree khi đang bật Hào quang Nộ 6 lớp và tung chiêu U3/I $\rightarrow$ Xác nhận `primitive_count == 0` (100% `ArrayMesh`).
   - **Test 27.4 (Bảo Toàn Sát Thương & Vật Lý Phase 24–26):** Chạy lại kiểm tra sát thương Nộ (U3 = `52.0 DMG`, I = `80.0 DMG`), phím `[F1]` Chơi lại, Cooldown `[Space]` 1.0s và cầu thang Phase 24 đạt PASS 100%.
2. Chạy Render thực tế trên GPU RTX 4060, chụp 2 bức ảnh màn hình cận cảnh **Hào Quang Nộ 6 Lớp (Đôi cánh Đỏ-Xanh + 3 Tinh Hoàn xoay chéo + Trận pháp 3 tầng)** và lưu vào `docs/QA_REPORTS/screenshots/phase27_1_ultimate_rage_aura_6layers.png` và `phase27_2_rage_combat_with_audio_telemetry.png`.
3. Cập nhật `docs/TASK_PROGRESS.md`, `docs/BAO_CAO_TIEN_DO_DU_AN_GAMEWIZAD.md`, commit và `git push` lên `https://github.com/NhutPham19/GameWizad`.