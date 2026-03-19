import 'package:flutter/material.dart';
import 'package:metroswap/controllers/payment_controller.dart';
import 'package:metroswap/screens/exchange/exchange.dart';
import 'package:metroswap/screens/home_screen.dart';
import 'package:metroswap/screens/payments/payment_confirmation_screen.dart';

/// Procesa el retorno desde PayPal después de aprobar o cancelar el pago.
class PayPalReturnScreen extends StatefulWidget {
  final bool success;

  const PayPalReturnScreen({
    super.key,
    required this.success,
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

  @override
  void initState() {
    super.initState();
    _handle();
  }

  Future<void> _handle() async {
    final uri = Uri.base;
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

    final amountStr = result["purchase_units"]?[0]?["payments"]?["captures"]?[0]?["amount"]?["value"];
    final parsedAmount = double.tryParse((amountStr ?? "").toString());

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
      amount: _capturedAmount ?? 0,
      exchangeId: _exchangeId,
    );
  }
}

