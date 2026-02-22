import 'package:flutter/material.dart';
import 'package:metroswap/screens/landing_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
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
        // Tema base de la aplicacion.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B00)), 
        useMaterial3: true,
      ),
      // Pantalla inicial.
      home: const LandingPage(), 
    );
  }
}
