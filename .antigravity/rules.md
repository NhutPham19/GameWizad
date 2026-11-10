# ⚖️ QUY TẮC THIẾT KẾ & THỰC THI HỆ THỐNG — GAMEWIZAD (ARGONS DIRECTIVES)

Tài liệu này lưu trữ các quy tắc bất khả xâm phạm mà toàn bộ hệ thống Multi-Agent (`AGENT-00` đến `AGENT-06`) phải tuân thủ tuyệt đối trong suốt vòng đời dự án GameWizad.

---

## 🔴 ĐIỀU KHOẢN THÉP BẮT BUỘC (CRITICAL DIRECTIVES)

### 1. LUẬT SỐ 1 — CHỐT CHẶN HỎI THƯ MỤC TẢI VỀ (`[STOP-AND-ASK GATE]`)
- Khi bất kỳ tác tử nào (đặc biệt là `AGENT-01`) chạm đến bước cần **Download / Clone / Install** các tài nguyên sau:
  - Game Engine (Godot 4.3+ 3D / Unity 6 URP)
  - MCP Servers (`godot-mcp`, `unity-mcp`)
  - Gói 3D Models, Textures, Rigging/Animations (.glb, .fbx từ Kenney, Mixamo, Poly Pizza...)
  - Blender CLI hoặc Shader packages ngoài
- Tác tử phụ trách **BẮT BUỘC DỪNG TIẾN TRÌNH NGAY LẬP TỨC**.
- Xuất thông báo yêu cầu User chỉ định thư mục lưu trữ theo mẫu chuẩn:
  > 🛑 **[YÊU CẦU XÁC NHẬN TỪ USER]:** Hiện tại đang ở bước tải `[Tên Công Cụ / Repo / Gói Asset]` (Dung lượng ước tính: `...`). Bạn muốn tôi tải và lưu công cụ này trực tiếp vào thư mục dự án `E:\DoAnCaNhan\ThuVienGame\GameWizad\...` hay lưu vào một thư mục dùng chung khác trên ổ đĩa? Vui lòng nhập đường dẫn để tôi tiếp tục!
- **CẤM:** Không tự ý tải ngầm vào `C:\Users\...`, thư mục Temp hoặc ổ đĩa hệ thống khi chưa có sự xác nhận của User.

### 2. LUẬT SỐ 2 — CẤM ĐƠN NHIỆM ÔM ĐỒM (NO MONOLITHIC EXECUTION)
- Phân công đúng vai trò tác tử (`AGENT-00` đến `AGENT-06`).
- Mỗi Task phải được ghi nhận rõ ràng vào `docs/TASK_PROGRESS.md` và `memory_state.json`.
- Chuyển giao nhiệm vụ tuần tự, có kiểm thử trung gian.

### 3. LUẬT SỐ 3 — ĐỊNH HƯỚNG ĐỒ HỌA 3D CEL-SHADED CHUẨN *WIZARD OF LEGEND 2*
- Không làm game 2D top-down hay pixel art. Toàn bộ thế giới là không gian 3D thực thể.
- **Camera:** Góc Isometric nghiêng `45°–50°`, xoay ngang `45°`, chiếu Orthographic hoặc Perspective với FOV hẹp để giữ chiều sâu hình học.
- **Toon Cel-Shader:** Ánh sáng phân bậc rõ rệt (2–3 bậc màu sắc sắc nét).
- **Ink Outline:** Có viền đen đồ họa bao quanh nhân vật, quái vật, cây cối, tảng đá.
- **Bloom Post-Processing:** Hiệu ứng phát sáng rực rỡ cho phép thuật (Lửa đỏ cam, Sét vàng tím, Nước xanh ngọc, Trận pháp tím).
- **Mặt nước 3D:** Có độ trong suốt, màu tím thẫm (Ải 1) hoặc xanh ngọc (Ải 3) kèm viền bọt sóng va đập bờ đá.

### 4. LUẬT SỐ 4 — QUYỀN PHỦ QUYẾT ĐỘC LẬP CỦA `AGENT-06` (QA VETO POWER)
- Mọi Task trước khi được đánh dấu `[x]` vào `docs/TASK_PROGRESS.md` đều phải có sự thẩm định và chữ ký `PASS` của `AGENT-06`.
- `AGENT-06` có quyền trả về (`REJECT`) nếu:
  - Có lỗi biên dịch, hàm gọi bị thiếu hoặc biến `null`.
  - Không đạt mốc hiệu năng $\ge 60$ FPS.
  - Thiếu viền đen Ink Outline hoặc sai góc nhìn Isometric 45°.
  - Hiệu ứng dung hợp phép thuật không hoạt động đúng ma trận.

---

## 🛠️ TIÊU CHUẨN KỸ THUẬT CODE & KIẾN TRÚC DỰ ÁN

1. **Mã nguồn sạch & Hướng đối tượng:**
   - Kế thừa từ `HeroBase3D` (`CharacterBody3D`) cho mọi lớp nhân vật.
   - Quản lý trạng thái bằng State Machine hoặc Enum rõ ràng (`IDLE`, `MOVE`, `DASH`, `CASTING`, `HURT`, `DEAD`).
2. **Hệ thống Tín hiệu (Signals / Events):**
   - Giảm phụ thuộc trực tiếp (Decoupling): Sát thương, nhặt tinh thể, đổi chiêu thức đều phát Signal.
3. **Quản lý Tài nguyên (Assets):**
   - Toàn bộ file 3D thô đưa vào `assets_staging/` trước khi import vào `src_game/assets/`.
   - Đường dẫn công cụ ngoài được đọc từ `external_tools_links/tool_paths.env`.
