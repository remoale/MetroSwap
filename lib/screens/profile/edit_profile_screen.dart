import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firestore = FirestoreService();
  final _storage = StorageService();
  final _picker = ImagePicker();

  late TextEditingController nameCtrl;
  File? newImage;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.user.name);
  }

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => newImage = File(picked.path));
  }

  Future<void> save() async {
    String? photoUrl = widget.user.photoUrl;

    if (newImage != null) {
      photoUrl = await _storage.uploadProfileImage(widget.user.uid, newImage!);
    }

    await _firestore.updateUser(widget.user.uid, {
      'name': nameCtrl.text,
      'photoUrl': photoUrl,
    });

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
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: newImage != null
                    ? FileImage(newImage!)
                    : widget.user.photoUrl != null
                        ? NetworkImage(widget.user.photoUrl!)
                        : null,
                child: widget.user.photoUrl == null && newImage == null
                    ? const Icon(Icons.camera_alt)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: save, child: const Text("Guardar"))
          ],
        ),
      ),
    );
  }
}
