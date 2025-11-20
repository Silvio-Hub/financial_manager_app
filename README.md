# Financial Manager

Aplicativo Flutter para gestão financeira pessoal, com autenticação, transações (receitas/despesas), gráficos e upload de comprovantes. Suporta Android, iOS, Web e Desktop.

## Visão Geral
- Autenticação por e-mail/senha
- Cadastro, edição e listagem de transações
- Sumário financeiro com gráficos de barras/linhas/pizza
- Upload de comprovantes (Storage)
- Tema claro/escuro e responsividade

## Novidades recentes
- Clean Architecture iniciada para Transações
- Riverpod integrado (convivendo com Provider)
- Injeção de dependências com GetIt (`lib/bootstrap.dart`)
- Repositório de Transações com paginação e filtros (Firestore)
- Persistência offline habilitada no Web (Firestore Settings API)

## Tecnologias
- Flutter 3.x
- Firebase: Authentication, Firestore, Storage
- Estado: Provider (módulos existentes) + Riverpod (novas features)
- DI: GetIt
- UI: Material Design

## Estrutura de Pastas (resumo)
```
lib/
  bootstrap.dart                # Registros de DI (GetIt)
  constants/                    # Cores, dimensões, strings
  features/
    transactions/
      domain/                   # Contratos e casos de uso
        repositories/transactions_repository.dart
        usecases/get_transactions_page.dart
      infra/                    # Implementações (Firestore)
        transactions_repository_firestore.dart
      presentation/
        providers/transactions_providers.dart
  models/                       # Transaction, User, Summary
  providers/                    # Providers (Provider)
  screens/                      # Login, Dashboard, Transações, Perfil
  services/                     # Auth, Firestore, Storage, Logger
  widgets/, themes/, utils/
```

## Dependências principais
- `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`
- `provider`
- `flutter_riverpod`
- `get_it`
- `rxdart`
- `cached_network_image`
- Outras: `intl`, `fl_chart`, `email_validator`, `file_picker`, `image_picker`, `path`, `syncfusion_flutter_pdfviewer`

Consulte `pubspec.yaml` para versões e a lista completa.

## Pré-requisitos
- Flutter SDK instalado
- Projeto Firebase configurado
- Windows: habilite "Developer Mode" para suporte a symlinks

## Instalação
```
flutter pub get
flutter analyze
```

## Configuração do Firebase
1) Execute `flutterfire configure` e confirme `lib/firebase_options.dart`
2) Android: `android/app/google-services.json` e plugin do Google Services
3) iOS: `GoogleService-Info.plist` e ajustes em `Runner/Info.plist`
4) Habilite Firestore/Storage e ajuste regras: `firestore.rules`, `storage.rules`

Guias:
- `FIREBASE_SETUP_GUIDE.md`
- `FIREBASE_STORAGE_SETUP_GUIDE.md`
- `TRANSACTIONS_FIRESTORE_GUIDE.md`

## Estado e DI
- Provider permanece para módulos existentes
- Riverpod adicionado para Transações e novas features. Em `main.dart` usamos alias apenas para `ProviderScope`:
  - `import 'package:flutter_riverpod/flutter_riverpod.dart' as rp show ProviderScope;`
  - `runApp(const rp.ProviderScope(child: FinancialManagerApp()));`
- DI: `setupDependencies(FirestoreService())` registra serviços, repositórios e casos de uso (GetIt)

## Transações (paginação)
- Contrato: `features/transactions/domain/repositories/transactions_repository.dart`
- Caso de uso: `features/transactions/domain/usecases/get_transactions_page.dart`
- Infra Firestore: `features/transactions/infra/transactions_repository_firestore.dart`
- Estado: `features/transactions/presentation/providers/transactions_providers.dart`
- Coleção explícita: `FirestoreService.transactionsCollectionFor(userId)`

## Persistência no Web
- `main.dart` (API moderna):
  - `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, ignoreUndefinedProperties: true);`

## Como Rodar
```
flutter run -d chrome    # Web
flutter run -d android   # Android
flutter run -d ios       # iOS (macOS)
flutter run -d windows   # Windows
flutter run -d macos     # macOS
flutter run -d linux     # Linux
```

## Convenções e Qualidade
- Análise estática: `flutter analyze`
- Formatação (se configurado): `dart format .`
- Testes: `flutter test`

## Resolução de Problemas
- Plugins no Windows: habilite symlink (Developer Mode)
- Cache do pub: `flutter clean && dart pub cache repair && flutter pub get`
- Conflito `Consumer` (Provider vs Riverpod): use alias `rp.ProviderScope` (já aplicado)
- Firestore: use `Settings.persistenceEnabled` ao invés de `enablePersistence`

## Funcionalidades Principais
- Login/Registro: `lib/screens/login_screen.dart`, `lib/providers/auth_provider.dart`
- Dashboard e gráficos: `lib/screens/dashboard_screen.dart`, `lib/widgets/*_chart.dart`
- Listagem/Filtros: `lib/screens/transactions_list_screen.dart`
- Formulário: `lib/screens/add_edit_transaction_screen.dart`
- Upload de recibo: `lib/widgets/receipt_upload_widget.dart`, `lib/services/storage_service.dart`
- Formatação de moeda: `lib/utils/formatters.dart`
- Temas: `lib/themes/app_theme.dart`, `lib/providers/theme_provider.dart`

## Segurança
- Revise `firestore.rules` e `storage.rules` antes de produção

## Roadmap
- Múltiplos perfis/contas
- Exportação/importação de dados
- Notificações e lembretes
- Internacionalização (i18n)
