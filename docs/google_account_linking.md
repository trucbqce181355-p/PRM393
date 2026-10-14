# UC 6 — Liên kết Google với tài khoản cùng email

Sau OAuth, backend xác minh token qua Supabase và chuẩn hóa email trước khi
tìm tài khoản. App không tự quyết định quyền sở hữu hoặc cập nhật MongoDB.

| Tình huống | Xử lý |
| --- | --- |
| Google đã liên kết | Đăng nhập vào tài khoản có supabaseUserId tương ứng. |
| Email trùng, emailVerified = true trên backend | Tự liên kết Google với tài khoản đã xác minh email. |
| Email trùng, chưa có bằng chứng xác minh email | Trả 409 account_link_required; app yêu cầu mật khẩu tài khoản cũ một lần. |
| Mật khẩu cũ sai | Không liên kết, không cấp phiên; cho nhập lại trong cùng màn hình. |
| Tài khoản bị khóa hoặc admin chưa liên kết | Từ chối liên kết. |
| Tài khoản đã liên kết Google khác | Từ chối thay danh tính đã liên kết. |

POST /api/auth/google nhận Bearer Supabase access token; khi cần xác nhận,
body có password. Backend kiểm tra mật khẩu cũ; mật khẩu SHA-256/plaintext
được chuyển sang scrypt sau khi xác minh thành công. Không yêu cầu OTP email
ở bước liên kết. Không bỏ qua mật khẩu chỉ vì users.id trùng Supabase UID.

MongoDB cập nhật nguyên tử supabaseUserId/emailVerified trên bản ghi hiện có,
giữ nguyên id, tên, điện thoại, lịch sử đơn hàng và thông tin tích lũy. Unique
index cho email/ID/Google UID và xử lý xung đột tạo tài khoản tránh tạo trùng
khi callback hoặc đăng ký diễn ra đồng thời. Dữ liệu users đã trùng từ trước
vẫn cần rà soát bằng check-users; luồng này không tự gộp/xóa bản ghi cũ.

Giới hạn yêu cầu Google áp dụng cả lần nhập mật khẩu: 30 yêu cầu/IP và
10 yêu cầu/UID trong mỗi cửa sổ 15 phút. Lỗi mạng/timeout/giới hạn được hiển
thị và có thể thử lại hoặc quay về đăng nhập. Mật khẩu chỉ ở bộ nhớ trong lúc
nhập/gửi yêu cầu; không lưu local và không ghi log. Backend local Windows
mặc định dùng loopback; khi triển khai máy chủ từ xa cần HTTPS cho API.

App gom yêu cầu Google đang chạy; callback trùng không mở lại bước xác nhận.
Hủy hoặc đổi luồng đăng nhập làm kết quả cũ không ghi đè phiên mới. Sau liên
kết, app nhận phiên Fruitopia của tài khoản gốc. Hồ sơ còn thiếu xử lý ở UC 7
theo google_profile_completion.md;
lưu/khôi phục phiên an toàn theo auth_sessions.md (UC 8); thu hồi phiên ở UC 9.
