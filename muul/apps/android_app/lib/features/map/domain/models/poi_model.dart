// lib/features/map/domain/models/poi_model.dart

class PoiModel {
  final String id;
  final String nombre;
  final String categoria;
  final String descripcion;
  final double latitud;
  final double longitud;
  final String? horario;
  final String? foto;
  final bool verificado;
  bool seleccionado;

  PoiModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    this.horario,
    this.foto,
    this.verificado = false,
    this.seleccionado = false,
  });

  factory PoiModel.fromMapbox(Map<String, dynamic> json) {
    final coords = json['geometry']['coordinates'] as List;
    final props = json['properties'] as Map<String, dynamic>;
    return PoiModel(
      id: json['id'] ?? props['mapbox_id'] ?? '',
      nombre: props['name'] ?? 'Sin nombre',
      categoria: props['poi_category']?[0] ?? 'general',
      descripcion: props['full_address'] ?? props['place_formatted'] ?? '',
      latitud: (coords[1] as num).toDouble(),
      longitud: (coords[0] as num).toDouble(),
    );
  }

  factory PoiModel.fromSupabase(Map<String, dynamic> json) {
    return PoiModel(
      id: json['id'].toString(),
      nombre: json['nombre'] ?? '',
      categoria: json['categoria'] ?? 'general',
      descripcion: json['descripcion'] ?? '',
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      horario: json['horario'],
      foto: json['foto'],
      verificado: json['verificado'] ?? false,
    );
  }
}