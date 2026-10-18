import '../../utils/snackbar_helper.dart';
import '../../services/auth_service.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

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

  final List<String> _priceRanges = [
    'Dưới 500.000₫',
    '500.000₫ - 1.000.000₫',
    '1.000.000₫ - 2.000.000₫',
    '2.000.000₫ - 3.000.000₫',
    'Trên 3.000.000₫',
  ];
  final List<String> _selectedPriceRanges = [];

  // Danh mục trái cây
  final List<Map<String, String>> _categories = [
    {
      'name': 'Tất cả',
      'image': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&q=80&w=200',
    },
    {
      'name': 'Trái Cây Nhiệt Đới',
      'image': 'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&q=80&w=200',
    },
    {
      'name': 'Trái Cây Nhập Khẩu',
      'image': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&q=80&w=200',
    },
    {
      'name': 'Trái Cây Theo Mùa',
      'image': 'https://images.unsplash.com/photo-1490818387583-1b5ba22177d0?auto=format&fit=crop&q=80&w=200',
    },
    {
      'name': 'Trái Cây Cắt Sẵn',
      'image': 'https://images.unsplash.com/photo-1519996529931-28324d5a630e?auto=format&fit=crop&q=80&w=200',
    },
    {
      'name': 'Trái Cây Thùng',
      'image': 'https://images.unsplash.com/photo-1589139265215-d7293a1cf552?auto=format&fit=crop&q=80&w=200',
    },
  ];

  // Banner trái cây theo mùa
  final List<Map<String, dynamic>> _seasonalBanners = [
    {
      'badge': 'MÙA VÀNG NHIỆT ĐỚI',
      'title': 'Trái Cây Nhiệt Đới Tươi Mát',
      'subtitle': 'Xoài Cát Chu, Sầu Riêng Ri6 ngọt béo vừa hái',
      'tag': 'ƯU ĐÃI ĐẾN 25%',
      'category': 'Trái Cây Nhiệt Đới',
      'image': 'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&q=80&w=800',
      'gradient': [Color(0xFFE65100), Color(0xFFFF9800)],
    },
    {
      'badge': 'NHẬP KHẨU CAO CẤP',
      'title': 'Táo Envy New Zealand Tươi Giòn',
      'subtitle': 'Nhập khẩu đường bay, thịt giòn tan, vị ngọt đậm',
      'tag': 'CHUẨN GLOBALGAP',
      'category': 'Trái Cây Nhập Khẩu',
      'image': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&q=80&w=800',
      'gradient': [Color(0xFF880E4F), Color(0xFFE91E63)],
    },
    {
      'badge': 'THU HOẠCH HỮU CƠ',
      'title': 'Trái Cây Theo Mùa Tươi Rót',
      'subtitle': 'Nho Mẫu Đơn & Cam Cara ruột đỏ mọng nước',
      'tag': 'FREESHIP TOÀN QUỐC',
      'category': 'Trái Cây Nhập Khẩu',
      'image': 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&q=80&w=800',
      'gradient': [Color(0xFF1B5E20), Color(0xFF4CAF50)],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    final filtered = DataService.products.where((p) {
      if (p.isDeleted || !p.isActive) return false;

      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.origin.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.price.toString().contains(query);

      bool matchesCategory = true;
      if (_selectedCategory != 'Tất cả') {
        final catLower = _selectedCategory.toLowerCase();
        final pCatLower = p.category.toLowerCase();
        if (_selectedCategory == 'Trái Cây Nhiệt Đới') {
          matchesCategory = pCatLower.contains('nhiệt đới') || pCatLower.contains('việt nam');
        } else if (_selectedCategory == 'Trái Cây Nhập Khẩu') {
          matchesCategory = pCatLower.contains('nhập khẩu');
        } else {
          matchesCategory = pCatLower.contains(catLower) || catLower.contains(pCatLower);
        }
      }
      
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
                    'Xin chào !',
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
            if (AuthService.isAdmin)
              IconButton(
                tooltip: 'Về trang quản trị',
                icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.green),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                  );
                },
              ),
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
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm "Táo Envy", xoài, sầu riêng...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: Colors.green, size: 24),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.green, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: PopupMenuButton<String>(
                      initialValue: _selectedSort,
                      onSelected: (String newValue) {
                        setState(() {
                          _selectedSort = newValue;
                        });
                      },
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      itemBuilder: (BuildContext context) {
                        return _sortOptions.map((String value) {
                          return PopupMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                if (value == _selectedSort)
                                  const Icon(Icons.check, size: 16, color: Colors.green)
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
                          Icon(Icons.sort, color: Colors.green, size: 20),
                          SizedBox(width: 6),
                          Text('Sắp xếp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Gợi ý tìm kiếm nhanh (Đặc biệt: Táo Envy)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text('Gợi ý:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    _buildQuickTag('Táo Envy', isHot: true),
                    _buildQuickTag('Trái Cây Nhiệt Đới'),
                    _buildQuickTag('Trái Cây Nhập Khẩu'),
                    _buildQuickTag('Sầu Riêng Ri6'),
                    _buildQuickTag('Xoài Cát Chu'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Banner Trái Cây Theo Mùa (Dev 1 Flow)
              _buildSeasonalBannerSection(),
              const SizedBox(height: 20),

              // Tiêu đề Danh mục
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh Mục Trái Cây',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (_selectedCategory != 'Tất cả')
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'Tất cả';
                        });
                      },
                      child: const Text(
                        'Xem tất cả',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Categories Chips List
              SizedBox(
                height: 124,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return _buildCategoryChip(cat['name']!, cat['image']!);
                  },
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
                                const Divider(height: 1),
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
              const SizedBox(height: 24),

              // Title & Search/Filter Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Kết quả cho "$_searchQuery"'
                            : (_selectedCategory == 'Tất cả' ? 'Trái Cây Tươi Mới' : _selectedCategory),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hiển thị ${_filteredProducts.length} sản phẩm',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  if (_searchQuery.isNotEmpty || _selectedCategory != 'Tất cả')
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _selectedCategory = 'Tất cả';
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 16, color: Colors.red),
                      label: const Text('Đặt lại', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 16),

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
                        childAspectRatio: 0.46, // Đủ chiều cao cho thẻ chi tiết nguồn gốc và độ tươi
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
          if (AuthService.isAdmin) {
            if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen())).then((_) => setState(() {}));
            }
          } else {
            if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())).then((_) => setState(() {}));
            } else if (index == 2) {
              if (AuthService.isLoggedIn) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen())).then((_) => setState(() {}));
              } else {
                _showLoginPopover(context);
              }
            }
          }
        },
        items: AuthService.isAdmin
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
              ]
            : [
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

  Widget _buildQuickTag(String tag, {bool isHot = false}) {
    final isSelected = (_searchQuery.toLowerCase() == tag.toLowerCase()) ||
        (_selectedCategory.toLowerCase() == tag.toLowerCase());
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            if (tag == 'Trái Cây Nhiệt Đới' || tag == 'Trái Cây Nhập Khẩu') {
              _selectedCategory = tag;
              _searchController.clear();
              _searchQuery = '';
            } else {
              _searchController.text = tag;
              _searchQuery = tag;
              _selectedCategory = 'Tất cả';
            }
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.green
                : (isHot ? Colors.red.shade50 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.green
                  : (isHot ? Colors.red.shade300 : Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHot) ...[
                const Icon(Icons.local_fire_department, size: 14, color: Colors.red),
                const SizedBox(width: 4),
              ],
              Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: (isSelected || isHot) ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (isHot ? Colors.red.shade800 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonalBannerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề banner theo mùa
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Banner Trái Cây Theo Mùa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.eco, size: 12, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'TƯƠI MỖI NGÀY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Carousel Slider
        SizedBox(
          height: 175,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _seasonalBanners.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = _seasonalBanners[index];
              final List<Color> gradientColors = banner['gradient'] as List<Color>;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = banner['category'];
                    _searchController.clear();
                    _searchQuery = '';
                  });
                  SnackbarHelper.showSuccess(
                    context,
                    'Đang xem: ${banner['category']} theo mùa',
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Background image
                        Positioned.fill(
                          child: Image.network(
                            banner['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Dark gradient overlay for readability
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.75),
                                  Colors.black.withOpacity(0.35),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      banner['badge'],
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      banner['tag'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    banner['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(color: Colors.black54, blurRadius: 4),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    banner['subtitle'],
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Khám phá ngay',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_seasonalBanners.length, (index) {
            final isActive = _currentBannerIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        width: 100,
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.network(
                imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
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
                color: isSelected ? Colors.green.shade800 : Colors.black87,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                  Row(
                    children: [
                      Icon(Icons.public, size: 11, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.origin.toUpperCase(),
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Freshness badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco, size: 10, color: Colors.green),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            product.freshness,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Prices with unit
                  Row(
                    children: [
                      Text(
                        FormatHelper.formatPrice(product.price),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        ' / ${product.unit}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FormatHelper.formatPrice(oldPrice),
                    style: const TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 10,
                    ),
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
                  if (!AuthService.isAdmin) ...[
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
                  ] else ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Center(
                        child: Text(
                          'XEM CHI TIẾT',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
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
