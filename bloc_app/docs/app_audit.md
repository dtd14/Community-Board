# Kiểm tra ứng dụng ngày 13/10/2026

Đã sửa hiển thị giờ bằng `.toLocal()` tại PostCard, PostDetailView và CommentCard. Chỉ chuyển múi giờ khi định dạng giao diện; không sửa timestamp trong model hay database. Giờ hiển thị theo thiết bị, không cố định Việt Nam.

Không cần sửa backend nếu timestamp trả về đúng thời điểm và có `Z` hoặc offset. Chưa đối chiếu được timestamp/schema của Supabase thực tế, nên chưa xác nhận nguyên nhân riêng của độ lệch nhanh 5 tiếng. Nếu server lưu sai thời điểm hoặc trả chuỗi không rõ múi giờ, sửa giao diện không giải quyết được phần đó.

## Kết quả kiểm tra

- Test cũ là test bộ đếm mẫu, thất bại vì MyApp chưa được đăng ký dependency trong GetIt; nội dung test cũng không phù hợp ứng dụng hiện tại.
- Đã thay bằng 12 widget test trong `test/widget_test.dart`: 3 vị trí hiển thị x 4 trường hợp (UTC, offset +07:00, qua nửa đêm, thời gian đã local). Cả 12 chạy thành công. Giá trị kỳ vọng dựa trên thời gian local định trước, nên không buộc máy CI dùng UTC+7.
- Sáu kịch bản chẩn đoán offline xác nhận các hành vi lỗi dưới đây. Repository giả lập lỗi mạng; không gửi request, tạo tài khoản, sửa hay xóa dữ liệu Supabase. Chẩn đoán nằm tạm trong `.dart_tool/app_audit_probe_test.dart` và bị Git bỏ qua. Các assertion của chẩn đoán xác nhận hành vi lỗi hiện có; kết quả pass của chẩn đoán không có nghĩa các lỗi đã được sửa.
- Flutter analyze: không có error/warning, còn 2 thông báo info `unnecessary_underscores` có sẵn tại `lib/features/auth/presentation/widgets/app_logo.dart:30`. Lệnh vẫn trả exit code 1 do hai thông báo này.
- Dart analyze trên lib của core, domain và data_supabase: không có vấn đề.
- Chưa kiểm tra tích hợp trên thiết bị, session thật, quyền RLS/RPC, SMTP hoặc dữ liệu database thực tế. Kết quả này không chứng minh toàn bộ ứng dụng không còn lỗi.

## Hành vi đã tái hiện bằng chẩn đoán

### 1. Thay ảnh bài đăng có thể làm mất ảnh cũ khi upload thất bại — ưu tiên cao

Nguồn: `../packages/domain/lib/src/post/usecases/update_post_usecase.dart:42`.

Kịch bản: bài đăng đã có ảnh; người dùng chọn ảnh mới; xóa ảnh cũ thành công nhưng upload ảnh mới lỗi mạng. Usecase gọi xóa thư mục trước rồi mới upload. Chẩn đoán ghi nhận thứ tự `delete old image -> upload fails`, kết quả trả failure. Database vẫn có thể giữ URL trỏ đến ảnh đã xóa.

Đề xuất: upload ảnh mới trước, cập nhật bài đăng thành công, sau đó dọn ảnh cũ. Khi dọn ảnh, xóa đúng file cũ thay vì toàn bộ thư mục có thể chứa ảnh mới.

### 2. Thay avatar có cùng rủi ro mất ảnh cũ — ưu tiên cao

Nguồn: `../packages/domain/lib/src/profile/usecases/update_profile_usecase.dart:47`.

Kịch bản: profile có avatar; xóa avatar cũ thành công nhưng upload mới lỗi mạng. Chẩn đoán ghi nhận `delete old avatar -> upload fails`. Đây là kiểm tra thứ tự thao tác với repository giả lập; tác động trên Storage thật phụ thuộc việc xóa có thành công hay không.

Đề xuất: upload mới, cập nhật profile, rồi dọn avatar cũ.

### 3. Mở hồ sơ tác giả từ chi tiết bài đăng gây lỗi điều hướng — ưu tiên cao

Nguồn: `lib/features/post/presentation/pages/post_detail_page.dart:291`; route khai báo tại `lib/core/config/router/route_constants.dart:20`.

Kịch bản: mở bài đăng của người khác và bấm avatar tác giả. Giao diện truyền `UserId`, trong khi route yêu cầu `userId`. Chẩn đoán GoRouter bắt được lỗi tham số và không mở hồ sơ.

Đề xuất: truyền đúng `userId` như các vị trí điều hướng khác.

