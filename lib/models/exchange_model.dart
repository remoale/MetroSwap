import 'package:cloud_firestore/cloud_firestore.dart';

class ExchangeModel {
  static const String statusRequested = 'requested';
  static const String statusAccepted = 'accepted';
  static const String statusRejected = 'rejected';
  static const String statusDeclined = 'declined';
  static const String statusCompleted = 'completed';

  final String id;
  final String postId;
  final String postTitle;
  final String imageUrl;
  final String method;
  final String ownerUid;
  final String targetUid;
  final String requesterUid;
  final String requesterName;
  final String status;
  final String paymentStatus;
  final double? paypalAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExchangeModel({
    required this.id,
    required this.postId,
    required this.postTitle,
    required this.imageUrl,
    required this.method,
    required this.ownerUid,
    required this.targetUid,
    required this.requesterUid,
    required this.requesterName,
    required this.status,
    required this.paymentStatus,
    this.paypalAmount,
    this.createdAt,
    this.updatedAt,
  });

  factory ExchangeModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ExchangeModel.fromMap(doc.data() ?? {}, fallbackId: doc.id);
  }

  factory ExchangeModel.fromMap(
    Map<String, dynamic> map, {
    String fallbackId = '',
  }) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    double? parseNumber(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final normalizedFallbackId = fallbackId.trim();
    final normalizedMapId = (map['id'] ?? '').toString().trim();

    return ExchangeModel(
      id: normalizedFallbackId.isNotEmpty ? normalizedFallbackId : normalizedMapId,
      postId: (map['postId'] ?? '').toString(),
      postTitle: (map['postTitle'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      method: (map['method'] ?? '').toString(),
      ownerUid: (map['ownerUid'] ?? '').toString(),
      targetUid: (map['targetUid'] ?? '').toString(),
      requesterUid: (map['requesterUid'] ?? '').toString(),
      requesterName: (map['requesterName'] ?? '').toString(),
      status: (map['status'] ?? statusRequested).toString(),
      paymentStatus: (map['paymentStatus'] ?? '').toString(),
      paypalAmount: parseNumber(map['paypalAmount']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'postId': postId,
      'postTitle': postTitle,
      'imageUrl': imageUrl,
      'method': method,
      'ownerUid': ownerUid,
      'targetUid': targetUid,
      'requesterUid': requesterUid,
      'requesterName': requesterName,
      'status': status,
      'paymentStatus': paymentStatus,
      if (paypalAmount != null) 'paypalAmount': paypalAmount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
