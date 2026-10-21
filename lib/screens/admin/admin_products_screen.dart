import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/product.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/format_helper.dart';
import 'admin_add_product_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: Tất cả, 1: Đang bán, 2: Ngưng bán

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    final visibleProducts = DataService.products.where((p) => p.isDeleted != true).toList();
    return visibleProducts.where((p) {
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.origin.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (_selectedFilter == 1) return p.isActive == true;
      if (_selectedFilter == 2) return p.isActive != true;
      return true;
    }).toList();
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Xóa sản phẩm'),
            ],
          ),
          content: Text.rich(
            TextSpan(
              text: 'Bạn có chắc chắn muốn xóa sản phẩm ',
              children: [
                TextSpan(
                  text: product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const TextSpan(
                  text: '?\n\nHành động này không thể hoàn tác.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await DataService.deleteProduct(product.id);
                if (mounted) {
                  setState(() {});
                  SnackbarHelper.showSuccess(context, 'Đã xóa sản phẩm ${product.name}');
                }
              },
              child: const Text('Xác nhận xóa'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final visibleProducts = DataService.products.where((p) => p.isDeleted != true).toList();
    final totalCount = visibleProducts.length;
    final activeCount = visibleProducts.where((p) => p.isActive == true).length;
    final inactiveCount = totalCount - activeCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text(
          'Quản lý sản phẩm',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminAddProductScreen()),
                );
                if (result == true) {
                  setState(() {});
                }
              },
              child: const Text(
                'Thêm sản phẩm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Statistics Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _buildStatCard('Tổng số', '$totalCount', Colors.blue.shade700, Icons.inventory_2),
                const SizedBox(width: 8),
                _buildStatCard('Đang bán', '$activeCount', Colors.green.shade700, Icons.check_circle_outline),
                const SizedBox(width: 8),
                _buildStatCard('Ngưng bán', '$inactiveCount', Colors.orange.shade700, Icons.pause_circle_outline),
              ],
            ),
          ),

          // Search Bar & Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tên sản phẩm, danh mục...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildFilterChip(0, 'Tất cả ($totalCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, 'Đang bán ($activeCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'Ngưng bán ($inactiveCount)'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Product List / Empty State
          Expanded(
            child: products.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int filterIndex, String label) {
    final isSelected = _selectedFilter == filterIndex;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedFilter = filterIndex;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade600 : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isActive = product.isActive == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminAddProductScreen(product: product)),
          );
          if (result == true) {
            setState(() {});
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Box
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
                      ),
                      image: (product.imageUrl.isNotEmpty)
                          ? DecorationImage(
                              image: product.imageUrl.startsWith('http')
                                  ? NetworkImage(product.imageUrl) as ImageProvider
                                  : FileImage(File(product.imageUrl)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (product.imageUrl.isEmpty)
                        ? const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isActive ? Colors.blue.shade700 : Colors.grey.shade700,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Active / Inactive Switch
                            Transform.scale(
                              scale: 0.85,
                              child: Switch(
                                value: isActive,
                                activeColor: Colors.green,
                                onChanged: (val) async {
                                  product.isActive = val;
                                  await DataService.updateProduct(product);
                                  if (mounted) {
                                    setState(() {});
                                    SnackbarHelper.showSuccess(
                                      context,
                                      val
                                          ? 'Đã bật bán "${product.name}"'
                                          : 'Đã tạm ngưng bán "${product.name}"',
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Giá: ${FormatHelper.formatPrice(product.price)} / ${product.unit}',
                          style: TextStyle(
                            color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Danh mục: ${product.category} • Tồn kho: ${product.stock} ${product.unit}',
                              style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                            ),
                            if (product.stock == 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('HẾT HÀNG', style: TextStyle(color: Colors.red.shade800, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ] else if (product.stock <= 10) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('SẮP HẾT', style: TextStyle(color: Colors.orange.shade900, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Xuất xứ: ${product.origin}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.8),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Đang bán' : 'Ngưng bán',
                          style: TextStyle(
                            color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Sửa', style: TextStyle(fontSize: 13)),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AdminAddProductScreen(product: product)),
                          );
                          if (result == true) {
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Xóa', style: TextStyle(fontSize: 13)),
                        onPressed: () => _confirmDeleteProduct(product),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty || _selectedFilter != 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.inventory_2_outlined,
                size: 56,
                color: Colors.green.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'Không tìm thấy sản phẩm phù hợp' : 'Chưa có sản phẩm nào',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Hãy thử tìm kiếm với từ khóa khác hoặc xóa bộ lọc.'
                  : 'Bấm nút bên dưới để thêm sản phẩm trái cây đầu tiên.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (isSearching)
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Đặt lại bộ lọc'),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedFilter = 0;
                  });
                },
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminAddProductScreen()),
                  );
                  if (result == true) {
                    setState(() {});
                  }
                },
                child: const Text('Thêm sản phẩm mới', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
