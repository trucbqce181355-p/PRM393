# Báo cáo rà soát đăng ký, đăng nhập Fruitopia — 14/10/2026

> Đây là báo cáo của phiên bản trước khi triển khai backend auth. Các vấn đề OTP,
> hồ sơ Google, định danh trùng email, phiên local và lỗi ghi hồ sơ đã được xử lý
> trong lần triển khai tiếp theo. Xem [hướng dẫn và trạng thái hiện tại](auth_backend_setup.md).

## Phạm vi và kết luận

Rà soát working tree chưa commit của dự án Flutter `PRM393`, tập trung vào
AuthRepository, AuthService, Customer, DataService, các màn hình xác thực,
sửa hồ sơ, đăng xuất và Windows OAuth runner. Đã đối chiếu thay đổi Git,
chạy kiểm tra tĩnh, test hồi quy và build Windows debug.

Giữ luồng hiện tại: đăng ký bằng email → OTP email → điền hồ sơ/mật khẩu;
đăng nhập bằng tài khoản local hoặc Google OAuth qua Supabase. Không chuyển
tài khoản local sang Supabase Auth và không tự gộp tài khoản trùng email.

Các lỗi kỹ thuật bên dưới đã được sửa. Tuy nhiên, chưa nên merge bản này như
một tính năng xác thực đã hoàn tất: đường hoàn tất hồ sơ Google và định danh
trùng email còn vấn đề chức năng; cách xác thực phía client còn rủi ro bảo mật.
Build thành công chỉ chứng minh mã biên dịch được, không chứng minh Google,
SMTP và MongoDB vận hành đúng trong môi trường của mọi thành viên.

## Những lỗi đã sửa

| Lỗi | Thay đổi |
| --- | --- |
| Sửa hồ sơ hoặc khóa/mở khóa tạo Customer mới nhưng bỏ mất passwordHash | Giữ passwordHash khi cập nhật; test kiểm tra cả dữ liệu Hive và thông tin tích lũy. |
| Hồ sơ không có mật khẩu local vẫn được chấp nhận với mật khẩu bất kỳ | Chỉ tạo phiên local khi mật khẩu khớp; hồ sơ OAuth phải qua xác thực Supabase. |
| Sửa hồ sơ local gọi updateUser dù không có phiên Supabase; ghi MongoDB hai lần | Dùng một đường AuthService → AuthRepository → DataService; nhánh local không gọi Supabase. |
| AuthService ưu tiên user Supabase hơn phiên local, có thể lấy ID/email của tài khoản khác | Ưu tiên hồ sơ của phiên local đang hoạt động; lấy dữ liệu mới nhất từ cache theo ID. Điều này chưa giải quyết hoàn toàn việc hai phiên cùng tồn tại. |
| Google có thể dùng Supabase UID để cập nhật một hồ sơ mang ID local nên cập nhật không tác dụng | Khi sửa hồ sơ, dùng ID của hồ sơ đã tìm thấy. Không đổi ID hoặc gộp dữ liệu. |
| Tài khoản local bị khóa vẫn có thể được khôi phục khi mở app | Kiểm tra isActive trong cache khi restore; bỏ phiên đã lưu nếu tài khoản bị khóa. |
| setState sau khi màn hình OTP đã bị dispose | Kiểm tra mounted ngay sau khoảng chờ xác minh. |
| Auto-submit OTP và nút xác nhận có thể chạy đồng thời | Thêm guard chống gọi lặp ở OTP, đăng nhập, đăng ký và lưu hồ sơ. |
| Controller login không được dispose; controller email hồ sơ được tạo lại mỗi build | Dispose controller login; dùng initialValue cho trường email chỉ đọc. |
| Dùng context sau await đăng xuất | Thêm kiểm tra context.mounted. |
| Đồng bộ MongoDB bỏ mất hạng thành viên | Đọc memberTier khi nạp hồ sơ. |
| Thông tin SMTP nằm trực tiếp trong source | Chuyển sang SMTP_USERNAME/SMTP_PASSWORD trong file cấu hình local đang được Git bỏ qua. |
| OTP được tạo bằng Random thông thường; giữ trạng thái mới dù gửi email lỗi | Dùng Random.secure; chỉ ghi nhận email/mã sau khi gửi thành công; xóa trạng thái OTP sau đăng ký thành công. |
| Widget test vẫn kiểm tra counter của template Flutter | Thay bằng kiểm tra màn hình cấu hình và lỗi rời màn hình OTP. |

