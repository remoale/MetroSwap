import 'package:flutter/material.dart';
import 'landing_page.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MetroSwap', 
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        // Le di los colores base de la app
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B00)), 
        useMaterial3: true,
      ),
      // Pantalla de inicio es la LandingPage
      home: const LandingPage(), 
    );
  }
}
