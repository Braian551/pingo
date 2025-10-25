import 'package:ping_go/src/core/error/result.dart';
import '../entities/location.dart';

/// Contrato abstracto del repositorio de mapas
abstract class MapRepository {
  /// Geocoding: Obtener coordenadas de una dirección
  Future<Result<Location>> geocodeAddress(String address);

  /// Reverse Geocoding: Obtener dirección de coordenadas
  Future<Result<Location>> reverseGeocode(double lat, double lng);

  /// Calcular ruta entre dos puntos
  Future<Result<Route>> calculateRoute(Location origin, Location destination);

  /// Calcular distancia entre dos puntos
  Future<Result<double>> calculateDistance(Location origin, Location destination);

  /// Buscar lugares cercanos
  Future<Result<List<Location>>> searchNearbyPlaces({
    required double lat,
    required double lng,
    required String query,
    double radiusKm = 1.0,
  });
}
