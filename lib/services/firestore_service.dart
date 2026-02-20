import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // Asegúrate de que esta ruta sea la correcta

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtener los datos de un usuario por su ID
  Future<UserModel?> getUser(String uid) async {
    try {
      var snapshot = await _db.collection('users').doc(uid).get();
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!);
      }
      return null;
    } catch (e) {
      print("Error al obtener usuario: $e");
      return null;
    }
  }

  // Actualizar los datos del usuario (nombre, foto, etc.)
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
    } catch (e) {
      print("Error al actualizar usuario: $e");
    }
  }
}