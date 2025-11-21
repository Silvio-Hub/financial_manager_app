import '../../repositories/auth_repository.dart';
import '../../../models/user.dart';

class RegisterUserUseCase {
  final AuthRepository _repo;
  RegisterUserUseCase(this._repo);

  Future<User?> call(String email, String password, {String? displayName}) {
    return _repo.register(email, password, displayName: displayName);
  }
}