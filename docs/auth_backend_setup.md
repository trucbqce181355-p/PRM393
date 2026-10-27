# Fruitopia Auth — Windows và Android

## Những bước người dùng sử dụng

- Đăng ký tài khoản: email → OTP email → họ tên/số điện thoại/mật khẩu → đăng nhập.
- Đăng nhập tài khoản: email và mật khẩu. Server kiểm tra mật khẩu và trạng thái khóa.
- Đăng nhập Google: trình duyệt Google → trở lại app → hoàn tất hồ sơ nếu cần.
- Google trùng email: tài khoản mới đã xác minh email trên backend tự liên kết;
  tài khoản MongoDB cũ chưa có bằng chứng xác minh trên server yêu cầu nhập mật khẩu
  cũ một lần, theo lựa chọn đã được người dùng xác nhận. Lần đăng nhập Google tiếp
  theo dùng liên kết đã lưu. Hồ sơ Google cũ có ID đúng bằng Supabase user ID được
  nhận diện qua danh tính đã xác minh đó.

Luồng Google không dùng pendingEmail, OTP hoặc registrationToken của luồng đăng ký.
Hồ sơ Google mới vẫn có các trường cá nhân và thiết lập mật khẩu như giao diện
hiện tại, để sau đó dùng được cả Google lẫn đăng nhập tài khoản. Hồ sơ đã có mật
khẩu giữ nguyên mật khẩu đó; bước cập nhật hồ sơ không được ghi đè mật khẩu cũ.

## Cách chạy trên máy hiện tại

MongoDB local phải đang chạy. Từ thư mục `PRM393`, chạy `run.bat`, hoặc chọn cấu
hình **Fruitopia (Windows)** trong VS Code. Có thể mở `Fruitopia.code-workspace`
trong repo để dùng đúng cấu hình chạy sau khi clone. Cả hai gọi `start-auth.js` để mở
backend auth ẩn trên port 5001, kiểm tra health rồi chạy app. Không cần ATL.
Launcher dùng fingerprint source để phát hiện backend cũ sau khi sửa/merge code;
chỉ restart tiến trình được launcher ghi nhận là do nó tạo. Process không thuộc
launcher cần được dừng trong terminal tương ứng trước khi chạy lại.

### Google xác nhận thành công nhưng app báo không kết nối máy chủ

Google/Supabase và backend auth local là hai dịch vụ riêng. Sau khi nhận phiên
Google, app gọi `POST /api/auth/google` trên backend local để xác minh và lấy
hồ sơ/phiên Fruitopia. Nếu backend cổng 5001 chưa chạy, bước này sẽ thất bại dù
Google đã xác nhận thành công. Backend đơn hàng cổng 5000 không xử lý bước này.

Tất cả cấu hình VS Code nằm trong `PRM393/.vscode`. Mở thư mục `PRM393`
hoặc file `PRM393/Fruitopia.code-workspace` để VS Code dùng đúng cấu hình.
Chọn **Fruitopia (Windows)** trong Run and Debug rồi F5;
chạy `main.dart` trực tiếp hoặc `flutter run` thủ công không đảm bảo chạy preLaunchTask.

Để khôi phục app đang mở, chạy `node start-auth.js` tại thư mục `PRM393`, rồi
bấm **Thử lại** trên app. Không cần xác nhận Google lại nếu phiên Google vẫn
còn hiệu lực. Kiểm tra backend bằng:

```powershell
Invoke-RestMethod http://127.0.0.1:5001/api/health
```

Kết quả phải có `success: true` và `data.service: fruitopia-auth`. Nếu launcher
báo lỗi, xem `auth-backend.stderr.log`; kiểm tra MongoDB local và `.env`. Launcher
phải thành công trước khi chạy app; không chọn Debug Anyway khi preLaunchTask lỗi.

Backend phải có quyền kết nối HTTPS ra Supabase. Ngày 14/10 đã xác định một
tiến trình backend khởi động trong sandbox bị chặn mạng (`EACCES`), dù health
local vẫn thành công. Đã khởi động lại ngoài sandbox và kiểm tra route Google
gọi được Supabase (token thử không hợp lệ được từ chối đúng với 401). Khi tự chạy
trong VS Code/terminal Windows bình thường, không có giới hạn sandbox của công cụ.
Lỗi mạng/timeout hoặc Supabase quá tải nay trả lỗi dịch vụ riêng; không coi là
token Google hết hạn. Log chỉ ghi route, loại lỗi và mã lỗi, không ghi token.

Backend xác thực nằm tại `auth_backend/`. Backend đơn hàng/sản phẩm đã được chuyển
vào `backend/` trong cùng repo `PRM393`, vẫn dùng port 5000; backend auth không thay thế
các API đơn hàng đó.

Chạy backend đơn hàng/sản phẩm bằng `npm start` từ `PRM393/backend` khi cần.
File `.env` và `node_modules` hiện tại đã được chuyển cùng thư mục; các file này
được Git bỏ qua. Khi clone mới, chạy `npm ci` trong `backend` và tạo `.env` local.
`run.bat` và task **Fruitopia Auth backend** vẫn chỉ khởi động backend xác thực.

