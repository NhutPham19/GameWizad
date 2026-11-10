# 📗 TÀI LIỆU CHỈ HUY TỐI CAO — PHẦN 2: BỔ SUNG AGENT KIỂM THỬ (QA), ĐẶC TẢ 5 NHÂN VẬT, MA TRẬN NGUYÊN TỐ & 3 ẢI 3D
- **Người chỉ đạo (Chief Architect):** ARGONS
- **Đơn vị thực thi (Execution Engine):** ANTIGRAVITY IDE & SUB-AGENTS (`AGENT-00` -> `AGENT-06`)
- **Nền tảng đã chốt bởi User:** **PHƯƠNG ÁN A** — Đồ họa 3D Desktop/PC chất lượng cao (**Godot 4.3+ 3D Forward+ Rendering + `godot-mcp`** hoặc **Unity 6 URP + `unity-mcp`**)[cite: 7]
- **Thư mục gốc của dự án (Project Root):** `E:\DoAnCaNhan\ThuVienGame\GameWizad`

---

## I. CẬP NHẬT KIẾN TRÚC MULTI-AGENT: BỔ SUNG `AGENT-06` (AGENT KIỂM THỬ ĐỘC LẬP)

> ⚠️ **LỆNH BẮT BUỘC CHO `AGENT-00 (Lead-Orchestrator)`:** Ngay khi đọc file số 2 này, `AGENT-00` phải tự động ghi đè/bổ sung **`AGENT-06`** vào file `.antigravity/agents_manifest.json`. **Không một Task nào được phép đánh dấu hoàn thành `[x]` nếu chưa có chữ ký xác nhận `PASS` của `AGENT-06`.**

### Hồ sơ định danh `AGENT-06`:
| Mã Agent | Tên định danh (Role) | Nhiệm vụ chuyên trách (Scope of Work) | Quyền hạn File / Thư mục | Quyền Phủ Quyết (Veto Power) |
| :--- | :--- | :--- | :--- | :--- |
| **AGENT-06** | **`QA-Automation- & Visual-Tester`** | Kiểm thử tự động bằng dòng lệnh (Headless CLI), kiểm tra lỗi biên dịch/thiếu hàm, đo FPS (đảm bảo $\ge 60$ FPS)[cite: 7], tự động chụp ảnh màn hình Viewport 3D để kiểm tra góc Camera Isometric 45°, viền đen Toon Shader, va chạm Hitbox và hiệu ứng kết hợp nguyên tố. | Toàn quyền đọc `src_game/`; quyền ghi vào `tests/`, `docs/QA_REPORTS/` và `docs/TASK_PROGRESS.md`. | **CÓ QUYỀN TỪ CHỐI BÀN GIAO (REJECT):** Nếu phát hiện lỗi crash, thiếu hàm, mất texture/shader hoặc FPS tụt dưới 60, `AGENT-06` bắt buộc trả Task về cho Agent phụ trách sửa ngay trước khi báo cáo User. |

### Quy trình Kiểm thử Tự động 4 Lớp (4-Layer QA Gate) của `AGENT-06`:
1. **Lớp 1 — Static & Compile Check (Kiểm tra Mã nguồn & Tham chiếu):** Quét toàn bộ script, đảm bảo 100% hàm được gọi đều đã định nghĩa, không có biến `null` hoặc đường dẫn mô hình 3D `.glb`/`.fbx` bị sai.
2. **Lớp 2 — Automated Headless Simulation (Giả lập Chiến đấu Tự động):** Chạy Engine ở chế độ tự động kiểm tra 5 nhân vật tung đủ 15 kỹ năng và 10 công thức dung hợp nguyên tố trong 10 giây mà không phát sinh Exception.
3. **Lớp 3 — Visual & Shader Screenshot Audit (Kiểm tra Đồ họa 3D):** Tự động kết xuất (render) ảnh chụp màn hình từ Camera Isometric vào thư mục `docs/QA_REPORTS/screenshots/` để đối chiếu:
   - Có viền đen Cel-Shading (Outline) sắc nét quanh nhân vật, cây cối, tảng đá chưa?[cite: 2, 3, 5]
   - Hiệu ứng Bloom phát sáng của Rồng lửa, Tia sét, Vòng ma thuật tím và Mắt tượng đá xanh đã rực rỡ chưa?[cite: 2, 4]
   - Mặt nước sông/hồ có độ trong suốt và gợn sóng bờ nước chưa?[cite: 2, 4]
