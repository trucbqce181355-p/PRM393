import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/voucher.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/format_helper.dart';

class AdminVouchersScreen extends StatefulWidget {
  const AdminVouchersScreen({super.key});

  @override
  State<AdminVouchersScreen> createState() => _AdminVouchersScreenState();
}

class _AdminVouchersScreenState extends State<AdminVouchersScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: Tất cả, 1: Đang hoạt động, 2: Tạm ngưng

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Voucher> get _filteredVouchers {
    final query = _searchController.text.trim().toLowerCase();
    return DataService.vouchers.where((v) {
      final matchesQuery = query.isEmpty ||
          v.code.toLowerCase().contains(query) ||
          v.description.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (_selectedFilter == 1) return v.isActive;
      if (_selectedFilter == 2) return !v.isActive;
      return true;
    }).toList();
  }

  void _openVoucherDialog({Voucher? voucher}) {
    final isEditing = voucher != null;
    final codeController = TextEditingController(text: voucher?.code ?? '');
    final descController = TextEditingController(text: voucher?.description ?? '');
    final discountController = TextEditingController(
      text: voucher != null ? voucher.discountAmount.toStringAsFixed(0) : '',
    );
    final minPurchaseController = TextEditingController(
      text: voucher != null ? voucher.minPurchase.toStringAsFixed(0) : '0',
    );
    bool isActive = voucher?.isActive ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentDiscount = double.tryParse(discountController.text) ?? 0.0;
            final currentMinPurchase = double.tryParse(minPurchaseController.text) ?? 0.0;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isEditing ? Colors.orange.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_note : Icons.add_card,
                      color: isEditing ? Colors.orange.shade700 : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Cập nhật Voucher' : 'Thêm Voucher mới',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mã Voucher
                      TextField(
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Mã voucher *',
                          hintText: 'VD: WELCOME10, GIAM20K',
                          prefixIcon: const Icon(Icons.confirmation_number_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Mô tả
                      TextField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả voucher',
                          hintText: 'VD: Giảm 20.000₫ cho đơn hàng trái cây',
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Số tiền giảm
                      TextField(
                        controller: discountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Số tiền giảm (₫) *',
                          hintText: 'VD: 20000',
                          prefixIcon: const Icon(Icons.discount_outlined),
                          helperText: currentDiscount > 0
                              ? 'Mức giảm: ${FormatHelper.formatPrice(currentDiscount)}'
                              : null,
                          helperStyle: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Đơn tối thiểu
                      TextField(
                        controller: minPurchaseController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Đơn hàng tối thiểu (₫)',
                          hintText: 'VD: 100000 (0 nếu không yêu cầu)',
                          prefixIcon: const Icon(Icons.shopping_bag_outlined),
                          helperText: currentMinPurchase > 0
                              ? 'Áp dụng cho đơn từ: ${FormatHelper.formatPrice(currentMinPurchase)}'
                              : 'Không giới hạn đơn tối thiểu',
                          helperStyle: TextStyle(color: Colors.blue.shade700),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Trạng thái kích hoạt
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.pause_circle_outline,
                                  color: isActive ? Colors.green : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isActive ? 'Kích hoạt voucher ngay' : 'Tạm ngưng voucher',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: isActive,
                              activeColor: Colors.green,
                              onChanged: (val) {
                                setDialogState(() {
                                  isActive = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEditing ? Colors.orange.shade700 : Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final code = codeController.text.trim().toUpperCase();
                    final desc = descController.text.trim();
                    final discount = double.tryParse(discountController.text) ?? 0.0;
                    final minPurchase = double.tryParse(minPurchaseController.text) ?? 0.0;

                    if (code.isEmpty) {
                      SnackbarHelper.showError(context, 'Vui lòng nhập mã voucher');
                      return;
                    }

                    // Check duplicate code if adding or changing code
                    final isDuplicate = DataService.vouchers.any((v) =>
                        v.code.toUpperCase() == code &&
                        (!isEditing || v.code.toUpperCase() != voucher.code.toUpperCase()));

                    if (isDuplicate) {
                      SnackbarHelper.showError(context, 'Mã voucher "$code" đã tồn tại!');
                      return;
                    }

                    if (discount <= 0) {
                      SnackbarHelper.showError(context, 'Số tiền giảm phải lớn hơn 0');
                      return;
                    }

                    final newVoucher = Voucher(
                      code: code,
                      description: desc.isNotEmpty ? desc : 'Giảm ${FormatHelper.formatPrice(discount)}',
                      discountAmount: discount,
                      minPurchase: minPurchase,
                      isActive: isActive,
                    );

                    Navigator.pop(dialogContext);

                    if (isEditing) {
                      await DataService.updateVoucher(voucher.code, newVoucher);
                      if (mounted) {
                        setState(() {});
                        SnackbarHelper.showSuccess(context, 'Đã cập nhật voucher "$code"');
                      }
                    } else {
                      await DataService.addVoucher(newVoucher);
                      if (mounted) {
                        setState(() {});
                        SnackbarHelper.showSuccess(context, 'Đã thêm voucher "$code" thành công');
                      }
                    }
                  },
                  child: Text(isEditing ? 'Lưu thay đổi' : 'Thêm Voucher'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteVoucher(Voucher voucher) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Xóa Voucher'),
            ],
          ),
          content: Text.rich(
            TextSpan(
              text: 'Bạn có chắc chắn muốn xóa voucher ',
              children: [
                TextSpan(
                  text: voucher.code,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const TextSpan(
                  text: '?\n\nHành động này không thể hoàn tác.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await DataService.deleteVoucher(voucher.code);
                if (mounted) {
                  setState(() {});
                  SnackbarHelper.showSuccess(context, 'Đã xóa voucher ${voucher.code}');
                }
              },
              child: const Text('Xác nhận xóa'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vouchers = _filteredVouchers;
    final totalCount = DataService.vouchers.length;
    final activeCount = DataService.vouchers.where((v) => v.isActive).length;
    final inactiveCount = totalCount - activeCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text(
          'Quản lý Voucher',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: () => _openVoucherDialog(),
              child: const Text(
                'Thêm voucher',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Statistics Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _buildStatCard('Tổng số', '$totalCount', Colors.blue.shade700, Icons.local_offer),
                const SizedBox(width: 8),
                _buildStatCard('Đang chạy', '$activeCount', Colors.green.shade700, Icons.check_circle_outline),
                const SizedBox(width: 8),
                _buildStatCard('Tạm ngưng', '$inactiveCount', Colors.orange.shade700, Icons.pause_circle_outline),
              ],
            ),
          ),

          // Search Bar & Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm mã voucher, mô tả...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
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
                  children: [
                    _buildFilterChip(0, 'Tất cả ($totalCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, 'Đang chạy ($activeCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'Tạm ngưng ($inactiveCount)'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Voucher List / Empty State
          Expanded(
            child: vouchers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: vouchers.length,
                    itemBuilder: (context, index) {
                      final voucher = vouchers[index];
                      return _buildVoucherCard(voucher);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int filterIndex, String label) {
    final isSelected = _selectedFilter == filterIndex;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedFilter = filterIndex;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade600 : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: voucher.isActive ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openVoucherDialog(voucher: voucher),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Ticket Icon Box
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: voucher.isActive ? Colors.orange.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: voucher.isActive ? Colors.orange.shade200 : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_offer_rounded,
                        color: voucher.isActive ? Colors.orange.shade700 : Colors.grey,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Voucher Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              voucher.code,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: voucher.isActive ? Colors.blue.shade700 : Colors.grey.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: voucher.code));
                                SnackbarHelper.showSuccess(context, 'Đã sao chép mã: ${voucher.code}');
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                              ),
                            ),
                            const Spacer(),
                            // Active / Inactive Switch
                            Transform.scale(
                              scale: 0.85,
                              child: Switch(
                                value: voucher.isActive,
                                activeColor: Colors.green,
                                onChanged: (val) async {
                                  await DataService.toggleVoucherStatus(voucher.code, val);
                                  if (mounted) {
                                    setState(() {});
                                    SnackbarHelper.showSuccess(
                                      context,
                                      val
                                          ? 'Đã kích hoạt voucher ${voucher.code}'
                                          : 'Đã tạm ngưng voucher ${voucher.code}',
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Giảm: ${FormatHelper.formatPrice(voucher.discountAmount)}',
                          style: TextStyle(
                            color: voucher.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          voucher.description,
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đơn tối thiểu: ${FormatHelper.formatPrice(voucher.minPurchase)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.8),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: voucher.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: voucher.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          voucher.isActive ? 'Đang hoạt động' : 'Tạm dừng áp dụng',
                          style: TextStyle(
                            color: voucher.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Sửa', style: TextStyle(fontSize: 13)),
                        onPressed: () => _openVoucherDialog(voucher: voucher),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Xóa', style: TextStyle(fontSize: 13)),
                        onPressed: () => _confirmDeleteVoucher(voucher),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty || _selectedFilter != 0;
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
                isSearching ? Icons.search_off_rounded : Icons.local_offer_outlined,
                size: 56,
                color: Colors.green.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'Không tìm thấy voucher phù hợp' : 'Chưa có voucher nào',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Hãy thử tìm kiếm với từ khóa khác hoặc xóa bộ lọc.'
                  : 'Bấm nút bên dưới để tạo mã giảm giá khuyến mãi đầu tiên.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (isSearching)
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Đặt lại bộ lọc'),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedFilter = 0;
                  });
                },
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Voucher mới', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _openVoucherDialog(),
              ),
          ],
        ),
      ),
    );
  }
}
