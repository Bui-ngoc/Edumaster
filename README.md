# EduMaster

EduMaster là ứng dụng Android của Nhóm F, học phần Phát triển ứng dụng cho các thiết bị di động (INT1449), Học viện Công nghệ Bưu chính Viễn thông. Dự án hỗ trợ sinh viên ôn tập trắc nghiệm song ngữ, tra cứu thuật ngữ CNTT và hỏi AI Tutor. Giáo viên có thể tạo đề, quản lý phòng thi, xem kết quả và phân nhóm sinh viên theo ID đã đăng ký.

**Thành viên:** Bùi Phương Ngọc — B24DCCC215, Nguyễn Minh Phương — B24DCCC231, Nguyễn Thị Yến Vi — B24DCCC286.

## 1. Chuẩn bị môi trường

| Công cụ | Yêu cầu |
| --- | --- |
| Git | Dùng để clone và cập nhật mã nguồn. |
| Flutter và Dart | Đã kiểm tra với **Flutter 3.47.9 / Dart 3.13.7**. `pubspec.yaml` yêu cầu Dart `^3.13.4`. Dart đi kèm Flutter. |
| Android Studio | Cài Android SDK Platform **36**, Android SDK Build-Tools, Platform-Tools và Command-line Tools. Nếu Gradle yêu cầu NDK, cài **NDK (Side by side) 28.2.13676358**. |
| Thiết bị Android | Dùng emulator hoặc điện thoại thật. Với Flutter 3.47.9, cấu hình dự án có min SDK 24. |

