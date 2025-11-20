import 'package:financial_manager/models/transaction.dart' as models;

abstract class TransactionsRepository {
  Future<List<models.Transaction>> fetchPage({
    required String userId,
    int limit = 20,
    String? lastDocumentId,
    String? typeFilter,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<void> create({
    required String userId,
    required models.Transaction tx,
  });

  Future<void> update({
    required String userId,
    required models.Transaction tx,
  });

  Future<void> delete({
    required String userId,
    required String transactionId,
  });
}