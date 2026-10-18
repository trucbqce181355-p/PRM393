import '../../utils/snackbar_helper.dart';
import '../../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../models/review.dart';
import '../../services/data_service.dart';
import 'cart_screen.dart';
import '../auth/login_screen.dart';
import '../../utils/format_helper.dart';

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
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (!AuthService.isAdmin) ...[
            IconButton(
              icon: Cart.items.isEmpty 
                ? const Icon(Icons.shopping_cart_outlined)
                : Badge(
                    label: Text('${Cart.items.length}'),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())).then((_) => setState(() {}));
              },
            ),
            const SizedBox(width: 8),
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
              child: Image.network(
                widget.product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
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
                      final prodReviews = DataService.getReviewsForProduct(widget.product.id, widget.product.name);
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
                                    _showAddReviewModal(context);
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
                              final dateStr = '${r.createdAt.day.toString().padLeft(2, '0')}/${r.createdAt.month.toString().padLeft(2, '0')}/${r.createdAt.year}';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (idx > 0) const Divider(height: 24),
                                  _buildReviewItem(
                                    r.userName,
                                    r.rating,
                                    r.comment,
                                    dateStr,
                                    hasImage: r.hasImage,
                                  ),
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

  void _showAddReviewModal(BuildContext context) {
    int modalRating = 5;
    final reviewController = TextEditingController();
    bool modalHasImage = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final userName = AuthService.userName ?? 'Huế Trân Võ';
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Đánh giá sản phẩm',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đánh giá với tư cách: $userName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        widget.product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < modalRating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 36,
                            ),
                            onPressed: () {
                              setModalState(() {
                                modalRating = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Nhập đánh giá cảm nhận thực tế của bạn về sản phẩm...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () {
                        setModalState(() {
                          modalHasImage = !modalHasImage;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: modalHasImage ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: modalHasImage ? Colors.green : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              modalHasImage ? Icons.check_circle : Icons.camera_alt,
                              color: modalHasImage ? Colors.green : Colors.grey.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              modalHasImage ? 'Đã đính kèm ảnh thực tế' : 'Đính kèm ảnh minh họa',
                              style: TextStyle(
                                color: modalHasImage ? Colors.green : Colors.grey.shade800,
                                fontWeight: modalHasImage ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final text = reviewController.text.trim();
                                if (text.isEmpty) {
                                  SnackbarHelper.showError(context, 'Vui lòng nhập nội dung đánh giá');
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                final newReview = Review(
                                  id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
                                  productId: widget.product.id,
                                  productName: widget.product.name,
                                  userName: userName,
                                  userEmail: AuthService.userEmail,
                                  rating: modalRating,
                                  comment: text,
                                  createdAt: DateTime.now(),
                                  hasImage: modalHasImage,
                                );

                                await DataService.addReview(newReview);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  setState(() {});
                                  SnackbarHelper.showSuccess(
                                    context,
                                    'Cảm ơn $userName đã đánh giá sản phẩm!',
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Gửi đánh giá',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewItem(String name, int rating, String comment, String date, {bool hasImage = false}) {
    final displayName = name.trim().isNotEmpty ? name.trim() : 'Khách hàng';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'K';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              size: 16,
              color: Colors.amber,
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(comment, style: TextStyle(color: Colors.grey[800], height: 1.4)),
        if (hasImage) ...[
          const SizedBox(height: 12),
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
                Text('Ảnh chụp thực tế từ khách hàng', style: TextStyle(color: Colors.black87, fontSize: 12)),
              ],
            ),
          )
        ]
      ],
    );
  }
}
