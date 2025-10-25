/// Clase base abstracta para representar fallos en la aplicación
/// 
/// Esta clase permite manejar errores de forma tipada y funcional,
/// separando la lógica de dominio de los detalles de implementación.
/// 
/// NOTA PARA MIGRACIÓN A MICROSERVICIOS:
/// - Estas clases de error pueden incluir códigos HTTP para API REST
/// - Facilita el manejo de errores distribuidos entre servicios
abstract class Failure {
  final String message;
  final int? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Fallo de servidor (API, Backend)
class ServerFailure extends Failure {
  const ServerFailure(String message, [int? code]) : super(message, code);
}

/// Fallo de conexión (red, timeout)
class ConnectionFailure extends Failure {
  const ConnectionFailure(String message) : super(message);
}

/// Fallo de cache/base de datos local
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

/// Fallo de validación (datos inválidos)
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Fallo de autenticación
class AuthFailure extends Failure {
  const AuthFailure(String message, [int? code]) : super(message, code);
}

/// Fallo no autorizado (permisos)
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(String message) : super(message, 403);
}

/// Fallo de recurso no encontrado
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message, 404);
}

/// Fallo genérico/desconocido
class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message);
}
