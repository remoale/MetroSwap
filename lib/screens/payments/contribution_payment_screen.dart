import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/screens/payments/paypal_sdk_payment_screen.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

class ContributionPaymentScreen extends StatefulWidget {
  final String tradeId;
  final String title;
  final String imageUrl;

  const ContributionPaymentScreen({
    super.key,
    required this.tradeId,
    required this.title,
    required this.imageUrl,
  });

  @override
  State<ContributionPaymentScreen> createState() => _ContributionPaymentScreenState();
}

class _ContributionPaymentScreenState extends State<ContributionPaymentScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  double _amount = 30;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _goToPayPal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayPalSDKPaymentScreen(amount: _amount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = widget.title.trim().isEmpty ? 'Titulo del Material' : widget.title;

    return Scaffold(
      backgroundColor: const Color(0xFFDAD7DD),
      body: SafeArea(
        child: Column(
          children: [
            const MetroSwapNavbar(
              developmentNav: true,
              heading: 'Contribuciones',
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Container(
                    margin: const EdgeInsets.all(22),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F3035),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLeftPanel(resolvedTitle),
                        const SizedBox(width: 22),
                        Expanded(child: _buildPaymentPanel()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const MetroSwapFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(String resolvedTitle) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF25262A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 150,
              color: const Color(0xFF3B3D43),
              child: widget.imageUrl.trim().isEmpty
                  ? const Icon(Icons.image_outlined, color: Colors.white70, size: 56)
                  : Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: kIsWeb
                          ? WebHtmlElementStrategy.prefer
                          : WebHtmlElementStrategy.never,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white70,
                        size: 56,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEE6F2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              resolvedTitle,
              style: const TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Categoria', style: TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Contribucion', style: TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            '\$${_amount.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Slider(
            value: _amount,
            min: 0,
            max: 100,
            activeColor: const Color(0xFFEE6F2E),
            inactiveColor: const Color(0xFFB8BBC4),
            onChanged: (value) => setState(() => _amount = value),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _goToPayPal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE9C832),
              foregroundColor: const Color(0xFF333333),
            ),
            child: const Text('Contribuir con PayPal'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD1CED4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'PayPal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2466B2),
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Correo'),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Ingrese Correo',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Contraseña'),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Ingrese Contraseña',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _goToPayPal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A4589),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Iniciar Sesion'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: ElevatedButton(
                  onPressed: _goToPayPal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE9C832),
                    foregroundColor: const Color(0xFF333333),
                  ),
                  child: const Text('Pago enviado'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
