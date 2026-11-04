import 'package:hive_flutter/hive_flutter.dart';

import '../models/product.dart';
import '../models/order.dart';
import '../models/voucher.dart';
import '../models/customer.dart';
import '../models/category.dart';
import '../models/review.dart';
import '../models/return_request.dart';
import '../models/app_notification.dart';
import '../models/stock_transaction.dart';
import '../models/chat_message.dart';
import '../models/seasonal_banner.dart';
import 'mongodb_service.dart';

import 'package:mongo_dart/mongo_dart.dart' as mongo;

class DataService {
  static List<Product> products = [];
  static List<Order> orders = [];
  static List<Voucher> vouchers = [];
  static List<Customer> customers = [];
  static List<Category> categories = [];
  static List<SeasonalBanner> banners = [];
  static List<Review> reviews = [];
  static List<ReturnRequest> returnRequests = [];
  static List<AppNotification> notifications = [];
  static List<StockTransaction> stockTransactions = [];
  static List<ChatMessage> chatMessages = [];
  static Set<String> closedConversations = {};

  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(
      'fruitopia_db_v5',
    ); // Đổi sang v5 để tránh lưu cache sai

    _loadData();
    await _syncFromMongoDB();
  }

  static List<SeasonalBanner> get defaultBanners => [
    SeasonalBanner(
      id: 'b1',
      badge: 'MÙA VÀNG NHIỆT ĐỚI',
      title: 'Trái Cây Nhiệt Đới Tươi Mát',
      subtitle: 'Xoài Cát Chu, Sầu Riêng Ri6 ngọt béo vừa hái',
      tag: 'ƯU ĐÃI ĐẾN 25%',
      category: 'Trái Cây Nhiệt Đới',
      image: 'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&q=80&w=800',
      colorStart: 0xFFE65100,
      colorEnd: 0xFFFF9800,
    ),
    SeasonalBanner(
      id: 'b2',
      badge: 'NHẬP KHẨU CAO CẤP',
      title: 'Táo Envy New Zealand Tươi Giòn',
      subtitle: 'Nhập khẩu đường bay, thịt giòn tan, vị ngọt đậm',
      tag: 'CHUẨN GLOBALGAP',
      category: 'Trái Cây Nhập Khẩu',
      image: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&q=80&w=800',
      colorStart: 0xFF880E4F,
      colorEnd: 0xFFE91E63,
    ),
    SeasonalBanner(
      id: 'b3',
      badge: 'THU HOẠCH HỮU CƠ',
      title: 'Trái Cây Theo Mùa Tươi Rót',
      subtitle: 'Nho Mẫu Đơn & Cam Cara ruột đỏ mọng nước',
      tag: 'FREESHIP TOÀN QUỐC',
      category: 'Trái Cây Theo Mùa',
      image: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&q=80&w=800',
      colorStart: 0xFF1B5E20,
      colorEnd: 0xFF4CAF50,
    ),
  ];

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

  static List<Voucher> get defaultVouchers => [
    Voucher(
      code: 'WELCOME10',
      description: 'Giảm 10.000₫ cho đơn hàng đầu tiên từ 100.000₫',
      discountAmount: 10000,
      minPurchase: 100000,
      isActive: true,
    ),
    Voucher(
      code: 'FREESHIP20',
      description: 'Miễn phí vận chuyển 20.000₫ cho đơn từ 150.000₫',
      discountAmount: 20000,
      minPurchase: 150000,
      isActive: true,
    ),
    Voucher(
      code: 'FRUIT50K',
      description: 'Giảm 50.000₫ cho đơn hàng trái cây từ 300.000₫',
      discountAmount: 50000,
      minPurchase: 300000,
      isActive: true,
    ),
  ];

  static void _loadData() {
    // Tải Products
    final productsData = _box.get('products');
    if (productsData != null &&
        productsData is List &&
        productsData.isNotEmpty) {
      products = productsData
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();
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
    if (vouchersData != null &&
        vouchersData is List &&
        vouchersData.isNotEmpty) {
      vouchers = vouchersData
          .map((e) => Voucher.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      vouchers = List.from(defaultVouchers);
      _saveVouchers();
    }

    // Tải Customers
    final customersData = _box.get('customers');
    if (customersData != null) {
      customers = (customersData as List)
          .map((e) => Customer.fromJson(Map<String, dynamic>.from(e)))
          .where((c) => c.email != 'user@example.com' && !c.name.contains('(Mẫu)'))
          .toList();
    } else {
      customers = [];
      _saveCustomers();
    }

    // Tải Categories
    final catsData = _box.get('categories');
    if (catsData != null) {
      categories = (catsData as List)
          .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      categories = [];
      _saveCategories();
    }

    // Tải Banners
    final bannersData = _box.get('banners');
    if (bannersData != null && bannersData is List && bannersData.isNotEmpty) {
      banners = bannersData
          .map((e) => SeasonalBanner.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      banners = List.from(defaultBanners);
      _saveBanners();
    }

    // Tải Orders từ local cache (chỉ đơn hàng thực tế, loại bỏ dữ liệu mẫu)
    final ordersData = _box.get('orders');
    if (ordersData != null && ordersData is List) {
      orders = ordersData
          .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
          .where((o) => o.id != '109283' && o.id != '109280')
          .toList();
    } else {
      orders = [];
    }

    // Tải Reviews từ local cache (chỉ đánh giá người dùng thật, loại bỏ dữ liệu ảo)
    final reviewsData = _box.get('reviews');
    if (reviewsData != null && reviewsData is List) {
      reviews = reviewsData
          .map((e) => Review.fromJson(Map<String, dynamic>.from(e)))
          .where(
            (r) =>
                r.userName != 'Nguyễn Văn A' &&
                r.userName != 'Trần Thị B' &&
                r.userName != 'Lê Văn C',
          )
          .toList();
    } else {
      reviews = [];
    }

    // Tải Return Requests
    final returnsData = _box.get('return_requests');
    if (returnsData != null && returnsData is List) {
      returnRequests = returnsData
          .map((e) => ReturnRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      returnRequests = [];
    }

    // Tải Notifications
    final notifsData = _box.get('notifications');
    if (notifsData != null && notifsData is List) {
      notifications = notifsData
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      notifications = [];
    }

    // Tải Stock Transactions
    final transData = _box.get('stock_transactions');
    if (transData != null && transData is List) {
      stockTransactions = transData
          .map((e) => StockTransaction.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      stockTransactions = [];
    }

    // Tải Chat Messages
    final chatData = _box.get('chat_messages');
    if (chatData != null && chatData is List) {
      chatMessages = chatData
          .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      chatMessages = [];
    }

    final closedData = _box.get('closed_conversations');
    if (closedData != null && closedData is List) {
      closedConversations = Set<String>.from(closedData);
    } else {
      closedConversations = {};
    }
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
      customers = remoteUsers
          .map((e) {
            return Customer(
              id: e['id']?.toString() ?? '',
              name: e['name']?.toString() ?? '',
              email: e['email']?.toString() ?? '',
              phone: e['phone']?.toString() ?? '',
              password: e['password']?.toString() ?? '123456',
              totalSpent: (e['totalSpent'] as num?)?.toDouble() ?? 0.0,
              totalOrders: (e['totalOrders'] as num?)?.toInt() ?? 0,
              isActive: e['isActive'] ?? true,
              memberTier: e['memberTier']?.toString() ?? 'Đồng',
              googleId: e['googleId']?.toString(),
              isGoogleLinked: e['isGoogleLinked'] == true || (e['googleId'] != null && e['googleId'].toString().isNotEmpty),
            );
          })
          .where((c) => c.email != 'user@example.com' && !c.name.contains('(Mẫu)'))
          .toList();
      await _saveCustomers();

      var colVouchers = MongoDBService.getCollection("vouchers");
      var remoteVouchers = await colVouchers.find().toList();
      if (remoteVouchers.isEmpty && vouchers.isNotEmpty) {
        for (var v in vouchers) {
          await colVouchers.insertOne({
            "code": v.code,
            "description": v.description,
            "discount_percent": v.discountAmount,
            "discountAmount": v.discountAmount,
            "min_order_value": v.minPurchase,
            "minPurchase": v.minPurchase,
            "isActive": v.isActive,
            "created_at": DateTime.now().toIso8601String(),
          });
        }
        remoteVouchers = await colVouchers.find().toList();
      }
      if (remoteVouchers.isNotEmpty) {
        vouchers = remoteVouchers.map((e) => Voucher.fromJson(e)).toList();
        await _saveVouchers();
      }

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

      var colBanners = MongoDBService.getCollection("banners");
      var remoteBanners = await colBanners.find().toList();
      if (remoteBanners.isEmpty) {
        final defBanners = defaultBanners.map((e) => e.toJson()).toList();
        await colBanners.insertAll(defBanners);
        remoteBanners = defBanners;
      }
      banners = remoteBanners.map((e) => SeasonalBanner.fromJson(e)).toList();
      await _saveBanners();

      // Đồng bộ đơn hàng thực tế từ MongoDB traicay_db
      var colOrders = MongoDBService.getCollection("orders");
      var remoteOrders = await colOrders.find().toList();
      orders = remoteOrders
          .map((e) => Order.fromJson(e))
          .where((o) => o.id != '109283' && o.id != '109280')
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveOrders();
      print("Đã đồng bộ ${orders.length} đơn hàng từ MongoDB traicay_db");

      // Cập nhật lại chính xác tổng chi tiêu (loại trừ các đơn đã hủy)
      for (var c in customers) {
        await syncCustomerSpending(c.email);
      }

      // Đồng bộ đánh giá thực tế từ MongoDB traicay_db (loại bỏ dữ liệu ảo)
      var colReviews = MongoDBService.getCollection("reviews");
      try {
        await colReviews.deleteMany(mongo.where.eq('userName', 'Nguyễn Văn A'));
        await colReviews.deleteMany(mongo.where.eq('userName', 'Trần Thị B'));
        await colReviews.deleteMany(mongo.where.eq('userName', 'Lê Văn C'));
      } catch (_) {}

      var remoteReviews = await colReviews.find().toList();
      reviews = remoteReviews
          .map((e) => Review.fromJson(e))
          .where(
            (r) =>
                r.userName != 'Nguyễn Văn A' &&
                r.userName != 'Trần Thị B' &&
                r.userName != 'Lê Văn C',
          )
          .toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveReviews();
      print(
        "Đã đồng bộ ${reviews.length} đánh giá thực tế từ MongoDB traicay_db",
      );

      // Đồng bộ Yêu cầu đổi trả khiếu nại từ MongoDB traicay_db
      var colReturns = MongoDBService.getCollection("return_requests");
      var remoteReturns = await colReturns.find().toList();
      if (remoteReturns.isNotEmpty) {
        returnRequests = remoteReturns.map((e) => ReturnRequest.fromJson(e)).toList();
        returnRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _saveReturnRequests();
      }

      // Đồng bộ Thông báo từ MongoDB traicay_db
      var colNotifs = MongoDBService.getCollection("notifications");
      var remoteNotifs = await colNotifs.find().toList();
      if (remoteNotifs.isNotEmpty) {
        notifications = remoteNotifs.map((e) => AppNotification.fromJson(e)).toList();
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _saveNotifications();
      }

      // Đồng bộ Lịch sử biến động kho từ MongoDB traicay_db
      var colTrans = MongoDBService.getCollection("stock_transactions");
      var remoteTrans = await colTrans.find().toList();
      if (remoteTrans.isNotEmpty) {
        stockTransactions = remoteTrans.map((e) => StockTransaction.fromJson(e)).toList();
        stockTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _saveStockTransactions();
      }

      // Đồng bộ Tin nhắn Chat từ MongoDB traicay_db
      var colChat = MongoDBService.getCollection("chat_messages");
      var remoteChat = await colChat.find().toList();
      if (remoteChat.isNotEmpty) {
        chatMessages = remoteChat.map((e) => ChatMessage.fromJson(e)).toList();
        chatMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        await _saveChatMessages();
      }
    } catch (e) {
      print("MongoDB Sync Error: $e");
    }
  }

  static Future<void> _saveChatMessages() async {
    try {
      await _box.put('chat_messages', chatMessages.map((e) => e.toJson()).toList());
      await _box.put('closed_conversations', closedConversations.toList());
    } catch (_) {}
  }

  static Future<void> _saveCategories() async {
    try {
      await _box.put('categories', categories.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  static Future<void> _saveBanners() async {
    try {
      await _box.put('banners', banners.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  static Future<void> saveCustomersToCache() => _saveCustomers();

  static Future<void> _saveCustomers() async {
    try {
      await _box.put('customers', customers.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  static Future<void> _saveProducts() async {
    try {
      await _box.put('products', products.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  static Future<void> _saveVouchers() async {
    try {
      await _box.put('vouchers', vouchers.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  static Future<void> _saveOrders() async {
    try {
      await _box.put('orders', orders.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  static Future<void> _saveReviews() async {
    try {
      await _box.put('reviews', reviews.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  static Future<void> _saveReturnRequests() async {
    try {
      await _box.put('return_requests', returnRequests.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  static Future<void> _saveNotifications() async {
    try {
      await _box.put('notifications', notifications.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  static Future<void> _saveStockTransactions() async {
    try {
      await _box.put('stock_transactions', stockTransactions.map((e) => e.toJson()).toList());
    } catch (_) {}
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
        "created_at": DateTime.now().toIso8601String(),
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
              .set('isDeleted', product.isDeleted),
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
          mongo.modify.set('isDeleted', true),
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
          "created_at": DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print("MongoDB Error (addCustomer): $e");
    }
  }

  static Future<void> addVoucher(Voucher voucher) async {
    final index = vouchers.indexWhere(
      (v) => v.code.toUpperCase() == voucher.code.toUpperCase(),
    );
    if (index != -1) {
      await updateVoucher(vouchers[index].code, voucher);
      return;
    }

    vouchers.insert(0, voucher);
    await _saveVouchers();

    try {
      var col = MongoDBService.getCollection("vouchers");
      await col.insertOne({
        "code": voucher.code,
        "description": voucher.description,
        "discount_percent": voucher.discountPercentage,
        "discountAmount": voucher.discountAmount,
        "min_order_value": voucher.minPurchase,
        "minPurchase": voucher.minPurchase,
        "discountType": voucher.discountType,
        "discountPercentage": voucher.discountPercentage,
        "maxDiscountAmount": voucher.maxDiscountAmount,
        "isActive": voucher.isActive,
        "created_at": DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("MongoDB Error (addVoucher): $e");
    }
  }

  static Future<void> updateVoucher(
    String oldCode,
    Voucher updatedVoucher,
  ) async {
    final index = vouchers.indexWhere(
      (v) => v.code.toUpperCase() == oldCode.toUpperCase(),
    );
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
              .set('discount_percent', updatedVoucher.discountPercentage)
              .set('minPurchase', updatedVoucher.minPurchase)
              .set('min_order_value', updatedVoucher.minPurchase)
              .set('discountType', updatedVoucher.discountType)
              .set('discountPercentage', updatedVoucher.discountPercentage)
              .set('maxDiscountAmount', updatedVoucher.maxDiscountAmount)
              .set('isActive', updatedVoucher.isActive)
              .set('updated_at', DateTime.now().toIso8601String()),
        );
      } catch (e) {
        print("MongoDB Error (updateVoucher): $e");
      }
    }
  }

  static Future<void> toggleVoucherStatus(String code, bool isActive) async {
    final index = vouchers.indexWhere(
      (v) => v.code.toUpperCase() == code.toUpperCase(),
    );
    if (index != -1) {
      final old = vouchers[index];
      vouchers[index] = old.copyWith(isActive: isActive);
      await _saveVouchers();

      try {
        var col = MongoDBService.getCollection("vouchers");
        await col.updateOne(
          mongo.where.eq('code', code),
          mongo.modify.set('isActive', isActive),
        );
      } catch (e) {
        print("MongoDB Error (toggleVoucherStatus): $e");
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
          mongo.modify.set('isActive', isActive),
        );
      } catch (e) {
        print("MongoDB Error (updateCustomerStatus): $e");
      }
    }
  }

  static Future<void> updateCustomerProfile(
    String id,
    String name,
    String phone,
    String password,
  ) async {
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
              .set('password', password.isNotEmpty ? password : old.password),
        );
      } catch (e) {
        print("MongoDB Error (updateCustomerProfile): $e");
      }
    }
  }

  static Future<bool> resetPasswordByEmail(String email, String newPassword) async {
    final cleanEmail = email.trim().toLowerCase();
    final index = customers.indexWhere((c) => c.email.trim().toLowerCase() == cleanEmail);
    if (index != -1) {
      final old = customers[index];
      customers[index] = old.copyWith(password: newPassword);
      await _saveCustomers();

      try {
        var col = MongoDBService.getCollection("users");
        await col.updateOne(
          mongo.where.eq('email', old.email),
          mongo.modify.set('password', newPassword),
        );
      } catch (e) {
        print("MongoDB Error (resetPasswordByEmail): $e");
      }
      return true;
    }
    return false;
  }

  // --- ORDERS API (Kết nối trực tiếp MongoDB traicay_db) ---
  static Future<void> refreshOrders() async {
    try {
      var colOrders = MongoDBService.getCollection("orders");
      var remoteOrders = await colOrders.find().toList();
      orders = remoteOrders
          .map((e) => Order.fromJson(e))
          .where((o) => o.id != '109283' && o.id != '109280')
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveOrders();

      // Đồng bộ lại chi tiêu và thứ hạng cho danh sách khách hàng
      for (int i = 0; i < customers.length; i++) {
        final email = customers[i].email;
        customers[i] = customers[i].copyWith(
          totalSpent: getCustomerTotalSpent(email),
          totalOrders: getCustomerTotalOrders(email),
          memberTier: getCustomerMemberTier(email),
        );
      }
      await _saveCustomers();
    } catch (e) {
      print("MongoDB Refresh Orders Error: $e");
    }
  }

  static List<Order> getOrdersForCustomer(String? email) {
    if (email == null || email.trim().isEmpty) return [];
    final target = email.trim().toLowerCase();
    return orders
        .where((o) => o.customerEmail?.trim().toLowerCase() == target)
        .toList();
  }

  static double getCustomerTotalSpent(String? customerEmail) {
    if (customerEmail == null || customerEmail.trim().isEmpty) return 0.0;
    final email = customerEmail.trim().toLowerCase();
    final validOrders = orders.where((o) =>
      o.customerEmail != null &&
      o.customerEmail!.trim().toLowerCase() == email &&
      o.status != OrderStatus.cancelled,
    );
    return validOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  static int getCustomerTotalOrders(String? customerEmail) {
    if (customerEmail == null || customerEmail.trim().isEmpty) return 0;
    final email = customerEmail.trim().toLowerCase();
    return orders.where((o) =>
      o.customerEmail != null &&
      o.customerEmail!.trim().toLowerCase() == email &&
      o.status != OrderStatus.cancelled,
    ).length;
  }

  static String getCustomerMemberTier(String? customerEmail) {
    final spent = getCustomerTotalSpent(customerEmail);
    return spent >= 2000000 ? 'Vàng' : (spent >= 500000 ? 'Bạc' : 'Đồng');
  }

  static Future<void> syncCustomerSpending(String customerEmail) async {
    final email = customerEmail.trim().toLowerCase();
    if (email.isEmpty) return;

    final realSpent = getCustomerTotalSpent(email);
    final realOrders = getCustomerTotalOrders(email);
    final realTier = getCustomerMemberTier(email);

    final cIndex = customers.indexWhere((c) => c.email.trim().toLowerCase() == email);
    if (cIndex != -1) {
      final c = customers[cIndex];
      customers[cIndex] = c.copyWith(
        totalSpent: realSpent,
        totalOrders: realOrders,
        memberTier: realTier,
      );
      await _saveCustomers();
    }

    try {
      var colUsers = MongoDBService.getCollection("users");
      await colUsers.updateOne(
        mongo.where.eq('email', email),
        mongo.modify
            .set('totalSpent', realSpent)
            .set('totalOrders', realOrders)
            .set('memberTier', realTier),
      );
    } catch (_) {}
  }

  static Future<void> addOrder(Order order) async {
    orders.insert(0, order);
    await _saveOrders();

    try {
      var col = MongoDBService.getCollection("orders");
      await col.insertOne(order.toJson());
      print("Đã lưu đơn hàng #${order.id} vào MongoDB traicay_db");
    } catch (e) {
      print("MongoDB Error (addOrder): $e");
    }

    // Cập nhật số đơn và tổng chi tiêu của khách hàng (chỉ tính đơn hợp lệ, không tính đơn hủy)
    if (order.customerEmail != null && order.customerEmail!.isNotEmpty) {
      await syncCustomerSpending(order.customerEmail!);
    }
  }

  static Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      orders[index].status = newStatus;
      await _saveOrders();

      String statusString;
      switch (newStatus) {
        case OrderStatus.ready:
          statusString = 'Đã gói xong';
          break;
        case OrderStatus.delivering:
          statusString = 'Đang giao';
          break;
        case OrderStatus.completed:
          statusString = 'Đã hoàn thành';
          break;
        case OrderStatus.cancelled:
          statusString = 'Đã hủy';
          break;
        case OrderStatus.pending:
          statusString = 'Đang xử lý';
          break;
      }

      try {
        var col = MongoDBService.getCollection("orders");
        await col.updateOne(
          mongo.where.eq('id', orderId),
          mongo.modify.set('status', statusString),
        );
      } catch (e) {
        print("MongoDB Error (updateOrderStatus): $e");
      }

      // Tự động gửi thông báo trạng thái đơn hàng cho khách hàng
      final order = orders[index];
      if (order.customerEmail != null && order.customerEmail!.isNotEmpty) {
        String notifTitle = '';
        String notifBody = '';
        switch (newStatus) {
          case OrderStatus.ready:
            notifTitle = 'Đơn hàng #${order.id} đã đóng gói xong 📦';
            notifBody = 'Đơn hàng của bạn đã được tuyển chọn trái cây tươi ngon và sẵn sàng giao.';
            break;
          case OrderStatus.delivering:
            notifTitle = 'Đơn hàng #${order.id} đang trên đường giao 🛵';
            notifBody = 'Tài xế đang vận chuyển trái cây đến địa chỉ của bạn. Vui lòng chú ý điện thoại!';
            break;
          case OrderStatus.completed:
            notifTitle = 'Giao hàng thành công #${order.id} 🎉';
            notifBody = 'Chúc bạn thưởng thức trái cây ngon miệng! Bạn hãy đánh giá sản phẩm để nhận ưu đãi nhé.';
            break;
          case OrderStatus.cancelled:
            notifTitle = 'Đơn hàng #${order.id} đã bị hủy ❌';
            notifBody = order.cancellationReason != null && order.cancellationReason!.isNotEmpty
                ? 'Đơn hàng đã bị hủy. Lý do: ${order.cancellationReason}'
                : 'Đơn hàng đã được cập nhật trạng thái hủy.';
            break;
          default:
            break;
        }

        if (notifTitle.isNotEmpty) {
          await addNotification(
            AppNotification(
              id: 'n_${DateTime.now().millisecondsSinceEpoch}',
              title: notifTitle,
              body: notifBody,
              type: 'order',
              customerEmail: order.customerEmail,
              orderId: order.id,
              createdAt: DateTime.now(),
            ),
          );
        }
        await syncCustomerSpending(order.customerEmail!);
      }
    }
  }

  // --- GÁN SHIPPER CHO ĐƠN HÀNG THỰC TẾ ---
  static Future<void> assignShipperToOrder({
    required String orderId,
    required String shipperName,
    required String shipperPhone,
  }) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    final old = orders[index];
    final updated = old.copyWith(
      status: OrderStatus.delivering,
      assignedShipperName: shipperName,
      assignedShipperPhone: shipperPhone,
    );
    orders[index] = updated;
    await _saveOrders();

    try {
      var col = MongoDBService.getCollection("orders");
      await col.updateOne(
        mongo.where.eq('id', orderId),
        mongo.modify
            .set('status', 'Đang giao')
            .set('assignedShipperName', shipperName)
            .set('assignedShipperPhone', shipperPhone),
      );
    } catch (e) {
      print("MongoDB Error (assignShipperToOrder): $e");
    }

    if (updated.customerEmail != null && updated.customerEmail!.isNotEmpty) {
      await addNotification(
        AppNotification(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Tài xế đang giao đơn #${updated.id} 🛵',
          body: 'Shipper $shipperName (SĐT: $shipperPhone) đang vận chuyển đơn hàng đến địa chỉ của bạn.',
          type: 'order',
          customerEmail: updated.customerEmail,
          orderId: updated.id,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  // --- TỪ CHỐI / HỦY ĐƠN HÀNG VỚI LÝ DO ---
  static Future<void> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    final old = orders[index];
    final updated = old.copyWith(
      status: OrderStatus.cancelled,
      cancellationReason: reason,
    );
    orders[index] = updated;
    await _saveOrders();

    try {
      var col = MongoDBService.getCollection("orders");
      await col.updateOne(
        mongo.where.eq('id', orderId),
        mongo.modify
            .set('status', 'Đã hủy')
            .set('cancellationReason', reason),
      );
    } catch (e) {
      print("MongoDB Error (cancelOrder): $e");
    }

    if (updated.customerEmail != null && updated.customerEmail!.isNotEmpty) {
      await syncCustomerSpending(updated.customerEmail!);
      await addNotification(
        AppNotification(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Đơn hàng #${updated.id} đã bị hủy ❌',
          body: 'Đơn hàng của bạn đã bị hủy. Lý do: $reason',
          type: 'order',
          customerEmail: updated.customerEmail,
          orderId: updated.id,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  // --- QUẢN LÝ DANH MỤC (CATEGORY CRUD) ---
  static String getDefaultCategoryImageUrl(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('nhiệt đới') || lower.contains('xoài')) {
      return 'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&q=80&w=200';
    } else if (lower.contains('nhập khẩu') || lower.contains('táo')) {
      return 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&q=80&w=200';
    } else if (lower.contains('cắt sẵn') || lower.contains('dĩa') || lower.contains('tô')) {
      return 'https://images.unsplash.com/photo-1519996529931-28324d5a630e?auto=format&fit=crop&q=80&w=200';
    } else if (lower.contains('mùa') || lower.contains('vụ') || lower.contains('hè')) {
      return 'https://images.unsplash.com/photo-1546548970-71785318a17b?auto=format&fit=crop&q=80&w=200';
    } else if (lower.contains('thùng') || lower.contains('hộp') || lower.contains('quà')) {
      return 'https://images.unsplash.com/photo-1577234286642-fc512a5f8f11?auto=format&fit=crop&q=80&w=200';
    } else if (lower.contains('việt nam') || lower.contains('nội địa') || lower.contains('chuối')) {
      return 'https://images.unsplash.com/photo-1528825871115-3581a5387919?auto=format&fit=crop&q=80&w=200';
    }
    return 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&q=80&w=200';
  }

  static Future<void> addCategory(Category category) async {
    categories.add(category);
    await _saveCategories();

    try {
      var col = MongoDBService.getCollection("categories");
      await col.insertOne(category.toJson());
    } catch (e) {
      print("MongoDB Error (addCategory): $e");
    }
  }

  static Future<void> updateCategory(Category category) async {
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = category;
      await _saveCategories();

      try {
        var col = MongoDBService.getCollection("categories");
        var modifier = mongo.modify.set('name', category.name);
        if (category.imageUrl != null && category.imageUrl!.isNotEmpty) {
          modifier = modifier.set('imageUrl', category.imageUrl!);
        } else {
          modifier = modifier.unset('imageUrl');
        }
        await col.updateOne(
          mongo.where.eq('id', category.id),
          modifier,
        );
      } catch (e) {
        print("MongoDB Error (updateCategory): $e");
      }
    }
  }

  static Future<bool> deleteCategory(String id) async {
    final cat = categories.firstWhere(
      (c) => c.id == id,
      orElse: () => Category(id: '', name: ''),
    );
    // Kiểm tra xem có sản phẩm nào thuộc danh mục này không
    final hasProducts = products.any(
      (p) => !p.isDeleted && (p.category == cat.name || p.category == id),
    );
    if (hasProducts) {
      return false; // Không xóa khi còn sản phẩm thuộc danh mục
    }

    categories.removeWhere((c) => c.id == id);
    await _saveCategories();

    try {
      var col = MongoDBService.getCollection("categories");
      await col.deleteOne(mongo.where.eq('id', id));
    } catch (e) {
      print("MongoDB Error (deleteCategory): $e");
    }
    return true;
  }

  // --- QUẢN LÝ BANNER THEO MÙA (BANNER CRUD) ---
  static Future<void> addBanner(SeasonalBanner banner) async {
    banners.insert(0, banner);
    await _saveBanners();

    try {
      var col = MongoDBService.getCollection("banners");
      await col.insertOne(banner.toJson());
    } catch (e) {
      print("MongoDB Error (addBanner): $e");
    }
  }

  static Future<void> updateBanner(SeasonalBanner banner) async {
    final index = banners.indexWhere((b) => b.id == banner.id);
    if (index != -1) {
      banners[index] = banner;
      await _saveBanners();

      try {
        var col = MongoDBService.getCollection("banners");
        await col.updateOne(
          mongo.where.eq('id', banner.id),
          mongo.modify
              .set('badge', banner.badge)
              .set('title', banner.title)
              .set('subtitle', banner.subtitle)
              .set('tag', banner.tag)
              .set('category', banner.category)
              .set('image', banner.image)
              .set('colorStart', banner.colorStart)
              .set('colorEnd', banner.colorEnd),
        );
      } catch (e) {
        print("MongoDB Error (updateBanner): $e");
      }
    }
  }

  static Future<bool> deleteBanner(String id) async {
    banners.removeWhere((b) => b.id == id);
    await _saveBanners();

    try {
      var col = MongoDBService.getCollection("banners");
      await col.deleteOne(mongo.where.eq('id', id));
    } catch (e) {
      print("MongoDB Error (deleteBanner): $e");
    }
    return true;
  }

  // --- QUẢN LÝ YÊU CẦU ĐỔI TRẢ / KHIẾU NẠI (RETURNS / CLAIMS) ---
  static Future<void> addReturnRequest(ReturnRequest req) async {
    returnRequests.insert(0, req);
    await _saveReturnRequests();

    try {
      var col = MongoDBService.getCollection("return_requests");
      await col.insertOne(req.toJson());
    } catch (e) {
      print("MongoDB Error (addReturnRequest): $e");
    }

    // Thông báo xác nhận cho khách hàng
    await addNotification(
      AppNotification(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Yêu cầu khiếu nại đã gửi 📦',
        body: 'Yêu cầu khiếu nại cho đơn hàng #${req.orderId} đang được tiếp nhận và xử lý.',
        type: 'return',
        customerEmail: req.customerEmail,
        orderId: req.orderId,
        createdAt: DateTime.now(),
      ),
    );
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
              .set('reason', updatedReq.reason)
              .set('description', updatedReq.description)
              .set('imageUrl', updatedReq.imageUrl)
              .set('updatedAt', DateTime.now().toIso8601String()),
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

  static Future<void> replyReturnRequest({
    required String requestId,
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
        print("MongoDB Error (replyReturnRequest): $e");
      }

      final statusVi = status == 'approved' ? 'CHẤP THUẬN' : 'TỪ CHỐI';
      await addNotification(
        AppNotification(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Phản hồi khiếu nại đơn #${req.orderId} 📢',
          body: 'Yêu cầu của bạn đã được $statusVi. Phản hồi của Shop: $reply',
          type: 'return',
          customerEmail: req.customerEmail,
          orderId: req.orderId,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  // --- HỆ THỐNG THÔNG BÁO (NOTIFICATIONS) ---
  static Future<void> addNotification(AppNotification notif) async {
    notifications.insert(0, notif);
    await _saveNotifications();

    try {
      var col = MongoDBService.getCollection("notifications");
      await col.insertOne(notif.toJson());
    } catch (e) {
      print("MongoDB Error (addNotification): $e");
    }
  }

  static Future<void> markNotificationRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      await _saveNotifications();

      try {
        var col = MongoDBService.getCollection("notifications");
        await col.updateOne(
          mongo.where.eq('id', id),
          mongo.modify.set('isRead', true),
        );
      } catch (_) {}
    }
  }

  static Future<void> markAllNotificationsRead(String? customerEmail) async {
    final email = customerEmail?.trim().toLowerCase();
    for (var n in notifications) {
      if (email == null || n.customerEmail == null || n.customerEmail!.toLowerCase() == email) {
        n.isRead = true;
      }
    }
    await _saveNotifications();

    try {
      var col = MongoDBService.getCollection("notifications");
      if (email != null) {
        await col.updateMany(
          mongo.where.eq('customerEmail', email),
          mongo.modify.set('isRead', true),
        );
      } else {
        await col.updateMany(
          mongo.where.exists('id'),
          mongo.modify.set('isRead', true),
        );
      }
    } catch (_) {}
  }

  static List<AppNotification> getNotificationsForUser(String? customerEmail) {
    if (customerEmail == null || customerEmail.trim().isEmpty) {
      return notifications.where((n) => n.customerEmail == null).toList();
    }
    final target = customerEmail.trim().toLowerCase();
    return notifications
        .where((n) => n.customerEmail == null || n.customerEmail!.toLowerCase() == target)
        .toList();
  }

  static int getUnreadNotificationCount(String? customerEmail) {
    return getNotificationsForUser(customerEmail).where((n) => !n.isRead).length;
  }

  // --- QUẢN LÝ KHO (5 CHỨC NĂNG WAREHOUSE) ---
  // Chức năng 1: Nhập kho trái cây (+ tồn kho, ghi nhận chi phí & đối tác)
  static Future<void> recordStockIn({
    required String productId,
    required int quantity,
    required double costPrice,
    String? supplier,
    required String reason,
    String creatorName = 'Admin',
  }) async {
    final pIndex = products.indexWhere((p) => p.id == productId);
    if (pIndex == -1) return;

    final product = products[pIndex];
    final prevStock = product.stock;
    final newStock = prevStock + quantity;

    products[pIndex] = product.copyWith(stock: newStock);
    await _saveProducts();

    final tx = StockTransaction(
      id: 'tx_in_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      productName: product.name,
      type: 'in',
      quantity: quantity,
      previousStock: prevStock,
      newStock: newStock,
      costPrice: costPrice,
      partner: supplier ?? 'Nhà vườn đối tác',
      reason: reason,
      createdAt: DateTime.now(),
      creatorName: creatorName,
    );
    stockTransactions.insert(0, tx);
    await _saveStockTransactions();

    try {
      var colProducts = MongoDBService.getCollection("products");
      await colProducts.updateOne(
        mongo.where.eq('id', productId),
        mongo.modify.set('stock', newStock),
      );
      var colTx = MongoDBService.getCollection("stock_transactions");
      await colTx.insertOne(tx.toJson());
    } catch (e) {
      print("MongoDB Error (recordStockIn): $e");
    }
  }

  // Chức năng 2: Xuất kho trái cây (- tồn kho, ghi nhận lý do: Bán sỉ, Chuyển cơ sở, Xuất mẫu, Quà tặng)
  static Future<bool> recordStockOut({
    required String productId,
    required int quantity,
    required String reason,
    String? recipient,
    String creatorName = 'Admin',
  }) async {
    final pIndex = products.indexWhere((p) => p.id == productId);
    if (pIndex == -1) return false;

    final product = products[pIndex];
    if (product.stock < quantity) return false;

    final prevStock = product.stock;
    final newStock = prevStock - quantity;

    products[pIndex] = product.copyWith(stock: newStock);
    await _saveProducts();

    final tx = StockTransaction(
      id: 'tx_out_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      productName: product.name,
      type: 'out',
      quantity: quantity,
      previousStock: prevStock,
      newStock: newStock,
      partner: recipient,
      reason: reason,
      createdAt: DateTime.now(),
      creatorName: creatorName,
    );
    stockTransactions.insert(0, tx);
    await _saveStockTransactions();

    try {
      var colProducts = MongoDBService.getCollection("products");
      await colProducts.updateOne(
        mongo.where.eq('id', productId),
        mongo.modify.set('stock', newStock),
      );
      var colTx = MongoDBService.getCollection("stock_transactions");
      await colTx.insertOne(tx.toJson());
    } catch (e) {
      print("MongoDB Error (recordStockOut): $e");
    }
    return true;
  }

  // Chức năng 3: Kiểm kê số lượng tồn kho (Đối soát thực tế vs sổ sách và tự động cân bằng chênh lệch)
  static Future<void> recordStockAudit({
    required String productId,
    required int actualStock,
    required String reason,
    String creatorName = 'Admin',
  }) async {
    final pIndex = products.indexWhere((p) => p.id == productId);
    if (pIndex == -1) return;

    final product = products[pIndex];
    final prevStock = product.stock;
    final diff = actualStock - prevStock;

    products[pIndex] = product.copyWith(stock: actualStock);
    await _saveProducts();

    final tx = StockTransaction(
      id: 'tx_audit_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      productName: product.name,
      type: 'audit',
      quantity: diff.abs(),
      previousStock: prevStock,
      newStock: actualStock,
      reason: '$reason (Chênh lệch: ${diff >= 0 ? "+$diff" : "$diff"})',
      createdAt: DateTime.now(),
      creatorName: creatorName,
    );
    stockTransactions.insert(0, tx);
    await _saveStockTransactions();

    try {
      var colProducts = MongoDBService.getCollection("products");
      await colProducts.updateOne(
        mongo.where.eq('id', productId),
        mongo.modify.set('stock', actualStock),
      );
      var colTx = MongoDBService.getCollection("stock_transactions");
      await colTx.insertOne(tx.toJson());
    } catch (e) {
      print("MongoDB Error (recordStockAudit): $e");
    }
  }

  // Chức năng 4: Cảnh báo trái cây tồn kho thấp (< threshold, mặc định 10)
  static List<Product> getLowStockProducts([int threshold = 10]) {
    return products.where((p) => !p.isDeleted && p.stock < threshold).toList();
  }

  // Chức năng 5: Quản lý trái cây hư hỏng / hao hụt (- tồn kho, ghi nhận nguyên nhân dập nát, hỏng cuống)
  static Future<bool> recordDamagedStock({
    required String productId,
    required int quantity,
    required String reason,
    String creatorName = 'Admin',
  }) async {
    final pIndex = products.indexWhere((p) => p.id == productId);
    if (pIndex == -1) return false;

    final product = products[pIndex];
    final actualDiscard = quantity > product.stock ? product.stock : quantity;
    final prevStock = product.stock;
    final newStock = prevStock - actualDiscard;

    products[pIndex] = product.copyWith(stock: newStock);
    await _saveProducts();

    final tx = StockTransaction(
      id: 'tx_dmg_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      productName: product.name,
      type: 'damage',
      quantity: actualDiscard,
      previousStock: prevStock,
      newStock: newStock,
      reason: 'Hư hỏng: $reason',
      createdAt: DateTime.now(),
      creatorName: creatorName,
    );
    stockTransactions.insert(0, tx);
    await _saveStockTransactions();

    try {
      var colProducts = MongoDBService.getCollection("products");
      await colProducts.updateOne(
        mongo.where.eq('id', productId),
        mongo.modify.set('stock', newStock),
      );
      var colTx = MongoDBService.getCollection("stock_transactions");
      await colTx.insertOne(tx.toJson());
    } catch (e) {
      print("MongoDB Error (recordDamagedStock): $e");
    }
    return true;
  }

  // --- REVIEWS API (Đánh giá người dùng thật kết nối MongoDB traicay_db) ---
  static Future<void> refreshReviews() async {
    try {
      var colReviews = MongoDBService.getCollection("reviews");
      try {
        await colReviews.deleteMany(mongo.where.eq('userName', 'Nguyễn Văn A'));
        await colReviews.deleteMany(mongo.where.eq('userName', 'Trần Thị B'));
        await colReviews.deleteMany(mongo.where.eq('userName', 'Lê Văn C'));
      } catch (_) {}

      var remoteReviews = await colReviews.find().toList();
      reviews = remoteReviews
          .map((e) => Review.fromJson(e))
          .where(
            (r) =>
                r.userName != 'Nguyễn Văn A' &&
                r.userName != 'Trần Thị B' &&
                r.userName != 'Lê Văn C',
          )
          .toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveReviews();
    } catch (e) {
      print("MongoDB Refresh Reviews Error: $e");
    }
  }

  static List<Review> getReviewsForProduct(
    String productId, [
    String? productName,
    bool includeHidden = false,
  ]) {
    final pid = productId.trim().toLowerCase();
    final pname = (productName ?? '').trim().toLowerCase();

    return reviews.where((r) {
      if (r.userName == 'Nguyễn Văn A' ||
          r.userName == 'Trần Thị B' ||
          r.userName == 'Lê Văn C') {
        return false;
      }

      if (!includeHidden && r.isHidden) {
        return false;
      }

      final rPid = r.productId.trim().toLowerCase();
      final rPname = (r.productName ?? '').trim().toLowerCase();

      // Khớp theo ID sản phẩm
      if (pid.isNotEmpty && rPid.isNotEmpty && rPid == pid) return true;

      // Khớp theo Tên sản phẩm (VD: Táo Envy New Zealand)
      if (pname.isNotEmpty && rPname.isNotEmpty) {
        if (rPname == pname ||
            rPname.contains(pname) ||
            pname.contains(rPname)) {
          return true;
        }
        // Khớp đặc biệt cho nhóm Táo
        if (pname.contains('táo') && rPname.contains('táo')) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  static double getAverageRatingForProduct(
    String productId, [
    String? productName,
  ]) {
    final validReviews = getReviewsForProduct(productId, productName, false);
    if (validReviews.isEmpty) {
      final pIndex = products.indexWhere(
        (p) =>
            p.id == productId || (productName != null && p.name == productName),
      );
      if (pIndex != -1) return products[pIndex].rating;
      return 5.0;
    }
    final avg =
        validReviews.map((r) => r.rating).reduce((a, b) => a + b) /
        validReviews.length;
    return double.parse(avg.toStringAsFixed(1));
  }

  static int getSoldCountForProduct(String productId, [String? productName]) {
    final pid = productId.trim().toLowerCase();
    final pname = (productName ?? '').trim().toLowerCase();
    int count = 0;
    for (final order in orders) {
      if (order.status == OrderStatus.cancelled) continue;
      for (final item in order.items) {
        final itemId = (item['productId'] ?? '').toString().trim().toLowerCase();
        final itemName = (item['productName'] ?? item['name'] ?? '').toString().trim().toLowerCase();
        if ((pid.isNotEmpty && itemId == pid) || (pname.isNotEmpty && itemName == pname)) {
          count += (item['quantity'] as num?)?.toInt() ?? 1;
        }
      }
    }
    return count;
  }

  static Future<void> _updateProductRating(
    String productId,
    String? productName,
  ) async {
    final roundedRating = getAverageRatingForProduct(productId, productName);
    final pIndex = products.indexWhere(
      (p) =>
          p.id == productId || (productName != null && p.name == productName),
    );
    if (pIndex != -1) {
      final p = products[pIndex];
      products[pIndex] = Product(
        id: p.id,
        name: p.name,
        description: p.description,
        price: p.price,
        unit: p.unit,
        imageUrl: p.imageUrl,
        stock: p.stock,
        category: p.category,
        origin: p.origin,
        freshness: p.freshness,
        rating: roundedRating,
        isActive: p.isActive,
        isDeleted: p.isDeleted,
      );
      await _saveProducts();

      try {
        var colProducts = MongoDBService.getCollection("products");
        await colProducts.updateOne(
          mongo.where.eq('id', p.id),
          mongo.modify.set('rating', roundedRating),
        );
      } catch (_) {}
    }
  }

  static Future<void> addReview(Review review) async {
    reviews.insert(0, review);
    await _saveReviews();

    try {
      var col = MongoDBService.getCollection("reviews");
      await col.insertOne(review.toJson());
      print(
        "Đã lưu đánh giá thực tế của ${review.userName} vào MongoDB traicay_db",
      );
    } catch (e) {
      print("MongoDB Error (addReview): $e");
    }

    await _updateProductRating(review.productId, review.productName);
  }

  static Future<void> updateReview(
    String reviewId, {
    int? rating,
    String? comment,
    String? imageUrl,
    bool? hasImage,
  }) async {
    final index = reviews.indexWhere((r) => r.id == reviewId);
    if (index == -1) return;

    final old = reviews[index];
    final updated = old.copyWith(
      rating: rating,
      comment: comment,
      imageUrl: imageUrl,
      hasImage: hasImage ?? (imageUrl != null && imageUrl.isNotEmpty),
      updatedAt: DateTime.now(),
    );
    reviews[index] = updated;
    await _saveReviews();

    try {
      var col = MongoDBService.getCollection("reviews");
      await col.updateOne(
        mongo.where.eq('id', reviewId),
        mongo.modify
            .set('rating', updated.rating)
            .set('comment', updated.comment)
            .set('hasImage', updated.hasImage)
            .set('imageUrl', updated.imageUrl)
            .set('updatedAt', updated.updatedAt?.toIso8601String()),
      );
    } catch (e) {
      print("MongoDB Error (updateReview): $e");
    }

    await _updateProductRating(updated.productId, updated.productName);
  }

  static Future<void> deleteReview(String reviewId) async {
    final index = reviews.indexWhere((r) => r.id == reviewId);
    if (index == -1) return;
    final r = reviews.removeAt(index);
    await _saveReviews();

    try {
      var col = MongoDBService.getCollection("reviews");
      await col.deleteOne(mongo.where.eq('id', reviewId));
    } catch (e) {
      print("MongoDB Error (deleteReview): $e");
    }

    await _updateProductRating(r.productId, r.productName);
  }

  static Future<void> replyReview(String reviewId, String reply) async {
    final index = reviews.indexWhere((r) => r.id == reviewId);
    if (index == -1) return;

    final updated = reviews[index].copyWith(
      adminReply: reply,
      adminReplyAt: DateTime.now(),
    );
    reviews[index] = updated;
    await _saveReviews();

    try {
      var col = MongoDBService.getCollection("reviews");
      await col.updateOne(
        mongo.where.eq('id', reviewId),
        mongo.modify
            .set('adminReply', reply)
            .set('adminReplyAt', updated.adminReplyAt?.toIso8601String()),
      );
    } catch (e) {
      print("MongoDB Error (replyReview): $e");
    }
  }

  static Future<void> toggleHideReview(String reviewId, bool isHidden) async {
    final index = reviews.indexWhere((r) => r.id == reviewId);
    if (index == -1) return;

    final updated = reviews[index].copyWith(isHidden: isHidden);
    reviews[index] = updated;
    await _saveReviews();

    try {
      var col = MongoDBService.getCollection("reviews");
      await col.updateOne(
        mongo.where.eq('id', reviewId),
        mongo.modify.set('isHidden', isHidden),
      );
    } catch (e) {
      print("MongoDB Error (toggleHideReview): $e");
    }

    await _updateProductRating(updated.productId, updated.productName);
  }

  static bool hasPurchasedProduct(
    String userEmail,
    String productId, [
    String? productName,
  ]) {
    final email = userEmail.trim().toLowerCase();
    if (email.isEmpty) return false;

    final userOrders = orders
        .where((o) => (o.customerEmail ?? '').toLowerCase() == email)
        .toList();
    if (userOrders.isEmpty) return false;

    final pid = productId.trim().toLowerCase();
    final pname = (productName ?? '').trim().toLowerCase();

    for (var o in userOrders) {
      if (o.status == OrderStatus.cancelled) continue;
      for (var item in o.items) {
        final itemId = item['productId']?.toString().toLowerCase() ?? '';
        final itemName = item['productName']?.toString().toLowerCase() ?? '';
        if (pid.isNotEmpty && (itemId == pid || itemName.contains(pid))) return true;
        if (pname.isNotEmpty && (itemName == pname || itemName.contains(pname))) return true;
      }
      final summary = o.itemsSummary.toLowerCase();
      if (pid.isNotEmpty && summary.contains(pid)) return true;
      if (pname.isNotEmpty && summary.contains(pname)) return true;

      final pIndex = products.indexWhere((p) => p.id.toLowerCase() == pid);
      if (pIndex != -1) {
        final pRealName = products[pIndex].name.toLowerCase();
        if (summary.contains(pRealName)) return true;
      }
    }
    return false;
  }

  // --- QUẢN LÝ CHAT & HỖ TRỢ KHÁCH HÀNG (MODULE 11) ---
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
    } else if (message.senderRole == 'admin') {
      await addNotification(
        AppNotification(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Tin nhắn mới từ CSKH 💬',
          body: message.message.isNotEmpty ? message.message : 'CSKH đã gửi phản hồi cho bạn.',
          type: 'chat',
          customerEmail: message.conversationId,
          createdAt: DateTime.now(),
        ),
      );
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
