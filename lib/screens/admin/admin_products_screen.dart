import 'package:flutter/material.dart';
import 'dart:io';
import '../../services/data_service.dart';
import 'admin_add_product_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Dark theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF252538),
        title: const Text(
          'Quản lý sản phẩm',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminAddProductScreen()),
              );
              if (result == true) {
                setState(() {});
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF252538),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Builder(
            builder: (context) {
              final visibleProducts = DataService.products.where((p) => p.isDeleted != true).toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleProducts.length,
                itemBuilder: (context, index) {
                  final product = visibleProducts[index];
                  final stockStatus = (product.isActive == true) ? 'Đang bán' : 'Ngưng bán';
                  final stockColor = (product.isActive == true) ? Colors.green : Colors.red;
                  return _buildProductListItem(
                    context,
                    product,
                    stockStatus,
                    stockColor,
                  );
                },
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildProductListItem(BuildContext context, dynamic product, String status, Color statusColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          image: (product.imageUrl != null && product.imageUrl.toString().isNotEmpty)
              ? DecorationImage(
                  image: product.imageUrl.startsWith('http')
                      ? NetworkImage(product.imageUrl) as ImageProvider
                      : FileImage(File(product.imageUrl)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: (product.imageUrl == null || product.imageUrl.toString().isEmpty)
            ? const Icon(Icons.image, color: Colors.grey)
            : null,
      ),
      title: Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text('${product.unit} • SL: ${product.stock}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Text('\$ ${product.price}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminAddProductScreen(product: product)),
              );
              if (result == true) {
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: Icon(
              product.isActive == true ? Icons.visibility : Icons.visibility_off,
              color: product.isActive == true ? Colors.green : Colors.grey,
              size: 20,
            ),
            onPressed: () async {
              product.isActive = !(product.isActive == true);
              await DataService.updateProduct(product);
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF252538),
                  title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
                  content: Text('Bạn có chắc muốn xóa ${product.name}?', style: const TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        Navigator.pop(context);
                        await DataService.deleteProduct(product.id);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
