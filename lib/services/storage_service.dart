import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfileImage(String uid, XFile file) async {
    try {
      // Ruta por usuario para aplicar reglas de seguridad por UID
      final ref = _storage.ref().child('profiles').child(uid).child('profile.jpg');
      final metadata = SettableMetadata(contentType: _detectImageMimeType(file.path));
      final bytes = await file.readAsBytes();

      // Subir el archivo y devolver la URL
      final uploadTask = ref.putData(bytes, metadata);
      TaskSnapshot snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<String?> resolveImageUrl(String? rawUrl) async {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final value = rawUrl.trim();
    if (value.startsWith('gs://')) {
      try {
        final ref = _storage.refFromURL(value);
        return await ref.getDownloadURL();
      } catch (_) {
        return null;
      }
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      if (value.contains('firebasestorage.googleapis.com') ||
          value.contains('.firebasestorage.app')) {
        try {
          final ref = _storage.refFromURL(value);
          return await ref.getDownloadURL();
        } catch (_) {
          return value;
        }
      }
      return value;
    }

    return null;
  }

  Future<String?> getProfileImageDownloadUrl(String uid) async {
    try {
      final ref = _storage.ref().child('profiles').child(uid).child('profile.jpg');
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> getProfileImageBytes(String uid, {int maxSizeBytes = 5 * 1024 * 1024}) async {
    try {
      final ref = _storage.ref().child('profiles').child(uid).child('profile.jpg');
      return await ref.getData(maxSizeBytes);
    } on FirebaseException catch (e) {
      debugPrint(
        '[StorageService.getProfileImageBytes] '
        'uid=$uid path=profiles/$uid/profile.jpg code=${e.code} message=${e.message}',
      );
      return null;
    } catch (e) {
      debugPrint(
        '[StorageService.getProfileImageBytes] '
        'uid=$uid path=profiles/$uid/profile.jpg error=$e',
      );
      return null;
    }
  }

  String _detectImageMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
