import '../../repositories/user_repository.dart';
import '../../../models/user.dart';

class UpdateProfileUseCase {
  final UserRepository _repo;
  UpdateProfileUseCase(this._repo);

  Future<void> call(User user) {
    return _repo.updateProfile(user);
  }
}