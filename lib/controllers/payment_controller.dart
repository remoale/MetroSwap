import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PaymentController {
  final _functions = FirebaseFunctions.instance;

  /// 1. Crear orden en PayPal (via Cloud Function)
  Future<String?> createPayment(double amount) async {
    try {
      final result = await _functions
          .httpsCallable("createPayPalOrder")
          .call({"amount": amount});

      final data = result.data;

      // Buscar el approval_url dentro de los links de PayPal
      final links = data["links"] as List<dynamic>;
      final approveLink = links.firstWhere(
        (l) => l["rel"] == "approve",
        orElse: () => null,
      );

      if (approveLink == null) return null;

      return approveLink["href"]; // URL para abrir PayPal
    } catch (e) {
      debugPrint("Error en PaymentController.createPayment: $e");
      return null;
    }
  }

  /// 2. Capturar el pago después del returnUrl
  Future<Map<String, dynamic>?> capturePayment(String orderId) async {
    try {
      final result = await _functions
          .httpsCallable("capturePayPalOrder")
          .call({"orderId": orderId});

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint("Error en PaymentController.capturePayment: $e");
      return null;
    }
  }
}
