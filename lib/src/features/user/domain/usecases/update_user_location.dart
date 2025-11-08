import 'package:viax/src/core/error/result.dart';
import 'package:viax/src/core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

/// Use Case: Actualizar UbicaciÃ³n del Usuario
/// 
/// Encapsula la lÃ³gica de negocio para actualizar la ubicaciÃ³n principal.
/// 
/// RESPONSABILIDADES:
/// - Validar datos de ubicaciÃ³n
/// - Invocar el repositorio para actualizar
/// - Retornar la ubicaciÃ³n actualizada o un error
class UpdateUserLocation {
  final UserRepository repository;

  UpdateUserLocation(this.repository);

  /// Ejecutar el caso de uso
  /// 
  /// [userId] ID del usuario (requerido)
  /// [direccion] DirecciÃ³n (opcional)
  /// [latitud] Latitud (opcional pero recomendado con longitud)
  /// [longitud] Longitud (opcional pero recomendado con latitud)
  /// [ciudad] Ciudad (opcional)
  /// [departamento] Departamento (opcional)
  /// [pais] PaÃ­s (opcional)
  Future<Result<UserLocation>> call({
    required int userId,
    String? direccion,
    double? latitud,
    double? longitud,
    String? ciudad,
    String? departamento,
    String? pais,
  }) async {
    // ValidaciÃ³n: userId debe ser positivo
    if (userId <= 0) {
      return Error(ValidationFailure('ID de usuario invÃ¡lido'));
    }

    // Si se proporciona latitud, longitud tambiÃ©n es requerida (y viceversa)
    if ((latitud != null && longitud == null) ||
        (latitud == null && longitud != null)) {
      return Error(
        ValidationFailure(
          'Latitud y longitud deben proporcionarse juntas',
        ),
      );
    }

    // Validar rango de coordenadas si se proporcionan
    if (latitud != null && longitud != null) {
      if (latitud < -90 || latitud > 90) {
        return Error(
          ValidationFailure('Latitud debe estar entre -90 y 90'),
        );
      }
      if (longitud < -180 || longitud > 180) {
        return Error(
          ValidationFailure('Longitud debe estar entre -180 y 180'),
        );
      }
    }

    return await repository.updateLocation(
      userId: userId,
      direccion: direccion?.trim(),
      latitud: latitud,
      longitud: longitud,
      ciudad: ciudad?.trim(),
      departamento: departamento?.trim(),
      pais: pais?.trim(),
    );
  }
}
