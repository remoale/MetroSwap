import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PaymentController {
  PaymentController()
    : _functions = FirebaseFunctions.instanceFor(region: "us-central1");

  final FirebaseFunctions _functions;

  /// Crea una orden en PayPal mediante una Cloud Function.
  Future<String?> createPayment({
    required double amount,
    required String returnUrl,
    required String cancelUrl,
  }) async {
    try {
      final result = await _functions
          .httpsCallable("createPayPalOrder")
          .call({
            "amount": amount,
            "returnUrl": returnUrl,
            "cancelUrl": cancelUrl,
          });

      final data = result.data;

      // Busca el enlace de aprobación dentro de la respuesta de PayPal.
      final links = data["links"] as List<dynamic>;
      final approveLink = links.firstWhere(
        (l) => l["rel"] == "approve",
        orElse: () => null,
      );

      if (approveLink == null) return null;

      return approveLink["href"]; // URL de aprobación de PayPal.
    } catch (e) {
      debugPrint("Error en PaymentController.createPayment: $e");
      return null;
    }
  }

  /// Captura el pago después del retorno desde PayPal.
  Future<Map<String, dynamic>?> capturePayment({
    required String orderId,
    String? exchangeId,
  }) async {
    try {
      final result = await _functions
          .httpsCallable("capturePayPalOrder")
          .call({
            "orderId": orderId,
            if (exchangeId != null && exchangeId.trim().isNotEmpty)
              "exchangeId": exchangeId.trim(),
          });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint("Error en PaymentController.capturePayment: $e");
      return null;
    }
  }
}