4. **Lớp 4 — Performance & Memory Gate (Hiệu năng):** Đảm bảo tốc độ khung hình ổn định từ **60–144 FPS** khi có mặt 25 quái vật và 5 hiệu ứng 3D VFX cùng lúc trên màn hình[cite: 7].

---

## II. CHỐT KỸ THUẬT PHƯƠNG ÁN A & CHỐT CHẶN TẢI CÔNG CỤ (`[STOP-AND-ASK GATE]`)

User đã chính thức chọn **Phương án A (Godot 4.3+ 3D Forward+ Rendering hoặc Unity 6 URP + MCP)**[cite: 7].
Để các Agents có thể **code 100% cảnh vật 3D, Shader, 5 Nhân vật và chạy Kiểm thử tự động bằng CLI** nhanh nhất mà không bắt User phải thao tác tay phức tạp:
- **Khuyến nghị thực thi mặc định trong Phương án A:** Sử dụng **Godot 4.3+ (3D Forward+ Vulkan/D3D12 Renderer) kết hợp `godot-mcp`**[cite: 7] (vì toàn bộ file cảnh 3D `.tscn`, vật liệu `.tres` và `.gdshader` đều là văn bản thuần túy, giúp `AGENT-02`, `AGENT-04`, `AGENT-05` tạo núi, sông, cây cối, rồng lửa 3D trực tiếp bằng code 100% và giúp `AGENT-06` chạy lệnh kiểm thử tự động trong 2 giây). *(Nếu User đã cài sẵn Unity và muốn ép dùng Unity 6 URP, User chỉ cần báo tại bước hỏi đường dẫn).*[cite: 7]

> 🛑 **NHẮC LẠI LUẬT SỐ 1 CHO `AGENT-01`:** Khi bắt đầu **Task 1.2** và **Task 1.3**, trước khi tải bản thực thi Engine (Godot 4.3+ / Unity MCP)[cite: 7] và các gói 3D Models (`.glb`/`.fbx`), `AGENT-01` **BẮT BUỘC DỪNG LẠI** hỏi User muốn tải vào thư mục nào trên ổ đĩa!

---

## III. ĐẶC TẢ KỸ THUẬT 5 NHÂN VẬT 3D (HEROES SPECIFICATION)

**Yêu cầu cho `AGENT-03 (Core-Combat-Coder)` và `AGENT-04 (Elemental-VFX-Engineer)`:**
- Mỗi nhân vật là một Prefab/Scene 3D kế thừa từ lớp cơ sở `HeroBase3D`.
- **Cơ chế Điều khiển chung (Dễ làm quen, chuẩn MOBA/Hades):**
  - `W, A, S, D`: Di chuyển 8 hướng mượt mà trên mặt phẳng 3D `XZ` (nhân vật tự xoay mặt về hướng di chuyển hoặc hướng con trỏ chuột khi tấn công).
  - `Space`: **Lướt (Dash)** vượt chướng ngại vật thấp, miễn nhiễm sát thương trong `0.22s` (I-frames) và để lại **3 bóng mờ 3D (3D Mesh Ghost Trail)** mang màu nguyên tố của nhân vật.
  - `Chuột Trái (LMB)`: **Đòn Đánh Thường (Combo 3 nhịp)** — Không tốn năng lượng, nhịp thứ 3 có hiệu ứng mạnh hơn.
  - `Chuột Phải (RMB)`: **Kỹ Năng Đặc Trưng (Signature Skill)** — Cooldown `4s - 6s`.
  - `Phím Q`: **Chiêu Cuối Nguyên Tố (Ultimate Arcane)** — Cooldown `10s - 12s`.
  - `Phím E`: **Kỹ Năng Dung Hợp (Elemental Fusion Slot)** — Mở khóa khi nhặt nguyên tố thứ 2 trở lên.
  - `Phím F`: Tương tác nhặt Tinh Thể Nguyên Tố / Mở Rương / Qua Cổng Ải.
  - `Phím 1 -> 5` (Trong chế độ thử nghiệm hoặc tại Đấu Trường Chờ): Cho phép đổi nhanh qua lại giữa 5 nhân vật để User test ngay lập tức.

