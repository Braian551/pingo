import 'package:viax/src/core/error/result.dart';
import 'package:viax/src/core/error/failures.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

/// Use Case: Completar Viaje
/// 
/// Encapsula la lÃ³gica de negocio para finalizar un viaje.
class CompleteTrip {
  final TripRepository repository;

  CompleteTrip(this.repository);

  /// Ejecutar el caso de uso
  Future<Result<Trip>> call({
    required int tripId,
    required double precioFinal,
    double? distanciaReal,
  }) async {
    if (tripId <= 0) {
      return Error(ValidationFailure('ID de viaje invÃ¡lido'));
    }

    if (precioFinal < 0) {
      return Error(ValidationFailure('El precio final no puede ser negativo'));
    }

    if (distanciaReal != null && distanciaReal < 0) {
      return Error(ValidationFailure('La distancia no puede ser negativa'));
    }

    return await repository.completeTrip(
      tripId: tripId,
      precioFinal: precioFinal,
      distanciaReal: distanciaReal,
    );
  }
}
