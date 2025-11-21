import '../../domain/repositories/user_repository.dart' as domain;
import '../../models/user.dart';
import '../../services/firestore_service.dart';

class UserRepositoryImpl implements domain.UserRepository {
  @override
  Future<User> getProfile(String uid) async {
    final user = await FirestoreService.getUserProfile(uid);
    return user ?? User.empty();
  }

  @override
  Future<void> updateProfile(User user) async {
    await FirestoreService.upsertUserProfile(user);
  }
}