# 📜 BÁO CÁO TIẾN ĐỘ TOÀN DIỆN & DANH MỤC CHI TIẾT TÀI NGUYÊN KHO LƯU TRỮ (REPOSITORY INVENTORY)
### DỰ ÁN: GAMEWIZAD — 3D ISOMETRIC ACTION ROGUELITE
**Ngày lập báo cáo:** 08/11/2026  
**Chỉ đạo kiến trúc:** ARGONS (Chief Architect)  
**Đơn vị thực thi:** Antigravity IDE & Hệ thống Sub-Agents (`AGENT-00` $\rightarrow$ `AGENT-06`)  
**Nền tảng công nghệ:** **Godot Engine 4.3+ 3D Forward+ (Vulkan Renderer)**  
**Trạng thái kiểm định QA Gate:** **100% PASS (17/17 Headless Tests & GPU RTX 4060 Verification)**  

---

## MỤC LỤC
1. [TỔNG QUAN DỰ ÁN & QUYẾT ĐỊNH CHIẾN LƯỢC MỚI NHẤT](#1-tổng-quan-dự-án--quyết-định-chiến-lược-mới-nhất)
2. [BÁO CÁO TIẾN ĐỘ THỰC THI QUA CÁC GIAI ĐOẠN (PHASES 1 - 11)](#2-báo-cáo-tiến-độ-thực-thi-qua-các-giai-đoạn-phases-1---11)
3. [DANH MỤC TOÀN DIỆN KHO LƯU TRỮ (REPOSITORY INVENTORY)](#3-danh-mục-toàn-diện-kho-lưu-trữ-repository-inventory)
   - 3.1. [Cấu trúc Thư mục Gốc & Phân bổ Chức năng](#31-cấu-trúc-thư-mục-gốc--phân-bổ-chức-năng)
   - 3.2. [Chi tiết Toàn bộ Mã Nguồn Script (`src_game/scripts/`)](#32-chi-tiết-toàn-bộ-mã-nguồn-script-src_gamescripts)
   - 3.3. [Các Scene Trực Quan 3D (`src_game/scenes/`)](#33-các-scene-trực-quan-3d-src_gamescenes)
   - 3.4. [Hệ thống Shader & Material Cel-Toon AAA (`src_game/shaders/`, `materials/`)](#34-hệ-thống-shader--material-cel-toon-aaa-src_gameshaders-materials)
   - 3.5. [Kho Tài Nguyên Đồ Họa 3D, Hạt VFX & Âm Thanh (`src_game/assets/` & `assets_staging/`)](#35-kho-tài-nguyên-đồ-họa-3d-hạt-vfx--âm-thanh)
   - 3.6. [Kho Văn Kiện Chỉ Đạo & Tài Liệu Thiết Kế (`TaiLieuAgents/`, `docs/`)](#36-kho-văn-kiện-chỉ-đạo--tài-liệu-thiết-kế)
4. [HẠ TẦNG KIỂM THỬ TỰ ĐỘNG & MINH CHỨNG GPU (AGENT-06 QA GATE)](#4-hạ-tầng-kiểm-thử-tự-động--minh-chứng-gpu-agent-06-qa-gate)
5. [HƯỚNG DẪN VẬN HÀNH, KHỞI CHẠY & BẢNG PHÍM ĐIỀU KHIỂN](#5-hướng-dẫn-vận-hành-khởi-chạy--bảng-phím-điều-khiển)
6. [KẾT LUẬN & ĐỊNH HƯỚNG BƯỚC TIẾP THEO](#6-kết-luận--định-hướng-bước-tiếp-theo)

---

## 1. TỔNG QUAN DỰ ÁN & QUYẾT ĐỊNH CHIẾN LƯỢC MỚI NHẤT

### 1.1. Tôn chỉ Dự án
**GameWizad** là tựa game hành động nhập vai Roguelite góc nhìn Isometric ($45^\circ / -45^\circ$) kết hợp phong cách đồ họa Stylized AAA (lấy cảm hứng từ *Wizard of Legend 2* và *Hades 2*). Game tập trung vào cơ chế chiến đấu phép thuật đa nguyên tố thời gian thực, khả năng hoán đổi linh hoạt giữa 5 Pháp sư nguyên bản và hệ thống dung hợp chiêu thức (Elemental Fusion Matrix).

### 1.2. Quyết định Chiến lược Cập nhật (Văn kiện 11 Cập nhật từ Argons)
1. **Loại bỏ hoàn toàn quy trình AI tự vẽ hình học thô:** Cấm dùng script AI Blender tự sinh các khối hộp làm nhân vật hoặc vũ khí vì làm giảm chất lượng thị giác và lệch tông nghệ thuật của game.
2. **Thanh trừng 100% nhân vật thứ 6 (*Astral Samurai Mage*):** Đã xóa sạch toàn bộ file mô hình, code, giao diện, phím tắt liên quan đến nhân vật này để tập trung tinh hoa vào đội hình 5 Pháp sư cốt lõi.
3. **Khai thác toàn diện hệ sinh thái tài nguyên nghệ thuật chuẩn CC0:** Tận dụng tối đa kho tài nguyên đồ sộ từ **`https://github.com/Kavex/GameDev-Resources`** kết hợp các gói tài sản nổi tiếng:
   - **KayKit & Quaternius:** Vũ khí 3D và nhân vật 3D hoàn chỉnh bộ xương 41 khớp.
   - **Kenney Particle Pack:** Hơn 80 texture hạt kỹ xảo độ phân giải cao tách nền trong suốt.
   - **Kenney UI Audio & Interface Sounds:** Hơn 150 hiệu ứng âm thanh WAV chuẩn studio.
   - **Game-Icons.net:** Hơn 4,200 biểu tượng kỹ năng và nguyên tố chuẩn RPG.

---

## 2. BÁO CÁO TIẾN ĐỘ THỰC THI QUA CÁC GIAI ĐOẠN (PHASES 1 - 11)

| Giai Đoạn | Tên Nhiệm Vụ | Nội Dung Trọng Tâm | Phân Công | Trạng Thái |
| :--- | :--- | :--- | :--- | :---: |
| **Giai đoạn 1** | Khởi tạo Hạ tầng & Multi-Agent | Thiết lập cấu trúc dự án Godot 4.3 tại `D:\GameEngines\Godot`, định hình phân quyền Multi-Agent (`AGENT-00` $\rightarrow$ `AGENT-06`), cấu trúc staging tài sản. | `AGENT-00`, `AGENT-01` | **Hoàn thành 100%** |
| **Giai đoạn 2** | Gameplay 5 Pháp Sư & Ải 1 | Lập trình 5 Pháp sư, hệ thống di chuyển WASD theo trục Isometric Camera, sàn đấu Ải 1 (Rừng Cổ Thụ U Minh), cọc mục tiêu thử đòn. | `AGENT-02`, `AGENT-03` | **Hoàn thành 100%** |
| **Giai đoạn 3** | Hoàn Thiện 3 Ải, 3 Boss & Nâng Cấp | Xây dựng Ải 2 (Hẻm Núi Thiêu Đốt + Boss Zephyrion Djinn), Ải 3 (Thánh Điện Hồ Tinh Tú + Final Boss Archmage Vexor), Modal chọn tướng `[M]`, Thẻ nâng cấp Roguelite. | `AGENT-03`, `AGENT-05` | **Hoàn thành 100%** |
| **Giai đoạn 4** | Đánh Giá QA Gate Ban Đầu | Xây dựng khung kiểm thử tự động Headless Runner, xuất báo cáo JSON và chụp ảnh GPU thực tế. | `AGENT-06` | **Hoàn thành 100%** |
| **Giai đoạn 5** | Tối Ưu Hóa Chuột, Diagnostics & VFX | Hỗ trợ ngắm bắn 360 độ bằng chuột (LMB/RMB), bảng chẩn đoán FPS/DrawCalls `[F12]`, hệ thống master VFX shader. | `AGENT-02`, `AGENT-04` | **Hoàn thành 100%** |
| **Giai đoạn 6** | ACES Tonemapping & Vũ Khí Kép | Áp dụng chuẩn màu ACES Tonemapper chống chói lóa, tích hợp chuyển đổi 2 bộ vũ khí qua phím `[X]`, dựng tường vô hình chống rơi vực. | `AGENT-02`, `AGENT-03` | **Hoàn thành 100%** |
| **Giai đoạn 7** | Stylized AAA UI & AnimationTree | Thanh máu xiên lục giác, 4 ô kỹ năng kim cương viền vàng, máy hoạt ảnh 3 tầng (Locomotion, Upper Body Filter, Full Body Action), cơ chế nhặt lõi nguyên tố thời gian thực (không khựng hình). | `AGENT-02`, `AGENT-04` | **Hoàn thành 100%** |
| **Giai đoạn 8** | Đại Tu Combat, BoxMesh Purge & Radar | Xóa sạch khối cam placeholder, tái cấu trúc 15 chiêu thức đúng bản sắc 5 Pháp sư, máy trạng thái Combat 3 pha chống đè chuột spam, tách biệt hạt EXP với Lõi Nguyên Tố, Radar mini-map góc phải, khóa camera tâm nhân vật, Menu Pause `[ESC]`. | Toàn bộ Multi-Agent | **Hoàn thành 100%** |
| **Giai đoạn 10** | Hotfix Mờ Nửa Màn Phải & Culling | Vô hiệu hóa Volumetric Fog xung đột Camera Ortho, sửa Soft Particles và tắt Backface Culling cho toàn bộ kỹ năng, tách rời Mini-map Radar và Diagnostics HUD, khóa `MOUSE_FILTER_IGNORE`. | `AGENT-02`, `AGENT-03` | **Hoàn thành 100%** |
| **Giai đoạn 11** | Cài Đặt Blender 4.2 LTS & Blender-MCP | Cài đặt Blender 4.2.3 LTS Portable vào `D:\GameEngines\Blender`, cài addon `blender_mcp.py` kết nối Port 9876, thiết lập file thực thi `START_BLENDER_MCP_STUDIO.bat`. | `AGENT-01`, `AGENT-03` | **Hoàn thành 100%** |
| **Giai đoạn 11 (Cập nhật)** | Purge Nhân Vật 6 & Khai Thác CC0 | Xóa sạch 100% nhân vật 6, bỏ AI vẽ thô, khôi phục đội hình 5 Pháp sư, tích hợp vũ khí 3D KayKit, 80+ texture Kenney Particle Pack, 150+ âm thanh WAV Kenney, 4,200+ icon Game-Icons. | Toàn bộ Multi-Agent | **Hoàn thành 100%** |

---

## 3. DANH MỤC TOÀN DIỆN KHO LƯU TRỮ (REPOSITORY INVENTORY)

### 3.1. Cấu trúc Thư mục Gốc & Phân bổ Chức năng
```
E:\DoAnCaNhan\ThuVienGame\GameWizad\
├── .antigravity/                   # Trạng thái ghi nhớ Agent, bộ nhớ hệ thống và cấu hình MCP
├── assets_staging/                 # Kho lưu trữ phân loại tài nguyên gốc (Staging Area)
│   ├── characters/                 # Phôi nhân vật và gói hoạt ảnh gốc KayKit
│   ├── enemies/                    # Mô hình quái vật và Boss
│   ├── environment/                # Mô hình địa hình, cây cối, đá, tường thành
│   ├── gamedev_resources/          # TÀI NGUYÊN TẢI VỀ TỪ KAVEX/GAMEDEV-RESOURCES (CC0)
│   │   ├── catalog/                # Bản sao kho danh mục Kavex/GameDev-Resources
│   │   ├── vfx_particles/          # Trọn bộ Kenney Particle Pack (80+ PNG)
│   │   ├── ui_icons/               # Trọn bộ Game-Icons.net (4,246 SVG)
│   │   ├── audio_sfx/              # Trọn bộ Kenney UI Audio & Interface Sounds (150+ WAV)
│   │   └── weapons_3d/             # Bộ vũ khí 3D KayKit
│   └── vfx_prefabs/                # Cấu trúc hạt tạo sẵn
├── docs/                           # Tài liệu kỹ thuật, báo cáo tiến độ và nghiệm thu QA
│   ├── QA_REPORTS/                 # Báo cáo JSON kiểm thử và kho ảnh chụp GPU thực tế
│   └── *.md                        # Các tài liệu phân tích kiến trúc chuyên sâu
├── external_tools_links/           # Liên kết công cụ bên ngoài (Blender MCP server)
├── src_game/                       # THƯ MỤC DỰ ÁN GODOT CHÍNH (GODOT PROJECT ROOT)
│   ├── assets/                     # Tài nguyên được import trực tiếp vào game
│   ├── materials/                  # Material (.tres) dùng trong game
│   ├── scenes/                     # Toàn bộ Scene (.tscn) của nhân vật, màn chơi, UI
│   ├── scripts/                    # Toàn bộ mã nguồn GDScript điều khiển game
│   ├── shaders/                    # Toàn bộ mã nguồn Shader (.gdshader)
│   ├── tests/                      # Kịch bản kiểm thử tự động (Headless Runner)
│   └── project.godot               # File cấu hình chính của dự án Godot
├── TaiLieuAgents/                  # Toàn bộ các văn kiện chỉ đạo chính thức từ Argons
├── CHAY_GAME_3D.bat                # Khởi chạy nhanh game 3D bằng Godot Console
├── MO_GODOT_EDITOR.bat             # Mở giao diện Godot Editor để chỉnh sửa trực quan
├── PLAY_GAME_WIZAD.bat             # Khởi chạy game với đầy đủ tham số tối ưu
└── START_BLENDER_MCP_STUDIO.bat    # Khởi động Blender 4.2 LTS kết nối Blender-MCP Port 9876
```

---

### 3.2. Chi tiết Toàn bộ Mã Nguồn Script (`src_game/scripts/`)

#### 🧙 A. Quản lý Nhân vật (`scripts/characters/`)
- [`hero_base_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/characters/hero_base_3d.gd): Lớp cơ sở trừu tượng (`CharacterBody3D`) cho mọi Pháp sư; quản lý máy trạng thái Combat 3 pha (`CAN_CAST`, `CASTING`, `RECOVERY`), di chuyển camera-basis, lướt né đòn (Dash), hoán đổi vũ khí kép (`[X]`), máu và tính toán sát thương.
- [`hero_ignis.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/characters/hero_ignis.gd): Pháp sư Lửa — Hỏa Trượng Cổ Thụ, Pháp Thư Phun Lửa, Tường Lửa 6m và Rồng Lửa Hỏa Long.
- [`hero_zephyr.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/characters/hero_zephyr.gd): Kiếm sĩ Gió — Song Đao chém kiếm khí hình lưỡi liềm, Phong Thuẫn 360 độ và Bão Tố Vĩnh Cửu hút quái.
- [`hero_aethel.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/characters/hero_aethel.gd): Pháp sư Sét — Tinh Cầu Sét giật lan, Song Lôi Liên Kết làm choáng 2.5s và Trận Pháp Tinh Không tăng tốc đánh.
- [`hero_kael.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/characters/hero_kael.gd): Thiết Thạch Hộ Vệ — Đại Rìu đập đất, Giáp Đá Phản Chấn chặn đòn và Địa Chấn Phá Sơn 12m.
- [`hero_nereus.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/characters/hero_nereus.gd): Thủy Sư — Kiếm Băng / Cung Tiễn, Thủy Cầu Trọng Lực lăn càn quét và Băng Phong Vạn Lý đóng băng hình quạt $180^\circ$.
- [`hero_visual_builder.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/characters/hero_visual_builder.gd): Tự động nạp mô hình GLB chuẩn KayKit, thiết lập bộ xương, gán shader viền Toon, tạo node gắn vũ khí (`handslot.r`, `handslot.l`) và khởi tạo AnimationTree 3 tầng.
- [`dash_ghost.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/characters/dash_ghost.gd): Tạo hiệu ứng bóng ma mờ dần khi nhân vật lướt né đòn.

#### ⚔️ B. Hệ thống Chiến đấu & Chiêu thức (`scripts/combat/`)
- [`projectile_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/projectile_3d.gd): Thực thể đạn phép thuật bay tự do, va chạm nổ diện rộng, hỗ trợ các thuộc tính nguyên tố.
- [`slash_arc_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/slash_arc_3d.gd): Lưỡi liềm kiếm khí cận chiến hình quạt với góc mở và bán kính tùy biến.
- [`fire_wall_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/fire_wall_3d.gd): Bức tường lửa bùng cháy dài 6m thiêu đốt kẻ địch đi qua.
- [`fire_dragon_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/fire_dragon_3d.gd): Chiêu cuối Rồng Lửa 3D uốn lượn lao về phía trước gây sát thương khổng lồ.
- [`wind_shield_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/wind_shield_3d.gd): Chi khiên gió xoay tròn 360 độ phản hồi đạn và hất văng quái vật.
- [`tornado_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/tornado_3d.gd): Lốc xoáy hút quái liên tục vào tâm và tung lên không trung.
- [`chain_lightning_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/chain_lightning_3d.gd): Tia sét hồ quang giật chuyền giữa các mục tiêu lân cận.
- [`arcane_circle_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/arcane_circle_3d.gd): Vòng ma pháp cổ ngữ dưới chân hỗ trợ buff chỉ số và phóng sét thiên thạch.
- [`earth_barrier_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/earth_barrier_3d.gd): Khiên đá phản chấn hấp thụ sát thương.
- [`earth_shatter_wave_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/earth_shatter_wave_3d.gd): Sóng chấn động xé toạc mặt đất tạo ra các cột đá nhọn.
- [`water_sphere_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/water_sphere_3d.gd): Thủy cầu lăn càn quét địa hình đẩy lùi kẻ thù.
- [`ice_blizzard_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/ice_blizzard_3d.gd): Bão tuyết đóng băng kẻ địch trong diện rộng $180^\circ$.
- [`vacuum_cross_slash_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/vacuum_cross_slash_3d.gd): Đòn chém chữ X chân không tốc độ cao của Boss Zephyrion.
- [`vfx_impact_explosion_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/vfx_impact_explosion_3d.gd): Vụ nổ va chạm ánh sáng kết hợp decal vết cháy mặt đất.
- [`hitbox_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/hitbox_3d.gd) & [`hurtbox_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/hurtbox_3d.gd): Hệ thống nhận diện va chạm chiến đấu chuẩn layer/mask, chống trùng lặp frame.
- [`damage_data.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/combat/damage_data.gd): Cấu trúc dữ liệu sát thương (trị số, nguyên tố, bạo kích, hiệu ứng khống chế).

#### 🔮 C. Kỹ Năng Dung Hợp Nguyên Tố 2 Hệ (`scripts/combat/fusion_spells/`)
10 kỹ năng kết hợp kích hoạt khi người chơi nhặt đủ lõi nguyên tố và ấn phím **`[E]`**:
1. `fusion_firestorm_vortex_3d.gd`: Hỏa Phong Long Quyển (Lửa + Gió)
2. `fusion_magma_eruption_3d.gd`: Dung Nham Bộc Phá (Lửa + Đất)
3. `fusion_plasma_overdrive_3d.gd`: Quá Tải Plasma (Lửa + Sét)
4. `fusion_scalding_steam_3d.gd`: Hơi Nước Sôi Bỏng (Lửa + Nước)
5. `fusion_thunder_cyclone_3d.gd`: Lôi Phong Cuồng Nộ (Gió + Sét)
6. `fusion_sandstorm_shrapnel_3d.gd`: Bão Cát Mảnh Vỡ (Gió + Đất)
7. `fusion_blizzard_maelstrom_3d.gd`: Bão Tuyết Xoáy Nước (Gió + Nước)
8. `fusion_magnetic_monolith_3d.gd`: Cột Từ Tính Trọng Lực (Sét + Đất)
9. `fusion_electrified_tide_3d.gd`: Thủy Triều Nhiễm Điện (Sét + Nước)
10. `fusion_quagmire_spikes_3d.gd`: Đầm Lầy Gai Nhọn (Đất + Nước)

#### 🎮 D. Hạ Tầng Lõi (`scripts/core/`)
- [`hero_manager.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/core/hero_manager.gd): Quản lý Hero Pool chứa sẵn 5 Pháp sư trong bộ nhớ, chuyển đổi tức thì $0.0\text{ms}$ qua phím `1` $\rightarrow$ `5`.
- [`isometric_camera_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/core/isometric_camera_3d.gd): Camera Orthographic cố định bám mượt mà theo trọng tâm nhân vật, không bị dạt chuột.
- [`main_arena.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/core/main_arena.gd): Điều phối logic màn chơi chung, wave quái và điều kiện chiến thắng.
- [`synth_audio.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/core/synth_audio.gd): Hệ thống âm thanh trung tâm tích hợp sẵn 12 kênh phát AudioStreamPlayer, hỗ trợ nạp file WAV thật và tổng hợp sóng dự phòng.
- [`shader_prewarmer.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/core/shader_prewarmer.gd): Biên dịch trước (pre-warm) toàn bộ 8 shader và vật liệu vào GPU PSO cache khi khởi động, chống khựng hình $100\%$.
- [`screenshot_capture.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/core/screenshot_capture.gd): Tự động chụp ảnh màn hình độ phân giải cao phục vụ kiểm thử nghiệm thu khi có cờ `--capture-screens`.

#### 💎 E. Nguyên Tố, Kinh Nghiệm & Rơi Đồ (`scripts/elements/`)
- [`elemental_core_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/elements/elemental_core_3d.gd): Lõi Nguyên Tố rơi ra sau mỗi đợt quái, có hào quang xoay tròn và tự động hút về người chơi trong cự ly 4m.
- [`exp_crystal_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/elements/exp_crystal_3d.gd): Viên ngọc kinh nghiệm hình thoi màu xanh lục phân biệt hoàn toàn với Lõi Nguyên Tố.
- [`health_orb_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/elements/health_orb_3d.gd): Ngọc hồi máu rơi ra khi đập vỡ thùng gỗ hoặc rương báu.
- [`fusion_matrix.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/elements/fusion_matrix.gd): Bảng tính toán logic kết hợp giữa 2 nguyên tố để sinh kỹ năng dung hợp tương ứng.
- [`element_types.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/elements/element_types.gd): Định nghĩa màu sắc, thông số và quan hệ tương khắc của 5 nguyên tố.

#### 👹 F. Quái Vật & Trùm Cuối (`scripts/enemies/`)
- [`enemy_base_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/enemies/enemy_base_3d.gd): Lớp quái vật cơ sở tích hợp tìm đường, thanh máu nổi, nhận sát thương và văng hiệu ứng.
- **3 Boss Đại Diện Cho 3 Ải:**
  1. [`boss_ancient_moss_titan_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/enemies/boss_ancient_moss_titan_3d.gd): Boss Ải 1 — Khổng Lồ Rêu Cổ Thụ, chiêu dậm đất tạo sóng xung kích và triệu hồi rễ cây.
  2. [`boss_zephyrion_djinn_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/enemies/boss_zephyrion_djinn_3d.gd): Boss Ải 2 — Ma Thần Gió Zephyrion, chiêu lướt chém chữ X và bão cát mù mịt.
  3. [`boss_archmage_vexor_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/enemies/boss_archmage_vexor_3d.gd): Boss Ải 3 — Đại Pháp Sư Vexor, chiêu lốc xoáy hư không và mưa thiên thạch ma thuật.
- **Các loại lính thường & tinh anh:**
  - `skeleton_warrior_3d.gd`, `skeleton_archer_3d.gd`, `skeleton_mage_3d.gd`: Bộ ba chiến binh, cung thủ và pháp sư xương.
  - `desert_cultist_3d.gd`, `sandstone_golem_3d.gd`, `sand_blade_dancer_3d.gd`: Quái sa mạc Ải 2.
  - `astral_mage_3d.gd`, `silver_guard_3d.gd`, `ruby_construct_3d.gd`: Vệ binh và pháp sư tinh tú Ải 3.
  - `dummy_target.gd`: Cọc gỗ thử nghiệm sát thương bất tử.

#### 🗺️ G. Màn Chơi & Môi Trường (`scripts/levels/`)
- [`biome_1_whispering_grove.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/levels/biome_1_whispering_grove.gd): Ải 1 — Rừng Cổ Thụ U Minh (cỏ xanh, cây cổ thụ, dòng sông tím, tường đá cổ).
- [`biome_2_sunscorched_canyon.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/levels/biome_2_sunscorched_canyon.gd): Ải 2 — Hẻm Núi Thiêu Đốt (vách đá sa mạc, xương quái vật khổng lồ, bão cát).
- [`biome_3_astral_sanctum.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/levels/biome_3_astral_sanctum.gd): Ải 3 — Thánh Điện Hồ Tinh Tú (cầu cẩm thạch trắng, hồ nước xanh ngọc, chậu đuốc, cờ đỏ).
- [`environment_props_builder.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/levels/environment_props_builder.gd): Tự động sinh vật cản chiến thuật ngẫu nhiên: tường thành vòm cửa đổ nát, cột đá hoa văn, thùng gỗ, rương báu phá hủy được.
- [`portal_gate_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/levels/portal_gate_3d.gd): Cổng dịch chuyển phát sáng đưa người chơi sang ải kế tiếp khi diệt xong Boss.

#### 🖥️ H. Giao Diện Người Dùng (`scripts/ui/`)
- [`combat_hud.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/ui/combat_hud.gd): Bảng HUD chiến đấu Stylized AAA: Thanh máu góc nghiêng lục giác, 4 ô kỹ năng kim cương viền vàng, biểu tượng phím tắt, hiển thị trạng thái vũ khí.
- [`minimap_radar_ui.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/ui/minimap_radar_ui.gd): La bàn Radar ma thuật thời gian thực tại góc trên bên phải HUD ($190\times 190\text{px}$) quét vị trí người chơi, quái thường, Boss, lõi nguyên tố và cổng dịch chuyển.
- [`pause_menu_ui.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/ui/pause_menu_ui.gd): Menu tạm dừng kích hoạt khi bấm phím **`[ESC]`** gồm 5 nút tính năng (Tiếp tục, Chơi lại, Đổi tướng, Cài đặt, Thoát).
- [`hero_select_modal_ui.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/ui/hero_select_modal_ui.gd): Bảng chọn tướng toàn màn hình mở bằng phím **`[M]`** với 5 thẻ thông tin chi tiết từng Pháp sư.
- [`upgrade_cards_ui.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/ui/upgrade_cards_ui.gd): Bảng chọn 3 thẻ bài nâng cấp Roguelite khi nhặt lõi nguyên tố hoặc lên cấp.
- [`live_diagnostics_hud.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/ui/live_diagnostics_hud.gd): Bảng theo dõi hiệu năng hệ thống nhỏ gọn ở Top-Center (bấm phím **`[F12]`** để bật/tắt chi tiết).
- [`damage_number_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/ui/damage_number_3d.gd): Con số sát thương nảy lên đầu quái vật có màu sắc tương ứng nguyên tố.
- [`floating_hp_bar_3d.gd`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/src_game/scripts/ui/floating_hp_bar_3d.gd): Thanh máu trôi nổi trên đầu quái vật và Boss.

---

### 3.3. Các Scene Trực Quan 3D (`src_game/scenes/`)
- **Nhân vật:**
  - `hero_ignis.tscn`, `hero_zephyr.tscn`, `hero_aethel.tscn`, `hero_kael.tscn`, `hero_nereus.tscn`: 5 Scene nhân vật đóng gói sẵn va chạm Capsule, Hurtbox và Script điều khiển.
- **Màn chơi:**
  - `biome_1_whispering_grove.tscn`: Scene màn chơi Ải 1.
  - `biome_2_sunscorched_canyon.tscn`: Scene màn chơi Ải 2.
  - `biome_3_astral_sanctum.tscn`: Scene màn chơi Ải 3.
  - `main_arena.tscn`: Scene đấu trường kiểm thử tổng hợp.
- **Giao diện:**
  - `StylizedArcaneHUD.tscn`: Scene HUD ma thuật đóng gói sẵn cấu trúc Node.

---

### 3.4. Hệ thống Shader & Material Cel-Toon AAA (`src_game/shaders/`, `materials/`)
- **Shaders:**
  - `cel_toon.gdshader`: Shader tô bóng hoạt hình Cel-Shaded 3 dải sáng tối (Light/Mid/Shadow Bands) kết hợp ánh sáng môi trường.
  - `ink_outline.gdshader`: Shader mở rộng bề mặt đảo ngược (Inverted Hull) vẽ đường viền mực đen dày đậm Anime.
  - `vfx_master_uber.gdshader`: Shader hạt kỹ xảo tổng thể hỗ trợ Billboard, Soft Particles an toàn cho Camera Ortho và culling disabled.
  - `ui_skewed_health_bar.gdshader`: Shader thanh máu nghiêng góc $15^\circ$ có vệt máu trễ đỏ cam phong cách Hades 2.
  - `ui_diamond_skill_slot.gdshader`: Shader ô kỹ năng hình thoi xoay $45^\circ$ với viền vàng cổ điển và mặt nạ hồi chiêu đồng hồ.
  - `water.gdshader`: Shader mặt nước hồ và sông có sóng gợn hình sin, khúc xạ ánh sáng và độ trong suốt.
  - `foliage_wind.gdshader`: Shader đung đưa tán cây và bụi cỏ theo gió tự nhiên.
  - `vfx_lava_fissure.gdshader`: Shader vết nứt dung nham bốc khói rực lửa.
  - `vfx_astral_thunder_zone.gdshader`: Shader vòng sấm sét tinh tú phát sáng lấp lánh.
- **Materials:**
  - `cel_toon_base.tres`, `outline_pass.tres`: Bộ đôi vật liệu tạo ngoại hình Cel-Toon cho toàn bộ nhân vật.
  - `water_river_purple.tres`, `water_sanctum_turquoise.tres`: Vật liệu dòng sông tím Ải 1 và hồ ngọc lam Ải 3.
  - `ground_moss.tres`, `skin_tone.tres`: Vật liệu thảm cỏ rêu và tông da nhân vật.

---

### 3.5. Kho Tài Nguyên Đồ Họa 3D, Hạt VFX & Âm Thanh

#### 🎭 A. Mô hình Nhân vật & Hoạt ảnh 3D
- **5 Phôi Nhân vật KayKit Rigged (Bộ xương chuẩn 41 bones):**
  - `Mage.glb` (Dùng cho Ignis)
  - `Rogue_Hooded.glb` (Dùng cho Zephyr)
  - `Rogue.glb` (Dùng cho Aethel)
  - `Barbarian.glb` (Dùng cho Kael)
  - `Knight.glb` (Dùng cho Nereus)
- **76 Hoạt ảnh KayKit / Mixamo tích hợp sẵn:**
  - Di chuyển: `Walking_A`, `Walking_B`, `Running_A`, `Running_B`, `Dodge_Forward`, `Dodge_Backward`.
  - Niệm phép: `Spellcast_Shoot`, `Spellcast_Raise`, `Spellcast_Long`.
  - Cận chiến 1 tay & 2 tay: `1H_Melee_Attack_Slice_Horizontal`, `1H_Melee_Attack_Slice_Diagonal`, `2H_Melee_Attack_Slice`, `2H_Melee_Attack_Chop`, `2H_Melee_Attack_Spinning`, `Dualwield_Melee_Attack_Slice`.
  - Bắn nỏ & Đấm: `2H_Ranged_Shoot`, `1H_Ranged_Shoot`, `Unarmed_Melee_Attack_Punch_A`.
  - Trạng thái: `Idle`, `Cheering`, `Hit_A`, `Hit_B`, `Death_A`, `Death_B`.

#### ⚔️ B. Bộ Vũ Khí 3D Họa Sĩ KayKit (`src_game/assets/weapons/`)
- `staff.gltf` + `staff.bin`: Hỏa Trượng ma thuật cổ thụ.
- `wand.gltf` + `wand.bin`: Đũa phép lửa nhanh.
- `spellbook_open.gltf` + `spellbook_closed.gltf`: Sách cổ ma pháp mở/đóng.
- `dagger.gltf` + `dagger.bin`: Song đao găm phong ma.
- `sword_1handed.gltf` & `sword_2handed.gltf`: Kiếm đơn và Đại kiếm băng.
- `axe_2handed.gltf` & `shield_square.gltf`: Đại rìu đá và Khiên hộ vệ.
- `crossbow_1handed.gltf` & `crossbow_2handed.gltf`: Nỏ bắn tiễn phép.

#### 🎆 C. Bộ Hạt Texture Kỹ Xảo Kenney Particle Pack (`src_game/assets/vfx_textures/`)
Trọn bộ 80+ file PNG độ nét cao tách nền trong suốt:
- Lửa & Cháy: `flame_01.png` $\rightarrow$ `flame_06.png`, `fire_01.png`, `fire_02.png`.
- Kiếm khí: `slash_01.png` $\rightarrow$ `slash_04.png`.
- Sấm sét: `spark_01.png` $\rightarrow$ `spark_07.png`.
- Trận pháp & Hào quang: `circle_01.png` $\rightarrow$ `circle_05.png`, `magic_01.png` $\rightarrow$ `magic_05.png`.
- Khói & Vết nổ: `smoke_01.png` $\rightarrow$ `smoke_10.png`, `scorch_01.png` $\rightarrow$ `scorch_03.png`.
- Ánh sáng & Bụi sao: `light_01.png` $\rightarrow$ `light_03.png`, `star_01.png` $\rightarrow$ `star_09.png`, `twirl_01.png` $\rightarrow$ `twirl_03.png`.

#### 🔊 D. Bộ Âm Thanh Studio Kenney (`src_game/assets/audio/`)
- `pickup_crystal.wav`, `crystal.wav`: Tiếng nhặt ngọc nguyên tố trong trẻo.
- `pickup_health.wav`: Tiếng nhặt bình máu.
- `dash.wav`: Tiếng gió lướt né đòn tốc độ cao.
- `slash.wav`, `hit.wav`: Âm thanh chém kiếm và va chạm đánh trúng mục tiêu.
- `click.wav`, `switch.wav`: Tiếng phản hồi xúc giác bấm nút giao diện.
- Toàn bộ kho hơn 150 file WAV lưu tại `assets_staging/gamedev_resources/audio_sfx/`.

#### 🖼️ E. Bộ Biểu Tượng SVG Game-Icons.net (`src_game/assets/ui/icons/`)
- `icon_fire.svg`, `icon_fireball.svg`: Biểu tượng ngọn lửa và cầu lửa.
- `icon_tornado.svg`: Biểu tượng lốc xoáy cuồng phong.
- `icon_water.svg`: Biểu tượng dòng nước trọng lực.
- `icon_lightning.svg`, `icon_lightning_storm.svg`: Biểu tượng tia sét hồ quang và bão sét.
- `icon_shield.svg`, `icon_ice.svg`: Biểu tượng khiên đá hộ thể và hoa băng vạn lý.
- `icon_sword_slice.svg`: Biểu tượng vệt chém kiếm sĩ.
- Toàn bộ kho 4,246 file SVG gốc lưu tại `assets_staging/gamedev_resources/ui_icons/game_icons/`.

---

### 3.6. Kho Văn Kiện Chỉ Đạo & Tài Liệu Thiết Kế

#### 📂 Thư mục `TaiLieuAgents/`:
1. `01_ARGONS_MASTER_SETUP_AND_AGENTS.md`: Quy định phân quyền và phân công nhiệm vụ của 7 Agents (`AGENT-00` $\rightarrow$ `AGENT-06`).
2. `02_ARGONS_GAMEPLAY_HEROES_AND_BIOMES_SPEC.md`: Bảng đặc tả chi tiết 5 Pháp sư, 3 Ải và ma trận dung hợp nguyên tố.
3. `07_ARGONS_ULTIMATE_UI_ANIMATION_VFX_OVERHAUL.md`: Chỉ đạo đại tu Stylized AAA UI và AnimationTree 3 tầng.
4. `08_ARGONS_EXECUTION_DIRECTIVE_VFX_FIXES_COMBAT_AND_SYSTEMS.md`: Chỉ đạo xóa sạch khối cam BoxMesh, sửa 10 ảnh test lỗi của User, làm lại 15 kỹ năng, thêm Mini-map Radar và Menu Tạm dừng phím ESC.
5. `08_ARGONS_FEEDBACK_AND_COMBAT_REWORK_DIRECTIVE.md`: Chỉ đạo máy trạng thái Combat 3 pha và tách hạt EXP với Lõi Nguyên Tố.
6. `09_ARGONS_FEEDBACK_HALF_SCREEN_BLUR_AND_UI_VFX_DEFECTS.md`: Báo cáo phân tích chuyên sâu lỗi mờ nửa màn hình phải và culling chiêu thức.
7. `10_ARGONS_HOTFIX_RIGHT_SCREEN_BLUR_AND_VFX_CULLING.md`: Chỉ đạo tắt Volumetric Fog, sửa Soft Particles và tách rời UI góc phải.

#### 📂 Thư mục Gốc `GameWizad/`:
8. `11_ARGONS_BLENDER_MCP_PIPELINE_AND_HYBRID_ASSETS_CapNhat.md`: Chỉ đạo chiến lược cập nhật xóa sạch nhân vật thứ 6, cấm dùng AI tự vẽ thô, khai thác toàn diện kho tài nguyên CC0 từ `Kavex/GameDev-Resources`.

#### 📂 Thư mục `docs/`:
9. `TASK_PROGRESS.md`: Bảng theo dõi tiến độ tổng thể cập nhật liên tục qua từng giai đoạn.
10. `LIVE_BUG_AND_LAG_LOG.md`: Nhật ký ghi nhận và giải quyết triệt để mọi lỗi phát sinh trong quá trình phát triển.
11. `PHAN_TICH_6_VAN_DE_COT_LOI_VA_GIAI_PHAP_KIEN_TRUC.md`: Tài liệu kiến trúc xử lý 6 vấn đề User phản hồi.
12. `HUONG_DAN_IMPORT_QUAI_MAP_VFX.md`: Hướng dẫn quy chuẩn nhập tài nguyên vào Godot 4.

---

## 4. HẠ TẦNG KIỂM THỬ TỰ ĐỘNG & MINH CHỨNG GPU (AGENT-06 QA GATE)

### 4.1. Bộ Kiểm Thử Tự Động 17 Bài (`tests/headless_runner.gd`)
Bộ kiểm thử chạy ở chế độ Headless không cần mở cửa sổ, kiểm tra tính toàn vẹn của dự án trước mỗi lần nghiệm thu:
- **Test 1:** Xác thực toàn bộ phím tắt trong `InputMap` (WASD, LMB, RMB, Q, E, Space, X, 1-5, M, ESC).
- **Test 2 & 3:** Kiểm tra biên dịch 8 Shader và tính hợp lệ của các Material `outline_pass`.
- **Test 4 & 5:** Mô phỏng không gian 3D Viewport và kiểm tra tính toán vector di chuyển theo hướng nhìn Camera Ortho.
- **Test 6:** Kiểm tra cơ chế rơi Lõi Nguyên Tố thời gian thực không khựng game.
- **Test 7 & 8:** Xác thực nạp môi trường và Boss của Ải 2 (Zephyrion) và Ải 3 (Archmage Vexor).
- **Test 9:** Xác thực giao diện chọn tướng Modal 5 thẻ bài và bộ nạp âm thanh SynthAudio.
- **Test 10:** Kiểm tra phản hồi chuột LMB/RMB và bảng chẩn đoán kỹ thuật LiveDiagnosticsHUD.
- **Test 11:** Kiểm tra vệt chém `SlashArc3D`, hoán đổi 2 bộ vũ khí `[X]` và tường vô hình an toàn.
- **Test 12:** Kiểm tra Hero Pool chứa đúng 5 Pháp sư và thời gian chuyển đổi tức thì $0.0\text{ms}$.
- **Test 13:** Kiểm tra AnimationTree 3 tầng và các shader giao diện AAA.
- **Test 14:** Xác thực triệt tiêu 100% BoxMesh cam, 15 kỹ năng đúng bản sắc và Menu Tạm Dừng `[ESC]`.
- **Test 15:** Xác thực triệt tiêu lỗi sương mờ nửa màn hình phải và tách biệt Mini-map Radar độc lập.
- **Test 16:** Xác thực kho vũ khí 3D KayKit, texture Kenney Particle Pack, âm thanh Kenney Audio và Game-Icons SVG.
- **Test 17:** Xác thực xóa sạch 100% tàn tích nhân vật thứ 6, khôi phục đội hình 5 Pháp sư cốt lõi.

**Kết quả kiểm định mới nhất:** **17/17 PASS (100% Tuyệt đối)**  
Báo cáo JSON: [`docs/QA_REPORTS/HEADLESS_TEST_RESULTS.json`](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/docs/QA_REPORTS/HEADLESS_TEST_RESULTS.json)

```json
{
	"directive": "11_ARGONS_BLENDER_MCP_PIPELINE_AND_HYBRID_ASSETS",
	"overall_status": "PASS",
	"engine": "4.3-stable (official)",
	"timestamp": "2026-11-08T13:11:43"
}
```

### 4.2. Minh Chứng Chụp Màn Hình Thực Tế Trên GPU Vật Lý (RTX 4060)
Chạy trên phần cứng **NVIDIA GeForce RTX 4060 Laptop GPU** với bộ dựng hình **Vulkan 1.4 Forward+**:
- [Ảnh 1: Pháp sư Ignis với Hỏa Trượng KayKit và hạt lửa Kenney sắc nét](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/docs/QA_REPORTS/screenshots/directive_11_capnhat_5heroes_1.png)
- [Ảnh 2: Kiếm sĩ Zephyr vung Song Đao KayKit chém vệt kiếm khí lưỡi liềm](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/docs/QA_REPORTS/screenshots/directive_11_capnhat_5heroes_2.png)
- [Ảnh 3: Hộ vệ Kael cầm Đại Rìu KayKit trên nền cảnh quan trong trẻo đối xứng 2 nửa màn hình](file:///E:/DoAnCaNhan/ThuVienGame/GameWizad/docs/QA_REPORTS/screenshots/directive_11_capnhat_5heroes_3.png)

---

## 5. HƯỚNG DẪN VẬN HÀNH, KHỞI CHẠY & BẢNG PHÍM ĐIỀU KHIỂN

### 5.1. Khởi Chạy Game 1-Click
Người dùng có thể khởi chạy nhanh dự án bằng các file script sẵn có ở thư mục gốc:
- **`CHAY_GAME_3D.bat`** hoặc **`PLAY_GAME_WIZAD.bat`**: Chạy ngay game 3D với cấu hình đồ họa Forward+ tối ưu nhất.
- **`MO_GODOT_EDITOR.bat`**: Khởi động Godot 4.3 Editor để mở trực tiếp dự án `src_game`.
- **`START_BLENDER_MCP_STUDIO.bat`**: Bật Blender 4.2 LTS ở chế độ kết nối MCP Server Port 9876.

### 5.2. Bảng Phím Tắt Điều Khiển Hoàn Chỉnh

| Phím Bấm | Chức Năng | Chi Tiết Thao Tác |
| :---: | :--- | :--- |
| **`W` / `A` / `S` / `D`** | Di Chuyển Nhân Vật | Di chuyển 8 hướng mượt mà bám theo trục chuẩn của Camera Isometric $45^\circ$. |
| **Chuột Trái (`LMB`)** | Tấn Công Cơ Bản / Combo | Tung chiêu thức cơ bản (bắn đạn lửa, chém kiếm khí, đập búa, giật sét, bắn băng). |
| **Chuột Phải (`RMB`)** | Kỹ Năng Thứ Hai (Phòng Thủ / Chặn Đòn) | Tường lửa, phong thuẫn 360 độ, trói sét, giáp đá phản chấn, cầu nước đẩy lùi. |
| **Phím `[Q]`** | Kỹ Năng Tối Thượng (Ultimate) | Hỏa Long xuất thế, Bão tố vĩnh cửu hút quái, Trận pháp tinh không, Địa chấn 12m, Băng phong vạn lý. |
| **Phím `[E]`** | Kỹ Năng Dung Hợp Nguyên Tố (Fusion Spell) | Tung 1 trong 10 chiêu thức dung hợp cực mạnh khi đã nhặt đủ 2 lõi nguyên tố tương ứng. |
| **Phím `[Space]`** | Lướt Né Đòn (Dash) | Lướt nhanh tức thời có hiệu ứng bóng ma, cung cấp khung hình bất tử (i-frame). |
| **Phím `[X]`** | Hoán Đổi Vũ Khí Kép (Dual Weapon Stance) | Đổi giữa 2 bộ vũ khí (Trượng $\leftrightarrow$ Đũa phép & Sách cổ; Dao găm $\leftrightarrow$ Nỏ; Kiếm đơn $\leftrightarrow$ Đại kiếm). |
| **Phím `[1]` $\rightarrow$ `[5]`** | Đổi Pháp Sư Tức Thì | `1`: Ignis (Lửa) \| `2`: Zephyr (Gió) \| `3`: Aethel (Sét) \| `4`: Kael (Đất) \| `5`: Nereus (Nước). |
| **Phím `[M]`** | Bảng Chọn Tướng (Hero Modal) | Mở giao diện toàn màn hình hiển thị chi tiết chỉ số và chiêu thức của cả 5 Pháp sư. |
| **Phím `[ESC]`** | Menu Tạm Dừng (Pause Menu) | Dừng game, cho phép chơi lại từ đầu, đổi tướng, cài đặt âm lượng/đồ họa hoặc thoát. |
| **Phím `[F12]`** | Bảng Chẩn Đoán Kỹ Thuật (Live Diagnostics) | Bật/tắt thanh theo dõi FPS, thời gian khung hình (ms), số lượng DrawCalls, hạt VFX và trạng thái camera. |

---

## 6. KẾT LUẬN & ĐỊNH HƯỚNG BƯỚC TIẾP THEO

Toàn bộ mã nguồn, tài sản nghệ thuật, giao diện và kịch bản chiến đấu trong repo `GameWizad` hiện đã được chuẩn hóa tuyệt đối:
- **Đạt độ tinh gọn cao:** Đã dọn sạch 100% các file dư thừa, không còn tàn tích nhân vật 6, không còn khối hộp cam hay lỗi màu hồng magenta.
- **Chuẩn hóa chất lượng tài sản:** Đang khai thác trực tiếp các bộ tài sản chất lượng cao chuẩn CC0 từ họa sĩ uy tín (**KayKit, Quaternius, Kenney, Game-Icons**).
- **Đạt độ ổn định xuất sắc:** Vượt qua 17/17 bài kiểm tra tự động Headless, hoạt động trơn tru 60 FPS trên GPU RTX 4060 với đồ họa Vulkan Forward+ sắc nét đồng đều cả 2 nửa màn hình.

Hệ thống Agent sẵn sàng đón nhận các chỉ đạo tiếp theo từ bạn và Argons để tiếp tục nâng cấp màn chơi, cơ chế boss hoặc mở rộng các tính năng gameplay chuyên sâu!