### Bảng Thông Số & Kỹ Năng Chi Tiết của 5 Nhân Vật:

#### 1. IGNIS — Hỏa Long Pháp Sư (Hệ Lửa - Fire)[cite: 2]
- **Ngoại hình 3D:** Áo choàng đỏ thẫm viền vàng phát sáng, mũ trùm đầu, tay phải tạo vòng cổ ngữ lửa vàng rực[cite: 2].
- **Chỉ số:** `HP: 100` | `Tốc chạy: 5.5m/s` | `Sát thương cơ bản: 18` | `Tốc đánh: 1.2 đòn/s`.
- **Kỹ năng 1 (Chuột Trái - *Hỏa Cầu Liên Hoàn*):** Phóng chuỗi cầu lửa 3D bay thẳng, để lại vệt khói và tàn lửa; phát nổ bán kính `1.8m` khi chạm quái[cite: 2].
- **Kỹ năng 2 (Chuột Phải - *Hỏa Ngục Ấn*):** Hiện vòng cổ ngữ vàng trước ngực và phóng một luồng sóng lửa hình nón đẩy lùi kẻ địch, gây hiệu ứng **Thiêu Đốt (Burn)** rút máu trong 3 giây[cite: 2].
- **Kỹ năng 3 (Phím Q - *Ngũ Đầu Hỏa Long*):** Triệu hồi 5 con rồng lửa 3D (dùng `RibbonDragon3D` uốn lượn) lao vút theo đường cong tới vị trí trỏ chuột, càn quét và hất tung mọi kẻ địch trên đường bay *(Giống hệt Ảnh mẫu số 1)*[cite: 2].

#### 2. ZEPHYR — Cuồng Phong Kiếm Sư (Hệ Gió - Wind)[cite: 3]
- **Ngoại hình 3D:** Áo choàng ngắn màu xanh ngọc/trắng bạc, mang song đao năng lượng gió.
- **Chỉ số:** `HP: 85` | `Tốc chạy: 7.0m/s (Nhanh nhất)` | `Sát thương cơ bản: 12` | `Tốc đánh: 2.0 đòn/s`.
- **Kỹ năng 1 (Chuột Trái - *Phong Nhận Trảm*):** Chém liên hoàn tạo ra các lưỡi sóng gió 3D hình lưỡi liềm màu trắng xanh bay xuyên qua hàng quái.
- **Kỹ năng 2 (Chuột Phải - *Bộ Pháp Cuồng Phong*):** Lướt chém hình chữ Z cực nhanh qua 3 mục tiêu gần nhất, để lại các xoáy gió nhỏ giữ chân quái `1s`.
- **Kỹ năng 3 (Phím Q - *Bão Tố Vĩnh Cửu*):** Tạo ra một cơn lốc xoáy 3D khổng lồ (`TornadoMesh3D`) tồn tại 4 giây tại vùng chỉ định, liên tục hút mọi quái vật xung quanh vào tâm lốc và cắt máu theo thời gian *(Giống hệt Ảnh mẫu số 2)*[cite: 3].

