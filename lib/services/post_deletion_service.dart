import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:metroswap/models/exchange_model.dart';
import 'package:metroswap/models/post_model.dart';

class PostDeletionResult {
  final bool hardDeleted;
  final String message;

  const PostDeletionResult({
    required this.hardDeleted,
    required this.message,
  });
}

class PostDeletionService {
  PostDeletionService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<PostDeletionResult> deletePost({
    required String postId,
    required String ownerUid,
    required String title,
    required String imageUrl,
  }) async {
    final normalizedPostId = postId.trim();
    final normalizedOwnerUid = ownerUid.trim();
    final normalizedTitle = title.trim();
    final normalizedImageUrl = imageUrl.trim();

    if (normalizedPostId.isEmpty) {
      throw StateError('No se pudo identificar la publicación.');
    }

    final hasActiveExchanges = await _hasActiveExchanges(normalizedPostId);
    if (hasActiveExchanges) {
      await _firestore.collection('posts').doc(normalizedPostId).update({
        'status': PostModel.statusInactive,
        'lifecycleStatus': PostModel.lifecycleOutOfStock,
        'quantity': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const PostDeletionResult(
        hardDeleted: false,
        message:
            'La publicación tiene intercambios activos, así que se desactivó en lugar de borrarse.',
      );
    }

    final batch = _firestore.batch();
    final postRef = _firestore.collection('posts').doc(normalizedPostId);
    batch.delete(postRef);

    if (normalizedOwnerUid.isNotEmpty) {
      final userRef = _firestore.collection('users').doc(normalizedOwnerUid);
      batch.set(userRef, {
        'books': FieldValue.arrayRemove([
          normalizedPostId,
          if (normalizedTitle.isNotEmpty) normalizedTitle,
        ]),
      }, SetOptions(merge: true));
    }

    await batch.commit();

    if (normalizedImageUrl.isNotEmpty && normalizedImageUrl.contains('firebase')) {
      try {
        await _storage.refFromURL(normalizedImageUrl).delete();
      } catch (_) {}
    }

    return const PostDeletionResult(
      hardDeleted: true,
      message: 'Publicación eliminada correctamente.',
    );
  }

  Future<bool> _hasActiveExchanges(String postId) async {
    final snapshot = await _firestore
        .collection('exchanges')
        .where('postId', isEqualTo: postId)
        .get();

    for (final doc in snapshot.docs) {
      final status = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
      if (status == ExchangeModel.statusRequested ||
          status == ExchangeModel.statusAccepted) {
        return true;
      }
    }

    return false;
  }
}
