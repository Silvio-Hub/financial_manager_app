import 'package:get_it/get_it.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';

// Camada de dados (implementações)
import 'data/repositories/transactions_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/receipt_repository_impl.dart';

// Contratos de domínio
import 'domain/repositories/transactions_repository.dart' as domain_tx;
import 'domain/repositories/auth_repository.dart' as domain_auth;
import 'domain/repositories/user_repository.dart' as domain_user;
import 'domain/repositories/receipt_repository.dart' as domain_receipt;

// Casos de uso (domínio)
import 'domain/use_cases/transactions/create_transaction_use_case.dart';
import 'domain/use_cases/transactions/update_transaction_use_case.dart';
import 'domain/use_cases/transactions/delete_transaction_use_case.dart';
import 'domain/use_cases/transactions/list_transactions_use_case.dart';
import 'domain/use_cases/transactions/get_summary_use_case.dart';
import 'domain/use_cases/auth/sign_in_use_case.dart';
import 'domain/use_cases/auth/sign_out_use_case.dart';
import 'domain/use_cases/auth/register_user_use_case.dart';
import 'domain/use_cases/user/get_profile_use_case.dart';
import 'domain/use_cases/user/update_profile_use_case.dart';

// Registros legados (feature transactions)
import 'features/transactions/domain/usecases/get_transactions_page.dart';
import 'features/transactions/infra/transactions_repository_firestore.dart';

final getIt = GetIt.instance;

void setupDependencies(FirestoreService firestoreService) {
  // Serviços base
  getIt.registerSingleton<FirestoreService>(firestoreService);
  getIt.registerLazySingleton<AuthService>(() => AuthService());

  // Repositórios (features legadas)
  getIt.registerLazySingleton<TransactionsRepositoryFirestore>(
    () => TransactionsRepositoryFirestore(getIt<FirestoreService>()),
  );

  // Repositórios (domínio)
  getIt.registerLazySingleton<domain_tx.TransactionsRepository>(
    () => TransactionsRepositoryImpl(),
  );
  getIt.registerLazySingleton<domain_auth.AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthService>()),
  );
  getIt.registerLazySingleton<domain_user.UserRepository>(
    () => UserRepositoryImpl(),
  );
  getIt.registerLazySingleton<domain_receipt.ReceiptRepository>(
    () => ReceiptRepositoryImpl(),
  );

  // Use cases (features legadas)
  getIt.registerFactory<GetTransactionsPage>(
    () => GetTransactionsPage(getIt<TransactionsRepositoryFirestore>()),
  );

  // Use cases (domínio)
  getIt.registerFactory<CreateTransactionUseCase>(
    () => CreateTransactionUseCase(getIt<domain_tx.TransactionsRepository>()),
  );
  getIt.registerFactory<UpdateTransactionUseCase>(
    () => UpdateTransactionUseCase(getIt<domain_tx.TransactionsRepository>()),
  );
  getIt.registerFactory<DeleteTransactionUseCase>(
    () => DeleteTransactionUseCase(getIt<domain_tx.TransactionsRepository>()),
  );
  getIt.registerFactory<ListTransactionsUseCase>(
    () => ListTransactionsUseCase(getIt<domain_tx.TransactionsRepository>()),
  );
  getIt.registerFactory<GetSummaryUseCase>(
    () => GetSummaryUseCase(getIt<domain_tx.TransactionsRepository>()),
  );

  getIt.registerFactory<SignInUseCase>(() => SignInUseCase(getIt<domain_auth.AuthRepository>()));
  getIt.registerFactory<SignOutUseCase>(() => SignOutUseCase(getIt<domain_auth.AuthRepository>()));
  getIt.registerFactory<RegisterUserUseCase>(() => RegisterUserUseCase(getIt<domain_auth.AuthRepository>()));

  getIt.registerFactory<GetProfileUseCase>(() => GetProfileUseCase(getIt<domain_user.UserRepository>()));
  getIt.registerFactory<UpdateProfileUseCase>(() => UpdateProfileUseCase(getIt<domain_user.UserRepository>()));
}