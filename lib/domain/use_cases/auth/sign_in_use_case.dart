import '../../repositories/auth_repository.dart';
import '../../../models/user.dart';

class SignInUseCase {
  final AuthRepository _repo;
  SignInUseCase(this._repo);

  Future<User?> call(String email, String password) {
    return _repo.signIn(email, password);
  }
}