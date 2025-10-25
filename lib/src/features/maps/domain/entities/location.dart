/// Entidad de Dominio: Location
/// 
/// Representa una ubicación geográfica con coordenadas y dirección.
class Location {
  final double latitud;
  final double longitud;
  final String? direccion;
  final String? ciudad;
  final String? pais;

  const Location({
    required this.latitud,
    required this.longitud,
    this.direccion,
    this.ciudad,
    this.pais,
  });

  /// Validar coordenadas
  bool get isValid =>
      latitud >= -90 && latitud <= 90 &&
      longitud >= -180 && longitud <= 180;

  @override
  String toString() => direccion ?? '$latitud, $longitud';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          latitud == other.latitud &&
          longitud == other.longitud;

  @override
  int get hashCode => latitud.hashCode ^ longitud.hashCode;
}

/// Ruta entre dos ubicaciones
class Route {
  final Location origen;
  final Location destino;
  final double distanciaKm;
  final int duracionMinutos;
  final List<Location> puntos;
  final String? instrucciones;

  const Route({
    required this.origen,
    required this.destino,
    required this.distanciaKm,
    required this.duracionMinutos,
    required this.puntos,
    this.instrucciones,
  });
}
