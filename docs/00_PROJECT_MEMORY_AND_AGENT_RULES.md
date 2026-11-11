# 🧠 SỔ TAY BỘ NHỚ DỰ ÁN & BỘ LUẬT THÉP TỐI CAO DÀNH CHO AI AGENTS (`GameWizad`)

- **Tên dự án:** `GameWizad` (3D Isometric Action Roguelike / Arena Combat — Chuẩn *KayKit 3D* & *Wizard of Legend 2*)
- **Kiến trúc trưởng (Chief Architect):** **ARGONS**
- **Đơn vị thực thi (Execution Engine):** **ANTIGRAVITY IDE** (`Gemini 3.8 Flash` & `Claude Opus 4.6`)
- **Kho GitHub Chính Thức (Single Source of Truth):** `https://github.com/NhutPham19/GameWizad`
- **Thư mục gốc trên máy Local:** `E:\DoAnCaNhan\ThuVienGame\GameWizad`
- **Đường dẫn Godot Engine 4.3+ (Forward+ GPU RTX 4060):** `D:\GameEngines\Godot`
- **File chạy nhanh cho User kiểm tra thực tế:** `E:\DoAnCaNhan\ThuVienGame\GameWizad\PLAY_GAME_WIZAD.bat`

---

## 🚨 PHẦN I: 8 LUẬT THÉP BẮT BUỘC (IRONCLAD RULES CHO MỌI AGENTS)

> ⚠️ **MỌI AI AGENT TRONG ANTIGRAVITY KHI ĐỌC FILE NÀY BẮT BUỘC PHẢI TUÂN THỦ 8 LUẬT SAU TRƯỚC KHI SỬA BẤT KỲ DÒNG CODE NÀO:**

### 1. LUẬT SỐ 1 — CHỐT CHẶN HỎI THƯ MỤC TẢI VỀ (`[STOP-AND-ASK GATE]`):
- Tuyệt đối **KHÔNG tự ý tải ngầm** bất kỳ Engine, công cụ, repo hay gói 3D Asset mới nào từ Internet về ổ đĩa khi chưa dừng lại hỏi User muốn lưu vào đường dẫn nào.
- Hiện tại dự án đã có đầy đủ tài nguyên chuẩn của **KayKit 3D** và **Kenney Particle Pack** bên trong `src_game/assets/` và `assets_staging/`. Hãy ưu tiên sử dụng 100% tài nguyên sẵn có trong repo!

### 2. LUẬT SỐ 2 — CẤM TUYỆT ĐỐI HÌNH KHỐI THÔ (`ZERO PRIMITIVE MESHES POLICY`):
- **NGHIÊM CẤM 100%** việc khởi tạo hoặc sử dụng các khối hình học cơ bản của Godot (`BoxMesh`, `SphereMesh`, `CylinderMesh`, `CapsuleMesh`, `PrismMesh`, `TorusMesh`) để làm nhân vật, vũ khí, thanh máu, hiệu ứng chiêu thức (VFX) hay cảnh quan bản đồ!
- `StrictQAHUD` đang quét Scene Tree mỗi $0.5\text{s}$: Nếu phát hiện bất kỳ `PrimitiveMesh` nào (`primitive_count > 0`), hệ thống QA sẽ tự động xóa node vi phạm và đánh trượt (`FAIL`) bản build ngay lập tức!
- **Giải pháp thay thế bắt buộc:**
  - **Mô hình & Đạo cụ:** Chỉ dùng file `.glb` / `.gltf` thật của KayKit trong `src_game/assets/`.
  - **Hiệu ứng kỹ xảo (VFX):** Chỉ dùng `GPUParticles3D` hoặc `Decal` / `Sprite3D` nạp ảnh `.png` trong suốt từ `src_game/assets/vfx_textures/` (`slash_*.png`, `spark_*.png`, `flame_*.png`, `circle_*.png`, `smoke_*.png`).
  - **Thanh máu trên đầu Bot:** Chỉ dùng `Sprite3D` hiển thị `GradientTexture2D` kèm `Label3D` (hoặc 1 thanh máu duy nhất, tuyệt đối không tạo 2 thanh máu chồng nhau và không dùng `BoxMesh`).

