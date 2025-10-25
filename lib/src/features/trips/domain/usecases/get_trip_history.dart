import 'package:ping_go/src/core/error/result.dart';
import 'package:ping_go/src/core/error/failures.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

/// Use Case: Obtener Historial de Viajes del Usuario
/// 
/// Encapsula la lógica de negocio para obtener historial completo.
class GetTripHistory {
  final TripRepository repository;

  GetTripHistory(this.repository);

  /// Ejecutar el caso de uso
  Future<Result<List<Trip>>> call(int usuarioId) async {
    if (usuarioId <= 0) {
      return Error(ValidationFailure('ID de usuario inválido'));
    }

    return await repository.getTripHistory(usuarioId);
  }
}
