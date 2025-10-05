import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart' as app_models;

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static CollectionReference get _userTransactionsCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }

  static Future<void> addTransaction(app_models.Transaction transaction) async {
    try {
      await _userTransactionsCollection
          .doc(transaction.id)
          .set(transaction.toMap());
    } catch (e) {
      throw Exception('Erro ao salvar transação: $e');
    }
  }

  static Future<void> updateTransaction(
    app_models.Transaction transaction,
  ) async {
    try {
      await _userTransactionsCollection
          .doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar transação: $e');
    }
  }

  static Future<void> deleteTransaction(String transactionId) async {
    try {
      await _userTransactionsCollection.doc(transactionId).delete();
    } catch (e) {
      throw Exception('Erro ao remover transação: $e');
    }
  }

  static Future<List<app_models.Transaction>> getAllTransactions() async {
    try {
      final querySnapshot = await _userTransactionsCollection
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => app_models.Transaction.fromMap(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar transações: $e');
    }
  }

  static Future<List<app_models.Transaction>> getTransactionsWithFilters({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    app_models.TransactionType? type,
    app_models.TransactionCategory? category,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
  }) async {
    try {
      Query query = _userTransactionsCollection.orderBy(
        'date',
        descending: true,
      );

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (category != null) {
        query = query.where(
          'category',
          isEqualTo: category.toString().split('.').last,
        );
      }

      if (startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay(startDate)),
        );
      }

      if (endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(_endOfDay(endDate)),
        );
      }

      if (minAmount != null) {
        query = query.where('amount', isGreaterThanOrEqualTo: minAmount);
      }

      if (maxAmount != null) {
        query = query.where('amount', isLessThanOrEqualTo: maxAmount);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      List<app_models.Transaction> transactions = querySnapshot.docs
          .map(
            (doc) => app_models.Transaction.fromMap(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        transactions = transactions
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

      return transactions;
    } catch (e) {
      throw Exception('Erro ao buscar transações filtradas: $e');
    }
  }

  static Future<PaginatedTransactions> getTransactionsWithFiltersPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    app_models.TransactionType? type,
    app_models.TransactionCategory? category,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
  }) async {
    try {
      Query query = _userTransactionsCollection.orderBy(
        'date',
        descending: true,
      );

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (category != null) {
        query = query.where(
          'category',
          isEqualTo: category.toString().split('.').last,
        );
      }

      if (startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay(startDate)),
        );
      }

      if (endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(_endOfDay(endDate)),
        );
      }

      if (minAmount != null) {
        query = query.where('amount', isGreaterThanOrEqualTo: minAmount);
      }

      if (maxAmount != null) {
        query = query.where('amount', isLessThanOrEqualTo: maxAmount);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      List<app_models.Transaction> transactions = querySnapshot.docs
          .map(
            (doc) => app_models.Transaction.fromMap(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        transactions = transactions
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

      final bool hasMore = querySnapshot.docs.length == limit;
      final DocumentSnapshot? newLastDocument = querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.last
          : lastDocument;

      return PaginatedTransactions(
        items: transactions,
        lastDocument: newLastDocument,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception('Erro ao buscar transações paginadas: $e');
    }
  }

  static Stream<List<app_models.Transaction>> getTransactionsStream() {
    try {
      return _userTransactionsCollection
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => app_models.Transaction.fromMap(
                    doc.data() as Map<String, dynamic>,
                  ),
                )
                .toList(),
          );
    } catch (e) {
      throw Exception('Erro ao criar stream de transações: $e');
    }
  }

  static Future<List<app_models.Transaction>> getTransactionsByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot = await _userTransactionsCollection
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay(startDate)),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(_endOfDay(endDate)),
          )
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => app_models.Transaction.fromMap(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar transações por período: $e');
    }
  }

  static Future<List<app_models.Transaction>> getTransactionsByCategory(
    app_models.TransactionCategory category,
  ) async {
    try {
      final querySnapshot = await _userTransactionsCollection
          .where('category', isEqualTo: category.toString().split('.').last)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => app_models.Transaction.fromMap(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar transações por categoria: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final querySnapshot = await _userTransactionsCollection.get();
      final transactions = querySnapshot.docs
          .map(
            (doc) => app_models.Transaction.fromMap(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();

      final incomeTransactions = transactions
          .where((t) => t.type == app_models.TransactionType.income)
          .toList();
      final expenseTransactions = transactions
          .where((t) => t.type == app_models.TransactionType.expense)
          .toList();

      final totalIncome = incomeTransactions.fold(
        0.0,
        (total, t) => total + t.amount,
      );
      final totalExpense = expenseTransactions.fold(
        0.0,
        (total, t) => total + t.amount,
      );

      return {
        'totalTransactions': transactions.length,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': totalIncome - totalExpense,
        'incomeCount': incomeTransactions.length,
        'expenseCount': expenseTransactions.length,
        'avgIncome': incomeTransactions.isNotEmpty
            ? totalIncome / incomeTransactions.length
            : 0.0,
        'avgExpense': expenseTransactions.isNotEmpty
            ? totalExpense / expenseTransactions.length
            : 0.0,
      };
    } catch (e) {
      throw Exception('Erro ao buscar estatísticas: $e');
    }
  }

  static Future<void> syncLocalDataToFirestore(
    List<app_models.Transaction> localTransactions,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final transaction in localTransactions) {
        final docRef = _userTransactionsCollection.doc(transaction.id);
        batch.set(docRef, transaction.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao sincronizar dados: $e');
    }
  }

  static bool get isUserAuthenticated => _auth.currentUser != null;

  static String? get currentUserId => _auth.currentUser?.uid;

  static Future<void> updateTransactionReceipts(
    String transactionId,
    List<String> receiptUrls,
  ) async {
    try {
      await _userTransactionsCollection.doc(transactionId).update({
        'receiptUrls': receiptUrls,
      });
    } catch (e) {
      throw Exception('Erro ao atualizar recibos da transação: $e');
    }
  }

  static Future<void> addReceiptToTransaction(
    String transactionId,
    String receiptUrl,
  ) async {
    try {
      await _userTransactionsCollection.doc(transactionId).update({
        'receiptUrls': FieldValue.arrayUnion([receiptUrl]),
      });
    } catch (e) {
      throw Exception('Erro ao adicionar recibo à transação: $e');
    }
  }

  static Future<void> removeReceiptFromTransaction(
    String transactionId,
    String receiptUrl,
  ) async {
    try {
      await _userTransactionsCollection.doc(transactionId).update({
        'receiptUrls': FieldValue.arrayRemove([receiptUrl]),
      });
    } catch (e) {
      throw Exception('Erro ao remover recibo da transação: $e');
    }
  }

  static Future<List<String>> getTransactionReceipts(
    String transactionId,
  ) async {
    try {
      final doc = await _userTransactionsCollection.doc(transactionId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['receiptUrls'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Erro ao buscar recibos da transação: $e');
    }
  }

  static Future<void> clearLocalCache() async {
    try {
      await _firestore.clearPersistence();
    } catch (e) {
      throw Exception('Erro ao limpar cache: $e');
    }
  }
}

class PaginatedTransactions {
  final List<app_models.Transaction> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaginatedTransactions({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });
}
