# Cài đặt và sử dụng Edumaster trên Android

## 1. Chuẩn bị trên máy mới

1. Cài Git và Android Studio. Tải Flutter **3.47.9** từ kho bản phát hành, giải nén, thêm `flutter/bin` vào `PATH` và mở PowerShell mới. [Kho bản phát hành Flutter](https://docs.flutter.dev/install/archive)
2. Mở **Android Studio → Tools → SDK Manager**. Trong **SDK Platforms**, cài Android API 36. Trong **SDK Tools**, cài Build-Tools, Platform-Tools và Command-line Tools. Cài Android Emulator nếu dùng máy ảo. Nếu Gradle báo thiếu NDK, chọn **NDK (Side by side) 28.2.13676358**.
3. Chạy `flutter doctor -v` và `flutter doctor --android-licenses`. Nếu Flutter chưa tìm thấy Android SDK, sao chép **Android SDK Location** từ SDK Manager và chạy `flutter config --android-sdk "DUONG-DAN-THAT"`. [Thiết lập Android SDK](https://docs.flutter.dev/platform-integration/android/setup)

## 2. Lấy source

```powershell
git clone https://github.com/Bui-ngoc/Edumaster.git
cd Edumaster
git branch --show-current
git log -1 --oneline
flutter pub get
```

Đối chiếu nhánh và commit với nhóm. Nếu đã clone, chạy `git status -sb`, lưu các thay đổi local rồi cập nhật nhánh bằng `git pull --ff-only`. `android/local.properties` chứa đường dẫn SDK trên từng máy.

### Xử lý Google Services

Khi thấy `File google-services.json is missing`, kiểm tra nhánh đang dùng:

- Nếu còn dùng Firebase, lấy cấu hình Android đúng ứng dụng `com.edumaster.app.edumaster` từ người quản trị. Đặt tại `android/app/google-services.json`.
- Nếu toàn bộ app đã bỏ Firebase runtime và AI Tutor dùng Worker, có thể bỏ `id("com.google.gms.google-services")` khỏi `android/app/build.gradle.kts` và bỏ khai báo cùng plugin trong `android/settings.gradle.kts`.

## 3. Chọn thiết bị và chạy app

**Emulator:** dùng **Tools → Device Manager → Create device**, tải system image, khởi động và chờ Android vào màn hình chính. Nếu gặp `Can't find service: package`, dừng AVD rồi chọn **Cold Boot Now**.

**Điện thoại thật:** bật **Tùy chọn nhà phát triển → Gỡ lỗi USB**, kết nối bằng cáp có truyền dữ liệu và xác nhận yêu cầu gỡ lỗi. Nếu máy chưa hiện trong Flutter, kiểm tra chế độ USB và driver của hãng.

```powershell
flutter devices
flutter run
```

Khi có nhiều thiết bị, thay `ID_THIET_BI` bằng ID thật trong `flutter run -d ID_THIET_BI`. Nếu cần chỉ định URL AI:

```powershell
flutter run "--dart-define=AI_TUTOR_CHAT_URL=https://edumaster-ai-tutor.edumaster-buingoc.workers.dev/chat"
```

## 4. Dùng theo vai trò

- **GV:** đăng ký tài khoản demo GV. Tạo nhóm trong **Quản lý Nhóm**, bấm **Thêm SV** rồi nhập ID của SV đã đăng ký trên chính thiết bị. Kiểm tra EXP trong bảng xếp hạng. GV có thể tạo phòng thi, lấy PIN hoặc QR và xem lịch sử phòng thi cục bộ.
- **SV:** đăng ký tài khoản demo SV và sao chép ID ở **Hồ sơ**. Thử luyện tập, thi thử, tra từ điển và AI Tutor. Streak cá nhân nằm trong **Chuỗi & Huy hiệu**. PIN hoặc QR cần trỏ đến phòng đã có trong dữ liệu local.
- **AI Tutor:** vào **Trực tuyến** và hỏi “Flutter là gì?”. Nếu app báo lỗi HTTP, kiểm tra `/health` và `/chat` theo [hướng dẫn Worker](../ai-backend/README.md). Ở chế độ **Ngoại tuyến**, thử câu hỏi thuộc nội dung học tập được hỗ trợ.

## 5. Test và build APK

```powershell
flutter analyze
flutter test
flutter build apk --release
```

Tệp APK mặc định ở `build/app/outputs/flutter-apk/app-release.apk`. Khi có `android/key.properties`, Gradle dùng cấu hình ký phát hành. Nếu không có tệp này, Gradle dùng chữ ký debug cho bản build thử. Cài APK vừa build và thử đăng nhập, từ điển, QR, phân nhóm và AI Tutor trên điện thoại thật.

Nếu cài đè thất bại do chữ ký khác, dùng APK có cùng chữ ký với bản đang cài. Gỡ bản cũ sẽ xóa dữ liệu local của ứng dụng.
