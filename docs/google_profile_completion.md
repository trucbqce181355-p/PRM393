# UC 7 — Hoàn tất hồ sơ Google lần đầu

Sau khi backend chấp nhận đăng nhập/liên kết Google, khách hàng thiếu họ tên
hoặc số điện thoại được chuyển đến màn hình hoàn tất hồ sơ. Hồ sơ đã đủ vào
trang chủ; tài khoản admin đã liên kết tiếp tục vào trang quản trị. AuthWrapper
áp dụng cùng kiểm tra hồ sơ cho khách hàng khi mở app/đăng nhập email.

## Thông tin và nghiệp vụ

- Email lấy từ tài khoản đã được backend xác minh, chỉ đọc; không gửi email/ID
  tùy ý lên API và không yêu cầu OTP email lần nữa.
- Họ tên từ 1 đến 100 ký tự sau khi bỏ khoảng trắng đầu/cuối.
- Số điện thoại liên hệ gồm 10 chữ số, bắt đầu bằng 0; không dùng để đăng nhập.
- Tài khoản chưa có mật khẩu phải thiết lập mật khẩu Fruitopia và nhập lại.
  Giữ quy tắc hiện tại: 12–256 ký tự ASCII, không có khoảng trắng đầu/cuối,
  có chữ hoa, chữ thường, số và ký tự đặc biệt. UI dùng chung validator với
  đăng ký email; backend luôn kiểm tra lại.
- Tài khoản liên kết đã có mật khẩu không hiển thị bước thiết lập mật khẩu.
  API từ chối thay mật khẩu đã có tại bước hồ sơ.

## API và lưu dữ liệu

PATCH /api/auth/profile nhận Bearer token Fruitopia và body name/phone,
thêm password khi thiết lập lần đầu. Backend kiểm tra phiên còn hạn và tài
khoản còn hoạt động, lấy users.id từ phiên. Chỉ cập nhật name/phone,
updated_at và password_hash (scrypt) khi chưa có mật khẩu; không đổi ID,
email, liên kết Google, role, đơn hàng hoặc thông tin tích lũy.

Thông tin và mật khẩu mới được ghi trong một cập nhật MongoDB. Điều kiện cập
nhật chặn tài khoản bị khóa và chặn hai yêu cầu cùng ghi đè mật khẩu. Response
chỉ trả hồ sơ công khai và hasPassword; không trả mật khẩu/hash. App chỉ cập
nhật hồ sơ trong bộ nhớ khi API thành công và phiên/ID vẫn là phiên ban đầu.

## Lỗi và vòng đời

Khóa nút/form trong lúc lưu, không cho bỏ qua hồ sơ bằng nút Back; có nút
đăng xuất để quay lại đăng nhập. Lỗi mạng/DB hiển thị thông báo và giữ form
để thử lại; không đi vào trang chủ bằng dữ liệu chỉ lưu local. Phiên hết hạn
(401) yêu cầu quay lại đăng nhập. Nếu mật khẩu đã được thiết lập bởi yêu cầu
khác (409), quay lại đăng nhập để lấy hồ sơ mới. Controller được dispose và
mật khẩu được xóa sau khi lưu thành công; không ghi mật khẩu ra log/local.

Sau khi thành công, đi đến trang chủ với ID và hồ sơ do backend trả về.
Lưu/khôi phục phiên an toàn theo auth_sessions.md (UC 8); thu hồi phiên theo auth_sign_out.md (UC 9).
