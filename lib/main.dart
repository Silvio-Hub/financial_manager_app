import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/financial_provider.dart';
import 'providers/user_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Verificar se o Firebase já foi inicializado
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Se o Firebase já foi inicializado, continuar normalmente
    if (e.toString().contains('duplicate-app')) {
      // Firebase já foi inicializado, continuar normalmente
    } else {
      rethrow;
    }
  }
  
  runApp(const FinancialManagerApp());
}

class FinancialManagerApp extends StatelessWidget {
  const FinancialManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, ThemeProvider>(
          create: (_) => ThemeProvider(),
          update: (_, settings, theme) {
            theme?.updateFromSettings(settings);
            return theme!;
          },
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FinancialProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Financial Manager',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt', 'BR'),
              Locale('en', 'US'),
            ],
            locale: const Locale('pt', 'BR'),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Conectar os providers após a inicialização
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      authProvider.setUserProvider(userProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Mostrar loading enquanto verifica o estado de autenticação
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Se usuário está logado, mostrar dashboard
        if (authProvider.isAuthenticated) {
          return const DashboardScreen();
        }
        
        // Se não está logado, mostrar tela de login
        return const LoginScreen();
      },
    );
  }
}
