import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../models/transaction.dart';
import '../../domain/use_cases/transactions/list_transactions_use_case.dart';
import '../../domain/entities/date_range.dart';

final _getIt = GetIt.instance;

final listTransactionsUseCaseProvider = Provider<ListTransactionsUseCase>((ref) {
  return _getIt<ListTransactionsUseCase>();
});

final listTransactionsProvider = StreamProvider.family<List<Transaction>, String>((ref, uid) {
  final usecase = ref.read(listTransactionsUseCaseProvider);
  return usecase(uid);
});

class ListTransactionsParams {
  final String uid;
  final DateRange? range;
  const ListTransactionsParams(this.uid, {this.range});
}

final listTransactionsByRangeProvider = StreamProvider.family<List<Transaction>, ListTransactionsParams>((ref, params) {
  final usecase = ref.read(listTransactionsUseCaseProvider);
  return usecase(params.uid, range: params.range);
});