import 'package:hive_flutter/hive_flutter.dart';
import '../models/financial_summary.dart';
import '../domain/entities/date_range.dart';
import '../models/transaction.dart';
import 'logger_service.dart';

class CacheService {
  static const String _boxName = 'financial_cache';
  static const String _summaryNs = 'summary';
  static const String _transactionsNs = 'transactions';

  Box<dynamic>? _box;

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<dynamic>(_boxName);
      LoggerService.info('[CacheService] Hive initialized and box opened: $_boxName');
    } catch (e, st) {
      LoggerService.error('[CacheService] Failed to initialize Hive', e, st);
      rethrow;
    }
  }

  bool get isReady => _box != null && _box!.isOpen;

  String _summaryKey(String uid, DateRange? range) {
    final startIso = range?.start?.toIso8601String() ?? '';
    final endIso = range?.end?.toIso8601String() ?? '';
    return '$_summaryNs:$uid:$startIso:$endIso';
  }

  String _transactionsKey(String uid, DateRange? range) {
    final startIso = range?.start?.toIso8601String() ?? '';
    final endIso = range?.end?.toIso8601String() ?? '';
    return '$_transactionsNs:$uid:$startIso:$endIso';
  }

  Future<void> putSummary(String uid, DateRange? range, FinancialSummary summary) async {
    if (!isReady) return;
    final key = _summaryKey(uid, range);
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = {
      'ts': now,
      'data': _summaryToMap(summary),
    };
    try {
      await _box!.put(key, payload);
      LoggerService.debug('[CacheService] putSummary key=$key');
    } catch (e, st) {
      LoggerService.error('[CacheService] putSummary failed', e, st);
    }
  }

  FinancialSummary? getSummary(String uid, DateRange? range, {Duration ttl = const Duration(minutes: 10)}) {
    if (!isReady) return null;
    final key = _summaryKey(uid, range);
    final raw = _box!.get(key);
    if (raw == null || raw is! Map) return null;
    try {
      final ts = (raw['ts'] ?? 0) as int;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > ttl.inMilliseconds) {
        LoggerService.verbose('[CacheService] cache expired for key=$key ageMs=$age');
        return null;
      }
      final data = raw['data'] as Map<dynamic, dynamic>;
      final summary = _summaryFromMap(Map<String, dynamic>.from(data));
      LoggerService.debug('[CacheService] getSummary HIT key=$key');
      return summary;
    } catch (e, st) {
      LoggerService.error('[CacheService] getSummary failed for key=$key', e, st);
      return null;
    }
  }

  Future<void> putTransactions(String uid, DateRange? range, List<Transaction> txs) async {
    if (!isReady) return;
    final key = _transactionsKey(uid, range);
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = {
      'ts': now,
      'data': txs.map(_transactionToMap).toList(),
    };
    try {
      await _box!.put(key, payload);
      LoggerService.debug('[CacheService] putTransactions key=$key count=${txs.length}');
    } catch (e, st) {
      LoggerService.error('[CacheService] putTransactions failed', e, st);
    }
  }

  List<Transaction>? getTransactions(String uid, DateRange? range, {Duration ttl = const Duration(minutes: 5)}) {
    if (!isReady) return null;
    final key = _transactionsKey(uid, range);
    final raw = _box!.get(key);
    if (raw == null || raw is! Map) return null;
    try {
      final ts = (raw['ts'] ?? 0) as int;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > ttl.inMilliseconds) {
        LoggerService.verbose('[CacheService] tx cache expired for key=$key ageMs=$age');
        return null;
      }
      final dataList = List<Map<dynamic, dynamic>>.from(raw['data'] ?? []);
      final txs = dataList
          .map((m) => _transactionFromMap(Map<String, dynamic>.from(m)))
          .toList();
      LoggerService.debug('[CacheService] getTransactions HIT key=$key count=${txs.length}');
      return txs;
    } catch (e, st) {
      LoggerService.error('[CacheService] getTransactions failed for key=$key', e, st);
      return null;
    }
  }

  Map<String, dynamic> _summaryToMap(FinancialSummary s) {
    return {
      'totalIncome': s.totalIncome,
      'totalExpense': s.totalExpense,
      'balance': s.balance,
      'expensesByCategory': s.expensesByCategory.map((k, v) => MapEntry(k.name, v)),
      'incomesByCategory': s.incomesByCategory.map((k, v) => MapEntry(k.name, v)),
      'monthlyData': s.monthlyData.map((m) => {
        'month': m.month.toIso8601String(),
        'income': m.income,
        'expense': m.expense,
        'balance': m.balance,
      }).toList(),
      'periodStart': s.periodStart.toIso8601String(),
      'periodEnd': s.periodEnd.toIso8601String(),
    };
  }

  FinancialSummary _summaryFromMap(Map<String, dynamic> m) {
    Map<TransactionCategory, double> expensesByCategory = {};
    Map<TransactionCategory, double> incomesByCategory = {};

    (m['expensesByCategory'] as Map).forEach((k, v) {
      final cat = TransactionCategory.values.firstWhere(
        (e) => e.name == k,
        orElse: () => TransactionCategory.otherExpense,
      );
      expensesByCategory[cat] = (v ?? 0).toDouble();
    });
    (m['incomesByCategory'] as Map).forEach((k, v) {
      final cat = TransactionCategory.values.firstWhere(
        (e) => e.name == k,
        orElse: () => TransactionCategory.otherIncome,
      );
      incomesByCategory[cat] = (v ?? 0).toDouble();
    });

    final monthlyData = List<Map<String, dynamic>>.from(m['monthlyData'] ?? [])
        .map((mm) => MonthlyData(
              month: DateTime.parse(mm['month'] as String),
              income: (mm['income'] ?? 0).toDouble(),
              expense: (mm['expense'] ?? 0).toDouble(),
              balance: (mm['balance'] ?? 0).toDouble(),
            ))
        .toList();

    return FinancialSummary(
      totalIncome: (m['totalIncome'] ?? 0).toDouble(),
      totalExpense: (m['totalExpense'] ?? 0).toDouble(),
      balance: (m['balance'] ?? 0).toDouble(),
      expensesByCategory: expensesByCategory,
      incomesByCategory: incomesByCategory,
      monthlyData: monthlyData,
      periodStart: DateTime.parse(m['periodStart'] as String),
      periodEnd: DateTime.parse(m['periodEnd'] as String),
    );
  }

  Map<String, dynamic> _transactionToMap(Transaction t) {
    return {
      'id': t.id,
      'title': t.title,
      'description': t.description,
      'amount': t.amount,
      'type': t.type.name,
      'category': t.category.name,
      'date': t.date.toIso8601String(),
      'userId': t.userId,
      'receiptUrls': t.receiptUrls,
      'parentTransactionId': t.parentTransactionId,
      'installmentIndex': t.installmentIndex,
      'installmentCount': t.installmentCount,
    };
  }

  Transaction _transactionFromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: (() {
        final raw = (map['type'] ?? '').toString().toLowerCase().trim();
        if (raw == 'income') return TransactionType.income;
        return TransactionType.expense;
      })(),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.otherExpense,
      ),
      date: DateTime.parse(map['date'] as String),
      userId: map['userId'],
      receiptUrls: List<String>.from(map['receiptUrls'] ?? []),
      parentTransactionId: map['parentTransactionId'],
      installmentIndex: (map['installmentIndex'] is int)
          ? map['installmentIndex'] as int
          : (map['installmentIndex'] != null)
              ? int.tryParse(map['installmentIndex'].toString())
              : null,
      installmentCount: (map['installmentCount'] is int)
          ? map['installmentCount'] as int
          : (map['installmentCount'] != null)
              ? int.tryParse(map['installmentCount'].toString())
              : null,
    );
  }
}