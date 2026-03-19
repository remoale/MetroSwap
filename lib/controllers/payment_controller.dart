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
      if (data is! Map) {
        debugPrint("Respuesta invalida en createPayment: ${data.runtimeType}");
        return null;
      }

      // Busca el enlace de aprobación dentro de la respuesta de PayPal.
      final links = data["links"];
      if (links is! List) {
        debugPrint("No se encontro la lista de links de PayPal.");
        return null;
      }

      final approveLink = links.firstWhere(
        (l) => l is Map && l["rel"] == "approve",
        orElse: () => null,
      );

      if (approveLink is! Map || approveLink["href"] is! String) {
        debugPrint("No se encontro el link de aprobacion de PayPal.");
        return null;
      }

      return approveLink["href"] as String; // URL de aprobación de PayPal.
    } catch (e, stackTrace) {
      debugPrint("Error en PaymentController.createPayment: $e");
      debugPrintStack(stackTrace: stackTrace);
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

      final data = result.data;
      if (data is! Map) {
        debugPrint("Respuesta invalida en capturePayment: ${data.runtimeType}");
        return null;
      }

      return Map<String, dynamic>.from(data);
    } catch (e, stackTrace) {
      debugPrint("Error en PaymentController.capturePayment: $e");
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}
