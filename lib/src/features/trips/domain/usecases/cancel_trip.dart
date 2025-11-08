import 'package:viax/src/core/error/result.dart';
import 'package:viax/src/core/error/failures.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

/// Use Case: Cancelar Viaje
/// 
/// Encapsula la lÃ³gica de negocio para cancelar un viaje.
class CancelTrip {
  final TripRepository repository;

  CancelTrip(this.repository);

  /// Ejecutar el caso de uso
  Future<Result<Trip>> call({
    required int tripId,
    required String motivo,
  }) async {
    if (tripId <= 0) {
      return Error(ValidationFailure('ID de viaje invÃ¡lido'));
    }

    if (motivo.trim().isEmpty) {
      return Error(
        ValidationFailure('Debe proporcionar un motivo de cancelaciÃ³n'),
      );
    }

    return await repository.cancelTrip(
      tripId: tripId,
      motivo: motivo,
    );
  }
}