Thông tin SMTP local hiện được giữ trong `supabase.env.json`, không đưa vào báo cáo.
`run.bat` và `.vscode/launch.json` đã truyền `--dart-define-from-file=supabase.env.json`.
Thành viên khác cần tự tạo file từ `supabase.env.example.json` và điền cấu hình.
Chạy `flutter run` không truyền file sẽ không có cấu hình SMTP.

## Rủi ro còn lại, theo mức ưu tiên

### 1. Cao — Hồ sơ Google đang đi vào hàm đăng ký bằng OTP

`lib/screens/auth/auth_gate.dart` chuyển user chưa có profile_completed sang
ProfileSetupScreen. `lib/screens/auth/profile_setup_screen.dart` gọi
AuthService.completeRegistration, trong khi hàm này lấy email từ pendingEmail
của bước OTP, không lấy email của phiên Google.

Khi mở app mới và đăng nhập Google lần đầu, pendingEmail không tồn tại nên
hoàn tất hồ sơ báo thiếu email. Nếu trạng thái đăng ký khác vẫn còn, có nguy cơ
dùng email đó để tạo ID local mới. Nhánh này cũng chưa đánh dấu profile_completed
cho phiên Google. Cần tách xử lý lưu hồ sơ của phiên Google bên trong service,
vẫn giữ các bước giao diện đã thống nhất. Chưa sửa vì việc Google có cần tạo
mật khẩu local hay chỉ hoàn tất hồ sơ chưa được thể hiện rõ và thống nhất trong code.

### 2. Cao — Trùng email và hai hệ định danh

`lib/services/data_service.dart:addCustomer` thay hồ sơ trong memory/Hive theo
email hoặc ID, nhưng MongoDB tìm bằng email chính xác và chỉ cập nhật tên/phone.
ID local có thể bị thay bằng ID mới trong cache trong khi MongoDB giữ ID cũ.
Việc findOne rồi insertOne không bảo đảm chống đăng ký đồng thời; khác biệt chữ
hoa/thường cũng có thể vượt qua bước tìm MongoDB.

Không có logic tạo/kiểm tra unique index trong phần code đã rà soát; chưa kiểm tra
index hoặc dữ liệu trên MongoDB thực tế. Cần chuẩn hóa email, kiểm tra index,
giữ ID hồ sơ nhất quán và chốt quy tắc liên kết tài khoản. Không tự gộp hoặc xóa
bản ghi vì có thể ảnh hưởng dữ liệu các thành viên khác sử dụng.

### 3. Cao — OTP được xác minh hoàn toàn trong app

`lib/services/auth_service.dart:verifyOtp` không có thời điểm hết hạn hoặc giới
hạn số lần thử. Countdown 60 giây trên màn hình chỉ giới hạn nút gửi lại.
completeRegistration cũng chưa kiểm tra một trạng thái xác minh OTP thành công;
luồng bình thường dựa vào điều hướng màn hình để bảo đảm thứ tự.

Cần kiểm tra đã xác minh tại service, thêm chính sách hết hạn/số lần thử và,
trước khi phát hành, để server quyết định xác minh. Có thể giữ nguyên trải nghiệm
email → OTP → hồ sơ. Chưa tự chọn các giới hạn thời gian/số lần thử vì đó là chính
sách cần được nhóm chốt.

