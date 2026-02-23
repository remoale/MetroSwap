import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'storage_service.dart';

class FirestoreService {
  static const String _adminEmail = 'administrador.metroswap@correo.unimet.edu.ve';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  String _resolveRoleFromEmail(String? email) {
    final normalized = email?.trim().toLowerCase() ?? '';
    if (normalized == _adminEmail) {
      return 'admin';
    }
    if (normalized.endsWith('@unimet.edu.ve')) {
      return 'profesor';
    }
    return 'estudiante';
  }

  String? _resolveCareerForRole(String role) {
    if (role == 'admin') return 'Administrador';
    if (role == 'profesor') return 'Profesor';
    return null;
  }

  Future<void> upsertUserProfile(User user) async {
    final role = _resolveRoleFromEmail(user.email);
    final roleCareer = _resolveCareerForRole(role);
    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'role': role,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (roleCareer != null) {
      data['career'] = roleCareer;
    }

    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      data['name'] = user.displayName;
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
