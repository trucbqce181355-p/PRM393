import 'package:flutter_test/flutter_test.dart';
import 'package:traicay/models/chat_message.dart';
import 'package:traicay/services/data_service.dart';

void main() {
  setUp(() {
    DataService.chatMessages.clear();
    DataService.closedConversations.clear();
  });

  group('Quản lý Chat - UC 71: Xem lịch sử tin nhắn', () {
    test('Tải lịch sử tin nhắn theo conversationId chính xác và đúng thứ tự thời gian', () async {
      final t1 = DateTime(2026, 10, 23, 10, 0);
      final t2 = DateTime(2026, 10, 23, 10, 5);
      final t3 = DateTime(2026, 10, 23, 10, 10);

      final msg1 = ChatMessage(
        id: 'm1',
        conversationId: 'user1@fruit.vn',
        senderEmail: 'user1@fruit.vn',
        senderName: 'Khách 1',
        senderRole: 'user',
        message: 'Xin chào shop',
        createdAt: t1,
        isRead: true,
      );

      final msg2 = ChatMessage(
        id: 'm2',
        conversationId: 'user2@fruit.vn',
        senderEmail: 'user2@fruit.vn',
        senderName: 'Khách 2',
        senderRole: 'user',
        message: 'Tôi muốn hỏi giá sầu riêng',
        createdAt: t2,
        isRead: false,
      );

      final msg3 = ChatMessage(
        id: 'm3',
        conversationId: 'user1@fruit.vn',
        senderEmail: 'support@fruitopia.vn',
        senderName: 'CSKH',
        senderRole: 'admin',
        message: 'Chào bạn, shop có thể giúp gì cho bạn?',
        createdAt: t3,
        isRead: true,
      );

      await DataService.sendChatMessage(msg1);
      await DataService.sendChatMessage(msg2);
      await DataService.sendChatMessage(msg3);

      final historyUser1 = DataService.getMessagesForConversation('user1@fruit.vn');
      expect(historyUser1.length, 2);
      expect(historyUser1[0].id, 'm1');
      expect(historyUser1[1].id, 'm3');
      expect(historyUser1[0].message, 'Xin chào shop');
      expect(historyUser1[1].message, 'Chào bạn, shop có thể giúp gì cho bạn?');

      final historyUser2 = DataService.getMessagesForConversation('user2@fruit.vn');
      expect(historyUser2.length, 1);
      expect(historyUser2[0].id, 'm2');
    });
  });

  group('Quản lý Chat - UC 72: Nhận tin nhắn theo thời gian thực (Realtime Chat)', () {
    test('Đồng bộ tin nhắn mới tức thì vào hội thoại khi có tin nhắn mới', () async {
      const convId = 'realtime@fruit.vn';
      expect(DataService.getMessagesForConversation(convId).length, 0);

      // Tin nhắn gửi đến
      final msg = ChatMessage(
        id: 'msg_rt_1',
        conversationId: convId,
        senderEmail: 'support@fruitopia.vn',
        senderName: 'Hỗ trợ viên',
        senderRole: 'admin',
        message: 'Đơn hàng của bạn đã được xuất kho nhé!',
        createdAt: DateTime.now(),
        isRead: false,
      );

      await DataService.sendChatMessage(msg);

      // Client nhận ngay lập tức
      final received = DataService.getMessagesForConversation(convId);
      expect(received.length, 1);
      expect(received.last.message, 'Đơn hàng của bạn đã được xuất kho nhé!');
      expect(received.last.senderRole, 'admin');
    });
  });

  group('Quản lý Chat - UC 73: Gửi hình ảnh qua tin nhắn', () {
    test('Gửi tin nhắn kèm hình ảnh minh chứng hợp lệ', () async {
      const convId = 'image_test@fruit.vn';
      final imgMsg = ChatMessage(
        id: 'msg_img_1',
        conversationId: convId,
        senderEmail: 'cust@fruit.vn',
        senderName: 'Khách Chụp Ảnh',
        senderRole: 'user',
        message: 'Ảnh quả xoài nhận được:',
        imageUrl: 'https://images.unsplash.com/photo-1553279768-865429fa0078',
        createdAt: DateTime.now(),
        isRead: false,
      );

      await DataService.sendChatMessage(imgMsg);

      final msgs = DataService.getMessagesForConversation(convId);
      expect(msgs.length, 1);
      expect(msgs.first.imageUrl, isNotNull);
      expect(msgs.first.imageUrl, contains('photo-1553279768-865429fa0078'));
    });
  });

  group('Quản lý Chat - UC 74: Gửi tệp đính kèm', () {
    test('Gửi tin nhắn kèm tệp tin đính kèm (hóa đơn / tài liệu PDF)', () async {
      const convId = 'file_test@fruit.vn';
      final fileMsg = ChatMessage(
        id: 'msg_file_1',
        conversationId: convId,
        senderEmail: 'cust@fruit.vn',
        senderName: 'Khách Đính Kèm File',
        senderRole: 'user',
        message: 'Gửi shop hóa đơn chuyển khoản:',
        fileUrl: 'https://storage.fruitopia.vn/invoices/inv_001.pdf',
        fileName: 'hoa_don_chuyen_khoan.pdf',
        createdAt: DateTime.now(),
        isRead: false,
      );

      await DataService.sendChatMessage(fileMsg);

      final msgs = DataService.getMessagesForConversation(convId);
      expect(msgs.length, 1);
      expect(msgs.first.fileUrl, isNotNull);
      expect(msgs.first.fileName, 'hoa_don_chuyen_khoan.pdf');
    });
  });

  group('Quản lý Chat - UC 75: Hiển thị trạng thái đã gửi / đã đọc', () {
    test('Đánh dấu tin nhắn chuyển từ chưa đọc (sent) sang đã đọc (read)', () async {
      const convId = 'read_test@fruit.vn';
      final msg = ChatMessage(
        id: 'msg_read_1',
        conversationId: convId,
        senderEmail: 'cust@fruit.vn',
        senderName: 'Khách',
        senderRole: 'user',
        message: 'Alo shop ơi',
        createdAt: DateTime.now(),
        isRead: false,
      );

      await DataService.sendChatMessage(msg);

      // Ban đầu chưa đọc
      var currentMsgs = DataService.getMessagesForConversation(convId);
      expect(currentMsgs.first.isRead, isFalse);

      // Admin mở hội thoại xem tin nhắn
      await DataService.markMessagesAsRead(convId, 'admin');

      // Tin nhắn được cập nhật thành đã đọc
      currentMsgs = DataService.getMessagesForConversation(convId);
      expect(currentMsgs.first.isRead, isTrue);
    });
  });

  group('Quản lý Chat - UC 76: Hiển thị trạng thái trực tuyến của nhân viên hỗ trợ', () {
    test('Hiển thị trạng thái trực tuyến của nhân viên CSKH khi người dùng chat', () async {
      final msg = ChatMessage(
        id: 'msg_online_1',
        conversationId: 'online_user@fruit.vn',
        senderEmail: 'online_user@fruit.vn',
        senderName: 'Khách Trực Tuyến',
        senderRole: 'user',
        message: 'Có ai đang trực không ạ?',
        createdAt: DateTime.now(),
        isRead: false,
      );

      await DataService.sendChatMessage(msg);

      final conversations = DataService.getAllConversations();
      final conv = conversations.firstWhere((c) => c.customerEmail == 'online_user@fruit.vn');
      expect(conv.isSupportAgentOnline, isTrue);
    });
  });

  group('Quản lý Chat - UC 77: Thông báo khi có tin nhắn mới', () {
    test('Cập nhật số tin nhắn chưa đọc (unreadCount) chính xác khi nhận tin nhắn mới', () async {
      const convId = 'unread_test@fruit.vn';
      
      // Khách gửi 2 tin nhắn chưa đọc
      await DataService.sendChatMessage(ChatMessage(
        id: 'u_1',
        conversationId: convId,
        senderEmail: 'unread_test@fruit.vn',
        senderName: 'Khách Chờ',
        senderRole: 'user',
        message: 'Tin nhắn 1',
        createdAt: DateTime.now(),
        isRead: false,
      ));

      await DataService.sendChatMessage(ChatMessage(
        id: 'u_2',
        conversationId: convId,
        senderEmail: 'unread_test@fruit.vn',
        senderName: 'Khách Chờ',
        senderRole: 'user',
        message: 'Tin nhắn 2',
        createdAt: DateTime.now(),
        isRead: false,
      ));

      final convs = DataService.getAllConversations();
      final target = convs.firstWhere((c) => c.customerEmail == convId);
      expect(target.unreadCount, 2);
    });
  });

  group('Quản lý Chat - UC 78: Tìm kiếm cuộc hội thoại', () {
    test('Tìm kiếm và lọc hội thoại theo tên khách hàng hoặc email chính xác', () async {
      await DataService.sendChatMessage(ChatMessage(
        id: 's_1',
        conversationId: 'nguyen_van_a@gmail.com',
        senderEmail: 'nguyen_van_a@gmail.com',
        senderName: 'Nguyễn Văn A',
        senderRole: 'user',
        message: 'Táo ngon lắm',
        createdAt: DateTime.now(),
        isRead: true,
      ));

      await DataService.sendChatMessage(ChatMessage(
        id: 's_2',
        conversationId: 'le_thi_b@gmail.com',
        senderEmail: 'le_thi_b@gmail.com',
        senderName: 'Lê Thị B',
        senderRole: 'user',
        message: 'Cần tư vấn xoài cát',
        createdAt: DateTime.now(),
        isRead: true,
      ));

      final allConvs = DataService.getAllConversations();
      
      // Tìm theo từ khóa "nguyen"
      final searchResult1 = allConvs.where(
        (c) => c.customerName.toLowerCase().contains('nguyen') || c.customerEmail.toLowerCase().contains('nguyen'),
      ).toList();
      expect(searchResult1.length, 1);
      expect(searchResult1.first.customerName, 'Nguyễn Văn A');

      // Tìm theo từ khóa "le_thi"
      final searchResult2 = allConvs.where(
        (c) => c.customerName.toLowerCase().contains('le_thi') || c.customerEmail.toLowerCase().contains('le_thi'),
      ).toList();
      expect(searchResult2.length, 1);
      expect(searchResult2.first.customerName, 'Lê Thị B');
    });
  });

  group('Quản lý Chat - UC 79: Đóng / Kết thúc cuộc hội thoại', () {
    test('Đóng cuộc hội thoại khi hỗ trợ xong và mở lại cuộc hội thoại', () async {
      const convId = 'close_test@fruit.vn';
      await DataService.sendChatMessage(ChatMessage(
        id: 'c_1',
        conversationId: convId,
        senderEmail: convId,
        senderName: 'Khách',
        senderRole: 'user',
        message: 'Cảm ơn shop đã tư vấn',
        createdAt: DateTime.now(),
        isRead: true,
      ));

      // Đóng cuộc hội thoại
      await DataService.closeConversation(convId);
      expect(DataService.closedConversations.contains(convId), isTrue);

      var convs = DataService.getAllConversations();
      var target = convs.firstWhere((c) => c.customerEmail == convId);
      expect(target.isClosed, isTrue);

      // Mở lại cuộc hội thoại
      await DataService.reopenConversation(convId);
      expect(DataService.closedConversations.contains(convId), isFalse);

      convs = DataService.getAllConversations();
      target = convs.firstWhere((c) => c.customerEmail == convId);
      expect(target.isClosed, isFalse);
    });
  });
}
