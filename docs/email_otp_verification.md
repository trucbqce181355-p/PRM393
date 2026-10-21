# UC 2 — Xác minh OTP, hết hạn và giới hạn số lần thử

`POST /api/auth/otp/verify` nhận challengeId và OTP 6 số. Server tìm challenge
đang ở trạng thái sent, còn hạn và chưa vượt giới hạn; tăng attempts nguyên tử
trước khi so sánh hash bằng timingSafeEqual. Mặc định mỗi challenge có 5 lần thử
và thời hạn 300 giây kể từ lúc yêu cầu mã. Không dùng mã cố định/fallback trên
luồng đăng ký email mới, không so sánh OTP trên Flutter.

Khi hết hạn, đã xác minh hoặc hết số lần thử, server trả lỗi và yêu cầu gửi lại.
Thời hạn được kiểm tra trong truy vấn MongoDB, không phụ thuộc TTL cleanup.
Nhiều yêu cầu đồng thời không thể vượt hạn mức hoặc xác minh thành công hai lần.

Thành công chuyển challenge sang verified, bỏ otpHash và lưu hash của proof
đăng ký có hạn 10 phút. Client giữ registrationToken trong bộ nhớ để UC 3 dùng;
commit này chưa tạo tài khoản, chưa cấp phiên đăng nhập và chưa sửa users.
Gửi lại thành công xóa proof trên client và vô hiệu challenge trước đó.

Màn hình OTP có 6 ô số, xử lý loading/lỗi, chặn submit đồng thời và dispose
controller/timer. Sau khi xác minh đúng, hiển thị email đã xác thực. Điều hướng
đến hồ sơ và tạo tài khoản bằng proof đã bổ sung trong [UC 3](email_registration.md); không gọi
màn hình tạo tài khoản legacy để tránh bỏ qua bằng chứng xác minh trên server.

Cấu hình OTP_TTL_SECONDS và OTP_MAX_ATTEMPTS trong auth_backend/.env;
không commit cấu hình bí mật. Cách chạy Windows và SMTP giữ như UC 1.
