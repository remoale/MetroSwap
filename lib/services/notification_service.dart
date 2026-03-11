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
      final directNotifications = snapshot.docs
          .map(NotificationModel.fromDoc)
          .toList(growable: false);
      return _mergeNotifications(directNotifications: directNotifications)
          .take(limit)
          .toList(growable: false);
    });
  }

  List<NotificationModel> _mergeNotifications({
    required List<NotificationModel> directNotifications,
  }) {
    final nonExchangeNotifications = <NotificationModel>[];
    final exchangeGroups = <String, List<NotificationModel>>{};

    for (final notification in directNotifications) {
      final exchangeId = _exchangeId(notification);
      if (exchangeId.isEmpty) {
        nonExchangeNotifications.add(notification);
        continue;
      }
      exchangeGroups.putIfAbsent(exchangeId, () => <NotificationModel>[])
          .add(notification);
    }

    final merged = <NotificationModel>[
      ...nonExchangeNotifications,
      ...exchangeGroups.values.map(_pickVisibleExchangeNotification),
    ];
    merged.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return merged;
  }

  NotificationModel _pickVisibleExchangeNotification(
    List<NotificationModel> notifications,
  ) {
    const priority = <String, int>{
      'completed': 4,
      'rejected': 3,
      'accepted': 2,
      'requested': 1,
    };

    notifications.sort((a, b) {
      final aPriority = priority[_normalizedStatus(a)] ?? 0;
      final bPriority = priority[_normalizedStatus(b)] ?? 0;
      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority);
      }

      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return notifications.first;
  }

  String _exchangeId(NotificationModel notification) {
    return notification.data?['exchangeId']?.toString().trim() ?? '';
  }

  String _normalizedStatus(NotificationModel notification) {
    final rawStatus = notification.data?['status']?.toString().trim().toLowerCase();
    if (rawStatus != null && rawStatus.isNotEmpty) {
      if (rawStatus == 'declined') {
        return 'rejected';
      }
      return rawStatus;
    }

    final type = notification.type.trim().toLowerCase();
    if (type == 'exchange_requested') {
      return 'requested';
    }
    if (type == 'exchange_accepted') {
      return 'accepted';
    }
    if (type == 'exchange_rejected') {
      return 'rejected';
    }
    if (type == 'exchange_completed') {
      return 'completed';
    }
    return '';
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
