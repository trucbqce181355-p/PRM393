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

// Global in-memory cart with complete helper APIs
class Cart {
  static final List<CartItem> _items = [];

  static List<CartItem> get items => _items;

  static bool get isEmpty => _items.isEmpty;

  static bool get isNotEmpty => _items.isNotEmpty;

  static int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  static void addItem(Product product, int quantity) {
    if (quantity <= 0) return;
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: 'cart_${DateTime.now().millisecondsSinceEpoch}_${product.id}',
        product: product,
        quantity: quantity,
      ));
    }
  }

  static void updateQuantity(String productId, int newQuantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
    }
  }

  static void changeQuantity(String productId, int delta) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final updated = _items[index].quantity + delta;
      if (updated <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = updated;
      }
    }
  }

  static void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
  }

  static void clear() {
    _items.clear();
  }

  static double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.totalPrice;
    }
    return total;
  }
}
