import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financial_manager/features/transactions/domain/usecases/get_transactions_page.dart';
import 'package:financial_manager/models/transaction.dart' as models;
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

final getTransactionsPageProvider = Provider<GetTransactionsPage>((ref) {
  return getIt<GetTransactionsPage>();
});

class TransactionsPageNotifier extends AsyncNotifier<List<models.Transaction>> {
  String? _lastId;
  String get lastId => _lastId ?? '';

  @override
  Future<List<models.Transaction>> build() async {
    // Inicialmente, não carrega nada até ser chamado explicitamente
    return <models.Transaction>[];
  }

  Future<void> loadFirstPage({required String userId, int limit = 20}) async {
    final usecase = ref.read(getTransactionsPageProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await usecase(userId: userId, limit: limit);
      _lastId = items.isNotEmpty ? items.last.id : null;
      return items;
    });
  }

  Future<void> loadNextPage({required String userId, int limit = 20}) async {
    final usecase = ref.read(getTransactionsPageProvider);
    final current = state.value ?? <models.Transaction>[];
    final next = await usecase(userId: userId, limit: limit, lastDocumentId: _lastId);
    _lastId = next.isNotEmpty ? next.last.id : _lastId;
    state = AsyncData([...current, ...next]);
  }
}

final transactionsPageProvider = AsyncNotifierProvider<TransactionsPageNotifier, List<models.Transaction>>(
  TransactionsPageNotifier.new,
);