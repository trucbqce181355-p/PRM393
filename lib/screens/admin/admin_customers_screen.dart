import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/format_helper.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: Tất cả, 1: Hoạt động, 2: Tạm khóa

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();
    return DataService.customers.where((c) {
      final matchesQuery = query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (_selectedFilter == 1) return c.isActive;
      if (_selectedFilter == 2) return !c.isActive;
      return true;
    }).toList();
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
    final customers = _filteredCustomers;
    final totalCount = DataService.customers.length;
    final activeCount = DataService.customers.where((c) => c.isActive).length;
    final inactiveCount = totalCount - activeCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text(
          'Quản lý Khách hàng',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Top Statistics Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _buildStatCard('Tổng số', '$totalCount', Colors.blue.shade700, Icons.people_alt_rounded),
                const SizedBox(width: 8),
                _buildStatCard('Hoạt động', '$activeCount', Colors.green.shade700, Icons.check_circle_outline),
                const SizedBox(width: 8),
                _buildStatCard('Tạm khóa', '$inactiveCount', Colors.orange.shade700, Icons.pause_circle_outline),
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
                    hintText: 'Tìm kiếm khách hàng (Tên, SĐT, Email)...',
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
                    _buildFilterChip(1, 'Hoạt động ($activeCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'Tạm khóa ($inactiveCount)'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Customers List
          Expanded(
            child: customers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _buildCustomerCard(customer);
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

  Widget _buildCustomerCard(Customer customer) {
    Color tierColor;
    Color tierBgColor;
    switch (customer.memberTier) {
      case 'Bạch Kim':
        tierColor = Colors.blue.shade700;
        tierBgColor = Colors.blue.shade50;
        break;
      case 'Vàng':
        tierColor = Colors.amber.shade800;
        tierBgColor = Colors.amber.shade50;
        break;
      case 'Bạc':
        tierColor = Colors.grey.shade700;
        tierBgColor = Colors.grey.shade100;
        break;
      default:
        tierColor = Colors.brown.shade700;
        tierBgColor = Colors.brown.shade50;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: customer.isActive ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: tierBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tierColor.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: tierColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Customer Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    customer.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: customer.isActive ? Colors.black87 : Colors.grey.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tierBgColor,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: tierColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    customer.memberTier,
                                    style: TextStyle(color: tierColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Switch Active / Inactive
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: customer.isActive,
                              activeColor: Colors.green,
                              onChanged: (val) async {
                                await DataService.updateCustomerStatus(customer.id, val);
                                if (mounted) {
                                  setState(() {});
                                  SnackbarHelper.showSuccess(
                                    context,
                                    val
                                        ? 'Đã mở khóa khách hàng "${customer.name}"'
                                        : 'Đã tạm khóa khách hàng "${customer.name}"',
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${customer.phone} • ${customer.email}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đã chi tiêu: ${FormatHelper.formatPrice(customer.totalSpent)} (${customer.totalOrders} đơn hàng)',
                        style: TextStyle(
                          color: customer.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.8),

            // Bottom status indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: customer.isActive ? Colors.green.shade50 : Colors.grey.shade100,
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
                          color: customer.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        customer.isActive ? 'Đang hoạt động' : 'Tài khoản bị khóa',
                        style: TextStyle(
                          color: customer.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Mã KH: #${customer.id.substring(customer.id.length > 6 ? customer.id.length - 6 : 0)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ],
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
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.people_outline_rounded,
                size: 56,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'Không tìm thấy khách hàng phù hợp' : 'Chưa có khách hàng nào',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Hãy thử tìm kiếm với tên, SĐT hoặc email khác.'
                  : 'Danh sách khách hàng đăng ký sẽ xuất hiện tại đây.',
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
              ),
          ],
        ),
      ),
    );
  }
}
