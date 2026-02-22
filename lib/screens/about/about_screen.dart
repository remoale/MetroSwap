import 'package:flutter/material.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E1E6),
      body: Column(
        children: [
          const MetroSwapNavbar(developmentNav: true, heading: 'Conócenos'),
          const Expanded(
            child: Center(
              child: Text(
                'En desarrollo',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          const MetroSwapFooter(),
        ],
      ),
    );
  }
}

