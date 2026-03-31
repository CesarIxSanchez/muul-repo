// lib/features/map/presentation/providers/map_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/services/location_service.dart';
import '../../data/poi_repository.dart';
import '../../data/route_service.dart';
import '../../domain/models/poi_model.dart';

class MapState {
  final geo.Position? userPosition;
  final bool isLoadingLocation;
  final String? locationError;
  final MapboxMap? mapController;
  final bool mapReady;

  // POIs
  final List<PoiModel> pois;
  final bool isLoadingPois;
  final PoiModel? poiSeleccionado;

  // Rutas
  final List<RouteResult> rutasAlternativas;
  final int rutaActivaIndex;
  final bool isLoadingRuta;

  // Itinerario
  final List<PoiModel> poisParaItinerario;
  final ItinerarioResult? itinerario;
  final bool isLoadingItinerario;

  const MapState({
    this.userPosition,
    this.isLoadingLocation = false,
    this.locationError,
    this.mapController,
    this.mapReady = false,
    this.pois = const [],
    this.isLoadingPois = false,
    this.poiSeleccionado,
    this.rutasAlternativas = const [],
    this.rutaActivaIndex = 0,
    this.isLoadingRuta = false,
    this.poisParaItinerario = const [],
    this.itinerario,
    this.isLoadingItinerario = false,
  });

  MapState copyWith({
    geo.Position? userPosition,
    bool? isLoadingLocation,
    String? locationError,
    MapboxMap? mapController,
    bool? mapReady,
    List<PoiModel>? pois,
    bool? isLoadingPois,
    PoiModel? poiSeleccionado,
    bool clearPoiSeleccionado = false,
    List<RouteResult>? rutasAlternativas,
    int? rutaActivaIndex,
    bool? isLoadingRuta,
    List<PoiModel>? poisParaItinerario,
    ItinerarioResult? itinerario,
    bool? isLoadingItinerario,
  }) {
    return MapState(
      userPosition: userPosition ?? this.userPosition,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      locationError: locationError,
      mapController: mapController ?? this.mapController,
      mapReady: mapReady ?? this.mapReady,
      pois: pois ?? this.pois,
      isLoadingPois: isLoadingPois ?? this.isLoadingPois,
      poiSeleccionado: clearPoiSeleccionado ? null : (poiSeleccionado ?? this.poiSeleccionado),
      rutasAlternativas: rutasAlternativas ?? this.rutasAlternativas,
      rutaActivaIndex: rutaActivaIndex ?? this.rutaActivaIndex,
      isLoadingRuta: isLoadingRuta ?? this.isLoadingRuta,
      poisParaItinerario: poisParaItinerario ?? this.poisParaItinerario,
      itinerario: itinerario ?? this.itinerario,
      isLoadingItinerario: isLoadingItinerario ?? this.isLoadingItinerario,
    );
  }
}

class MapNotifier extends AsyncNotifier<MapState> {
  final _poiRepo = PoiRepository();
  final _routeService = RouteService();

  @override
  Future<MapState> build() async => const MapState();

  Future<void> onMapCreated(MapboxMap controller) async {
    state = AsyncData(state.value!.copyWith(mapController: controller, mapReady: true));
    await fetchUserLocation();
  }

  Future<void> fetchUserLocation() async {
    final s = state.value ?? const MapState();
    state = AsyncData(s.copyWith(isLoadingLocation: true));

    try {
      final position = await LocationService.getCurrentPosition();
      state = AsyncData(s.copyWith(
        userPosition: position,
        isLoadingLocation: false,
      ));
      await _centerMapOnUser(position, s.mapController);
      await fetchPoisCercanos(); // Carga POIs automáticamente
    } on LocationServiceException catch (e) {
      state = AsyncData(s.copyWith(isLoadingLocation: false, locationError: e.message));
    }
  }

  Future<void> fetchPoisCercanos() async {
    final s = state.value ?? const MapState();
    if (s.userPosition == null) return;

    state = AsyncData(s.copyWith(isLoadingPois: true));
    final pois = await _poiRepo.fetchTodosPois(
      lat: s.userPosition!.latitude,
      lng: s.userPosition!.longitude,
    );
    state = AsyncData((state.value ?? const MapState()).copyWith(
      pois: pois,
      isLoadingPois: false,
    ));
  }

  void seleccionarPoi(PoiModel poi) {
    state = AsyncData(state.value!.copyWith(poiSeleccionado: poi));
  }

  void deseleccionarPoi() {
    state = AsyncData(state.value!.copyWith(clearPoiSeleccionado: true));
  }

  // Agrega/quita un POI de la lista para itinerario
  void togglePoiItinerario(PoiModel poi) {
    final s = state.value!;
    final lista = List<PoiModel>.from(s.poisParaItinerario);
    final idx = lista.indexWhere((p) => p.id == poi.id);
    if (idx >= 0) {
      lista.removeAt(idx);
      poi.seleccionado = false;
    } else {
      poi.seleccionado = true;
      lista.add(poi);
    }
    state = AsyncData(s.copyWith(poisParaItinerario: lista));
  }

  // Calcula ruta a un solo POI (3 alternativas)
  Future<void> calcularRutaAPoi(PoiModel destino) async {
    final s = state.value!;
    if (s.userPosition == null) return;

    state = AsyncData(s.copyWith(isLoadingRuta: true));

    final rutas = await _routeService.calcularRutas(
      origenLat: s.userPosition!.latitude,
      origenLng: s.userPosition!.longitude,
      destinoLat: destino.latitud,
      destinoLng: destino.longitud,
    );

    state = AsyncData((state.value ?? const MapState()).copyWith(
      rutasAlternativas: rutas,
      rutaActivaIndex: 0,
      isLoadingRuta: false,
    ));
  }

  // Calcula itinerario con múltiples POIs seleccionados
  Future<void> calcularItinerario() async {
    final s = state.value!;
    if (s.userPosition == null || s.poisParaItinerario.isEmpty) return;

    state = AsyncData(s.copyWith(isLoadingItinerario: true));

    final resultado = await _routeService.calcularItinerario(
      origenLat: s.userPosition!.latitude,
      origenLng: s.userPosition!.longitude,
      destinos: s.poisParaItinerario,
    );

    state = AsyncData((state.value ?? const MapState()).copyWith(
      itinerario: resultado,
      isLoadingItinerario: false,
    ));
  }

  void cambiarRutaActiva(int index) {
    state = AsyncData(state.value!.copyWith(rutaActivaIndex: index));
  }

  void limpiarRutas() {
    state = AsyncData(state.value!.copyWith(
      rutasAlternativas: [],
      itinerario: null,
      poisParaItinerario: [],
    ));
  }

  Future<void> _centerMapOnUser(geo.Position position, MapboxMap? controller) async {
    if (controller == null) return;
    await controller.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(position.longitude, position.latitude)),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 1200, startDelay: 0),
    );
  }
}

final mapProvider = AsyncNotifierProvider<MapNotifier, MapState>(MapNotifier.new);