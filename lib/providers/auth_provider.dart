import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_provider.dart';

class User {
  final String id;
  final String email;
  final String? name;

  User({
    required this.id,
    required this.email,
    this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
    );
  }
}

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  UserProvider? _userProvider;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _loadUser();
  }

  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  Future<void> _loadUser() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email');
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('user_name');

      if (userEmail != null && userId != null) {
        _user = User(
          id: userId,
          email: userEmail,
          name: userName,
        );
      }
    } catch (e) {
      _setError('Erro ao carregar usuário: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulação de login - em um app real, você faria uma chamada para API
      await Future.delayed(const Duration(seconds: 1));

      // Validação simples para demonstração
      if (email.isNotEmpty && password.length >= 6) {
        final userId = DateTime.now().millisecondsSinceEpoch.toString();
        final userName = email.split('@')[0];
        
        _user = User(
          id: userId,
          email: email,
          name: userName,
        );

        await _saveUser();
        
        // Criar usuário no UserProvider
        if (_userProvider != null) {
          await _userProvider!.createUser(
            id: userId,
            email: email,
            name: userName,
          );
        }
        
        return true;
      } else {
        _setError('Email ou senha inválidos');
        return false;
      }
    } catch (e) {
      _setError('Erro ao fazer login: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulação de registro - em um app real, você faria uma chamada para API
      await Future.delayed(const Duration(seconds: 1));

      if (email.isNotEmpty && password.length >= 6 && name.isNotEmpty) {
        final userId = DateTime.now().millisecondsSinceEpoch.toString();
        
        _user = User(
          id: userId,
          email: email,
          name: name,
        );

        await _saveUser();
        
        // Criar usuário no UserProvider
        if (_userProvider != null) {
          await _userProvider!.createUser(
            id: userId,
            email: email,
            name: name,
          );
        }
        
        return true;
      } else {
        _setError('Dados inválidos para registro');
        return false;
      }
    } catch (e) {
      _setError('Erro ao registrar: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      
      // Limpar dados do UserProvider
      if (_userProvider != null) {
        await _userProvider!.clearUser();
      }
      
      _user = null;
    } catch (e) {
      _setError('Erro ao fazer logout: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveUser() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', _user!.email);
      await prefs.setString('user_id', _user!.id);
      if (_user!.name != null) {
        await prefs.setString('user_name', _user!.name!);
      }
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}