import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/payment_controller.dart';
import '../../widgets/primary_button.dart';
import 'payment_confirmation_screen.dart';
import 'payment_cancel_screen.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';


class PayPalSDKPaymentScreen extends StatefulWidget {
  final double amount;

  const PayPalSDKPaymentScreen({super.key, required this.amount});

  @override
  State<PayPalSDKPaymentScreen> createState() => _PayPalSDKPaymentScreenState();
}

class _PayPalSDKPaymentScreenState extends State<PayPalSDKPaymentScreen> {
  final PaymentController _controller = PaymentController();
  bool loading = false;

  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = linkStream.listen((String? link) {
      if (link == null) return;

      if (link.contains("paypal-success")) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentConfirmationScreen(amount: widget.amount),
          ),
        );
      } 
      if (link.contains("paypal-cancel")) {
        Navigator.pushReplacement(
          context,
           MaterialPageRoute(
            builder: (context) => const PaymentCancelScreen()
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> pay() async {
    setState(() => loading = true);

    final url = await _controller.createPayment(widget.amount);

    setState(() => loading = false);

    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentConfirmationScreen(amount: widget.amount),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error creando orden PayPal")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pagar con PayPal (SDK)")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Monto a pagar: \$${widget.amount}"),
            const SizedBox(height: 20),

            PrimaryButton(
              text: "Pagar con PayPal",
              loading: loading,
              onPressed: pay,
            ),
          ],
        ),
      ),
    );
  }
}
