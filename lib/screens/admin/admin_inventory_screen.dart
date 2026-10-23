import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/data_service.dart';
import '../../utils/format_helper.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/app_image_helper.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  // Stock filter in Tab 0: 'all' or 'low' (< 10)
  bool _filterLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> get _activeProducts {
    return DataService.products.where((p) => !p.isDeleted).toList();
  }

  List<Product> get _filteredProducts {
    final query = _searchCtrl.text.trim().toLowerCase();
    var list = _activeProducts;
    if (_filterLowStockOnly) {
      list = list.where((p) => p.stock < 10).toList();
    }
    if (query.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(query)).toList();
    }
    return list;
  }

  // --- FUNCTION 1: DIALOG NHẬP KHO TRÁI CÂY ---
  void _showStockInDialog([Product? preselected]) {
    Product? selectedProduct = preselected ?? (_activeProducts.isNotEmpty ? _activeProducts.first : null);
    final qtyCtrl = TextEditingController(text: '50');
    final costCtrl = TextEditingController(text: '50000');
    final supplierCtrl = TextEditingController(text: 'Nhà vườn Đồng Tháp');
    final reasonCtrl = TextEditingController(text: 'Nhập hàng vụ mới');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_shopping_cart, color: Colors.green),
              SizedBox(width: 8),
              Text('Nhập kho trái cây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  isExpanded: true,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: _activeProducts.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (Hiện có: ${p.stock})'))).toList(),
                  onChanged: (val) => setDialogState(() => selectedProduct = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Số lượng nhập:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: selectedProduct?.unit ?? 'kg',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Giá vốn (VNĐ):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Nhà vườn / Nhà cung cấp:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: supplierCtrl,
                  decoration: InputDecoration(
                    hintText: 'Nhà vườn, cảng nhập, hợp tác xã...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Lý do / Ghi chú nhập:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                if (selectedProduct == null) return;
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                final cost = double.tryParse(costCtrl.text.trim()) ?? 0.0;
                if (qty <= 0) {
                  SnackbarHelper.showError(context, 'Số lượng nhập phải lớn hơn 0');
                  return;
                }

                Navigator.pop(ctx);
                await DataService.recordStockIn(
                  productId: selectedProduct!.id,
                  quantity: qty,
                  costPrice: cost,
                  supplier: supplierCtrl.text.trim(),
                  reason: reasonCtrl.text.trim(),
                );
                setState(() {});
                if (mounted) {
                  SnackbarHelper.showSuccess(context, 'Đã nhập thành công $qty ${selectedProduct!.unit} ${selectedProduct!.name}');
                }
              },
              child: const Text('Xác nhận nhập kho'),
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNCTION 2: DIALOG XUẤT KHO TRÁI CÂY ---
  void _showStockOutDialog([Product? preselected]) {
    Product? selectedProduct = preselected ?? (_activeProducts.isNotEmpty ? _activeProducts.first : null);
    final qtyCtrl = TextEditingController(text: '10');
    String selectedReason = 'Xuất bán sỉ / Đại lý';
    final reasons = [
      'Xuất bán sỉ / Đại lý',
      'Chuyển cơ sở / Cửa hàng phụ',
      'Xuất mẫu dùng thử / Hội chợ',
      'Quà biếu tặng đối tác',
      'Lý do khác',
    ];
    final recipientCtrl = TextEditingController(text: 'Đại lý Fruitopia Tân Bình');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.output_rounded, color: Colors.blue),
              SizedBox(width: 8),
              Text('Xuất kho trái cây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn sản phẩm xuất:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  isExpanded: true,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: _activeProducts.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (Tồn: ${p.stock})'))).toList(),
                  onChanged: (val) => setDialogState(() => selectedProduct = val),
                ),
                const SizedBox(height: 12),
                const Text('Số lượng xuất:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    suffixText: selectedProduct?.unit ?? 'kg',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Mục đích / Lý do xuất:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setDialogState(() => selectedReason = val!),
                ),
                const SizedBox(height: 12),
                const Text('Người nhận / Đơn vị tiếp nhận:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: recipientCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () async {
                if (selectedProduct == null) return;
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (qty <= 0) {
                  SnackbarHelper.showError(context, 'Số lượng xuất phải lớn hơn 0');
                  return;
                }
                if (qty > selectedProduct!.stock) {
                  SnackbarHelper.showError(context, 'Số lượng trong kho không đủ (Hiện còn: ${selectedProduct!.stock})');
                  return;
                }

                Navigator.pop(ctx);
                final ok = await DataService.recordStockOut(
                  productId: selectedProduct!.id,
                  quantity: qty,
                  reason: selectedReason,
                  recipient: recipientCtrl.text.trim(),
                );
                setState(() {});
                if (mounted) {
                  if (ok) {
                    SnackbarHelper.showSuccess(context, 'Đã xuất kho $qty ${selectedProduct!.unit} ${selectedProduct!.name}');
                  } else {
                    SnackbarHelper.showError(context, 'Xuất kho thất bại: Tồn kho không đủ');
                  }
                }
              },
              child: const Text('Xác nhận xuất kho'),
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNCTION 3: DIALOG KIỂM KÊ TỒN KHO ---
  void _showAuditDialog(Product product) {
    final actualCtrl = TextEditingController(text: product.stock.toString());
    final reasonCtrl = TextEditingController(text: 'Kiểm kê định kỳ tháng');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final entered = int.tryParse(actualCtrl.text.trim()) ?? product.stock;
          final diff = entered - product.stock;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.fact_check_outlined, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(child: Text('Kiểm kê: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số lượng trên sổ sách:'),
                        Text('${product.stock} ${product.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Số lượng thực tế kiểm đếm:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: actualCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      suffixText: product.unit,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Chênh lệch đối soát: ', style: TextStyle(fontSize: 13)),
                      Text(
                        diff == 0 ? 'Khớp sổ sách' : (diff > 0 ? '+$diff (Thừa)' : '$diff (Thiếu)'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: diff == 0 ? Colors.green : (diff > 0 ? Colors.blue : Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Lý do kiểm kê / Đối soát:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                onPressed: () async {
                  final actual = int.tryParse(actualCtrl.text.trim());
                  if (actual == null || actual < 0) {
                    SnackbarHelper.showError(context, 'Số lượng kiểm đếm không hợp lệ');
                    return;
                  }

                  Navigator.pop(ctx);
                  await DataService.recordStockAudit(
                    productId: product.id,
                    actualStock: actual,
                    reason: reasonCtrl.text.trim(),
                  );
                  setState(() {});
                  if (mounted) {
                    SnackbarHelper.showSuccess(context, 'Đã cập nhật kiểm kê cân bằng kho cho ${product.name}');
                  }
                },
                child: const Text('Cân bằng tồn kho'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- FUNCTION 5: DIALOG BÁO HỎNG / HAO HỤT ---
  void _showDamageDialog([Product? preselected]) {
    Product? selectedProduct = preselected ?? (_activeProducts.isNotEmpty ? _activeProducts.first : null);
    final qtyCtrl = TextEditingController(text: '3');
    String selectedReason = 'Trái cây dập nát do vận chuyển';
    final reasons = [
      'Trái cây dập nát do vận chuyển',
      'Hỏng thối tự nhiên / Quá chín',
      'Nứt vỏ rỉ nước / Lỗi bảo quản lạnh',
      'Hao hụt tự nhiên do bay hơi ẩm',
      'Lý do khác',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Ghi nhận trái cây hư hỏng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn loại quả hư hỏng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  isExpanded: true,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: _activeProducts.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (Tồn: ${p.stock})'))).toList(),
                  onChanged: (val) => setDialogState(() => selectedProduct = val),
                ),
                const SizedBox(height: 12),
                const Text('Số lượng loại bỏ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    suffixText: selectedProduct?.unit ?? 'kg',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Nguyên nhân hư hỏng / hao hụt:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setDialogState(() => selectedReason = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                if (selectedProduct == null) return;
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (qty <= 0) {
                  SnackbarHelper.showError(context, 'Số lượng loại bỏ phải lớn hơn 0');
                  return;
                }

                Navigator.pop(ctx);
                await DataService.recordDamagedStock(
                  productId: selectedProduct!.id,
                  quantity: qty,
                  reason: selectedReason,
                );
                setState(() {});
                if (mounted) {
                  SnackbarHelper.showSuccess(context, 'Đã ghi nhận hủy $qty ${selectedProduct!.unit} ${selectedProduct!.name} bị hư hỏng');
                }
              },
              child: const Text('Xác nhận loại bỏ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = DataService.getLowStockProducts(10).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quản lý Kho & Tồn kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Text('Tồn kho'),
                  if (lowStockCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      child: Text('$lowStockCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Nhập kho (In)'),
            const Tab(text: 'Xuất kho (Out)'),
            const Tab(text: 'Hàng hư hỏng (Damage)'),
            const Tab(text: 'Lịch sử kho (Logs)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Danh sách tồn kho & Cảnh báo tồn thấp (< 10)
          _buildStockListTab(lowStockCount),

          // Tab 2: Phím tắt Nhập kho
          _buildQuickActionTab(
            title: 'Phiếu nhập kho trái cây',
            subtitle: 'Thêm số lượng tồn kho, ghi nhận đơn giá vốn và đối tác nhà vườn.',
            icon: Icons.add_shopping_cart,
            color: Colors.green,
            buttonText: 'Tạo phiếu nhập kho ngay',
            onTap: () => _showStockInDialog(),
          ),

          // Tab 3: Phím tắt Xuất kho
          _buildQuickActionTab(
            title: 'Phiếu xuất kho trái cây',
            subtitle: 'Giảm số lượng tồn kho khi xuất sỉ, chuyển chi nhánh hoặc biếu tặng.',
            icon: Icons.output_rounded,
            color: Colors.blue,
            buttonText: 'Tạo phiếu xuất kho ngay',
            onTap: () => _showStockOutDialog(),
          ),

          // Tab 4: Phím tắt Báo hư hỏng
          _buildQuickActionTab(
            title: 'Ghi nhận trái cây hư hỏng / hao hụt',
            subtitle: 'Giảm tồn kho và ghi nhận lý do dập nát, hỏng cuống, hỏng thời tiết.',
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            buttonText: 'Lập biên bản tiêu hủy quả hỏng',
            onTap: () => _showDamageDialog(),
          ),

          // Tab 5: Lịch sử biến động kho
          _buildStockHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildStockListTab(int lowStockCount) {
    final products = _filteredProducts;

    return Column(
      children: [
        // Summary & Cảnh báo tồn thấp Banner
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_activeProducts.length} Mặt hàng', style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('Đang kinh doanh', style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _filterLowStockOnly = !_filterLowStockOnly),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _filterLowStockOnly ? Colors.red : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$lowStockCount Cảnh báo tồn thấp',
                              style: TextStyle(
                                color: _filterLowStockOnly ? Colors.white : Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _filterLowStockOnly ? 'Đang lọc < 10' : 'Tồn kho < 10 sản phẩm',
                              style: TextStyle(
                                color: _filterLowStockOnly ? Colors.white70 : Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm quả trong kho...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('Không tìm thấy sản phẩm nào trong kho'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final isLow = p.stock < 10;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AppImageHelper.buildImage(
                                    imageUrl: p.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorWidget: Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.green.shade50,
                                      child: const Icon(Icons.eco, color: Colors.green),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text('${p.category} • ${p.origin}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${p.stock} ${p.unit}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isLow ? Colors.red : Colors.green.shade800,
                                      ),
                                    ),
                                    if (isLow)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(6)),
                                        child: const Text('SẮP HẾT', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    side: const BorderSide(color: Colors.green),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: () => _showStockInDialog(p),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Nhập thêm', style: TextStyle(fontSize: 12)),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: () => _showStockOutDialog(p),
                                  icon: const Icon(Icons.output, size: 16),
                                  label: const Text('Xuất kho', style: TextStyle(fontSize: 12)),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.purple,
                                    side: const BorderSide(color: Colors.purple),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: () => _showAuditDialog(p),
                                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                                  label: const Text('Kiểm kê', style: TextStyle(fontSize: 12)),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: () => _showDamageDialog(p),
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('Báo hỏng', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuickActionTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 42),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: onTap,
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockHistoryTab() {
    final list = DataService.stockTransactions;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Chưa có lịch sử biến động kho nào', style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tx = list[index];

        Color color = Colors.green;
        String typeLabel = 'Nhập kho';
        IconData icon = Icons.add_circle_outline;
        if (tx.type == 'out') {
          color = Colors.blue;
          typeLabel = 'Xuất kho';
          icon = Icons.remove_circle_outline;
        } else if (tx.type == 'audit') {
          color = Colors.purple;
          typeLabel = 'Kiểm kê';
          icon = Icons.fact_check_outlined;
        } else if (tx.type == 'damage') {
          color = Colors.red;
          typeLabel = 'Hư hỏng';
          icon = Icons.warning_amber_rounded;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 18),
                        const SizedBox(width: 6),
                        Text(typeLabel, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Text(FormatHelper.formatDateTime(tx.createdAt), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(tx.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Tồn trước: ${tx.previousStock}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const Text('  ➔  ', style: TextStyle(color: Colors.grey)),
                    Text(
                      'Tồn sau: ${tx.newStock}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text('(${tx.type == 'in' ? '+' : '-'}${tx.quantity})', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                if (tx.reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Lý do: ${tx.reason}', style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
                ],
                if (tx.partner != null && tx.partner!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Đối tác: ${tx.partner}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
