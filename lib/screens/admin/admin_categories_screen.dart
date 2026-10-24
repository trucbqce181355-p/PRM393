import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Category> get _filteredCategories {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return DataService.categories;
    return DataService.categories.where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  int _getProductCount(Category cat) {
    return DataService.products
        .where((p) => !p.isDeleted && (p.category == cat.name || p.category == cat.id))
        .length;
  }

  void _showAddEditDialog([Category? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isEdit ? Icons.edit : Icons.add_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(isEdit ? 'Sửa danh mục' : 'Thêm danh mục mới', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tên danh mục trái cây:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Trái Cây Sấy Khô, Nước Ép Tươi...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                SnackbarHelper.showError(context, 'Tên danh mục không được để trống');
                return;
              }

              Navigator.pop(ctx);
              if (isEdit) {
                await DataService.updateCategory(Category(id: existing.id, name: name));
                if (mounted) SnackbarHelper.showSuccess(context, 'Đã cập nhật danh mục "$name"');
              } else {
                final newCat = Category(
                  id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                );
                await DataService.addCategory(newCat);
                if (mounted) SnackbarHelper.showSuccess(context, 'Đã thêm danh mục "$name"');
              }
              setState(() {});
            },
            child: Text(isEdit ? 'Cập nhật' : 'Thêm mới'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Category cat) {
    final count = _getProductCount(cat);
    if (count > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Không thể xóa'),
            ],
          ),
          content: Text(
            'Danh mục "${cat.name}" hiện đang có $count sản phẩm trực thuộc. '
            'Vui lòng xóa hoặc đổi danh mục cho các sản phẩm đó trước khi xóa danh mục này.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa danh mục'),
        content: Text('Bạn có chắc chắn muốn xóa danh mục "${cat.name}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await DataService.deleteCategory(cat.id);
              if (ok) {
                if (mounted) SnackbarHelper.showSuccess(context, 'Đã xóa danh mục "${cat.name}"');
                setState(() {});
              } else {
                if (mounted) SnackbarHelper.showError(context, 'Không thể xóa danh mục này');
              }
            },
            child: const Text('Xóa ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quản lý Danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm danh mục'),
      ),
      body: Column(
        children: [
          // Search & Summary Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm danh mục...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng cộng: ${DataService.categories.length} danh mục',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${DataService.products.where((p) => !p.isDeleted).length} sản phẩm',
                      style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('Chưa có danh mục nào phù hợp', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final count = _getProductCount(cat);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green.shade50,
                                radius: 22,
                                child: const Icon(Icons.folder_open, color: Colors.green, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$count sản phẩm đang bán',
                                      style: TextStyle(
                                        color: count > 0 ? Colors.green.shade700 : Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                tooltip: 'Sửa danh mục',
                                onPressed: () => _showAddEditDialog(cat),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Xóa danh mục',
                                onPressed: () => _confirmDelete(cat),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
