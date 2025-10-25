import 'package:ping_go/src/core/error/result.dart';
import 'package:ping_go/src/core/error/failures.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

/// Use Case: Conductor Acepta un Viaje
/// 
/// Encapsula la lógica de negocio para que un conductor acepte un viaje.
class AcceptTrip {
  final TripRepository repository;

  AcceptTrip(this.repository);

  /// Ejecutar el caso de uso
  Future<Result<Trip>> call({
    required int tripId,
    required int conductorId,
  }) async {
    if (tripId <= 0) {
      return Error(ValidationFailure('ID de viaje inválido'));
    }

    if (conductorId <= 0) {
      return Error(ValidationFailure('ID de conductor inválido'));
    }

    return await repository.acceptTrip(tripId, conductorId);
  }
}
