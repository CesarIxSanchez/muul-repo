import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/profile_models.dart';
import 'auth_session_service.dart';
import 'muul_api_client.dart';

class ProfileService {
  ProfileService({
    SupabaseClient? client,
    AuthSessionService? authService,
    MuulApiClient? apiClient,
    String? apiBaseUrl,
  })  : _client = client ?? Supabase.instance.client,
        _authService = authService,
        _apiClient = apiClient ?? MuulApiClient(apiBaseUrl ?? AppConstants.prodApiBaseUrl);

  final SupabaseClient _client;
  final AuthSessionService? _authService;
  final MuulApiClient _apiClient;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('No hay sesión activa');
    return id;
  }

  Future<UserProfile?> getMyUserProfile() async {
    final data = await _client.from('perfiles').select().eq('id', _uid).maybeSingle();
    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  Future<UserProfile> createUserProfile({
    required String username,
    required UserGender gender,
    String language = 'es-MX',
    String userType = 'usuario',
  }) async {
    try {
      // Convertir language al formato correcto (solo código de idioma)
      // De 'es-MX' a 'es', de 'en-US' a 'en', etc.
      final idioma = language.split('-').first;

      // El trigger handle_new_user() ya creó el perfil en perfiles
      // Solo necesitamos actualizar el tipo de usuario y otros campos
      
      final data = await _client
          .from('perfiles')
          .update({
            'nombre': username,
            'tipo': userType,
            'idioma': idioma,
          })
          .eq('id', _uid)
          .select()
          .single();
      
      return UserProfile.fromMap(data);
    } on PostgrestException catch (e) {
      throw Exception('Error actualizando perfil: ${e.message}');
    } catch (e) {
      throw Exception('Error actualizando perfil: $e');
    }
  }

  Future<UserProfile> updateUserProfile({
    String? newUsername,
    UserGender? gender,
    String? language,
    String? avatarUrl,
  }) async {
    final current = await getMyUserProfile();
    if (current == null) throw Exception('Perfil no encontrado');

    final updates = <String, dynamic>{};

    if (newUsername != null && newUsername.isNotEmpty && newUsername != current.username) {
      if (current.lastUsernameChangeDate != null &&
          DateTime.now().difference(current.lastUsernameChangeDate!).inDays < 30) {
        throw Exception('Solo puedes cambiar tu username una vez cada mes.');
      }
      updates['nombre'] = newUsername;
      updates['last_username_change_date'] = DateTime.now().toIso8601String();
    }

    if (language != null) {
      // Convertir al formato correcto: 'es-MX' → 'es'
      final idioma = language.split('-').first;
      updates['idioma'] = idioma;
    }
    if (avatarUrl != null) updates['foto_url'] = avatarUrl;

    if (updates.isEmpty) return current;

    try {
      final data = await _client.from('perfiles').update(updates).eq('id', _uid).select().single();
      return UserProfile.fromMap(data);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Ese nombre ya existe.');
      }
      rethrow;
    }
  }

  Future<BusinessProfile?> getMyBusinessProfile() async {
    final data = await _client.from('businesses').select().eq('id', _uid).maybeSingle();
    if (data == null) return null;
    return BusinessProfile.fromMap(data);
  }

  Future<BusinessProfile> registerBusiness({
    required String businessName,
    required String address,
    String language = 'es-MX',
    String? description,
    String? phone,
    String? schedule,
    String? website,
    String? instagram,
    String? collectionId,
    List<String>? amenities,
    double latitude = 0.0,
    double longitude = 0.0,
  }) async {
    // Obtener token JWT para la API REST
    final token = _authService?.currentSession?.accessToken ?? await _getSupabaseToken();
    if (token == null) throw Exception('No hay token de autenticación disponible');

    // Llamar a API REST para registrar el negocio
    final data = await _apiClient.registerBusiness(
      nombre: businessName.trim(),
      direccion: address.trim(),
      latitud: latitude,
      longitud: longitude,
      token: token,
      descripcion: description,
      telefonos: phone,
      horario: schedule,
      sitioWeb: website,
      instagram: instagram,
      coleccionId: collectionId,
      amenidades: amenities,
    );

    return BusinessProfile.fromMap(data);
  }

  Future<BusinessProfile> updateBusinessProfile({
    String? businessName,
    String? address,
    String? language,
    String? description,
    String? phone,
    String? schedule,
    String? website,
    String? instagram,
    String? collectionId,
    List<String>? amenities,
    double? latitude,
    double? longitude,
  }) async {
    // Obtener el negocio actual para tener su ID
    final currentBusiness = await getMyBusinessProfile();
    if (currentBusiness == null) throw Exception('No hay negocio registrado');

    // Obtener token JWT para la API REST
    final token = _authService?.currentSession?.accessToken ?? await _getSupabaseToken();
    if (token == null) throw Exception('No hay token de autenticación disponible');

    // Llamar a API REST para actualizar el negocio
    final data = await _apiClient.updateBusiness(
      businessId: currentBusiness.id,
      token: token,
      nombre: businessName,
      direccion: address,
      descripcion: description,
      telefonos: phone,
      horario: schedule,
      sitioWeb: website,
      instagram: instagram,
      coleccionId: collectionId,
      amenidades: amenities,
      latitud: latitude,
      longitud: longitude,
    );

    return BusinessProfile.fromMap(data);
  }

  /// Registra el negocio directamente en Supabase. Forma simplificada para debuggear RLS.
  Future<BusinessProfile> registerBusinessDirect({
    required String businessName,
    required String address,
    String language = 'es-MX',
    String? description,
    String? phone,
    String? schedule,
    String? website,
    String? instagram,
    String? collectionId,
    List<String>? amenities,
    double latitude = 0.0,
    double longitude = 0.0,
  }) async {
    try {
      // Verificar que el perfil está actualizado
      final profile = await getMyUserProfile();
      if (profile == null) {
        throw Exception('Perfil no encontrado. Registrate nuevamente.');
      }
      if (profile.tipo != 'empresa') {
        throw Exception('Tu tipo debe ser "empresa". Actual: ${profile.tipo}');
      }

      // Inserción muy simple: solo campos OBLIGATORIOS
      final businessData = {
        'propietario_id': _uid,
        'nombre': businessName.trim(),
        'latitud': latitude,
        'longitud': longitude,
        'activo': true,
      };

      final response = await _client
          .from('negocios')
          .insert(businessData)
          .select()
          .single();

      return BusinessProfile.fromMap(response);
    } on PostgrestException catch (e) {
      final errorMsg = '''
RLS Error: ${e.message}
Código: ${e.code}
Usuario: $_uid
Intenta:
1. Verifica que tu perfil tiene tipo='empresa'
2. Contacta a soporte con el código ${e.code}
      ''';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<String?> _getSupabaseToken() async {
    return _client.auth.currentSession?.accessToken;
  }
}
