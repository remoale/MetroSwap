import 'package:flutter/material.dart';

class MetroSwapBrand extends StatelessWidget {
  final Color color;
  final double logoHeight;
  final double fontSize;
  final double logoYOffset;

  const MetroSwapBrand({
    super.key,
    this.color = Colors.white,
    this.logoHeight = 64,
    this.fontSize = 26,
    this.logoYOffset = -6,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.translate(
          offset: Offset(0, logoYOffset),
          child: Image.asset(
            'assets/images/logo_metroswap.png',
            height: logoHeight,
            fit: BoxFit.contain,
          ),
        ),
        Transform.translate(
          offset: const Offset(-12, 0),
          child: Text(
            'MetroSwap',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
