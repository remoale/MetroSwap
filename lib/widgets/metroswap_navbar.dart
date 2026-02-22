import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/screens/about/about_screen.dart';
import 'package:metroswap/screens/home_screen.dart';
import 'package:metroswap/screens/notifications/notifications_screen.dart';
import 'package:metroswap/screens/profile/profile_screen.dart';
import 'package:metroswap/screens/publish/publish_screen.dart';
import 'package:metroswap/widgets/metroswap_brand.dart';

class MetroSwapNavbar extends StatelessWidget {
  final bool developmentNav;
  final String? heading;

  const MetroSwapNavbar({
    super.key,
    this.developmentNav = false,
    this.heading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      color: const Color(0xFF333333),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          const MetroSwapBrand(),
          if (heading != null)
            Expanded(
              child: Center(
                child: Text(
                  heading!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (developmentNav) ...[
          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
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
          const SizedBox(width: 20),
        ] else ...[
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PublishScreen(),
                ),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Conócenos'),
          ),
          const SizedBox(width: 25),
        ],
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.white70, size: 35),
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(uid: user.uid),
              ),
            );
          },
        ),
      ],
    );
  }
}
