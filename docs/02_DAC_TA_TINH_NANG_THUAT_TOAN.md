# Đặc tả tính năng và thuật toán

## Trắc nghiệm và phòng thi

Ứng dụng đọc câu hỏi song ngữ từ `assets/data/questions_300.json`. Người học có thể luyện tập tự do, thi thử tính giờ và làm lại câu sai. Giáo viên chọn nguồn đề, thời lượng và mã PIN phòng thi. QR cung cấp mã phòng để ứng dụng tra cứu phòng trong kho cục bộ.

Khi thí sinh rời ứng dụng trong lúc thi, luồng giám sát đọc các sự kiện vòng đời Flutter và ghi nhận vi phạm. Màn hình GV đọc tiến độ `LiveStudentSession` trong dữ liệu cục bộ. Sau khi nộp, ứng dụng chấm điểm và lưu kết quả.

## Từ điển và kiến thức SM-2

Từ điển dùng SQLite FTS để tìm kiếm toàn văn dữ liệu thuật ngữ trên thiết bị. SuperMemo SM-2 là thuật toán tham khảo mà AI Tutor ngoại tuyến có thể giải thích. Hệ số dễ nhớ được cập nhật theo công thức:

$$
EF' = \max(1.3, EF + 0.1 - (5 - q)(0.08 + (5 - q)0.02))
$$

Bản Android hiện chưa có màn hình flashcard thực thi lịch ôn theo SM-2.

## AI Tutor

- **Trực tuyến:** Flutter gửi `POST /chat` qua HTTPS. Cloudflare Worker gọi Workers AI và trả JSON có trường `answer`.
- **Ngoại tuyến:** `LocalAiEngine` trả lời câu hỏi được hỗ trợ, chẳng hạn kiến thức Dart, Flutter và tính điểm. Luồng giải thích đáp án sai có thể dùng lời giải có sẵn khi dịch vụ AI gặp lỗi.

## Thêm sinh viên vào nhóm

Luồng GV tra đúng mã ID trong bảng SQLite `users`, bỏ qua hoa thường và khoảng trắng ở hai đầu. ID chưa đăng ký báo `id ko tồn tại`. Sinh viên đã ở nhóm đích báo `id đã có trong nhóm`. Khi chuyển nhóm, bảng xếp hạng dùng ID tài khoản và giữ EXP của sinh viên.
