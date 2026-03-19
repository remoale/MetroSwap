import 'package:flutter/material.dart';
import 'package:metroswap/controllers/payment_controller.dart';
import 'package:metroswap/screens/exchange/exchange.dart';
import 'package:metroswap/screens/home_screen.dart';
import 'package:metroswap/screens/payments/payment_confirmation_screen.dart';

/// Procesa el retorno desde PayPal después de aprobar o cancelar el pago.
class PayPalReturnScreen extends StatefulWidget {
  final bool success;
  final Uri? callbackUri;

  const PayPalReturnScreen({
    super.key,
    required this.success,
    this.callbackUri,
  });

  @override
  State<PayPalReturnScreen> createState() => _PayPalReturnScreenState();
}

class _PayPalReturnScreenState extends State<PayPalReturnScreen> {
  final PaymentController _paymentController = PaymentController();
  bool _loading = true;
  String? _error;
  double? _capturedAmount;
  String? _exchangeId;

  double? _extractCapturedAmount(Map<String, dynamic> result) {
    final purchaseUnits = result["purchase_units"];
    if (purchaseUnits is! List || purchaseUnits.isEmpty) {
      return null;
    }

    final firstUnit = purchaseUnits.first;
    if (firstUnit is! Map) {
      return null;
    }

    final payments = firstUnit["payments"];
    if (payments is! Map) {
      return null;
    }

    final captures = payments["captures"];
    if (captures is! List || captures.isEmpty) {
      return null;
    }

    final firstCapture = captures.first;
    if (firstCapture is! Map) {
      return null;
    }

    final amount = firstCapture["amount"];
    if (amount is! Map) {
      return null;
    }

    final value = amount["value"];
    if (value == null) {
      return null;
    }

    return double.tryParse(value.toString());
  }

  @override
  void initState() {
    super.initState();
    _handle();
  }

  Future<void> _handle() async {
    final uri = widget.callbackUri ?? Uri.base;
    final exchangeId = uri.queryParameters["tradeId"]?.trim();
    _exchangeId = (exchangeId != null && exchangeId.isNotEmpty) ? exchangeId : null;

    if (!widget.success) {
      setState(() => _loading = false);
      return;
    }

    final orderId = uri.queryParameters["token"];

    if (orderId == null || orderId.isEmpty) {
      setState(() {
        _loading = false;
        _error = "No se encontró el token de PayPal.";
      });
      return;
    }

    final result = await _paymentController.capturePayment(
      orderId: orderId,
      exchangeId: _exchangeId,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _loading = false;
        _error = "No se pudo capturar el pago.";
      });
      return;
    }

    final parsedAmount = _extractCapturedAmount(result);
    if (parsedAmount == null || parsedAmount <= 0) {
      setState(() {
        _loading = false;
        _error = "PayPal respondio sin un monto valido para confirmar el pago.";
      });
      return;
    }

    setState(() {
      _loading = false;
      _capturedAmount = parsedAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!widget.success) {
      final exchangeId = _exchangeId;
      if (exchangeId != null && exchangeId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => TradeChatScreen(tradeId: exchangeId)),
            (_) => false,
          );
          messenger.showSnackBar(
            const SnackBar(content: Text('Pago cancelado.')),
          );
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Pago cancelado.')),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Pago")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 72, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false,
                  );
                },
                child: const Text("Volver al inicio"),
              ),
            ],
          ),
        ),
      );
    }

    return PaymentConfirmationScreen(
      amount: _capturedAmount!,
      exchangeId: _exchangeId,
    );
  }
}

