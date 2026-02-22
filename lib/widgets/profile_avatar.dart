import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? localImageBytes;
  final double size;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.localImageBytes,
    this.size = 60,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();

    Widget avatarChild = const Icon(Icons.person, size: 40);

    if (localImageBytes != null) {
      avatarChild = ClipOval(
        child: Image.memory(
          localImageBytes!,
          width: size * 2,
          height: size * 2,
          fit: BoxFit.cover,
        ),
      );
    } else if (normalizedUrl != null && normalizedUrl.isNotEmpty) {
      avatarChild = ClipOval(
        child: Image.network(
          normalizedUrl,
          width: size * 2,
          height: size * 2,
          fit: BoxFit.cover,
          webHtmlElementStrategy: kIsWeb
              ? WebHtmlElementStrategy.prefer
              : WebHtmlElementStrategy.never,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, size: 40),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size,
        child: avatarChild,
      ),
    );
  }
}
