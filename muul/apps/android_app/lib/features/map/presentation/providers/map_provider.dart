// lib/features/map/presentation/providers/map_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/services/location_service.dart';

class MapState {
  final geo.Position? userPosition;
  final bool isLoadingLocation;
  final String? locationError;
  final MapboxMap? mapController;
  final bool mapReady;

  const MapState({
    this.userPosition,
    this.isLoadingLocation = false,
    this.locationError,
    this.mapController,
    this.mapReady = false,
  });

  MapState copyWith({
    geo.Position? userPosition,
    bool? isLoadingLocation,
    String? locationError,
    MapboxMap? mapController,
    bool? mapReady,
  }) {
    return MapState(
      userPosition:      userPosition      ?? this.userPosition,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      locationError:     locationError,
      mapController:     mapController     ?? this.mapController,
      mapReady:          mapReady          ?? this.mapReady,
    );
  }
}

class MapNotifier extends AsyncNotifier<MapState> {
  @override
  Future<MapState> build() async => const MapState();

  Future<void> onMapCreated(MapboxMap controller) async {
    state = AsyncData(
      state.value!.copyWith(mapController: controller, mapReady: true),
    );
    await fetchUserLocation();
  }

  Future<void> fetchUserLocation() async {
    final currentState = state.value ?? const MapState();
    state = AsyncData(
      currentState.copyWith(isLoadingLocation: true, locationError: null),
    );

    try {
      final position = await LocationService.getCurrentPosition();
      final newState = currentState.copyWith(
        userPosition: position,
        isLoadingLocation: false,
      );
      state = AsyncData(newState);
      await _centerMapOnUser(position, newState.mapController);
    } on LocationServiceException catch (e) {
      state = AsyncData(
        currentState.copyWith(
          isLoadingLocation: false,
          locationError: e.message,
        ),
      );
    }
  }

  Future<void> _centerMapOnUser(
    geo.Position position,
    MapboxMap? controller,
  ) async {
    if (controller == null) return;
    await controller.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 1200, startDelay: 0),
    );
  }
}

final mapProvider = AsyncNotifierProvider<MapNotifier, MapState>(
  MapNotifier.new,
);