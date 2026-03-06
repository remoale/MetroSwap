import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/payment_controller.dart';
import '../../widgets/primary_button.dart';

class PayPalSDKPaymentScreen extends StatefulWidget {
  final double amount;

  const PayPalSDKPaymentScreen({super.key, required this.amount});

  @override
  State<PayPalSDKPaymentScreen> createState() => _PayPalSDKPaymentScreenState();
}

class _PayPalSDKPaymentScreenState extends State<PayPalSDKPaymentScreen> {
  final PaymentController _controller = PaymentController();
  bool loading = false;

  Future<void> pay() async {
    setState(() => loading = true);

    final url = await _controller.createPayment(widget.amount);

    setState(() => loading = false);

    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
