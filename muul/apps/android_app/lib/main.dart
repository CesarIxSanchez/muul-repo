// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_colors.dart';
import 'features/map/presentation/map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar token de Mapbox (DEBE ir antes de cualquier MapWidget)
  MapboxOptions.setAccessToken(AppConstants.mapboxToken);

  // 2. Inicializar Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    // 3. Envolver con ProviderScope de Riverpod
    const ProviderScope(
      child: MuulApp(),
    ),
  );
}

class MuulApp extends StatelessWidget {
  const MuulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muul',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgApp,
        colorScheme: ColorScheme.dark(
          primary:   AppColors.primary,
          secondary: AppColors.secondary,
          error:     AppColors.accent,
          surface:   AppColors.bgCard,
        ),
        fontFamily: 'Inter', // Asegúrate de añadir Inter a pubspec.yaml
      ),
      home: const MapScreen(),
    );
  }
}