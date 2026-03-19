import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metroswap/utils/admin_utils.dart';
import 'package:metroswap/widgets/metroswap_brand.dart';
import 'package:metroswap/widgets/metroswap_drawer.dart';

class MetroSwapLayout extends StatelessWidget {
  final Widget body;
  const MetroSwapLayout({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final email = FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
    final isAdmin = isAdminEmail(email);

    return Scaffold(
      backgroundColor: const Color(0xFFE4E1E6),
      endDrawer: isMobile ? const MetroSwapDrawer() : null, 
      
      appBar: isMobile
          ? AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 70,
              backgroundColor: isAdmin
                  ? const Color(0xFFC93C20)
                  : const Color(0xFF2C2C2C),
              title: const MetroSwapBrand(),
              actions: [
                if (isAdmin)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Builder(
                  builder: (context) {
                    return IconButton(
                      padding: const EdgeInsets.only(right: 20),
                      icon: const Icon(Icons.menu, color: Color(0xFFFF6B00), size: 40), 
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer(); 
                      },
                    );
                  },
                )
              ],
            )
          : null,
      body: body, 
    );
  }
}
