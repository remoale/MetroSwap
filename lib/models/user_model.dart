class UserModel {
  final String uid;
  String name;
  String email;
  String? photoUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  // PROTOTYPE → permite clonar el objeto sin acoplarlo
  UserModel clone() {
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      photoUrl: photoUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'],
        name: map['name'],
        email: map['email'],
        photoUrl: map['photoUrl'],
      );
}