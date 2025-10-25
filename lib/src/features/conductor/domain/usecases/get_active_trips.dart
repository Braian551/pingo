import 'package:ping_go/src/core/error/result.dart';
import 'package:ping_go/src/core/error/failures.dart';
import '../repositories/conductor_repository.dart';

/// Use Case: Obtener Viajes Activos
/// 
/// Encapsula la lógica de negocio para obtener viajes en curso.
class GetActiveTrips {
  final ConductorRepository repository;

  GetActiveTrips(this.repository);

  /// Ejecutar el caso de uso
  /// 
  /// [conductorId] ID del conductor (requerido)
  Future<Result<List<Map<String, dynamic>>>> call(int conductorId) async {
    if (conductorId <= 0) {
      return Error(ValidationFailure('ID de conductor inválido'));
    }

    return await repository.getActiveTrips(conductorId);
  }
}