### 4. Cao — Phiên local và quyền admin có thể bị giả mạo

`lib/repositories/auth_repository.dart` lưu saved_session_user_id trong
SharedPreferences rồi khôi phục theo ID. Đây không phải token được server ký;
không có hết hạn hoặc xác minh server. Nhánh admin có thông tin đăng nhập viết
cứng và khôi phục bằng một ID cố định. Người kiểm soát máy khách có thể sửa
local state; kiểm tra isActive đã thêm vẫn chỉ dựa trên cache.

Mã client cũng nạp toàn bộ users và passwordHash từ MongoDB về Hive. Không nên
để server tin customerId hoặc role do client cung cấp khi cho phép truy cập dữ liệu.
Cần xác thực/ủy quyền phía backend trước khi phát hành cho người dùng thật.

### 5. Cao — Mật khẩu và thông tin gửi email vẫn có giới hạn bảo mật

Mật khẩu local dùng SHA-256 không salt, đồng thời vẫn hỗ trợ giá trị plaintext cũ.
Đây là cách lưu và so sánh hiện tại; chưa thay thuật toán vì cần chuyển đổi dữ liệu
để giữ khả năng đăng nhập của tài khoản cũ.

Đưa thông tin SMTP ra khỏi source giảm nguy cơ push lên Git, nhưng dart-define
được biên dịch vào client. Người nhận executable vẫn có thể trích xuất thông tin.
Cần chuyển gửi email về backend trước khi phân phối app. Không đưa file local,
OAuth client-secret hoặc khóa server vào commit.

### 6. Trung bình — Thông báo thành công khi MongoDB đã thất bại

DataService ghi cache trước rồi catch lỗi MongoDB và chỉ print. Đăng ký hoặc sửa
hồ sơ có thể báo thành công nhưng dữ liệu chỉ tồn tại trên máy hiện tại. Khi chạy
trên máy khác hoặc đồng bộ lại, tài khoản có thể không tồn tại hoặc dữ liệu quay
về bản cũ. Chưa có hàng đợi retry/đánh dấu chưa đồng bộ.

Cần chốt việc có cho đăng ký offline hay không. Nếu có, cần lưu trạng thái chờ
đồng bộ và retry; nếu không, cần trả lỗi khi ghi MongoDB thất bại. Chưa đổi hành vi
này vì có thể thay chính sách offline của nhóm.

### 7. Trung bình — Phiên Google/local và tài khoản bị khóa

Phiên local và Supabase có thể tồn tại đồng thời. Đã sửa việc đọc hồ sơ ưu tiên
sai, nhưng vẫn cần bảo đảm chỉ một phiên là phiên đang hoạt động. Đường Google
qua AuthGate chưa chặn hồ sơ có isActive=false. Tài khoản khóa trên máy khác có
thể vẫn dùng cache cũ; app hiện chỉ đồng bộ users khi khởi động.

### 8. Trung bình — Đăng xuất và khôi phục admin

Nút đăng xuất trong `lib/screens/admin/admin_dashboard_screen.dart` chỉ điều
hướng về UserHomeScreen, không gọi signOut. AuthGate khôi phục admin_user cũng
đưa vào trang user vì chưa phân nhánh admin. Cần kiểm tra cùng người phụ trách
admin để sửa nhất quán với cơ chế phân quyền chung.

### 9. Thấp — Stream và xử lý lỗi cần cải thiện

AuthGate tạo lại stream/future trong build, có thể đọc hồ sơ lại khi widget được
rebuild. Một số catch bỏ qua lỗi khiến khó phân biệt sai mật khẩu, mất mạng,
lưu phiên thất bại và lỗi dữ liệu. Có các helper public chưa có nơi gọi như
registerCustomer; nên rà soát hợp đồng API với nhóm trước khi xóa.

## Kết quả kiểm tra tự động

