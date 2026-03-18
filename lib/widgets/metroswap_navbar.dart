import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/screens/about/about_screen.dart';
import 'package:metroswap/screens/admin/admin_screen.dart';
import 'package:metroswap/screens/home_screen.dart';
import 'package:metroswap/screens/landing_screen.dart';
import 'package:metroswap/screens/notifications/notifications_screen.dart';
import 'package:metroswap/screens/profile/profile_screen.dart';
import 'package:metroswap/screens/publish/publish_screen.dart';
import 'package:metroswap/services/auth_service.dart';
import 'package:metroswap/utils/admin_utils.dart';
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
  final Color _colorAdmin = const Color(0xFFC93C20);

  @override
  void initState() {
    super.initState();
    final email = FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
    _isAdmin = isAdminEmail(email);
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

  Widget _buildNotificationsButton(
    BuildContext context,
    bool isNotifications,
    String uid,
  ) {
    final unreadStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: unreadStream,
      builder: (context, snapshot) {
        final unreadCount = _resolveVisibleUnreadCount(snapshot.data?.docs ?? const []);

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 28,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: isNotifications
              ? null
              : () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
        );
      },
    );
  }

  int _resolveVisibleUnreadCount(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    const lifecycleTypes = <String>{
      'exchange_requested',
      'exchange_accepted',
      'exchange_rejected',
      'exchange_completed',
      'exchange_cancelled',
    };

    final nonExchangeUnread = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final exchangeGroups = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final doc in docs) {
      final data = doc.data();
      final type = (data['type'] ?? '').toString().trim().toLowerCase();
      final exchangeId = (data['data'] is Map<String, dynamic>)
          ? ((data['data'] as Map<String, dynamic>)['exchangeId'] ?? '')
              .toString()
              .trim()
          : '';
      if (exchangeId.isEmpty || !lifecycleTypes.contains(type)) {
        nonExchangeUnread.add(doc);
        continue;
      }
      exchangeGroups.putIfAbsent(exchangeId, () => <QueryDocumentSnapshot<Map<String, dynamic>>>[])
          .add(doc);
    }

    var count = nonExchangeUnread.length;
    for (final group in exchangeGroups.values) {
      if (group.isNotEmpty) {
        count += 1;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final normalizedHeading = widget.heading.toLowerCase();
    final isHome = normalizedHeading == 'inicio';
    final isNotifications = normalizedHeading == 'notificaciones';
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final showMobileHeading = !isHome && !isMobile;

    return Container(
      height: 85,
      color: _isAdmin ? _colorAdmin : _colorOriginal,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 5 : 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToAdmin(context),
            child: MetroSwapBrand(
              color: Colors.white,
              logoHeight: isMobile ? 44 : 64,
              fontSize: isMobile ? 17 : 26,
              logoYOffset: isMobile ? -3 : -6,
            ),
          ),
          if (!isHome && isMobile) ...[
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        isLoggedIn ? const HomeScreen() : const LandingScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white70),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Inicio', style: TextStyle(fontSize: 12)),
            ),
          ],
          if (_isAdmin) ...[
            SizedBox(width: isMobile ? 5 : 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Bienvenido admin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 14 : 20,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          if (showMobileHeading) ...[
            SizedBox(width: isMobile ? 8 : 24),
            Expanded(
              child: Center(
                child: Text(
                  widget.heading,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                ),
              ),
            ),
          ] else
            const Spacer(),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                    minimumSize: Size(0, isMobile ? 36 : 40),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Publicar', style: TextStyle(fontSize: isMobile ? 14 : 16)),
                ),
                SizedBox(width: isMobile ? 8 : 15),
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
                    minimumSize: Size(0, isMobile ? 36 : 40),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Conócenos', style: TextStyle(fontSize: isMobile ? 14 : 16)),
                ),
              ] else ...[
                if (!isMobile)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              isLoggedIn ? const HomeScreen() : const LandingScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Inicio', style: TextStyle(fontSize: 16)),
                  ),
              ],
                if (widget.showLogoutButton) ...[
                SizedBox(width: isMobile ? 6 : 12),
                ElevatedButton.icon(
                  onPressed: () => _handleSignOut(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAdmin
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFFF5C00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size(0, isMobile ? 36 : 40),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.exit_to_app, size: 18),
                  // Ocultamos la palabra en móviles para que quepa el icono de salir
                  label: isMobile ? const SizedBox.shrink() : const Text('Cerrar sesion'),
                ),
                ],
                if (widget.showNotificationsButton && isLoggedIn) ...[
                SizedBox(width: isMobile ? 0 : 25),
                _buildNotificationsButton(
                  context,
                  isNotifications,
                  FirebaseAuth.instance.currentUser!.uid,
                ),
                ],
              if (widget.showProfileButton && isLoggedIn) ...[
                SizedBox(width: isMobile ? 0 : 10),
                IconButton(
                  visualDensity:
                      isMobile ? VisualDensity.compact : VisualDensity.standard,
                  padding: EdgeInsets.all(isMobile ? 4 : 8),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.account_circle,
                    color: Colors.white70,
                    size: isMobile ? 24 : 35, 
                  ),
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
                SizedBox(width: isMobile ? 0 : 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
