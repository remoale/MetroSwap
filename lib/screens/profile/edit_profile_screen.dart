import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/profile_controller.dart'; 
import '../../models/user_model.dart'; 
import '../../widgets/profile_avatar.dart'; 
import '../../widgets/primary_button.dart';

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

  @override
  void initState() {
    super.initState();
    editableUser = widget.user.clone(); //Aquí se usa el PROTOTYPE
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => newImage = File(picked.path));
    }
  }

  Future<void> save() async {
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
      body: Padding(
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
            TextField( 
              decoration: const InputDecoration(labelText: "Nombre"),
              onChanged: (value) => editableUser.name = value,
              controller: TextEditingController(text: editableUser.name),
            ),
            const SizedBox(height: 20),
            PrimaryButton(text: "Guardar Cambios", onPressed: save),
          ],
        ),
      ),
    );
  }
}
