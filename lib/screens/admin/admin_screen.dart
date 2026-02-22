import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de admin'),
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Eres administrador 🛠️',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}