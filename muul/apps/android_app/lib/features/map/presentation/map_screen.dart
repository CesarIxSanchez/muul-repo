// lib/features/map/presentation/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tema_provider.dart';
import '../data/route_service.dart';
import '../domain/models/poi_model.dart';
import 'providers/map_provider.dart';
import 'widgets/map_controls.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/poi_bottom_sheet.dart';
import 'widgets/route_panel.dart';
import 'widgets/itinerary_panel.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  PointAnnotationManager? _annotationManager;
  PolylineAnnotationManager? _polylineManager;
  final List<PointAnnotation> _annotations = [];
  final List<PolylineAnnotation> _polylines = [];

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final temaColors = ref.watch(temaColoresProvider);

    // Dibuja POIs y rutas cuando cambia el estado
    ref.listen(mapProvider, (prev, next) {
      final s = next.value;
      if (s == null) return;
      _dibujarPois(s.pois);
      if (s.rutasAlternativas.isNotEmpty) {
        _dibujarRutas(s.rutasAlternativas, s.rutaActivaIndex, temaColors);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Stack(
        children: [
          // ── Mapa ─────────────────────────────────────────────────────────
          MapWidget(
            key: const ValueKey('muul_map'),
            styleUri: AppConstants.mapboxStyleDark,
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(-99.1332, 19.4326)),
              zoom: 13.0,
            ),
            onMapCreated: (MapboxMap controller) async {
              _annotationManager =
                  await controller.annotations.createPointAnnotationManager();
              _polylineManager =
                  await controller.annotations.createPolylineAnnotationManager();

              // Listener de tap en marcadores
              _annotationManager!.addOnPointAnnotationClickListener(
                _PoiClickListener(ref),
              );

              ref.read(mapProvider.notifier).onMapCreated(controller);
            },
            onStyleLoadedListener: (_) =>
                debugPrint('🗺️ dark-v11 cargado'),
          ),

          // ── Loading POIs ──────────────────────────────────────────────────
          mapState.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) => s.isLoadingPois
                ? const Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Center(child: _LoadingChip(texto: 'Buscando lugares…')),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Loading Ruta ──────────────────────────────────────────────────
          mapState.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) => s.isLoadingRuta
                ? const Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Center(child: _LoadingChip(texto: 'Calculando ruta…')),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Panel de rutas alternativas ───────────────────────────────────
          mapState.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) => s.rutasAlternativas.isNotEmpty && s.itinerario == null
                ? Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: RoutePanel(
                      rutas: s.rutasAlternativas,
                      indexActivo: s.rutaActivaIndex,
                      onSelectRuta: (i) =>
                          ref.read(mapProvider.notifier).cambiarRutaActiva(i),
                      onClose: () {
                        ref.read(mapProvider.notifier).limpiarRutas();
                        _limpiarPolilineas();
                      },
                      temaColors: temaColors,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Panel de itinerario ───────────────────────────────────────────
          mapState.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) => s.itinerario != null
                ? Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ItineraryPanel(
                      itinerario: s.itinerario!,
                      onClose: () {
                        ref.read(mapProvider.notifier).limpiarRutas();
                        _limpiarPolilineas();
                      },
                      temaColors: temaColors,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Botón "Calcular itinerario" cuando hay POIs seleccionados ─────
          mapState.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) => s.poisParaItinerario.isNotEmpty && s.itinerario == null
                ? Positioned(
                    bottom: 100,
                    left: 16,
                    right: 72,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: temaColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.alt_route),
                      label: Text(
                        'Calcular itinerario (${s.poisParaItinerario.length} paradas)',
                      ),
                      onPressed: () =>
                          ref.read(mapProvider.notifier).calcularItinerario(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Controles ─────────────────────────────────────────────────────
          Positioned(
            bottom: 32,
            right: 16,
            child: MapControls(temaColors: temaColors),
          ),

          // ── Badge tema ────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _TemaBadge(temaColors: temaColors),
          ),
        ],
      ),
    );
  }

  Future<void> _dibujarPois(List<PoiModel> pois) async {
    if (_annotationManager == null) return;
    await _annotationManager!.deleteAll();
    _annotations.clear();

    for (final poi in pois) {
      final annotation = await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(poi.longitud, poi.latitud)),
          iconSize: poi.verificado ? 1.4 : 1.0,
          textField: poi.nombre,
          textSize: 10,
          textColor: Colors.white.value,
          textHaloColor: Colors.black.value,
          textHaloWidth: 1.0,
          textOffset: [0, 1.5],
        ),
      );
      _annotations.add(annotation);
    }
  }

  Future<void> _dibujarRutas(
    List<RouteResult> rutas,
    int indexActivo,
    TemaColors temaColors,
  ) async {
    if (_polylineManager == null) return;
    await _polylineManager!.deleteAll();
    _polylines.clear();

    for (var i = 0; i < rutas.length; i++) {
      final ruta = rutas[i];
      final esActiva = i == indexActivo;
      final coords = ruta.coordenadas
          .map((c) => Position(c[0], c[1]))
          .toList();

      await _polylineManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: coords),
          lineColor: esActiva
              ? temaColors.secondary.value
              : Colors.grey.withValues(alpha: 0.5).value,
          lineWidth: esActiva ? 5.0 : 2.5,
        ),
      );
    }
  }

  void _limpiarPolilineas() {
    _polylineManager?.deleteAll();
    _polylines.clear();
  }
}

// ── Listener de clicks en POIs ────────────────────────────────────────────────
class _PoiClickListener extends OnPointAnnotationClickListener {
  final WidgetRef ref;
  _PoiClickListener(this.ref);

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    final pois = ref.read(mapProvider).value?.pois ?? [];
    final coords = annotation.geometry.coordinates;
    final poi = pois.firstWhere(
      (p) => (p.longitud - coords.lng).abs() < 0.0001 &&
             (p.latitud - coords.lat).abs() < 0.0001,
      orElse: () => PoiModel(
        id: '', nombre: 'Lugar', categoria: 'general',
        descripcion: '', latitud: coords.lat.toDouble(),
        longitud: coords.lng.toDouble(),
      ),
    );

    ref.read(mapProvider.notifier).seleccionarPoi(poi);

    showModalBottomSheet(
      context: ref.context,
      backgroundColor: Colors.transparent,
      builder: (_) => PoiBottomSheet(poi: poi),
    );

    return true;
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────
class _LoadingChip extends StatelessWidget {
  final String texto;
  const _LoadingChip({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
          const SizedBox(width: 8),
          Text(texto, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
        color: temaColors.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        temaColors.nombre,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}