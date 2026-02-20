import 'package:flutter/material.dart';
import 'landing_page.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
