import 'package:ping_go/src/core/error/result.dart';
import 'package:ping_go/src/core/error/failures.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

/// Use Case: Iniciar Viaje
/// 
/// Encapsula la lógica de negocio para que un conductor inicie un viaje.
class StartTrip {
  final TripRepository repository;

  StartTrip(this.repository);

  /// Ejecutar el caso de uso
  Future<Result<Trip>> call(int tripId) async {
    if (tripId <= 0) {
      return Error(ValidationFailure('ID de viaje inválido'));
    }

    return await repository.startTrip(tripId);
  }
}
