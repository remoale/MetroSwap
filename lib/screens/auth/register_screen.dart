import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metroswap/screens/home_screen.dart';
import 'package:metroswap/utils/admin_utils.dart';
import 'package:metroswap/widgets/metroswap_brand.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final List<String> _carrerasUnimet =[
    'Profesor',
    'Ciencias Administrativas',
    'Comunicación Social y Empresarial',
    'Contaduría Pública',
    'Derecho',
    'Economía Empresarial',
    'Educación',
    'Estudios Internacionales',
    'Estudios Liberales',
    'Estudios simultáneos',
    'Idiomas Modernos',
    'Ingeniería Civil',
    'Ingeniería de Sistemas',
    'Ingeniería Eléctrica',
    'Ingeniería Mecánica',
    'Ingeniería Producción',
    'Ingeniería Química',
    'Matemáticas Industriales',
    'Psicología',
    'TSU en Desarrollo de Sistemas Inteligentes',
    'Turismo Sostenible',  
  ];
  String? _carreraSeleccionada;
  bool _isLoading = false;
  bool _obscurePassword = true; 

  final Color naranjaM = const Color(0xFFFF6B00);
  final Color grisOscuroHeader = const Color(0xFF2E2E2E);
  final Color grisFondoPajina = const Color(0xFFD1CED6);
  final Color cuadroGrisFormulario = const Color(0xFF333333);

  @override 
  void dispose(){
    _nombreController.dispose();
    _studentIdController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _resolveRoleFromEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (isAdminEmail(normalized)) {
      return 'admin';
    }
    if (normalized.endsWith('@unimet.edu.ve')) {
      return 'profesor';
    }
    return 'estudiante';
  }

  String _resolveCareerForRole(String role) {
    if (role == 'admin') return 'Administrador';
    if (role == 'profesor') return 'Profesor';
    return _carreraSeleccionada ?? "";
  }

  Future<void> _validarYRegistrar() async {
    final nombre = _nombreController.text.trim();
    final studentId = _studentIdController.text.trim();
    final telefono = _telefonoController.text.trim();
    final correo = _correoController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final role = _resolveRoleFromEmail(correo);
    final carrera  = _resolveCareerForRole(role);

    if (nombre.isEmpty || studentId.isEmpty || telefono.isEmpty || correo.isEmpty || password.isEmpty) {
      _showError("Por favor, llena todos los campos.");
      return;
    }

    final formatoNombre = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ]+(\s+[a-zA-ZáéíóúÁÉÍÓÚñÑ]+)+$');
    if (!formatoNombre.hasMatch(nombre)) {
      _showError("Debe ingresar al menos nombre y apellido, sin dígitos numéricos.");
      return;
    }

    if (role == 'estudiante' && carrera.isEmpty) {
      _showError("Debe seleccionar una carrera.");
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

    final studentIdPattern = RegExp(r'^\d{6,15}$');
    if (!studentIdPattern.hasMatch(studentId)) {
      _showError("El Student ID debe tener entre 6 y 15 dígitos numéricos.");
      return;
    }

    final esSoloNumeros = RegExp(r'^[0-9]{10,12}$');
    if (!esSoloNumeros.hasMatch(telefono)) {
      _showError("El teléfono debe contener 10 o 12 números, sin puntos ni guiones.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correo,
        password: password,
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': nombre, 
        'email': correo,       
        'studentId': studentId,
        'phone': telefono,     
        'career': carrera,
        'role': role,
        'photoUrl': '',       
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user!.uid,
      });

      debugPrint("Usuario creado exitosamente: ${userCredential.user!.uid}");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
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
      _showError("Ocurrió un error inesperado: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final columnaIzquierda = [
      _buildInputField("Nombre completo:", _nombreController, false),
      _buildDropdownField("Carrera:"),
      _buildInputField("Teléfono:", _telefonoController, false, esNumero: true),
    ];

    final columnaDerecha = [
      _buildInputField("Correo Unimet:", _correoController, false),
      _buildPasswordField("Contraseña:", _passwordController),
      _buildInputField("Student ID:", _studentIdController, false, esNumero: true),
    ];

    return Scaffold(
      backgroundColor: grisFondoPajina,
      body: Column(
        children: [
          Container(
            color: grisOscuroHeader,
            height: isMobile ? 70 : 85, 
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 24),
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
                      if (!isMobile) const MetroSwapBrand(),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Crea tu cuenta",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 18 : 22, 
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: isMobile ? 80 : 110,
                      height: 3,
                      decoration: BoxDecoration(
                        color: naranjaM,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20.0 : 60.0, 
                vertical: isMobile ? 20.0 : 40.0,
              ),
              child: Column(
                children: [
                  if (isMobile) ...[
                    _buildFormCard(columnaIzquierda, isMobile: true),
                    const SizedBox(height: 20),
                    _buildFormCard(columnaDerecha, isMobile: true),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFormCard(columnaIzquierda)),
                        const SizedBox(width: 40),
                        Expanded(child: _buildFormCard(columnaDerecha)),
                      ],
                    ),
                  ],

                  SizedBox(height: isMobile ? 30 : 50),

                  SizedBox(
                    height: 60,
                    width: isMobile ? double.infinity : null, 
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validarYRegistrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: naranjaM,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Registrarse",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
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

  Widget _buildDropdownField(String label){
    return Padding (
      padding: const EdgeInsets.only(bottom : 25.0),
      child : Column (
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text (label,style: const TextStyle(color: Colors.white,fontSize: 16)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isExpanded: true, 
            initialValue : _carreraSeleccionada,
            dropdownColor : const Color(0xFF444444),
            style: const TextStyle(color:Colors.white,fontSize: 16),
            decoration :InputDecoration(
              filled:true,
              fillColor: naranjaM,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15,vertical: 15),
              border: OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide: BorderSide.none ),
            ),
            hint :const Text("Seleccionar carrera", style: TextStyle(color: Colors.white60)),
            icon : const Icon (Icons.arrow_drop_down,color :Colors.white),
            items:  _carrerasUnimet.map((c)=> DropdownMenuItem(value: c , child :Text(c))).toList(),
            onChanged : (val)=> setState(()=> _carreraSeleccionada= val),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 25 : 35), 
      decoration: BoxDecoration(
        color: cuadroGrisFormulario,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2), 
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

  Widget _buildPasswordField(String label, TextEditingController controller) {
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
            obscureText: _obscurePassword, 
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Mínimo 8 caracteres", 
              hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
              filled: true,
              fillColor: naranjaM,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword; 
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
