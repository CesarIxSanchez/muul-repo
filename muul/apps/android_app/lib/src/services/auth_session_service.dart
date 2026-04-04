import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import 'muul_api_client.dart';

class AuthSessionService {
  AuthSessionService({
    SupabaseClient? client,
    MuulApiClient? apiClient,
  })  : _client = client ?? Supabase.instance.client,
        _apiClient = apiClient ?? MuulApiClient(AppConstants.prodApiBaseUrl);

  final SupabaseClient _client;
  final MuulApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _refreshKey = 'muul_refresh_token';
  static const _accessKey = 'muul_access_token';

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Future<void> restoreSession() async {
    if (_client.auth.currentSession != null) return;
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null || refresh.isEmpty) return;

    try {
      await _client.auth.refreshSession(refresh);
    } catch (_) {
      await _storage.delete(key: _refreshKey);
    }
  }

  Future<void> saveSessionTokens() async {
    final refresh = _client.auth.currentSession?.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: refresh);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    await saveSessionTokens();
  }

  Future<void> signUp({
    required String email,
    required String password,
    String userType = 'usuario',
  }) async {
    // Registrar usuario en Supabase Auth
    await _client.auth.signUp(email: email, password: password);
    
    // Actualizar metadata con el tipo de usuario
    await _client.auth.updateUser(
      UserAttributes(
        data: {'tipo': userType},
      ),
    );
    
    // Refrescar la sesión para obtener JWT actualizado con la metadata
    final session = _client.auth.currentSession;
    if (session?.refreshToken != null) {
      await _client.auth.refreshSession(session!.refreshToken!);
    }
    
    await saveSessionTokens();
  }

  Future<Map<String, dynamic>> signUpViaApi({
    required String email,
    required String password,
    required String nombre,
    required String tipo,
    String idioma = 'es',
  }) async {
    final response = await _apiClient.registerViaApi(
      email: email,
      password: password,
      nombre: nombre,
      tipo: tipo,
      idioma: idioma,
    );
    return response;
  }

  Future<Map<String, dynamic>> signInViaApi({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.loginViaApi(
      email: email,
      password: password,
    );
    
    // Guardar access token
    if (response['access_token'] != null) {
      await _storage.write(key: _accessKey, value: response['access_token']);
    }
    
    // Guardar refresh token
    if (response['refresh_token'] != null) {
      await _storage.write(key: _refreshKey, value: response['refresh_token']);
    }
    
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await _storage.delete(key: _refreshKey);
  }

  /// Limpia tokens almacenados sin llamar a Supabase signOut
  /// (para usar cuando el evento de sign out ya fue disparado)
  Future<void> clearStoredTokens() async {
    await _storage.delete(key: _refreshKey);
  }

  Future<String?> ensureValidAccessToken() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      // Intenta obtener del almacenamiento si existe
      return await _storage.read(key: _accessKey);
    }

    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      if (DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 1)))) {
        final refresh = await _storage.read(key: _refreshKey);
        await _client.auth.refreshSession(refresh);
        await saveSessionTokens();
      }
    }

    return _client.auth.currentSession?.accessToken;
  }

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;
}
