import 'package:viax/src/core/error/result.dart';
import 'package:viax/src/core/error/failures.dart';
import '../repositories/conductor_repository.dart';

/// Use Case: Obtener EstadÃ­sticas del Conductor
/// 
/// Encapsula la lÃ³gica de negocio para obtener estadÃ­sticas.
class GetConductorStatistics {
  final ConductorRepository repository;

  GetConductorStatistics(this.repository);

  /// Ejecutar el caso de uso
  /// 
  /// [conductorId] ID del conductor (requerido)
  Future<Result<Map<String, dynamic>>> call(int conductorId) async {
    if (conductorId <= 0) {
      return Error(ValidationFailure('ID de conductor invÃ¡lido'));
    }

    return await repository.getStatistics(conductorId);
  }
}
