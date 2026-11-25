# Bảo mật và lưu trữ dữ liệu

| Dữ liệu | Nơi lưu và phạm vi |
| --- | --- |
| Tài khoản, vai trò, phiên đăng nhập | `SharedPreferences`. Thông tin tài khoản được ghi vào bảng `users` của SQLite `edumaster_app.db`. |
| Hồ sơ, nhóm, EXP và streak | `SharedPreferences` và các bảng SQLite liên quan trên thiết bị. |
| Phòng thi, kết quả, lịch sử và tiến độ | Kho dữ liệu cục bộ trên thiết bị. |
| Từ điển và trắc nghiệm | Tệp JSON trong `assets/data/`. Từ điển được nhập vào `edumaster_it_dictionary.db`. |
| Ảnh đại diện | Hồ sơ lưu đường dẫn ảnh trên thiết bị. |

Android lưu SQLite và SharedPreferences trong vùng dữ liệu riêng của ứng dụng. Tài khoản demo cho phép chọn vai trò khi đăng ký và mật khẩu local chưa được băm. Dữ liệu tài khoản, nhóm và phòng thi không tự đồng bộ giữa thiết bị. Xóa dữ liệu ứng dụng hoặc gỡ APK có thể làm mất dữ liệu local.

## AI và quyền Android

Chế độ **Trực tuyến** gửi câu hỏi và ngữ cảnh qua HTTPS đến Cloudflare Worker. Chế độ **Ngoại tuyến** xử lý câu hỏi trên thiết bị. Flutter giữ lịch sử hội thoại trong bộ nhớ khi chạy. API `/chat` công khai và có giới hạn theo IP. Hạn mức Workers AI do tài khoản Cloudflare quản lý.

App dùng Internet cho AI trực tuyến, camera khi quét QR hoặc chụp ảnh đại diện, và trình chọn ảnh để lấy ảnh. Giữ keystore, cấu hình ký và thông tin bí mật trong nơi lưu trữ được cấp quyền. Tài liệu và app dùng URL Worker công khai. [Hướng dẫn backend](../ai-backend/README.md)
