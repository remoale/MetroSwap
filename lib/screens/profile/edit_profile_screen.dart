import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/profile_controller.dart'; 
import '../../models/user_model.dart'; 
import '../../widgets/profile_avatar.dart'; 
import '../../widgets/primary_button.dart';
import '../../widgets/custom_textfield.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final controller = ProfileController();
  final picker = ImagePicker();

  late UserModel editableUser;
  File? newImage;

  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController careerCtrl;
  late TextEditingController booksCtrl;

  @override
  void initState() {
    super.initState();
    editableUser = widget.user.clone(); //Aquí se usa el PROTOTYPE

    nameCtrl = TextEditingController(text: editableUser.name); 
    phoneCtrl = TextEditingController(text: editableUser.phone ?? ""); 
    careerCtrl = TextEditingController(text: editableUser.career ?? ""); 
    booksCtrl = TextEditingController( 
      text: editableUser.books?.join(", ") ?? "",
    );
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => newImage = File(picked.path));
    }
  }

  Future<void> save() async {
    editableUser.name = nameCtrl.text; 
    editableUser.phone = phoneCtrl.text; 
    editableUser.career = careerCtrl.text; 
    
    // Convertir libros separados por coma a lista 
    editableUser.books = booksCtrl.text 
    .split(",") 
    .map((e) => e.trim()) 
    .where((e) => e.isNotEmpty) 
    .toList();
    
    if (newImage != null) {
      editableUser.photoUrl = await controller.uploadImage(editableUser.uid, newImage!);
    }

    await controller.updateUser(editableUser);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ProfileAvatar(
              imageUrl: editableUser.photoUrl,
              localImage: newImage,
              size: 70,
              onTap: pickImage,
            ),
            const SizedBox(height: 20),
            
            CustomTextField(controller: nameCtrl, label: "Nombre"),
            const SizedBox(height: 15),

            CustomTextField(
              controller: phoneCtrl, 
              label: "Teléfono",
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            
            CustomTextField(controller: careerCtrl, label: "Carrera"),
            const SizedBox(height: 15),

            CustomTextField(
              controller: booksCtrl, 
              label: "Libros (separados por coma)",
            ),
            const SizedBox(height: 25),

            PrimaryButton(text: "Guardar Cambios", onPressed: save),
          ],
        ),
      ),
    );
  }
}
