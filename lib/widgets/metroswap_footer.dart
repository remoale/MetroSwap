import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MetroSwapFooter extends StatefulWidget {
  const MetroSwapFooter({super.key});

  @override
  State<MetroSwapFooter> createState() => _MetroSwapFooterState();
}

class _MetroSwapFooterState extends State<MetroSwapFooter> {
  bool _isAdmin = false;
  // Mantenemos el color gris original para usuarios normales
  final Color _colorOriginal = const Color(0xFF333333); 
  // ¡Aquí está tu nuevo color terracota favorito para el admin!
  final Color _colorAdmin = const Color(0xFFC93C20); 

  @override
  void initState() {
    super.initState();
    _verificarRolAdmin();
  }

  Future<void> _verificarRolAdmin() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && mounted) {
          final isAdminUser = doc.data()?['role']?.toString().toLowerCase() == 'admin';
          setState(() {
            _isAdmin = isAdminUser;
          });
        }
      } catch (e) {
        debugPrint("Error verificando admin en Footer: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        // AQUÍ APLICAMOS EL COLOR DINÁMICO
        color: _isAdmin ? _colorAdmin : _colorOriginal,
        // *** CAMBIO CLAVE AQUÍ ***
        // Hemos eliminado la línea que redondeaba las esquinas superiores.
        // Ahora el Container será un rectángulo perfecto.
      ),
      child: const Text(
        '© 2026 MetroSwap - Universidad Metropolitana.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}