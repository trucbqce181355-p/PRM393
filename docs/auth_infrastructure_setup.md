# Auth infrastructure — commit 0

Commit này chuẩn bị backend auth, kết nối MongoDB, HTTP client và cấu hình chạy
Flutter Windows. Chưa triển khai API OTP, đăng ký, đăng nhập, liên kết Google,
hồ sơ hoặc phiên đăng nhập. Các chức năng đó được đưa vào từng commit tiếp theo.
Luồng giao diện đang có trên nhánh gốc được giữ nguyên trong commit này.

## Thiết lập

Yêu cầu Node.js 22 trở lên, MongoDB local, Flutter và bộ công cụ build Windows.

```powershell
cd auth_backend
npm ci
Copy-Item .env.example .env
```

Điền MONGODB_URI và DB_NAME trong `.env`. Các trường Supabase, SMTP và giới hạn
OTP/session trong file mẫu dành cho những bước triển khai tiếp theo; chưa dùng
ở commit 0. Không commit `.env` hoặc thông tin bí mật.

Từ thư mục gốc repo:

```powershell
Copy-Item supabase.env.example.json supabase.env.json
flutter pub get
.\run.bat
```

Có thể mở `Fruitopia.code-workspace`, chọn **Fruitopia (Windows)** rồi F5.
Task chạy `start-auth.js` trước Flutter. Launcher yêu cầu backend có `.env` và
dependencies, rồi kiểm tra health; không chọn Debug Anyway nếu task thất bại.
Không có yêu cầu ATL mới trong commit này.

Backend mặc định nghe `127.0.0.1:5001`. Health kiểm tra kết nối MongoDB và chỉ
đọc dữ liệu; commit này không sửa users hoặc tạo index. Khi cần xem log trực tiếp:

```powershell
cd auth_backend
npm start
```

```powershell
Invoke-RestMethod http://127.0.0.1:5001/api/health
```

Kết quả thành công có `success: true` và `data.service: fruitopia-auth`.
`lib/services/auth_api_service.dart` chuẩn bị việc gửi JSON, Bearer token và
xử lý lỗi/timeout. Địa chỉ Windows mặc định là
`http://127.0.0.1:5001/api/auth`; Android Emulator dùng `10.0.2.2` nếu không
đặt AUTH_API_URL. Client chưa được nối vào các màn hình trong commit 0.

Launcher không dừng tiến trình không thuộc thư mục này. Nếu cổng 5001 đang được
dùng bởi backend ở một workspace khác, hãy chạy phiên bản này sau khi dừng
backend đó trong terminal tương ứng. Cấu hình HTTP local dành cho phát triển.
