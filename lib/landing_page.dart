import 'package:flutter/material.dart';
import 'login_view.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Color gris clarito de fondo
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C), // Gris oscuro de tu diseño
        title: Row(
          children: [
            // Colocamos el Logo
            Image.asset(
              'assets/images/logo_metroswap.png',
              height: 40, 
            ),
            const SizedBox(width: 10),
            const Text(
              'MetroSwap',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              foregroundColor: Colors.white,
            ),
            child: const Text('Conócenos'),
          ),
          const SizedBox(width: 15),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder : (context) => const LoginView()),
                );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00), // Naranja Unimet
              foregroundColor: Colors.white,
            ),
            child: const Text('Acceder'),
          ),
          const SizedBox(width: 20), // Espacio al borde derecho
        ],
      ),
      // Usamos SingleChildScrollView para que se pueda scrollear hacia abajo
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner principal
            Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                // Aqui agregamos la foto de los estudiantes
                image: DecorationImage(
                  image: AssetImage('assets/images/fondo_estudiantes.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                // Esto le pone una capa oscura a la foto para que el texto blanco se lea bien
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Text(
                    'Bienvenido a MetroSwap',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Sección de información (misión, visión, objetivo)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              // Wrap hace que si la pantalla es pequeña (teléfono), los cuadros se pongan uno debajo del otro
              child: Wrap(
                spacing: 40, // Espacio horizontal entre columnas
                runSpacing: 40, // Espacio vertical si se colapsan
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

            // Pie de pagina
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
    );
  }

  
  // Hice esta función para no repetir el mismo código 3 veces
  Widget _buildInfoColumn({required String title, required String text}) {
    return SizedBox(
      width: 300, // Ancho fijo para cada columna de texto
      child: Column(
        children: [
          // El "botón" gris oscuro curvo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          // El texto descriptivo
          Text(
            text,
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}