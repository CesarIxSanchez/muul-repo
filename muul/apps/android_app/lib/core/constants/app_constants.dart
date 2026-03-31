// lib/core/constants/app_constants.dart
import 'env.dart';

class AppConstants {
  static const String mapboxToken = mapboxPublicToken;

  static const String mapboxStyleDark =
      'mapbox://styles/mapbox/dark-v11';
  static const String mapboxDirectionsUrl =
      'https://api.mapbox.com/directions/v5/mapbox/walking';
  static const String mapboxSearchUrl =
      'https://api.mapbox.com/search/searchbox/v1/category';

  static const String supabaseUrl =
      'https://TU_PROYECTO.supabase.co';
  static const String supabaseAnonKey = 'TU_ANON_KEY';

  static const double geofenceRadiusMeters = 50.0;
}