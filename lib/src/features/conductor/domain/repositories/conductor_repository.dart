import '../entities/conductor_profile.dart';
import '../../../../core/error/result.dart';

/// Contrato abstracto del repositorio de conductores
/// 
/// Define las operaciones que se pueden realizar con los datos del conductor
/// sin especificar CÓMO se implementan (BD local, API, cache, etc.)
/// 
/// Usa Result<T> para manejo de errores funcional:
/// - Success(data): Cuando la operación es exitosa
/// - Error(failure): Cuando hay un error
/// 
/// NOTA PARA MIGRACIÓN A MICROSERVICIOS:
/// - Este contrato permite cambiar fácilmente de una implementación
///   local (SQLite) a una remota (API REST de un microservicio)
/// - Solo necesitas crear una nueva implementación sin tocar la capa de dominio
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

  /// Actualiza el vehículo del conductor
  Future<Result<Vehicle>> updateVehicle(
    int conductorId,
    Vehicle vehicle,
  );

  /// Envía el perfil para aprobación
  Future<Result<bool>> submitForApproval(int conductorId);

  /// Obtiene el estado de verificación del conductor
  Future<Result<Map<String, dynamic>>> getVerificationStatus(
    int conductorId,
  );

  /// Obtiene estadísticas del conductor
  Future<Result<Map<String, dynamic>>> getStatistics(int conductorId);

  /// Obtiene ganancias del conductor por período
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

  /// Actualiza ubicación del conductor en tiempo real
  Future<Result<void>> updateLocation({
    required int conductorId,
    required double latitud,
    required double longitud,
  });
}