#### 3. AETHEL — Tinh Không Lôi Pháp (Hệ Sét/Bí Thuật - Lightning/Arcane)[cite: 4]
- **Ngoại hình 3D:** Giáp pháp sư tím bạc, vương miện năng lượng, xung quanh người có hạt điện tử tím bay lơ lửng[cite: 4].
- **Chỉ số:** `HP: 95` | `Tốc chạy: 5.8m/s` | `Sát thương cơ bản: 16` | `Tốc đánh: 1.4 đòn/s`.
- **Kỹ năng 1 (Chuột Trái - *Hồ Quang Điện*):** Phóng tia chớp nảy tự động giữa 3 mục tiêu đứng gần nhau trong bán kính `5m`.
- **Kỹ năng 2 (Chuột Phải - *Song Lôi Liên Kết*):** Phóng 2 luồng sét vàng rực rỡ (`ChainLightning3D`) nối trực tiếp từ tay Aethel sang 2 kẻ địch gần trỏ chuột nhất, làm **Tê Liệt (Stun nhẹ)** và rút máu liên tục trong `2.5s` *(Giống hệt Ảnh mẫu số 3)*[cite: 4].
- **Kỹ năng 3 (Phím Q - *Trận Pháp Tinh Không*):** Dựng một vòng kết giới cổ ngữ màu tím hồng phát sáng rực rỡ (`ArcaneCircleDecal3D`) dưới mặt đất trong 6 giây; khi đứng trong vòng, Aethel được tăng 40% tốc độ ra đòn và mọi kẻ địch bước vào vòng bị sét đánh tự động *(Giống hệt Ảnh mẫu số 3)*[cite: 4].

#### 4. KAEL — Thiết Thạch Hộ Vệ (Hệ Đất - Earth)[cite: 5]
- **Ngoại hình 3D:** Áo choàng vàng đất kết hợp giáp vai đá, găng tay thạch anh khổng lồ[cite: 5].
- **Chỉ số:** `HP: 160 (Trâu nhất, Giáp giảm 25% sát thương)` | `Tốc chạy: 4.6m/s` | `Sát thương cơ bản: 20` | `Tốc đánh: 0.9 đòn/s`.
- **Kỹ năng 1 (Chuột Trái - *Thiết Quyền Chấn*):** Đấm cận chiến 3D làm nứt mặt đất phía trước, gây sát thương diện rộng và đẩy lùi quái.
- **Kỹ năng 2 (Chuột Phải - *Giáp Đá Phản Chấn*):** Tạo 4 tảng đá xoay quanh người hấp thụ `50` sát thương; sau 4 giây hoặc khi vỡ sẽ nổ văng mảnh đá vào quái xung quanh.
- **Kỹ năng 3 (Phím Q - *Địa Chấn Phá Sơn*):** Đập mạnh xuống đất tạo ra 2 dải sóng đá tảng 3D (`EarthShatterWave3D`) trồi lên liên tiếp chạy dài `12m`, nghiền nát và hất tung toàn bộ kẻ địch dọc hành lang đá *(Giống hệt Ảnh mẫu số 4)*[cite: 5].

#### 5. NEREUS — Hàn Băng Thủy Sư (Hệ Nước/Băng - Water/Ice)[cite: 5]
- **Ngoại hình 3D:** Áo choàng xanh lam thẫm, vòng nước xoáy tròn quanh cổ tay[cite: 5].
- **Chỉ số:** `HP: 115` | `Tốc chạy: 5.4m/s` | `Sát thương cơ bản: 15` | `Tốc đánh: 1.3 đòn/s`.
- **Kỹ năng 1 (Chuột Trái - *Hàn Băng Tiễn*):** Bắn chùm 3 mũi tên băng làm **Chậm (Slow 35%)** tốc độ di chuyển của kẻ địch.
- **Kỹ năng 2 (Chuột Phải - *Thủy Cầu Cuộn Xoáy*):** Triệu hồi một quả cầu nước 3D khổng lồ (`WaterSphere3D`) lăn về phía trước, cuốn toàn bộ quái vật trên đường đi vào bên trong quả cầu rồi phát nổ tung tóe *(Giống hệt quả cầu nước ở Ảnh mẫu số 4)*[cite: 5].
- **Kỹ năng 3 (Phím Q - *Tuyệt Đối Không Độ*):** Tạo cơn sóng thần băng giá quét hình quạt 180 độ, đóng băng cứng (Freeze) mọi kẻ địch trúng đòn trong `3 giây`.

---

## IV. HỆ THỐNG NHẶT NGUYÊN TỐ, CƯỜNG HÓA & MA TRẬN DUNG HỢP (ELEMENTAL FUSION MATRIX)

