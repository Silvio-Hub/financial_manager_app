import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_widget.dart';
import '../widgets/radio_group.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Configurações',
        showBackButton: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const LoadingWidget(message: 'Carregando configurações...');
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Aparência'),
              _buildThemeSection(context, settingsProvider),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Preferências'),
              _buildPreferencesSection(context, settingsProvider),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Notificações'),
              _buildNotificationsSection(context, settingsProvider),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Segurança'),
              _buildSecuritySection(context, settingsProvider),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Dados'),
              _buildDataSection(context, settingsProvider),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Conta'),
              _buildAccountSection(context),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Tema'),
            subtitle: Text(provider.themeDisplayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Moeda'),
            subtitle: Text(provider.currencyDisplayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyDialog(context, provider),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Idioma'),
            subtitle: Text(provider.languageDisplayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notificações'),
            subtitle: const Text('Receber notificações do app'),
            value: provider.notificationsEnabled,
            onChanged: (value) => provider.setNotificationsEnabled(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometria'),
            subtitle: const Text('Usar impressão digital ou Face ID'),
            value: provider.biometricEnabled,
            onChanged: (value) => provider.setBiometricEnabled(value),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Alterar Senha'),
            subtitle: const Text('Modificar sua senha de acesso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.backup_outlined),
            title: const Text('Backup Automático'),
            subtitle: const Text('Fazer backup dos dados automaticamente'),
            value: provider.autoBackupEnabled,
            onChanged: (value) => provider.setAutoBackupEnabled(value),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Exportar Dados'),
            subtitle: const Text('Baixar seus dados em formato CSV'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showExportDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Limpar Cache'),
            subtitle: const Text('Remover dados temporários'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearCacheDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre o App'),
            subtitle: const Text('Versão 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ajuda e Suporte'),
            subtitle: const Text('Central de ajuda e contato'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHelpDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Fazer logout da conta'),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolher Tema'),
        content: CustomRadioGroup<ThemeMode>(
          groupValue: provider.themeMode,
          onChanged: (value) {
            if (value != null) {
              provider.setThemeMode(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Claro'),
                leading: RadioButton<ThemeMode>(
                  value: ThemeMode.light,
                ),
                onTap: () {
                  provider.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Escuro'),
                leading: RadioButton<ThemeMode>(
                  value: ThemeMode.dark,
                ),
                onTap: () {
                  provider.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Automático'),
                leading: RadioButton<ThemeMode>(
                  value: ThemeMode.system,
                ),
                onTap: () {
                  provider.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, SettingsProvider provider) {
    final currencies = [
      {'code': 'BRL', 'name': 'Real (R\$)'},
      {'code': 'USD', 'name': 'Dólar (\$)'},
      {'code': 'EUR', 'name': 'Euro (€)'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolher Moeda'),
        content: CustomRadioGroup<String>(
          groupValue: provider.currency,
          onChanged: (value) {
            if (value != null) {
              provider.setCurrency(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((currency) {
              return ListTile(
                title: Text(currency['name']!),
                leading: RadioButton<String>(
                  value: currency['code']!,
                ),
                onTap: () {
                  provider.setCurrency(currency['code']!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider provider) {
    final languages = [
      {'code': 'pt', 'name': 'Português'},
      {'code': 'en', 'name': 'English'},
      {'code': 'es', 'name': 'Español'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolher Idioma'),
        content: CustomRadioGroup<String>(
           groupValue: provider.language,
          onChanged: (value) {
            if (value != null) {
              provider.setLanguage(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((language) {
              return ListTile(
                title: Text(language['name']!),
                leading: RadioButton<String>(
                  value: language['code']!,
                ),
                onTap: () {
                  provider.setLanguage(language['code']!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Senha'),
        content: const Text('Esta funcionalidade será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Dados'),
        content: const Text('Deseja exportar todos os seus dados financeiros?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
              );
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Cache'),
        content: const Text('Isso irá remover dados temporários. Deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache limpo com sucesso')),
              );
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Financial Manager',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.account_balance_wallet, size: 48),
      children: [
        const Text('Um aplicativo para gerenciar suas finanças pessoais de forma simples e eficiente.'),
        const SizedBox(height: 16),
        const Text('Desenvolvido com Flutter e Firebase.'),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda e Suporte'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 Email: suporte@financialmanager.com'),
            SizedBox(height: 8),
            Text('📱 WhatsApp: (11) 99999-9999'),
            SizedBox(height: 8),
            Text('🌐 Site: www.financialmanager.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}