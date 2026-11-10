# GameWizad

Game hành động Roguelike Isometric 3D phong cách Cel-Shaded (lấy cảm hứng từ *Wizard of Legend 2*), phát triển trên nền tảng **Godot Engine 4.3+**.

## 🎮 Tổng Quan Dự Án

- **Thể loại:** 3D Isometric Action Roguelike
- **Engine:** Godot Engine 4.3+ (3D)
- **Đồ họa:** 3D Cel-shaded Toon Shading, góc nhìn Camera Isometric (45°–50° nghiêng, xoay 45°), hiệu ứng phép thuật VFX & Post-processing Bloom.
- **Hệ thống nhân vật:** 5 hệ nguyên tố pháp thuật (Ignis - Hỏa, Zephyr - Phong, Aethel - Lôi, Kael - Thổ, Nereus - Thủy).

## 📁 Cấu Trúc Thư Mục

- `src_game/`: Mã nguồn Godot Engine chính của trò chơi (scenes, scripts, shaders, materials, vfx).
- `assets_staging/`: Thư mục tài nguyên 3D models (.glb, .fbx), animations, textures, âm thanh SFX và UI icons.
- `docs/`: Tài liệu kiến trúc hệ thống, gameplay design specifications, và báo cáo tiến độ.
- `external_tools_links/`: Cấu hình tích hợp công cụ ngoài (Blender MCP, GPUTrail, Godot binaries).
- `TaiLieuAgents/`: Tài liệu hướng dẫn thiết lập và phối hợp các AI agents.

## 🚀 Hướng Dẫn Khởi Chạy

1. Mở Godot Engine 4.3+: Chạy file `MO_GODOT_EDITOR.bat` hoặc mở thư mục `src_game` trong Godot Editor.
2. Chạy thử game: Chạy `PLAY_GAME_WIZAD.bat` hoặc nhấn **F5** trong Godot.
3. Chạy kiểm thử tự động: Chạy `RUN_AUTO_TEST_AND_VERIFY.bat`.
