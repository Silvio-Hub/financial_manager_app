import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:financial_manager/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:financial_manager/models/transaction.dart' as models;
import 'package:financial_manager/services/firestore_service.dart';

class TransactionsRepositoryFirestore implements TransactionsRepository {
  final FirestoreService firestoreService;
  TransactionsRepositoryFirestore(this.firestoreService);

  @override
  Future<List<models.Transaction>> fetchPage({
    required String userId,
    int limit = 20,
    String? lastDocumentId,
    String? typeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final collection = FirestoreService.transactionsCollectionFor(userId);
    Query query = collection.orderBy('date', descending: true).limit(limit);

    if (typeFilter != null && typeFilter.isNotEmpty) {
      query = query.where('type', isEqualTo: typeFilter);
    }
    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate);
    }
    if (lastDocumentId != null) {
      final lastDoc = await collection.doc(lastDocumentId).get();
      if (lastDoc.exists) {
        query = (query as Query<Map<String, dynamic>>).startAfterDocument(lastDoc);
      }
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => models.Transaction.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> create({required String userId, required models.Transaction tx}) async {
    final data = tx.toMap();
    await FirestoreService.transactionsCollectionFor(userId).add(data);
  }

  @override
  Future<void> update({required String userId, required models.Transaction tx}) async {
    await FirestoreService.transactionsCollectionFor(userId).doc(tx.id).update(tx.toMap());
  }

  @override
  Future<void> delete({required String userId, required String transactionId}) async {
    await FirestoreService.transactionsCollectionFor(userId).doc(transactionId).delete();
  }
}