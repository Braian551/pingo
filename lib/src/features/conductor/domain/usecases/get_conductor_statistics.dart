import 'package:ping_go/src/core/error/result.dart';
import 'package:ping_go/src/core/error/failures.dart';
import '../repositories/conductor_repository.dart';

/// Use Case: Obtener Estadísticas del Conductor
/// 
/// Encapsula la lógica de negocio para obtener estadísticas.
class GetConductorStatistics {
  final ConductorRepository repository;

  GetConductorStatistics(this.repository);

  /// Ejecutar el caso de uso
  /// 
  /// [conductorId] ID del conductor (requerido)
  Future<Result<Map<String, dynamic>>> call(int conductorId) async {
    if (conductorId <= 0) {
      return Error(ValidationFailure('ID de conductor inválido'));
    }

    return await repository.getStatistics(conductorId);
  }
}
