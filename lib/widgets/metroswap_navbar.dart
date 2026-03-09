import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metroswap/screens/admin/admin_screen.dart';
import 'package:metroswap/screens/about/about_screen.dart';
import 'package:metroswap/screens/home_screen.dart';
import 'package:metroswap/screens/landing_screen.dart';
import 'package:metroswap/screens/notifications/notifications_screen.dart';
import 'package:metroswap/screens/profile/profile_screen.dart';
import 'package:metroswap/screens/exchange/show_material.dart';
import 'package:metroswap/screens/exchange/exchange.dart'; 
import 'package:metroswap/screens/publish/publish_screen.dart'; 
import 'package:metroswap/services/auth_service.dart';
import 'package:metroswap/widgets/metroswap_brand.dart';

class MetroSwapNavbar extends StatefulWidget {
  final bool developmentNav;
  final String heading;
  final bool showLogoutButton;
  final bool showNotificationsButton;
  final bool showProfileButton;

  const MetroSwapNavbar({
    super.key,
    required this.developmentNav,
    required this.heading,
    this.showLogoutButton = false,
    this.showNotificationsButton = true,
    this.showProfileButton = true,
  });

  @override
  State<MetroSwapNavbar> createState() => _MetroSwapNavbarState();
}

class _MetroSwapNavbarState extends State<MetroSwapNavbar> {
  bool _isAdmin = false;
  final Color _colorOriginal = const Color(0xFF2C2C2C);
  final Color _colorAdmin = const Color(0xFFC93C20); // Tu color terracota

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
        debugPrint("Error verificando admin en Navbar: $e");
      }
    }
  }

  void _navigateToAdmin(BuildContext context) {
    if (_isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminScreen()),
      );
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final authService = AuthService();
    await authService.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedHeading = widget.heading.toLowerCase();
    final isHome = normalizedHeading == 'inicio';
    final isNotifications = normalizedHeading == 'notificaciones';
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Container(
      height: 85,
      color: _isAdmin ? _colorAdmin : _colorOriginal, 
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToAdmin(context),
            child: const MetroSwapBrand(
              color: Colors.white,
            ),
          ),
          // *** NUEVO CÓDIGO AQUÍ: Mensaje de "Bienvenido admin" ***
          if (_isAdmin) ...[
            const SizedBox(width: 15), // Separación del logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2), // Un fondo semi-transparente elegante
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Bienvenido admin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          
          if (!isHome) ...[
            const SizedBox(width: 24),
            Expanded(
              child: Center(
                child: Text(
                  widget.heading,
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
                      MaterialPageRoute(builder: (_) => const TradeChatScreen(tradeId: 'oxwHctJT1W84enkndGT',)), //AQUI PARA PROBAR, deberia ir Publish
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
                      MaterialPageRoute(
                        builder: (_) => isLoggedIn
                            ? const HomeScreen()
                            : const LandingScreen(),
                      ),
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
              if (widget.showLogoutButton) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _handleSignOut(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAdmin ? const Color(0xFF2C2C2C) : const Color(0xFFFF5C00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.exit_to_app, size: 18),
                  label: const Text("Cerrar sesion"),
                ),
              ],
              if (widget.showNotificationsButton && isLoggedIn) ...[
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
              ],
              if (widget.showProfileButton && isLoggedIn) ...[
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
              const SizedBox(width: 28),
            ],
          ),
        ],
      ),
    );
  }
}