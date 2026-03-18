import 'package:flutter/material.dart';
import 'package:metroswap/widgets/metroswap_brand.dart';
import 'package:metroswap/widgets/metroswap_drawer.dart';

class MetroSwapLayout extends StatelessWidget {
  final Widget body;
  const MetroSwapLayout({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFE4E1E6),
      endDrawer: isMobile ? const MetroSwapDrawer() : null, 
      
      appBar: isMobile
          ? AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 70,
              backgroundColor: const Color(0xFF2C2C2C),
              title: const MetroSwapBrand(),
              actions: [
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