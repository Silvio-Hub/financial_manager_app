import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logger_service.dart';

class SettingsProvider extends ChangeNotifier {
  // Chaves para SharedPreferences
  static const String _themeKey = 'theme_mode';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _biometricKey = 'biometric_enabled';
  static const String _autoBackupKey = 'auto_backup_enabled';
  static const String _currencyKey = 'currency';
  static const String _languageKey = 'language';

  // Estados das configurações
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _autoBackupEnabled = true;
  String _currency = 'BRL';
  String _language = 'pt';
  bool _isLoading = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get autoBackupEnabled => _autoBackupEnabled;
  String get currency => _currency;
  String get language => _language;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }

  // Carregar configurações do armazenamento local
  Future<void> _loadSettings() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Carregar tema
      final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
      _themeMode = ThemeMode.values[themeIndex];
      
      // Carregar outras configurações
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _biometricEnabled = prefs.getBool(_biometricKey) ?? false;
      _autoBackupEnabled = prefs.getBool(_autoBackupKey) ?? true;
      _currency = prefs.getString(_currencyKey) ?? 'BRL';
      _language = prefs.getString(_languageKey) ?? 'pt';
      
      LoggerService.debug('Configurações carregadas do armazenamento local');
    } catch (e) {
      LoggerService.error('Erro ao carregar configurações: $e', e);
    } finally {
      _setLoading(false);
    }
  }

  // Salvar configurações no armazenamento local
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt(_themeKey, _themeMode.index);
      await prefs.setBool(_notificationsKey, _notificationsEnabled);
      await prefs.setBool(_biometricKey, _biometricEnabled);
      await prefs.setBool(_autoBackupKey, _autoBackupEnabled);
      await prefs.setString(_currencyKey, _currency);
      await prefs.setString(_languageKey, _language);
      
      LoggerService.debug('Configurações salvas no armazenamento local');
    } catch (e) {
      LoggerService.error('Erro ao salvar configurações: $e', e);
    }
  }

  // Alterar tema
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode != themeMode) {
      _themeMode = themeMode;
      await _saveSettings();
      notifyListeners();
      LoggerService.debug('Tema alterado para: $themeMode');
    }
  }

  // Alterar notificações
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled != enabled) {
      _notificationsEnabled = enabled;
      await _saveSettings();
      notifyListeners();
      LoggerService.debug('Notificações ${enabled ? 'ativadas' : 'desativadas'}');
    }
  }

  // Alterar biometria
  Future<void> setBiometricEnabled(bool enabled) async {
    if (_biometricEnabled != enabled) {
      _biometricEnabled = enabled;
      await _saveSettings();
      notifyListeners();
      LoggerService.debug('Biometria ${enabled ? 'ativada' : 'desativada'}');
    }
  }

  // Alterar backup automático
  Future<void> setAutoBackupEnabled(bool enabled) async {
    if (_autoBackupEnabled != enabled) {
      _autoBackupEnabled = enabled;
      await _saveSettings();
      notifyListeners();
      LoggerService.debug('Backup automático ${enabled ? 'ativado' : 'desativado'}');
    }
  }

  // Alterar moeda
  Future<void> setCurrency(String currency) async {
    if (_currency != currency) {
      _currency = currency;
      await _saveSettings();
      notifyListeners();
      LoggerService.debug('Moeda alterada para: $currency');
    }
  }

  // Alterar idioma
  Future<void> setLanguage(String language) async {
    if (_language != language) {
      _language = language;
      await _saveSettings();
      notifyListeners();
      LoggerService.debug('Idioma alterado para: $language');
    }
  }

  // Resetar todas as configurações
  Future<void> resetSettings() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remover todas as chaves de configuração
      await prefs.remove(_themeKey);
      await prefs.remove(_notificationsKey);
      await prefs.remove(_biometricKey);
      await prefs.remove(_autoBackupKey);
      await prefs.remove(_currencyKey);
      await prefs.remove(_languageKey);
      
      // Restaurar valores padrão
      _themeMode = ThemeMode.system;
      _notificationsEnabled = true;
      _biometricEnabled = false;
      _autoBackupEnabled = true;
      _currency = 'BRL';
      _language = 'pt';
      
      LoggerService.debug('Configurações resetadas para os valores padrão');
      notifyListeners();
    } catch (e) {
      LoggerService.error('Erro ao resetar configurações: $e', e);
    } finally {
      _setLoading(false);
    }
  }

  // Obter nome do tema atual
  String get themeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Automático';
    }
  }

  // Obter nome da moeda atual
  String get currencyDisplayName {
    switch (_currency) {
      case 'BRL':
        return 'Real (R\$)';
      case 'USD':
        return 'Dólar (\$)';
      case 'EUR':
        return 'Euro (€)';
      default:
        return _currency;
    }
  }

  // Obter nome do idioma atual
  String get languageDisplayName {
    switch (_language) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return _language;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}