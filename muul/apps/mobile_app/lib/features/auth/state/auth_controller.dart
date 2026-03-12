import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:services/services.dart';

enum AuthStatus {
  loading,
  unauthenticated,
  authenticated,
}

class AuthController extends ChangeNotifier {
  AuthController(this._authService);

  final AuthService _authService;

  AuthStatus _status = AuthStatus.loading;
  User? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final result = await _authService.restoreSession();
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _currentUser = result.data;
    _status = _currentUser == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final result = await _authService.login(email: email, password: password);
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }

    _currentUser = result.data;
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final result = await _authService.register(
      email: email,
      password: password,
      displayName: displayName,
    );

    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }

    _currentUser = result.data;
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> updateProfile({
    required String displayName,
    String? bio,
    required String preferredLanguage,
  }) async {
    final user = _currentUser;
    if (user == null) {
      _errorMessage = 'No hay una sesion activa.';
      notifyListeners();
      return false;
    }

    final result = await _authService.updateProfile(
      user,
      displayName: displayName,
      bio: bio,
      preferredLanguage: preferredLanguage,
    );

    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }

    _currentUser = result.data;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    final result = await _authService.logout();
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return;
    }

    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
