import 'package:flutter/material.dart';

class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // --- LADO IZQUIERDO: FORMULARIO ---
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF333333),
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BIENVENIDO A METROSWAP',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Correo institucional',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('¿OLVIDASTE LA CONTRASEÑA?', style: TextStyle(color: Colors.white60, fontSize: 10)),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Center(child: Text('o', style: TextStyle(color: Colors.white60, fontSize: 14))),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Registrarse', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
                      label: const Text('Continuar con Google', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(backgroundColor: Colors.blue.shade700, side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // --- LADO DERECHO: LOGO GIGANTE Y FOOTER ---
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFFE5E5E5),
              // REDUJIMOS EL PADDING HORIZONTAL DE 50 A 20 PARA DARLE MÁS ESPACIO AL LOGO
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
              child: Column(
                children: [
                  const Spacer(),
                  
                  // --- AQUÍ EL LOGO CRECERÁ LIBREMENTE ---
                  Expanded(
                    flex: 6,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/logo_grande.png',
                        // QUITAMOS EL 'width: 500' PARA QUE NO TENGA LÍMITE FIJO
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      '© 2026 MetroSwap - Universidad Metropolitana.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}