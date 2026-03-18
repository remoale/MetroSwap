import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Reference _profileRef(String uid) {
    return _storage.ref().child('profiles').child(uid).child('profile.jpg');
  }

  Future<String?> uploadProfileImage(String uid, XFile file) async {
    try {
      // Usa una ruta por usuario para respetar las reglas por UID.
      final ref = _profileRef(uid);
      final metadata = SettableMetadata(contentType: _detectImageMimeType(file.path));
      final bytes = await file.readAsBytes();

      // Sube la imagen y devuelve su URL pública.
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
          return null;
        }
      }
      return value;
    }

    return null;
  }

  Future<String?> getProfileImageDownloadUrl(String uid) async {
    try {
      final ref = _profileRef(uid);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<String?> ensureProfileImageFromRemoteUrlIfMissing({
    required String uid,
    required String remoteUrl,
  }) async {
    final normalizedUrl = remoteUrl.trim();
    if (normalizedUrl.isEmpty) {
      return getProfileImageDownloadUrl(uid);
    }

    final ref = _profileRef(uid);

    try {
      await ref.getMetadata();
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        debugPrint(
          '[StorageService.ensureProfileImageFromRemoteUrlIfMissing] '
          'uid=$uid metadata_error code=${e.code} message=${e.message}',
        );
        return null;
      }
    } catch (e) {
      debugPrint(
        '[StorageService.ensureProfileImageFromRemoteUrlIfMissing] '
        'uid=$uid metadata_error error=$e',
      );
      return null;
    }

    try {
      final uri = Uri.tryParse(normalizedUrl);
      if (uri == null) return null;

      final byteData = await NetworkAssetBundle(uri).load('');
      final bytes = byteData.buffer.asUint8List();
      if (bytes.isEmpty) return null;

      final metadata = SettableMetadata(
        contentType: _detectImageMimeType(uri.path),
      );

      final snapshot = await ref.putData(bytes, metadata);
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint(
        '[StorageService.ensureProfileImageFromRemoteUrlIfMissing] '
        'uid=$uid upload_error code=${e.code} message=${e.message}',
      );
      return null;
    } catch (e) {
      debugPrint(
        '[StorageService.ensureProfileImageFromRemoteUrlIfMissing] '
        'uid=$uid upload_error error=$e',
      );
      return null;
    }
  }

  Future<Uint8List?> getProfileImageBytes(String uid, {int maxSizeBytes = 5 * 1024 * 1024}) async {
    try {
      final ref = _profileRef(uid);
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
