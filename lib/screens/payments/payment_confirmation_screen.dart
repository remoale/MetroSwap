import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final double amount;

  const PaymentConfirmationScreen({
    super.key,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pago completado"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 90,
            ),
            const SizedBox(height: 20),

            Text(
              "¡Pago exitoso!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 10),

            Text(
              "Tu pago de \$${0} se ha procesado correctamente."
                  .replaceAll("0", amount.toStringAsFixed(2)),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 40),

            PrimaryButton(
              text: "Continuar",
              onPressed: () {
                Navigator.pop(context); // o navega a otra pantalla
              },
            ),
          ],
        ),
      ),
    );
  }
}
