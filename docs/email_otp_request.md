# UC 1 — Yêu cầu và gửi lại OTP email

Màn hình đăng ký gửi email đến `POST /api/auth/otp/request`. Server chuẩn hóa
email, kiểm tra dữ liệu users, tạo OTP 6 số bằng crypto, lưu hash OTP/challenge
trong MongoDB và gửi bằng Gmail SMTP. Client chỉ nhận challenge ID, thời hạn
và thời gian chờ gửi lại; không nhận hoặc tạo mã OTP.

Điền SMTP_USERNAME và SMTP_PASSWORD (Gmail app password) trong `auth_backend/.env`.
Không đưa credentials vào Flutter hoặc Git. Chạy bằng run.bat/cấu hình Windows
đã có từ commit nền tảng; backend cần truy cập Internet để gửi email.

- Chờ 60 giây trước khi gửi lại, được kiểm soát cả trên UI và server.
- Giới hạn 10 yêu cầu/email/giờ và 20 yêu cầu/IP/giờ, lưu MongoDB.
- Gửi lại thành công vô hiệu challenge cũ.
- Gửi email thất bại xóa challenge đang gửi, trả lỗi và không điều hướng thành công.
- Kiểm tra email cũ chưa có emailNormalized; không sửa users hoặc dữ liệu đơn hàng.
- Chặn submit đồng thời; timer/controller được dispose khi rời màn hình.

Commit này hoàn thành bước yêu cầu/gửi lại OTP. Màn hình OTP hiện hiển thị email
và nút gửi lại; nhập/xác minh OTP và giới hạn thử thuộc UC 2. Luồng auth cũ ở các
màn hình khác vẫn thuộc nhánh gốc, sẽ được thay thế trong các commit tiếp theo.
EmailOtpService giữ challenge để bước xác minh tiếp theo dùng đúng challenge mới.
