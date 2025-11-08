import '../../../../core/error/result.dart';
import '../entities/conductor_profile.dart';
import '../repositories/conductor_repository.dart';

/// Caso de uso: Actualizar perfil del conductor
/// 
/// Encapsula la lÃ³gica de negocio para actualizar el perfil.
/// Puede incluir validaciones de negocio antes de persistir.
class UpdateConductorProfile {
  final ConductorRepository repository;

  UpdateConductorProfile(this.repository);

  /// Ejecuta el caso de uso
  /// 
  /// Validaciones de negocio que podrÃ­an agregarse:
  /// - Verificar que el conductor tiene permisos
  /// - Validar formato de telÃ©fono
  /// - Validar que la direcciÃ³n sea vÃ¡lida
  Future<Result<ConductorProfile>> call(
    int conductorId,
    Map<String, dynamic> profileData,
  ) async {
    // AquÃ­ podrÃ­as agregar validaciones de negocio
    // Por ejemplo: validar formato de telÃ©fono, etc.
    
    return await repository.updateProfile(conductorId, profileData);
  }
}
