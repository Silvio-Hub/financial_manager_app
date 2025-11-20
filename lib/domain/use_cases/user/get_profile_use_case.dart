import '../../repositories/user_repository.dart';
import '../../../models/user.dart';

class GetProfileUseCase {
  final UserRepository _repo;
  GetProfileUseCase(this._repo);

  Future<User> call(String uid) {
    return _repo.getProfile(uid);
  }
}