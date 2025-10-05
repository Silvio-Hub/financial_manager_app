import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
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
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;
  UserProvider? _userProvider;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // Escutar mudanças no estado de autenticação do Firebase
    _authService.authStateChanges.listen((firebase_auth.User? firebaseUser) {
      if (firebaseUser != null) {
        _user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName,
        );
        _saveUser();
      } else {
        _user = null;
        _clearUser();
      }
      notifyListeners();
    });
  }

  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  Future<void> _clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
    } catch (e) {
      debugPrint('Erro ao limpar dados do usuário: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      
      if (userCredential != null && userCredential.user != null) {
        // O usuário será automaticamente definido pelo listener authStateChanges
        return true;
      } else {
        _setError('Falha no login');
        return false;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Usuário não encontrado';
          break;
        case 'wrong-password':
          errorMessage = 'Senha incorreta';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido';
          break;
        case 'user-disabled':
          errorMessage = 'Usuário desabilitado';
          break;
        default:
          errorMessage = 'Erro ao fazer login: ${e.message}';
      }
      _setError(errorMessage);
      return false;
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
      final userCredential = await _authService.createUserWithEmailAndPassword(email, password);
      
      if (userCredential != null && userCredential.user != null) {
        // Atualizar o nome do usuário no Firebase
        await userCredential.user!.updateDisplayName(name);
        await userCredential.user!.reload();
        
        // Criar usuário no UserProvider
        if (_userProvider != null) {
          await _userProvider!.createUser(
            id: userCredential.user!.uid,
            email: email,
            name: name,
          );
        }
        
        return true;
      } else {
        _setError('Falha no registro');
        return false;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'A senha é muito fraca';
          break;
        case 'email-already-in-use':
          errorMessage = 'Este email já está em uso';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operação não permitida';
          break;
        default:
          errorMessage = 'Erro ao registrar: ${e.message}';
      }
      _setError(errorMessage);
      return false;
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
      await _authService.signOut();
      
      // Limpar dados locais
      await _clearUser();
      
      // Limpar dados do UserProvider
      if (_userProvider != null) {
        await _userProvider!.clearUser();
      }
      
      // O usuário será automaticamente definido como null pelo listener authStateChanges
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