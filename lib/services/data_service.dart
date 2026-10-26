import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/voucher.dart';
import '../models/customer.dart';
import '../models/category.dart';
import '../models/chat_message.dart';
import '../models/app_notification.dart';
import '../models/return_request.dart';
import 'mongodb_service.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class DataService {
  static List<Product> products = [];
  static List<Order> orders = [];
  static List<Voucher> vouchers = [];
  static List<Customer> customers = [];
  static List<Category> categories = [];
  static List<ChatMessage> chatMessages = [];
  static Set<String> closedConversations = {};
  static List<AppNotification> notifications = [];
  static List<ReturnRequest> returnRequests = [];

  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('fruitopia_db_v5'); // Đổi sang v5 để tránh lưu cache sai

    _loadData();
    await _syncFromMongoDB();
  }

  static void _loadData() {
    // Tải Products
    final productsData = _box.get('products');
    if (productsData != null) {
      products = (productsData as List).map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      products = [];
      _saveProducts();
    }

    // Tải Vouchers
    final vouchersData = _box.get('vouchers');
    if (vouchersData != null) {
      vouchers = (vouchersData as List).map((e) => Voucher.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      vouchers = [];
      _saveVouchers();
    }
    
    // Tải Customers
    final customersData = _box.get('customers');
    if (customersData != null) {
      customers = (customersData as List).map((e) => Customer.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      customers = [];
      _saveCustomers();
    }
    
    // Tải Categories
    final catsData = _box.get('categories');
    if (catsData != null) {
      categories = (catsData as List).map((e) => Category.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      categories = [];
      _saveCategories();
    }

    // Tạm thời Orders khởi tạo rỗng
    orders = [];
  }

  static Future<void> _syncFromMongoDB() async {
    try {
      var colProducts = MongoDBService.getCollection("products");
      var remoteProducts = await colProducts.find().toList();
      products = remoteProducts.map((e) {
        return Product(
          id: e['id']?.toString() ?? '',
          name: e['name']?.toString() ?? '',
          description: e['description']?.toString() ?? '',
          price: (e['price'] as num?)?.toDouble() ?? 0.0,
          unit: e['unit']?.toString() ?? 'kg',
          imageUrl: e['imageUrl']?.toString() ?? '',
          stock: (e['stock'] as num?)?.toInt() ?? 0,
          category: e['category']?.toString() ?? 'Khác',
          rating: (e['rating'] as num?)?.toDouble() ?? 0.0,
          isActive: e['isActive'] ?? true,
          isDeleted: e['isDeleted'] ?? false,
        );
      }).toList();
      await _saveProducts();

      var colCustomers = MongoDBService.getCollection("users");
      var remoteUsers = await colCustomers.find().toList();
      customers = remoteUsers.map((e) {
        return Customer(
          id: e['id']?.toString() ?? '',
          name: e['name']?.toString() ?? '',
          email: e['email']?.toString() ?? '',
          phone: e['phone']?.toString() ?? '',
          password: e['password']?.toString() ?? '123456',
          totalSpent: (e['totalSpent'] as num?)?.toDouble() ?? 0.0,
          totalOrders: (e['totalOrders'] as num?)?.toInt() ?? 0,
          isActive: e['isActive'] ?? true,
        );
      }).toList();
      await _saveCustomers();
      
      var colVouchers = MongoDBService.getCollection("vouchers");
      var remoteVouchers = await colVouchers.find().toList();
      vouchers = remoteVouchers.map((e) {
        return Voucher(
          code: e['code']?.toString() ?? '',
          description: e['description']?.toString() ?? '',
          discountAmount: (e['discount_percent'] as num?)?.toDouble() ?? 0.0,
          minPurchase: (e['min_order_value'] as num?)?.toDouble() ?? 0.0,
          isActive: e['isActive'] ?? true,
        );
      }).toList();
      await _saveVouchers();

      var colCategories = MongoDBService.getCollection("categories");
      var remoteCategories = await colCategories.find().toList();
      if (remoteCategories.isEmpty) {
        // Tạo sẵn các phân loại mẫu nếu DB trống
        final defaultCats = [
          {'id': 'c1', 'name': 'Trái Cây Nhập Khẩu'},
          {'id': 'c2', 'name': 'Trái Cây Việt Nam'},
          {'id': 'c3', 'name': 'Trái Cây Cắt Sẵn'},
          {'id': 'c4', 'name': 'Trái Cây Thùng'},
          {'id': 'c5', 'name': 'Trái Cây Mùa Hè'},
        ];
        await colCategories.insertAll(defaultCats);
        remoteCategories = defaultCats;
      }
      categories = remoteCategories.map((e) => Category.fromJson(e)).toList();
      await _saveCategories();

    } catch (e) {
      print("MongoDB Sync Error: $e");
    }
  }

  static Future<void> _saveCategories() async {
    await _box.put('categories', categories.map((e) => e.toJson()).toList());
  }

  static Future<void> _saveCustomers() async {
    await _box.put('customers', customers.map((e) => e.toJson()).toList());
  }

  static Future<void> _saveProducts() async {
    await _box.put('products', products.map((e) => e.toJson()).toList());
  }

  static Future<void> _saveVouchers() async {
    await _box.put('vouchers', vouchers.map((e) => e.toJson()).toList());
  }

  // --- API Methods ---
  static Future<void> addProduct(Product product) async {
    products.insert(0, product);
    await _saveProducts();

    try {
      var col = MongoDBService.getCollection("products");
      await col.insertOne({
        "id": product.id,
        "name": product.name,
        "description": product.description,
        "price": product.price,
        "unit": product.unit,
        "imageUrl": product.imageUrl,
        "stock": product.stock,
        "category": product.category,
        "rating": product.rating,
        "isActive": product.isActive,
        "isDeleted": product.isDeleted,
        "created_at": DateTime.now().toIso8601String()
      });
    } catch (e) {
      print("MongoDB Error (addProduct): $e");
    }
  }

  static Future<void> updateProduct(Product product) async {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
      await _saveProducts();

      try {
        var col = MongoDBService.getCollection("products");
        await col.updateOne(
          mongo.where.eq('id', product.id),
          mongo.modify
              .set('name', product.name)
              .set('description', product.description)
              .set('price', product.price)
              .set('unit', product.unit)
              .set('imageUrl', product.imageUrl)
              .set('stock', product.stock)
              .set('category', product.category)
              .set('rating', product.rating)
              .set('isActive', product.isActive)
              .set('isDeleted', product.isDeleted)
        );
      } catch (e) {
        print("MongoDB Error (updateProduct): $e");
      }
    }
  }

  static Future<void> deleteProduct(String id) async {
    final index = products.indexWhere((p) => p.id == id);
    if (index != -1) {
      products[index].isDeleted = true; // Xóa mềm hoàn toàn khỏi giao diện
      await _saveProducts();

      try {
        var col = MongoDBService.getCollection("products");
        await col.updateOne(
          mongo.where.eq('id', id),
          mongo.modify.set('isDeleted', true)
        );
      } catch (e) {
        print("MongoDB Error (deleteProduct): $e");
      }
    }
  }

  static Future<void> addCustomer(Customer customer) async {
    // Avoid duplicate if already exists (AuthService might call this)
    if (!customers.any((c) => c.email == customer.email)) {
      customers.add(customer);
      await _saveCustomers();
    }
    
    // Đã insert ở AuthService, nhưng nếu gọi trực tiếp thì dự phòng ở đây
    try {
      var col = MongoDBService.getCollection("users");
      var exists = await col.findOne(mongo.where.eq('email', customer.email));
      if (exists == null) {
        await col.insertOne({
          "id": customer.id,
          "name": customer.name,
          "email": customer.email,
          "phone": customer.phone,
          "password": customer.password,
          "role": "customer",
          "created_at": DateTime.now().toIso8601String()
        });
      }
    } catch (e) {
      print("MongoDB Error (addCustomer): $e");
    }
  }

  static Future<void> addVoucher(Voucher voucher) async {
    vouchers.add(voucher);
    await _saveVouchers();

    try {
      var col = MongoDBService.getCollection("vouchers");
      await col.insertOne({
        "code": voucher.code,
        "description": voucher.description,
        "discount_percent": voucher.discountAmount, // reusing fields for simplicity
        "min_order_value": voucher.minPurchase,
        "isActive": voucher.isActive,
        "created_at": DateTime.now().toIso8601String()
      });
    } catch (e) {
      print("MongoDB Error (addVoucher): $e");
    }
  }

  static Future<void> updateVoucher(String oldCode, Voucher updatedVoucher) async {
    final index = vouchers.indexWhere((v) => v.code.toUpperCase() == oldCode.toUpperCase());
    if (index != -1) {
      vouchers[index] = updatedVoucher;
      await _saveVouchers();

      try {
        var col = MongoDBService.getCollection("vouchers");
        await col.updateOne(
          mongo.where.eq('code', oldCode),
          mongo.modify
              .set('code', updatedVoucher.code)
              .set('description', updatedVoucher.description)
              .set('discountAmount', updatedVoucher.discountAmount)
              .set('discount_percent', updatedVoucher.discountAmount)
              .set('minPurchase', updatedVoucher.minPurchase)
              .set('min_order_value', updatedVoucher.minPurchase)
              .set('isActive', updatedVoucher.isActive)
              .set('updated_at', DateTime.now().toIso8601String()),
        );
      } catch (e) {
        print("MongoDB Error (updateVoucher): $e");
      }
    }
  }

  static Future<void> deleteVoucher(String code) async {
    vouchers.removeWhere((v) => v.code.toUpperCase() == code.toUpperCase());
    await _saveVouchers();

    try {
      var col = MongoDBService.getCollection("vouchers");
      await col.deleteOne(mongo.where.eq('code', code));
    } catch (e) {
      print("MongoDB Error (deleteVoucher): $e");
    }
  }

  static Future<void> toggleVoucherStatus(String code, bool isActive) async {
    final index = vouchers.indexWhere((v) => v.code.toUpperCase() == code.toUpperCase());
    if (index != -1) {
      final old = vouchers[index];
      vouchers[index] = old.copyWith(isActive: isActive);
      await _saveVouchers();

      try {
        var col = MongoDBService.getCollection("vouchers");
        await col.updateOne(
          mongo.where.eq('code', code),
          mongo.modify
              .set('isActive', isActive)
              .set('updated_at', DateTime.now().toIso8601String()),
        );
      } catch (e) {
        print("MongoDB Error (toggleVoucherStatus): $e");
      }
    }
  }

  static Future<void> updateCustomerStatus(String id, bool isActive) async {
    final index = customers.indexWhere((c) => c.id == id);
    if (index != -1) {
      final old = customers[index];
      customers[index] = Customer(
        id: old.id,
        name: old.name,
        email: old.email,
        phone: old.phone,
        totalSpent: old.totalSpent,
        totalOrders: old.totalOrders,
        memberTier: old.memberTier,
        isActive: isActive,
      );
      await _saveCustomers();
      
      try {
        var col = MongoDBService.getCollection("users");
        await col.updateOne(
          mongo.where.eq('email', old.email),
          mongo.modify.set('isActive', isActive)
        );
      } catch (e) {
        print("MongoDB Error (updateCustomerStatus): $e");
      }
    }
  }

  static Future<void> updateCustomerProfile(String id, String name, String phone, String password) async {
    final index = customers.indexWhere((c) => c.id == id);
    if (index != -1) {
      final old = customers[index];
      customers[index] = Customer(
        id: old.id,
        name: name,
        email: old.email,
        password: password.isNotEmpty ? password : old.password,
        phone: phone,
        totalSpent: old.totalSpent,
        totalOrders: old.totalOrders,
        memberTier: old.memberTier,
        isActive: old.isActive,
      );
      await _saveCustomers();

      try {
        var col = MongoDBService.getCollection("users");
        await col.updateOne(
          mongo.where.eq('email', old.email),
          mongo.modify
              .set('name', name)
              .set('phone', phone)
              .set('password', password.isNotEmpty ? password : old.password)
        );
      } catch (e) {
        print("MongoDB Error (updateCustomerProfile): $e");
      }
    }
  }

  // --- QUẢN LÝ YÊU CẦU ĐỔI TRẢ & HỖ TRỢ KHÁCH HÀNG ---
  static Future<void> _saveReturnRequests() async {
    try {
      await _box.put('return_requests', returnRequests.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  static Future<void> addReturnRequest(ReturnRequest req) async {
    returnRequests.insert(0, req);
    await _saveReturnRequests();

    try {
      var col = MongoDBService.getCollection("return_requests");
      await col.insertOne(req.toJson());
    } catch (e) {
      print("MongoDB Error (addReturnRequest): $e");
    }
  }

  static Future<void> updateReturnRequest(ReturnRequest updatedReq) async {
    final index = returnRequests.indexWhere((r) => r.id == updatedReq.id);
    if (index != -1) {
      returnRequests[index] = updatedReq;
      await _saveReturnRequests();

      try {
        var col = MongoDBService.getCollection("return_requests");
        await col.updateOne(
          mongo.where.eq('id', updatedReq.id),
          mongo.modify
              .set('status', updatedReq.status)
              .set('adminReply', updatedReq.adminReply)
              .set('updatedAt', updatedReq.updatedAt?.toIso8601String()),
        );
      } catch (e) {
        print("MongoDB Error (updateReturnRequest): $e");
      }
    }
  }

  static Future<void> cancelReturnRequest(String requestId) async {
    final index = returnRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final req = returnRequests[index];
      final updated = req.copyWith(
        status: 'cancelled',
        updatedAt: DateTime.now(),
      );
      returnRequests[index] = updated;
      await _saveReturnRequests();

      try {
        var col = MongoDBService.getCollection("return_requests");
        await col.updateOne(
          mongo.where.eq('id', requestId),
          mongo.modify
              .set('status', 'cancelled')
              .set('updatedAt', DateTime.now().toIso8601String()),
        );
      } catch (e) {
        print("MongoDB Error (cancelReturnRequest): $e");
      }
    }
  }

  static Future<void> processReturnRequest(
    String requestId, {
    required String status,
    required String reply,
  }) async {
    final index = returnRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final req = returnRequests[index];
      final updated = req.copyWith(
        status: status,
        adminReply: reply,
        updatedAt: DateTime.now(),
      );
      returnRequests[index] = updated;
      await _saveReturnRequests();

      try {
        var col = MongoDBService.getCollection("return_requests");
        await col.updateOne(
          mongo.where.eq('id', requestId),
          mongo.modify
              .set('status', status)
              .set('adminReply', reply)
              .set('updatedAt', DateTime.now().toIso8601String()),
        );
      } catch (e) {
        print("MongoDB Error (processReturnRequest): $e");
      }
    }
  }

  static Future<void> replyReturnRequest({
    required String requestId,
    required String status,
    required String reply,
  }) async {
    await processReturnRequest(requestId, status: status, reply: reply);
  }

  static List<Order> getOrdersForCustomer(String? email) {
    if (email == null || email.trim().isEmpty) return [];
    final target = email.trim().toLowerCase();
    return orders
        .where((o) => o.customerEmail?.trim().toLowerCase() == target)
        .toList();
  }

  // --- QUẢN LÝ CHAT & HỖ TRỢ KHÁCH HÀNG (MODULE 11) ---
  static Future<void> _saveChatMessages() async {
    try {
      await _box.put('chat_messages', chatMessages.map((e) => e.toJson()).toList());
      await _box.put('closed_conversations', closedConversations.toList());
    } catch (_) {}
  }

  static Future<void> sendChatMessage(ChatMessage message) async {
    chatMessages.add(message);
    await _saveChatMessages();

    try {
      var col = MongoDBService.getCollection("chat_messages");
      await col.insertOne(message.toJson());
    } catch (e) {
      print("MongoDB Error (sendChatMessage): $e");
    }

    if (message.senderRole == 'user') {
      _triggerAutoReplyIfNeeded(message.conversationId, message.senderName);
    }
  }

  static void _triggerAutoReplyIfNeeded(String conversationId, String customerName) {
    Future.delayed(const Duration(milliseconds: 1200), () async {
      final convMsgs = getMessagesForConversation(conversationId);
      if (convMsgs.isNotEmpty && convMsgs.last.senderRole == 'user') {
        final botMsg = ChatMessage(
          id: 'msg_bot_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: conversationId,
          senderEmail: 'support@fruitopia.vn',
          senderName: 'CSKH Fruitopia',
          senderRole: 'admin',
          message: 'Chào $customerName! Chuyên viên tư vấn Fruitopia đã nhận được tin nhắn và đang hỗ trợ bạn ngay.',
          createdAt: DateTime.now(),
          isRead: false,
        );
        chatMessages.add(botMsg);
        await _saveChatMessages();
      }
    });
  }

  static List<ChatMessage> getMessagesForConversation(String conversationId) {
    return chatMessages
        .where((m) => m.conversationId.toLowerCase() == conversationId.toLowerCase())
        .toList();
  }

  static List<ChatConversation> getAllConversations() {
    final Map<String, List<ChatMessage>> groups = {};
    for (var m in chatMessages) {
      final key = m.conversationId.toLowerCase();
      groups.putIfAbsent(key, () => []).add(m);
    }

    final List<ChatConversation> result = [];
    for (var entry in groups.entries) {
      final msgs = entry.value;
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final last = msgs.last;
      final unread = msgs.where((m) => !m.isRead && m.senderRole == 'user').length;
      final customer = customers.firstWhere(
        (c) => c.email.toLowerCase() == entry.key,
        orElse: () => Customer(id: '', name: last.senderRole == 'user' ? last.senderName : 'Khách hàng', email: entry.key, phone: '', totalSpent: 0, totalOrders: 0),
      );

      result.add(
        ChatConversation(
          id: entry.key,
          customerEmail: entry.key,
          customerName: customer.name.isNotEmpty ? customer.name : (last.senderRole == 'user' ? last.senderName : 'Khách hàng'),
          customerPhone: customer.phone,
          lastMessage: last.message.isNotEmpty ? last.message : (last.imageUrl != null ? '[Hình ảnh]' : '[Tệp đính kèm]'),
          lastMessageTime: last.createdAt,
          unreadCount: unread,
          isClosed: closedConversations.contains(entry.key),
          isSupportAgentOnline: true,
        ),
      );
    }

    result.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return result;
  }

  static Future<void> markMessagesAsRead(String conversationId, String readerRole) async {
    bool hasChanged = false;
    for (var m in chatMessages) {
      if (m.conversationId.toLowerCase() == conversationId.toLowerCase()) {
        if (!m.isRead && m.senderRole != readerRole) {
          m.isRead = true;
          hasChanged = true;
        }
      }
    }
    if (hasChanged) {
      await _saveChatMessages();
      try {
        var col = MongoDBService.getCollection("chat_messages");
        await col.updateMany(
          mongo.where.eq('conversationId', conversationId).ne('senderRole', readerRole),
          mongo.modify.set('isRead', true),
        );
      } catch (e) {
        print("MongoDB error markMessagesAsRead: $e");
      }
    }
  }

  static Future<void> closeConversation(String conversationId) async {
    closedConversations.add(conversationId.toLowerCase());
    await _saveChatMessages();
  }

  static Future<void> reopenConversation(String conversationId) async {
    closedConversations.remove(conversationId.toLowerCase());
    await _saveChatMessages();
  }

  static Future<void> clearConversationMessages(String conversationId) async {
    chatMessages.removeWhere((m) => m.conversationId.toLowerCase() == conversationId.toLowerCase());
    await _saveChatMessages();
    try {
      var col = MongoDBService.getCollection("chat_messages");
      await col.deleteMany(mongo.where.eq('conversationId', conversationId));
    } catch (e) {
      print("MongoDB error clearConversationMessages: $e");
    }
  }
}

