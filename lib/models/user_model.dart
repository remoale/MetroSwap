class UserModel {
  final String uid;
  String name;
  String email;
  String? photoUrl;
  String? phone;
  String? career;
  String? studentId;
  List<String>? books;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phone,
    this.career,
    this.studentId,
    this.books,
  });

  // PROTOTYPE: permite clonar el objeto sin acoplarlo
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
    );
  }

  // MAPPER: convierte el objeto a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'displayName': name,
      'email': email,
      'photoUrl': photoUrl,
      'phone': phone,
      'career': career,
      'studentId': studentId,
      'books': books,
    };
  }

  //Crea un modelo desde Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    final rawName = map['name'] ?? map['displayName'];
    final rawPhoto = map['photoUrl'] ?? map['photoURL'];
    return UserModel(
      uid: (map['uid'] ?? '').toString(),
      name: (rawName ?? 'Usuario').toString(),
      email: (map['email'] ?? '').toString(),
      photoUrl: rawPhoto?.toString(),
      phone: map['phone'],
      career: map['career'],
      studentId: (map['studentId'] ?? map['carnet'])?.toString(),
      books: map['books'] != null ? List<String>.from(map['books']) : null,
    );
  }
}
