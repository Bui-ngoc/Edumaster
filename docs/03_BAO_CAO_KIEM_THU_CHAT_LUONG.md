# Kiểm thử chất lượng Edumaster

Từ thư mục có `pubspec.yaml`:

```powershell
flutter pub get
flutter analyze
flutter test --reporter expanded
```

Chạy riêng các luồng vừa cập nhật:

```powershell
flutter test test/unit/teacher_group_membership_test.dart
flutter test test/unit/ai_tutor_mode_test.dart test/widget/ai_chat_screen_test.dart
```

Bản kiểm tra với **Flutter 3.47.9 / Dart 3.13.7** đạt **41/41 bài test**. `flutter analyze` báo 0 lỗi, 1 cảnh báo hàm chưa dùng và 5 gợi ý dùng `const`. GitHub Actions trong bản rà soát đang ghim Flutter 3.27.4, thấp hơn yêu cầu Dart của dự án.

| Nhóm | Phạm vi |
| --- | --- |
| Unit | Tài khoản, dữ liệu câu hỏi, tính điểm, từ điển, thêm SV theo ID, AI ngoại tuyến và phản hồi HTTP mô phỏng. |
| Widget | Trạng thái tải, lỗi và rỗng. Màn hình AI Tutor đọc cài đặt và đổi chế độ. |
| Trợ năng | Vùng chạm, nhãn, độ tương phản và một số luồng song ngữ. |

## Kiểm tra trên Android

1. Đăng ký SV và lấy ID từ Hồ sơ. Đăng nhập GV trên cùng thiết bị. Thử thêm ID hợp lệ, lặp lại cùng ID vào cùng nhóm và thử một ID chưa đăng ký. Kiểm tra EXP và thông báo.
2. Tra một từ trong từ điển. Dùng camera quét mã QR của phòng có trong dữ liệu local.
3. Gọi `GET /health` và `POST /chat`, rồi gửi một câu hỏi từ APK đã cài trên điện thoại. [Lệnh kiểm tra Worker](../ai-backend/README.md)

Test quản lý nhóm mô phỏng bảng tài khoản và test AI mô phỏng dịch vụ. Lượt test trong Codex chưa xác nhận thao tác SQLite, camera hoặc APK trên thiết bị Android thật.
