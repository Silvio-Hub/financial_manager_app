import '../../repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _repo;
  SignOutUseCase(this._repo);

  Future<void> call() {
    return _repo.signOut();
  }
}