import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  static const String methodExchange = 'Intercambio';
  static const String methodSale = 'Venta';
  static const String methodDonation = 'Donacion';

  static const String lifecyclePublished = 'Publicado';
  static const String lifecycleRequested = 'Solicitado';
  static const String lifecycleAccepted = 'Aceptado';
  static const String lifecycleDelivered = 'Entregado';

  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';

  final String id;
  final String title;
  final String description;
  final String materialType;
  final String knowledgeArea;
  final String career;
  final String subject;
  final String condition;
  final String method;
  final double? priceUsd;
  final String imageUrl;
  final String ownerUid;
  final String ownerName;
  final String? ownerEmail;
  final String status;
  final String lifecycleStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PostModel({
    required this.id,
    required this.title,
    required this.description,
    required this.materialType,
    required this.knowledgeArea,
    required this.career,
    required this.subject,
    required this.condition,
    required this.method,
    required this.priceUsd,
    required this.imageUrl,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerEmail,
    this.status = statusActive,
    this.lifecycleStatus = lifecyclePublished,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'materialType': materialType,
      'knowledgeArea': knowledgeArea,
      'career': career,
      'subject': subject,
      'condition': condition,
      'method': method,
      'priceUsd': priceUsd,
      'imageUrl': imageUrl,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'status': status,
      'lifecycleStatus': lifecycleStatus,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'materialType': materialType,
      'knowledgeArea': knowledgeArea,
      'career': career,
      'subject': subject,
      'condition': condition,
      'method': method,
      'priceUsd': priceUsd,
      'imageUrl': imageUrl,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'status': status,
      'lifecycleStatus': lifecycleStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return PostModel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      materialType: (map['materialType'] ?? '').toString(),
      knowledgeArea: (map['knowledgeArea'] ?? '').toString(),
      career: (map['career'] ?? '').toString(),
      subject: (map['subject'] ?? '').toString(),
      condition: (map['condition'] ?? '').toString(),
      method: (map['method'] ?? '').toString(),
      priceUsd: map['priceUsd'] == null
          ? null
          : double.tryParse(map['priceUsd'].toString()),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      ownerUid: (map['ownerUid'] ?? '').toString(),
      ownerName: (map['ownerName'] ?? '').toString(),
      ownerEmail: map['ownerEmail']?.toString(),
      status: (map['status'] ?? statusActive).toString(),
      lifecycleStatus: (map['lifecycleStatus'] ?? lifecyclePublished).toString(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
