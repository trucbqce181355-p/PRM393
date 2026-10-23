import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/voucher.dart';
import '../models/customer.dart';
import '../models/category.dart';
import 'mongodb_service.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class DataService {
  static List<Product> products = [];
  static List<Order> orders = [];
  static List<Voucher> vouchers = [];
  static List<ChatMessage> chatMessages = [];
  static Set<String> closedConversations = {};
  static List<Customer> customers = [];
  static List<Category> categories = [];

  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('fruitopia_db_v5'); // Đổi sang v5 để tránh lưu cache sai

    _loadData();
    await _syncFromMongoDB();
  }

  static List<Product> get defaultProducts => [
    Product(
      id: 'p_tao_envy',
      name: 'Táo Envy New Zealand',
      description: 'Táo Envy New Zealand nhập khẩu chính ngạch, trái to tròn đều, vỏ đỏ ruby bắt mắt. Thịt táo chắc, giòn tan sảng khoái và ngọt thanh đậm vị, hương thơm tự nhiên đặc trưng. Giàu vitamin C, chất chống oxy hóa và khoáng chất tốt cho sức khỏe.',
      price: 185000,
      unit: 'kg',
      imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&q=80&w=600',
      rating: 5.0,
      stock: 85,
      category: 'Trái Cây Nhập Khẩu',
      origin: 'New Zealand',
      freshness: '100% Tươi giòn mới cập cảng',
    ),
    Product(
      id: 'p_xoai_cat',
      name: 'Xoài Cát Chu Cao Lãnh',
      description: 'Xoài Cát Chu đặc sản Cao Lãnh - Đồng Tháp, trái chín vàng ươm tự nhiên, thịt dày mịn không xơ, vị ngọt đậm đà thơm ngát. Chuẩn VietGAP an toàn tuyệt đối.',
      price: 65000,
      unit: 'kg',
      imageUrl: 'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&q=80&w=600',
      rating: 4.9,
      stock: 120,
      category: 'Trái Cây Nhiệt Đới',
      origin: 'Đồng Tháp, Việt Nam',
      freshness: '100% Thu hoạch tại vườn trong ngày',
    ),
    Product(
      id: 'p_sau_rieng',
      name: 'Sầu Riêng Ri6 Cơm Vàng Hạt Lép',
      description: 'Sầu riêng Ri6 miền Tây chuẩn cơm vàng hạt lép, múi khô ráo béo ngậy ngọt lịm. Chín già tự nhiên rụng cành, cam kết không nhúng thuốc, bao 1 đổi 1.',
      price: 145000,
      unit: 'kg',
      imageUrl: 'https://images.unsplash.com/photo-1589139265215-d7293a1cf552?auto=format&fit=crop&q=80&w=600',
      rating: 4.8,
      stock: 40,
      category: 'Trái Cây Nhiệt Đới',
      origin: 'Bến Tre, Việt Nam',
      freshness: 'Tươi mới rụng vườn hôm nay',
    ),
    Product(
      id: 'p_nho_mau_don',
      name: 'Nho Mẫu Đơn Shine Muscat',
      description: 'Nho Mẫu Đơn Shine Muscat nhập khẩu, chùm dày quả xanh ngọc bích không hạt, vỏ mỏng giòn ngọt thơm dịu hương hoa nhài quý phái.',
      price: 420000,
      unit: 'kg',
      imageUrl: 'https://images.unsplash.com/photo-1537640538966-79f369143f8f?auto=format&fit=crop&q=80&w=600',
      rating: 5.0,
      stock: 25,
      category: 'Trái Cây Nhập Khẩu',
      origin: 'Nhật Bản',
      freshness: '99% Tươi xanh nguyên phấn bảo quản lạnh',
    ),
    Product(
      id: 'p_thanh_long',
      name: 'Thanh Long Ruột Đỏ Hữu Cơ',
      description: 'Thanh Long ruột đỏ Bình Thuận tươi mát, quả căng mọng tai xanh, ruột đỏ thẫm ngọt thanh giàu chất chống lão hóa tự nhiên.',
      price: 45000,
      unit: 'kg',
      imageUrl: 'https://images.unsplash.com/photo-1527325678964-54921661f888?auto=format&fit=crop&q=80&w=600',
      rating: 4.7,
      stock: 150,
      category: 'Trái Cây Nhiệt Đới',
      origin: 'Bình Thuận, Việt Nam',
      freshness: '100% Tươi mới hái sáng nay',
    ),
    Product(
      id: 'p_cam_cara',
      name: 'Cam Cara Ruột Đỏ Úc',
      description: 'Cam Cara nhập khẩu Úc ruột đỏ không hạt, tép cam mọng nước ngọt thanh không chua, giàu vitamin C và Lycopene.',
      price: 110000,
      unit: 'kg',
      imageUrl: 'https://images.unsplash.com/photo-1547514701-42782101795e?auto=format&fit=crop&q=80&w=600',
      rating: 4.9,
      stock: 60,
      category: 'Trái Cây Nhập Khẩu',
      origin: 'Australia (Úc)',
      freshness: 'Tươi mọng nước bảo quản chuẩn quốc tế',
    ),
    Product(
      id: 'p_mang_cut',
      name: 'Măng Cụt Lái Thiêu',
      description: 'Măng cụt Lái Thiêu chính gốc, vỏ mỏng cuống xanh, múi trắng ngần vị chua ngọt hài hòa thanh tao.',
      price: 95000,
      unit: 'kg',
      imageUrl: 'https://images.unsplash.com/photo-1589139265215-d7293a1cf552?auto=format&fit=crop&q=80&w=600',
      rating: 4.9,
      stock: 55,
      category: 'Trái Cây Nhiệt Đới',
      origin: 'Bình Dương, Việt Nam',
      freshness: '100% Tươi rói cuống xanh',
    ),
  ];

  static void _loadData() {
    // Tải Products
    final productsData = _box.get('products');
    if (productsData != null && productsData is List && productsData.isNotEmpty) {
      products = productsData.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
      // Ensure Táo Envy is always available
      if (!products.any((p) => p.name.contains('Táo Envy'))) {
        products.insert(0, defaultProducts.first);
      }
    } else {
      products = List.from(defaultProducts);
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
      if (remoteProducts.isEmpty) {
        for (var p in defaultProducts) {
          await colProducts.insertOne(p.toJson());
        }
        remoteProducts = await colProducts.find().toList();
      }
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
          origin: e['origin']?.toString() ?? 'Việt Nam',
          freshness: e['freshness']?.toString() ?? '100% Tươi mới trong ngày',
          rating: (e['rating'] as num?)?.toDouble() ?? 0.0,
          isActive: e['isActive'] ?? true,
          isDeleted: e['isDeleted'] ?? false,
        );
      }).toList();

      if (!products.any((p) => p.name.contains('Táo Envy'))) {
        products.insert(0, defaultProducts.first);
      }
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
        final defaultCats = [
          {'id': 'c1', 'name': 'Trái Cây Nhiệt Đới'},
          {'id': 'c2', 'name': 'Trái Cây Nhập Khẩu'},
          {'id': 'c3', 'name': 'Trái Cây Cắt Sẵn'},
          {'id': 'c4', 'name': 'Trái Cây Theo Mùa'},
          {'id': 'c5', 'name': 'Trái Cây Thùng'},
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

  static List<ChatConversation> getAllConversations() {
    final Map<String, List<ChatMessage>> grouped = {};
    for (var m in chatMessages) {
      grouped.putIfAbsent(m.conversationId, () => []).add(m);
    }
    final List<ChatConversation> list = [];
    grouped.forEach((convId, msgs) {
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final lastMsg = msgs.last;
      list.add(ChatConversation(
        conversationId: convId,
        customerName: msgs.firstWhere((m) => m.senderRole == 'user', orElse: () => lastMsg).senderName,
        customerEmail: convId,
        lastMessage: lastMsg.message,
        lastMessageTime: lastMsg.createdAt,
        unreadCount: msgs.where((m) => m.senderRole == 'user').length,
        isClosed: closedConversations.contains(convId.toLowerCase()),
      ));
    });
    list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return list;
  }

  static List<ChatMessage> getMessagesForConversation(String conversationId) {
    final msgs = chatMessages.where((m) => m.conversationId.toLowerCase() == conversationId.toLowerCase()).toList();
    msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return msgs;
  }

  static void _triggerAutoReplyIfNeeded(String conversationId, String customerName) {
    Future.delayed(const Duration(milliseconds: 600), () async {
      final autoReply = ChatMessage(
        id: 'm_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderEmail: 'support@fruitopia.vn',
        senderName: 'Fruitopia CSKH',
        senderRole: 'admin',
        message: 'Chào ${customerName}, chuyên viên tư vấn Fruitopia đã nhận được yêu cầu của bạn và sẽ phản hồi trong giây lát!',
        createdAt: DateTime.now(),
      );
      await sendChatMessage(autoReply);
    });
  }

  static Future<void> sendChatMessage(ChatMessage message) async {
    chatMessages.add(message);
    await _saveChatMessages();
    if (message.senderRole == 'user') {
      _triggerAutoReplyIfNeeded(message.conversationId, message.senderName);
    }
    try {
      var col = MongoDBService.getCollection("chat_messages");
      await col.insertOne(message.toJson());
    } catch (e) {
      print("MongoDB Error (sendChatMessage): $e");
    }
  }

  static Future<void> _saveChatMessages() async {
    if (_box.isOpen) {
      final jsonList = chatMessages.map((m) => m.toJson()).toList();
      await _box.put('chat_messages', jsonList);
    }
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
        "origin": product.origin,
        "freshness": product.freshness,
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
              .set('origin', product.origin)
              .set('freshness', product.freshness)
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

  static Future<void> toggleVoucherStatus(String code, bool isActive) async {
    final index = vouchers.indexWhere((v) => v.code == code);
    if (index != -1) {
      vouchers[index] = vouchers[index].copyWith(isActive: isActive);
      await _saveVouchers();
      try {
        var col = MongoDBService.getCollection("vouchers");
        await col.updateOne(mongo.where.eq('code', code), mongo.modify.set('isActive', isActive));
      } catch (e) {
        print("MongoDB Error (toggleVoucherStatus): $e");
      }
    }
  }

  static Future<void> deleteVoucher(String code) async {
    vouchers.removeWhere((v) => v.code == code);
    await _saveVouchers();
    try {
      var col = MongoDBService.getCollection("vouchers");
      await col.deleteOne(mongo.where.eq('code', code));
    } catch (e) {
      print("MongoDB Error (deleteVoucher): $e");
    }
  }

  static Future<void> updateVoucher(String oldCode, Voucher updatedVoucher) async {
    final index = vouchers.indexWhere((v) => v.code == oldCode);
    if (index != -1) {
      vouchers[index] = updatedVoucher;
      await _saveVouchers();
      try {
        var col = MongoDBService.getCollection("vouchers");
        await col.replaceOne(mongo.where.eq('code', oldCode), updatedVoucher.toJson());
      } catch (e) {
        print("MongoDB Error (updateVoucher): $e");
      }
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
}