SMTP đã được chuyển từ file cấu hình app sang `auth_backend/.env` local; file này
được Git bỏ qua. Client không chứa SMTP password hoặc logic xác minh OTP nữa.

## Thiết lập cho thành viên khác

Yêu cầu Node.js 22 trở lên, Flutter, MongoDB và công cụ build Windows hiện có.

```powershell
cd PRM393\auth_backend
npm ci
Copy-Item .env.example .env
```

Điền MongoDB URI/database, Supabase URL/publishable key và Gmail SMTP account/app
password trong `.env`. Không dùng `service_role` hoặc OAuth client secret trong
client Flutter. Supabase URL/key trên server phải thuộc cùng project với app.
File `.env` không được commit. Sau khi đổi cấu hình `.env`, restart backend.

Tạo `PRM393/supabase.env.json` từ `supabase.env.example.json`. Chỉ cần Supabase
URL/key và AUTH_API_URL của app. Windows local mặc định
`http://127.0.0.1:5001/api/auth`. Để dùng Android Emulator, bỏ AUTH_API_URL để
app chọn `http://10.0.2.2:5001/api/auth`, hoặc điền đúng địa chỉ đó. Thiết bị
Android thật cần địa chỉ server nó có thể truy cập; mặc định server chỉ bind
loopback để phục vụ phát triển trên Windows.

Để chạy backend trực tiếp và xem log:

```powershell
cd PRM393\auth_backend
npm start
```

`npm run dev` dùng Node watch để restart khi sửa source. App Flutter vẫn cần
`--dart-define-from-file=supabase.env.json` khi không chạy qua run.bat/VS Code.

## Dữ liệu và phiên

`users.id` là ID nghiệp vụ cố định. Backend không thay ID cũ bằng Supabase UID.
`supabaseUserId` là liên kết riêng tới danh tính Google đã xác minh. Email được
trim và lowercase trong `emailNormalized`; unique index ngăn hai tài khoản
đang hoạt động cùng email, cả khi yêu cầu chạy đồng thời. Không áp dụng quy tắc
bỏ dấu chấm hoặc bỏ phần +tag của Gmail.

Khi startup, backend kiểm tra email/ID không hợp lệ hoặc trùng trước khi bổ sung
emailNormalized/identityActive và tạo index. Nếu có xung đột, backend dừng và
yêu cầu kiểm tra dữ liệu; không tự xóa, đổi ID hay gộp đơn hàng.

```powershell
cd PRM393\auth_backend
npm run check-users
```

Lần kiểm tra MongoDB local hiện tại: 2 hồ sơ, không phát hiện email hoặc ID trùng.
Đã bổ sung trường định danh/index khi khởi động backend; ID, đơn hàng, quyền và
mật khẩu của dữ liệu thật được giữ. Các DB kiểm thử dùng tên riêng
`fruitopia_auth_test_<random>` và chỉ xóa chính database tạm đó.

Mật khẩu mới dùng scrypt với salt ngẫu nhiên. Mật khẩu SHA-256/plaintext cũ được
kiểm tra trên server và nâng cấp sau khi người dùng chứng minh mật khẩu đúng.
Giá trị hash không được dùng thay mật khẩu, không trả về API và không lưu Hive.

Server cấp token ngẫu nhiên 256 bit, chỉ lưu hash token trong auth_sessions.
Mỗi API được bảo vệ kiểm tra token, thời hạn và tài khoản trong MongoDB. Phiên
mặc định 7 ngày, có thể thu hồi khi đăng xuất. App lưu token trong Windows
Credential Manager hoặc Android Keystore (AES-GCM), không lưu user ID làm
bằng chứng đăng nhập. Phiên saved_session_user_id cũ bị bỏ; người dùng cần đăng
nhập lại một lần sau nâng cấp. Mất kết nối server không cấp phiên offline từ Hive.
Token trong bộ nhớ chỉ phục vụ các API auth mới; API backend đơn hàng cũ chưa
được tích hợp middleware này.

Supabase OAuth session chỉ tồn tại trong bộ nhớ trong lần chạy app; SDK được
cấu hình EmptyLocalStorage để không lưu access/refresh token Google vào
SharedPreferences. Phiên OAuth plaintext cũ của project được bỏ khi nâng cấp.
Phiên backend trong kho hệ điều hành vẫn khôi phục đăng nhập Google sau khi mở
lại app. PKCE callback giữ cơ chế xử lý của Supabase SDK.

## OTP và giới hạn

| Thiết lập | Mặc định |
| --- | --- |
| OTP_TTL_SECONDS | 300 giây |
| OTP_MAX_ATTEMPTS | 5 lần |
| OTP_RESEND_SECONDS | 60 giây |
| Proof sau xác minh OTP | 10 phút, dùng một lần |
| SESSION_TTL_SECONDS | 604800 giây |