### 3. LUẬT SỐ 3 — CHUẨN HOẠT ẢNH XƯƠNG `Skeleton3D` (`ZERO T-POSE & ZERO FOOT SLIDING`):
- Nhân vật (`Knight.glb`) và Bot (`Barbarian.glb`) đều có bộ xương `Skeleton3D` (40–50 khớp) và `AnimationPlayer` tích hợp sẵn 75 hoạt ảnh chuẩn KayKit.
- **Mọi việc phát hoạt ảnh, giải giáp vũ khí thừa và gắn vũ khí chuẩn** BẮT BUỘC phải thông qua lớp `KayKitAnimationBinder` (`src_game/scripts/core/kaykit_animation_binder.gd`).
- Không được khóa nhân vật đứng im quá lâu khi vung kiếm (gây cảm giác đơ) và không được cho nhân vật trượt đi khi đang phát hoạt ảnh đứng yên. Phải áp dụng cơ chế **Bước Tấn Công (`Attack Step-Lunge` $0.0\text{s} \rightarrow 0.14\text{s}$) + Trụ Chân Chém ($0.14\text{s} \rightarrow 0.24\text{s}$) + Ngắt Sớm Thu Kiếm (`Early Walk-Cancel` ở $0.24\text{s}$)** để vừa dứt khoát vừa 0% trượt chân!

### 4. LUẬT SỐ 4 — CHUẨN DI CHUYỂN WASD, XOAY MẶT $360^\circ$ & CHỐNG KẸT PHÍM:
- Đọc tín hiệu di chuyển trực tiếp từ phần cứng bàn phím mỗi frame vật lý (`Input.is_physical_key_pressed(KEY_W/A/S/D)` và `KEY_UP/DOWN/LEFT/RIGHT`) để không bao giờ bị kẹt nút di chuyển.
- Phép chiếu hướng di chuyển theo góc Camera Isometric ($45^\circ$):
  - `forward = Vector3(-1.0, 0.0, -1.0).normalized()` (Phím `W` đi thẳng lên trên màn hình).
  - `right = Vector3(1.0, 0.0, -1.0).normalized()` (Phím `D` đi sang phải màn hình).
- Mô hình KayKit có mặt trước nhìn theo trục **`+Z`** của `VisualRoot`: Công thức góc xoay mặt chuẩn là `target_yaw = atan2(dir.x, dir.z)` và nội suy mượt bằng `lerp_angle(visual_root.rotation.y, target_yaw, 18.0 * delta)`.

### 5. LUẬT SỐ 5 — CHUẨN VẬT LÝ BẢN ĐỒ ĐA TẦNG & CẦU THANG (KHÔNG XUYÊN TƯỜNG, KHÔNG RƠI MAP, KHÔNG KẸT GÓC):
- **3 Tầng độ cao chuẩn của Map (`kaykit_multitier_arena.gd`):**
  - **Tầng 1 (Sân Chính):** $Y = 0.05\text{m}$
  - **Tầng 2 (Bệ Trung Tâm):** $Y = 4.05\text{m}$
  - **Tầng 3 (Đài Cao Phía Bắc):** $Y = 8.05\text{m}$
- **Va chạm Tường & Cầu thang:**
  - Mọi cầu thang nối tầng phải có `SmoothStairRampCollider` (mặt dốc phẳng thuộc group `"stairs"`), chừa trống tường chắn ở đầu cầu thang, và có `SideGuardLeft` / `SideGuardRight` chặn hai bên hông cầu thang để không đi xuyên ngang vào gầm cầu thang.
  - Khi bấm `Space` (Lướt / Dash) trên cầu thang: Phải tắt `_apply_stair_step_up()` và giảm tốc độ Dash trên dốc (`DASH_SPEED * 0.72`) để tốc độ lướt lên bậc thang cân bằng với mặt phẳng.
  - **Đạo cụ nhỏ (`torch_lit`, cỏ, hoa):** Tuyệt đối **KHÔNG gắn `StaticBody3D`** để tránh tạo khe hẹp gây kẹt nhân vật ở góc tường (như góc đuốc Tầng 3). Các vật cản lớn (`chest`, `pillar`) phải cách tường tối thiểu $\ge 2.2\text{m}$ hoặc ép sát $0.0\text{m}$ vào tường.

