# UC 8 — Lưu, khôi phục phiên và xử lý hết hạn

## Lưu phiên

Sau đăng nhập email hoặc Google/liên kết, app chỉ chấp nhận đăng nhập sau khi
ghi token Fruitopia thành công vào kho của hệ điều hành qua MethodChannel
fruitopia/secure_session. Windows dùng Generic Credential
Fruitopia/AuthSession/v1 trong Windows Credential Manager của người dùng
Windows hiện tại. Android (API 23+) dùng khóa AES-256 trong Android Keystore
và lưu ciphertext AES-GCM cùng IV trong SharedPreferences riêng của app.
Không có cơ chế lưu token dạng rõ dự phòng khi kho an toàn bị lỗi.

Chỉ token Fruitopia được lưu; Supabase JWT, mật khẩu, ID/role/hồ sơ không được
lưu làm bằng chứng đăng nhập. Supabase tiếp tục dùng EmptyLocalStorage. Các
key legacy auth_token/user_session/saved_session_user_id và cache JWT Supabase
cũ được xóa. Helper ghi/đọc phiên dạng rõ không còn caller đã được gỡ khỏi
StorageService; các phần đơn hàng/địa chỉ/thanh toán giữ nguyên.

## Khôi phục

App hiển thị trạng thái đang khôi phục, đọc token an toàn rồi gọi
GET /api/auth/session. Backend kiểm tra hash token, expiresAt > thời gian
hiện tại và tài khoản còn hoạt động; trả hồ sơ công khai, role, hasPassword,
sessionProvider và expiresAt. TTL MongoDB chỉ dọn bản ghi; backend luôn kiểm
tra thời hạn trong truy vấn, không chờ TTL xóa mới từ chối phiên.

| Kết quả | Hành vi |
| --- | --- |
| Không có token | Mở đăng nhập. |
| Token sai định dạng/401/403 | Xóa token local, thông báo và yêu cầu đăng nhập lại. |
| Phiên hợp lệ | Lấy ID/role/hồ sơ từ backend; mở hồ sơ còn thiếu, trang khách hoặc trang admin. |
| Backend lỗi mạng/503 hoặc dữ liệu response lỗi | Không cho vào tài khoản; giữ token để thử lại. |
| Kho của hệ điều hành lỗi | Không cho vào tài khoản; hiển thị thử lại hoặc xóa phiên đã lưu. |

Backend phải được chạy bằng cấu hình dự án trước khi khôi phục. Không tự cấp
phiên khi offline và không tin hồ sơ cache hoặc token/ID legacy trong local.

## Hết hạn khi app đang mở

Timer theo expiresAt của backend xóa phiên và chuyển về đăng nhập khi hết
hạn. Khi app trở lại trạng thái resumed, GET /session xác minh lại trên
backend. Lỗi mạng tạm thời lúc này giữ phiên đã được chấp nhận cùng timer;
không gia hạn thời hạn. API client xử lý 401 của request dùng token Fruitopia
và 403 của /session hoặc /profile để bỏ phiên bị từ chối. Token Google không
được coi là token Fruitopia trong cơ chế này; lỗi phân quyền API khác không
tự xóa phiên chỉ vì trả 403.

AuthSessionGuard xóa toàn bộ lịch sử điều hướng khi phiên đang dùng bị từ
chối/hết hạn. Khôi phục, đăng nhập và xóa phiên kiểm tra generation; thao tác
kho lưu được tuần tự hóa. Kết quả cũ không ghi đè danh tính mới; nếu hủy trong
lúc ghi, kho được đưa về token của phiên đã chấp nhận hoặc xóa token vừa ghi.

Không tự refresh/gia hạn token Fruitopia. Sau thời hạn SESSION_TTL_SECONDS
(mặc định 7 ngày), cần đăng nhập lại. Xóa token local được nối vào logout để
không khôi phục lại ở lần mở app tiếp theo; xác nhận và thu hồi phiên backend
thực hiện theo auth_sign_out.md (UC 9).

## Phạm vi kiểm tra khi tách commit

Kiểm tra cú pháp backend, phân tích Dart và biên dịch Windows. Không chạy
executable từ worktree tạm: cùng target credential/protocol với app chính,
có thể ảnh hưởng phiên thật hoặc đăng ký callback. Cần kiểm nghiệm thực tế
mở lại app, mất kết nối, phiên hết hạn và kho lưu lỗi trên bản app chính;
không tạo token/tài khoản giả hoặc file test trong commit này.
