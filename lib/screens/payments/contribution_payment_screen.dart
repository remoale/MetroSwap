import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/controllers/payment_controller.dart';
import 'package:metroswap/screens/payments/paypal_return_screen.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_layout.dart'; 
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

/// Gestiona el flujo de pago de una contribución asociada a un intercambio.
class ContributionPaymentScreen extends StatefulWidget {
  final String tradeId;
  final String title;
  final String imageUrl;
  final double amount;
  final bool allowCustomAmount;

  const ContributionPaymentScreen({
    super.key,
    required this.tradeId,
    required this.title,
    required this.imageUrl,
    required this.amount,
    required this.allowCustomAmount,
  });

  @override
  State<ContributionPaymentScreen> createState() => _ContributionPaymentScreenState();
}

class _ContributionPaymentScreenState extends State<ContributionPaymentScreen> {
  final PaymentController _paymentController = PaymentController();
  double _amount = 30;
  bool _loadingPayPal = false;
  StreamSubscription? _linkSub;
  static const List<int> _quickAmounts = [1, 5, 10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _amount = widget.amount > 0 ? widget.amount : 30;

    if (!kIsWeb) {
      _linkSub = linkStream.listen((String? link) {
        if (link == null || !mounted) return;

        final callbackUri = Uri.tryParse(link);
        final callbackPath = callbackUri?.path;

        if (callbackPath == "/paypal-success") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PayPalReturnScreen(
                success: true,
                callbackUri: callbackUri,
              ),
            ),
          );
        } else if (callbackPath == "/paypal-cancel") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PayPalReturnScreen(
                success: false,
                callbackUri: callbackUri,
              ),
            ),
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
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El monto debe ser mayor a 0")),
      );
      return;
    }
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
      amount: _amount,
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final desktopMinHeight = (constraints.maxHeight - 90).clamp(360.0, 620.0);

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      isMobile ? 20 : 34,
                      0,
                      isMobile ? 24 : 44,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Container(
                          constraints: BoxConstraints(
                            minHeight: isMobile ? 0 : desktopMinHeight,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 22),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 18 : 22,
                            vertical: isMobile ? 18 : 24,
                          ),
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
                                      const SizedBox(width: 26),
                                      Expanded(child: _buildPaymentPanel(isMobile: false)),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                }
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
      width: isMobile ? double.infinity : 260,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
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
              height: isMobile ? 220 : 260,
              color: const Color(0xFF3B3D43),
              padding: const EdgeInsets.all(10),
              child: widget.imageUrl.trim().isEmpty
                  ? const Icon(Icons.image_outlined, color: Colors.white70, size: 56)
                  : Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
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
          Text(
            widget.allowCustomAmount ? 'Contribucion' : 'Monto requerido',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            '\$${_amount.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (widget.allowCustomAmount) ...[
            Row(
              children: [
                IconButton(
                  tooltip: 'Disminuir',
                  onPressed: _amount <= 0 ? null : () => setState(() => _amount -= 1),
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                ),
                Expanded(
                  child: Slider(
                    value: _amount,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: const Color(0xFFEE6F2E),
                    inactiveColor: const Color(0xFFB8BBC4),
                    onChanged: (value) => setState(() => _amount = value),
                  ),
                ),
                IconButton(
                  tooltip: 'Aumentar',
                  onPressed: _amount >= 100 ? null : () => setState(() => _amount += 1),
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickAmounts
                  .map(
                    (value) => _QuickAmountButton(
                      amount: value,
                      selected: _amount.round() == value,
                      onPressed: () => setState(() => _amount = value.toDouble()),
                    ),
                  )
                  .toList(),
            ),
          ],
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
          width: isMobile ? double.infinity : 560,
          margin: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(vertical: 28),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 26 : 34,
            isMobile ? 24 : 36,
            isMobile ? 26 : 34,
            isMobile ? 24 : 36,
          ),
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
              Container(
                height: isMobile ? 120 : 148,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/brands/paypal.png',
                  width: isMobile ? 260 : 360,
                  height: isMobile ? 100 : 128,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  cacheWidth: isMobile ? 900 : 1400,
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
              const SizedBox(height: 18),
              Text(
                widget.allowCustomAmount
                    ? 'Monto a pagar: \$${_amount.toStringAsFixed(0)}'
                    : 'Monto requerido: \$${_amount.toStringAsFixed(0)}',
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

class _QuickAmountButton extends StatelessWidget {
  final int amount;
  final bool selected;
  final VoidCallback onPressed;

  const _QuickAmountButton({
    required this.amount,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        backgroundColor: selected ? const Color(0xFFEE6F2E) : null,
        foregroundColor: selected ? Colors.white : Colors.white70,
        side: BorderSide(color: selected ? const Color(0xFFEE6F2E) : Colors.white24),
        visualDensity: VisualDensity.compact,
      ),
      child: Text('\$$amount'),
    );
  }
}
