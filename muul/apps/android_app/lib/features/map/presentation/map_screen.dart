// lib/features/map/presentation/map_screen.dart

import 'dart:ui' as ui;
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
  PointAnnotationManager?    _annotationManager;
  PolylineAnnotationManager? _polylineManager;
  final Map<String, Uint8List> _iconCache = {};

  @override
  Widget build(BuildContext context) {
    final mapState   = ref.watch(mapProvider);
    final temaColors = ref.watch(temaColoresProvider);
    final s          = mapState.value;
    final hayPanel   = (s?.rutasAlternativas.isNotEmpty ?? false) ||
                       (s?.itinerario != null);

    ref.listen(mapProvider, (prev, next) {
      final ns = next.value;
      if (ns == null) return;
      _dibujarPois(ns.poisFiltrados, temaColors);
      if (ns.rutasAlternativas.isNotEmpty) {
        _dibujarRutas(ns.rutasAlternativas, ns.rutaActivaIndex, temaColors);
      } else if (ns.itinerarioCoords.isNotEmpty) {
        _dibujarRutaItinerario(ns.itinerarioCoords, temaColors);
      } else if (ns.rutasAlternativas.isEmpty && ns.itinerarioCoords.isEmpty) {
        _polylineManager?.deleteAll();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (hayPanel) {
          ref.read(mapProvider.notifier).limpiarRutas();
          _polylineManager?.deleteAll();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgApp,
        body: Stack(
          children: [
            // ── Mapa ───────────────────────────────────────────────────
            Positioned.fill(
              child: MapWidget(
                key: const ValueKey('muul_map'),
                styleUri: AppConstants.mapboxStyleDark,
                cameraOptions: CameraOptions(
                  center: Point(coordinates: Position(-99.1332, 19.4326)),
                  zoom: 13.0,
                ),
                onMapCreated: (MapboxMap controller) async {
                  _annotationManager = await controller.annotations
                      .createPointAnnotationManager();
                  _polylineManager = await controller.annotations
                      .createPolylineAnnotationManager();

                  // Ocultar elementos de UI por defecto para que sea más premium
                  controller.compass.updateSettings(CompassSettings(enabled: false));
                  controller.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
                  controller.logo.updateSettings(LogoSettings(enabled: false));
                  controller.attribution.updateSettings(AttributionSettings(enabled: false));

                  _annotationManager!.addOnPointAnnotationClickListener(
                    _PoiClickListener(ref: ref, context: context),
                  );
                  ref.read(mapProvider.notifier).onMapCreated(controller);
                },
                onStyleLoadedListener: (_) =>
                    debugPrint('🗺️ dark-v11 cargado'),
              ),
            ),

            // ── Barra superior ─────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: const Column(
                children: [
                  MapSearchBar(),
                  SizedBox(height: 8),
                  FilterChipsBar(),
                ],
              ),
            ),

            // ── Loading chips ──────────────────────────────────────────
            if (s?.isLoadingPois ?? false)
              Positioned(
                top: MediaQuery.of(context).padding.top + 108,
                left: 0, right: 0,
                child: const Center(
                  child: _LoadingChip(texto: 'Buscando lugares…'),
                ),
              ),
            if (s?.isLoadingRuta ?? false)
              Positioned(
                top: MediaQuery.of(context).padding.top + 108,
                left: 0, right: 0,
                child: const Center(
                  child: _LoadingChip(texto: 'Calculando ruta…'),
                ),
              ),
            if (s?.isLoadingItinerario ?? false)
              Positioned(
                top: MediaQuery.of(context).padding.top + 108,
                left: 0, right: 0,
                child: const Center(
                  child: _LoadingChip(texto: 'Generando itinerario…'),
                ),
              ),

            // ── Panel rutas alternativas ───────────────────────────────
            if ((s?.rutasAlternativas.isNotEmpty ?? false) &&
                s?.itinerario == null)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: RoutePanel(
                  rutas: s!.rutasAlternativas,
                  indexActivo: s.rutaActivaIndex,
                  onSelectRuta: (i) =>
                      ref.read(mapProvider.notifier).cambiarRutaActiva(i),
                  onClose: () {
                    ref.read(mapProvider.notifier).limpiarRutas();
                    _polylineManager?.deleteAll();
                  },
                  temaColors: temaColors,
                ),
              ),

            // ── Panel itinerario ───────────────────────────────────────
            if (s?.itinerario != null)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: ItineraryPanel(
                  itinerario: s!.itinerario!,
                  onClose: () {
                    ref.read(mapProvider.notifier).limpiarRutas();
                    _polylineManager?.deleteAll();
                  },
                  temaColors: temaColors,
                ),
              ),

            // ── Botón calcular itinerario ──────────────────────────────
            if ((s?.poisParaItinerario.isNotEmpty ?? false) &&
                s?.itinerario == null)
              Positioned(
                bottom: 100, left: 16, right: 72,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: temaColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                  icon: const Icon(Icons.alt_route),
                  label: Text(
                    'Calcular itinerario (${s!.poisParaItinerario.length} paradas)',
                  ),
                  onPressed: () =>
                      ref.read(mapProvider.notifier).calcularItinerario(),
                ),
              ),

            // ── Controles ──────────────────────────────────────────────
            if (!hayPanel)
              Positioned(
                bottom: 32, right: 16,
                child: MapControls(temaColors: temaColors),
              ),

            // ── Badge tema ─────────────────────────────────────────────
            if (!hayPanel)
              Positioned(
                bottom: 32, left: 16,
                child: _TemaBadge(temaColors: temaColors),
              ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de íconos ──────────────────────────────────────────────────────

  Future<Uint8List> _generarIcono(Color color, IconData icon) async {
    final key = '${color.value}_${icon.codePoint}';
    if (_iconCache.containsKey(key)) return _iconCache[key]!;

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);
    const size     = 48.0;

    final paint = Paint()..color = color;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 1.5, border);

    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          fontSize: 24,
          color: Colors.white,
        ),
      )
      ..layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));

    final picture = recorder.endRecording();
    final img     = await picture.toImage(size.toInt(), size.toInt());
    final bytes   = await img.toByteData(format: ui.ImageByteFormat.png);
    final result  = bytes!.buffer.asUint8List();

    _iconCache[key] = result;
    return result;
  }

  Color _colorParaCategoria(String cat, TemaColors temaColors) {
    switch (cat.toLowerCase()) {
      case 'restaurant':
      case 'comida':
      case 'food':
        return const Color(0xFFE53935);
      case 'museum':
      case 'cultura':
      case 'historic':
        return const Color(0xFF8E24AA);
      case 'market':
      case 'tienda':
      case 'shop':
        return const Color(0xFF1E88E5);
      case 'park':
        return const Color(0xFF43A047);
      case 'cafe':
        return const Color(0xFF6D4C41);
      default:
        return temaColors.secondary;
    }
  }

  IconData _iconParaCategoria(String cat) {
    switch (cat.toLowerCase()) {
      case 'restaurant':
      case 'comida':
      case 'food':
        return Icons.restaurant;
      case 'museum':
      case 'cultura':
        return Icons.museum;
      case 'historic':
        return Icons.account_balance;
      case 'market':
      case 'tienda':
      case 'shop':
        return Icons.shopping_bag;
      case 'park':
        return Icons.park;
      case 'cafe':
        return Icons.coffee;
      default:
        return Icons.place;
    }
  }

  Future<void> _dibujarPois(
    List<PoiModel> pois,
    TemaColors temaColors,
  ) async {
    if (_annotationManager == null) return;
    await _annotationManager!.deleteAll();

    for (final poi in pois) {
      final color  = _colorParaCategoria(poi.categoria, temaColors);
      final icon   = _iconParaCategoria(poi.categoria);
      final imagen = await _generarIcono(color, icon);

      await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(poi.longitud, poi.latitud),
          ),
          image: imagen,
          iconSize: poi.verificado ? 1.3 : 1.0,
          iconAnchor: IconAnchor.BOTTOM,
          textField: poi.nombre,
          textSize: 10,
          textColor: Colors.white.value,
          textHaloColor: Colors.black.value,
          textHaloWidth: 1.5,
          textOffset: [0, 0.5],
          textAnchor: TextAnchor.TOP,
        ),
      );
    }
  }

  Future<void> _dibujarRutas(
    List<RouteResult> rutas,
    int indexActivo,
    TemaColors temaColors,
  ) async {
    if (_polylineManager == null) return;
    await _polylineManager!.deleteAll();

    for (var i = 0; i < rutas.length; i++) {
      final esActiva = i == indexActivo;
      final coords = rutas[i]
          .coordenadas
          .map((c) => Position(c[0], c[1]))
          .toList();

      if (esActiva) {
        await _polylineManager!.create(
          PolylineAnnotationOptions(
            geometry: LineString(coordinates: coords),
            lineColor: temaColors.secondary.withValues(alpha: 0.35).value,
            lineWidth: 16.0,
            lineBlur: 8.0,
          ),
        );
        await _polylineManager!.create(
          PolylineAnnotationOptions(
            geometry: LineString(coordinates: coords),
            lineColor: temaColors.secondary.value,
            lineWidth: 4.5,
          ),
        );
      } else {
        await _polylineManager!.create(
          PolylineAnnotationOptions(
            geometry: LineString(coordinates: coords),
            lineColor: Colors.grey.withValues(alpha: 0.35).value,
            lineWidth: 2.5,
          ),
        );
      }
    }
  }

  Future<void> _dibujarRutaItinerario(
    List<List<double>> coords,
    TemaColors temaColors,
  ) async {
    if (_polylineManager == null) return;
    await _polylineManager!.deleteAll();
    final positions = coords.map((c) => Position(c[0], c[1])).toList();

    await _polylineManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: positions),
        lineColor: temaColors.secondary.withValues(alpha: 0.35).value,
        lineWidth: 16.0,
        lineBlur: 8.0,
      ),
    );
    await _polylineManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: positions),
        lineColor: temaColors.secondary.value,
        lineWidth: 4.5,
      ),
    );
  }

} // ✅ _MapScreenState termina AQUÍ

