# UC 4 — Đăng nhập bằng email và mật khẩu

`POST /api/auth/login` xác minh email/mật khẩu trên backend, kiểm tra trạng thái
khóa và trả token cùng hồ sơ đã lọc thông tin nhạy cảm. Không kiểm tra mật khẩu
bằng cache Flutter, không dùng tài khoản admin/mật khẩu viết cứng.
Đã gỡ SMTP phía client; OTP email dùng backend từ UC 1, không còn dependency
mailer trong Flutter. Giữ các nơi gọi/màn hình legacy của dev qua helper tương
thích; UC này không triển khai API đặt lại mật khẩu.

- Account mới dùng scrypt với salt ngẫu nhiên.
- Account cũ có SHA-256 hoặc plaintext được nâng cấp sau khi nhập mật khẩu đúng;
  giữ nguyên ID, role, đơn hàng và thông tin tích lũy.
- Sai mật khẩu/email trả 401; bị khóa trả 403; vượt hạn mức trả 429.
- Giới hạn 50 yêu cầu/IP và 10 yêu cầu/email trong 15 phút, lưu MongoDB.
- Token ngẫu nhiên 256 bit; MongoDB chỉ lưu hash, userId và thời hạn mặc định 7 ngày.
- GET /api/auth/session xác minh token, thời hạn và trạng thái tài khoản trên server.

UI mở form email mặc định và có đường dẫn đăng ký. AuthService.login gọi API,
lấy role từ server để điều hướng user/admin; currentUser của phiên backend lấy
hồ sơ từ server, không lấy định danh từ cache email. UC 8 bổ sung lưu an toàn và
khôi phục phiên theo auth_sessions.md; không ghi token backend dạng rõ xuống
SharedPreferences. Hồ sơ/quyền khi khôi phục vẫn lấy từ backend.

Ở UC 4, luồng Google/điện thoại legacy còn giữ cho bước chuyển tiếp; UC 5 thay
Google bằng OAuth thật và gỡ đăng nhập điện thoại theo nghiệp vụ. Hồ sơ
của phiên backend không được sửa bằng màn hình legacy ghi trực tiếp mật khẩu vào
MongoDB; cập nhật qua API sẽ được bổ sung trong bước hồ sơ. Code đơn hàng, sản phẩm,
voucher và hỗ trợ không thay đổi trong commit này.

Admin phải có account thật trong MongoDB. Khi cần thiết lập admin trên máy mới,
đặt ADMIN_EMAIL/ADMIN_PASSWORD mạnh trong auth_backend/.env, chạy
`node create-admin.js` từ auth_backend rồi bỏ ADMIN_PASSWORD khỏi .env. Công cụ
không ghi đè/nâng role của tài khoản đã có; không tự chạy trên dữ liệu của nhóm.
Không có credential thật hoặc thao tác tạo tài khoản/gửi email trong commit.
