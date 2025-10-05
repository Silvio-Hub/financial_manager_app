import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/logger_service.dart';

class UserProvider with ChangeNotifier {
  User _user = User.empty();
  bool _isLoading = false;
  String? _error;

  User get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUser => !_user.isEmpty;

  static const String _userKey = 'user_data';

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadUserFromLocal() async {
    _setLoading(true);
    _setError(null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        _user = User.fromJson(userMap);
        LoggerService.debug(
          'Dados do usuário carregados do armazenamento local',
        );
      } else {
        LoggerService.debug(
          'Nenhum dado de usuário encontrado no armazenamento local',
        );
        _user = User.empty();
      }
    } catch (e) {
      LoggerService.error('Erro ao carregar dados do usuário: $e', e);
      _setError('Erro ao carregar dados do usuário');
      _user = User.empty();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveUserToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(_user.toJson());
      await prefs.setString(_userKey, userJson);
      LoggerService.debug('Dados do usuário salvos no armazenamento local');
    } catch (e) {
      LoggerService.error('Erro ao salvar dados do usuário: $e', e);
    }
  }

  Future<void> updateUser({
    String? name,
    String? phone,
    String? profileImageUrl,
    DateTime? birthDate,
    String? occupation,
    String? bio,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final updatedUser = _user.copyWith(
        name: name,
        phone: phone,
        profileImageUrl: profileImageUrl,
        birthDate: birthDate,
        occupation: occupation,
        bio: bio,
        updatedAt: DateTime.now(),
      );

      _user = updatedUser;

      await _saveUserToLocal();

      LoggerService.debug('Dados do usuário atualizados com sucesso');
      notifyListeners();
    } catch (e) {
      LoggerService.error('Erro ao atualizar dados do usuário: $e', e);
      _setError('Erro ao atualizar dados do usuário');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setUser(User user) async {
    _setLoading(true);
    _setError(null);

    try {
      _user = user;
      await _saveUserToLocal();
      LoggerService.debug('Usuário definido: ${user.name}');
      notifyListeners();
    } catch (e) {
      LoggerService.error('Erro ao definir usuário: $e', e);
      _setError('Erro ao definir usuário');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createUser({
    required String id,
    required String email,
    required String name,
    String? phone,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final newUser = User(
        id: id,
        email: email,
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _user = newUser;
      await _saveUserToLocal();

      LoggerService.debug('Novo usuário criado: $name');
      notifyListeners();
    } catch (e) {
      LoggerService.error('Erro ao criar usuário: $e', e);
      _setError('Erro ao criar usuário');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearUser() async {
    try {
      _user = User.empty();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      LoggerService.debug('Dados do usuário limpos');
      notifyListeners();
    } catch (e) {
      LoggerService.error('Erro ao limpar dados do usuário: $e', e);
    }
  }

  Future<void> updateProfileImage(String imageUrl) async {
    await updateUser(profileImageUrl: imageUrl);
  }

  Future<void> removeProfileImage() async {
    await updateUser(profileImageUrl: null);
  }

  bool get isProfileComplete {
    return _user.name.isNotEmpty && _user.email.isNotEmpty;
  }

  double get profileCompleteness {
    int filledFields = 0;
    int totalFields = 7;

    if (_user.name.isNotEmpty) filledFields++;
    if (_user.email.isNotEmpty) filledFields++;
    if (_user.phone != null && _user.phone!.isNotEmpty) filledFields++;
    if (_user.birthDate != null) filledFields++;
    if (_user.occupation != null && _user.occupation!.isNotEmpty)
      filledFields++;
    if (_user.bio != null && _user.bio!.isNotEmpty) filledFields++;
    if (_user.profileImageUrl != null && _user.profileImageUrl!.isNotEmpty)
      filledFields++;

    return filledFields / totalFields;
  }

  Map<String, dynamic> get userStats {
    return {
      'profileCompleteness': (profileCompleteness * 100).round(),
      'memberSince': _user.createdAt,
      'lastUpdate': _user.updatedAt,
      'hasProfileImage': _user.profileImageUrl != null,
      'age': _user.age,
    };
  }
}