- `flutter test --no-pub`: **8/8 test đạt**. Bao phủ giữ hash/thông tin tích lũy
  khi sửa hồ sơ, khóa/mở khóa, sai mật khẩu, hồ sơ thiếu mật khẩu local, restore
  tài khoản khóa, sửa hồ sơ local không có Supabase, màn hình cấu hình và rời OTP.
- Test sử dụng Hive trong thư mục tạm và SharedPreferences giả lập; không kết
  nối MongoDB, không gửi email và không đăng nhập tài khoản Google thực.
  Log MongoDB chưa kết nối là nhánh fallback được chủ động chạy trong test.
- `flutter analyze --no-pub`: không có error; **5 warning và 54 info** ở toàn
  dự án. Lệnh trả exit code 1 vì còn các chẩn đoán. Chủ yếu import/element không
  dùng, API deprecated, print và context sau await ở màn hình ngoài auth.
- `flutter build windows --debug --no-pub --dart-define-from-file=supabase.env.json`:
  build thành công. Đây là kiểm tra biên dịch, không phải kiểm thử UI hay OAuth thực tế.
- `git diff --check`: đạt sau dọn khoảng trắng cuối file.
- `git check-ignore supabase.env.json`: xác nhận file cấu hình local được bỏ qua.

## Các trường hợp cần kiểm thử tích hợp trước khi merge

| Trường hợp | Kết quả cần đạt |
| --- | --- |
| Đăng ký email mới, OTP đúng, điền hồ sơ, tắt/mở app, đăng nhập trên máy thứ hai | Một hồ sơ có ID nhất quán, dữ liệu được lưu MongoDB, đăng nhập đúng mật khẩu. |
| OTP sai, hết hạn, gửi lại, quay lại sửa email, nhấn xác nhận nhanh nhiều lần | Mã gắn với đúng email, không dùng lại mã cũ, không tạo hồ sơ lặp. |
| Google lần đầu, đăng nhập lại, hủy ở trình duyệt, tài khoản cùng email với local | Không dùng pendingEmail của đăng ký khác; không mất hồ sơ hoặc tạo ID lệch. |
| OAuth callback khi app đang mở, đã đóng, hoặc hai cửa sổ đang chạy | Callback tới đúng instance; không mất hoặc nhầm phiên. |
| Đăng xuất rồi đổi giữa tài khoản local và Google | Tên/email/ID luôn thuộc tài khoản vừa đăng nhập; phiên cũ không xuất hiện lại. |
| Sửa hồ sơ, đóng/mở app, kiểm tra MongoDB và đăng nhập lại | Tên/phone mới và mật khẩu cũ được giữ; không báo thành công nếu yêu cầu bắt buộc chưa lưu. |
| Khóa tài khoản, đăng nhập local/Google, khôi phục phiên cũ | Áp dụng cùng một chính sách khóa cho mọi đường vào app. |
| Tắt MongoDB, mất mạng/SMTP lỗi, Hive hỏng | Có lỗi hoặc trạng thái offline rõ ràng, không tạo dữ liệu khác nhau giữa các máy. |
| Đăng xuất admin và khôi phục admin sau khởi động | Đăng xuất xóa phiên; khôi phục điều hướng theo quyền được xác minh. |

## Lưu ý khi chuẩn bị commit và merge

Working tree đang có nhiều thay đổi thuộc auth, profile, home, dependency và
Windows runner; cần xem diff theo file trước khi stage. Những file mới như
repositories/config/AuthGate phải được đưa vào commit cùng nơi import chúng.
Không stage file cấu hình local. Các file `.dart_tool` và build không cần commit.

Tài liệu setup cũ còn mô tả Phone OTP và một số hành vi profile trước đây; cần
đồng bộ lại sau khi nhóm chốt Google/profile và liên kết email. Chưa commit,
push, merge hoặc thay dữ liệu MongoDB/Supabase trong lần rà soát này.
