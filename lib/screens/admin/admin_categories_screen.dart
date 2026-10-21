import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/category.dart';
import '../../services/data_service.dart';
import '../../utils/image_helper.dart';
import '../../utils/snackbar_helper.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  String _searchQuery = '';

  List<Category> get _filteredCategories {
    if (_searchQuery.trim().isEmpty) {
      return DataService.categories;
    }
    return DataService.categories
        .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  int _getProductCount(String categoryName) {
    return DataService.products
        .where((p) => p.category == categoryName && p.isDeleted != true)
        .length;
  }

  void _showAddOrEditCategoryDialog({Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    String imageUrl = category?.imageUrl ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_note_rounded : Icons.create_new_folder_rounded,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tên danh mục *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'VD: Trái Cây Nhập Khẩu',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Hình ảnh đại diện (Tùy chọn)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade100,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: imageUrl.isNotEmpty
                            ? AppImage(imageUrl: imageUrl, fit: BoxFit.cover)
                            : const Icon(Icons.category_outlined, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: const Text('Chọn ảnh từ máy', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade800,
                              side: BorderSide(color: Colors.green.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setDialogState(() {
                                  imageUrl = image.path;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              final urlCtrl = TextEditingController(text: imageUrl);
                              showDialog(
                                context: context,
                                builder: (uCtx) => AlertDialog(
                                  title: const Text('Nhập liên kết ảnh'),
                                  content: TextField(
                                    controller: urlCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'https://images.unsplash.com/...',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(uCtx), child: const Text('Hủy')),
                                    ElevatedButton(
                                      onPressed: () {
                                        setDialogState(() {
                                          imageUrl = urlCtrl.text.trim();
                                        });
                                        Navigator.pop(uCtx);
                                      },
                                      child: const Text('Lưu'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Hoặc nhập URL ảnh', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  SnackbarHelper.showError(context, 'Tên danh mục không được để trống');
                  return;
                }

                if (isEditing) {
                  final oldName = category.name;
                  final updated = Category(
                    id: category.id,
                    name: name,
                    imageUrl: imageUrl,
                  );
                  await DataService.updateCategory(updated, oldName: oldName);
                  if (mounted) {
                    SnackbarHelper.showSuccess(context, 'Đã cập nhật danh mục "$name"');
                  }
                } else {
                  final newCat = Category(
                    id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    imageUrl: imageUrl,
                  );
                  await DataService.addCategory(newCat);
                  if (mounted) {
                    SnackbarHelper.showSuccess(context, 'Đã thêm danh mục mới "$name"');
                  }
                }

                Navigator.pop(ctx);
                setState(() {});
              },
              child: Text(isEditing ? 'Lưu thay đổi' : 'Thêm mới'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(Category category) {
    final productCount = _getProductCount(category.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Xóa danh mục'),
          ],
        ),
        content: Text(
          productCount > 0
              ? 'Danh mục "${category.name}" đang có $productCount sản phẩm.\n\nNếu xóa, các sản phẩm này sẽ được tự động chuyển về danh mục "Khác". Bạn có chắc chắn muốn xóa?'
              : 'Bạn có chắc chắn muốn xóa danh mục "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await DataService.deleteCategory(category.id, category.name);
              if (mounted) {
                SnackbarHelper.showSuccess(context, 'Đã xóa danh mục "${category.name}"');
                setState(() {});
              }
            },
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = _filteredCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text(
          'Quản lý Danh mục',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _showAddOrEditCategoryDialog(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Summary
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm danh mục...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng cộng: ${cats.length} danh mục',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${DataService.products.where((p) => p.isDeleted != true).length} sản phẩm',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Categories List
          Expanded(
            child: cats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy danh mục nào',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final cat = cats[index];
                      final count = _getProductCount(cat.name);

                      return Card(
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.green.shade50,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: cat.imageUrl.isNotEmpty
                                      ? AppImage(imageUrl: cat.imageUrl, fit: BoxFit.cover)
                                      : Icon(Icons.eco_rounded, color: Colors.green.shade700, size: 28),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: count > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$count sản phẩm',
                                        style: TextStyle(
                                          color: count > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700, size: 22),
                                tooltip: 'Chỉnh sửa',
                                onPressed: () => _showAddOrEditCategoryDialog(category: cat),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 22),
                                tooltip: 'Xóa',
                                onPressed: () => _confirmDeleteCategory(cat),
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
