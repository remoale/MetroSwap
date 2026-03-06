import 'package:paypal_sdk/core.dart';
import 'package:paypal_sdk/orders.dart';
import 'package:collection/collection.dart';

class PayPalSDKService {
  late PayPalHttpClient _client;
  late OrdersApi _ordersApi;

  PayPalSDKService() {
    _client = PayPalHttpClient(
      PayPalEnvironment.sandbox(
        clientId: "TU_CLIENT_ID",
        clientSecret: "TU_CLIENT_SECRET",
      ),
    );

    _ordersApi = OrdersApi(_client);
  }

  /// Crea una orden PayPal y devuelve la URL de aprobación
  Future<String?> createOrder(double amount) async {
    try {
      final orderRequest = OrderRequest(
        intent: OrderRequestIntent.capture,
        purchaseUnits: [
          PurchaseUnitRequest(
            amount: AmountWithBreakdown(
              currencyCode: "USD",
              value: amount.toString(),
            ),
          ),
        ],
        applicationContext: ApplicationContext(
          returnUrl: "myapp://paypal-success",
          cancelUrl: "myapp://paypal-cancel",
        ),
      );

      final order = await _ordersApi.createOrder(orderRequest);

      // Buscar el link de aprobación
      LinkDescription? approveLink;
      try {
        approveLink = order.links?.firstWhereOrNull((link) => link.rel == "approve");
      } catch (e) {
        approveLink = null;
      }
      return approveLink?.href;
    } catch (e) {
      print("Error creando orden PayPal: $e");
      return null;
    }
  }
}