import '../../utils/snackbar_helper.dart';
import '../../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../auth/forgot_password_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'cart_screen.dart';
import 'user_profile_screen.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../services/data_service.dart';
import 'product_detail_screen.dart';
import '../../utils/format_helper.dart';
import 'user_vouchers_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  String _selectedSort = 'Sản phẩm nổi bật';

  final List<String> _sortOptions = [
    'Sản phẩm nổi bật',
    'Giá: Tăng dần',
    'Giá: Giảm dần',
    'Tên: A-Z',
    'Tên: Z-A',
    'Cũ nhất',
    'Mới nhất',
    'Bán chạy nhất',
    'Tồn kho giảm dần'
  ];

  List<String> _selectedPriceRanges = [];
  final List<String> _priceRanges = [
    'Dưới 500.000₫',
    '500.000₫ - 1.000.000₫',
    '1.000.000₫ - 2.000.000₫',
    '2.000.000₫ - 3.000.000₫',
    'Trên 3.000.000₫',
  ];

  List<Product> get _filteredProducts {
    final filtered = DataService.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            p.price.toString().contains(_searchQuery);
      final matchesCategory = _selectedCategory == 'Tất cả' || p.category == _selectedCategory;
      
      bool matchesPrice = true;
      if (_selectedPriceRanges.isNotEmpty) {
        matchesPrice = false;
        for (String range in _selectedPriceRanges) {
          if (range == 'Dưới 500.000₫' && p.price < 500000) matchesPrice = true;
          if (range == '500.000₫ - 1.000.000₫' && p.price >= 500000 && p.price <= 1000000) matchesPrice = true;
          if (range == '1.000.000₫ - 2.000.000₫' && p.price >= 1000000 && p.price <= 2000000) matchesPrice = true;
          if (range == '2.000.000₫ - 3.000.000₫' && p.price >= 2000000 && p.price <= 3000000) matchesPrice = true;
          if (range == 'Trên 3.000.000₫' && p.price > 3000000) matchesPrice = true;
        }
      }

      return matchesSearch && matchesCategory && matchesPrice;
    }).toList();

    if (_selectedSort == 'Giá: Tăng dần') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSort == 'Giá: Giảm dần') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    } else if (_selectedSort == 'Tên: A-Z') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (_selectedSort == 'Tên: Z-A') {
      filtered.sort((a, b) => b.name.compareTo(a.name));
    }
    // Default or other options can rely on existing order

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AuthService.userName == null
            ? const Text(
                'Fruitopia',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào, ${AuthService.userName}! ',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    'Mua trái cây tươi',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
        actions: [
          if (AuthService.userName == null) ...[
            GestureDetector(
              onTap: () {
                _showLoginPopover(context);
              },
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Colors.black87, size: 28),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Đăng nhập / Đăng ký', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.normal)),
                      Row(
                        children: const [
                          Text('Tài khoản của tôi', style: TextStyle(color: Colors.black87, fontSize: 12)),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())).then((_) => setState(() {}));
              },
              child: Row(
                children: [
                  Badge(
                    label: Text('${Cart.items.length}'),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.black87, size: 24),
                  ),
                  const SizedBox(width: 4),
                  const Text('Giỏ hàng', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                ],
              ),
            )
          ] else ...[
            IconButton(
              icon: const Icon(Icons.local_offer_outlined, color: Colors.amber),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UserVouchersScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
              onPressed: () {},
            ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                onPressed: () {
                  AuthService.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const UserHomeScreen()),
                    (route) => false,
                  );
                },
              ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              // Search Bar and Sort Dropdown
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sản phẩm...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 28),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1), // Blue border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PopupMenuButton<String>(
                      initialValue: _selectedSort,
                      onSelected: (String newValue) {
                        setState(() {
                          _selectedSort = newValue;
                        });
                      },
                      offset: const Offset(0, 50), // Show menu below the button
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      itemBuilder: (BuildContext context) {
                        return _sortOptions.map((String value) {
                          return PopupMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                if (value == _selectedSort)
                                  const Icon(Icons.check, size: 16, color: Colors.black87)
                                else
                                  const SizedBox(width: 16),
                                const SizedBox(width: 8),
                                Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort_by_alpha, color: Colors.black87, size: 20),
                          SizedBox(width: 8),
                          Text('Sắp xếp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Categories
              SizedBox(
                height: 120, // Increased height for image and text
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip('Trái Cây Nhập Khẩu', 'https://images.unsplash.com/photo-1528825871115-3581a5387919?auto=format&fit=crop&q=80&w=150'),
                    _buildCategoryChip('Trái Cây Việt Nam', 'https://images.unsplash.com/photo-1550985543-f47f38aeea53?auto=format&fit=crop&q=80&w=150'),
                    _buildCategoryChip('Trái Cây Cắt Sẵn', 'https://images.unsplash.com/photo-1519996529931-28324d5a630e?auto=format&fit=crop&q=80&w=150'),
                    _buildCategoryChip('Trái Cây Thùng', 'https://images.unsplash.com/photo-1589139265215-d7293a1cf552?auto=format&fit=crop&q=80&w=150'),
                    _buildCategoryChip('Trái Cây Mùa Hè', 'https://images.unsplash.com/photo-1490818387583-1b5ba22177d0?auto=format&fit=crop&q=80&w=150'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Price Filter & BO LOC
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: Icon(Icons.filter_alt_outlined, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text('BỘ LỌC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: const Text('Lọc giá', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          children: _priceRanges.map((range) {
                            return Column(
                              children: [
                                const Divider(height: 1), // Divider like the image
                                CheckboxListTile(
                                  title: Text(range, style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                                  value: _selectedPriceRanges.contains(range),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedPriceRanges.add(range);
                                      } else {
                                        _selectedPriceRanges.remove(range);
                                      }
                                    });
                                  },
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: const Color(0xFF1976D2),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Title
              const Text('Khuyến Mãi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal, color: Colors.black87)),
              const SizedBox(height: 16),
              const SizedBox(height: 24),

              // Product Grid
              _filteredProducts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('Không tìm thấy sản phẩm nào!')),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.52, // Tăng chiều cao thẻ
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(context, _filteredProducts[index]);
                      },
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())).then((_) => setState(() {}));
          } else if (index == 2) {
            if (AuthService.isLoggedIn) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen())).then((_) => setState(() {}));
            } else {
              _showLoginPopover(context);
            }
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Cart.items.isEmpty 
              ? const Icon(Icons.shopping_cart)
              : Badge(
                  label: Text('${Cart.items.length}'),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.shopping_cart),
                ),
            label: 'Giỏ hàng',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String imageUrl) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          // Unselect if clicking the already selected category
          _selectedCategory = isSelected ? 'Tất cả' : label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        width: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFF1976D2), width: 2) : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.network(
                imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 24),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1976D2) : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    // Fake old price for UI demonstration (-17% discount)
    final oldPrice = product.price * 1.17; 
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
        ).then((_) => setState(() {}));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and Badge
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[100],
                          child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2B6DE1), // Blue badge
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '-38%',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.flash_on, color: Colors.yellow, size: 14),
                          Text('FLASH SALE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, fontStyle: FontStyle.italic)),
                        ]
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Origin
                  const Text(
                    'MỸ',
                    style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  // Title
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Prices
                  Row(
                    children: [
                      Text(
                        FormatHelper.formatPrice(product.price), // Current price
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        FormatHelper.formatPrice(oldPrice), // Old price
                        style: const TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Rating
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) => const Icon(Icons.star_border, color: Colors.amber, size: 14)),
                      ),
                      const SizedBox(width: 4),
                      const Text('0 đánh giá', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Sold
                  const Text(
                    'Đã bán: 4563',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  // Add to Cart Button
                  InkWell(
                    onTap: () {
                      setState(() {
                        Cart.addItem(product, 1);
                      });
                      SnackbarHelper.showSuccess(context, 'Đã thêm ${product.name} vào giỏ hàng');
                    },
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.amber, width: 1.5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Center(
                              child: Text(
                                'THÊM VÀO GIỎ',
                                style: TextStyle(
                                  color: Color(0xFF001E4C), // Dark blue text
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.shopping_bag_outlined, color: Color(0xFF001E4C), size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginPopover(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black12,
      builder: (context) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 80, right: 30),
            child: Material(
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Mũi tên trỏ lên (Arrow up)
                  Positioned(
                    top: -6,
                    right: 70,
                    child: Transform.rotate(
                      angle: 3.14159 / 4, // 45 degrees
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                            left: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Hộp thoại popup
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'ĐĂNG NHẬP TÀI KHOẢN',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nhập email và mật khẩu của bạn:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Mật khẩu',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.5),
                            children: [
                              const TextSpan(text: 'This site is protected by reCAPTCHA and the Google '),
                              TextSpan(text: 'Privacy Policy', style: TextStyle(color: Colors.blue.shade600)),
                              const TextSpan(text: ' and '),
                              TextSpan(text: 'Terms of Service', style: TextStyle(color: Colors.blue.shade600)),
                              const TextSpan(text: ' apply.'),
                            ]
                          )
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A1A), // Đen
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            ),
                            onPressed: () async {
                              final email = emailController.text.trim();
                              final pass = passwordController.text.trim();
                              if (email.isEmpty || pass.isEmpty) {
                                SnackbarHelper.showError(context, 'Vui lòng nhập đủ thông tin');
                                return;
                              }
                              try {
                                final role = await AuthService.login(email, pass);
                                if (context.mounted) {
                                  Navigator.pop(context); // Đóng popover
                                  if (role == 'admin') {
                                    Navigator.pushReplacement(
                                      context, 
                                      MaterialPageRoute(builder: (context) => const AdminDashboardScreen())
                                    );
                                  } else {
                                    setState(() {}); // Làm mới home screen
                                    SnackbarHelper.showSuccess(context, 'Đăng nhập thành công');
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  // Clean up the exception message string since throw Exception adds "Exception: " prefix
                                  String errorMsg = e.toString();
                                  if (errorMsg.startsWith('Exception: ')) {
                                    errorMsg = errorMsg.substring(11);
                                  }
                                  SnackbarHelper.showError(context, errorMsg);
                                }
                              }
                            },
                            child: const Text('ĐĂNG NHẬP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Khách hàng mới? ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                              },
                              child: Text('Tạo tài khoản', style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
                            )
                          ]
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Quên mật khẩu? ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                              },
                              child: Text('Khôi phục mật khẩu', style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
                            )
                          ]
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
