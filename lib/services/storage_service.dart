import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfileImage(String uid, File file) async {
    try {
      // Crea una ruta en la nube para la foto
      Reference ref = _storage.ref().child('profiles').child('$uid.jpg');
      
      // Sube el archivo
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      
      // Devuelve la URL de la foto para guardarla en el perfil
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }
}