### 4. Tác giả thường không thấy nút sửa/xóa bài đăng — ưu tiên cao, cần đối chiếu quy tắc quyền

Nguồn: `lib/features/post/presentation/pages/post_detail_page.dart:183`.

Điều kiện hiện tại đòi hỏi đồng thời là tác giả VÀ có role admin. Chẩn đoán người dùng role user xem bài của mình xác nhận không có cả hai nút. Admin cũng không có nút khi xem bài của người khác. Đây là hành vi giao diện đã xác nhận; chưa kiểm tra chính sách backend.

Đề xuất: nếu tác giả được sửa bài và admin được kiểm duyệt, tách `canEdit` (tác giả) và `canDelete` (tác giả hoặc admin). Quyền backend cần thực thi tương ứng.

### 5. Lưu comment thất bại vẫn đóng hộp thoại, mất nội dung vừa sửa — ưu tiên vừa

Nguồn: `lib/features/post/presentation/widgets/comment_card.dart:217`.

Kịch bản: mở sửa comment, nhập nội dung mới, lưu rồi nhận lỗi mạng. Listener chỉ kiểm tra `submittingCommentId` khác ID hiện tại, không phân biệt thành công/thất bại. Chẩn đoán xác nhận dialog đóng và nội dung vừa nhập không còn hiển thị.

Đề xuất: chỉ đóng khi lưu comment đó thành công; giữ dialog và nội dung khi có lỗi. Lọc chuyển trạng thái của đúng thao tác để sự kiện khác không đóng dialog.

### 6. Avatar hợp lệ không hiển thị trong thẻ bài đăng — ưu tiên vừa

Nguồn: `lib/features/post/presentation/widgets/post_card.dart:52`.

Điều kiện fallback dùng `isNotEmpty`, nên URL hợp lệ lại hiển thị icon người. Chuỗi rỗng đi vào nhánh tải ảnh. Chẩn đoán URL không rỗng xác nhận không có CachedNetworkImage và chỉ có icon.

Đề xuất: fallback cho null/rỗng, tải ảnh khi URL không rỗng.

## Các vấn đề phát hiện qua đọc mã, chưa chạy tích hợp để đo tác động

### 7. Xóa avatar dùng đường dẫn không đúng và che giấu lỗi

Nguồn: `../packages/data_supabase/lib/src/profile/datasources/supabase_profile_remote_data_source.dart:130`, `../packages/data_supabase/lib/src/profile/repositories/profile_repository_impl.dart:84`.

Với URL dạng `/storage/v1/object/public/avatars/public/<user>/avatar/<file>`, `pathSegments.sublist(3)` tạo `public/avatars/public/<user>/avatar/<file>`. Đường dẫn file trong bucket avatars phải là `public/<user>/avatar/<file>`. Repository còn trả Right(null) trong catch, nên lỗi xóa bị báo thành công. Cần xác minh bằng Storage thật; không thực hiện xóa trong lần kiểm tra này.

### 8. Danh sách bài của một người có thể nhận bài của người khác

Nguồn: `lib/features/post/presentation/bloc/my_post_list/my_post_list_bloc.dart:345`.

Khi nhận PostCreatedDispatched, bloc thêm bài vào đầu danh sách mà không lọc authorId theo `_userId`. Nếu một màn hình danh sách bài cá nhân còn tồn tại khi nhận sự kiện tạo bài của tác giả khác, bài đó có thể xuất hiện sai danh sách. Cần kiểm tra luồng điều hướng để đo phạm vi tác động.

### 9. Like thất bại có thể làm mất cập nhật vừa nhận

Nguồn: `lib/features/post/presentation/handlers/toggle_like_handler.dart:55`.

Khi request like lỗi, handler khôi phục toàn bộ `originalList`. Nếu danh sách đã nhận bài mới hoặc cập nhật khác trong thời gian chờ request, rollback có thể ghi đè các thay đổi đó. Đề xuất rollback riêng trạng thái like của bài đang thao tác trên danh sách mới nhất.

### 10. Phân trang comment chưa có thứ tự ổn định

Nguồn: `../packages/data_supabase/lib/src/post/datasources/supabase_post_remote_data_source.dart:134`.

Truy vấn getComments dùng range nhưng không chỉ định order. Cần kiểm tra view thực tế; để phân trang ổn định nên sắp theo created_at và thêm ID để phân biệt timestamp trùng nhau. Offset pagination vẫn có thể trùng/bỏ sót khi dữ liệu thay đổi giữa các request; có thể cân nhắc cursor nếu gặp thường xuyên.

Các lỗi khác trong báo cáo chưa được sửa. Thay đổi mã chạy của lần này chỉ gồm chuyển giờ ở ba vị trí giao diện.
