import '../../models/user.dart';

/// Authentication contract for the domain layer.
abstract class AuthRepository {
  /// Emits auth state changes for the logged-in user.
  Stream<User?> authState();

  /// Attempts to sign in and returns the authenticated user.
  Future<User?> signIn(String email, String password);

  /// Signs out the current user.
  Future<void> signOut();

  /// Registers a new user.
  Future<User?> register(String email, String password, {String? displayName});
}