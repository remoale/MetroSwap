import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime? createdAt;
  final bool read;
  final DateTime? readAt;
  final String? actorUid;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    required this.readAt,
    this.actorUid,
    this.data,
  });

  factory NotificationModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return NotificationModel.fromMap(doc.id, doc.data());
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    final createdAtTimestamp = map['createdAt'];
    final readAtTimestamp = map['readAt'];

    return NotificationModel(
      id: id,
      type: (map['type'] ?? 'system').toString(),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      createdAt: createdAtTimestamp is Timestamp
          ? createdAtTimestamp.toDate()
          : null,
      read: map['read'] == true,
      readAt: readAtTimestamp is Timestamp ? readAtTimestamp.toDate() : null,
      actorUid: map['actorUid']?.toString(),
      data: map['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'body': body,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'read': read,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'actorUid': actorUid,
      'data': data,
    };
  }
}
