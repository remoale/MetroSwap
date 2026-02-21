import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(clientId: "614391071848-ltl8o0l941276poedpqob4in300tq7nd.apps.googleusercontent.com");

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null; // El usuario cancelo
      // Verificamos si el correo es de la Unimet
      if (!googleUser.email.endsWith('@unimet.edu.ve') && !googleUser.email.endsWith('@correo.unimet.edu.ve')) 
      {
        // Si no, cerramos la sesión de Google inmediatamente
      await _googleSignIn.signOut();
      throw Exception('Solo se permiten correos de dominio unimet: @unimet.edu.ve o @correo.unimet.edu.ve');
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception("No se pudieron obtener los tokens de Google.");
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      return userCredential.user;
    } catch (e) {
      if (e.toString().contains('Solo se permiten correos')) {
        rethrow;
      }
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      //Cerrar sesion
    }
  }
}