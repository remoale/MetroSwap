import 'package:flutter/material.dart';
import 'package:metroswap/screens/auth/login_screen.dart';
import 'package:metroswap/screens/about/about_screen.dart'; 
import 'package:metroswap/widgets/metroswap_brand.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Banner principal
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
                color: Colors.orange.withValues(alpha: -8), 
                child: const Center(
                  child: Text(
                    'Bienvenido a MetroSwap',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 55,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(offset: Offset(2.0, 2.0), blurRadius: 5.0, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Sección de Misión, Visión y Objetivo
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
              child: Wrap(
                spacing: 60, 
                runSpacing: 50, 
                alignment: WrapAlignment.center,
                children: [
                  _buildInfoColumn(title: 'Misión', text: 'Desarrollar una plataforma web y móvil centralizada para que estudiantes y docentes publiquen, busquen y gestionen el intercambio o venta de libros y guías de forma eficiente.'),
                  _buildInfoColumn(title: 'Visión', text: 'Crear un ecosistema colaborativo en la Universidad Metropolitana que facilite el acceso a materiales educativos, asegurando que cada recurso sea rastreable.'),
                  _buildInfoColumn(title: 'Objetivo', text: 'Desarrollar e implementar un sistema completo de gestión para la Universidad Metropolitana que permita comprar, vender e intercambiar material académico.'),
                ],
              ),
            ),

            // 3. Sección: ¿Cómo funciona?
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
              child: Column(
                children: [
                  const Text(
                    '¿Cómo funciona MetroSwap?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
                  ),
                  const SizedBox(height: 60),
                  Wrap(
                    spacing: 50,
                    runSpacing: 40,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStepCard(
                        icon: Icons.person_add_alt_1, 
                        title: '1. Regístrate', 
                        description: 'Crea tu cuenta gratis usando tu correo de la universidad.'
                      ),
                      _buildStepCard(
                        icon: Icons.menu_book_rounded, 
                        title: '2. Busca o Publica', 
                        description: 'Encuentra los libros que necesitas o sube el material que ya no usas.'
                      ),
                      _buildStepCard(
                        icon: Icons.handshake_outlined, 
                        title: '3. Intercambia', 
                        description: 'Contacta a otros estudiantes y coordinen la entrega en el campus.'
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4. Pie de pagina
            Container(
              width: double.infinity,
              color: const Color(0xFF2C2C2C),
              padding: const EdgeInsets.all(30),
              child: const Text(
                '© 2026 MetroSwap - Universidad Metropolitana.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn({required String title, required String text}) {
    return SizedBox(
      width: 320, 
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40), 
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(height: 25),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildStepCard({required IconData icon, required String title, required String description}) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: const Color(0xFFFF6B00).withValues(alpha: 0.1),
            child: Icon(icon, size: 45, color: const Color(0xFFFF6B00)),
          ),
          const SizedBox(height: 25),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C))),
          const SizedBox(height: 15),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black54)),
        ],
      ),
    );
  }
}