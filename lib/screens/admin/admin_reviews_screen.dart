import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  String _selectedFilter = 'all'; // all, unreplied, replied, hidden
  int? _ratingFilter; // null or 1..5
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await DataService.refreshReviews();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Review> get _filteredReviews {
    return DataService.reviews.where((r) {
      if (_selectedFilter == 'unreplied' && (r.adminReply != null && r.adminReply!.trim().isNotEmpty)) {
        return false;
      }
      if (_selectedFilter == 'replied' && (r.adminReply == null || r.adminReply!.trim().isEmpty)) {
        return false;
      }
      if (_selectedFilter == 'hidden' && !r.isHidden) {
        return false;
      }
      if (_ratingFilter != null && r.rating != _ratingFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchProd = (r.productName ?? '').toLowerCase().contains(query);
        final matchUser = r.userName.toLowerCase().contains(query);
        final matchComment = r.comment.toLowerCase().contains(query);
        if (!matchProd && !matchUser && !matchComment) return false;
      }
      return true;
    }).toList();
  }

  void _showReplyDialog(Review review) {
    final replyController = TextEditingController(text: review.adminReply ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.reply, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              review.adminReply != null ? 'Sửa phản hồi' : 'Phản hồi đánh giá',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đánh giá của ${review.userName}:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${review.comment}"',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: replyController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung phản hồi từ cửa hàng...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = replyController.text.trim();
              if (text.isEmpty) {
                SnackbarHelper.showError(context, 'Vui lòng nhập nội dung phản hồi');
                return;
              }
              Navigator.pop(ctx);
              await DataService.replyReview(review.id, text);
              setState(() {});
              if (mounted) {
                SnackbarHelper.showSuccess(context, 'Đã gửi phản hồi thành công!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Gửi phản hồi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteReview(Review review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa đánh giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Bạn có chắc chắn muốn xóa đánh giá của "${review.userName}" không? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DataService.deleteReview(review.id);
              setState(() {});
              if (mounted) {
                SnackbarHelper.showSuccess(context, 'Đã xóa đánh giá thành công');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredReviews;
    final total = DataService.reviews.length;
    final unrepliedCount = DataService.reviews.where((r) => r.adminReply == null || r.adminReply!.trim().isEmpty).length;
    final hiddenCount = DataService.reviews.where((r) => r.isHidden).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Quản lý Đánh giá', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStatPill('Tất cả', '$total', Colors.blue, _selectedFilter == 'all', () {
                  setState(() => _selectedFilter = 'all');
                }),
                const SizedBox(width: 8),
                _buildStatPill('Chưa trả lời', '$unrepliedCount', Colors.orange, _selectedFilter == 'unreplied', () {
                  setState(() => _selectedFilter = 'unreplied');
                }),
                const SizedBox(width: 8),
                _buildStatPill('Đang ẩn', '$hiddenCount', Colors.red, _selectedFilter == 'hidden', () {
                  setState(() => _selectedFilter = 'hidden');
                }),
              ],
            ),
          ),

          // Search & Star filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên quả, khách hàng, nội dung...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tất cả sao', style: TextStyle(fontSize: 12)),
                        selected: _ratingFilter == null,
                        onSelected: (_) => setState(() => _ratingFilter = null),
                        selectedColor: Colors.green.shade100,
                      ),
                      const SizedBox(width: 6),
                      ...[5, 4, 3, 2, 1].map((star) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$star', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 2),
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                              ],
                            ),
                            selected: _ratingFilter == star,
                            onSelected: (_) => setState(() => _ratingFilter = _ratingFilter == star ? null : star),
                            selectedColor: Colors.amber.shade100,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Reviews List
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy đánh giá nào',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final r = list[index];
                      return _buildAdminReviewCard(r);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String count, Color color, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? color : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminReviewCard(Review r) {
    final dateStr = '${r.createdAt.day.toString().padLeft(2, '0')}/${r.createdAt.month.toString().padLeft(2, '0')}/${r.createdAt.year}';
    final hasReply = r.adminReply != null && r.adminReply!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: r.isHidden ? Colors.red.shade200 : Colors.grey.shade200,
          width: r.isHidden ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Product info + Rating + Hide status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.productName ?? 'Sản phẩm #${r.productId}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < r.rating ? Icons.star : Icons.star_border,
                                size: 16,
                                color: Colors.amber,
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (r.isHidden)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_off, size: 12, color: Colors.red),
                        SizedBox(width: 4),
                        Text('Đang ẩn', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // User Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  radius: 12,
                  child: Text(
                    r.userName.isNotEmpty ? r.userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  r.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (r.userEmail != null && r.userEmail!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(${r.userEmail})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // Review comment
            Text(
              r.comment,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            ),

            // Attached image if present
            if (r.imageUrl != null && r.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: r.imageUrl!.startsWith('http')
                    ? Image.network(
                        r.imageUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(r.imageUrl!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
              ),
            ] else if (r.hasImage) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Có ảnh thực tế', style: TextStyle(fontSize: 11, color: Colors.black87)),
                  ],
                ),
              ),
            ],

            // Admin response box
            if (hasReply) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Phản hồi từ Cửa hàng',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                        ),
                        const Spacer(),
                        if (r.adminReplyAt != null)
                          Text(
                            '${r.adminReplyAt!.day.toString().padLeft(2, '0')}/${r.adminReplyAt!.month.toString().padLeft(2, '0')}/${r.adminReplyAt!.year}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.adminReply!,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action Buttons Bar
            Row(
              children: [
                // Toggle Hide/Show button
                OutlinedButton.icon(
                  onPressed: () async {
                    final newHidden = !r.isHidden;
                    await DataService.toggleHideReview(r.id, newHidden);
                    setState(() {});
                    if (mounted) {
                      SnackbarHelper.showSuccess(
                        context,
                        newHidden ? 'Đã ẩn đánh giá này khỏi khách hàng' : 'Đã hiện lại đánh giá',
                      );
                    }
                  },
                  icon: Icon(
                    r.isHidden ? Icons.visibility : Icons.visibility_off_outlined,
                    size: 16,
                    color: r.isHidden ? Colors.green : Colors.orange.shade800,
                  ),
                  label: Text(
                    r.isHidden ? 'Hiện lại' : 'Ẩn review',
                    style: TextStyle(
                      fontSize: 12,
                      color: r.isHidden ? Colors.green : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: BorderSide(
                      color: r.isHidden ? Colors.green : Colors.orange.shade300,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),

                // Reply button
                ElevatedButton.icon(
                  onPressed: () => _showReplyDialog(r),
                  icon: Icon(hasReply ? Icons.edit : Icons.reply, size: 16, color: Colors.white),
                  label: Text(
                    hasReply ? 'Sửa phản hồi' : 'Trả lời',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const Spacer(),

                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _confirmDeleteReview(r),
                  tooltip: 'Xóa đánh giá',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
