import 'package:ping_go/src/core/error/result.dart';
import 'package:ping_go/src/core/error/failures.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

/// Use Case: Obtener Viajes Activos del Usuario
/// 
/// Encapsula la lógica de negocio para obtener viajes activos.
class GetActiveTrips {
  final TripRepository repository;

  GetActiveTrips(this.repository);

  /// Ejecutar el caso de uso
  Future<Result<List<Trip>>> call(int usuarioId) async {
    if (usuarioId <= 0) {
      return Error(ValidationFailure('ID de usuario inválido'));
    }

    return await repository.getActiveTrips(usuarioId);
  }
}
