import '../../domain/entities/location.dart';

/// Modelo de Datos para Location
class LocationModel extends Location {
  const LocationModel({
    required super.latitud,
    required super.longitud,
    super.direccion,
    super.ciudad,
    super.pais,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitud: _parseDouble(json['latitud']) ?? _parseDouble(json['lat']) ?? 0.0,
      longitud: _parseDouble(json['longitud']) ?? _parseDouble(json['lng']) ?? 0.0,
      direccion: json['direccion'] ?? json['address'],
      ciudad: json['ciudad'] ?? json['city'],
      pais: json['pais'] ?? json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
      'ciudad': ciudad,
      'pais': pais,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

/// Modelo de Datos para Route
class RouteModel extends Route {
  const RouteModel({
    required super.origen,
    required super.destino,
    required super.distanciaKm,
    required super.duracionMinutos,
    required super.puntos,
    super.instrucciones,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final puntosJson = json['puntos'] as List? ?? [];
    final puntos = puntosJson
        .map((p) => LocationModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return RouteModel(
      origen: LocationModel.fromJson(json['origen']),
      destino: LocationModel.fromJson(json['destino']),
      distanciaKm: _parseDouble(json['distancia_km']),
      duracionMinutos: _parseInt(json['duracion_minutos']),
      puntos: puntos,
      instrucciones: json['instrucciones'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
