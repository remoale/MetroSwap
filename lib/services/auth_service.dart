import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:metroswap/services/firestore_service.dart';

class AuthService {
  AuthService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        "614391071848-ltl8o0l941276poedpqob4in300tq7nd.apps.googleusercontent.com",
  );

  bool isInstitutionalEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized.endsWith('@unimet.edu.ve') ||
        normalized.endsWith('@correo.unimet.edu.ve');
  }

  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!isInstitutionalEmail(normalizedEmail)) {
      throw Exception(
        'Solo se permiten correos de dominio unimet: @unimet.edu.ve o @correo.unimet.edu.ve',
      );
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(displayName.trim());
        await _firestoreService.upsertUserProfile(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    }
  }

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!isInstitutionalEmail(normalizedEmail)) {
      throw Exception(
        'Solo se permiten correos de dominio unimet: @unimet.edu.ve o @correo.unimet.edu.ve',
      );
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      if (userCredential.user != null) {
        await _firestoreService.upsertUserProfile(userCredential.user!);
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;
      if (!isInstitutionalEmail(googleUser.email)) {
        await _googleSignIn.signOut();
        throw Exception(
          'Solo se permiten correos de dominio unimet: @unimet.edu.ve o @correo.unimet.edu.ve',
        );
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
      if (userCredential.user != null) {
        await _firestoreService.upsertUserProfile(userCredential.user!);
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e.toString().contains('Solo se permiten correos')) {
        rethrow;
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (_) {}
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ese correo ya esta registrado.';
      case 'invalid-email':
        return 'El correo no tiene un formato valido.';
      case 'weak-password':
        return 'La contrasena es muy debil.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'Correo o contrasena incorrectos.';
      case 'wrong-password':
        return 'Correo o contrasena incorrectos.';
      case 'operation-not-allowed':
        return 'Metodo de autenticacion no habilitado en Firebase.';
      case 'network-request-failed':
        return 'Error de red. Verifica tu conexion e intenta de nuevo.';
      case 'popup-blocked':
      case 'popup-closed-by-user':
        return 'El popup de Google se bloqueo o cerro antes de completar el inicio de sesion.';
      default:
        return 'Error de autenticacion (${e.code}).';
    }
  }
}
