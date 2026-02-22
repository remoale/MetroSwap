import 'package:flutter/material.dart';
import 'package:metroswap/screens/landing_page.dart';
import 'package:metroswap/services/auth_service.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _carnetController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _carnetController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final correo = _correoController.text.trim();
    final password = _passwordController.text;

    if (nombre.isEmpty || apellido.isEmpty || correo.isEmpty || password.isEmpty) {
      _showError('Completa todos los campos obligatorios.');
      return;
    }

    if (password.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    if (!_authService.isInstitutionalEmail(correo)) {
      _showError('Usa un correo institucional UNIMET.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.registerWithEmailAndPassword(
        email: correo,
        password: password,
        displayName: '$nombre $apellido',
      );
      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: const Color.fromARGB(255, 244, 88, 41),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Únete a MetroSwap',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Regístrate con tu correo UNIMET para intercambiar material.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _crearCampoTexto('Nombre', 'Ej: Juan', _nombreController, false),
              _crearCampoTexto('Apellido', 'Ej: Pérez', _apellidoController, false),
              _crearCampoTexto('Carnet', 'Ej: 202112345', _carnetController, false),
              _crearCampoTexto('Teléfono', 'Ej: 0414-1234567', _telefonoController, false),
              _crearCampoTexto(
                'Correo Institucional',
                'Ej: jperez@correo.unimet.edu.ve',
                _correoController,
                false,
              ),
              _crearCampoTexto(
                'Contraseña',
                'Mínimo 6 caracteres',
                _passwordController,
                true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Registrarse',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _crearCampoTexto(
    String titulo,
    String pista,
    TextEditingController controlador,
    bool esPassword,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controlador,
        obscureText: esPassword,
        decoration: InputDecoration(
          labelText: titulo,
          hintText: pista,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}
