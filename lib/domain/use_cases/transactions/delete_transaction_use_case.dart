import '../../repositories/transactions_repository.dart';

class DeleteTransactionUseCase {
  final TransactionsRepository _repo;
  DeleteTransactionUseCase(this._repo);

  Future<void> call(String uid, String transactionId) {
    return _repo.delete(uid, transactionId);
  }
}