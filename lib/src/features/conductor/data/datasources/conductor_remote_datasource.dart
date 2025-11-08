/// Fuente de datos abstracta para operaciones con la API del conductor
/// 
/// Define el contrato para comunicarse con el backend (API REST).
/// Puede tener mÃºltiples implementaciones:
/// - ConductorRemoteDataSourceImpl: ImplementaciÃ³n real con HTTP
/// - ConductorRemoteDataSourceMock: Mock para testing
/// 
/// NOTA PARA MIGRACIÃ“N A MICROSERVICIOS:
/// - Esta interfaz representa la comunicaciÃ³n con un microservicio especÃ­fico
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

  /// Actualiza el vehÃ­culo en la API
  Future<Map<String, dynamic>> updateVehicle(
    int conductorId,
    Map<String, dynamic> vehicleData,
  );

  /// EnvÃ­a el perfil para aprobaciÃ³n
  Future<Map<String, dynamic>> submitForApproval(int conductorId);

  /// Obtiene el estado de verificaciÃ³n
  Future<Map<String, dynamic>> getVerificationStatus(int conductorId);

  /// Obtiene estadÃ­sticas del conductor
  Future<Map<String, dynamic>> getStatistics(int conductorId);

  /// Obtiene ganancias por perÃ­odo
  Future<Map<String, dynamic>> getEarnings(int conductorId, String periodo);

  /// Obtiene historial de viajes
  Future<List<Map<String, dynamic>>> getTripHistory(int conductorId);

  /// Obtiene viajes activos
  Future<List<Map<String, dynamic>>> getActiveTrips(int conductorId);

  /// Actualiza disponibilidad
  Future<void> updateAvailability(int conductorId, bool disponible);

  /// Actualiza ubicaciÃ³n en tiempo real
  Future<void> updateLocation(int conductorId, double latitud, double longitud);
}
