# Backend AI Tutor trên Cloudflare

Flutter gửi `POST /chat` tới Worker. Worker gọi Cloudflare Workers AI qua binding `AI` và trả JSON có trường `answer`. APK dùng URL HTTPS công khai. Cập nhật cùng Worker giữ URL cho các APK đã cài.

## Triển khai hoặc cập nhật

Trong Cloudflare Dashboard, mở đúng Worker trong **Workers & Pages**. Trong **Settings → Bindings → Production**, kiểm tra hai binding `AI` (Workers AI) và `CHAT_RATE_LIMIT` (Rate limiter). Mở **Edit code**, cập nhật mã entry point theo `worker.mjs` rồi bấm **Deploy**.

Nếu triển khai bằng Wrangler, cài Node.js và npm. Từ thư mục gốc repository:

```powershell
cd ai-backend
npx.cmd wrangler login
npx.cmd wrangler deploy
```

Trên macOS hoặc Linux, dùng `npx` thay cho `npx.cmd`. `wrangler.toml` khai báo tên Worker và hai binding. Nếu Wrangler hỏi subdomain lần đầu, nhập tên bạn chọn. Để giữ URL của APK đã phát, dùng đúng tài khoản và cập nhật đúng Worker.

## Kiểm tra Worker

```powershell
$workerUrl = 'https://edumaster-ai-tutor.edumaster-buingoc.workers.dev'
Invoke-RestMethod "$workerUrl/health"
Invoke-RestMethod "$workerUrl/chat" -Method Post -ContentType 'application/json' -Body '{"prompt":"Flutter la gi? Tra loi bang tieng Viet."}'
```

`/health` kiểm tra các binding. `/chat` cần trả trường `answer` mới xác nhận model trả lời. Nếu thiếu binding có thể gặp `503`, vượt giới hạn tần suất có thể gặp `429`, và lỗi gọi model hoặc phản hồi trống có thể trả `502`. Xem log trong **Observability** hoặc chạy `npx.cmd wrangler tail edumaster-ai-tutor`.

Endpoint giới hạn 10 yêu cầu mỗi phút theo IP tại mỗi vị trí Cloudflare. Các lượt gọi dùng hạn mức Workers AI của tài khoản. Thành viên chạy Flutter chỉ cần URL Worker. [Hướng dẫn cấu hình Flutter](../README.md)
