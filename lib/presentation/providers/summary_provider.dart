import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../models/financial_summary.dart';
import '../../domain/use_cases/transactions/get_summary_use_case.dart';
import '../../domain/entities/date_range.dart';
import '../../services/logger_service.dart';
import 'dart:async';
import '../../domain/repositories/transactions_repository.dart';
import '../../services/cache_service.dart';

final _getIt = GetIt.instance;

final getSummaryUseCaseProvider = Provider<GetSummaryUseCase>((ref) {
  return _getIt<GetSummaryUseCase>();
});

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return _getIt<TransactionsRepository>();
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  return _getIt<CacheService>();
});

final summaryProvider = FutureProvider.family<FinancialSummary, String>((ref, uid) async {
  final usecase = ref.read(getSummaryUseCaseProvider);
  if (uid.isEmpty) {
    return FinancialSummary(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
      expensesByCategory: const {},
      incomesByCategory: const {},
      monthlyData: const [],
      periodStart: DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: DateTime.now(),
    );
  }
  LoggerService.debug('[summaryProvider] fetching summary for uid=$uid');
  try {
    return await usecase(uid).timeout(const Duration(seconds: 12));
  } on TimeoutException {
    LoggerService.warning('[summaryProvider] timeout fetching summary for uid=$uid');
    return FinancialSummary(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
      expensesByCategory: const {},
      incomesByCategory: const {},
      monthlyData: const [],
      periodStart: DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: DateTime.now(),
    );
  } catch (e, st) {
    LoggerService.error('[summaryProvider] error fetching summary', e, st);
    rethrow;
  }
});

class SummaryParams {
  final String uid;
  final DateRange? range;
  const SummaryParams(this.uid, {this.range});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SummaryParams &&
        other.uid == uid &&
        other.range?.start == range?.start &&
        other.range?.end == range?.end;
  }

  @override
  int get hashCode => Object.hash(uid, range?.start, range?.end);
}

final summaryByRangeProvider = FutureProvider.family<FinancialSummary, SummaryParams>((ref, params) async {
  final usecase = ref.read(getSummaryUseCaseProvider);
  if (params.uid.isEmpty) {
    LoggerService.info('[summaryByRangeProvider] empty uid, returning zero summary');
    return FinancialSummary(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
      expensesByCategory: const {},
      incomesByCategory: const {},
      monthlyData: const [],
      periodStart: params.range?.start ?? DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: params.range?.end ?? DateTime.now(),
    );
  }
  LoggerService.debug('[summaryByRangeProvider] fetching summary for uid=${params.uid} range=${params.range?.start}..${params.range?.end}');
  try {
    final result = await usecase(params.uid, range: params.range).timeout(const Duration(seconds: 12));
    LoggerService.info('[summaryByRangeProvider] fetched summary: income=${result.totalIncome}, expense=${result.totalExpense}');
    return result;
  } on TimeoutException {
    LoggerService.warning('[summaryByRangeProvider] timeout fetching summary for uid=${params.uid}');
    return FinancialSummary(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
      expensesByCategory: const {},
      incomesByCategory: const {},
      monthlyData: const [],
      periodStart: params.range?.start ?? DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: params.range?.end ?? DateTime.now(),
    );
  } catch (e, st) {
    LoggerService.error('[summaryByRangeProvider] error fetching summary', e, st);
    rethrow;
  }
});

final summaryByRangeStreamProvider = StreamProvider.family<FinancialSummary, SummaryParams>((ref, params) {
  final repo = ref.read(transactionsRepositoryProvider);
  final cache = ref.read(cacheServiceProvider);

  if (params.uid.isEmpty) {
    LoggerService.info('[summaryByRangeStreamProvider] empty uid, emitting zero summary');
    return Stream.value(
      FinancialSummary(
        totalIncome: 0,
        totalExpense: 0,
        balance: 0,
        expensesByCategory: const {},
        incomesByCategory: const {},
        monthlyData: const [],
        periodStart: params.range?.start ?? DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: params.range?.end ?? DateTime.now(),
      ),
    );
  }

  LoggerService.debug('[summaryByRangeStreamProvider] watching summary for uid=${params.uid} range=${params.range?.start}..${params.range?.end}');

  final controller = StreamController<FinancialSummary>();

  // Seed com cache se disponível
  final cached = cache.getSummary(params.uid, params.range);
  if (cached != null) {
    LoggerService.verbose('[summaryByRangeStreamProvider] cache HIT, seeding stream');
    controller.add(cached);
  } else {
    LoggerService.verbose('[summaryByRangeStreamProvider] cache MISS');
  }

  // Assina stream de transações e atualiza resumo + cache (write-through)
  final sub = repo
      .watchByUser(params.uid, range: params.range)
      .listen((txs) async {
        final summary = FinancialSummary.fromTransactions(
          txs,
          startDate: params.range?.start,
          endDate: params.range?.end,
        );
        LoggerService.verbose('[summaryByRangeStreamProvider] summary updated: income=${summary.totalIncome}, expense=${summary.totalExpense}, count=${txs.length}');
        controller.add(summary);
        await cache.putSummary(params.uid, params.range, summary);
      }, onError: (e, st) {
        LoggerService.error('[summaryByRangeStreamProvider] error watching summary', e, st);
      });

  // Cancelamento consciente
  controller.onCancel = () {
    sub.cancel();
    controller.close();
  };

  return controller.stream;
});