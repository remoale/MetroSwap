import 'dart:io';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ProfileController {
  final _firestore = FirestoreService();
  final _storage = StorageService();

  Future<UserModel?> loadUser(String uid) async {
    return await _firestore.getUser(uid);
  }

  Future<String?> uploadImage(String uid, File file) async {
    return await _storage.uploadProfileImage(uid, file);
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.updateUser(user.uid, user.toMap());
  }
}