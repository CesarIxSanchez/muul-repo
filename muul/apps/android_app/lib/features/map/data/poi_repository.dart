// lib/features/map/data/poi_repository.dart

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/models/poi_model.dart';

class PoiRepository {
  final _supabase = Supabase.instance.client;

  // Busca lugares cercanos en Mapbox Search API
  Future<List<PoiModel>> fetchMapboxPois({
    required double lat,
    required double lng,
    double radiusMetros = 1000,
  }) async {
    // Categorías turísticas relevantes
    const categorias = 'restaurant,museum,historic,attraction,park,market,cafe';

    final uri = Uri.parse(
      '${AppConstants.mapboxSearchUrl}'
      '/$categorias'
      '?access_token=${AppConstants.mapboxToken}'
      '&proximity=$lng,$lat'
      '&limit=25'
      '&language=es',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final features = data['features'] as List? ?? [];

    return features
        .map((f) => PoiModel.fromMapbox(f as Map<String, dynamic>))
        .toList();
  }

  // Busca negocios locales registrados en Supabase
  Future<List<PoiModel>> fetchSupabasePois({
    required double lat,
    required double lng,
    double radioKm = 2.0,
  }) async {
    try {
      // Bounding box simple para filtrar por área
      final latDelta = radioKm / 111.0;
      final lngDelta = radioKm / (111.0 * cos(lat * pi / 180));

      final data = await _supabase
          .from('negocios')
          .select()
          .gte('latitud', lat - latDelta)
          .lte('latitud', lat + latDelta)
          .gte('longitud', lng - lngDelta)
          .lte('longitud', lng + lngDelta);

      return (data as List)
          .map((e) => PoiModel.fromSupabase(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Combina ambas fuentes
  Future<List<PoiModel>> fetchTodosPois({
    required double lat,
    required double lng,
  }) async {
    final results = await Future.wait([
      fetchMapboxPois(lat: lat, lng: lng),
      fetchSupabasePois(lat: lat, lng: lng),
    ]);
    return [...results[0], ...results[1]];
  }
}