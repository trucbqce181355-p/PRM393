import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/data_service.dart';
import '../../utils/format_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/snackbar_helper.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Tất cả'; // Tất cả, Còn hàng, Sắp hết, Hết hàng
  String _selectedCategory = 'Tất cả';

  List<Product> get _filteredProducts {
    return DataService.products.where((p) {
      if (p.isDeleted == true) return false;

      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'Tất cả' || p.category == _selectedCategory;

      bool matchesStock = true;
      if (_selectedFilter == 'Còn hàng') {
        matchesStock = p.stock > 10;
      } else if (_selectedFilter == 'Sắp hết') {
        matchesStock = p.stock > 0 && p.stock <= 10;
      } else if (_selectedFilter == 'Hết hàng') {
        matchesStock = p.stock == 0;
      }

      return matchesSearch && matchesCategory && matchesStock;
    }).toList();
  }

  // Statistics
  int get _totalProducts => DataService.products.where((p) => p.isDeleted != true).length;
  int get _totalStockUnits => DataService.products
      .where((p) => p.isDeleted != true)
      .fold(0, (sum, p) => sum + p.stock);
  int get _lowStockCount => DataService.products
      .where((p) => p.isDeleted != true && p.stock > 0 && p.stock <= 10)
      .length;
  int get _outOfStockCount => DataService.products
      .where((p) => p.isDeleted != true && p.stock == 0)
      .length;

  // --- Dialog: Nhập kho (Stock In) ---
  void _showStockInDialog(Product product) {
    int addQuantity = 10;
    final quantityController = TextEditingController(text: '10');
    final supplierController = TextEditingController(text: product.origin);
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final newStock = product.stock + addQuantity;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_business_rounded, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Nhập kho trái cây',
                            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Product info preview
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AppImage(imageUrl: product.imageUrl, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tồn kho hiện tại: ${product.stock} ${product.unit}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Input quantity
                  Text('Số lượng nhập thêm (${product.unit}) *',
                      style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (addQuantity > 1) {
                            setModalState(() {
                              addQuantity--;
                              quantityController.text = addQuantity.toString();
                            });
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                      ),
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val) ?? 0;
                            setModalState(() {
                              addQuantity = parsed;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setModalState(() {
                            addQuantity++;
                            quantityController.text = addQuantity.toString();
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                      ),
                    ],
                  ),

                  // Quick quantity chips
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [10, 20, 50, 100].map((q) {
                      return ActionChip(
                        label: Text('+$q ${product.unit}'),
                        backgroundColor: addQuantity == q ? Colors.green.shade50 : const Color(0xFFF3F4F6),
                        labelStyle: TextStyle(
                          color: addQuantity == q ? Colors.green.shade800 : Colors.black87,
                          fontWeight: addQuantity == q ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onPressed: () {
                          setModalState(() {
                            addQuantity = q;
                            quantityController.text = q.toString();
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),
                  // Supplier / Origin
                  const Text('Nhà cung cấp / Nguồn nhập',
                      style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: supplierController,
                    decoration: InputDecoration(
                      hintText: 'VD: Nông trại Đà Lạt / Nhập khẩu...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 14),
                  // Note
                  const Text('Ghi chú phiếu nhập',
                      style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã phiếu, lô hàng, hạn sử dụng...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  // Summary Box
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tồn kho sau khi nhập:',
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                        Text(
                          '$newStock ${product.unit}',
                          style: TextStyle(color: Colors.green.shade800, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Submit button
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: addQuantity <= 0
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await DataService.adjustProductStock(product.id, addQuantity);
                              if (mounted) {
                                SnackbarHelper.showSuccess(
                                  context,
                                  'Đã nhập +$addQuantity ${product.unit} cho "${product.name}"',
                                );
                                setState(() {});
                              }
                            },
                      child: const Text('Xác nhận Nhập Kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Dialog: Xuất kho (Stock Out) ---
  void _showStockOutDialog(Product product) {
    int outQuantity = 5;
    final quantityController = TextEditingController(text: '5');
    final reasons = [
      'Xuất bán sỉ / Doanh nghiệp',
      'Xuất chuyển chi nhánh',
      'Xuất hàng tặng / Dùng thử',
      'Xuất trả nhà cung cấp',
      'Khác',
    ];
    String reason = reasons.first;
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final remaining = product.stock - outQuantity;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.output_rounded, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Xuất kho trái cây',
                            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hiện có trong kho: ${product.stock} ${product.unit}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  Text('Số lượng xuất (${product.unit}) *',
                      style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        outQuantity = int.tryParse(val) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text('Mục đích xuất kho *',
                      style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: reasons.contains(reason) ? reason : reasons.first,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => reason = v);
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text('Ghi chú', style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'Tên đối tác nhận, địa điểm giao...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: remaining < 0 ? Colors.red.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: remaining < 0 ? Colors.red.shade200 : Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          remaining < 0 ? 'Lỗi: Vượt quá tồn kho!' : 'Tồn kho còn lại:',
                          style: TextStyle(
                            color: remaining < 0 ? Colors.red.shade800 : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$remaining ${product.unit}',
                          style: TextStyle(
                            color: remaining < 0 ? Colors.red.shade800 : Colors.blue.shade800,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (outQuantity <= 0 || outQuantity > product.stock)
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await DataService.adjustProductStock(product.id, -outQuantity);
                              if (mounted) {
                                SnackbarHelper.showSuccess(
                                  context,
                                  'Đã xuất kho -$outQuantity ${product.unit} cho "${product.name}"',
                                );
                                setState(() {});
                              }
                            },
                      child: const Text('Xác nhận Xuất Kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Dialog: Kiểm kê tồn kho & Quản lý trái cây hư hỏng (Stock Adjustment / Audit / Spoilage) ---
  void _showStockAdjustmentDialog(Product product) {
    int targetStock = product.stock;
    final stockController = TextEditingController(text: product.stock.toString());
    String reason = 'Kiểm kê thực tế';
    final noteController = TextEditingController();

    final reasons = [
      'Kiểm kê thực tế',
      'Hàng hư hỏng / quá hạn',
      'Hao hụt tự nhiên',
      'Đổi trả từ khách hàng',
      'Sai sót kiểm đếm',
      'Khác',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final delta = targetStock - product.stock;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune_rounded, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          const Text(
                            'Kiểm kê & Điều chỉnh tồn kho',
                            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Số lượng hiện tại trên hệ thống: ${product.stock} ${product.unit}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  Text('Số lượng thực tế sau kiểm kê / trừ hư hỏng (${product.unit}) *',
                      style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        targetStock = int.tryParse(val) ?? product.stock;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text('Lý do điều chỉnh (Kiểm kê / Hư hỏng) *',
                      style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: reasons.contains(reason) ? reason : reasons.first,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => reason = v);
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text('Ghi chú chi tiết',
                      style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'VD: Trái cây bị dập nát 3kg khi vận chuyển...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: delta < 0
                          ? Colors.red.shade50
                          : (delta > 0 ? Colors.green.shade50 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: delta < 0
                            ? Colors.red.shade200
                            : (delta > 0 ? Colors.green.shade200 : Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chênh lệch tồn kho:',
                          style: TextStyle(
                            color: delta < 0 ? Colors.red.shade800 : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          delta > 0 ? '+$delta ${product.unit}' : '$delta ${product.unit}',
                          style: TextStyle(
                            color: delta < 0
                                ? Colors.red.shade800
                                : (delta > 0 ? Colors.green.shade800 : Colors.black87),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: targetStock < 0
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await DataService.updateProductStock(product.id, targetStock);
                              if (mounted) {
                                SnackbarHelper.showSuccess(
                                  context,
                                  'Đã cập nhật tồn kho "${product.name}" thành $targetStock ${product.unit} (Lý do: $reason)',
                                );
                                setState(() {});
                              }
                            },
                      child: const Text('Cập nhật tồn kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

  Widget _buildFilterChip(String label, String countStr, {Color? color}) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? Colors.green.shade600) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($countStr)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryItem(Product product) {
    Color stockBadgeColor;
    String stockStatusText;

    if (product.stock == 0) {
      stockBadgeColor = Colors.red.shade700;
      stockStatusText = 'HẾT HÀNG';
    } else if (product.stock <= 10) {
      stockBadgeColor = Colors.orange.shade800;
      stockStatusText = 'SẮP HẾT';
    } else {
      stockBadgeColor = Colors.green.shade700;
      stockStatusText = 'CÒN HÀNG';
    }

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: product.stock == 0
              ? Colors.red.shade200
              : (product.stock <= 10 ? Colors.orange.shade200 : Colors.grey.shade200),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppImage(imageUrl: product.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: stockBadgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: stockBadgeColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '$stockStatusText: ${product.stock} ${product.unit}',
                              style: TextStyle(color: stockBadgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.category} • ${FormatHelper.formatPrice(product.price)} / ${product.unit}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Xuất xứ: ${product.origin}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Action buttons row (Nhập kho, Xuất kho, Kiểm kê / Hư hỏng)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_business_rounded, size: 16),
                    label: const Text('Nhập Kho', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      side: BorderSide(color: Colors.green.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _showStockInDialog(product),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.output_rounded, size: 16),
                    label: const Text('Xuất Kho', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade800,
                      side: BorderSide(color: Colors.blue.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _showStockOutDialog(product),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Kiểm Kê', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _showStockAdjustmentDialog(product),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final totalCount = _totalProducts;
    final inStockCount = DataService.products.where((p) => p.isDeleted != true && p.stock > 10).length;
    final lowStock = _lowStockCount;
    final outOfStock = _outOfStockCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text(
          'Quản lý Kho hàng & Tồn kho',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // KPI statistics row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _buildStatCard('Tổng tồn', '$_totalStockUnits', Colors.blue.shade700, Icons.inventory_2_rounded),
                const SizedBox(width: 8),
                _buildStatCard('Sắp hết', '$lowStock', Colors.orange.shade800, Icons.warning_amber_rounded),
                const SizedBox(width: 8),
                _buildStatCard('Hết hàng', '$outOfStock', Colors.red.shade700, Icons.cancel_outlined),
              ],
            ),
          ),

          // Search and Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên trái cây, phân loại...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', '$totalCount'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Còn hàng', '$inStockCount', color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      _buildFilterChip('Sắp hết', '$lowStock', color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      _buildFilterChip('Hết hàng', '$outOfStock', color: Colors.red.shade700),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List of inventory items
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Không có sản phẩm nào phù hợp',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildInventoryItem(products[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
