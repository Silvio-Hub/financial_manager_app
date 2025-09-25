import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getter para o usuário atual
  User? get currentUser => _auth.currentUser;

  // Stream do estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login com email e senha
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Registro com email e senha
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Verificar se o usuário está logado
  bool get isSignedIn => currentUser != null;

  // Obter o ID do usuário atual
  String? get currentUserId => currentUser?.uid;

  // Obter o email do usuário atual
  String? get currentUserEmail => currentUser?.email;
}
