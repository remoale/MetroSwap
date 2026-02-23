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
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final rawName = map['name'];
    final rawPhoto = map['photoUrl'] ?? map['photoURL'];
    final rawRole = (map['role'] ?? '').toString().toLowerCase();
    final normalizedRole = rawRole == roleAdmin
        ? roleAdmin
        : rawRole == roleProfessor
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
    );
  }
}
