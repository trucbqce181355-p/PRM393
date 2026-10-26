import 'package:flutter_test/flutter_test.dart';
import 'package:traicay/models/chat_message.dart';
import 'package:traicay/services/data_service.dart';

void main() {
  setUp(() {
    DataService.chatMessages.clear();
    DataService.closedConversations.clear();
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
