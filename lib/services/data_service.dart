import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/voucher.dart';
import '../models/customer.dart';
import '../models/category.dart';
import '../models/review.dart';
import 'mongodb_service.dart';
import 'order_status_service.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class DataService {
  static List<Product> products = [];
  static List<Order> orders = [];
  static List<Voucher> vouchers = [];
  static List<Customer> customers = [];
  static List<Category> categories = [];
  static List<Review> reviews = [];

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
    if (vouchersData != null && vouchersData is List && vouchersData.isNotEmpty) {
      vouchers = vouchersData.map((e) => Voucher.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      vouchers = List.from(defaultVouchers);
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
          .where((r) => r.userName != 'Nguyễn Văn A' && r.userName != 'Trần Thị B' && r.userName != 'Lê Văn C')
          .toList();
    } else {
      reviews = [];
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
            "created_at": DateTime.now().toIso8601String()
          });
        }
        remoteVouchers = await colVouchers.find().toList();
      }
      if (remoteVouchers.isNotEmpty) {
        vouchers = remoteVouchers.map((e) {
          return Voucher(
            code: e['code']?.toString() ?? '',
            description: e['description']?.toString() ?? '',
            discountAmount: (e['discountAmount'] as num?)?.toDouble() ?? (e['discount_percent'] as num?)?.toDouble() ?? 0.0,
            minPurchase: (e['minPurchase'] as num?)?.toDouble() ?? (e['min_order_value'] as num?)?.toDouble() ?? 0.0,
            isActive: e['isActive'] ?? true,
          );
        }).toList();
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
          .where((r) => r.userName != 'Nguyễn Văn A' && r.userName != 'Trần Thị B' && r.userName != 'Lê Văn C')
          .toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveReviews();
      print("Đã đồng bộ ${reviews.length} đánh giá thực tế từ MongoDB traicay_db");

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

  static Future<void> addVoucher(Voucher voucher) async {
    final index = vouchers.indexWhere((v) => v.code.toUpperCase() == voucher.code.toUpperCase());
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
        "discount_percent": voucher.discountAmount,
        "discountAmount": voucher.discountAmount,
        "min_order_value": voucher.minPurchase,
        "minPurchase": voucher.minPurchase,
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
              .set('updated_at', DateTime.now().toIso8601String())
        );
      } catch (e) {
        print("MongoDB Error (updateVoucher): $e");
      }
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
          mongo.modify.set('isActive', isActive)
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
    } catch (e) {
      print("MongoDB Refresh Orders Error: $e");
    }
  }

  static List<Order> getOrdersForCustomer(String? email) {
    if (email == null || email.trim().isEmpty) return [];
    final target = email.trim().toLowerCase();
    return orders.where((o) => o.customerEmail?.trim().toLowerCase() == target).toList();
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

    // Cập nhật số đơn và tổng chi tiêu của khách hàng
    if (order.customerEmail != null && order.customerEmail!.isNotEmpty) {
      final cIndex = customers.indexWhere((c) => c.email.toLowerCase() == order.customerEmail!.toLowerCase());
      if (cIndex != -1) {
        final c = customers[cIndex];
        final newSpent = c.totalSpent + order.totalAmount;
        final newCount = c.totalOrders + 1;
        final newTier = newSpent >= 2000000 ? 'Vàng' : (newSpent >= 500000 ? 'Bạc' : 'Đồng');

        customers[cIndex] = Customer(
          id: c.id,
          name: c.name,
          email: c.email,
          phone: c.phone,
          password: c.password,
          totalSpent: newSpent,
          totalOrders: newCount,
          memberTier: newTier,
          isActive: c.isActive,
        );
        await _saveCustomers();

        try {
          var colUsers = MongoDBService.getCollection("users");
          await colUsers.updateOne(
            mongo.where.eq('email', c.email),
            mongo.modify
                .inc('totalOrders', 1)
                .inc('totalSpent', order.totalAmount)
          );
        } catch (_) {}
      }
    }
  }

  static Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await OrderStatusService.updateStatus(
      orders: orders,
      orderId: orderId,
      status: newStatus,
      saveOrders: _saveOrders,
    );
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
          .where((r) => r.userName != 'Nguyễn Văn A' && r.userName != 'Trần Thị B' && r.userName != 'Lê Văn C')
          .toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveReviews();
    } catch (e) {
      print("MongoDB Refresh Reviews Error: $e");
    }
  }

  static List<Review> getReviewsForProduct(String productId, [String? productName, bool includeHidden = false]) {
    final pid = productId.trim().toLowerCase();
    final pname = (productName ?? '').trim().toLowerCase();

    return reviews.where((r) {
      if (r.userName == 'Nguyễn Văn A' || r.userName == 'Trần Thị B' || r.userName == 'Lê Văn C') {
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
        if (rPname == pname || rPname.contains(pname) || pname.contains(rPname)) {
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

  static double getAverageRatingForProduct(String productId, [String? productName]) {
    final validReviews = getReviewsForProduct(productId, productName, false);
    if (validReviews.isEmpty) {
      final pIndex = products.indexWhere((p) => p.id == productId || (productName != null && p.name == productName));
      if (pIndex != -1) return products[pIndex].rating;
      return 5.0;
    }
    final avg = validReviews.map((r) => r.rating).reduce((a, b) => a + b) / validReviews.length;
    return double.parse(avg.toStringAsFixed(1));
  }

  static Future<void> _updateProductRating(String productId, String? productName) async {
    final roundedRating = getAverageRatingForProduct(productId, productName);
    final pIndex = products.indexWhere((p) => p.id == productId || (productName != null && p.name == productName));
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
      print("Đã lưu đánh giá thực tế của ${review.userName} vào MongoDB traicay_db");
    } catch (e) {
      print("MongoDB Error (addReview): $e");
    }

    await _updateProductRating(review.productId, review.productName);
  }

  static Future<void> updateReview(String reviewId, {int? rating, String? comment, String? imageUrl, bool? hasImage}) async {
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

  static bool hasPurchasedProduct(String userEmail, String productId, [String? productName]) {
    final email = userEmail.trim().toLowerCase();
    if (email.isEmpty) return false;

    final userOrders = orders.where((o) => (o.customerEmail ?? '').toLowerCase() == email).toList();
    if (userOrders.isEmpty) return false;

    final pid = productId.trim().toLowerCase();
    final pname = (productName ?? '').trim().toLowerCase();

    for (var o in userOrders) {
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
}
