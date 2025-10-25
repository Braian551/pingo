import 'package:ping_go/src/core/error/result.dart';
import 'package:ping_go/src/core/error/failures.dart';
import '../repositories/conductor_repository.dart';

/// Use Case: Obtener Ganancias del Conductor
/// 
/// Encapsula la lógica de negocio para obtener ganancias por período.
class GetConductorEarnings {
  final ConductorRepository repository;

  GetConductorEarnings(this.repository);

  /// Ejecutar el caso de uso
  /// 
  /// [conductorId] ID del conductor (requerido)
  /// [periodo] Período: 'hoy', 'semana', 'mes' (default: 'hoy')
  Future<Result<Map<String, dynamic>>> call({
    required int conductorId,
    String periodo = 'hoy',
  }) async {
    if (conductorId <= 0) {
      return Error(ValidationFailure('ID de conductor inválido'));
    }

    final periodosValidos = ['hoy', 'semana', 'mes', 'custom'];
    if (!periodosValidos.contains(periodo.toLowerCase())) {
      return Error(
        ValidationFailure(
          'Período inválido. Use: ${periodosValidos.join(", ")}',
        ),
      );
    }

    return await repository.getEarnings(
      conductorId: conductorId,
      periodo: periodo.toLowerCase(),
    );
  }
}
