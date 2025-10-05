import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/financial_summary.dart';
import '../services/firestore_service.dart';
import '../services/logger_service.dart';

class FinancialProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  FinancialSummary? _currentSummary;
  bool _isLoading = false;
  String? _error;
  DateTime _selectedPeriodStart = DateTime.now();
  DateTime _selectedPeriodEnd = DateTime.now();

  DocumentSnapshot? _lastFetchedDocument;
  bool _hasMoreTransactions = true;

  List<Transaction> get transactions {
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  FinancialSummary? get currentSummary => _currentSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedPeriodStart => _selectedPeriodStart;
  DateTime get selectedPeriodEnd => _selectedPeriodEnd;
  bool get hasMoreTransactions => _hasMoreTransactions;

  List<Transaction> get filteredTransactions {
    return _transactions
        .where(
          (transaction) =>
              transaction.date.isAfter(
                _selectedPeriodStart.subtract(const Duration(days: 1)),
              ) &&
              transaction.date.isBefore(
                _selectedPeriodEnd.add(const Duration(days: 1)),
              ),
        )
        .toList();
  }

  List<Transaction> get incomeTransactions => filteredTransactions
      .where((t) => t.type == TransactionType.income)
      .toList();

  List<Transaction> get expenseTransactions => filteredTransactions
      .where((t) => t.type == TransactionType.expense)
      .toList();

  double get totalIncome => incomeTransactions.fold(
    0.0,
    (previous, transaction) => previous + transaction.amount,
  );

  double get totalExpense => expenseTransactions.fold(
    0.0,
    (previous, transaction) => previous + transaction.amount,
  );

  double get balance => totalIncome - totalExpense;

  FinancialProvider() {
    _initializePeriod();
    loadTransactions();
  }

  void _initializePeriod() {
    final now = DateTime.now();
    _selectedPeriodStart = now.subtract(const Duration(days: 30));
    _selectedPeriodEnd = now;
  }

  Future<void> loadTransactions() async {
    _setLoading(true);
    _clearError();

    try {
      if (FirestoreService.isUserAuthenticated) {
        LoggerService.debug('Usuário autenticado, carregando do Firebase...');
        await loadTransactionsFromFirestore();
        return;
      }

      LoggerService.debug(
        'Usuário não autenticado, carregando dados locais...',
      );
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getStringList('transactions') ?? [];

      LoggerService.debug(
        'Carregando transações locais... ${transactionsJson.length} encontradas',
      );

      _transactions = transactionsJson
          .map((json) => Transaction.fromMap(jsonDecode(json)))
          .toList();

      _transactions.sort((a, b) => b.date.compareTo(a.date));

      LoggerService.debug(
        '${_transactions.length} transações carregadas localmente',
      );

      _updateSummary();
    } catch (e) {
      LoggerService.error('Erro ao carregar transações: $e', e);
      _setError('Erro ao carregar transações: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = _transactions
          .map((transaction) => jsonEncode(transaction.toMap()))
          .toList();

      await prefs.setStringList('transactions', transactionsJson);
    } catch (e) {
      _setError('Erro ao salvar transações: $e');
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    _setLoading(true);
    _clearError();

    try {
      _transactions.add(transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      await _saveTransactions();
      _updateSummary();
    } catch (e) {
      _setError('Erro ao adicionar transação: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTransaction(Transaction updatedTransaction) async {
    _setLoading(true);
    _clearError();

    try {
      final index = _transactions.indexWhere(
        (t) => t.id == updatedTransaction.id,
      );
      if (index != -1) {
        _transactions[index] = updatedTransaction;
        _transactions.sort((a, b) => b.date.compareTo(a.date));

        await _saveTransactions();
        _updateSummary();
      }
    } catch (e) {
      _setError('Erro ao atualizar transação: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeTransaction(String transactionId) async {
    _setLoading(true);
    _clearError();

    try {
      _transactions.removeWhere((t) => t.id == transactionId);

      await _saveTransactions();
      _updateSummary();
    } catch (e) {
      _setError('Erro ao remover transação: $e');
    } finally {
      _setLoading(false);
    }
  }

  void setPeriod(DateTime start, DateTime end) {
    _selectedPeriodStart = start;
    _selectedPeriodEnd = end;
    _updateSummary();
    notifyListeners();
  }

  void setCurrentMonth() {
    final now = DateTime.now();
    setPeriod(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 0),
    );
  }

  void setLast30Days() {
    final now = DateTime.now();
    setPeriod(now.subtract(const Duration(days: 30)), now);
  }

  void setCurrentYear() {
    final now = DateTime.now();
    setPeriod(DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
  }

  void _updateSummary() {
    LoggerService.debug(
      'Atualizando resumo com ${_transactions.length} transações',
    );
    LoggerService.debug(
      'Período: $_selectedPeriodStart até $_selectedPeriodEnd',
    );

    _currentSummary = FinancialSummary.fromTransactions(
      _transactions,
      startDate: _selectedPeriodStart,
      endDate: _selectedPeriodEnd,
    );

    LoggerService.debug(
      'Resumo criado - Receitas: ${_currentSummary?.totalIncome}, Despesas: ${_currentSummary?.totalExpense}',
    );
    notifyListeners();
  }

  Map<TransactionCategory, List<Transaction>> getTransactionsByCategory(
    TransactionType type,
  ) {
    final transactions = type == TransactionType.income
        ? incomeTransactions
        : expenseTransactions;
    final Map<TransactionCategory, List<Transaction>> grouped = {};

    for (final transaction in transactions) {
      grouped.putIfAbsent(transaction.category, () => []).add(transaction);
    }

    return grouped;
  }

  Future<void> clearAllData() async {
    _setLoading(true);
    _clearError();

    try {
      _transactions.clear();
      _currentSummary = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('transactions');

      notifyListeners();
    } catch (e) {
      _setError('Erro ao limpar dados: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTransactionsWithFilters({
    int page = 0,
    int pageSize = 20,
    TransactionType? type,
    TransactionCategory? category,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
    bool reset = false,
  }) async {
    if (reset) {
      _setLoading(true);
    }
    _clearError();

    try {
      if (reset) {
        await loadTransactions();
      }

      List<Transaction> filteredList = List.from(_transactions);

      if (type != null) {
        filteredList = filteredList.where((t) => t.type == type).toList();
      }

      if (category != null) {
        filteredList = filteredList
            .where((t) => t.category == category)
            .toList();
      }

      if (dateRange != null) {
        filteredList = filteredList
            .where(
              (t) =>
                  t.date.isAfter(
                    dateRange.start.subtract(const Duration(days: 1)),
                  ) &&
                  t.date.isBefore(dateRange.end.add(const Duration(days: 1))),
            )
            .toList();
      }

      if (minAmount != null) {
        filteredList = filteredList
            .where((t) => t.amount >= minAmount)
            .toList();
      }

      if (maxAmount != null) {
        filteredList = filteredList
            .where((t) => t.amount <= maxAmount)
            .toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        filteredList = filteredList
            .where(
              (t) =>
                  t.description.toLowerCase().contains(query) ||
                  t.title.toLowerCase().contains(query) ||
                  t.category.displayName.toLowerCase().contains(query),
            )
            .toList();
      }

      filteredList.sort((a, b) => b.date.compareTo(a.date));

      if (reset) {
        _transactions = filteredList;
      } else {
        final startIndex = page * pageSize;
        final endIndex = (startIndex + pageSize).clamp(0, filteredList.length);

        if (startIndex < filteredList.length) {
          final newItems = filteredList.sublist(startIndex, endIndex);
          _transactions.addAll(newItems);
        }
      }

      _updateSummary();
    } catch (e) {
      _setError('Erro ao carregar transações: $e');
    } finally {
      if (reset) {
        _setLoading(false);
      }
    }
  }

  List<Transaction> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;

    final lowerQuery = query.toLowerCase();
    return _transactions
        .where(
          (transaction) =>
              transaction.description.toLowerCase().contains(lowerQuery) ||
              transaction.title.toLowerCase().contains(lowerQuery) ||
              transaction.category.displayName.toLowerCase().contains(
                lowerQuery,
              ),
        )
        .toList();
  }

  List<Transaction> filterTransactions({
    TransactionType? type,
    TransactionCategory? category,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
  }) {
    List<Transaction> filtered = List.from(_transactions);

    if (type != null) {
      filtered = filtered.where((t) => t.type == type).toList();
    }

    if (category != null) {
      filtered = filtered.where((t) => t.category == category).toList();
    }

    if (dateRange != null) {
      filtered = filtered
          .where(
            (t) =>
                t.date.isAfter(
                  dateRange.start.subtract(const Duration(days: 1)),
                ) &&
                t.date.isBefore(dateRange.end.add(const Duration(days: 1))),
          )
          .toList();
    }

    if (minAmount != null) {
      filtered = filtered.where((t) => t.amount >= minAmount).toList();
    }

    if (maxAmount != null) {
      filtered = filtered.where((t) => t.amount <= maxAmount).toList();
    }

    return filtered;
  }

  Map<String, dynamic> getTransactionStats() {
    return {
      'total': _transactions.length,
      'income': incomeTransactions.length,
      'expense': expenseTransactions.length,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': balance,
      'avgIncome': incomeTransactions.isNotEmpty
          ? totalIncome / incomeTransactions.length
          : 0.0,
      'avgExpense': expenseTransactions.isNotEmpty
          ? totalExpense / expenseTransactions.length
          : 0.0,
    };
  }

  // ========== MÉTODOS DE INTEGRAÇÃO COM FIRESTORE ==========

  Future<void> loadTransactionsFromFirestore() async {
    if (!FirestoreService.isUserAuthenticated) {
      LoggerService.debug('Usuário não autenticado, carregando dados locais');
      await loadTransactions();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      LoggerService.debug('Carregando transações do Firestore...');
      final firestoreTransactions = await FirestoreService.getAllTransactions();

      _transactions = firestoreTransactions;
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      LoggerService.debug(
        '${_transactions.length} transações carregadas do Firestore',
      );

      await _saveTransactions();
      _updateSummary();

      if (_transactions.isEmpty) {
        await _syncLocalDataToFirestore();
      }
    } catch (e) {
      LoggerService.error(
        'Erro ao carregar do Firestore, usando dados locais: $e',
        e,
      );
      _setError('Erro ao carregar dados online: $e');
      await loadTransactions();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addTransactionWithSync(Transaction transaction) async {
    _setLoading(true);
    _clearError();

    try {
      _transactions.add(transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      await _saveTransactions();

      if (FirestoreService.isUserAuthenticated) {
        await FirestoreService.addTransaction(transaction);
        LoggerService.debug('Transação sincronizada com Firestore');
      }

      _updateSummary();
    } catch (e) {
      LoggerService.error('Erro ao sincronizar com Firestore: $e', e);
      _setError('Transação salva localmente. Erro de sincronização: $e');
      _updateSummary();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTransactionWithSync(Transaction updatedTransaction) async {
    _setLoading(true);
    _clearError();

    try {
      final index = _transactions.indexWhere(
        (t) => t.id == updatedTransaction.id,
      );
      if (index != -1) {
        _transactions[index] = updatedTransaction;
        _transactions.sort((a, b) => b.date.compareTo(a.date));

        await _saveTransactions();

        if (FirestoreService.isUserAuthenticated) {
          await FirestoreService.updateTransaction(updatedTransaction);
          LoggerService.debug('Transação atualizada no Firestore');
        }

        _updateSummary();
      }
    } catch (e) {
      LoggerService.error('Erro ao atualizar no Firestore: $e', e);
      _setError('Transação atualizada localmente. Erro de sincronização: $e');
      _updateSummary();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeTransactionWithSync(String transactionId) async {
    _setLoading(true);
    _clearError();

    try {
      _transactions.removeWhere((t) => t.id == transactionId);

      await _saveTransactions();

      if (FirestoreService.isUserAuthenticated) {
        await FirestoreService.deleteTransaction(transactionId);
        LoggerService.debug('Transação removida do Firestore');
      }

      _updateSummary();
    } catch (e) {
      LoggerService.error('Erro ao remover do Firestore: $e', e);
      _setError('Transação removida localmente. Erro de sincronização: $e');
      _updateSummary();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _syncLocalDataToFirestore() async {
    if (!FirestoreService.isUserAuthenticated) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getStringList('transactions') ?? [];

      if (transactionsJson.isNotEmpty) {
        final localTransactions = transactionsJson
            .map((json) => Transaction.fromMap(jsonDecode(json)))
            .toList();

        LoggerService.debug(
          'Sincronizando ${localTransactions.length} transações locais com Firestore',
        );
        await FirestoreService.syncLocalDataToFirestore(localTransactions);

        await loadTransactionsFromFirestore();
      }
    } catch (e) {
      LoggerService.error('Erro ao sincronizar dados locais: $e', e);
    }
  }

  Future<void> loadTransactionsWithFiltersFromFirestore({
    int page = 0,
    int pageSize = 20,
    TransactionType? type,
    TransactionCategory? category,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
    bool reset = false,
  }) async {
    if (!FirestoreService.isUserAuthenticated) {
      await loadTransactionsWithFilters(
        page: page,
        pageSize: pageSize,
        type: type,
        category: category,
        dateRange: dateRange,
        minAmount: minAmount,
        maxAmount: maxAmount,
        searchQuery: searchQuery,
        reset: reset,
      );
      return;
    }

    if (reset) {
      _setLoading(true);
      _lastFetchedDocument = null;
      _hasMoreTransactions = true;
    }
    _clearError();

    try {
      final result = await FirestoreService.getTransactionsWithFiltersPaginated(
        limit: pageSize,
        lastDocument: _lastFetchedDocument,
        type: type,
        category: category,
        startDate: dateRange?.start,
        endDate: dateRange?.end,
        minAmount: minAmount,
        maxAmount: maxAmount,
        searchQuery: searchQuery,
      );

      _lastFetchedDocument = result.lastDocument;
      _hasMoreTransactions = result.hasMore;

      if (reset) {
        _transactions = result.items;
      } else {
        _transactions.addAll(result.items);
      }

      _updateSummary();
    } catch (e) {
      LoggerService.error(
        'Erro ao carregar transações filtradas do Firestore: $e',
        e,
      );
      _setError('Erro ao carregar transações: $e');

      await loadTransactionsWithFilters(
        page: page,
        pageSize: pageSize,
        type: type,
        category: category,
        dateRange: dateRange,
        minAmount: minAmount,
        maxAmount: maxAmount,
        searchQuery: searchQuery,
        reset: reset,
      );
    } finally {
      if (reset) {
        _setLoading(false);
      }
    }
  }

  bool get isOnlineMode => FirestoreService.isUserAuthenticated;

  Future<void> forceSyncWithFirestore() async {
    if (!FirestoreService.isUserAuthenticated) {
      _setError('Usuário não autenticado para sincronização');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _syncLocalDataToFirestore();
      await loadTransactionsFromFirestore();
      LoggerService.debug('Sincronização completa realizada com sucesso');
    } catch (e) {
      LoggerService.error('Erro na sincronização completa: $e', e);
      _setError('Erro na sincronização: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
