import 'package:financial_manager/features/transactions/domain/usecases/get_transactions_page.dart';
import 'package:financial_manager/features/transactions/infra/transactions_repository_firestore.dart';
import 'package:financial_manager/services/firestore_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupDependencies(FirestoreService firestoreService) {
  // Registro de serviços base
  getIt.registerSingleton<FirestoreService>(firestoreService);

  // Repositórios
  getIt.registerLazySingleton<TransactionsRepositoryFirestore>(() => TransactionsRepositoryFirestore(getIt<FirestoreService>()));

  // Use cases
  getIt.registerFactory<GetTransactionsPage>(() => GetTransactionsPage(getIt<TransactionsRepositoryFirestore>()));
}