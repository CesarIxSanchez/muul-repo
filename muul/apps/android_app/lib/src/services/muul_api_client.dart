import 'dart:convert';

import 'package:http/http.dart' as http;

class MuulApiClient {
  MuulApiClient(this.baseUrl);

  final String baseUrl;

  Future<bool> checkHealth() async {
    final uri = Uri.parse(baseUrl.replaceFirst('/api/v1', '/health'));
    final response = await http.get(uri);
    return response.statusCode == 200;
  }

  Future<List<dynamic>> fetchPois({String? token}) async {
    final uri = Uri.parse('$baseUrl/pois');
    final response = await http.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 400) {
      throw Exception('Error API /pois: ${response.statusCode}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> registerBusiness({
    required String nombre,
    required String direccion,
    required double latitud,
    required double longitud,
    required String token,
    String? descripcion,
    String? telefonos,
    String? horario,
    String? sitioWeb,
    String? instagram,
    String? coleccionId,
    List<String>? amenidades,
  }) async {
    final uri = Uri.parse('$baseUrl/negocios');
    final body = {
      'nombre': nombre,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
      if (telefonos != null && telefonos.isNotEmpty) 'telefonos': telefonos,
      if (horario != null && horario.isNotEmpty) 'horario': horario,
      if (sitioWeb != null && sitioWeb.isNotEmpty) 'sitio_web': sitioWeb,
      if (instagram != null && instagram.isNotEmpty) 'instagram': instagram,
      if (coleccionId != null && coleccionId.isNotEmpty) 'coleccion_id': coleccionId,
      if (amenidades != null && amenidades.isNotEmpty) 'amenidades': amenidades,
    };

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw Exception('Error API /negocios POST: ${response.statusCode} - ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginViaApi({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final body = {
      'email': email,
      'password': password,
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw Exception('Error API /auth/login: ${response.statusCode} - ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerViaApi({
    required String email,
    required String password,
    required String nombre,
    required String tipo,
    String idioma = 'es',
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final body = {
      'email': email,
      'password': password,
      'nombre': nombre,
      'tipo': tipo,
      'idioma': idioma,
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw Exception('Error API /auth/register: ${response.statusCode} - ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBusiness({
    required String businessId,
    required String token,
    String? nombre,
    String? descripcion,
    String? direccion,
    double? latitud,
    double? longitud,
    String? telefonos,
    String? horario,
    String? sitioWeb,
    String? instagram,
    String? coleccionId,
    List<String>? amenidades,
  }) async {
    final uri = Uri.parse('$baseUrl/negocios/$businessId');
    final body = {
      if (nombre != null && nombre.isNotEmpty) 'nombre': nombre,
      if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
      if (direccion != null && direccion.isNotEmpty) 'direccion': direccion,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (telefonos != null && telefonos.isNotEmpty) 'telefonos': telefonos,
      if (horario != null && horario.isNotEmpty) 'horario': horario,
      if (sitioWeb != null && sitioWeb.isNotEmpty) 'sitio_web': sitioWeb,
      if (instagram != null && instagram.isNotEmpty) 'instagram': instagram,
      if (coleccionId != null && coleccionId.isNotEmpty) 'coleccion_id': coleccionId,
      if (amenidades != null && amenidades.isNotEmpty) 'amenidades': amenidades,
    };

    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw Exception('Error API /negocios PATCH: ${response.statusCode} - ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? nombre,
    String? fotoUrl,
    String? idioma,
  }) async {
    final uri = Uri.parse('$baseUrl/perfiles/me');
    final body = {
      if (nombre != null && nombre.isNotEmpty) 'nombre': nombre,
      if (fotoUrl != null && fotoUrl.isNotEmpty) 'foto_url': fotoUrl,
      if (idioma != null && idioma.isNotEmpty) 'idioma': idioma,
    };

    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw Exception('Error API /perfiles/me PATCH: ${response.statusCode} - ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProfile({required String token}) async {
    final uri = Uri.parse('$baseUrl/perfiles/me');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 400) {
      throw Exception('Error API /perfiles/me GET: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
