import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logger_service.dart';
import 'settings_provider.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  SettingsProvider? _settingsProvider;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  bool get isLightMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.light;
    }
    return _themeMode == ThemeMode.light;
  }
  
  bool get isSystemMode => _themeMode == ThemeMode.system;
  
  ThemeProvider() {
    _loadThemeMode();
  }

  void updateFromSettings(SettingsProvider settingsProvider) {
    _settingsProvider = settingsProvider;
    if (_themeMode != settingsProvider.themeMode) {
      _themeMode = settingsProvider.themeMode;
      notifyListeners();
    }
  }
  
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeKey);
      
      if (themeModeString != null) {
        _themeMode = _getThemeModeFromString(themeModeString);
        notifyListeners();
      }
    } catch (e) {
      LoggerService.error('Erro ao carregar tema: $e', e);
    }
  }
  
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;
    
    _themeMode = themeMode;
    notifyListeners();
    
    // Sincronizar com SettingsProvider se disponível
    if (_settingsProvider != null) {
      await _settingsProvider!.setThemeMode(themeMode);
    } else {
      // Fallback para SharedPreferences direto
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_themeKey, _getStringFromThemeMode(themeMode));
      } catch (e) {
        LoggerService.error('Erro ao salvar tema: $e', e);
      }
    }
  }
  
  Future<void> toggleTheme() async {
    final newThemeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await setThemeMode(newThemeMode);
  }
  
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }
  
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }
  
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
  
  String _getStringFromThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
  
  ThemeMode _getThemeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }
  
  String get currentThemeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }
  
  IconData get currentThemeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}