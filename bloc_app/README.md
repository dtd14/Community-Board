# Community Board

Ứng dụng Flutter quản lý thông tin và truyền thông nội bộ: bảng tin phân loại, ghim thông tin, tương tác, danh sách người thích và xác nhận đã đọc.

## Chạy ứng dụng

Giữ các package `core`, `domain`, `data_supabase` tại `../packages` cùng ứng dụng.

1. Cấu hình `.env` với `SUPABASE_URL` và `SUPABASE_ANON_KEY` của dự án hiện có. Không dùng service_role key.
2. Chạy [migration Supabase](docs/supabase_board_upgrade.sql), rồi [kiểm tra cấu trúc và quyền](docs/supabase_verify.sql). Migration dựa trên schema hiện có, không phải script khởi tạo dự án mới.
3. Chạy `flutter pub get` rồi `flutter run`; dùng `flutter run -d chrome` cho web.
4. Đăng xuất và đăng nhập lại để nạp quyền từ `profiles`.

## Kiểm tra và tài liệu

- `flutter analyze`
- `flutter test`
- `flutter build web --no-pub`
- [Báo cáo thay đổi, hướng dẫn backend và các mục cần cập nhật trong đồ án](docs/board_upgrade_report.md).
- Ảnh xem trước dùng dữ liệu minh họa: [điện thoại](docs/ui-preview/feed-390.png), [màn hình rộng](docs/ui-preview/feed-1440.png).