Để người chơi mới vào **hiểu ngay lập tức mà không cần đọc hướng dẫn dài**, `AGENT-04` sẽ lập trình cơ chế **Trụ Tinh Thể Nguyên Tố (Elemental Pillar)**:
- Sau khi tiêu diệt một đợt quái hoặc mở rương, một viên **Tinh Thể 3D phát sáng** rơi xuống đất kèm vòng sáng dưới chân.
- Khi bấm `F`, thời gian trong game chậm lại và hiện **Giao diện 3 Thẻ Bài Trực Quan** (có Icon 3D, Tên chiêu và Mô tả 1 dòng):
  1. **Nếu chọn Tinh Thể CÙNG HỆ với Nhân vật:** **Cường Hóa Cấp Độ (Lv.1 $\rightarrow$ Lv.3)** — Tăng 30% sát thương, mở rộng kích thước hiệu ứng 3D (VD: Rồng lửa to hơn, Lốc xoáy rộng hơn, Sóng đá dài hơn) và giảm 20% Cooldown.
  2. **Nếu chọn Tinh Thể KHÁC HỆ:** Mở khóa hoặc nâng cấp **Kỹ Năng Dung Hợp (Phím E)** đồng thời cộng hưởng màu sắc vào chiêu cuối (Phím Q) theo bảng ma trận 10 cặp kết hợp sau:

| Cặp Nguyên Tố Kết Hợp | Tên Kỹ Năng Dung Hợp (Phím E) | Hiệu Ứng Đồ Họa 3D & Cơ Chế Chiến Đấu |
| :--- | :--- | :--- |
| **🔥 Lửa + 🌪️ Gió** | **Hỏa Phong Bạo (Firestorm Vortex)** | Tạo cơn lốc xoáy 3D bốc lửa đỏ rực, hút quái vật vào tâm và phát nổ liên hoàn. |
| **🔥 Lửa + ⚡ Sét** | **Pháo Điện Từ (Plasma Overdrive)** | Phóng tia laser năng lượng vàng-đỏ xuyên thấu toàn bản đồ, để lại vệt điện nổ dưới đất. |
| **🔥 Lửa + 🪨 Đất** | **Nham Thạch Phun Trào (Magma Eruption)** | Các tảng đá 3D trồi lên mang theo vết nứt dung nham phát sáng, để lại hồ lửa đốt máu quái *(Giống Ảnh 4)*[cite: 5]. |
| **🔥 Lửa + 🌊 Nước** | **Bão Hơi Nước Áp Suất (Scalding Steam Blast)** | Nổ sương mù nhiệt độ cao diện rộng làm mù hướng di chuyển của quái và gây sát thương chuẩn. |
| **🌪️ Gió + ⚡ Sét** | **Lôi Vân Cuồng Phong (Thunder Cyclone)** | Cơn lốc xoáy trắng bạc liên tục phóng các tia sét vàng giật toàn bộ quái xung quanh *(Giống Ảnh 2)*[cite: 3]. |
| **🌪️ Gió + 🪨 Đất** | **Bão Cát Sa Mạc (Sandstorm Shrapnel)** | Triệu hồi bão cát đá xoáy tròn đẩy lùi quái và cắt giáp của Boss. |
| **🌪️ Gió + 🌊 Nước** | **Bão Tuyết Vĩnh Cửu (Blizzard Maelstrom)** | Lốc xoáy băng giá làm chậm 70% rồi đóng băng cứng mọi kẻ địch bị cuốn vào. |
| **⚡ Sét + 🪨 Đất** | **Trụ Đá Từ Trường (Magnetic Monolith)** | Dựng cột đá cổ ngữ phát tia sét nối giữa các cột, tạo hàng rào điện khóa chặt đường đi của quái. |
| **⚡ Sét + 🌊 Nước** | **Đại Dương Dẫn Điện (Electrified Tide)** | Phóng quả cầu nước mang dòng điện cao thế, làm choáng (Stun) dây chuyền toàn bộ nhóm quái. |
| **🪨 Đất + 🌊 Nước** | **Đầm Lầy Thạch Nhũ (Quagmire Spikes)** | Hóa lỏng mặt đất dưới chân quái thành vùng bùn lầy giữ chân, sau 1.5s đâm hàng loạt gai đá/băng từ dưới lên. |

