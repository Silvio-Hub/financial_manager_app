import '../../repositories/transactions_repository.dart';
import '../../entities/date_range.dart';
import '../../../models/financial_summary.dart';

class GetSummaryUseCase {
  final TransactionsRepository _repo;
  GetSummaryUseCase(this._repo);

  Future<FinancialSummary> call(String uid, {DateRange? range}) {
    return _repo.summary(uid, range: range);
  }
}