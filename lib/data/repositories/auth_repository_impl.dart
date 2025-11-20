import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/repositories/auth_repository.dart';
import '../../models/user.dart' as domain_user;
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  AuthRepositoryImpl(this._authService);

  domain_user.User _toDomainUser(fb.User firebaseUser, {domain_user.User? profile}) {
    final now = DateTime.now();
    if (profile != null && !profile.isEmpty) {
      return profile.copyWith(updatedAt: now);
    }
    return domain_user.User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Stream<domain_user.User?> authState() {
    return _authService.authStateChanges.asyncMap((fb.User? user) async {
      if (user == null) return null;
      final profile = await FirestoreService.getUserProfile(user.uid);
      return _toDomainUser(user, profile: profile);
    });
  }

  @override
  Future<domain_user.User?> signIn(String email, String password) async {
    final cred = await _authService.signInWithEmailAndPassword(email, password);
    final fb.User? user = cred?.user ?? _authService.currentUser;
    if (user == null) return null;
    // Enriquecer com perfil
    final profile = await FirestoreService.getUserProfile(user.uid);
    final domain = _toDomainUser(user, profile: profile);
    // Se não houver perfil, garantir upsert mínimo
    if (profile == null) {
      await FirestoreService.upsertUserProfile(domain);
    }
    return domain;
  }

  @override
  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  Future<domain_user.User?> register(String email, String password, {String? displayName}) async {
    final cred = await _authService.createUserWithEmailAndPassword(email, password);
    final fb.User? user = cred?.user ?? _authService.currentUser;
    if (user == null) return null;
    if ((displayName ?? '').isNotEmpty) {
      await user.updateDisplayName(displayName);
      await user.reload();
    }
    final now = DateTime.now();
    final domain = domain_user.User(
      id: user.uid,
      email: user.email ?? email,
      name: displayName ?? user.displayName ?? '',
      createdAt: now,
      updatedAt: now,
    );
    await FirestoreService.upsertUserProfile(domain);
    return domain;
  }
}