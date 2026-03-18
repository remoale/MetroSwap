import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:metroswap/screens/exchange/exchange.dart';
import 'package:metroswap/screens/home_screen.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final double amount;
  final String? exchangeId;

  const PaymentConfirmationScreen({
    super.key,
    required this.amount,
    this.exchangeId,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d \'de\' MMMM \'de\' y', 'es')
        .format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFE9E7EA),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Container(
              margin: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF2F3035),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: _LeftSummary(
                        amount: amount,
                        dateLabel: dateLabel,
                        exchangeId: exchangeId,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: _RightActions(exchangeId: exchangeId),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeftSummary extends StatelessWidget {
  final double amount;
  final String dateLabel;
  final String? exchangeId;

  const _LeftSummary({
    required this.amount,
    required this.dateLabel,
    required this.exchangeId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirmación de pago',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: Color(0xFF2ECC71),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Producto comprado',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Compra realizada el $dateLabel',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10),
        if (exchangeId != null) ...[
          Text(
            'Exchange: $exchangeId',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class _RightActions extends StatelessWidget {
  final String? exchangeId;
  const _RightActions({required this.exchangeId});

  @override
  Widget build(BuildContext context) {
    Widget card({
      required String title,
      required String subtitle,
      required String imageAsset,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: AssetImage(imageAsset),
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(
                  Color(0x66000000),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          card(
            title: 'Buscar más material',
            subtitle: 'Explora publicaciones nuevas',
            imageAsset: 'assets/images/pago_buscar_material.png',
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
          ),
          const SizedBox(height: 16),
          card(
            title: exchangeId == null ? 'Ir al inicio' : 'Ir al intercambio',
            subtitle: exchangeId == null ? 'Volver a MetroSwap' : 'Ver el intercambio completado',
            imageAsset: 'assets/images/pago_ir_intercambio.png',
            onTap: () {
              if (exchangeId == null) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                return;
              }
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => TradeChatScreen(tradeId: exchangeId!)),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
