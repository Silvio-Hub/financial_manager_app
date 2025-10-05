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

  // Estado de paginação (Firestore)
  DocumentSnapshot? _lastFetchedDocument;
  bool _hasMoreTransactions = true;

  // Getters
  // Garantir ordenação por data (mais recentes primeiro) sempre que acessar
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

  // Transações filtradas por período
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

  // Transações por tipo
  List<Transaction> get incomeTransactions => filteredTransactions
      .where((t) => t.type == TransactionType.income)
      .toList();

  List<Transaction> get expenseTransactions => filteredTransactions
      .where((t) => t.type == TransactionType.expense)
      .toList();

  // Totais
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
    // Usar últimos 30 dias como período padrão para refletir melhor dados recentes
    final now = DateTime.now();
    _selectedPeriodStart = now.subtract(const Duration(days: 30));
    _selectedPeriodEnd = now;
  }

  // Carregar transações (prioriza Firebase se autenticado)
  Future<void> loadTransactions() async {
    _setLoading(true);
    _clearError();

    try {
      // Se usuário estiver autenticado, carregar do Firebase
      if (FirestoreService.isUserAuthenticated) {
        LoggerService.debug('Usuário autenticado, carregando do Firebase...');
        await loadTransactionsFromFirestore();
        return;
      }

      // Caso contrário, carregar do armazenamento local
      LoggerService.debug('Usuário não autenticado, carregando dados locais...');
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getStringList('transactions') ?? [];

      LoggerService.debug(
        'Carregando transações locais... ${transactionsJson.length} encontradas',
      );

      _transactions = transactionsJson
          .map((json) => Transaction.fromMap(jsonDecode(json)))
          .toList();

      // Ordenar por data (mais recente primeiro)
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      LoggerService.debug('${_transactions.length} transações carregadas localmente');

      _updateSummary();
    } catch (e) {
      LoggerService.error('Erro ao carregar transações: $e', e);
      _setError('Erro ao carregar transações: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Salvar transações no armazenamento local
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

  // Adicionar transação
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

  // Atualizar transação
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

  // Remover transação
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

  // Definir período de análise
  void setPeriod(DateTime start, DateTime end) {
    _selectedPeriodStart = start;
    _selectedPeriodEnd = end;
    _updateSummary();
    notifyListeners();
  }

  // Definir período para o mês atual
  void setCurrentMonth() {
    final now = DateTime.now();
    setPeriod(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 0),
    );
  }

  // Definir período para os últimos 30 dias
  void setLast30Days() {
    final now = DateTime.now();
    setPeriod(now.subtract(const Duration(days: 30)), now);
  }

  // Definir período para o ano atual
  void setCurrentYear() {
    final now = DateTime.now();
    setPeriod(DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
  }

  // Atualizar resumo financeiro
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

  // Obter transações por categoria
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

  // Limpar todos os dados
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



  // Carregar transações com filtros e paginação
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
      // Se for reset, recarregar todas as transações
      if (reset) {
        await loadTransactions();
      }

      // Aplicar filtros
      List<Transaction> filteredList = List.from(_transactions);

      // Filtro por tipo
      if (type != null) {
        filteredList = filteredList.where((t) => t.type == type).toList();
      }

      // Filtro por categoria
      if (category != null) {
        filteredList = filteredList
            .where((t) => t.category == category)
            .toList();
      }

      // Filtro por período
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

      // Filtro por valor mínimo
      if (minAmount != null) {
        filteredList = filteredList
            .where((t) => t.amount >= minAmount)
            .toList();
      }

      // Filtro por valor máximo
      if (maxAmount != null) {
        filteredList = filteredList
            .where((t) => t.amount <= maxAmount)
            .toList();
      }

      // Filtro por busca textual
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

      // Ordenar por data (mais recente primeiro)
      filteredList.sort((a, b) => b.date.compareTo(a.date));

      // Se for reset, substituir a lista, senão adicionar à lista existente
      if (reset) {
        _transactions = filteredList;
      } else {
        // Para paginação, adicionar apenas os novos itens
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

  // Buscar transações por texto
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

  // Filtrar transações por múltiplos critérios
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

  // Obter estatísticas de transações
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

  // Carregar transações do Firestore
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

      // Salvar localmente como backup
      await _saveTransactions();
      _updateSummary();

      // Se não houver transações no Firestore, sincronizar dados locais
      if (_transactions.isEmpty) {
        await _syncLocalDataToFirestore();
      }
    } catch (e) {
      LoggerService.error(
        'Erro ao carregar do Firestore, usando dados locais: $e',
        e,
      );
      _setError('Erro ao carregar dados online: $e');
      await loadTransactions(); // Fallback para dados locais
    } finally {
      _setLoading(false);
    }
  }

  // Adicionar transação com sincronização Firestore
  Future<void> addTransactionWithSync(Transaction transaction) async {
    _setLoading(true);
    _clearError();

    try {
      // Adicionar localmente primeiro
      _transactions.add(transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      // Salvar localmente
      await _saveTransactions();

      // Sincronizar com Firestore se autenticado
      if (FirestoreService.isUserAuthenticated) {
        await FirestoreService.addTransaction(transaction);
        LoggerService.debug('Transação sincronizada com Firestore');
      }

      _updateSummary();
    } catch (e) {
      // Se falhar no Firestore, manter dados locais
      LoggerService.error('Erro ao sincronizar com Firestore: $e', e);
      _setError('Transação salva localmente. Erro de sincronização: $e');
      _updateSummary();
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar transação com sincronização Firestore
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

        // Salvar localmente
        await _saveTransactions();

        // Sincronizar com Firestore se autenticado
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

  // Remover transação com sincronização Firestore
  Future<void> removeTransactionWithSync(String transactionId) async {
    _setLoading(true);
    _clearError();

    try {
      _transactions.removeWhere((t) => t.id == transactionId);

      // Salvar localmente
      await _saveTransactions();

      // Sincronizar com Firestore se autenticado
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

  // Sincronizar dados locais com Firestore
  Future<void> _syncLocalDataToFirestore() async {
    if (!FirestoreService.isUserAuthenticated) return;

    try {
      // Carregar dados locais
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

        // Recarregar do Firestore para garantir consistência
        await loadTransactionsFromFirestore();
      }
    } catch (e) {
      LoggerService.error('Erro ao sincronizar dados locais: $e', e);
    }
  }

  // Carregar transações com filtros do Firestore
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
      // Fallback para método local
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
      // Resetar estado de paginação
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
       LoggerService.error('Erro ao carregar transações filtradas do Firestore: $e', e);
       _setError('Erro ao carregar transações: $e');

      // Fallback para método local
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

  // Verificar status de sincronização
  bool get isOnlineMode => FirestoreService.isUserAuthenticated;

  // Forçar sincronização completa
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

  // Métodos auxiliares
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
