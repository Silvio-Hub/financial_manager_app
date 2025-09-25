import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Manager'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return PopupMenuButton<ThemeMode>(
                icon: Icon(themeProvider.currentThemeIcon),
                tooltip: 'Alterar tema',
                onSelected: (ThemeMode mode) {
                  themeProvider.setThemeMode(mode);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: ThemeMode.light,
                    child: Row(
                      children: [
                        Icon(
                          Icons.light_mode,
                          color: themeProvider.themeMode == ThemeMode.light
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Claro',
                          style: TextStyle(
                            color: themeProvider.themeMode == ThemeMode.light
                                ? Theme.of(context).primaryColor
                                : null,
                            fontWeight: themeProvider.themeMode == ThemeMode.light
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ThemeMode.dark,
                    child: Row(
                      children: [
                        Icon(
                          Icons.dark_mode,
                          color: themeProvider.themeMode == ThemeMode.dark
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Escuro',
                          style: TextStyle(
                            color: themeProvider.themeMode == ThemeMode.dark
                                ? Theme.of(context).primaryColor
                                : null,
                            fontWeight: themeProvider.themeMode == ThemeMode.dark
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ThemeMode.system,
                    child: Row(
                      children: [
                        Icon(
                          Icons.brightness_auto,
                          color: themeProvider.themeMode == ThemeMode.system
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sistema',
                          style: TextStyle(
                            color: themeProvider.themeMode == ThemeMode.system
                                ? Theme.of(context).primaryColor
                                : null,
                            fontWeight: themeProvider.themeMode == ThemeMode.system
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao fazer logout: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Boas-vindas
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bem-vindo!',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.displayName ?? user?.email ?? 'Usuário',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Resumo financeiro (placeholder)
            Text(
              'Resumo Financeiro',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: AppColors.income,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Receitas',
                            style: TextStyle(
                              color: AppColors.income,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'R\$ 0,00',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.income,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.trending_down,
                            color: AppColors.expense,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Despesas',
                            style: TextStyle(
                              color: AppColors.expense,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'R\$ 0,00',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.expense,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Ações rápidas
            Text(
              'Ações Rápidas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidade em desenvolvimento'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nova Receita'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.income,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidade em desenvolvimento'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove),
                    label: const Text('Nova Despesa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.expense,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}