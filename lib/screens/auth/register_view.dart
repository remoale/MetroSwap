import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metroswap/screens/home_page.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Controladores para capturar la información
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();
  final TextEditingController _carnetController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Estado de carga para el botón
  bool _isLoading = false;

  // Paleta de colores basada en tu diseño
  final Color naranjaM = const Color(0xFFFF6B00);
  final Color grisOscuroHeader = const Color(0xFF2E2E2E);
  final Color grisFondoPajina = const Color(0xFFD1CED6);
  final Color cuadroGrisFormulario = const Color(0xFF333333);

  // --- FUNCIÓN PARA MOSTRAR ERRORES ---
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // --- LÓGICA DE VALIDACIÓN Y REGISTRO EN FIREBASE ---
  Future<void> _validarYRegistrar() async {
    final nombre = _nombreController.text.trim();
    final carrera = _carreraController.text.trim();
    final carnet = _carnetController.text.trim();
    final telefono = _telefonoController.text.trim();
    final correo = _correoController.text.trim();
    final password = _passwordController.text;

    // 1. Validaciones locales
    if (nombre.isEmpty || carrera.isEmpty || carnet.isEmpty || telefono.isEmpty || correo.isEmpty || password.isEmpty) {
      _showError("Por favor, llena todos los campos.");
      return;
    }

    if (!correo.endsWith("@correo.unimet.edu.ve") && !correo.endsWith("@unimet.edu.ve")) {
      _showError("Solo se permiten correos institucionales UNIMET.");
      return;
    }

    if (password.length < 8) {
      _showError("La contraseña debe tener al menos 8 caracteres.");
      return;
    }

    final esSoloNumeros = RegExp(r'^[0-9]+$');
    if (!esSoloNumeros.hasMatch(carnet) || !esSoloNumeros.hasMatch(telefono)) {
      _showError("El carnet y teléfono deben contener solo números, sin puntos ni guiones.");
      return;
    }

    // 2. Intentar registrar en Firebase
    setState(() {
      _isLoading = true; // Activa el circulito de carga
    });

    try {
      // Crea el usuario en Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correo,
        password: password,
      );

      // Guarda los datos extra en la base de datos de Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'displayName': nombre, 
        'email': correo,       
        'studentId': carnet,   
        'phone': telefono,     
        'career': carrera,
        'photoUrl': '',       
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user!.uid,
      });

      debugPrint("Usuario creado exitosamente: ${userCredential.user!.uid}");

      // Navegar al HomePage y evitar que regrese a esta pantalla
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // 3. Manejo de errores de Authentication
      if (e.code == 'email-already-in-use') {
        _showError("Ya existe una cuenta registrada con este correo.");
      } else if (e.code == 'invalid-email') {
        _showError("El formato del correo no es válido.");
      } else if (e.code == 'weak-password') {
        _showError("La contraseña es muy débil.");
      } else {
        _showError("Error de registro: ${e.message}");
      }
    } catch (e) {
      // Manejo de errores de Firestore (como el permission-denied)
      _showError("Ocurrió un error inesperado: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Detiene la animación cargue bien o mal
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grisFondoPajina,
      body: Column(
        children: [
          // --- HEADER CON BOTÓN CENTRADO ---
          Container(
            color: grisOscuroHeader,
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                        Image.asset(
                        "assets/images/logo_metroswap.png", 
                        height: 60, 
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10), 
                      const Text(
                        "MetroSwap",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 24),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  decoration: BoxDecoration(
                    color: naranjaM,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Crea tu cuenta",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),

          // --- CUERPO DEL REGISTRO ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 40),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna Izquierda
                      Expanded(
                        child: _buildFormCard([
                          _buildInputField("Nombre completo:", _nombreController, false),
                          _buildInputField("Carrera:", _carreraController, false),
                          _buildInputField("Teléfono:", _telefonoController, false, esNumero: true),
                        ]),
                      ),
                      const SizedBox(width: 40),
                      // Columna Derecha
                      Expanded(
                        child: _buildFormCard([
                          _buildInputField("Correo Unimet:", _correoController, false),
                          _buildInputField("Contraseña:", _passwordController, true),
                          _buildInputField("Carnet:", _carnetController, false, esNumero: true),
                        ]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // BOTÓN REGISTRARSE DINÁMICO
                  SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validarYRegistrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: naranjaM,
                        padding: const EdgeInsets.symmetric(horizontal: 100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Registrarse",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- PIE DE PÁGINA ---
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
    );
  }

  // WIDGETS REUTILIZABLES
  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: cuadroGrisFormulario,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool isPassword, {bool esNumero = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: esNumero ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Insertar",
              hintStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: naranjaM,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}