---

## V. THIẾT KẾ CHI TIẾT 3 ẢI 3D (BIOMES), CẢNH QUAN & BOSS

**Yêu cầu cho `AGENT-05 (Biome-Level-Builder)` và `AGENT-02 (TechArtist-Shader-3D)`:**
Mỗi ải phải được dựng bằng các mô hình 3D có độ cao thấp (Elevation) rõ rệt, có bờ vực, cầu nối, cây cối đung đưa nhẹ theo gió (Vertex Wind Shader) và ánh sáng riêng biệt:

### 🌲 ẢI 1: RỪNG CỔ THỤ & DÒNG SÔNG U MINH (THE WHISPERING GROVE)[cite: 2, 5]
- **Bố cục Địa hình 3D:**
  - Nền cỏ xanh rêu phân tầng cao thấp, xen kẽ các phiến gạch đá cổ rêu phong và một khu vực **hố sâu xây tường đá vuông vức ở giữa sân** (quái cung thủ có thể đứng dưới hố hoặc bên kia sông bắn sang) *(Chuẩn Ảnh 1 & Ảnh 4)*[cite: 2, 5].
  - Một **dòng sông nước tím thẫm uốn lượn** cắt chéo qua bản đồ; trên mặt sông có các bậc đá ngầm và cầu gỗ mục để nhân vật lướt (Dash) hoặc chạy qua[cite: 2].
- **Cảnh quan & Vật thể trang trí 3D:**
  - Cụm **5 Bức Tượng Đá Cổ Đại phủ rêu** nằm giữa lùm cây, đôi mắt của tượng phát ra luồng sáng xanh lam hướng thẳng lên trời *(Chuẩn Ảnh 1)*[cite: 2].
  - Rừng **cây thông lá tím sẫm** bao quanh rìa bản đồ, xen lẫn các **bông hoa rừng phát sáng màu hồng/đỏ** và cụm bình gốm cổ có thể đánh vỡ để rơi máu/vàng *(Chuẩn Ảnh 1 & Ảnh 4)*[cite: 2, 5].
- **Quái vật Ải 1:** Bộ Xương Cầm Kiếm (Skeleton Warrior), Cung Thủ Xương (Skeleton Archer)[cite: 2, 5], Pháp Sư Rừng Xanh (Forest Shaman phóng cầu lửa đỏ)[cite: 2].
- **Boss Ải 1 — CỔ THẠCH HỘ PHÁP (ANCIENT MOSS TITAN):** Bức tượng đá mắt xanh khổng lồ bước ra khỏi lùm cây, sở hữu chiêu đập đất tạo sóng đá 3D, bắn tia laser xanh từ mắt và triệu hồi lính xương.

---

### 🏜️ ẢI 2: HẺM NÚI SA MẠC & PHẾ TÍCH CÁT ĐỎ (SUNSCORCHED CANYON)[cite: 3]
- **Bố cục Địa hình 3D:**
  - Sàn đá sa thạch màu vàng cam lát gạch vòng tròn đồng tâm bị nứt vỡ theo thời gian, bao bọc bởi các **vách núi đá đỏ dựng đứng nhiều tầng** và những bức tường gạch cổ đổ nát *(Chuẩn Ảnh 2)*[cite: 3].
- **Cảnh quan & Vật thể trang trí 3D:**
  - Những chiếc **rễ cây / ngà hóa thạch uốn cong hình xoắn ốc** vươn ra từ vách đá[cite: 3].
  - Các rặng **xương rồng đá khổng lồ nở hoa tím phát sáng xanh** trên đỉnh núi[cite: 3].
  - Hàng cột đá tròn La Mã/Cổ đại bị gãy ngang và hiệu ứng các dải cát bụi mỏng bay lơ lửng qua màn hình[cite: 3].
