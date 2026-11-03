import 'package:intl/intl.dart';

class FormatHelper {
  static String formatPrice(double price) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(price);
  }
}
