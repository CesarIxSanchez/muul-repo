// lib/features/map/presentation/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tema_provider.dart';
import 'providers/map_provider.dart';
import 'widgets/map_controls.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  @override
  Widget build(BuildContext context) {
    final mapState   = ref.watch(mapProvider);
    final temaColors = ref.watch(temaColoresProvider);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('muul_map'),
            styleUri: AppConstants.mapboxStyleDark,
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(-99.1332, 19.4326),
              ),
              zoom: 13.0,
            ),
            onMapCreated: (MapboxMap controller) {
              ref
                  .read(mapProvider.notifier)
                  .onMapCreated(controller);
            },
            onStyleLoadedListener: (StyleLoadedEventData data) {
              debugPrint('🗺️ Estilo Mapbox dark-v11 cargado');
            },
          ),

          mapState.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (state) {
              if (state.isLoadingLocation) {
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: _LocationLoadingChip(),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          mapState.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (state) {
              if (state.locationError != null) {
                return Positioned(
                  bottom: 120,
                  left: 16,
                  right: 16,
                  child: _LocationErrorBanner(
                    message: state.locationError!,
                    onRetry: () =>
                        ref.read(mapProvider.notifier).fetchUserLocation(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          Positioned(
            bottom: 32,
            right: 16,
            child: MapControls(temaColors: temaColors),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _TemaBadge(temaColors: temaColors),
          ),
        ],
      ),
    );
  }
}

class _LocationLoadingChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        // ← cambio 1
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Obteniendo ubicación…',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LocationErrorBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        // ← cambio 2
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Reintentar',
              style: TextStyle(color: AppColors.secondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemaBadge extends StatelessWidget {
  final TemaColors temaColors;

  const _TemaBadge({required this.temaColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        // ← cambio 3
        color: temaColors.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        temaColors.nombre,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}