// ════════════════════════════════════════════════════════════════════════════
// Clases de nivel superior — FUERA de _MapScreenState
// ════════════════════════════════════════════════════════════════════════════

// ── POI click listener ────────────────────────────────────────────────────────

class _PoiClickListener extends OnPointAnnotationClickListener {
  final WidgetRef ref;
  final BuildContext context; // ✅ FIX: context separado de ref

  _PoiClickListener({required this.ref, required this.context});

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    final pois   = ref.read(mapProvider).value?.pois ?? [];
    final coords = annotation.geometry.coordinates;

    final poi = pois.firstWhere(
      (p) =>
          (p.longitud - coords.lng).abs() < 0.0001 &&
          (p.latitud  - coords.lat).abs() < 0.0001,
      orElse: () => PoiModel(
        id: '',
        nombre: 'Lugar',
        categoria: 'general',
        descripcion: '',
        latitud:  coords.lat.toDouble(),
        longitud: coords.lng.toDouble(),
      ),
    );

    ref.read(mapProvider.notifier).seleccionarPoi(poi);

    // ✅ FIX: usamos this.context en lugar de ref.context
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PoiBottomSheet(poi: poi),
    );
    return true;
  }
}

// ── Loading chip ──────────────────────────────────────────────────────────────

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
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Tema badge ────────────────────────────────────────────────────────────────

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
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
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