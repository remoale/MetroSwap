import 'dart:io';
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

  Future<UserModel?> loadUser(String uid) async {
    final user = await _firestore.getUser(uid);
    return user?.clone(); // Devuelve una copia para evitar mutaciones directas 
  }

  Future<String?> uploadImage(String uid, File file) async {
    return await _storage.uploadProfileImage(uid, file);
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.updateUser(user.uid, user.toMap());
  }
}