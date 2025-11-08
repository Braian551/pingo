/// Contrato para el Datasource Local de Usuarios
/// 
/// Define las operaciones de almacenamiento local (sesiones).
/// Esta es una interfaz abstracta que serÃ¡ implementada con SharedPreferences.
/// 
/// RESPONSABILIDADES:
/// - Definir firma de mÃ©todos para almacenamiento local
/// - Guardar y recuperar sesiones de usuario
/// - Trabajar con Map<String, dynamic> (JSON)
abstract class UserLocalDataSource {
  /// Guardar sesiÃ³n del usuario localmente
  /// 
  /// [sessionData] JSON con datos de la sesiÃ³n
  /// Lanza [CacheException] si hay error al guardar
  Future<void> saveSession(Map<String, dynamic> sessionData);

  /// Obtener sesiÃ³n guardada localmente
  /// 
  /// Retorna JSON con datos de la sesiÃ³n o null si no existe
  /// Lanza [CacheException] si hay error al leer
  Future<Map<String, dynamic>?> getSavedSession();

  /// Limpiar sesiÃ³n guardada
  /// 
  /// Lanza [CacheException] si hay error al limpiar
  Future<void> clearSession();
}
