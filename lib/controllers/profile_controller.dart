import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ProfileController {
  final FirestoreService _firestore;
  final StorageService _storage;

  ProfileController({
    FirestoreService? firestore,
    StorageService? storage,
  }) : _firestore = firestore ?? FirestoreService(), 
  _storage = storage ?? StorageService();

  // Carga los datos del usuario desde Firestore.
  Future<UserModel?> loadUser(String uid) async {
    final user = await _firestore.getUser(uid);
    if (user == null) return null;
    return user.clone(); // Devuelve una copia para evitar modificaciones directas.
  }

  // Sube una imagen de perfil y devuelve su URL.
  Future<String?> uploadImage(String uid, XFile file) async {
    return await _storage.uploadProfileImage(uid, file);
  }

  // Actualiza los datos del usuario en Firestore.
  Future<void> updateUser(UserModel user) async {
    await _firestore.updateUser(user.uid, user.toMap());
  }
}