### 6. LUẬT SỐ 6 — CHUẨN VẬT LÝ LƯỚT (`SPACE`) & TRÍ TUỆ NHÂN TẠO CỦA BOT (`EnemyMinion3D`):
- **Lướt (`Space`) đụng Bot là Văng Lại — KHÔNG XUYÊN QUA:** Khi `HeroKnight3D` đang Dash mà đụng trúng `EnemyMinion3D`, nhân vật dừng Dash ngay và **nảy lùi nhẹ lại $0.8\text{m}$ (`_rebound_timer = 0.16s`)**, đồng thời **húc văng con Bot (và các Bot đứng sát cạnh) lùi ra xa $2.0\text{m}$ (`apply_dash_impact_knockback`)** để phá vòng vây trong góc tường mà không đi xuyên qua người Bot!
- **AI Điều Hướng Của Bot Khi Ở Xa / Khác Tầng:**
  - Bot giữ khoảng cách dừng chiến đấu $1.45\text{m}$ (nếu $< 1.10\text{m}$ tự lùi nhẹ) + lực đẩy tách bầy đàn (`Boids Separation` bán kính $1.35\text{m}$).
  - Khi khác tầng ($\Delta Y > 1.15\text{m}$): Bot phải tự tìm đến **Trạm Cầu Thang (`_get_smart_navigation_target`)** dẫn lên/xuống tầng của người chơi.
  - Khi vướng tường/rương/cột đá ở xa: Bot dùng **Cảm biến 7 tia râu (`_compute_obstacle_avoidance_direction`) + Bộ gỡ kẹt (`Unstuck Recovery`)** để đi đường vòng, và **xoay mặt theo đúng hướng bước chân di chuyển thực tế (`horiz_vel`)** chứ không được nhìn chằm chằm vào người chơi rồi ủi đầu vào tường!

### 7. LUẬT SỐ 7 — CHUẨN GIAO DIỆN KHÔNG CHẶN CHUỘT (`MOUSE_FILTER_IGNORE`):
- Mọi node `Control`, `PanelContainer`, `VBoxContainer`, `Label`, `ProgressBar` trên `StrictQAHUD` (ngoại trừ duy nhất nút `RestartButton - Chơi Lại (Phím R)` ở giữa đỉnh màn hình) **BẮT BUỘC đặt `mouse_filter = Control.MOUSE_FILTER_IGNORE`** để không bao giờ chặn thao tác click Chuột Trái (`LMB`) / Chuột Phải (`RMB`) của người chơi.

### 8. LUẬT SỐ 8 — QUY TRÌNH KIỂM THỬ TỰ ĐỘNG & ĐỒNG BỘ GITHUB SAU MỖI TASK:
- Không được báo cáo hoàn thành nếu chưa chạy script kiểm thử tự động trong `src_game/tests/` đạt **100% PASS** trên Godot CLI.
- Sau mỗi đợt sửa lỗi thành công, bắt buộc cập nhật `docs/CURRENT_CODE_SNAPSHOT.md`, chạy `git add .`, `git commit` và `git push` thẳng lên nhánh `main` của `https://github.com/NhutPham19/GameWizad`.

---

## 📂 PHẦN II: BẢN ĐỒ KIẾN TRÚC FILE CHUẨN HIỆN TẠI TRÊN GITHUB

Khi các Agents cần đọc hoặc sửa tính năng nào, chỉ được phép thao tác đúng trên hệ thống file chuẩn đã được làm sạch dưới đây (tuyệt đối không tạo lại các file rác của thế hệ cũ đã xóa ở Phase 14):

