/// Fuente de datos abstracta para operaciones con la API del conductor
/// 
/// Define el contrato para comunicarse con el backend (API REST).
/// Puede tener múltiples implementaciones:
/// - ConductorRemoteDataSourceImpl: Implementación real con HTTP
/// - ConductorRemoteDataSourceMock: Mock para testing
/// 
/// NOTA PARA MIGRACIÓN A MICROSERVICIOS:
/// - Esta interfaz representa la comunicación con un microservicio específico
/// - Cuando migres a microservicios, solo cambias la URL base
/// - Ejemplo: http://localhost:8080/conductor-service/api/v1/profile
abstract class ConductorRemoteDataSource {
  /// Obtiene el perfil del conductor desde la API
  Future<Map<String, dynamic>> getProfile(int conductorId);

  /// Actualiza el perfil en la API
  Future<Map<String, dynamic>> updateProfile(
    int conductorId,
    Map<String, dynamic> profileData,
  );

  /// Actualiza la licencia en la API
  Future<Map<String, dynamic>> updateLicense(
    int conductorId,
    Map<String, dynamic> licenseData,
  );

  /// Actualiza el vehículo en la API
  Future<Map<String, dynamic>> updateVehicle(
    int conductorId,
    Map<String, dynamic> vehicleData,
  );

  /// Envía el perfil para aprobación
  Future<Map<String, dynamic>> submitForApproval(int conductorId);

  /// Obtiene el estado de verificación
  Future<Map<String, dynamic>> getVerificationStatus(int conductorId);

  /// Obtiene estadísticas del conductor
  Future<Map<String, dynamic>> getStatistics(int conductorId);

  /// Obtiene ganancias por período
  Future<Map<String, dynamic>> getEarnings(int conductorId, String periodo);

  /// Obtiene historial de viajes
  Future<List<Map<String, dynamic>>> getTripHistory(int conductorId);

  /// Obtiene viajes activos
  Future<List<Map<String, dynamic>>> getActiveTrips(int conductorId);

  /// Actualiza disponibilidad
  Future<void> updateAvailability(int conductorId, bool disponible);

  /// Actualiza ubicación en tiempo real
  Future<void> updateLocation(int conductorId, double latitud, double longitud);
}
