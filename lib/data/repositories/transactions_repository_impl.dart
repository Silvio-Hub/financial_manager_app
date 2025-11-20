import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import '../../domain/repositories/transactions_repository.dart' as domain;
import '../../domain/entities/date_range.dart';
import '../../models/transaction.dart' as models;
import '../../models/financial_summary.dart';
import '../../services/firestore_service.dart';
import 'package:get_it/get_it.dart';
import '../../services/cache_service.dart';
import '../../services/logger_service.dart';

class TransactionsRepositoryImpl implements domain.TransactionsRepository {
  TransactionsRepositoryImpl();

  cf.Timestamp _startOfDay(DateTime d) => cf.Timestamp.fromDate(DateTime(d.year, d.month, d.day));
  cf.Timestamp _endOfDay(DateTime d) => cf.Timestamp.fromDate(DateTime(d.year, d.month, d.day, 23, 59, 59, 999));

  @override
  Future<void> create(String uid, models.Transaction transaction) async {
    await FirestoreService.transactionsCollectionFor(uid)
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  @override
  Future<void> update(String uid, models.Transaction transaction) async {
    await FirestoreService.transactionsCollectionFor(uid)
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  @override
  Future<void> delete(String uid, String transactionId) async {
    await FirestoreService.transactionsCollectionFor(uid)
        .doc(transactionId)
        .delete();
  }

  @override
  Stream<List<models.Transaction>> watchByUser(String uid, {DateRange? range}) async* {
    final cache = GetIt.I<CacheService>();
    final cached = cache.getTransactions(uid, range);
    if (cached != null && cached.isNotEmpty) {
      LoggerService.debug('[TransactionsRepo] watchByUser cache SEED uid=$uid count=${cached.length}');
      yield cached;
    }

    cf.Query<Map<String, dynamic>> query = FirestoreService.transactionsCollectionFor(uid)
        .orderBy('date', descending: true) as cf.Query<Map<String, dynamic>>;

    if (range != null) {
      if (range.start != null) {
        query = query.where('date', isGreaterThanOrEqualTo: _startOfDay(range.start!));
      }
      if (range.end != null) {
        query = query.where('date', isLessThanOrEqualTo: _endOfDay(range.end!));
      }
    }

    yield* query.snapshots().map((snapshot) {
      final txs = snapshot.docs
          .map((doc) => models.Transaction.fromMap(doc.data()))
          .toList();
      try {
        cache.putTransactions(uid, range, txs);
      } catch (e, st) {
        LoggerService.error('[TransactionsRepo] watchByUser cache WRITE failed', e, st);
      }
      return txs;
    });
  }

  @override
  Future<List<models.Transaction>> fetchByUser(String uid, {DateRange? range}) async {
    try {
      final cache = GetIt.I<CacheService>();
      final cached = cache.getTransactions(uid, range);
      if (cached != null && cached.isNotEmpty) {
        LoggerService.debug('[TransactionsRepo] fetchByUser cache HIT uid=$uid count=${cached.length}');
        return cached;
      }

      cf.Query<Map<String, dynamic>> query = FirestoreService.transactionsCollectionFor(uid)
          .orderBy('date', descending: true) as cf.Query<Map<String, dynamic>>;

      if (range != null) {
        if (range.start != null) {
          query = query.where('date', isGreaterThanOrEqualTo: _startOfDay(range.start!));
        }
        if (range.end != null) {
          query = query.where('date', isLessThanOrEqualTo: _endOfDay(range.end!));
        }
      }

      final snapshot = await query.get();
      final txs = snapshot.docs
          .map((doc) => models.Transaction.fromMap(doc.data()))
          .toList();
      try {
        await cache.putTransactions(uid, range, txs);
        LoggerService.debug('[TransactionsRepo] fetchByUser cache WRITE uid=$uid count=${txs.length}');
      } catch (e, st) {
        LoggerService.error('[TransactionsRepo] putTransactions failed', e, st);
      }
      return txs;
    } catch (e, st) {
      LoggerService.error('Error fetching transactions for user', e, st);
      rethrow;
    }
  }

  @override
  Future<FinancialSummary> summary(String uid, {DateRange? range}) async {
    final txs = await fetchByUser(uid, range: range);
    return FinancialSummary.fromTransactions(
      txs,
      startDate: range?.start,
      endDate: range?.end,
    );
  }
}