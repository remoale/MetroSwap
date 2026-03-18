import 'package:flutter/material.dart';
import 'package:metroswap/screens/home_screen.dart';
import 'package:metroswap/screens/publish/publish_screen.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_layout.dart'; 
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 750;

    return MetroSwapLayout(
      body: Column(
        children: [
          if (!isMobile)
            const MetroSwapNavbar(developmentNav: true, heading: ""),
            
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/Sucess.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(color: Colors.black.withValues(alpha: 0.6)),
                Center(
                  child: SingleChildScrollView( 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline, 
                          color: Colors.green, 
                          size: isMobile ? 80 : 100, 
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Publicación Exitosa",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 26 : 32, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 50),

                        isMobile
                            ? Column( 
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildOption(context, "Seguir publicando", () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (_) => const PublishScreen()),
                                      (route) => route.isFirst,
                                    );
                                  }),
                                  const SizedBox(height: 30),
                                  _buildOption(context, "Volver al inicio", () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                                      (route) => false,
                                    );
                                  }),
                                ],
                              )
                            : Row( 
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildOption(context, "Seguir publicando", () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (_) => const PublishScreen()),
                                      (route) => route.isFirst,
                                    );
                                  }),
                                  const SizedBox(width: 50),
                                  _buildOption(context, "Volver al inicio", () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                                      (route) => false,
                                    );
                                  }),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const MetroSwapFooter(),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, VoidCallback onTap) {
    return Column(
      children: [
        Text(
          title, 
          style: const TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0XFFFF4500),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: const Text("Ir", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}