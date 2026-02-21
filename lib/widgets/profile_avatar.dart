import 'dart:io';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final File? localImage;
  final double size;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.localImage,
    this.size = 60,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;
    
    if (localImage != null) {
      provider = FileImage(localImage!);
    } else if (imageUrl != null) {
      provider = NetworkImage(imageUrl!);
    }
    
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size,
        backgroundImage: provider,
        child: provider == null
            ? const Icon(Icons.person, size: 40)
            : null,
      ),
    );
  }
}