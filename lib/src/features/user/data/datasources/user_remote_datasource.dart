/// Contrato para el Datasource Remoto de Usuarios
/// 
/// Define las operaciones de comunicaciÃ³n con el backend (API).
/// Esta es una interfaz abstracta que serÃ¡ implementada con HTTP.
/// 
/// RESPONSABILIDADES:
/// - Definir firma de mÃ©todos para comunicaciÃ³n con API
/// - No contiene lÃ³gica de negocio
/// - Trabaja con Map<String, dynamic> (JSON crudo)
abstract class UserRemoteDataSource {
  /// Registrar usuario en el backend
  /// 
  /// Retorna JSON con datos del usuario creado y ubicaciÃ³n
  /// Lanza [ServerException] si hay error del servidor
  /// Lanza [NetworkException] si no hay conexiÃ³n
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String password,
    String? direccion,
    double? latitud,
    double? longitud,
    String? ciudad,
    String? departamento,
    String? pais,
  });

  /// Login en el backend
  /// 
  /// Retorna JSON con datos del usuario y token (si aplica)
  /// Lanza [ServerException] si credenciales son invÃ¡lidas
  /// Lanza [NetworkException] si no hay conexiÃ³n
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  /// Obtener perfil del usuario
  /// 
  /// Retorna JSON con datos del usuario y ubicaciÃ³n principal
  /// Lanza [ServerException] si el usuario no existe
  /// Lanza [NetworkException] si no hay conexiÃ³n
  Future<Map<String, dynamic>> getProfile({int? userId, String? email});

  /// Actualizar perfil del usuario
  /// 
  /// Retorna JSON con el perfil actualizado
  /// Lanza [ServerException] si hay error al actualizar
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    String? nombre,
    String? apellido,
    String? telefono,
  });

  /// Actualizar ubicaciÃ³n del usuario
  /// 
  /// Retorna JSON con la ubicaciÃ³n actualizada
  /// Lanza [ServerException] si hay error al actualizar
  Future<Map<String, dynamic>> updateLocation({
    required int userId,
    String? direccion,
    double? latitud,
    double? longitud,
    String? ciudad,
    String? departamento,
    String? pais,
  });

  /// Verificar si un usuario existe
  /// 
  /// Retorna JSON con campo 'exists': true/false
  Future<Map<String, dynamic>> checkUserExists(String email);
}