```text
E:\DoAnCaNhan\ThuVienGame\GameWizad\
├── PLAY_GAME_WIZAD.bat                                  # File khởi chạy cửa sổ Game 3D (1600x900) trên GPU RTX 4060
├── XUAT_SNAPSHOT_CODE.ps1                               # Script xuất toàn bộ code .gd/.tscn ra docs/CURRENT_CODE_SNAPSHOT.md
├── docs\
│   ├── 00_PROJECT_MEMORY_AND_AGENT_RULES.md             # [FILE NÀY] Sổ tay bộ nhớ & Luật thép cho Agents
│   ├── CURRENT_CODE_SNAPSHOT.md                         # Bản chụp toàn bộ mã nguồn hiện tại
│   └── QA_REPORTS\screenshots\                          # Ảnh chụp màn hình thực tế từ GPU RTX 4060
└── src_game\
    ├── project.godot                                    # Main Scene: res://scenes/world/kaykit_multitier_arena.tscn
    ├── scenes\
    │   └── world\
    │       └── kaykit_multitier_arena.tscn              # Cảnh chính: Đấu trường 3 tầng KayKit + HeroKnight3D + 5 EnemyMinion3D + StrictQAHUD
    ├── scripts\
    │   ├── core\
    │   │   ├── kaykit_animation_binder.gd               # Lõi điều khiển Skeleton3D, 75 hoạt ảnh, dọn vũ khí thừa & gắn BladeTipMarker
    │   │   └── kaykit_vfx_manager.gd                    # Lõi kỹ xảo 0% Primitive Mesh (Hạt bám mũi kiếm, Decal đất, Bom khói 3D, Chữ sát thương)
    │   ├── characters\
    │   │   └── hero_knight_3d.gd                        # Nhân vật chính: Hiệp sĩ KayKit (WASD, LMB Combo 3 nhịp, RMB Khiên, Q Xoay 360, E Bom khói, Space Dash, C Nhảy)
    │   ├── enemies\
    │   │   └── enemy_minion_3d.gd                       # Bot đối kháng: Chiến binh Barbarian cầm rìu (AI tìm cầu thang, 7 tia tránh vật cản, Boids, Hit-stun, 1 Thanh máu)
    │   ├── world\
    │   │   └── kaykit_multitier_arena.gd                # Xây dựng bản đồ 3 tầng (Y=0m, 4m, 8m), cầu thang SmoothStairRamp, tường biên phẳng, đạo cụ KayKit
    │   └── ui\
    │       └── strict_qa_hud.gd                         # HUD Trái (Máu Hero & Chiêu), Nút Giữa (Chơi Lại / Phím R), HUD Phải (Đo FPS, 0 Hình khối, Xương, Tọa độ)
    └── tests\
        ├── test_phase_17_stairs_combat_bounds.gd        # Test leo cầu thang, đánh thường LMB trừ máu, tường biên
        ├── test_phase_18_all_6_fixes.gd                 # Test chống xuyên tường, hông cầu thang, 1 thanh máu Bot, chống kẹt phím, nút Restart, xoay mặt
        └── test_phase_19_corners_dash_and_fluid_combat.gd # Test góc đuốc Tầng 3, tốc độ Dash cầu thang, Dash đụng Bot dội lại, Walk-Cancel 0.24s, AI Bot đi vòng vật cản
```

---

## 🎮 PHẦN III: BẢNG ĐIỀU KHIỂN & CƠ CHẾ CHIẾN ĐẤU CHUẨN CỦA `HeroKnight3D`

