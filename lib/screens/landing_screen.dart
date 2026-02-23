import 'package:flutter/material.dart';
import 'package:metroswap/screens/about/about_screen.dart';
import 'package:metroswap/screens/auth/login_screen.dart';
import 'package:metroswap/widgets/metroswap_brand.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 85, 
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        backgroundColor: const Color(0xFF2C2C2C),
        title: const MetroSwapBrand(),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              side: const BorderSide(color: Colors.white),
              foregroundColor: Colors.white,
            ),
            child: const Text('Conócenos', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 15),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder : (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Acceder', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 30),
        ],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Banner principal
                    Container(
                      height: 350,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/fondo_estudiantes.jpg'),
                          fit: BoxFit.cover,
                          alignment: Alignment.center, 
                        ),
                      ),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Center(
                          child: Text(
                            'Bienvenido a MetroSwap',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 55,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Seccion de informacion.
                    Expanded(
                      child: Container(
                        alignment: Alignment.center, 
                        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                        child: Wrap(
                          spacing: 80, 
                          runSpacing: 60, 
                          alignment: WrapAlignment.center,
                          children: [
                            _buildInfoColumn(
                              title: 'Misión',
                              text: 'Desarrollar una plataforma web y móvil centralizada para que estudiantes y docentes publiquen, busquen y gestionen el intercambio o venta de libros y guías de forma eficiente.',
                            ),
                            _buildInfoColumn(
                              title: 'Visión',
                              text: 'Crear un ecosistema colaborativo en la Universidad Metropolitana que facilite el acceso a materiales educativos, asegurando que cada recurso sea rastreable desde su publicación hasta su entrega.',
                            ),
                            _buildInfoColumn(
                              title: 'Objetivo',
                              text: 'Desarrollar e implementar un sistema completo de gestión para la Universidad Metropolitana que permita a profesores y estudiantes comprar, vender e intercambiar material académico.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Pie de pagina.
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF2C2C2C),
                      padding: const EdgeInsets.all(20),
                      child: const Text(
                        '© 2026 MetroSwap - Universidad Metropolitana.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget auxiliar para bloques informativos.
  Widget _buildInfoColumn({required String title, required String text}) {
    return SizedBox(
      width: 380, 
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 50), 
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 18 
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            text,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 17, 
              height: 1.6, 
            ),
          ),
        ],
      ),
    );
  }
}