Giới hạn gửi OTP và đăng nhập được lưu MongoDB, theo cả email và IP, nên restart
server không reset ngay giới hạn. Giới hạn số lần thử OTP dùng update nguyên tử;
gửi nhiều yêu cầu đồng thời không vượt quá 5 lần. Gửi lại thành công hủy mã/proof
cũ. Server luôn kiểm tra expiresAt, không phụ thuộc thời điểm MongoDB TTL cleanup.

Một lần đăng ký thành công tiêu thụ proof. Nếu phản hồi bị mất sau khi server
đã tạo tài khoản, dùng email/mật khẩu vừa thiết lập để đăng nhập; submit lại
proof không tạo tài khoản thứ hai.

## API auth

| API | Quyền |
| --- | --- |
| POST /api/auth/otp/request | Email hợp lệ, có giới hạn gửi |
| POST /api/auth/otp/verify | Challenge ID và OTP |
| POST /api/auth/register | Proof OTP còn hiệu lực |
| POST /api/auth/login | Mật khẩu đúng trên server |
| POST /api/auth/google | Supabase access token được getUser xác minh; mật khẩu cũ khi cần liên kết |
| GET /api/auth/session | Backend session token |
| PATCH /api/auth/profile | Backend session token, chỉ cập nhật hồ sơ của chính chủ |
| POST /api/auth/logout | Thu hồi backend token, kể cả tài khoản đã khóa |
| GET /api/auth/customers | Admin đã xác thực |
| PATCH /api/auth/customers/:id/status | Admin đã xác thực |

Ghi MongoDB thất bại trả lỗi; app chỉ cập nhật hồ sơ/status sau khi API trả thành
công. Việc tạo/sửa sản phẩm và voucher cũ trong DataService không thuộc lần sửa
auth này và vẫn cần một lần rà soát riêng nếu muốn thay chính sách offline.

Không còn admin password viết cứng hoặc admin session tạo từ user ID local.
Tài khoản admin phải tồn tại trong MongoDB với role admin và mật khẩu hợp lệ.
Nếu cần tạo admin cho môi trường mới, đặt ADMIN_EMAIL/ADMIN_PASSWORD mạnh trong
`.env`, chạy `node create-admin.js`, rồi bỏ ADMIN_PASSWORD khỏi file. Script
không ghi đè hoặc nâng quyền một email đang tồn tại. Không chạy script này trên
dữ liệu chung khi chưa thống nhất với nhóm.

## Lịch sử kiểm tra trước khi dọn code

Theo yêu cầu dọn code, các file test Flutter/backend/native do phần auth tạo ra
đã được xóa, cùng script `npm test` và target CMake `auth_storage_test`.
Các kết quả dưới đây là lịch sử kiểm tra trước khi xóa, không phải bộ test còn
có thể chạy trong repo. Lần sửa kết nối Supabase cuối cùng có 21 test backend đạt.
`check-users.js` và `create-admin.js` vẫn là công cụ vận hành, không phải mock data.

- Backend: 18 test đạt, dùng MongoDB tạm thật và SMTP/Google verifier giả lập.
  Bao phủ OTP expiry/thử sai/gửi lại/đồng thời, proof một lần, liên kết legacy có
  mật khẩu, giữ ID/dữ liệu, callback Google đồng thời, password migration,
  session giả/hết hạn/khóa/revoke, cập nhật profile đồng thời và lỗi DB trả 503.
- Flutter: 14 test đạt, giả lập HTTP và native storage channel. Kiểm tra nguồn
  định danh server, cache/user ID giả, lỗi server, Google profile sau restore,
  proof OTP, cập nhật profile và rời màn hình OTP khi request đang chờ.
- Windows debug build thành công. Native storage test dùng đúng channel code
  và Credential Manager thật: read/write/overwrite/reject-empty/delete đạt.
  Credential test có namespace riêng Fruitopia.NativeStorageRegressionTest;
  không truy cập credential Fruitopia/AuthSession/v1 của app.
- Backend khởi động với cấu hình local, health check đạt. Không gửi email OTP
  thật và không đăng nhập Google thật trong bộ test.
- Analyzer không có error; toàn dự án còn 5 warning và 50 info, chủ yếu ở các
  màn hình/API cũ. Các file auth và test mới không có chẩn đoán. git diff --check đạt.
- Android Keystore đã triển khai nhưng chưa kiểm thử trên thiết bị Android.

Vẫn cần thử thủ công một lần: đăng ký email thật, Google mới, Google cùng email
tài khoản cũ với mật khẩu đúng/sai, tắt/mở app, đổi tài khoản và đăng xuất. Khi
triển khai ra mạng, dùng HTTPS và MongoDB có xác thực/quyền truy cập phù hợp;
cấu hình HTTP/loopback hiện tại dành cho phát triển local. Quyền admin của các
API sản phẩm/đơn hàng ngoài backend auth mới chưa được bảo vệ bởi middleware mới.

Tham khảo: [Supabase getUser](https://supabase.com/docs/reference/javascript/auth-getuser),
[MongoDB unique indexes](https://www.mongodb.com/docs/manual/core/index-unique/),
[Windows CredWrite](https://learn.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credwritew),
[Android Keystore](https://developer.android.com/privacy-and-security/keystore).
