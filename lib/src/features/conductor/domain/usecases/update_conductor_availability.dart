import 'package:ping_go/src/core/error/result.dart';
import 'package:ping_go/src/core/error/failures.dart';
import '../repositories/conductor_repository.dart';

/// Use Case: Actualizar Disponibilidad del Conductor
/// 
/// Encapsula la lógica de negocio para cambiar disponibilidad.
class UpdateConductorAvailability {
  final ConductorRepository repository;

  UpdateConductorAvailability(this.repository);

  /// Ejecutar el caso de uso
  /// 
  /// [conductorId] ID del conductor (requerido)
  /// [disponible] Estado de disponibilidad (requerido)
  Future<Result<void>> call({
    required int conductorId,
    required bool disponible,
  }) async {
    if (conductorId <= 0) {
      return Error(ValidationFailure('ID de conductor inválido'));
    }

    return await repository.updateAvailability(
      conductorId: conductorId,
      disponible: disponible,
    );
  }
}
