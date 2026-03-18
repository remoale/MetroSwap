import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'storage_service.dart';
import '../utils/admin_utils.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  String _resolveRoleFromEmail(String? email) {
    final normalized = email?.trim().toLowerCase() ?? '';
    if (isAdminEmail(normalized)) {
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
    final userRef = _firestore.collection('users').doc(user.uid);
    final existingSnapshot = await userRef.get();
    final role = _resolveRoleFromEmail(user.email);
    final roleCareer = _resolveCareerForRole(role);
    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    if (!existingSnapshot.exists) {
      data['role'] = role;
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    if (!existingSnapshot.exists && roleCareer != null) {
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

    await userRef.set(data, SetOptions(merge: true));
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
