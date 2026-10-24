/// Handles the confirmation step for cash-on-delivery orders.
class CodPaymentService {
  const CodPaymentService();

  Future<void> process(Future<void> Function() confirmOrder) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    await confirmOrder();
  }
}
