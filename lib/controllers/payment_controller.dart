import 'package:flutter/foundation.dart';

import '../services/paypal_sdk_service.dart';

class PaymentController {
  final PayPalSDKService _paypalService = PayPalSDKService();

  /// Crea una orden de pago y devuelve la URL de aprobación de PayPal
  Future<String?> createPayment(double amount) async {
    try {
      final url = await _paypalService.createOrder(amount);
      return url;
    } catch (e) {
      debugPrint("Error en PaymentController.createPayment: $e");
      return null;
    }
  }
}
