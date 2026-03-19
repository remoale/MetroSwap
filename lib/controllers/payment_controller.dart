import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

class PaymentController {
  PaymentController()
    : _functions = FirebaseFunctions.instanceFor(region: "us-central1");

  static const String _paypalHttpEndpoint =
      "https://us-central1-metroswap-73a05.cloudfunctions.net/createPayPalOrderHttp";

  final FirebaseFunctions _functions;

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

  String _formatCallableError(FirebaseFunctionsException error) {
    final code = error.code.trim();
    final message = (error.message ?? "").trim();
    if (code.isNotEmpty && message.isNotEmpty) {
      return "$code: $message";
    }
    if (message.isNotEmpty) {
      return message;
    }
    if (code.isNotEmpty) {
      return "Cloud Functions error: $code";
    }
    return "Error desconocido en Cloud Functions.";
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
      final result = await _functions
          .httpsCallable("capturePayPalOrder")
          .call({
            "orderId": orderId,
            if (exchangeId != null && exchangeId.trim().isNotEmpty)
              "exchangeId": exchangeId.trim(),
          });

      return _normalizeMapData(result.data, "capturePayment");
    } on FirebaseFunctionsException catch (e, stackTrace) {
      final message = _formatCallableError(e);
      debugPrint("Error en PaymentController.capturePayment: $message");
      debugPrintStack(stackTrace: stackTrace);
      throw Exception(message);
    } catch (e, stackTrace) {
      final message = _fallbackErrorMessage(e, "capturar el pago");
      debugPrint("Error en PaymentController.capturePayment");
      debugPrintStack(stackTrace: stackTrace);
      throw Exception(message);
    }
  }
}
