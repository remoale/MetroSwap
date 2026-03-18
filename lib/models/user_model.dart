import 'package:metroswap/utils/admin_utils.dart';

class UserModel {
  static const String roleStudent = 'estudiante';
  static const String roleProfessor = 'profesor';
  static const String roleAdmin = 'admin';

  final String uid;
  String name;
  String email;
  String? photoUrl;
  String? phone;
  String? career;
  String? studentId;
  List<String>? books;
  String role;
  int reputation; 
  int tradesCount;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phone,
    this.career,
    this.studentId,
    this.books,
    this.role = roleStudent,
    this.reputation = 0,
    this.tradesCount = 0,
  });

  UserModel clone() {
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      photoUrl: photoUrl,
      phone: phone,
      career: career,
      studentId: studentId,
      books: books != null ? List<String>.from(books!) : null,
      role: role,
      reputation: reputation,
      tradesCount: tradesCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'phone': phone,
      'career': career,
      'studentId': studentId,
      'books': books,
      'role': role,
      'reputation': reputation,
      'tradesCount': tradesCount,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final rawName = map['name'];
    final rawPhoto = map['photoUrl'] ?? map['photoURL'];
    final normalizedEmail = (map['email'] ?? '').toString().trim().toLowerCase();
    final rawRole = (map['role'] ?? '').toString().toLowerCase();
    final normalizedRole = rawRole == roleAdmin
        ? roleAdmin
        : rawRole == roleProfessor
            ? roleProfessor
            : isAdminEmail(normalizedEmail)
                ? roleAdmin
                : normalizedEmail.endsWith('@unimet.edu.ve')
                    ? roleProfessor
                    : roleStudent;
    return UserModel(
      uid: (map['uid'] ?? '').toString(),
      name: (rawName ?? 'Usuario').toString(),
      email: (map['email'] ?? '').toString(),
      photoUrl: rawPhoto?.toString(),
      phone: map['phone'],
      career: map['career'],
      studentId: (map['studentId'] ?? map['carnet'])?.toString(),
      books: map['books'] != null ? List<String>.from(map['books']) : null,
      role: normalizedRole,
      reputation: map['reputation'] ?? 0, 
      tradesCount: map['tradesCount'] ?? 0, 
    );
  }
}
