import 'package:ping_go/src/core/error/result.dart';
import 'package:ping_go/src/core/error/failures.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

/// Use Case: Cancelar Viaje
/// 
/// Encapsula la lógica de negocio para cancelar un viaje.
class CancelTrip {
  final TripRepository repository;

  CancelTrip(this.repository);

  /// Ejecutar el caso de uso
  Future<Result<Trip>> call({
    required int tripId,
    required String motivo,
  }) async {
    if (tripId <= 0) {
      return Error(ValidationFailure('ID de viaje inválido'));
    }

    if (motivo.trim().isEmpty) {
      return Error(
        ValidationFailure('Debe proporcionar un motivo de cancelación'),
      );
    }

    return await repository.cancelTrip(
      tripId: tripId,
      motivo: motivo,
    );
  }
}
