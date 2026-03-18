import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false; 

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4), 
      ),
    );
  }

  Future<void> resetPassword() async {
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      _showError('Ingresa tu correo institucional.');
      return;
    }

    if (!email.endsWith('@correo.unimet.edu.ve') && !email.endsWith('@unimet.edu.ve')) {
      _showError('Debes colocar un correo institucional de dominio UNIMET (@correo.unimet.edu.ve o @unimet.edu.ve).');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      _showSuccess('Correo de recuperación enviado. ¡Revisa tu bandeja!');
      
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showError('Error: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error inesperado: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  //Widgets reutilizables

  Widget _buildBackButton() {
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: const Icon(
        Icons.arrow_back_ios_new,
        color: Colors.white,
        size: 20,
      ),
      tooltip: 'Volver',
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿OLVIDASTE LA CONTRASEÑA?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Ingresa tu correo institucional para recibir un enlace de recuperación.',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Correo institucional',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15.0,
              vertical: 15.0,
            ),
          ),
          style: const TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            onPressed: _isLoading ? null : resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
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
    );
  }

  //Layouts (Móvil y Computadora) 

  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBackButton(),
                    const SizedBox(height: 30),
                    Center(
                      child: Image.asset(
                        'assets/images/logo_grande.png',
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildFormContent(),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      '© 2026 MetroSwap - Universidad Metropolitana.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF333333),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: SafeArea(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: _buildBackButton(),
                    ),
                  ),
                  Center(
                    child: _buildFormContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFFE5E5E5),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
            child: Column(
              children: [
                const Spacer(),
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/logo_grande.png',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: isMobile ? const Color(0xFF333333) : Colors.white,
      body: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(),
    );
  }
}
