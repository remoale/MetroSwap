import 'package:flutter/material.dart';
import 'package:metroswap/views/register_view.dart';
import 'auth_service.dart';
import 'landing_page.dart';
import 'forgot_password_page.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Lado izquierdo del formulario
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
                    onPressed: () {
                      // Navegamos a la nueva pantalla (Añadiendo una hoja al patrón Composite)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage(),
                        ),
                      );
                    },
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
                      onPressed: () {Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const RegisterView()),
  );
},
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Registrarse', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton.icon(
                      onPressed: () async
                      {
                        final authService = AuthService();
                        try {
                          final user = await authService.signInWithGoogle();
                          if (user != null && context.mounted) 
                          {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LandingPage()), /// AQUI DEBE IR EL HOMEPAGE PERO POR AHORA ESTA ASI DE PRUEBA
                              );
                          }
                        } catch (e) {
                            if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),
                                ),
                                backgroundColor: Colors.red.shade700, 
                                action: SnackBarAction(
                                  label: 'OK',
                                  textColor: Colors.white,
                                  onPressed: () {}, // Permite al usuario cerrarlo manualmente
                                )
                              )
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
                      label: const Text('Continuar con Google', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(backgroundColor: Colors.blue.shade700, side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Lado derecho: Logo grande y pie de pagina
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFFE5E5E5),
              // Reduje el paddin horizontal de 50 a 20 para darle más espacio al logo
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
              child: Column(
                children: [
                  const Spacer(),
                  
                  // Aqui el logo crecera libremente 
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
