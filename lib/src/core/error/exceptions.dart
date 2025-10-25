/// Excepciones para la capa de datos
/// 
/// Estas excepciones se lanzan en datasources y se convierten
/// en Failures en la capa de repositorio.
/// 
/// NOTA: Las excepciones son para errores técnicos/infraestructura,
/// los Failures son para la lógica de negocio.

/// Excepción base
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Error del servidor (HTTP 500, 400, etc.)
class ServerException extends AppException {
  const ServerException(String message) : super(message);
}

/// Error de conexión/red
class NetworkException extends AppException {
  const NetworkException(String message) : super(message);
}

/// Recurso no encontrado (HTTP 404)
class NotFoundException extends AppException {
  const NotFoundException(String message) : super(message);
}

/// Error de caché/BD local
class CacheException extends AppException {
  const CacheException(String message) : super(message);
}

/// Error de autenticación (HTTP 401)
class AuthException extends AppException {
  const AuthException(String message) : super(message);
}

/// Error de autorización (HTTP 403)
class UnauthorizedException extends AppException {
  const UnauthorizedException(String message) : super(message);
}

/// Error de validación de datos
class ValidationException extends AppException {
  const ValidationException(String message) : super(message);
}
