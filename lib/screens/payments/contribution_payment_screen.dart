import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/controllers/payment_controller.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_layout.dart'; 
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

import 'payment_cancel_screen.dart';
import 'payment_confirmation_screen.dart';

/// Gestiona el flujo de pago de una contribución asociada a un intercambio.
class ContributionPaymentScreen extends StatefulWidget {
  final String tradeId;
  final String title;
  final String imageUrl;
  final double amount; // <-- Añadimos el monto exacto requerido

  const ContributionPaymentScreen({
    super.key,
    required this.tradeId,
    required this.title,
    required this.imageUrl,
    required this.amount, // <-- Se requiere al llamar a esta pantalla
  });

  @override
  State<ContributionPaymentScreen> createState() => _ContributionPaymentScreenState();
}

class _ContributionPaymentScreenState extends State<ContributionPaymentScreen> {
  final PaymentController _paymentController = PaymentController();
  bool _loadingPayPal = false;
  StreamSubscription? _linkSub;
  // Eliminamos _amount y _quickAmounts porque ahora el precio es fijo

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _linkSub = linkStream.listen((String? link) {
        if (link == null || !mounted) return;

        if (link.contains("paypal-success")) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              // Usamos el monto fijo del widget
              builder: (context) => PaymentConfirmationScreen(amount: widget.amount),
            ),
          );
        } else if (link.contains("paypal-cancel")) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PaymentCancelScreen()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _payWithPayPal() async {
    if (_loadingPayPal) return;
    setState(() => _loadingPayPal = true);

    final base = Uri.base;
    final returnUrl = base
        .replace(
          path: "/paypal-success",
          queryParameters: {"tradeId": widget.tradeId},
        )
        .toString();
    final cancelUrl = base
        .replace(
          path: "/paypal-cancel",
          queryParameters: {"tradeId": widget.tradeId},
        )
        .toString();

    final url = await _paymentController.createPayment(
      amount: widget.amount,
      returnUrl: returnUrl,
      cancelUrl: cancelUrl,
    );

    if (!mounted) return;
    setState(() => _loadingPayPal = false);

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error creando orden PayPal")),
      );
      return;
    }

    if (kIsWeb) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: "_self",
      );
      return;
    }

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = widget.title.trim().isEmpty ? 'Titulo del Material' : widget.title;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return MetroSwapLayout(
      body: SafeArea(
        child: Column(
          children: [
            if (!isMobile)
              const MetroSwapNavbar(
                developmentNav: true,
                heading: 'Contribuciones',
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver al intercambio'),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20), 
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 22),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F3035),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildLeftPanel(resolvedTitle, isMobile: true),
                                const SizedBox(height: 22),
                                _buildPaymentPanel(isMobile: true),
                              ],
                            )
                          : IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch, 
                                children: [
                                  _buildLeftPanel(resolvedTitle, isMobile: false),
                                  const SizedBox(width: 22),
                                  Expanded(child: _buildPaymentPanel(isMobile: false)),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            if (!isMobile) const MetroSwapFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(String resolvedTitle, {required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : 240, 
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF25262A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, 
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
          const Text('Contribucion', style: TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            // Mostramos el monto fijo
            '\$${widget.amount.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          // Se eliminaron los botones de '+' y '-' el Slider y la lista de botones rápidos.
        ],
      ),
    );
  }

  Widget _buildPaymentPanel({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD1CED4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Container(
          width: isMobile ? double.infinity : 460,
          margin: isMobile ? const EdgeInsets.all(16) : EdgeInsets.zero, 
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F1),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 86,
                child: Center(
                  child: Image.asset(
                    'assets/brands/paypal.png',
                    width: 300,
                    height: 86,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    cacheWidth: 480,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'PayPal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF2466B2),
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                // Mostramos el monto fijo
                'Monto a pagar: \$${widget.amount.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loadingPayPal ? null : _payWithPayPal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4589),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loadingPayPal
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Pagar con PayPal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// La clase _QuickAmountButton fue eliminada completamente ya que no se usará más.