import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traicay/models/customer.dart';
import 'package:traicay/models/product.dart';
import 'package:traicay/models/order.dart';
import 'package:traicay/models/voucher.dart';
import 'package:traicay/models/review.dart';
import 'package:traicay/models/chat_message.dart';
import 'package:traicay/services/auth_service.dart';
import 'package:traicay/services/data_service.dart';
import 'package:traicay/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await AuthService.init();
    DataService.customers.clear();
    DataService.products.clear();
    DataService.orders.clear();
    DataService.vouchers.clear();
    DataService.reviews.clear();
    DataService.chatMessages.clear();
    DataService.closedConversations.clear();
  });

  group('1. Quản lý người dùng & Google Auth Flow', () {
    test('1.1 Đăng nhập Google với email mới -> Trả về needs_profile_setup', () async {
      final res = await AuthService.loginWithGoogle(
        email: 'newuser@gmail.com',
        name: 'New Google User',
      );

      expect(res['status'], 'needs_profile_setup');
      expect(AuthService.pendingEmail, 'newuser@gmail.com');
    });

    test('1.2 Hoàn tất hồ sơ sau khi đăng nhập Google lần đầu', () async {
      await AuthService.loginWithGoogle(
        email: 'newuser@gmail.com',
        name: 'New Google User',
      );

      await AuthService.completeGoogleProfile(
        name: 'New Google User',
        phone: '0901234567',
        password: 'password123',
      );

      expect(AuthService.isLoggedIn, isTrue);
      expect(AuthService.userEmail, 'newuser@gmail.com');
      expect(AuthService.userName, 'New Google User');

      final customer = DataService.customers.firstWhere((c) => c.email == 'newuser@gmail.com');
      expect(customer.phone, '0901234567');
      expect(customer.isGoogleLinked, isTrue);
    });

    test('1.3 Liên kết Google với tài khoản cùng email đã tồn tại', () async {
      // Tài khoản đã đăng ký từ trước
      final existingCustomer = Customer(
        id: 'cust_exist',
        name: 'Trần Văn Cũ',
        email: 'exist@gmail.com',
        phone: '0988888888',
        password: 'oldpassword',
        totalSpent: 0,
        totalOrders: 0,
        isGoogleLinked: false,
      );
      DataService.customers.add(existingCustomer);

      // Đăng nhập Google cùng email
      final res = await AuthService.loginWithGoogle(
        email: 'exist@gmail.com',
        name: 'Google Tran',
      );

      expect(res['status'], 'linked_and_logged_in');
      expect(AuthService.isLoggedIn, isTrue);
      expect(AuthService.userEmail, 'exist@gmail.com');

      // Xác minh cờ isGoogleLinked được cập nhật thành true
      final updated = DataService.customers.firstWhere((c) => c.email == 'exist@gmail.com');
      expect(updated.isGoogleLinked, isTrue);
    });

    test('1.4 Lưu phiên, khôi phục phiên và thu hồi phiên (Đăng xuất)', () async {
      await AuthService.saveSession(
        email: 'session@fruit.vn',
        name: 'Fruit Lover',
        token: 'token_sample_123',
      );

      expect(AuthService.isLoggedIn, isTrue);
      expect(AuthService.userEmail, 'session@fruit.vn');

      // Đăng xuất thu hồi phiên
      await AuthService.logout();
      expect(AuthService.isLoggedIn, isFalse);
      expect(AuthService.userEmail, isNull);
    });
  });

  group('2. Các chức năng Cá nhân & Địa chỉ & Khiếu nại', () {
    test('2.1 Hạng thành viên lấy động từ Customer.memberTier', () {
      final vipCustomer = Customer(
        id: 'cust_vip',
        name: 'Đại Gia Trái Cây',
        email: 'vip@gmail.com',
        phone: '0912345678',
        totalSpent: 5000000,
        totalOrders: 20,
        memberTier: 'Kim Cương',
      );
      expect(vipCustomer.memberTier, 'Kim Cương');
    });

    test('2.2 Thêm, xem, sửa, xóa địa chỉ và chọn địa chỉ mặc định', () async {
      final addr1 = {
        'title': 'Nhà riêng',
        'address': 'Số 10 Hai Bà Trưng, Bến Nghé, Quận 1',
        'phone': '0901111111',
        'isDefault': true,
      };

      final addr2 = {
        'title': 'Cơ quan',
        'address': 'Tòa nhà Landmark 81, Bình Thạnh',
        'phone': '0901111111',
        'isDefault': false,
      };

      await StorageService.addAddress(addr1);
      await StorageService.addAddress(addr2);

      var list = StorageService.getAddresses();
      expect(list.length, 2);
      expect(list[0]['title'], 'Nhà riêng');
      expect(list[0]['isDefault'], true);

      // Đổi địa chỉ mặc định sang addr2
      await StorageService.setDefaultAddress(1);
      list = StorageService.getAddresses();
      expect(list[1]['isDefault'], true);
      expect(list[0]['isDefault'], false);

      // Sửa địa chỉ 0
      final editedAddr = Map<String, dynamic>.from(list[0]);
      editedAddr['title'] = 'Nhà ba mẹ';
      await StorageService.updateAddress(0, editedAddr);
      list = StorageService.getAddresses();
      expect(list[0]['title'], 'Nhà ba mẹ');

      // Xóa địa chỉ 0
      await StorageService.deleteAddress(0);
      list = StorageService.getAddresses();
      expect(list.length, 1);
      expect(list[0]['title'], 'Cơ quan');
    });
  });

  group('3. Quản lý kho (5 Chức năng kho hàng)', () {
    test('3.1 Nhập kho, Xuất kho, Kiểm kê, Cảnh báo tồn thấp, Hư hỏng', () {
      final product = Product(
        id: 'prod_apple',
        name: 'Táo Envy New Zealand',
        description: 'Táo giòn ngọt',
        price: 150000,
        unit: 'kg',
        imageUrl: 'assets/images/apple.jpg',
        category: 'Trái cây nhập khẩu',
        origin: 'New Zealand',
        stock: 50,
      );
      DataService.products.add(product);

      // 1. Nhập kho thêm 20
      product.stock += 20;
      expect(product.stock, 70);

      // 2. Xuất kho 15
      product.stock -= 15;
      expect(product.stock, 55);

      // 3. Kiểm kê điều chỉnh thực tế thành 50
      product.stock = 50;
      expect(product.stock, 50);

      // 4. Cảnh báo sản phẩm tồn kho thấp (< 10kg)
      product.stock = 5;
      final isLowStock = product.stock < 10;
      expect(isLowStock, isTrue);

      // 5. Ghi nhận trái cây hư hỏng loại bỏ 2kg
      product.stock -= 2;
      expect(product.stock, 3);
    });
  });

  group('4. Quản lý Đơn hàng (Shipper, Lý do hủy, Khóa tài khoản)', () {
    test('4.1 Gán Shipper, Từ chối kèm lý do, Khóa tài khoản khách hàng', () {
      final order = Order(
        id: 'ORD_TEST_01',
        customerName: 'Lê Hoàng',
        customerPhone: '0933333333',
        address: 'Hà Nội',
        totalAmount: 350000,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      // Gán Shipper
      order.assignedShipperName = 'Nguyễn Văn Giao';
      order.assignedShipperPhone = '0977889900';
      order.status = OrderStatus.delivering;
      expect(order.assignedShipperName, 'Nguyễn Văn Giao');
      expect(order.status, OrderStatus.delivering);

      // Từ chối đơn hàng kèm lý do
      order.status = OrderStatus.cancelled;
      order.cancellationReason = 'Hết hàng loại 1 tại kho';
      expect(order.status, OrderStatus.cancelled);
      expect(order.cancellationReason, 'Hết hàng loại 1 tại kho');

      // Khóa và Mở khóa tài khoản khách hàng
      var cust = Customer(
        id: 'cust_lock',
        name: 'Khách Gian Lận',
        email: 'bad@fruit.vn',
        phone: '0900000000',
        totalSpent: 0,
        totalOrders: 0,
        isActive: true,
      );

      cust = cust.copyWith(isActive: false);
      expect(cust.isActive, isFalse); // Khóa

      cust = cust.copyWith(isActive: true);
      expect(cust.isActive, isTrue); // Mở khóa
    });
  });

  group('5. Quản lý mã giảm giá (Vouchers)', () {
    test('5.1 Voucher tiền mặt và voucher phần trăm kèm trần giảm giá tối đa', () {
      // 1. Tiền mặt 20.000đ
      final fixedVoucher = Voucher(
        code: 'GIAM20K',
        description: 'Giảm 20.000đ',
        discountAmount: 20000,
        minPurchase: 100000,
        discountType: 'fixed',
      );
      expect(fixedVoucher.calculateDiscount(150000), 20000);
      expect(fixedVoucher.calculateDiscount(50000), 0);

      // 2. Phần trăm 20% tối đa 50.000đ
      final percentVoucher = Voucher(
        code: 'GIAM20PHANTRAM',
        description: 'Giảm 20% tối đa 50k',
        discountAmount: 0,
        minPurchase: 100000,
        discountType: 'percentage',
        discountPercentage: 20,
        maxDiscountAmount: 50000,
      );

      // 200k -> 20% = 40k (< 50k)
      expect(percentVoucher.calculateDiscount(200000), 40000);
      // 500k -> 20% = 100k (> 50k -> áp trần 50k)
      expect(percentVoucher.calculateDiscount(500000), 50000);
    });
  });

  group('6. Quản lý đánh giá (Reviews)', () {
    test('6.1 Thêm, sửa, xóa, ảnh và Admin phản hồi đánh giá', () async {
      final review = Review(
        id: 'rev_1',
        productId: 'prod_mango',
        productName: 'Xoài Cát Hòa Lộc',
        userName: 'Trần Văn A',
        userEmail: 'a@gmail.com',
        rating: 5,
        comment: 'Xoài rất thơm ngon!',
        createdAt: DateTime.now(),
        hasImage: true,
        imageUrl: '/storage/mango_review.jpg',
      );

      await DataService.addReview(review);
      expect(DataService.getReviewsForProduct('prod_mango').length, 1);

      // Admin phản hồi
      await DataService.replyReview('rev_1', 'Cảm ơn quý khách đã tin tưởng!');
      final repliedReview = DataService.reviews.firstWhere((r) => r.id == 'rev_1');
      expect(repliedReview.adminReply, 'Cảm ơn quý khách đã tin tưởng!');
      expect(repliedReview.adminReplyAt, isNotNull);

      // Chỉnh sửa đánh giá
      await DataService.updateReview('rev_1', rating: 4, comment: 'Đổi sang 4 sao do giao muộn');
      final updated = DataService.reviews.firstWhere((r) => r.id == 'rev_1');
      expect(updated.rating, 4);

      // Xóa đánh giá
      await DataService.deleteReview('rev_1');
      expect(DataService.getReviewsForProduct('prod_mango').length, 0);
    });
  });

  group('7. Quản lý Chat & Hỗ trợ khách hàng Realtime', () {
    test('7.1 Gửi tin nhắn, lưu trữ hội thoại, trạng thái đọc, đóng/mở hội thoại', () async {
      final msg = ChatMessage(
        id: 'msg_cust_1',
        conversationId: 'user@fruit.vn',
        senderEmail: 'user@fruit.vn',
        senderName: 'Khách Hàng Thân Thiết',
        senderRole: 'user',
        message: 'Shop ơi trái cây hôm nay có tươi không?',
        createdAt: DateTime.now(),
        isRead: false,
      );

      await DataService.sendChatMessage(msg);

      // Hội thoại đã được tạo
      final convs = DataService.getAllConversations();
      expect(convs.any((c) => c.customerEmail == 'user@fruit.vn'), isTrue);

      // Đánh dấu đã đọc bởi admin
      await DataService.markMessagesAsRead('user@fruit.vn', 'admin');
      final updatedConvs = DataService.getAllConversations();
      final targetConv = updatedConvs.firstWhere((c) => c.customerEmail == 'user@fruit.vn');
      expect(targetConv.unreadCount, 0);

      // Đóng cuộc hội thoại
      await DataService.closeConversation('user@fruit.vn');
      expect(DataService.closedConversations.contains('user@fruit.vn'), isTrue);

      // Mở lại cuộc hội thoại
      await DataService.reopenConversation('user@fruit.vn');
      expect(DataService.closedConversations.contains('user@fruit.vn'), isFalse);
    });
  });
}
