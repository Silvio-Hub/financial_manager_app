# Financial Manager

Aplicativo Flutter para gestão financeira pessoal, com autenticação, cadastro de transações (receitas e despesas), gráficos interativos e upload de comprovantes. Suporta múltiplas plataformas (Android, iOS, Web, Windows, macOS, Linux) e integrações com Firebase.

## Visão Geral

- Autenticação por e-mail e senha
- Cadastro, edição e listagem de transações
- Sumário financeiro com gráficos de barras, linhas e pizza
- Formatação de moeda brasileira (`R$`) padronizada
- Upload de comprovantes (recibos) com armazenamento
- Tema claro/escuro e modo sistema
- Responsividade e animações suaves

## Tecnologias

- Flutter 3.x
- Firebase (Authentication, Firestore, Storage)
- Provider (gerência de estado)
- Material Design (Material 3)

## Estrutura de Pastas

```
lib/
  constants/         # Cores, dimensões, strings
  models/            # Modelos (Transação, Usuário, Sumário)
  providers/         # Providers (Auth, Financeiro, Settings, Theme)
  screens/           # Telas (Login, Dashboard, Transações, Perfil, etc.)
  services/          # Serviços (Auth, Firestore, Storage, Logger)
  themes/            # Tema claro/escuro
  utils/             # Utilitários (Formatters, Validators)
  widgets/           # Widgets reutilizáveis
```

## Pré-requisitos

- Flutter SDK instalado e configurado
- Conta Firebase com projeto criado
- Node não é necessário para o app Flutter (apenas para ferramentas web opcionais)

## Configuração do Firebase

1. Execute `flutterfire configure` e selecione o projeto Firebase.
2. Verifique que `lib/firebase_options.dart` foi gerado.
3. Android: inclua `android/app/google-services.json` (já presente) e garanta o plugin do Google Services.
4. iOS: configure `Runner/Info.plist` e adicione o `GoogleService-Info.plist` se necessário.
5. Firestore e Storage: habilite no console e ajuste regras conforme `firestore.rules` e `storage.rules`.

Guias úteis:

- `FIREBASE_SETUP_GUIDE.md`
- `FIREBASE_STORAGE_SETUP_GUIDE.md`
- `TRANSACTIONS_FIRESTORE_GUIDE.md`

## Como Rodar

Instale dependências:

```
flutter pub get
```

Executar em Web (Chrome):

```
flutter run -d chrome
```

Executar em Android (emulador/dispositivo):

```
flutter run -d android
```

Executar em iOS (macOS):

```
flutter run -d ios
```

Desktop (Windows/macOS/Linux), conforme seu sistema:

```
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

## Variáveis e Ambiente (Windows)

Alguns plugins de Flutter precisam de suporte a symlink. Em Windows:

- Ative o “Developer Mode” (Configurações > Privacidade e segurança > Para desenvolvedores > Modo desenvolvedor)
- Se necessário, ajuste o cache do pub: `PUB_CACHE` (ex.: `D:\PubCache`)

Comandos úteis:

```
flutter clean
dart pub cache repair
flutter pub get
```

## Funcionalidades Principais

- Login e Registro: `lib/screens/login_screen.dart`, `lib/providers/auth_provider.dart`
- Dashboard e Gráficos: `lib/screens/dashboard_screen.dart`, `lib/widgets/*_chart.dart`
- Listagem e Filtros: `lib/screens/transactions_list_screen.dart`
- Formulário de Transação: `lib/screens/add_edit_transaction_screen.dart`
- Upload de Recibo: `lib/widgets/receipt_upload_widget.dart`, `lib/services/storage_service.dart`
- Formatação de Moeda: `lib/utils/formatters.dart (formatCurrency)`
- Temas: `lib/themes/app_theme.dart`, `lib/providers/theme_provider.dart`

## Convenções e Qualidade

- Análise estática:

```
flutter analyze
```

- Formatação (se configurado):

```
dart format .
```

- Testes:

```
flutter test
```

## Resolução de Problemas

Erro Gradle/Plugins (ex.: `flutter_plugin_android_lifecycle` com “different root”):

- Ative symlink (Developer Mode) no Windows
- Ajuste `PUB_CACHE` (ex.: `D:\PubCache`)
- Rode: `flutter clean && dart pub cache repair && flutter pub get`

Sem logs/ruído de debug:

- `LoggerService` atua como no-op de produção

FAB sobrepondo gráficos no Android:

- Foi adicionado espaçamento extra no `dashboard_screen.dart` para evitar sobreposição

## Segurança

- Verifique `firestore.rules` e `storage.rules`
- Use regras restritivas em produção

## Roadmap (Sugestões)

- Múltiplos perfis/contas
- Exportação/importação de dados
- Notificações e lembretes
- Internacionalização (i18n)
