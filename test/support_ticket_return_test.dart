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
}
