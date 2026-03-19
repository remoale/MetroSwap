import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Encapsula la creación y captura de pagos de PayPal.
class PaymentController {
  PaymentController();

  static const String _paypalHttpEndpoint =
      "https://us-central1-metroswap-73a05.cloudfunctions.net/createPayPalOrderHttp";
  static const String _paypalCaptureHttpEndpoint =
      "https://us-central1-metroswap-73a05.cloudfunctions.net/capturePayPalOrderHttp";

  Map<String, dynamic> _normalizeMapData(dynamic data, String action) {
    try {
      final normalized = jsonDecode(jsonEncode(data));
      if (normalized is Map) {
        return Map<String, dynamic>.from(normalized);
      }
    } catch (_) {
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      "Respuesta invalida en $action: ${data.runtimeType}",
    );
  }

  String _fallbackErrorMessage(Object error, String action) {
    try {
      final text = error.toString().trim();
      if (text.isNotEmpty && text != "Exception") {
        return text.replaceFirst("Exception: ", "").trim();
      }
    } catch (_) {
      // Ignora errores de serialización inestables en web.
    }
    return "No se pudo $action. Intenta nuevamente.";
  }

  /// Crea una orden en PayPal mediante una Cloud Function.
  Future<String> createPayment({
    required double amount,
    required String returnUrl,
    required String cancelUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_paypalHttpEndpoint),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "amount": amount,
          "returnUrl": returnUrl,
          "cancelUrl": cancelUrl,
        }),
      );

      final data = _normalizeMapData(
        jsonDecode(response.body),
        "createPayment",
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorMessage = data["error"]?.toString().trim();
        throw Exception(
          errorMessage?.isNotEmpty == true
              ? errorMessage!
              : "No se pudo crear la orden de PayPal.",
        );
      }

      final approveUrl = data["approveUrl"]?.toString().trim() ?? "";
      if (approveUrl.isEmpty) {
        throw Exception("PayPal no devolvio el link de aprobacion.");
      }

      return approveUrl;
    } catch (e, stackTrace) {
      final message = _fallbackErrorMessage(e, "crear la orden de PayPal");
      debugPrint("Error en PaymentController.createPayment");
      debugPrintStack(stackTrace: stackTrace);
      throw Exception(message);
    }
  }

  /// Captura el pago después del retorno desde PayPal.
  Future<Map<String, dynamic>> capturePayment({
    required String orderId,
    String? exchangeId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_paypalCaptureHttpEndpoint),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "orderId": orderId,
          if (exchangeId != null && exchangeId.trim().isNotEmpty)
            "exchangeId": exchangeId.trim(),
        }),
      );

      final data = _normalizeMapData(
        jsonDecode(response.body),
        "capturePayment",
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorMessage = data["error"]?.toString().trim();
        throw Exception(
          errorMessage?.isNotEmpty == true
              ? errorMessage!
              : "No se pudo capturar el pago.",
        );
      }

      return data;
    } catch (e, stackTrace) {
      final message = _fallbackErrorMessage(e, "capturar el pago");
      debugPrint("Error en PaymentController.capturePayment");
      debugPrintStack(stackTrace: stackTrace);
      throw Exception(message);
    }
  }
}
