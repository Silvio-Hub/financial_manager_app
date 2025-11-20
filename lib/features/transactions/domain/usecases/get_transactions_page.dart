import 'package:financial_manager/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:financial_manager/models/transaction.dart' as models;

class GetTransactionsPage {
  final TransactionsRepository repository;
  const GetTransactionsPage(this.repository);

  Future<List<models.Transaction>> call({
    required String userId,
    int limit = 20,
    String? lastDocumentId,
    String? typeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return repository.fetchPage(
      userId: userId,
      limit: limit,
      lastDocumentId: lastDocumentId,
      typeFilter: typeFilter,
      startDate: startDate,
      endDate: endDate,
    );
  }
}