import 'package:viax/src/core/error/result.dart';
import '../entities/trip.dart';

/// Contrato abstracto del repositorio de viajes
/// 
/// Define las operaciones que se pueden realizar con los datos de viajes
/// sin especificar CÃ“MO se implementan (BD local, API, cache, etc.)
/// 
/// Usa Result<T> para manejo de errores funcional:
/// - Success(data): Cuando la operaciÃ³n es exitosa
/// - Error(failure): Cuando hay un error
abstract class TripRepository {
  /// Crear un nuevo viaje (solicitud)
  Future<Result<Trip>> createTrip({
    required int usuarioId,
    required TripType tipoServicio,
    required TripLocation origen,
    required TripLocation destino,
  });

  /// Obtener viaje por ID
  Future<Result<Trip>> getTripById(int tripId);

  /// Obtener viajes activos de un usuario
  Future<Result<List<Trip>>> getActiveTrips(int usuarioId);

  /// Obtener historial de viajes de un usuario
  Future<Result<List<Trip>>> getTripHistory(int usuarioId);

  /// Obtener viajes activos de un conductor
  Future<Result<List<Trip>>> getConductorActiveTrips(int conductorId);

  /// Obtener historial de viajes de un conductor
  Future<Result<List<Trip>>> getConductorTripHistory(int conductorId);

  /// Conductor acepta un viaje
  Future<Result<Trip>> acceptTrip(int tripId, int conductorId);

  /// Conductor inicia un viaje
  Future<Result<Trip>> startTrip(int tripId);

  /// Finalizar viaje
  Future<Result<Trip>> completeTrip({
    required int tripId,
    required double precioFinal,
    double? distanciaReal,
  });

  /// Cancelar viaje
  Future<Result<Trip>> cancelTrip({
    required int tripId,
    required String motivo,
  });

  /// Calificar conductor
  Future<Result<void>> rateConductor({
    required int tripId,
    required int calificacion,
    String? comentario,
  });

  /// Calificar usuario
  Future<Result<void>> rateUser({
    required int tripId,
    required int calificacion,
    String? comentario,
  });

  /// Buscar conductores disponibles cerca
  Future<Result<List<Map<String, dynamic>>>> findNearbyDrivers({
    required double latitud,
    required double longitud,
    required TripType tipoServicio,
    double radiusKm = 5.0,
  });
}
