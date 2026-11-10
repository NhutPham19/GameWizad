# 📘 TÀI LIỆU CHỈ HUY TỐI CAO — PHẦN 1: KIẾN TRÚC MULTI-AGENT, THIẾT LẬP MÔI TRƯỜNG & QUY TRÌNH CÔNG CỤ
- **Người chỉ đạo (Chief Architect):** ARGONS
- **Đơn vị thực thi (Execution Engine):** ANTIGRAVITY IDE & SUB-AGENTS
- **Tên dự án:** GameWizad (3D Isometric Cel-Shaded Action Roguelike — Phong cách *Wizard of Legend 2*)[cite: 2, 3, 4, 5, 6]
- **Thư mục gốc của dự án (Project Root):** `E:\DoAnCaNhan\ThuVienGame\GameWizad`

---

## ⚠️ ĐIỀU KHOẢN BẮT BUỘC DÀNH CHO ANTIGRAVITY (SYSTEM DIRECTIVES)

Khi Antigravity đọc file này, bạn **BẮT BUỘC** phải tuân thủ 3 luật thép sau đây của **Argons** trước khi chạy bất kỳ dòng lệnh Terminal hay tạo bất kỳ file code nào:

1. **LUẬT SỐ 1 — CHỐT CHẶN HỎI THƯ MỤC TẢI VỀ (`[STOP-AND-ASK GATE]`):**
   - Bất kỳ lúc nào tiến trình chạm tới bước cần **Download / Clone / Install** các công cụ bên ngoài (Game Engine, MCP Server, GitHub Repositories, gói 3D Assets, Blender/Mixamo CLI, Shader packs, hoặc thư viện nặng), Antigravity **PHẢI DỪNG LẠI NGAY LẬP TỨC**.
   - Xuất thông báo rõ ràng ra khung chat theo mẫu:
     > 🛑 **[YÊU CẦU XÁC NHẬN TỪ USER]:** Hiện tại đang ở bước tải `[Tên Công Cụ / Repo / Gói Asset]` (Dung lượng ước tính: `...`). Bạn muốn tôi tải và lưu công cụ này trực tiếp vào thư mục dự án `E:\DoAnCaNhan\ThuVienGame\GameWizad\...` hay lưu vào một thư mục dùng chung khác trên ổ đĩa? Vui lòng nhập đường dẫn để tôi tiếp tục!
   - **Tuyệt đối không tự ý tải ngầm** vào ổ `C:\` hay thư mục tạm khi chưa có sự đồng ý của User.

2. **LUẬT SỐ 2 — CẤM ĐƠN NHIỆM ÔM ĐỒM (NO MONOLITHIC EXECUTION):**
   - Một phiên (instance) Antigravity duy nhất **KHÔNG ĐƯỢC** tự làm tất cả mọi việc từ cài môi trường, viết Shader, code 5 nhân vật cho tới dựng cảnh 3 ải trong 1 mạch.
   - Phải khởi tạo cấu trúc **Multi-Agent (5 Tác tử chuyên biệt)** như mục II bên dưới và thực thi từng Task nhỏ, lưu trạng thái vào file `TASK_PROGRESS.md` sau mỗi bước hoàn thành.

3. **LUẬT SỐ 3 — ĐỊNH HƯỚNG ĐỒ HỌA 3D CEL-SHADED CHUẨN *WIZARD OF LEGEND 2*:**
   - Tuyệt đối không tạo game 2D phẳng nhìn từ đỉnh đầu.
   - Bắt buộc sử dụng không gian **3D thực thụ**, góc nhìn Camera Isometric/Orthographic nghiêng **45°–50°**, xoay ngang **45°**, tích hợp **Toon Cel-Shader có viền đen (Ink Outline)** và hiệu ứng phát sáng **Post-Processing Bloom** cho kỹ năng phép thuật.

---

## I. CẤU TRÚC THƯ MỤC CHUẨN TẠI `E:\DoAnCaNhan\ThuVienGame\GameWizad`

Ngay ở Task đầu tiên (chưa cần tải công cụ ngoài), Antigravity sẽ khởi tạo cây thư mục quản lý dự án tại `E:\DoAnCaNhan\ThuVienGame\GameWizad` như sau:

```text
E:\DoAnCaNhan\ThuVienGame\GameWizad\
├── .antigravity\                      # Cấu hình phân quyền các Sub-Agents
│   ├── agents_manifest.json           # Định nghĩa vai trò & giới hạn quyền của 5 Agents
│   ├── memory_state.json              # Lưu trữ trạng thái bàn giao giữa các Agents
│   └── rules.md                       # Quy tắc code & quy tắc hỏi đường dẫn Download
├── docs\                              # Lưu trữ tài liệu chỉ đạo của Argons
│   ├── 01_ARGONS_MASTER_SETUP_AND_AGENTS.md
│   ├── 02_ARGONS_GAMEPLAY_HEROES_AND_BIOMES_SPEC.md
│   └── TASK_PROGRESS.md               # Bảng theo dõi tiến độ từng Task [ ] / [x]
├── external_tools_links\              # Chứa cấu hình đường dẫn trỏ tới nơi User chọn cài công cụ
│   └── tool_paths.env                 # Lưu đường dẫn sau khi hỏi User
├── assets_staging\                    # Nơi trung chuyển mô hình 3D (.glb/.fbx), анимаtion Mixamo, VFX
│   ├── characters\                    # 5 Pháp sư (Ignis, Zephyr, Aethel, Kael, Nereus)
│   ├── enemies\                       # Skeleton, Archer, Sand Assassin, Crystal Golem, Bosses
│   ├── environment\                   # Cây cổ thụ, Tượng đá mắt xanh, Cột sa mạc, Cầu đá
│   └── vfx_prefabs\                   # Rồng lửa 3D, Lốc xoáy, Tia sét, Vòng trận pháp tím
└── src_game\                          # Mã nguồn chính của Game 3D