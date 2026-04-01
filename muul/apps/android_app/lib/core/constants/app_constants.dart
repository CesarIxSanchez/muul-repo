// lib/core/constants/app_constants.dart
import 'env.dart';
class AppConstants {
  // ── Mapbox ──────────────────────────────────────────────────
  static const String mapboxToken = mapboxPublicToken;
  static const String mapboxStyleDark =
      'mapbox://styles/mapbox/dark-v11';
  static const String mapboxDirectionsUrl =
      'https://api.mapbox.com/directions/v5/mapbox/walking';
  static const String mapboxSearchUrl =
      'https://api.mapbox.com/search/searchbox/v1/category';

  // ── Supabase ─────────────────────────────────────────────────
  static const String supabaseUrl =
      'https://qewqnirwuptcudoflgkd.supabase.co';
  static const String supabaseAnonKey = 'TU_ANON_KEY_AQUI';

  // ── Geofencing ───────────────────────────────────────────────
  static const double geofenceRadiusMeters = 50.0;

  // ── Animaciones ──────────────────────────────────────────────
  static const Duration markerAnimDuration = Duration(milliseconds: 350);
  static const Duration markerCascadeDelay = Duration(milliseconds: 40);
}