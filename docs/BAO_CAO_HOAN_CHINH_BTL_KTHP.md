# Báo cáo kết thúc học phần — EduMaster

**Học viện Công nghệ Bưu chính Viễn thông · INT1449-20261-02 · Nhóm F**

- Bùi Phương Ngọc — B24DCCC215
- Nguyễn Minh Phương — B24DCCC231
- Nguyễn Thị Yến Vi — B24DCCC286

## 1. Mục đích

EduMaster hỗ trợ học và ôn thi qua trắc nghiệm song ngữ, từ điển CNTT ngoại tuyến và AI Tutor. Giáo viên có luồng riêng để tạo đề, theo dõi tiến độ và kết quả trên dữ liệu cục bộ, quản lý nhóm và thêm sinh viên theo mã tài khoản.

## 2. Các luồng chính

**Giáo viên:** đặt tên, PIN và thời lượng phòng thi. Có thể dùng bộ đề mẫu, lọc câu hỏi hoặc soạn câu hỏi mới. Phòng tạo ra có QR để xác định mã phòng. Màn hình chi tiết hiển thị bài nộp và thống kê điểm từ dữ liệu thiết bị. Trong quản lý nhóm, giáo viên thêm sinh viên bằng ID có trong bảng `users`. Bảng xếp hạng nhóm hiển thị EXP. Giáo viên không ghi streak khi đăng nhập.

**Sinh viên:** luyện tập song ngữ, thi thử, làm lại câu sai và tra từ điển. Sinh viên có thể hỏi AI Tutor, xem EXP theo nhóm và xem streak cá nhân. Luồng thi ghi nhận sự kiện rời ứng dụng qua vòng đời Flutter. Bản demo lưu dữ liệu tài khoản và phòng thi tại thiết bị dùng để chạy.

## 3. Kiến trúc và thuật toán

Ứng dụng Flutter tổ chức thành các phần giao diện, nghiệp vụ và dữ liệu. Provider quản lý trạng thái. Repository kết nối phần nghiệp vụ với nguồn JSON, SQLite, SharedPreferences và HTTP. Từ điển dùng FTS để tra toàn văn. SM-2 là phần thiết kế tham khảo và nội dung giải thích trong AI Tutor ngoại tuyến.

Ở chế độ trực tuyến, Flutter gửi câu hỏi tới Cloudflare Worker thông qua `POST /chat`. Worker gọi Workers AI rồi trả JSON có `answer`. Ở chế độ ngoại tuyến, app xử lý các câu hỏi được hỗ trợ bằng bộ quy tắc cục bộ. [Sơ đồ kiến trúc](01_BAO_CAO_TONG_QUAN_KIEN_TRUC.md) · [Đặc tả thuật toán](02_DAC_TA_TINH_NANG_THUAT_TOAN.md)

## 4. Kiểm thử và trợ năng

Bản rà soát đạt **41/41 bài test**, gồm unit test, widget test và kiểm tra trợ năng. Phân tích tĩnh có 0 lỗi, 1 cảnh báo và 5 gợi ý. Test AI dùng phản hồi mô phỏng. Kết quả đó chưa thay cho kiểm thử APK trên Android thật. [Báo cáo kiểm thử](03_BAO_CAO_KIEM_THU_CHAT_LUONG.md)

## 5. Lưu trữ và quy trình bàn giao

Tài khoản, nhóm, EXP và phòng thi lưu trên thiết bị. Việc chia sẻ source không chia sẻ dữ liệu lớp học. Để dùng AI trực tuyến trên nhiều máy, các bản app dùng cùng URL Worker công khai. [Lưu trữ và quyền Android](04_CHINH_SACH_BAO_MAT_DU_LIEU.md)

Người nhận chuẩn bị Flutter và Android SDK, clone đúng nhánh, chạy `flutter pub get`, chọn thiết bị và chạy `flutter run`. Hướng dẫn cũng có cách xử lý Google Services, chạy test và build APK. [Hướng dẫn cài đặt chi tiết](05_HUONG_DAN_CAI_DAT_SU_DUNG.md)
