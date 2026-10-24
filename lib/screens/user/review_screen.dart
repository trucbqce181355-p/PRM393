import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../models/review.dart';
import '../../utils/snackbar_helper.dart';

class ReviewScreen extends StatefulWidget {
  final String orderId;
  final String? productId;
  final String? productName;
  final Review? existingReview;

  const ReviewScreen({
    super.key,
    required this.orderId,
    this.productId,
    this.productName,
    this.existingReview,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5;
  final TextEditingController _reviewController = TextEditingController();
  File? _imageFile;
  String? _existingImageUrl;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  String? _selectedProductId;
  String? _selectedProductName;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _reviewController.text = widget.existingReview!.comment;
      _selectedProductId = widget.existingReview!.productId;
      _selectedProductName = widget.existingReview!.productName;
      _existingImageUrl = widget.existingReview!.imageUrl;
      if (_existingImageUrl != null && File(_existingImageUrl!).existsSync()) {
        _imageFile = File(_existingImageUrl!);
      }
    } else {
      _initSelectedProduct();
    }
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _existingImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Không thể chọn ảnh: $e');
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Chụp ảnh từ máy ảnh'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
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

    final currentUserName = AuthService.userName ?? 'Khách hàng';
    final imagePath = _imageFile?.path ?? _existingImageUrl;

    try {
      if (widget.existingReview != null) {
        await DataService.updateReview(
          widget.existingReview!.id,
          rating: _rating,
          comment: comment,
          imageUrl: imagePath,
          hasImage: imagePath != null && imagePath.isNotEmpty,
        );
        if (!mounted) return;
        SnackbarHelper.showSuccess(context, 'Đã cập nhật đánh giá thành công!');
      } else {
        final newReview = Review(
          id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
          productId: resolvedProductId,
          productName: resolvedProductName,
          userName: currentUserName,
          userEmail: AuthService.userEmail,
          rating: _rating,
          comment: comment,
          createdAt: DateTime.now(),
          hasImage: imagePath != null && imagePath.isNotEmpty,
          imageUrl: imagePath,
          orderId: widget.orderId,
        );

        await DataService.addReview(newReview);
        if (!mounted) return;
        SnackbarHelper.showSuccess(context, 'Cảm ơn $currentUserName đã gửi đánh giá!');
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Đã xảy ra lỗi: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = AuthService.userName ?? 'Khách hàng';
    final isEditing = widget.existingReview != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Chỉnh sửa đánh giá' : 'Đánh giá sản phẩm',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
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
                  onChanged: isEditing
                      ? null
                      : (val) {
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
              child: Text(
                'Hình ảnh thực tế đính kèm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: _imageFile != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _imageFile!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _imageFile = null;
                                _existingImageUrl = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _existingImageUrl!.startsWith('http')
                                  ? Image.network(
                                      _existingImageUrl!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_existingImageUrl!),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      ),
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _existingImageUrl = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                      : InkWell(
                          onTap: _showImagePickerOptions,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.green),
                                SizedBox(height: 6),
                                Text(
                                  'Tải ảnh lên',
                                  style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Camera / Thư viện',
                                  style: TextStyle(color: Colors.grey, fontSize: 10),
                                ),
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
                    : Text(
                        isEditing ? 'Lưu chỉnh sửa' : 'Gửi đánh giá',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
