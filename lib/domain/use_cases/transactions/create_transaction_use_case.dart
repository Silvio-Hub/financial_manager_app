import '../../repositories/transactions_repository.dart';
import '../../../models/transaction.dart';

class CreateTransactionUseCase {
  final TransactionsRepository _repo;
  CreateTransactionUseCase(this._repo);

  Future<void> call(String uid, Transaction transaction) {
    return _repo.create(uid, transaction);
  }
}