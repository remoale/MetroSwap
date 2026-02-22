import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  Future<void> upsertUserProfile(User user) async {
    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    // No sobrescribir datos de perfil con null en inicios de sesion por email.
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      data['name'] = user.displayName;
      data['displayName'] = user.displayName;
    }
    if (user.photoURL != null && user.photoURL!.trim().isNotEmpty) {
      final photoFromStorage = await _storage.ensureProfileImageFromRemoteUrlIfMissing(
        uid: user.uid,
        remoteUrl: user.photoURL!,
      );
      data['photoUrl'] = photoFromStorage ?? user.photoURL;
    } else {
      final photoFromStorage = await _storage.getProfileImageDownloadUrl(user.uid);
      if (photoFromStorage != null) {
        data['photoUrl'] = photoFromStorage;
      }
    }

    await _firestore.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      if (!snapshot.exists) return null;
      return UserModel.fromMap(snapshot.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }
}