Tải và giải nén Flutter, thêm `flutter/bin` vào `PATH`, rồi mở terminal mới. Trong Android Studio, vào **Tools → SDK Manager** để cài các gói Android. [Cài Flutter](https://docs.flutter.dev/install) · [Thiết lập Android](https://docs.flutter.dev/platform-integration/android/setup)

```powershell
git --version
flutter --version
flutter doctor -v
flutter doctor --android-licenses
```

## 2. Clone và cấu hình

Mở PowerShell trong thư mục bạn muốn chứa dự án:

```powershell
git clone https://github.com/Bui-ngoc/Edumaster.git
cd Edumaster
git branch --show-current
git log -1 --oneline
flutter pub get
```

Đối chiếu nhánh và commit với người gửi source. Nếu nhóm dùng nhánh khác, chuyển sang đúng nhánh trước khi chạy `flutter pub get`. Các lệnh Flutter bên dưới chạy tại thư mục có `pubspec.yaml`.

### Cấu hình AI Tutor

- **Trực tuyến:** Flutter gọi `https://edumaster-ai-tutor.edumaster-buingoc.workers.dev/chat`. Bản Flutter kết nối Worker có URL mặc định trong `lib/data/datasources/gemini_ai_datasource.dart`.
- **Ngoại tuyến:** Chọn **Ngoại tuyến** trong AI Tutor để dùng kiến thức và phép tính được hỗ trợ trên thiết bị.
- **Cấu hình dùng chung:** Thành viên chỉ cần địa chỉ HTTPS của Worker. Người quản trị cấu hình binding `AI` và `CHAT_RATE_LIMIT` trên Cloudflare. Quy trình chạy app không cần nhập API key.

Nếu dùng Worker khác hoặc nhánh chưa có URL mặc định, truyền URL đầy đủ có `/chat`:

```powershell
flutter run "--dart-define=AI_TUTOR_CHAT_URL=https://edumaster-ai-tutor.edumaster-buingoc.workers.dev/chat"
```

### Cấu hình Android

Android build có thể yêu cầu `android/app/google-services.json` vì cấu hình Gradle hiện còn áp dụng plugin `com.google.gms.google-services`. Tệp này không được theo dõi trong Git. Với nhánh còn Firebase, người quản trị cần cung cấp tệp đúng ứng dụng. Với nhánh đã bỏ Firebase runtime, xem cách gỡ khai báo plugin trong [hướng dẫn cài đặt](docs/05_HUONG_DAN_CAI_DAT_SU_DUNG.md).

## 3. Chạy ứng dụng và build APK

- **Emulator:** Android Studio → **Device Manager** → tạo hoặc mở thiết bị ảo Android. Chờ Android vào màn hình chính.
- **Điện thoại thật:** Bật **Tùy chọn nhà phát triển → Gỡ lỗi USB**. Dùng cáp truyền dữ liệu, mở khóa điện thoại và xác nhận yêu cầu gỡ lỗi.

```powershell
flutter devices
flutter run
```

Nếu có nhiều thiết bị, dùng `flutter run -d ID_THIET_BI` và thay ID bằng giá trị Flutter in ra. Khi app mở, đăng ký tài khoản demo GV hoặc SV. Thử AI bằng cách vào **AI Tutor → Trực tuyến** và hỏi “Flutter là gì?”. Chế độ này cần Internet và Worker đang hoạt động.

```powershell
flutter build apk --release
```

APK mặc định nằm ở `build/app/outputs/flutter-apk/app-release.apk`. Nếu cần dùng Worker khác, thêm `--dart-define=AI_TUTOR_CHAT_URL=...` vào lệnh build. Thử chính APK đã build trên điện thoại thật trước khi chia sẻ.

## 4. Chạy kiểm thử

```powershell
flutter analyze
flutter test --reporter expanded
flutter test test/unit/teacher_group_membership_test.dart
flutter test test/unit/ai_tutor_mode_test.dart test/widget/ai_chat_screen_test.dart
```

Unit test và widget test có thể chạy khi chưa có thiết bị Android. Test AI dùng phản hồi mô phỏng. Để thử model thật, chạy cả `GET /health` và `POST /chat` theo [hướng dẫn Worker](ai-backend/README.md). [Kết quả và phạm vi kiểm thử](docs/03_BAO_CAO_KIEM_THU_CHAT_LUONG.md)

## 5. Dữ liệu lưu ở đâu?

| Dữ liệu | Nơi lưu |
| --- | --- |
| Tài khoản, phiên đăng nhập và vai trò | `SharedPreferences`. Tài khoản được ghi vào bảng `users` trong SQLite `edumaster_app.db`. |
| Hồ sơ, EXP, nhóm, bảng xếp hạng và streak của SV | Bộ nhớ riêng của ứng dụng trên thiết bị, gồm `SharedPreferences` và các bảng SQLite tương ứng. |
| Phòng thi, bài nộp, tiến độ và lịch sử thi | Kho dữ liệu cục bộ. PIN hoặc QR xác định phòng đã có trong dữ liệu của ứng dụng. |
| Ngân hàng câu hỏi và dữ liệu từ điển gốc | `assets/data/questions_300.json` và `assets/data/it_dictionary.json`. |
| Từ điển sau khi khởi tạo | SQLite `edumaster_it_dictionary.db`. |
| Hội thoại AI | Lịch sử hiển thị giữ trong bộ nhớ khi app chạy. Chế độ trực tuyến gửi câu hỏi và ngữ cảnh hội thoại qua HTTPS đến Worker. |

Tài khoản, nhóm và phòng thi lưu riêng trên từng thiết bị. Cùng source giúp mọi máy dùng cùng mã ứng dụng và URL AI Tutor. Khi demo thêm SV, đăng ký tài khoản SV trên cùng thiết bị mà GV sẽ dùng để quản lý nhóm. Mật khẩu tài khoản local chưa được băm, nên chỉ dùng thông tin dành riêng cho demo.

## Tài liệu

- [Cài đặt, chạy và dùng theo vai trò](docs/05_HUONG_DAN_CAI_DAT_SU_DUNG.md)
- [Kiến trúc dự án](docs/01_BAO_CAO_TONG_QUAN_KIEN_TRUC.md)
- [Đặc tả tính năng](docs/02_DAC_TA_TINH_NANG_THUAT_TOAN.md)
- [Kiểm thử](docs/03_BAO_CAO_KIEM_THU_CHAT_LUONG.md)
- [Bảo mật và lưu trữ](docs/04_CHINH_SACH_BAO_MAT_DU_LIEU.md)
- [Triển khai AI Tutor](ai-backend/README.md)
- [Báo cáo kết thúc học phần](docs/BAO_CAO_HOAN_CHINH_BTL_KTHP.md)
