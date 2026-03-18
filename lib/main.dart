import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metroswap/screens/home_screen.dart';
import 'package:metroswap/screens/landing_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:metroswap/services/presence_service.dart';
import 'firebase_options.dart';
import 'package:metroswap/screens/payments/paypal_return_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _resolveEntryScreen() {
    final path = Uri.base.path;

    if (path == "/paypal-success") {
      return const PayPalReturnScreen(success: true);
    }

    if (path == "/paypal-cancel") {
      return const PayPalReturnScreen(success: false);
    }

    return const PresenceBootstrap(child: AuthGate());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MetroSwap', 
      debugShowCheckedModeBanner: false, 
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B00)), 
        useMaterial3: true,
      ),
      onGenerateRoute: (settings) {
        if (settings.name == "/paypal-success") {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const PayPalReturnScreen(success: true),
          );
        }
        if (settings.name == "/paypal-cancel") {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const PayPalReturnScreen(success: false),
          );
        }
        return null;
      },
      home: _resolveEntryScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen(); 
        }

        return const LandingScreen();
      },
    );
  }
}

class PresenceBootstrap extends StatefulWidget {
  final Widget child;

  const PresenceBootstrap({
    super.key,
    required this.child,
  });

  @override
  State<PresenceBootstrap> createState() => _PresenceBootstrapState();
}

class _PresenceBootstrapState extends State<PresenceBootstrap> {
  @override
  void initState() {
    super.initState();
    PresenceService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
