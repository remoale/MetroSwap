import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/profile_controller.dart'; 
import '../../models/user_model.dart'; 
import '../../widgets/profile_avatar.dart'; 
import '../landing_page.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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

  @override
  void initState() {
    super.initState();
    editableUser = widget.user.clone(); //Aquí se usa el PROTOTYPE

    nameCtrl = TextEditingController(text: editableUser.name); 
    phoneCtrl = TextEditingController(text: editableUser.phone ?? ""); 
    careerCtrl = TextEditingController(text: editableUser.career ?? ""); 
    studentIdCtrl = TextEditingController(
      text: _fallbackStudentId(editableUser.studentId, editableUser.uid),
    );
    booksCtrl = TextEditingController( 
      text: editableUser.books?.join(", ") ?? "",
    );
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
    if (_isSaving) return;
    setState(() => _isSaving = true);

    editableUser.name = nameCtrl.text; 
    editableUser.phone = phoneCtrl.text; 
    editableUser.career = careerCtrl.text; 
    editableUser.studentId = _normalizeOptional(studentIdCtrl.text);
    
    // Convertir libros separados por coma a lista 
    editableUser.books = booksCtrl.text 
    .split(",") 
    .map((e) => e.trim()) 
    .where((e) => e.isNotEmpty) 
    .toList();
    
    if (newImage != null) {
      final uploadedUrl = await controller.uploadImage(editableUser.uid, newImage!);
      if (uploadedUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo subir la foto de perfil.')),
        );
        setState(() => _isSaving = false);
        return;
      }
      editableUser.photoUrl = uploadedUrl;
    }

    await controller.updateUser(editableUser);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFECEF),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 760;
                  return SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
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
                                    child: TextField(
                                      controller: nameCtrl,
                                      style: const TextStyle(
                                        color: Color(0xFF54515A),
                                        fontSize: 22,
                                      ),
                                      decoration: _fieldDecoration("Nombre de usuario"),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                          backgroundColor:
                                              const Color(0xFFFF5C00),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: _isSaving
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
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
            ),
            Container(
              width: double.infinity,
              color: const Color(0xFF2C2C2C),
              padding: const EdgeInsets.all(20),
              child: const Text(
                "© 2026 MetroSwap - Universidad Metropolitana.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 85,
      color: const Color(0xFF2C2C2C),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Image.asset(
            "assets/images/logo_metroswap.png",
            height: 45,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "MetroSwap",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const LandingPage(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white, width: 1.4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Inicio"),
          ),
        ],
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
        _buildEditableField(
          controller: careerCtrl,
          hintText: "Carrera...",
        ),
        const SizedBox(height: 16),
        _buildFieldLabel("Carnet:"),
        _buildEditableField(
          controller: studentIdCtrl,
          hintText: "Carnet...",
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
          hintText: "Ejemplo de número de teléfono",
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildFieldLabel("Libros:"),
        _buildEditableField(
          controller: booksCtrl,
          hintText: "Separados por coma",
        ),
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
    if (uid.length <= 8) {
      return uid.toUpperCase();
    }
    return uid.substring(0, 8).toUpperCase();
  }

  String _fallbackStudentId(String? studentId, String uid) {
    final normalized = _normalizeOptional(studentId);
    if (normalized == null) {
      return _buildDefaultStudentId(uid);
    }
    return normalized;
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
