# UC 5 — Đăng nhập bằng Google

UI chỉ cung cấp Google hoặc email/mật khẩu. Google mở trình duyệt hệ thống qua
Supabase OAuth; Windows nhận callback `com.example.traicay://login-callback`
bằng app_links và chuyển callback về instance đang chạy. Có intent filter cho
Android; Windows là nền tảng chính. Không dùng tài khoản Google/token giả lập.

## Cấu hình

Điền SUPABASE_URL và SUPABASE_PUBLISHABLE_KEY trong supabase.env.json của app
và auth_backend/.env của backend, thuộc cùng một project. Chỉ dùng public key
ở Flutter; không đưa Google client secret hoặc service_role vào app/Git.

Trong Google Cloud, cấu hình OAuth Web client cho Supabase với redirect
`https://<project-ref>.supabase.co/auth/v1/callback`. Trong Supabase Auth bật
provider Google, đặt client ID/secret trên dashboard và thêm redirect URL
`com.example.traicay://login-callback`. Dùng run.bat/cấu hình Windows đã có.

## Xác minh và lưu danh tính

Sau callback, app gửi Supabase access token tới POST /api/auth/google.
Backend gọi Supabase /auth/v1/user để xác minh; yêu cầu email đã xác minh và
identity provider google. Chỉ backend tạo/lấy users và cấp token Fruitopia.

Google user mới có ID c_<UUID> riêng, supabaseUserId liên kết tới Google/Supabase
và emailNormalized; unique index chặn tạo trùng khi có nhiều callback. Google
user đã liên kết giữ nguyên ID, dữ liệu đơn hàng và thông tin tích lũy.

UC 5 chặn email đã có account nhưng chưa liên kết (409 account_link_required),
không tự tạo bản ghi trùng; liên kết được bổ sung ở UC 6. Không tạo/nâng quyền
admin theo email Google; role lấy từ account đã liên kết trên server. Tài khoản
bị khóa không được cấp phiên.

Account Google có hồ sơ đầy đủ vào trang chủ. Account mới hiển thị xác nhận
đăng nhập thành công; hoàn tất hồ sơ được bổ sung ở UC 7. Supabase JWT và token
Fruitopia chỉ ở bộ nhớ; Supabase dùng EmptyLocalStorage. UC 8 lưu/khôi phục phiên
Fruitopia an toàn. Không ghi JWT ra log/file hoặc lưu trong SharedPreferences.
Luồng SĐT và hồ sơ giả lập cũ đã được gỡ khỏi UI/auth service theo nghiệp vụ
Google hoặc email. Phiên local legacy được bỏ qua/xóa khi khởi động để không
vào app bằng token giả đã lưu trước đây. Các nơi gọi của member UI vẫn có helper
tương thích; cập nhật hồ sơ thực hiện qua API ở bước hồ sơ tiếp theo.

## Lỗi và vòng đời

Màn hình chờ callback có retry khi backend lỗi và quay lại đăng nhập. Hủy luồng
hoặc đổi sang email làm callback cũ không thể ghi đè phiên mới. Callback trùng
được gom vào một request đang chạy. Lỗi mạng/timeout Supabase trả 503 riêng,
token không hợp lệ trả 401, quá nhiều yêu cầu bị giới hạn theo IP và UID.

Backend phải truy cập được Supabase qua HTTPS; không khởi động trong sandbox
bị chặn mạng. Không chạy app build từ worktree tạm cùng app chính: Windows
protocol sẽ được đăng ký lại theo đường dẫn executable đang chạy.

Android tắt deep link handler mặc định của Flutter để app_links xử lý callback,
theo [hướng dẫn Flutter](https://docs.flutter.dev/ui/navigation/deep-linking).
