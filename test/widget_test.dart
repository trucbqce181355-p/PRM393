import 'package:flutter_test/flutter_test.dart';
import 'package:traicay/main.dart';

void main() {
  testWidgets('Voucher app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
