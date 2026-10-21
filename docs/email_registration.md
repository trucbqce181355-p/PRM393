# UC 3 — Tạo tài khoản sau khi xác minh email

Sau khi xác minh OTP, luồng email mở EmailRegistrationScreen: email chỉ đọc,
họ tên, số điện thoại, mật khẩu và nhập lại mật khẩu. Client và server kiểm tra
thông tin; server chỉ lấy email từ proof đã xác minh, không tin email nhập lại.

`POST /api/auth/register` nhận registrationToken, name, phone và password.
Proof verified phải còn hạn và được claim nguyên tử để chống đăng ký đồng thời.
Đăng ký thành công tiêu thụ proof; gửi lại OTP trước đó sẽ vô hiệu proof cũ.
Mật khẩu dùng scrypt với salt ngẫu nhiên, không trả hash hoặc mật khẩu qua API.
Không lưu mật khẩu trong cache/session Flutter cho luồng đăng ký email mới.

User mới có ID c_<UUID>, emailNormalized, emailVerified và identityActive;
role customer, trạng thái active, số đơn/chi tiêu ban đầu bằng 0. Unique index
cho email và ID ngăn tạo trùng khi có nhiều request. Startup kiểm tra dữ liệu
cũ trước khi bổ sung trường định danh và index; không đổi ID hoặc gộp/xóa user.
Khi startup báo dữ liệu không hợp lệ/trùng, chạy `npm run check-users` trong
auth_backend để đọc báo cáo; công cụ chỉ kiểm tra, không tự sửa dữ liệu.

Customer không còn mật khẩu mặc định 123456 khi đọc record thiếu password:
account đã dùng password_hash không được đăng nhập bằng mật khẩu fallback
trong luồng legacy. Luồng điện thoại/Google và hồ sơ legacy của dev được giữ;
đăng nhập email bằng hash trên backend đã được bổ sung trong [UC 4](email_password_login.md).

Ở UC 3, đăng ký chỉ xác nhận tạo tài khoản thành công, rồi cho mở đăng nhập.
Không cấp token giả hoặc lưu phiên local. Cấp phiên/đăng nhập và lưu phiên an
toàn sẽ được bổ sung trong các UC tiếp theo. Nếu phản hồi bị mất sau khi server
đã tạo account, không dùng proof để tạo lại; đăng nhập bằng email/mật khẩu đó.
Không có SMTP credentials trong commit; dùng .env local và cách chạy Windows
từ commit nền tảng. Không chạy seeding hoặc sửa dữ liệu đơn hàng.
