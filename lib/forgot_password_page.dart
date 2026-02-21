import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  Future<void> resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correo de recuperación enviado. ¡Revisa tu bandeja!'),
            backgroundColor: Colors.green,
          ),
        );
        // Opcional: Regresar al login después de unos segundos
        // Future.delayed(const Duration(seconds: 2), () => Navigator.of(context).pop());
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos un Row para dividir la pantalla en dos columnas
      body: Row(
        children: [
          // --- COLUMNA IZQUIERDA (Formulario) ---
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF333333), // Fondo oscuro
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón para regresar
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox(height: 20),
                  
                  // Título
                  const Text(
                    '¿OLVIDASTE LA CONTRASEÑA?',
                    style: TextStyle(
                      color: Colors.white, // Texto blanco
                      fontSize: 16, // Un poco más grande
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Texto explicativo (opcional, pero ayuda)
                  const Text(
                    'Ingresa tu correo institucional para recibir un enlace de recuperación.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 30),

                  // Campo de texto (InputDecoration decorador)
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Correo institucional',
                      filled: true,
                      fillColor: Colors.white, // Fondo blanco para el input
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15.0,
                        vertical: 15.0,
                      ),
                    ),
                    style: const TextStyle(color: Colors.black), // Texto negro al escribir
                  ),
                  const SizedBox(height: 25),

                  // Botón de "Enviar correo"
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00), // Naranja
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Enviar correo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- COLUMNA DERECHA (Logo grande) ---
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFFE5E5E5), // Fondo gris claro
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
              child: Column(
                children: [
                  const Spacer(),
                  // Logo grande centrado
                  Expanded(
                    flex: 6,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/logo_grande.png', // Asegúrate que esta ruta sea correcta
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Pie de página
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