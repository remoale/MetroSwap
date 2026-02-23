import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metroswap/screens/admin/admin_screen.dart';
import 'package:metroswap/screens/about/about_screen.dart';
import 'package:metroswap/screens/home_screen.dart';
import 'package:metroswap/screens/notifications/notifications_screen.dart';
import 'package:metroswap/screens/profile/profile_screen.dart';
import 'package:metroswap/screens/publish/publish_screen.dart';
import 'package:metroswap/widgets/metroswap_brand.dart';

class MetroSwapNavbar extends StatelessWidget {
  final bool developmentNav;
  final String heading;

  const MetroSwapNavbar({
    super.key,
    required this.developmentNav,
    required this.heading,
  });

  Future<void> _navigateToAdmin(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        final data = doc.data();
        final isAdminUser = data?['role']?.toString().toLowerCase() == 'admin';
        if (doc.exists && isAdminUser) {
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
    final normalizedHeading = heading.toLowerCase();
    final isHome = normalizedHeading == 'inicio';
    final isNotifications = normalizedHeading == 'notificaciones';

    return Container(
      height: 85,
      color: const Color(0xFF2C2C2C),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToAdmin(context),
            child: const MetroSwapBrand(
              color: Colors.white,
            ),
          ),
          if (!isHome) ...[
            const SizedBox(width: 24),
            Expanded(
              child: Center(
                child: Text(
                  heading,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else
            const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHome) ...[
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PublishScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Publicar'),
                ),
                const SizedBox(width: 15),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Conócenos'),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Inicio'),
                ),
              ],
              const SizedBox(width: 25),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                onPressed: isNotifications
                    ? null
                    : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
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
        ],
      ),
    );
  }
}
