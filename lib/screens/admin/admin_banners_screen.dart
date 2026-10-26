import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/seasonal_banner.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<SeasonalBanner> get _filteredBanners {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return DataService.banners;
    return DataService.banners.where((b) {
      return b.title.toLowerCase().contains(query) ||
          b.badge.toLowerCase().contains(query) ||
          b.category.toLowerCase().contains(query);
    }).toList();
  }

  void _showAddEditDialog([SeasonalBanner? existing]) {
    final isEdit = existing != null;
    final badgeCtrl = TextEditingController(text: existing?.badge ?? 'MÙA VÀNG NHIỆT ĐỚI');
    final tagCtrl = TextEditingController(text: existing?.tag ?? 'ƯU ĐÃI ĐẾN 25%');
    final titleCtrl = TextEditingController(text: existing?.title ?? 'Trái Cây Nhiệt Đới Tươi Mát');
    final subtitleCtrl = TextEditingController(
      text: existing?.subtitle ?? 'Xoài Cát Chu, Sầu Riêng Ri6 ngọt béo vừa hái',
    );
    final imageCtrl = TextEditingController(
      text: existing?.image ??
          'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&q=80&w=800',
    );

    String selectedCategory = existing?.category ??
        (DataService.categories.isNotEmpty ? DataService.categories.first.name : 'Trái Cây Nhiệt Đới');
    int selectedColorStart = existing?.colorStart ?? 0xFFE65100;
    int selectedColorEnd = existing?.colorEnd ?? 0xFFFF9800;

    final colorPresets = [
      {'name': 'Cam / Vàng', 'start': 0xFFE65100, 'end': 0xFFFF9800},
      {'name': 'Hồng / Đỏ', 'start': 0xFF880E4F, 'end': 0xFFE91E63},
      {'name': 'Xanh lá', 'start': 0xFF1B5E20, 'end': 0xFF4CAF50},
      {'name': 'Xanh dương', 'start': 0xFF0D47A1, 'end': 0xFF1E88E5},
      {'name': 'Tím quý phái', 'start': 0xFF4A148C, 'end': 0xFF7B1FA2},
    ];

    final sampleImages = [
      {'name': 'Xoài vàng', 'url': 'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&q=80&w=800'},
      {'name': 'Táo Envy', 'url': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&q=80&w=800'},
      {'name': 'Trái cây tổng hợp', 'url': 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&q=80&w=800'},
      {'name': 'Dâu tây đỏ', 'url': 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?auto=format&fit=crop&q=80&w=800'},
      {'name': 'Cam mọng nước', 'url': 'https://images.unsplash.com/photo-1546548970-71785318a17b?auto=format&fit=crop&q=80&w=800'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Widget buildBannerBgImage(String path) {
            if (path.isEmpty) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(selectedColorStart), Color(selectedColorEnd)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            }
            if (!path.startsWith('http')) {
              final file = File(path);
              if (file.existsSync()) {
                return Image.file(file, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade400));
              }
            }
            return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade400));
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit : Icons.add_photo_alternate_rounded, color: Colors.green),
                const SizedBox(width: 8),
                Text(isEdit ? 'Sửa Banner Theo Mùa' : 'Thêm Banner Mới', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Preview Header
                    const Text('Xem trước giao diện Banner:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            Positioned.fill(child: buildBannerBgImage(imageCtrl.text.trim())),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.78),
                                      Colors.black.withValues(alpha: 0.35),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                                        child: Text(
                                          badgeCtrl.text.isNotEmpty ? badgeCtrl.text : 'HUY HIỆU',
                                          style: const TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                                        child: Text(
                                          tagCtrl.text.isNotEmpty ? tagCtrl.text : 'TAG ƯU ĐÃI',
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        titleCtrl.text.isNotEmpty ? titleCtrl.text : 'Tiêu đề Banner',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitleCtrl.text.isNotEmpty ? subtitleCtrl.text : 'Mô tả ngắn banner...',
                                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                    const SizedBox(height: 16),

                    // Inputs
                    const Text('Huy hiệu (Badge) & Tag khuyến mãi:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: badgeCtrl,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Huy hiệu',
                              hintText: 'VD: MÙA VÀNG NHIỆT ĐỚI',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: tagCtrl,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Tag ưu đãi',
                              hintText: 'VD: ƯU ĐÃI ĐẾN 25%',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    const Text('Tiêu đề chính của Banner:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Trái Cây Nhiệt Đới Tươi Mát',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Mô tả chi tiết:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subtitleCtrl,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Xoài Cát Chu, Sầu Riêng Ri6 ngọt béo vừa hái',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Liên kết Danh mục lọc:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: (DataService.categories.any((c) => c.name == selectedCategory) || selectedCategory == 'Tất cả')
                              ? selectedCategory
                              : (DataService.categories.isNotEmpty ? DataService.categories.first.name : 'Tất cả'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả sản phẩm')),
                            ...DataService.categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tông màu Gradient
                    const Text('Tông màu Gradient dự phòng:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: colorPresets.map((p) {
                        final isSel = selectedColorStart == p['start'];
                        return ChoiceChip(
                          avatar: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [Color(p['start'] as int), Color(p['end'] as int)]),
                            ),
                          ),
                          label: Text(p['name'] as String, style: const TextStyle(fontSize: 11)),
                          selected: isSel,
                          selectedColor: Colors.green.shade100,
                          onSelected: (_) {
                            setDialogState(() {
                              selectedColorStart = p['start'] as int;
                              selectedColorEnd = p['end'] as int;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Hình ảnh nền
                    const Text('Hình ảnh Banner:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green.shade800,
                            elevation: 0,
                            side: BorderSide(color: Colors.green.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.photo_library_outlined, size: 16),
                          label: const Text('Chọn ảnh từ máy', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            try {
                              final picker = ImagePicker();
                              final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                              if (file != null) {
                                setDialogState(() {
                                  imageCtrl.text = file.path;
                                });
                              }
                            } catch (e) {
                              if (mounted) SnackbarHelper.showError(context, 'Không thể chọn ảnh: $e');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: imageCtrl,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Hoặc dán URL ảnh (https://...)',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Gợi ý ảnh nhanh:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: sampleImages.map((s) {
                        return ActionChip(
                          label: Text(s['name']!, style: const TextStyle(fontSize: 10)),
                          backgroundColor: Colors.grey.shade100,
                          onPressed: () {
                            setDialogState(() {
                              imageCtrl.text = s['url']!;
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
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) {
                    SnackbarHelper.showError(context, 'Tiêu đề banner không được để trống');
                    return;
                  }

                  final newBanner = SeasonalBanner(
                    id: existing?.id ?? 'banner_${DateTime.now().millisecondsSinceEpoch}',
                    badge: badgeCtrl.text.trim().isNotEmpty ? badgeCtrl.text.trim() : 'MÙA VÀNG NHIỆT ĐỚI',
                    title: title,
                    subtitle: subtitleCtrl.text.trim(),
                    tag: tagCtrl.text.trim().isNotEmpty ? tagCtrl.text.trim() : 'ƯU ĐÃI ĐẾN 25%',
                    category: selectedCategory,
                    image: imageCtrl.text.trim(),
                    colorStart: selectedColorStart,
                    colorEnd: selectedColorEnd,
                  );

                  Navigator.pop(ctx);
                  if (isEdit) {
                    await DataService.updateBanner(newBanner);
                    if (mounted) SnackbarHelper.showSuccess(context, 'Đã cập nhật banner "$title"');
                  } else {
                    await DataService.addBanner(newBanner);
                    if (mounted) SnackbarHelper.showSuccess(context, 'Đã thêm banner "$title"');
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

  void _confirmDelete(SeasonalBanner banner) {
    if (DataService.banners.length <= 1) {
      SnackbarHelper.showError(context, 'Cần giữ lại ít nhất 1 banner để hiển thị trên trang chủ');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa Banner'),
        content: Text('Bạn có chắc chắn muốn xóa banner "${banner.title}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await DataService.deleteBanner(banner.id);
              if (ok) {
                if (mounted) SnackbarHelper.showSuccess(context, 'Đã xóa banner');
                setState(() {});
              }
            },
            child: const Text('Xóa ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(SeasonalBanner b) {
    Widget buildBg(String path) {
      if (path.isEmpty) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(b.colorStart), Color(b.colorEnd)]),
          ),
        );
      }
      if (!path.startsWith('http')) {
        final f = File(path);
        if (f.existsSync()) {
          return Image.file(f, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade400));
        }
      }
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade400));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Column(
        children: [
          // Banner Visual Card
          SizedBox(
            height: 150,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                children: [
                  Positioned.fill(child: buildBg(b.image)),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                              child: Text(b.badge, style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                              child: Text(b.tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            Text(b.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Info & Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Liên kết danh mục: ${b.category}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade700,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Sửa'),
                      onPressed: () => _showAddEditDialog(b),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Xóa'),
                      onPressed: () => _confirmDelete(b),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredBanners;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quản lý Banner Theo Mùa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm Banner', style: TextStyle(fontWeight: FontWeight.bold)),
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
          // Top Search & Summary Bar
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
                          hintText: 'Tìm kiếm banner (tiêu đề, huy hiệu, danh mục)...',
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
                      icon: const Icon(Icons.add_circle_outline, size: 18),
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
                      'Tổng cộng: ${DataService.banners.length} banner đang chạy',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Tự động hiển thị slider trang chủ',
                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.view_carousel_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('Chưa có banner nào phù hợp', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm banner ngay'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      return _buildBannerCard(list[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
