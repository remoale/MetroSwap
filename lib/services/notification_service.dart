import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metroswap/models/notification_model.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('notifications');
  }

  Stream<List<NotificationModel>> streamNotifications(
    String uid, {
    int limit = 50,
  }) {
    return _notificationsRef(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(NotificationModel.fromDoc).toList();
    });
  }

  Future<void> markAsRead({
    required String uid,
    required String notificationId,
  }) async {
    await _notificationsRef(uid).doc(notificationId).set(
      {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> markAllAsRead(String uid) async {
    final unreadSnapshot =
        await _notificationsRef(uid).where('read', isEqualTo: false).get();

    if (unreadSnapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unreadSnapshot.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}