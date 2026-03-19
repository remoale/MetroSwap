import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/profile_controller.dart'; 
import '../../models/user_model.dart'; 
import '../../widgets/profile_avatar.dart'; 
import '../../widgets/metroswap_layout.dart'; 

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const List<String> _unimetCareers = [
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

  final controller = ProfileController();
  final picker = ImagePicker();
  bool _isSaving = false;

  late UserModel editableUser;
  XFile? newImage;
  Uint8List? newImageBytes;

  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController careerCtrl;
  late TextEditingController studentIdCtrl;
  late TextEditingController booksCtrl;
  String? selectedCareer;

  @override
  void initState() {
    super.initState();
    editableUser = widget.user.clone(); 

    nameCtrl = TextEditingController(text: editableUser.name); 
    phoneCtrl = TextEditingController(text: editableUser.phone ?? ""); 
    careerCtrl = TextEditingController(text: editableUser.career ?? ""); 
    studentIdCtrl = TextEditingController(
      text: _fallbackStudentId(editableUser.studentId, editableUser.uid),
    );
    booksCtrl = TextEditingController( 
      text: editableUser.books?.join(", ") ?? "",
    );
    if (_isStudentRole(editableUser.role)) {
      final currentCareer = editableUser.career?.trim();
      if (currentCareer != null && _unimetCareers.contains(currentCareer)) {
        selectedCareer = currentCareer;
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    careerCtrl.dispose();
    studentIdCtrl.dispose();
    booksCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        newImage = picked;
        newImageBytes = bytes;
      });
    }
  }

  Future<void> save() async {
    final nombre = nameCtrl.text.trim();
    final formatoNombre = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ]+(\s+[a-zA-ZáéíóúÁÉÍÓÚñÑ]+)+$');
    
    if (!formatoNombre.hasMatch(nombre)) {
      _showError("Debe ingresar al menos nombre y apellido, sin números.");
      return; 
    }

    final telefono = phoneCtrl.text.trim();
    final formatoTelefono = RegExp(r'^[0-9]{10,12}$'); 
    
    if (!formatoTelefono.hasMatch(telefono)) {
      _showError("Ingrese un teléfono válido (10 o 12 dígitos).");
      return;
    }

    final studentId = studentIdCtrl.text.trim();
    final studentIdPattern = RegExp(r'^[0-9]{6,15}$');
    
    if (studentId.isEmpty || !studentIdPattern.hasMatch(studentId)) {
      _showError("Ingrese un Student ID válido (6-15 dígitos).");
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    editableUser.name = nameCtrl.text; 
    editableUser.phone = phoneCtrl.text; 
    editableUser.career = _resolveCareerForRole(
      editableUser.role,
      selectedCareer: selectedCareer,
      fallbackCareer: careerCtrl.text,
    );
    editableUser.studentId = _normalizeOptional(studentIdCtrl.text);
    
    editableUser.books = booksCtrl.text 
    .split(",") 
    .map((e) => e.trim()) 
    .where((e) => e.isNotEmpty) 
    .toList();
    
    if (newImage != null) {
      final uploadedUrl = await controller.uploadImage(editableUser.uid, newImage!);
      if (uploadedUrl == null) {
        if (!mounted) return;
        _showError('No se pudo subir la foto de perfil.');
        setState(() => _isSaving = false);
        return;
      }
      editableUser.photoUrl = uploadedUrl;
      try {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(uploadedUrl);
      } catch (_) {}
    }

    await controller.updateUser(editableUser);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Forzamos reputación a double para evitar errores de tipo int/double
    final double currentReputation = (editableUser.reputation).toDouble();

    return MetroSwapLayout(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 700;
          final isCompact = constraints.maxWidth < 760;

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 0 : 24,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ProfileAvatar(
                            imageUrl: editableUser.photoUrl,
                            localImageBytes: newImageBytes,
                            size: 38,
                            onTap: pickImage,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: nameCtrl,
                                  style: const TextStyle(
                                    color: Color(0xFF54515A),
                                    fontSize: 22,
                                  ),
                                  decoration: _fieldDecoration("Nombre de usuario"),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      currentReputation.toStringAsFixed(1), 
                                      style: const TextStyle(
                                        fontSize: 20, 
                                        fontWeight: FontWeight.bold, 
                                        color: Color(0xFFFF9800)
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Row(
                                      children: List.generate(5, (index) {
                                        if (index < currentReputation.floor()) {
                                          return const Icon(Icons.star, color: Colors.amber, size: 22);
                                        } else if (index < currentReputation) {
                                          return const Icon(Icons.star_half, color: Colors.amber, size: 22);
                                        } else {
                                          return const Icon(Icons.star_border, color: Colors.amber, size: 22);
                                        }
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${editableUser.tradesCount} calificaciones)', 
                                      style: const TextStyle(
                                        fontSize: 14, 
                                        fontWeight: FontWeight.w500, 
                                        color: Colors.grey
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF5A5860),
                            width: 3,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 16 : 28, 
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Información del usuario",
                              style: TextStyle(
                                color: Color(0xFF6A6770),
                                fontSize: 26,
                              ),
                            ),
                            const SizedBox(height: 18),
                            isCompact
                                ? Column(
                                    children: [
                                      _buildLeftFields(),
                                      const SizedBox(height: 18),
                                      _buildRightFields(),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildLeftFields()),
                                      const SizedBox(width: 30),
                                      Expanded(child: _buildRightFields()),
                                    ],
                                  ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 190,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5C00),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text("Guardar cambios"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel("Nombre:"),
        _buildEditableField(
          controller: nameCtrl,
          hintText: "Nombre...",
        ),
        const SizedBox(height: 16),
        _buildFieldLabel("Carrera:"),
        _buildCareerField(),
        const SizedBox(height: 16),
        _buildFieldLabel("Carnet:"),
        _buildEditableField(
          controller: studentIdCtrl,
          hintText: "20261234567",
        ),
      ],
    );
  }

  Widget _buildRightFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel("Correo Unimet:"),
        _buildReadOnlyField(editableUser.email),
        const SizedBox(height: 16),
        _buildFieldLabel("Número de teléfono:"),
        _buildEditableField(
          controller: phoneCtrl,
          hintText: "Ejemplo: 04121234567",
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildFieldLabel("Materiales:"),
        _buildReadOnlyField(booksCtrl.text.isEmpty ? "Ninguno" : booksCtrl.text),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF595660),
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _fieldDecoration(hintText),
    );
  }

  Widget _buildCareerField() {
    if (_isStudentRole(editableUser.role)) {
      return DropdownButtonFormField<String>(
        initialValue: selectedCareer,
        isExpanded: true,
        decoration: _fieldDecoration("Selecciona tu carrera"),
        items: _unimetCareers
            .map(
              (career) => DropdownMenuItem<String>(
                value: career,
                child: Text(
                  career,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedCareer = value;
          });
        },
      );
    }

    return _buildReadOnlyField(editableUser.career?.trim().isNotEmpty == true
        ? editableUser.career!
        : "No especificada");
  }

  Widget _buildReadOnlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: const TextStyle(color: Color(0xFF6C6872), fontSize: 16),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF8C8892)),
      filled: true,
      fillColor: const Color(0xFFF4F4F4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF5C00), width: 1.4),
      ),
    );
  }

  String _buildDefaultStudentId(String uid) {
    return uid.length <= 8 ? uid.toUpperCase() : uid.substring(0, 8).toUpperCase();
  }

  String _fallbackStudentId(String? studentId, String uid) {
    final normalized = _normalizeOptional(studentId);
    return normalized ?? _buildDefaultStudentId(uid);
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }

  bool _isStudentRole(String? role) {
    return role?.trim().toLowerCase() == UserModel.roleStudent;
  }

  String? _resolveCareerForRole(
    String? role, {
    String? selectedCareer,
    String? fallbackCareer,
  }) {
    final normalizedRole = role?.trim().toLowerCase();
    if (normalizedRole == UserModel.roleAdmin) return 'Administrador';
    if (normalizedRole == UserModel.roleProfessor) return 'Profesor';
    if (normalizedRole == UserModel.roleStudent) return selectedCareer;
    final normalizedCareer = fallbackCareer?.trim();
    return (normalizedCareer == null || normalizedCareer.isEmpty) ? null : normalizedCareer;
  }
}