- **Quái vật Ải 2:** Sát Thủ Sa Mạc Song Đao Xanh (Sand Blade Dancer), Tế Tư Cát Tím (Desert Cultist)[cite: 3], Bọ Cạp Đá.
- **Boss Ải 2 — CHÚA TỂ CUỒNG PHONG SA MẠC (ZEPHYRION THE DJINN):** Boss tốc độ cao liên tục tạo ra 3 cơn lốc xoáy cát trên sân, lướt chém chữ X và giáng sấm sét sa mạc.

---

### 🏛️ ẢI 3: THÁNH ĐIỆN TRÊN KHÔNG & HỒ TINH TÚ (ASTRAL SANCTUM)[cite: 4]
- **Bố cục Địa hình 3D:**
  - Nhân vật chiến đấu trên một **cây cầu đá cẩm thạch rộng lớn có lan can đá chạm khắc**, bắc ngang qua một **hồ nước màu xanh ngọc bích (Turquoise) sâu thẳm** *(Chuẩn Ảnh 3)*[cite: 4].
- **Cảnh quan & Vật thể trang trí 3D:**
  - Nhìn xuyên qua làn nước xanh ngọc bên dưới cầu là hàng loạt **trụ đá cổ đại và cổng vòm chìm dưới đáy hồ** tạo cảm giác không gian 3D cực kỳ hùng vĩ[cite: 4].
  - Dọc hai bên thành cầu đặt các **chậu lửa đồng cháy rực**, các **cổng vòm đá treo cờ hiệu màu đỏ thẫm** và dây leo xanh bám quanh trụ đá[cite: 4].
  - Hiệu ứng mưa phùn nhẹ rơi chéo và tạo vòng tròn gợn sóng trên mặt nước xanh ngọc[cite: 4].
- **Quái vật Ải 3:** Golem Tinh Thể Đỏ Phát Sáng (Ruby Construct)[cite: 4], Kỵ Sĩ Giáp Bạc Thánh Điện, Pháp Sư Tinh Tú.
- **Boss Cuối Game — ĐẠI PHÁP SƯ HƯ KHÔNG (ARCHMAGE VEXOR):** Sử dụng vòng trận pháp tím khổng lồ, kết hợp cả 5 nguyên tố (Rồng lửa, Lốc xoáy, Sóng đá, Cầu nước, Tia sét đôi) để thử thách kỹ năng điều khiển của người chơi.

---

## VI. BẢNG PHÂN CHIA TASK GIAI ĐOẠN 2 & GIAI ĐOẠN 3 (CÓ CHỐT CHẶN KIỂM THỬ CỦA `AGENT-06`)

> 📌 **QUY TẮC THỰC THI:** Sau khi hoàn tất Task 1.1 -> 1.6 ở File 1, `AGENT-00` điều phối các Agents thực hiện tiếp từ **Task 2.1 đến Task 3.5** dưới đây. Mỗi Task đều phải đi qua bước nghiệm thu của `AGENT-06`.

### 🔹 TASK 2.1: Lập trình Khung Điều Khiển 3D, Camera Follow & 5 Nhân Vật Cơ Bản
- **Thực thi:** `AGENT-03 (Core-Combat-Coder)`
- **Chi tiết:** Code lớp `HeroBase3D`, di chuyển WASD, Dash có 3 bóng mờ 3D, xoay hướng theo chuột, và cài đặt đủ 5 nhân vật (Ignis, Zephyr, Aethel, Kael, Nereus) cùng 15 kỹ năng riêng biệt[cite: 2, 3, 4, 5].
- **Kiểm thử (`AGENT-06`):** Chạy test tự động chuyển đổi cả 5 nhân vật (phím `1-5`), kích hoạt đủ Chuột trái, Chuột phải, Phím Q cho từng nhân vật, đảm bảo không lỗi null và đạt $\ge 60$ FPS[cite: 7].

### 🔹 TASK 2.2: Lập trình Hệ Thống Rơi Tinh Thể, UI 3 Thẻ Bài & Ma Trận 10 Kỹ Năng Dung Hợp
- **Thực thi:** `AGENT-04 (Elemental-VFX-Engineer)` + `AGENT-03`
- **Chi tiết:** Tạo Trụ Tinh Thể Nguyên Tố rơi ra khi diệt quái, giao diện chọn 3 thẻ nâng cấp/dung hợp khi bấm `F`, và hoàn thiện 10 hiệu ứng 3D Fusion (Phím E).
- **Kiểm thử (`AGENT-06`):** Giả lập nhặt 5 loại nguyên tố trên từng nhân vật, kiểm tra toàn bộ 10 công thức kết hợp trong bảng Ma trận mục IV hoạt động đúng hiệu ứng 3D và sát thương.

