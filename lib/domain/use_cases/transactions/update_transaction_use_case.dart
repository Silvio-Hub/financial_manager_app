import '../../repositories/transactions_repository.dart';
import '../../../models/transaction.dart';

class UpdateTransactionUseCase {
  final TransactionsRepository _repo;
  UpdateTransactionUseCase(this._repo);

  Future<void> call(String uid, Transaction transaction) {
    return _repo.update(uid, transaction);
  }
}