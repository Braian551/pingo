import 'package:viax/src/core/error/result.dart';
import 'package:viax/src/core/error/failures.dart';
import '../repositories/conductor_repository.dart';

/// Use Case: Actualizar UbicaciÃ³n del Conductor
/// 
/// Encapsula la lÃ³gica de negocio para actualizar ubicaciÃ³n en tiempo real.
class UpdateConductorLocation {
  final ConductorRepository repository;

  UpdateConductorLocation(this.repository);

  /// Ejecutar el caso de uso
  /// 
  /// [conductorId] ID del conductor (requerido)
  /// [latitud] Latitud actual (requerido)
  /// [longitud] Longitud actual (requerido)
  Future<Result<void>> call({
    required int conductorId,
    required double latitud,
    required double longitud,
  }) async {
    if (conductorId <= 0) {
      return Error(ValidationFailure('ID de conductor invÃ¡lido'));
    }

    // Validar coordenadas
    if (latitud < -90 || latitud > 90) {
      return Error(ValidationFailure('Latitud debe estar entre -90 y 90'));
    }

    if (longitud < -180 || longitud > 180) {
      return Error(ValidationFailure('Longitud debe estar entre -180 y 180'));
    }

    return await repository.updateLocation(
      conductorId: conductorId,
      latitud: latitud,
      longitud: longitud,
    );
  }
}
