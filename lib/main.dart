import 'package:flutter/material.dart';
// Importamos tu nueva pantalla. Asegúrate de que el nombre del archivo sea correcto.
import 'landing_page.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MetroSwap', // Cambiamos el nombre de la app
      debugShowCheckedModeBanner: false, // Quitamos la etiqueta de "DEBUG" de la esquina
      theme: ThemeData(
        // Le damos los colores base de la app
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B00)), 
        useMaterial3: true,
      ),
      // ¡Aquí está la magia! Le decimos que la pantalla de inicio es tu LandingPage
      home: const LandingPage(), 
    );
  }
}
