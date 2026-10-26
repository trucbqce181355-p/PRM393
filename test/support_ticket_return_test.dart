import 'package:flutter_test/flutter_test.dart';
import 'package:traicay/models/return_request.dart';
import 'package:traicay/services/data_service.dart';

void main() {
  setUp(() {
    DataService.returnRequests.clear();
  });

  group('Quản lý Hỗ trợ - UC 80: Tạo yêu cầu hỗ trợ khách hàng', () {
    test('Gửi yêu cầu hỗ trợ kỹ thuật / thắc mắc dịch vụ thành công', () async {
      final req = ReturnRequest(
        id: 'ticket_001',
        orderId: 'ORD_SUPPORT_123',
        customerEmail: 'support_user@fruit.vn',
        customerName: 'Trần Văn Hỗ Trợ',
        reason: 'Hỗ trợ thay đổi địa chỉ giao hàng',
        description: 'Tôi muốn đổi địa chỉ giao sang số 15 Lê Duẩn, Q1 do chuyển chỗ làm việc.',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await DataService.addReturnRequest(req);

      expect(DataService.returnRequests.length, 1);
      final saved = DataService.returnRequests.first;
      expect(saved.id, 'ticket_001');
      expect(saved.reason, 'Hỗ trợ thay đổi địa chỉ giao hàng');
      expect(saved.status, 'pending');
    });
  });

  group('Quản lý Đổi trả - UC 81: Gửi yêu cầu đổi trả sản phẩm', () {
    test('Khách hàng gửi yêu cầu đổi trả kèm đơn hàng và hình ảnh sản phẩm hỏng', () async {
      final req = ReturnRequest(
        id: 'ret_001',
        orderId: 'ORD_999',
        customerEmail: 'customer@fruit.vn',
        customerName: 'Nguyễn Văn Mua',
        reason: 'Trái cây bị dập nát khi vận chuyển',
        description: 'Khi mở hộp thì thấy 2 quả xoài bị dập và chảy nước.',
        imageUrl: 'https://storage.fruitopia.vn/returns/mango_damaged.jpg',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await DataService.addReturnRequest(req);

      expect(DataService.returnRequests.length, 1);
      final r = DataService.returnRequests.first;
      expect(r.id, 'ret_001');
      expect(r.orderId, 'ORD_999');
      expect(r.imageUrl, contains('mango_damaged.jpg'));
      expect(r.status, 'pending');
    });

    test('Admin phê duyệt yêu cầu đổi trả sản phẩm', () async {
      final req = ReturnRequest(
        id: 'ret_002',
        orderId: 'ORD_888',
        customerEmail: 'user_claim@fruit.vn',
        customerName: 'Lê Văn Khách',
        reason: 'Giao nhầm loại táo',
        description: 'Tôi đặt Táo Envy nhưng nhận Táo Rockit.',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await DataService.addReturnRequest(req);

      // Admin duyệt đổi hàng mới
      await DataService.replyReturnRequest(
        requestId: 'ret_002',
        status: 'approved',
        reply: 'Fruitopia xin lỗi vì sự bất tiện này. Chúng tôi sẽ giao lại đúng Táo Envy trong 2 giờ.',
      );

      final updated = DataService.returnRequests.firstWhere((r) => r.id == 'ret_002');
      expect(updated.status, 'approved');
      expect(updated.adminReply, contains('Chúng tôi sẽ giao lại đúng Táo Envy'));
    });

    test('Admin từ chối yêu cầu đổi trả kèm lý do phản hồi', () async {
      final req = ReturnRequest(
        id: 'ret_003',
        orderId: 'ORD_777',
        customerEmail: 'user_reject@fruit.vn',
        customerName: 'Hoàng Văn C',
        reason: 'Đổi ý không muốn mua nữa',
        description: 'Đã nhận hàng 4 ngày trước nay muốn trả lại.',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await DataService.addReturnRequest(req);

      // Admin từ chối do quá hạn 24h
      await DataService.replyReturnRequest(
        requestId: 'ret_003',
        status: 'rejected',
        reply: 'Rất tiếc chính sách đổi trả của shop chỉ áp dụng trong vòng 24h kể từ khi nhận hàng.',
      );

      final updated = DataService.returnRequests.firstWhere((r) => r.id == 'ret_003');
      expect(updated.status, 'rejected');
      expect(updated.adminReply, contains('chỉ áp dụng trong vòng 24h'));
    });
  });
}
