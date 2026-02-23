import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metroswap/screens/admin/admin_screen.dart';
import 'package:metroswap/screens/profile/profile_screen.dart';

class MetroSwapNavbar extends StatelessWidget {
  final bool developmentNav;
  final String heading;

  const MetroSwapNavbar({
    super.key,
    required this.developmentNav,
    required this.heading,
  });

  // Única lógica adicional: El acceso para el administrador
  Future<void> _navigateToAdmin(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && doc.data()?['isAdmin'] == true) {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminScreen()),
            );
          }
        }
      } catch (e) {
        debugPrint("Error verificando admin: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      color: const Color(0xFF333333),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          // Logo con acceso secreto para admin
          GestureDetector(
            onTap: () => _navigateToAdmin(context),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo_metroswap.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                const Text(
                  'MetroSwap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Botón Publicar (Sin lógica, tal como lo tenías)
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Publicar'),
          ),
          const SizedBox(width: 15),
          // BOTÓN CONÓCENOS: Lógica eliminada, ahora no hace nada
          OutlinedButton(
            onPressed: () {}, // <--- Aquí quitamos cualquier navegación
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Conócenos'),
          ),
          const SizedBox(width: 25),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white70, size: 35),
            onPressed: () {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(uid: currentUser.uid),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}