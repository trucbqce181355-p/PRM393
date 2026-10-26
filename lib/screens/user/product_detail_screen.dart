import 'dart:io';
import '../../utils/snackbar_helper.dart';
import '../../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../models/review.dart';
import '../../services/data_service.dart';
import 'cart_screen.dart';
import 'review_screen.dart';
import '../auth/login_screen.dart';
import '../../utils/format_helper.dart';
import '../../utils/app_image_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _refreshReviews();
  }

  Future<void> _refreshReviews() async {
    await DataService.refreshReviews();
    if (mounted) {
      setState(() {});
    }
  }

  void _addToCart() {
    setState(() {
      Cart.addItem(widget.product, _quantity);
    });
    SnackbarHelper.showSuccess(context, 'Đã thêm $_quantity ${widget.product.unit} ${widget.product.name} vào giỏ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
              tooltip: 'Quay lại',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          if (!AuthService.isAdmin) ...[
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Cart.items.isEmpty 
                    ? const Icon(Icons.shopping_cart_outlined, color: Colors.black87, size: 20)
                    : Badge(
                        label: Text('${Cart.items.length}'),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.shopping_cart_outlined, color: Colors.black87, size: 20),
                      ),
                  tooltip: 'Giỏ hàng',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())).then((_) => setState(() {}));
                  },
                ),
              ),
            ),
          ],
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: AppImageHelper.buildImage(
                imageUrl: widget.product.imageUrl,
                fit: BoxFit.cover,
                errorWidget: const Center(
                  child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                ),
              ),
            ),
            
            // Product Details
            Container(
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final prodReviews = DataService.getReviewsForProduct(widget.product.id, widget.product.name);
                          final double avgRating = prodReviews.isNotEmpty
                              ? (prodReviews.map((r) => r.rating).reduce((a, b) => a + b) / prodReviews.length)
                              : widget.product.rating;
                          return Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 22),
                              const SizedBox(width: 4),
                              Text(
                                '${avgRating.toStringAsFixed(1)} (${prodReviews.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Category tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      widget.product.category,
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Price card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade50, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GIÁ BÁN NIÊM YẾT',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  FormatHelper.formatPrice(widget.product.price),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ' / ${widget.product.unit}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt, color: Colors.red, size: 16),
                              SizedBox(width: 2),
                              Text(
                                'GIÁ THEO KG TỐT NHẤT',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Highlight Attributes: Nguồn gốc & Độ tươi
                  Row(
                    children: [
                      // Nguồn gốc
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.public, color: Colors.blue.shade700, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'NGUỒN GỐC',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.product.origin,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Độ tươi
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.eco_rounded, color: Colors.orange.shade700, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ĐỘ TƯƠI',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.product.freshness,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Cam kết chất lượng
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_outlined, color: Colors.green, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cam kết 100% tươi sạch, đổi trả miễn phí trong 24h nếu dập nát hoặc không đạt chuẩn.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Đánh giá từ khách hàng thực tế (Loại bỏ toàn bộ dữ liệu ảo)
                  Builder(
                    builder: (context) {
                      final rawReviews = DataService.getReviewsForProduct(widget.product.id, widget.product.name);
                      final prodReviews = rawReviews.where((r) {
                        if (!r.isHidden) return true;
                        if (AuthService.isAdmin) return true;
                        if (AuthService.userEmail != null &&
                            (r.userEmail ?? '').toLowerCase() == AuthService.userEmail!.toLowerCase()) {
                          return true;
                        }
                        return false;
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Đánh giá từ khách hàng',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${prodReviews.length}',
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              if (!AuthService.isAdmin)
                                TextButton.icon(
                                  onPressed: () {
                                    if (!AuthService.isLoggedIn) {
                                      SnackbarHelper.showError(context, 'Vui lòng đăng nhập để viết đánh giá!');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                                      ).then((_) {
                                        if (mounted) setState(() {});
                                      });
                                      return;
                                    }

                                    final email = AuthService.userEmail ?? '';
                                    final hasPurchased = DataService.hasPurchasedProduct(
                                      email,
                                      widget.product.id,
                                      widget.product.name,
                                    );

                                    if (!hasPurchased) {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: const Row(
                                            children: [
                                              Icon(Icons.verified_user_outlined, color: Colors.orange),
                                              SizedBox(width: 8),
                                              Text('Chưa thể đánh giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          content: const Text(
                                            'Chính sách đánh giá minh bạch:\nBạn chỉ có thể đánh giá và nhận xét sau khi đã mua sản phẩm này trên hệ thống.',
                                            style: TextStyle(height: 1.4),
                                          ),
                                          actions: [
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: const Text('Đã hiểu', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReviewScreen(
                                          orderId: 'ORDER_PURCHASED',
                                          productId: widget.product.id,
                                          productName: widget.product.name,
                                        ),
                                      ),
                                    ).then((val) {
                                      if (val == true) _refreshReviews();
                                    });
                                  },
                                  icon: const Icon(Icons.rate_review_outlined, color: Colors.green, size: 18),
                                  label: const Text('Viết đánh giá', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          if (prodReviews.isEmpty) ...[
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Chưa có đánh giá nào cho sản phẩm này.',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hãy là người đầu tiên chia sẻ cảm nhận của bạn!',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            ...prodReviews.asMap().entries.map((entry) {
                              final int idx = entry.key;
                              final r = entry.value;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (idx > 0) const Divider(height: 24),
                                  _buildReviewItem(r),
                                ],
                              );
                            }),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40), // extra padding for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AuthService.isAdmin ? null : Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() {
                            _quantity--;
                          });
                        }
                      },
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _quantity++;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Add to Cart Button
              Expanded(
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Thêm vào giỏ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(Review r) {
    final displayName = r.userName.trim().isNotEmpty ? r.userName.trim() : 'Khách hàng';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'K';
    final dateStr = '${r.createdAt.day.toString().padLeft(2, '0')}/${r.createdAt.month.toString().padLeft(2, '0')}/${r.createdAt.year}';
    final isMyReview = AuthService.userEmail != null &&
        AuthService.userEmail!.isNotEmpty &&
        (r.userEmail ?? '').toLowerCase() == AuthService.userEmail!.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    radius: 16,
                    child: Text(
                      initial,
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 12, color: Colors.green),
                        SizedBox(width: 2),
                        Text('Đã mua', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (isMyReview) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    onSelected: (action) async {
                      if (action == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewScreen(
                              orderId: r.orderId ?? '',
                              productId: widget.product.id,
                              productName: widget.product.name,
                              existingReview: r,
                            ),
                          ),
                        ).then((val) {
                          if (val == true) _refreshReviews();
                        });
                      } else if (action == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Xóa đánh giá'),
                            content: const Text('Bạn có chắc chắn muốn xóa bài đánh giá này?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Xóa', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await DataService.deleteReview(r.id);
                          await _refreshReviews();
                          if (mounted) {
                            SnackbarHelper.showSuccess(context, 'Đã xóa đánh giá thành công');
                          }
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Sửa đánh giá'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa đánh giá', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < r.rating ? Icons.star : Icons.star_border,
              size: 16,
              color: Colors.amber,
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(r.comment, style: TextStyle(color: Colors.grey[800], height: 1.4)),
        if (r.imageUrl != null && r.imageUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: r.imageUrl!.startsWith('http')
                ? Image.network(
                    r.imageUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(r.imageUrl!),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
          ),
        ] else if (r.hasImage) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Text('Ảnh thực tế từ khách hàng', style: TextStyle(color: Colors.black87, fontSize: 12)),
              ],
            ),
          ),
        ],
        if (r.adminReply != null && r.adminReply!.isNotEmpty) ...[
          const SizedBox(height: 10),
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
                      'Phản hồi từ Người bán',
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
      ],
    );
  }
}
