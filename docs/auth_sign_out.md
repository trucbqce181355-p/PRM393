# UC 9 — Xác nhận đăng xuất và thu hồi phiên

## Luồng

Các nút đăng xuất ở trang khách hàng, hồ sơ, trang admin và hoàn tất hồ sơ
Google dùng chung hộp xác nhận. Hủy đóng hộp thoại và giữ phiên. Xác nhận
khóa các nút/Back trong lúc xử lý, không mở nhiều hộp thoại hoặc gửi nhiều
yêu cầu đăng xuất đồng thời.

1. App gửi POST /api/auth/logout với Bearer token Fruitopia đang dùng.
2. Backend kiểm tra định dạng token và xóa đúng bản ghi hash trong auth_sessions.
   Không cần tài khoản còn hoạt động để thu hồi phiên của nó. Gọi lại với token
   đã thu hồi/hết hạn vẫn trả thành công sau thao tác xóa; không phụ thuộc TTL.
3. Khi backend trả thành công, app bỏ danh tính trong bộ nhớ và dọn token trong
   Windows Credential Manager hoặc kho mã hóa Android, key auth legacy và
   phiên Supabase local. Chờ SDK Google/Supabase tối đa 15 giây; có thể thử lại
   nếu bước này bị lỗi. Không lưu/log token hoặc mật khẩu.
4. Chỉ sau khi dọn xong, app chuyển về đăng nhập và xóa lịch sử điều hướng.
   Mở lại app không khôi phục phiên đã thu hồi.

API không nhận userId từ client. Token là bằng chứng sở hữu phiên; MongoDB
chỉ nhận hash. Thu hồi áp dụng phiên đang dùng, giữ nguyên tài khoản, hồ sơ,
liên kết Google, đơn hàng và các dữ liệu nghiệp vụ khác.

## Lỗi và thử lại

| Tình huống | Xử lý |
| --- | --- |
| Backend lỗi mạng/timeout/DB | Báo lỗi trong hộp thoại; giữ phiên đã chấp nhận và token local để thử lại. Không báo hoàn tất đăng xuất. |
| Backend thu hồi xong nhưng local/SDK lỗi | Không tiếp tục dùng danh tính đã thu hồi; mở màn hình lỗi dọn phiên, cho thử lại. |
| Thử lại sau lỗi dọn phiên | Nhớ token đã thu hồi trong bộ nhớ để chỉ tiếp tục dọn local/SDK. Chặn đăng nhập mới đến khi dọn xong. |
| Đóng app sau khi thu hồi nhưng chưa xóa token local | Lần mở app sau, GET /session từ chối token; cơ chế UC 8 xóa phiên đã lưu. |
| Phiên hết hạn/bị từ chối trong lúc đang xử lý | UC 8 đưa về đăng nhập; kết quả cũ không ghi đè phiên mới. |

Xóa phiên đã lưu chưa được xác minh trong màn hình khôi phục lỗi là thao tác
phục hồi local riêng (discardSavedSession). Nếu đã có phiên được chấp nhận
hoặc đã thu hồi nhưng còn dọn dở, thao tác này dùng luồng logout ở trên. Khi
không có danh tính được chấp nhận và không đọc/xác minh được credential, thao
tác chỉ xóa credential lỗi trên thiết bị, không báo đã thu hồi phiên backend;
token trên server vẫn theo thời hạn của nó. Đây là đường phục hồi khi kho
lưu lỗi đã có ở UC 8.

## Phạm vi thay đổi và kiểm tra

Các màn hình dùng chung của nhóm chỉ thay điểm gọi/import đăng xuất. Không
định dạng lại layout hoặc sửa chức năng đơn hàng, sản phẩm, chỉnh sửa hồ sơ,
voucher/hỗ trợ. Điểm gọi logout sau đổi mật khẩu legacy được nối await và bỏ
điều hướng trùng; luồng cập nhật mật khẩu legacy vẫn giữ nguyên.

Kiểm tra cú pháp backend, phân tích tĩnh phần auth và biên dịch Windows.
Không gửi logout vào phiên thật, không thay đổi MongoDB hoặc credential của
app đang dùng. Cần kiểm nghiệm thực tế Hủy, đăng xuất thành công, mở lại app,
mất kết nối và lỗi kho lưu trên bản app chính. Không thêm/chạy test giả lập
hoặc đưa credential vào Git.
