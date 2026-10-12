import 'product.dart';

class CartItem {
  final String id; // Unique ID for cart entry
  final Product product;
  int quantity;

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}

// Temporary in-memory cart until we set up state management (Provider)
class Cart {
  static final List<CartItem> _items = [];

  static List<CartItem> get items => _items;

  static void addItem(Product product, int quantity) {
    // Check if exists
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: DateTime.now().toString(),
        product: product,
        quantity: quantity,
      ));
    }
  }

  static double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.totalPrice;
    }
    return total;
  }
}