| Phím / Chuột | Tên Hành Động | Hoạt Ảnh KayKit (`AnimationPlayer`) | Cơ Chế Vật Lý & Kỹ Xảo (`KayKitVFXManager`) |
| :--- | :--- | :--- | :--- |
| **`W, A, S, D` / Phím Mũi Tên** | Di chuyển 8 hướng | `Running_A` (Khi dừng: `Idle`) | Đọc phím vật lý trực tiếp mỗi frame; tự động leo cầu thang giữa 3 tầng; xoay mặt $360^\circ$ mượt mà theo hướng chạy. |
| **Chuột Trái (`LMB`)** | Đánh Thường (Combo 3 Nhịp) | `1H_Melee_Attack_Slice_Horizontal` $\rightarrow$ `Slice_Diagonal` $\rightarrow$ `Chop` (`speed_scale = 1.45`) | Bước tấn ngắn ($0.14\text{s}$) + Trụ chân chém ($0.10\text{s}$) + **Ngắt sớm thu kiếm ở $0.24\text{s}$ (`Early Walk-Cancel`)** để chạy tiếp ngay. Quét sát thương hình quạt + khoảng cách mũi kiếm `BladeTipMarker`; làm Bot khựng `Hit-Stun` $0.35\text{s}$. |
| **Chuột Phải (`RMB`)** | Khiên Phản Kích (`Shield Bash`) | `1H_Melee_Attack_Stab` / `Block_Attack` (`speed_scale = 1.45`) | Lao ngắn tới trước bằng khiên, gây sát thương, đẩy lùi và làm choáng các Bot phía trước mặt. |
| **Phím `Q`** | Cơn Lốc Kiếm $360^\circ$ (`Whirlwind`) | `2H_Melee_Attack_Spinning` (`speed_scale = 1.55`) | **Vừa xoay kiếm $360^\circ$ vừa di chuyển được theo `WASD` ở $80\%$ tốc độ**, kèm **Giảm $60\%$ sát thương nhận vào (`Hyper-Armor`)**, chém trúng toàn bộ Bot xung quanh. |
| **Phím `E`** | Ném Bom Khói 3D (`Smoke Bomb`) | `Throw` (`speed_scale = 1.75`, chỉ khóa $0.18\text{s}$) | Ném mô hình `smokebomb.gltf` thật bay hình parabol tới vị trí con trỏ chuột; nổ khói bán kính $4.0\text{m}$ gây sát thương và **Làm Chậm $60\%$ + Ngắt đòn đánh của Bot trong $2.5\text{s}$**. |
| **Phím `Space`** | Lướt Chiến Thuật (`Tactical Dash`) | `Dodge_Forward` | **Ngắt tức thì mọi đòn đánh đang vung (`Instant Dash-Cancel`)**, cấp $0.35\text{s}$ Bất Tử (`I-Frames`). Tốc độ cân bằng trên cả mặt phẳng và cầu thang. **Nếu Lướt đụng trúng Bot: Nhân vật nảy lùi lại $0.8\text{m}$, húc văng đám Bot lùi ra xa $2.0\text{m}$ (0% xuyên qua quái).** |
| **Phím `C`** | Nhảy Vượt Địa Hình (`Jump`) | `Jump_Full_Short` | Nhảy vật lý thật (`JUMP_VELOCITY = 9.5`), cho phép nhảy lên các bục đá hoặc né đòn quét đất. |
| **Phím `R` / Nút `CHƠI LẠI`** | Làm Mới Toàn Bộ Màn Chơi | `get_tree().reload_current_scene()` | Đặt lại ngay lập tức máu nhân vật ($100/100$), vị trí xuất phát và toàn bộ 5 con Bot ở 3 tầng để test nhanh bất cứ lúc nào. |

---

## 🔄 PHẦN IV: QUY TRÌNH KHỞI ĐỘNG LẠI TRÍ NHỚ CHO AGENTS (KHI BẮT ĐẦU PHIÊN MỚI)

Bất cứ khi nào một Agent mới được gọi hoặc bắt đầu một cuộc trò chuyện mới trong Antigravity, Agent phải thực hiện đúng **3 bước khởi động (3-Step Boot Sequence)** sau:
1. **Bước 1:** Đọc toàn bộ file `docs/00_PROJECT_MEMORY_AND_AGENT_RULES.md` (file này) để nạp lại 8 Luật Thép và sơ đồ kiến trúc dự án.
2. **Bước 2:** Kiểm tra nhanh trạng thái `git status` và đọc các file liên quan trực tiếp trong `src_game/scripts/` trước khi đưa ra phương án sửa đổi.
3. **Bước 3:** Thực thi yêu cầu của User/Argons, chạy test tự động xác nhận `PASS 100%` (đảm bảo `PRIMITIVE MESHES: 0`), cập nhật `docs/CURRENT_CODE_SNAPSHOT.md` và `git push` lên `https://github.com/NhutPham19/GameWizad`.