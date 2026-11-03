import 'package:flutter/material.dart';
import '../../services/storage_service.dart';

class UserPaymentMethodsScreen extends StatefulWidget {
  const UserPaymentMethodsScreen({super.key});

  @override
  State<UserPaymentMethodsScreen> createState() => _UserPaymentMethodsScreenState();
}

class _UserPaymentMethodsScreenState extends State<UserPaymentMethodsScreen> {
  late List<Map<String, dynamic>> _methods;

  @override
  void initState() {
    super.initState();
    _methods = StorageService.getPaymentMethods();
  }

  IconData _getIcon(String iconStr) {
    if (iconStr == 'wallet') return Icons.account_balance_wallet;
    if (iconStr == 'money') return Icons.money;
    return Icons.payment;
  }

  void _addMockPayment() async {
    final newPayment = {
      'title': 'Thẻ tín dụng',
      'subtitle': 'Visa đuôi 4321',
      'icon': 'credit_card',
      'isDefault': false,
    };
    await StorageService.addPaymentMethod(newPayment);
    setState(() {
      _methods = StorageService.getPaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Phương thức thanh toán', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._methods.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPaymentCard(m['title'], m['subtitle'], _getIcon(m['icon']), m['title'].contains('MoMo') ? Colors.pink : Colors.blue, m['isDefault']),
          )),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _addMockPayment,
            icon: const Icon(Icons.add, color: Colors.green),
            label: const Text('Thêm phương thức mới', style: TextStyle(color: Colors.green)),
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

  Widget _buildPaymentCard(String title, String subtitle, IconData icon, Color iconColor, bool isDefault) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDefault ? Border.all(color: Colors.green, width: 2) : null,
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
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Mặc định', style: TextStyle(color: Colors.green, fontSize: 10)),
                      )
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.grey), onPressed: () {}),
        ],
      ),
    );
  }
}
