import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    final imgUrlCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    final isEdit = existing != null;
    String currentImage = existing?.imageUrl ?? '';

    final presets = [
      {'name': 'Xoài (Nhiệt đới)', 'url': 'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&q=80&w=200'},
      {'name': 'Táo (Nhập khẩu)', 'url': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&q=80&w=200'},
      {'name': 'Dĩa trái cây (Cắt sẵn)', 'url': 'https://images.unsplash.com/photo-1519996529931-28324d5a630e?auto=format&fit=crop&q=80&w=200'},
      {'name': 'Cam tươi (Theo mùa)', 'url': 'https://images.unsplash.com/photo-1546548970-71785318a17b?auto=format&fit=crop&q=80&w=200'},
      {'name': 'Hộp quà (Trái cây thùng)', 'url': 'https://images.unsplash.com/photo-1577234286642-fc512a5f8f11?auto=format&fit=crop&q=80&w=200'},
      {'name': 'Chuối vàng (Việt Nam)', 'url': 'https://images.unsplash.com/photo-1528825871115-3581a5387919?auto=format&fit=crop&q=80&w=200'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Widget buildPreviewImage() {
            if (currentImage.isEmpty) {
              return Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: Colors.green, size: 28),
                    SizedBox(height: 2),
                    Text('Chưa có ảnh', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }

            Widget imgWidget;
            if (currentImage.startsWith('http')) {
              imgWidget = Image.network(
                currentImage,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: Colors.red.shade50,
                  child: const Icon(Icons.broken_image, color: Colors.red),
                ),
              );
            } else {
              final file = File(currentImage);
              imgWidget = Image.file(
                file,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: Colors.red.shade50,
                  child: const Icon(Icons.broken_image, color: Colors.red),
                ),
              );
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imgWidget,
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        currentImage = '';
                        imgUrlCtrl.clear();
                      });
                    },
                    child: const CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit : Icons.add_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(isEdit ? 'Sửa danh mục' : 'Thêm danh mục mới', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tên danh mục trái cây:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      autofocus: !isEdit,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Trái Cây Sấy Khô, Nước Ép Tươi...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Hình ảnh danh mục (hiển thị bên trang chủ):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildPreviewImage(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade50,
                                  foregroundColor: Colors.green.shade800,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.green.shade300),
                                  ),
                                ),
                                icon: const Icon(Icons.photo_library_outlined, size: 18),
                                label: const Text('Chọn ảnh từ máy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  try {
                                    final picker = ImagePicker();
                                    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                                    if (file != null) {
                                      setDialogState(() {
                                        currentImage = file.path;
                                        imgUrlCtrl.text = file.path;
                                      });
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      SnackbarHelper.showError(context, 'Không thể chọn ảnh: $e');
                                    }
                                  }
                                },
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: imgUrlCtrl,
                                onChanged: (val) {
                                  setDialogState(() {
                                    currentImage = val.trim();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Hoặc dán link ảnh (https://...)',
                                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Gợi ý ảnh mẫu nhanh:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: presets.map((preset) {
                        final isChosen = currentImage == preset['url'];
                        return ActionChip(
                          avatar: isChosen ? const Icon(Icons.check, size: 14, color: Colors.green) : null,
                          label: Text(preset['name']!, style: TextStyle(fontSize: 11, color: isChosen ? Colors.green.shade900 : Colors.black87)),
                          backgroundColor: isChosen ? Colors.green.shade50 : Colors.grey.shade100,
                          side: BorderSide(color: isChosen ? Colors.green : Colors.grey.shade300),
                          onPressed: () {
                            setDialogState(() {
                              currentImage = preset['url']!;
                              imgUrlCtrl.text = preset['url']!;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
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

                  final finalImg = currentImage.trim().isNotEmpty ? currentImage.trim() : null;

                  Navigator.pop(ctx);
                  if (isEdit) {
                    await DataService.updateCategory(
                      Category(id: existing.id, name: name, imageUrl: finalImg),
                    );
                    if (mounted) SnackbarHelper.showSuccess(context, 'Đã cập nhật danh mục "$name"');
                  } else {
                    final newCat = Category(
                      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      imageUrl: finalImg,
                    );
                    await DataService.addCategory(newCat);
                    if (mounted) SnackbarHelper.showSuccess(context, 'Đã thêm danh mục "$name"');
                  }
                  setState(() {});
                },
                child: Text(isEdit ? 'Cập nhật' : 'Thêm mới'),
              ),
            ],
          );
        },
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

  Widget _buildCategoryThumb(Category cat) {
    final img = (cat.imageUrl != null && cat.imageUrl!.isNotEmpty)
        ? cat.imageUrl!
        : DataService.getDefaultCategoryImageUrl(cat.name);

    if (img.startsWith('http')) {
      return Image.network(
        img,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, color: Colors.green, size: 24),
      );
    } else {
      final file = File(img);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, color: Colors.green, size: 24),
        );
      }
    }
    return const Icon(Icons.eco_rounded, color: Colors.green, size: 24);
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
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm danh mục', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Action Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
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
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Thêm mới', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm danh mục ngay'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.green.shade50,
                                  child: _buildCategoryThumb(cat),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            cat.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                        if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.green.shade200),
                                            ),
                                            child: const Text('Có ảnh riêng', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
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
                                tooltip: 'Sửa danh mục & ảnh',
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
