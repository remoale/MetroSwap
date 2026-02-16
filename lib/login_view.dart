import 'package:flutter/material.dart';

class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // --- LADO IZQUIERDO: FORMULARIO (Gris Oscuro) ---
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF333333), // El gris oscuro de tu Figma
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BIENVENIDO A METROSWAP',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Aquí irán los campos de texto en el siguiente commit
                  const Text('Formulario en proceso...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          // --- LADO DERECHO: LOGO GRANDE (Gris Clarito) ---
          Expanded(
            flex: 3, // Es más ancho que el lado del login
            child: Container(
              color: const Color(0xFFE5E5E5), // Gris muy claro
              child: Center(
                child: Image.asset(
                  'assets/images/logo_metroswap.png',
                  width: 400, // Logo bien grande como en tu diseño
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}