### 🔹 TASK 2.3: Dựng Ải 1 — Rừng Cổ Thụ, Dòng Sông Tím, Tượng Đá Mắt Xanh & Boss Ải 1[cite: 2, 5]
- **Thực thi:** `AGENT-05 (Biome-Level-Builder)` + `AGENT-02`
- **Chi tiết:** Lắp đặt địa hình cỏ phân tầng, hố đá giữa sân, dòng sông tím, cụm tượng đá phát sáng xanh, cây thông tím, hoa phát sáng, 3 loại quái Ải 1 và Boss *Ancient Moss Titan*[cite: 2, 5].
- **Kiểm thử (`AGENT-06`):** Chụp ảnh màn hình Ải 1 đối chiếu với Ảnh mẫu 1 & 4[cite: 2, 5], kiểm tra va chạm bờ sông/tường đá (nhân vật không bị lọt xuống đáy map) và test trận đánh Boss Ải 1.

### 🔹 TASK 3.1: Dựng Ải 2 — Hẻm Núi Sa Mạc, Vách Đá Đỏ, Xương Rồng Tím & Boss Ải 2[cite: 3]
- **Thực thi:** `AGENT-05` + `AGENT-02`
- **Chi tiết:** Dựng địa hình hẻm núi sa thạch, cột cổ gãy, xương rồng hoa tím, ngà hóa thạch xoắn ốc, hiệu ứng bão cát bay ngang, quái sa mạc và Boss *Zephyrion The Djinn*[cite: 3].
- **Kiểm thử (`AGENT-06`):** Chụp ảnh màn hình Ải 2 đối chiếu với Ảnh mẫu 2[cite: 3], kiểm tra hiệu ứng lốc xoáy 3D và hiệu năng khung hình.

### 🔹 TASK 3.2: Dựng Ải 3 — Thánh Điện Cầu Đá, Hồ Nước Xanh Ngọc & Đại Pháp Sư Boss Cuối[cite: 4]
- **Thực thi:** `AGENT-05` + `AGENT-02`
- **Chi tiết:** Dựng cầu đá cẩm thạch, Shader mặt hồ nước xanh ngọc nhìn xuyên thấu các cột đá chìm bên dưới, chậu lửa vàng, cổng vòm cờ đỏ, mưa phùn và Boss cuối *Archmage Vexor*[cite: 4].
- **Kiểm thử (`AGENT-06`):** Chụp ảnh màn hình Ải 3 đối chiếu với Ảnh mẫu 3[cite: 4], kiểm tra độ phản chiếu/trong suốt của nước và chuỗi kỹ năng 5 hệ của Boss cuối.

### 🔹 TASK 3.3: Hoàn thiện HUD Giao Diện, Màn Hình Chọn 5 Nhân Vật 3D, Âm Thanh & Đóng Gói Bản Chạy
- **Thực thi:** Toàn bộ Agents dưới sự điều phối của `AGENT-00` và kiểm định cuối cùng bởi `AGENT-06`.
- **Chi tiết:**
  1. Thiết kế màn hình chọn 5 Pháp sư đứng trên bục đá 3D (hiển thị rõ thanh chỉ số Máu, Tốc độ, Sát thương và 3 kỹ năng).
  2. Hoàn thiện HUD chiến đấu gọn đẹp (Thanh máu, Icon 4 kỹ năng LMB/RMB/Q/E kèm vòng đếm ngược Cooldown, chỉ báo Ải hiện tại `1/3, 2/3, 3/3`).
  3. `AGENT-06` xuất báo cáo tổng kết `docs/QA_REPORTS/FINAL_SIGN_OFF.md` và mở cửa sổ Game 3D hoàn chỉnh cho User trải nghiệm.