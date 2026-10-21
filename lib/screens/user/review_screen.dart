import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../models/review.dart';
import '../../utils/snackbar_helper.dart';

class ReviewScreen extends StatefulWidget {
  final String orderId;
  final String? productId;
  final String? productName;

  const ReviewScreen({
    super.key,
    required this.orderId,
    this.productId,
    this.productName,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _hasImage = false;
  bool _isSubmitting = false;

  String? _selectedProductId;
  String? _selectedProductName;

  @override
  void initState() {
    super.initState();
    _initSelectedProduct();
  }

  void _initSelectedProduct() {
    String resolvedId = widget.productId ?? '';
    String resolvedName = widget.productName ?? '';

    if (resolvedId.isEmpty && resolvedName.isNotEmpty) {
      for (var p in DataService.products) {
        if (resolvedName.toLowerCase().contains(p.name.toLowerCase()) ||
            p.name.toLowerCase().contains(resolvedName.toLowerCase())) {
          resolvedId = p.id;
          resolvedName = p.name;
          break;
        }
      }
    }

    if (resolvedId.isEmpty) {
      final taoProduct = DataService.products.firstWhere(
        (p) => p.name.contains('Táo'),
        orElse: () => DataService.products.isNotEmpty ? DataService.products.first : DataService.defaultProducts.first,
      );
      resolvedId = taoProduct.id;
      resolvedName = taoProduct.name;
    }

    _selectedProductId = resolvedId;
    _selectedProductName = resolvedName;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      SnackbarHelper.showError(context, 'Vui lòng chọn số sao đánh giá');
      return;
    }

    final comment = _reviewController.text.trim();
    if (comment.isEmpty) {
      SnackbarHelper.showError(context, 'Vui lòng nhập nội dung đánh giá');
      return;
    }

    setState(() => _isSubmitting = true);

    final resolvedProductId = _selectedProductId ??
        (DataService.products.isNotEmpty ? DataService.products.first.id : 'p_tao_envy');
    final resolvedProductName = _selectedProductName ??
        (DataService.products.isNotEmpty ? DataService.products.first.name : 'Táo Envy New Zealand');

    final currentUserName = AuthService.userName ?? 'Huế Trân Võ';

    final newReview = Review(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      productId: resolvedProductId,
      productName: resolvedProductName,
      userName: currentUserName,
      userEmail: AuthService.userEmail,
      rating: _rating,
      comment: comment,
      createdAt: DateTime.now(),
      hasImage: _hasImage,
      orderId: widget.orderId,
    );

    // Lưu trực tiếp vào MongoDB traicay_db và đồng bộ DataService
    await DataService.addReview(newReview);

    if (!mounted) return;

    setState(() => _isSubmitting = false);
    SnackbarHelper.showSuccess(context, 'Cảm ơn $currentUserName đã gửi đánh giá!');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = AuthService.userName ?? 'Huế Trân Võ';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đánh giá sản phẩm', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Người đánh giá: $displayName',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sản phẩm đánh giá',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedProductId,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                  items: DataService.products.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final sel = DataService.products.firstWhere((p) => p.id == val);
                      setState(() {
                        _selectedProductId = sel.id;
                        _selectedProductName = sel.name;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn cảm thấy chất lượng sản phẩm như thế nào?',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 42,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Hãy chia sẻ cảm nhận thực tế của bạn về độ tươi, vị ngọt và đóng gói...',
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
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Hình ảnh thực tế', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _hasImage = !_hasImage;
                  });
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasImage ? Colors.green : Colors.grey.shade300,
                      width: _hasImage ? 2 : 1,
                    ),
                  ),
                  child: _hasImage
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 36, color: Colors.green),
                            SizedBox(height: 4),
                            Text('Đã đính kèm ảnh', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Thêm ảnh', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Gửi đánh giá',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
