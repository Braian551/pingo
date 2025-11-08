import '../entities/conductor_profile.dart';
import '../../../../core/error/result.dart';

/// Contrato abstracto del repositorio de conductores
/// 
/// Define las operaciones que se pueden realizar con los datos del conductor
/// sin especificar CÃ“MO se implementan (BD local, API, cache, etc.)
/// 
/// Usa Result<T> para manejo de errores funcional:
/// - Success(data): Cuando la operaciÃ³n es exitosa
/// - Error(failure): Cuando hay un error
/// 
/// NOTA PARA MIGRACIÃ“N A MICROSERVICIOS:
/// - Este contrato permite cambiar fÃ¡cilmente de una implementaciÃ³n
///   local (SQLite) a una remota (API REST de un microservicio)
/// - Solo necesitas crear una nueva implementaciÃ³n sin tocar la capa de dominio
/// - Ejemplo: ConductorRepositoryImpl (API) vs ConductorRepositoryLocal (SQLite)
abstract class ConductorRepository {
  /// Obtiene el perfil completo de un conductor por su ID
  Future<Result<ConductorProfile>> getProfile(int conductorId);

  /// Actualiza el perfil del conductor
  Future<Result<ConductorProfile>> updateProfile(
    int conductorId,
    Map<String, dynamic> profileData,
  );

  /// Actualiza la licencia de conducir
  Future<Result<DriverLicense>> updateLicense(
    int conductorId,
    DriverLicense license,
  );

  /// Actualiza el vehÃ­culo del conductor
  Future<Result<Vehicle>> updateVehicle(
    int conductorId,
    Vehicle vehicle,
  );

  /// EnvÃ­a el perfil para aprobaciÃ³n
  Future<Result<bool>> submitForApproval(int conductorId);

  /// Obtiene el estado de verificaciÃ³n del conductor
  Future<Result<Map<String, dynamic>>> getVerificationStatus(
    int conductorId,
  );

  /// Obtiene estadÃ­sticas del conductor
  Future<Result<Map<String, dynamic>>> getStatistics(int conductorId);

  /// Obtiene ganancias del conductor por perÃ­odo
  Future<Result<Map<String, dynamic>>> getEarnings({
    required int conductorId,
    required String periodo,
  });

  /// Obtiene historial de viajes
  Future<Result<List<Map<String, dynamic>>>> getTripHistory(int conductorId);

  /// Obtiene viajes activos
  Future<Result<List<Map<String, dynamic>>>> getActiveTrips(int conductorId);

  /// Actualiza disponibilidad del conductor
  Future<Result<void>> updateAvailability({
    required int conductorId,
    required bool disponible,
  });

  /// Actualiza ubicaciÃ³n del conductor en tiempo real
  Future<Result<void>> updateLocation({
    required int conductorId,
    required double latitud,
    required double longitud,
  });
}
