import '../entities/date_range.dart';
import '../../models/transaction.dart';
import '../../models/financial_summary.dart';

/// Abstraction for transaction operations, independent from infrastructure.
abstract class TransactionsRepository {
  /// Creates a new transaction for the given [uid].
  Future<void> create(String uid, Transaction transaction);

  /// Updates an existing transaction (matched by id) for the given [uid].
  Future<void> update(String uid, Transaction transaction);

  /// Deletes a transaction by [transactionId] for the given [uid].
  Future<void> delete(String uid, String transactionId);

  /// Watches transactions for the given [uid], optionally filtered by [range].
  Stream<List<Transaction>> watchByUser(String uid, {DateRange? range});

  /// Fetches transactions once for the given [uid], optionally filtered by [range].
  Future<List<Transaction>> fetchByUser(String uid, {DateRange? range});

  /// Computes financial summary for the given [uid] and optional [range].
  Future<FinancialSummary> summary(String uid, {DateRange? range});
}
