import 'package:viax/src/core/error/result.dart';
import 'package:viax/src/core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

/// Use Case: Actualizar Perfil de Usuario
/// 
/// Encapsula la lÃ³gica de negocio para actualizar el perfil.
/// 
/// RESPONSABILIDADES:
/// - Validar datos de entrada
/// - Invocar el repositorio para actualizar
/// - Retornar el perfil actualizado o un error
class UpdateUserProfile {
  final UserRepository repository;

  UpdateUserProfile(this.repository);

  /// Ejecutar el caso de uso
  /// 
  /// [userId] ID del usuario (requerido)
  /// [nombre] Nuevo nombre (opcional)
  /// [apellido] Nuevo apellido (opcional)
  /// [telefono] Nuevo telÃ©fono (opcional)
  /// 
  /// Al menos un campo debe ser proporcionado para actualizar
  Future<Result<User>> call({
    required int userId,
    String? nombre,
    String? apellido,
    String? telefono,
  }) async {
    // ValidaciÃ³n: userId debe ser positivo
    if (userId <= 0) {
      return Error(ValidationFailure('ID de usuario invÃ¡lido'));
    }

    // ValidaciÃ³n: al menos un campo debe ser proporcionado
    if (nombre == null && apellido == null && telefono == null) {
      return Error(
        ValidationFailure(
          'Debe proporcionar al menos un campo para actualizar',
        ),
      );
    }

    // Validar que los campos no estÃ©n vacÃ­os si se proporcionan
    if (nombre != null && nombre.trim().isEmpty) {
      return Error(ValidationFailure('El nombre no puede estar vacÃ­o'));
    }

    if (apellido != null && apellido.trim().isEmpty) {
      return Error(ValidationFailure('El apellido no puede estar vacÃ­o'));
    }

    if (telefono != null && telefono.trim().isEmpty) {
      return Error(ValidationFailure('El telÃ©fono no puede estar vacÃ­o'));
    }

    return await repository.updateProfile(
      userId: userId,
      nombre: nombre?.trim(),
      apellido: apellido?.trim(),
      telefono: telefono?.trim(),
    );
  }
}
