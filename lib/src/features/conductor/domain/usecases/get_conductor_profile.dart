import '../../../../core/error/result.dart';
import '../entities/conductor_profile.dart';
import '../repositories/conductor_repository.dart';

/// Caso de uso: Obtener perfil del conductor
/// 
/// Encapsula la lÃ³gica de negocio para obtener el perfil de un conductor.
/// Sigue el principio de responsabilidad Ãºnica (SRP).
/// 
/// NOTA PARA MIGRACIÃ“N A MICROSERVICIOS:
/// - Este use case puede invocar mÃºltiples repositorios si es necesario
/// - Por ejemplo, podrÃ­a consultar el servicio de conductores Y el servicio de pagos
/// - Facilita la orquestaciÃ³n de llamadas a diferentes microservicios
class GetConductorProfile {
  final ConductorRepository repository;

  GetConductorProfile(this.repository);

  /// Ejecuta el caso de uso
  /// 
  /// ParÃ¡metros:
  /// - [conductorId]: ID del conductor a consultar
  /// 
  /// Retorna:
  /// - Success<ConductorProfile>: Si se encontrÃ³ el perfil
  /// - Error: Si ocurriÃ³ un error (network, servidor, etc.)
  Future<Result<ConductorProfile>> call(int conductorId) async {
    return await repository.getProfile(conductorId);
  }
}
