import '../../repositories/transactions_repository.dart';
import '../../entities/date_range.dart';
import '../../../models/transaction.dart';

class ListTransactionsUseCase {
  final TransactionsRepository _repo;
  ListTransactionsUseCase(this._repo);

  Stream<List<Transaction>> call(String uid, {DateRange? range}) {
    return _repo.watchByUser(uid, range: range);
  }
}