import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../utils/snackbar_helper.dart';

class UserPaymentMethodsScreen extends StatefulWidget {
  final bool isSelecting;
  const UserPaymentMethodsScreen({super.key, this.isSelecting = false});

  @override
  State<UserPaymentMethodsScreen> createState() => _UserPaymentMethodsScreenState();
}

class _UserPaymentMethodsScreenState extends State<UserPaymentMethodsScreen> {
  late List<Map<String, dynamic>> _methods;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  void _loadMethods() {
    setState(() {
      _methods = StorageService.getPaymentMethods();
    });
  }

  IconData _getIcon(String? iconStr, String title) {
    final lowerTitle = title.toLowerCase();
    if (iconStr == 'wallet' ||
        lowerTitle.contains('momo') ||
        lowerTitle.contains('zalo') ||
        lowerTitle.contains('ví')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (iconStr == 'bank' ||
        lowerTitle.contains('ngân hàng') ||
        lowerTitle.contains('tài khoản')) {
      return Icons.account_balance_rounded;
    }
    if (iconStr == 'money' ||
        lowerTitle.contains('cod') ||
        lowerTitle.contains('tiền mặt')) {
      return Icons.local_atm_rounded;
    }
    return Icons.credit_card_rounded;
  }

  Color _getIconColor(String? iconStr, String title) {
    final lower = title.toLowerCase();
    if (lower.contains('momo')) return Colors.pink.shade600;
    if (lower.contains('zalo')) return Colors.blue.shade600;
    if (lower.contains('vnpay')) return Colors.deepOrange.shade600;
    if (lower.contains('shopee')) return Colors.orange.shade700;
    if (lower.contains('tiền mặt') || lower.contains('cod') || iconStr == 'money') {
      return Colors.teal.shade700;
    }
    if (lower.contains('ngân hàng') || iconStr == 'bank') return Colors.indigo.shade600;
    return Colors.blue.shade700;
  }

  void _setDefault(int index) async {
    await StorageService.setDefaultPaymentMethod(index);
    _loadMethods();
    if (mounted) {
      SnackbarHelper.showSuccess(
        context,
        'Đã đặt "${_methods[index]['title']}" làm mặc định',
      );
    }
  }

  void _confirmDelete(int index) {
    final item = _methods[index];
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa phương thức', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Bạn có chắc chắn muốn xóa phương thức thanh toán "${item['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await StorageService.deletePaymentMethod(index);
              _loadMethods();
              if (!mounted) return;
              SnackbarHelper.showSuccess(context, 'Đã xóa phương thức thanh toán');
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet({int? index}) {
    final bool isEditing = index != null;
    final Map<String, dynamic> current = isEditing ? _methods[index] : {};

    // Xác định loại ban đầu
    String initialType = 'card';
    if (isEditing) {
      if (current['type'] != null) {
        initialType = current['type'];
      } else {
        final lowerTitle = (current['title'] ?? '').toString().toLowerCase();
        final iconStr = current['icon'] ?? '';
        if (iconStr == 'money' || lowerTitle.contains('cod') || lowerTitle.contains('tiền mặt')) {
          initialType = 'cod';
        } else if (iconStr == 'wallet' || lowerTitle.contains('momo') || lowerTitle.contains('ví')) {
          initialType = 'wallet';
        } else if (iconStr == 'bank' || lowerTitle.contains('ngân hàng')) {
          initialType = 'bank';
        } else {
          initialType = 'card';
        }
      }
    }

    String selectedType = initialType;
    String selectedCardBrand = 'Visa';
    String selectedWallet = 'Ví MoMo';
    String selectedBank = 'Vietcombank';

    final cardNumberController = TextEditingController(
      text: isEditing ? (current['accountNumber'] ?? '') : '',
    );
    final cardHolderController = TextEditingController(
      text: isEditing ? (current['cardHolder'] ?? '') : '',
    );
    final expiryController = TextEditingController(
      text: isEditing ? (current['expiry'] ?? '') : '',
    );
    final phoneController = TextEditingController(
      text: isEditing ? (current['phone'] ?? '') : '',
    );
    final noteController = TextEditingController(
      text: isEditing ? (current['subtitle'] ?? '') : '',
    );

    // Tách dữ liệu subtitle nếu thẻ cũ
    if (isEditing && cardNumberController.text.isEmpty && selectedType == 'card') {
      final sub = (current['subtitle'] ?? '').toString();
      final match = RegExp(r'\d+').firstMatch(sub);
      if (match != null) {
        cardNumberController.text = match.group(0)!;
      }
    }

    bool isDefault = isEditing
        ? (current['isDefault'] ?? false)
        : (_methods.isEmpty ? true : false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (innerCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh kéo nhẹ trên modal
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Chỉnh sửa phương thức' : 'Thêm phương thức mới',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(modalCtx),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Lựa chọn loại phương thức
                    const Text('Chọn loại thanh toán:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTypeChip('card', 'Thẻ tín dụng / ghi nợ', Icons.credit_card_rounded, selectedType, (val) {
                          setModalState(() => selectedType = val);
                        }),
                        _buildTypeChip('wallet', 'Ví điện tử', Icons.account_balance_wallet_rounded, selectedType, (val) {
                          setModalState(() => selectedType = val);
                        }),
                        _buildTypeChip('bank', 'Ngân hàng', Icons.account_balance_rounded, selectedType, (val) {
                          setModalState(() => selectedType = val);
                        }),
                        _buildTypeChip('cod', 'Tiền mặt (COD)', Icons.local_atm_rounded, selectedType, (val) {
                          setModalState(() => selectedType = val);
                        }),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Form động theo từng loại
                    if (selectedType == 'card') ...[
                      const Text('Loại thẻ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: ['Visa', 'Mastercard', 'JCB', 'Napas'].map((brand) {
                          final isSel = selectedCardBrand == brand;
                          return ChoiceChip(
                            label: Text(brand),
                            selected: isSel,
                            selectedColor: Colors.blue.shade100,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.blue.shade800 : Colors.black87,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => selectedCardBrand = brand);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cardNumberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Số thẻ hoặc 4 số cuối',
                          hintText: 'VD: 4321 hoặc 4123 4567 8901 4321',
                          prefixIcon: const Icon(Icons.credit_card),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cardHolderController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Tên chủ thẻ (IN HOA KHÔNG DẤU)',
                          hintText: 'VD: NGUYEN VAN A',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: expiryController,
                        keyboardType: TextInputType.datetime,
                        decoration: InputDecoration(
                          labelText: 'Ngày hết hạn (MM/YY)',
                          hintText: 'VD: 12/28',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ] else if (selectedType == 'wallet') ...[
                      const Text('Chọn ví điện tử:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: ['Ví MoMo', 'ZaloPay', 'VNPay', 'ShopeePay'].map((wallet) {
                          final isSel = selectedWallet == wallet;
                          return ChoiceChip(
                            label: Text(wallet),
                            selected: isSel,
                            selectedColor: wallet.contains('MoMo')
                                ? Colors.pink.shade100
                                : Colors.blue.shade100,
                            labelStyle: TextStyle(
                              color: isSel
                                  ? (wallet.contains('MoMo') ? Colors.pink.shade800 : Colors.blue.shade800)
                                  : Colors.black87,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => selectedWallet = wallet);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại liên kết ví',
                          hintText: 'VD: 0901234567',
                          prefixIcon: const Icon(Icons.phone_android_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ] else if (selectedType == 'bank') ...[
                      const Text('Chọn ngân hàng:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: ['Vietcombank', 'MB Bank', 'Techcombank', 'ACB', 'BIDV', 'VPBank'].map((b) {
                          final isSel = selectedBank == b;
                          return ChoiceChip(
                            label: Text(b),
                            selected: isSel,
                            selectedColor: Colors.indigo.shade100,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.indigo.shade800 : Colors.black87,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => selectedBank = b);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cardNumberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Số tài khoản ngân hàng',
                          hintText: 'VD: 1029384756',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cardHolderController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Tên người thụ hưởng (IN HOA)',
                          hintText: 'VD: NGUYEN VAN A',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.teal.shade700, size: 22),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Thanh toán trực tiếp bằng tiền mặt cho shipper khi nhận hàng.',
                                style: TextStyle(fontSize: 13, color: Colors.teal),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        decoration: InputDecoration(
                          labelText: 'Ghi chú thêm',
                          hintText: 'VD: Thanh toán khi nhận hàng, chuẩn bị tiền lẻ...',
                          prefixIcon: const Icon(Icons.notes_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: isDefault,
                          activeColor: Colors.green,
                          onChanged: (val) {
                            setModalState(() => isDefault = val ?? false);
                          },
                        ),
                        const Text('Đặt làm phương thức thanh toán mặc định'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          String title;
                          String subtitle;
                          String iconStr;

                          if (selectedType == 'card') {
                            final rawNumber = cardNumberController.text.trim();
                            final last4 = rawNumber.length >= 4
                                ? rawNumber.substring(rawNumber.length - 4)
                                : (rawNumber.isNotEmpty ? rawNumber : '4321');
                            title = 'Thẻ tín dụng';
                            subtitle = '$selectedCardBrand đuôi $last4';
                            if (cardHolderController.text.trim().isNotEmpty) {
                              subtitle += ' • ${cardHolderController.text.trim()}';
                            }
                            iconStr = 'credit_card';
                          } else if (selectedType == 'wallet') {
                            final phone = phoneController.text.trim();
                            final maskedPhone = phone.length > 4
                                ? '${phone.substring(0, phone.length - 3)}***'
                                : (phone.isNotEmpty ? phone : 'Liên kết ví');
                            title = selectedWallet;
                            subtitle = 'Thanh toán qua $selectedWallet ($maskedPhone)';
                            iconStr = 'wallet';
                          } else if (selectedType == 'bank') {
                            final acc = cardNumberController.text.trim();
                            final holder = cardHolderController.text.trim();
                            title = 'Ngân hàng $selectedBank';
                            subtitle = acc.isNotEmpty
                                ? '$selectedBank - $acc ${holder.isNotEmpty ? "($holder)" : ""}'
                                : 'Chuyển khoản qua $selectedBank';
                            iconStr = 'bank';
                          } else {
                            title = 'Thanh toán tiền mặt (COD)';
                            subtitle = noteController.text.trim().isNotEmpty
                                ? noteController.text.trim()
                                : 'Thanh toán khi nhận hàng';
                            iconStr = 'money';
                          }

                          final newMethod = {
                            'type': selectedType,
                            'title': title,
                            'subtitle': subtitle,
                            'icon': iconStr,
                            'accountNumber': cardNumberController.text.trim(),
                            'cardHolder': cardHolderController.text.trim(),
                            'expiry': expiryController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'isDefault': isDefault || _methods.isEmpty,
                          };

                          if (isEditing) {
                            await StorageService.updatePaymentMethod(index, newMethod);
                          } else {
                            await StorageService.addPaymentMethod(newMethod);
                          }

                          _loadMethods();
                          if (modalCtx.mounted) {
                            Navigator.pop(modalCtx);
                          }
                          if (!mounted) return;
                          SnackbarHelper.showSuccess(
                            context,
                            isEditing
                                ? 'Đã cập nhật phương thức thanh toán'
                                : 'Đã thêm phương thức thanh toán mới',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          isEditing ? 'Cập nhật phương thức' : 'Lưu phương thức',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildTypeChip(
    String typeKey,
    String label,
    IconData icon,
    String currentType,
    Function(String) onSelect,
  ) {
    final isSelected = currentType == typeKey;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onSelect(typeKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.green.shade800 : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Phương thức thanh toán',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _methods.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._methods.asMap().entries.map((entry) {
                  final index = entry.key;
                  final m = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildPaymentCard(
                      index: index,
                      title: m['title'] ?? '',
                      subtitle: m['subtitle'] ?? '',
                      icon: _getIcon(m['icon'], m['title'] ?? ''),
                      iconColor: _getIconColor(m['icon'], m['title'] ?? ''),
                      isDefault: m['isDefault'] == true,
                    ),
                  );
                }),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showPaymentSheet(),
                  icon: const Icon(Icons.add, color: Colors.green),
                  label: const Text(
                    'Thêm phương thức mới',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.credit_card_off_rounded,
                size: 56,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có phương thức thanh toán nào',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              'Thêm phương thức để thanh toán đơn hàng nhanh chóng hơn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showPaymentSheet(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thêm phương thức mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDefault,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (widget.isSelecting) {
          Navigator.pop(context, _methods[index]);
        } else if (!isDefault) {
          _setDefault(index);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDefault
              ? Border.all(color: Colors.green, width: 2)
              : Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Mặc định',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tooltip: 'Tùy chọn',
              onSelected: (value) {
                if (value == 'default') {
                  _setDefault(index);
                } else if (value == 'edit') {
                  _showPaymentSheet(index: index);
                } else if (value == 'delete') {
                  _confirmDelete(index);
                }
              },
              itemBuilder: (context) => [
                if (!isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                        SizedBox(width: 10),
                        Text('Đặt làm mặc định'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                      SizedBox(width: 10),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      SizedBox(width: 10),
                      Text('Xóa', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
