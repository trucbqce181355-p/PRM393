import 'package:flutter/material.dart';
import '../../services/storage_service.dart';

class UserAddressesScreen extends StatefulWidget {
  final bool isSelecting;
  const UserAddressesScreen({super.key, this.isSelecting = false});

  @override
  State<UserAddressesScreen> createState() => _UserAddressesScreenState();
}

class _UserAddressesScreenState extends State<UserAddressesScreen> {
  late List<Map<String, dynamic>> _addresses;

  @override
  void initState() {
    super.initState();
    _addresses = StorageService.getAddresses();
  }

  void _showAddressSheet({int? index}) {
    final bool isEditing = index != null;
    final Map<String, dynamic> currentAddress = isEditing ? _addresses[index] : {};
    
    final titleController = TextEditingController(text: isEditing ? currentAddress['title'] : '');
    final addressController = TextEditingController(text: isEditing ? currentAddress['address'] : '');
    final phoneController = TextEditingController(text: isEditing ? currentAddress['phone'] : '');
    bool isDefault = isEditing
        ? (currentAddress['isDefault'] ?? false)
        : (_addresses.isEmpty ? true : false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Sửa địa chỉ' : 'Thêm địa chỉ giao hàng mới',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tên địa chỉ (VD: Nhà riêng, Công ty)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết nhận hàng', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Số điện thoại nhận hàng', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isDefault,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setModalState(() => isDefault = val ?? false);
                        },
                      ),
                      const Text('Đặt làm địa chỉ giao hàng mặc định'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty ||
                            addressController.text.trim().isEmpty ||
                            phoneController.text.trim().isEmpty) {
                          return;
                        }
                        final newAddress = {
                          'title': titleController.text.trim(),
                          'address': addressController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'isDefault': isDefault || _addresses.isEmpty,
                        };
                        
                        if (isEditing) {
                          await StorageService.updateAddress(index, newAddress);
                        } else {
                          await StorageService.addAddress(newAddress);
                        }
                        
                        if (mounted) {
                          setState(() {
                            _addresses = StorageService.getAddresses();
                          });
                          Navigator.pop(context); // Đóng modal bottom sheet
                          if (widget.isSelecting) {
                            Navigator.pop(context, newAddress); // Trả về màn hình thanh toán
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isEditing ? 'Cập nhật địa chỉ' : 'Lưu địa chỉ',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa địa chỉ'),
        content: const Text('Bạn có chắc chắn muốn xóa địa chỉ này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await StorageService.deleteAddress(index);
              if (mounted) {
                setState(() {
                  _addresses = StorageService.getAddresses();
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isSelecting ? 'Chọn địa chỉ giao hàng' : 'Địa chỉ giao hàng', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _addresses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_off_outlined, size: 64, color: Colors.green),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Chưa có địa chỉ giao hàng',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isSelecting
                          ? 'Vui lòng thêm địa chỉ nhận hàng để có thể đặt hàng.'
                          : 'Hãy thêm địa chỉ nhận hàng để thuận tiện cho việc mua sắm.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddressSheet(),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Thêm địa chỉ ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.isSelecting) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.touch_app, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chạm vào một địa chỉ để chọn giao hàng',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ..._addresses.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final addr = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildAddressCard(index, addr['title'], addr['address'], addr['phone'], addr['isDefault'] == true),
                  );
                }),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddressSheet(),
                  icon: const Icon(Icons.add, color: Colors.green),
                  label: const Text('Thêm địa chỉ mới', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildAddressCard(int index, String title, String address, String phone, bool isDefault) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.isSelecting
          ? () async {
              await StorageService.setDefaultAddress(index);
              if (mounted) {
                Navigator.pop(context, _addresses[index]);
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDefault ? Border.all(color: Colors.green, width: 2) : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(title.toLowerCase().contains('nhà') ? Icons.home : Icons.work, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Mặc định', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ]
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.blue), 
                      onPressed: () => _showAddressSheet(index: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent), 
                      onPressed: () => _confirmDelete(index),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(address, style: const TextStyle(color: Colors.black87, fontSize: 14)),
            const SizedBox(height: 4),
            Text('SĐT: $phone', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
