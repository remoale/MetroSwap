import 'dart:async';

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
    final directNotificationsStream = _notificationsRef(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
    final requesterExchangesStream = _firestore
        .collection('exchanges')
        .where('requesterUid', isEqualTo: uid)
        .limit(limit)
        .snapshots();
    final targetExchangesStream = _firestore
        .collection('exchanges')
        .where('targetUid', isEqualTo: uid)
        .limit(limit)
        .snapshots();
    final ownerExchangesStream = _firestore
        .collection('exchanges')
        .where('ownerUid', isEqualTo: uid)
        .limit(limit)
        .snapshots();

    return Stream.multi((controller) {
      List<NotificationModel> directNotifications = const <NotificationModel>[];
      List<NotificationModel> requesterExchangeNotifications =
          const <NotificationModel>[];
      List<NotificationModel> targetExchangeNotifications =
          const <NotificationModel>[];
      List<NotificationModel> ownerExchangeNotifications =
          const <NotificationModel>[];

      void emitMerged() {
        final merged = _mergeNotifications(
          directNotifications: directNotifications,
          requesterExchangeNotifications: requesterExchangeNotifications,
          targetExchangeNotifications: targetExchangeNotifications,
          ownerExchangeNotifications: ownerExchangeNotifications,
        );
        controller.add(merged.take(limit).toList(growable: false));
      }

      final subscriptions = <StreamSubscription<dynamic>>[
        directNotificationsStream.listen(
          (snapshot) {
            directNotifications = snapshot.docs
                .map(NotificationModel.fromDoc)
                .toList(growable: false);
            emitMerged();
          },
          onError: controller.addError,
        ),
        requesterExchangesStream.listen(
          (snapshot) {
            requesterExchangeNotifications = snapshot.docs
                .map((doc) => _notificationFromExchangeDoc(doc: doc, uid: uid))
                .whereType<NotificationModel>()
                .toList(growable: false);
            emitMerged();
          },
          onError: (_) {
            requesterExchangeNotifications = const <NotificationModel>[];
            emitMerged();
          },
        ),
        targetExchangesStream.listen(
          (snapshot) {
            targetExchangeNotifications = snapshot.docs
                .map((doc) => _notificationFromExchangeDoc(doc: doc, uid: uid))
                .whereType<NotificationModel>()
                .toList(growable: false);
            emitMerged();
          },
          onError: (_) {
            targetExchangeNotifications = const <NotificationModel>[];
            emitMerged();
          },
        ),
        ownerExchangesStream.listen(
          (snapshot) {
            ownerExchangeNotifications = snapshot.docs
                .map((doc) => _notificationFromExchangeDoc(doc: doc, uid: uid))
                .whereType<NotificationModel>()
                .toList(growable: false);
            emitMerged();
          },
          onError: (_) {
            ownerExchangeNotifications = const <NotificationModel>[];
            emitMerged();
          },
        ),
      ];

      controller.onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };
    });
  }

  List<NotificationModel> _mergeNotifications({
    required List<NotificationModel> directNotifications,
    required List<NotificationModel> requesterExchangeNotifications,
    required List<NotificationModel> targetExchangeNotifications,
    required List<NotificationModel> ownerExchangeNotifications,
  }) {
    final byKey = <String, NotificationModel>{};

    for (final notification in directNotifications) {
      byKey[_notificationKey(notification)] = notification;
    }

    final synthetic = <NotificationModel>[
      ...requesterExchangeNotifications,
      ...targetExchangeNotifications,
      ...ownerExchangeNotifications,
    ];
    for (final notification in synthetic) {
      final key = _notificationKey(notification);
      byKey.putIfAbsent(key, () => notification);
    }

    final merged = byKey.values.toList(growable: false);
    merged.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return merged;
  }

  String _notificationKey(NotificationModel notification) {
    final exchangeId = notification.data?['exchangeId']?.toString().trim() ?? '';
    final status = notification.data?['status']?.toString().trim() ?? '';
    if (exchangeId.isNotEmpty) {
      return '${notification.type}|$exchangeId|$status';
    }
    return 'doc:${notification.id}';
  }

  NotificationModel? _notificationFromExchangeDoc({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String uid,
  }) {
    final data = doc.data();
    final requesterUid = (data['requesterUid'] ?? '').toString().trim();
    final targetUid = (data['targetUid'] ?? '').toString().trim();
    final ownerUid = (data['ownerUid'] ?? '').toString().trim();
    final status = (data['status'] ?? 'requested').toString().trim().toLowerCase();
    final postTitle = (data['postTitle'] ?? '').toString().trim();
    final exchangeId = doc.id;
    final postId = (data['postId'] ?? '').toString().trim();
    final requesterName =
        (data['requesterName'] ?? data['actorName'] ?? 'Un usuario')
            .toString()
            .trim();
    final ownerName =
        (data['ownerName'] ?? data['targetName'] ?? 'El propietario')
            .toString()
            .trim();

    final isRequester = requesterUid == uid;
    final isTarget = targetUid == uid || ownerUid == uid;
    if (!isRequester && !isTarget) {
      return null;
    }

    final updatedAt = data['updatedAt'];
    final createdAt = data['createdAt'];
    final when = updatedAt is Timestamp
        ? updatedAt.toDate()
        : createdAt is Timestamp
            ? createdAt.toDate()
            : null;

    String type;
    String title;
    String body;
    String actorUid;
    String actorName;

    switch (status) {
      case 'accepted':
        type = 'exchange_accepted';
        title = 'Intercambio aceptado';
        if (isRequester) {
          body = '$ownerName acepto tu solicitud de intercambio';
          actorUid = targetUid.isNotEmpty ? targetUid : ownerUid;
          actorName = ownerName;
        } else {
          body = 'Aceptaste el intercambio de $requesterName';
          actorUid = requesterUid;
          actorName = requesterName;
        }
        break;
      case 'rejected':
      case 'declined':
        type = 'exchange_rejected';
        title = 'Intercambio rechazado';
        if (isRequester) {
          body = '$ownerName rechazo tu solicitud de intercambio';
          actorUid = targetUid.isNotEmpty ? targetUid : ownerUid;
          actorName = ownerName;
        } else {
          body = 'Rechazaste el intercambio de $requesterName';
          actorUid = requesterUid;
          actorName = requesterName;
        }
        break;
      case 'completed':
        type = 'exchange_completed';
        title = 'Intercambio completado';
        if (isRequester) {
          body = 'El intercambio con $ownerName fue completado';
          actorUid = targetUid.isNotEmpty ? targetUid : ownerUid;
          actorName = ownerName;
        } else {
          body = 'El intercambio con $requesterName fue completado';
          actorUid = requesterUid;
          actorName = requesterName;
        }
        break;
      case 'requested':
      default:
        type = 'exchange_requested';
        if (isRequester) {
          title = 'Solicitud enviada';
          body = postTitle.isEmpty
              ? 'Tu solicitud de intercambio fue enviada'
              : 'Tu solicitud para "$postTitle" fue enviada';
          actorUid = targetUid.isNotEmpty ? targetUid : ownerUid;
          actorName = ownerName;
        } else {
          title = 'Nueva solicitud de intercambio';
          body = '$requesterName quiere realizar un intercambio contigo';
          actorUid = requesterUid;
          actorName = requesterName;
        }
        break;
    }

    return NotificationModel(
      id: 'exchange_event_${doc.id}_$status',
      type: type,
      title: title,
      body: body,
      createdAt: when,
      // Son notificaciones sinteticas para visualizar estado del intercambio.
      read: true,
      readAt: when,
      actorUid: actorUid.isEmpty ? null : actorUid,
      data: {
        'exchangeId': exchangeId,
        'postId': postId.isEmpty ? null : postId,
        'status': status,
        'actorName': actorName,
      },
    );
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
