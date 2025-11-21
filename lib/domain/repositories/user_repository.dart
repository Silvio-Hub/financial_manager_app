import '../../models/user.dart';

/// User profile contract for the domain layer.
abstract class UserRepository {
  Future<User> getProfile(String uid);
  Future<void> updateProfile(User user);
}