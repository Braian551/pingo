import 'failures.dart';

/// Tipo Result para manejo funcional de errores sin dependencias externas
/// 
/// Inspirado en el patrón Either de programación funcional:
/// - Success<T>: Operación exitosa con resultado de tipo T
/// - Error: Operación fallida con un Failure
/// 
/// USO:
/// ```dart
/// Result<User> result = await repository.getUser(id);
/// return result.when(
///   success: (user) => Text(user.name),
///   error: (failure) => Text(failure.message),
/// );
/// ```
/// 
/// NOTA PARA MIGRACIÓN A MICROSERVICIOS:
/// - Este patrón facilita el manejo de respuestas HTTP de APIs
/// - Permite propagar errores sin excepciones
sealed class Result<T> {
  const Result();

  /// Ejecuta una función según el resultado
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else {
      return error((this as Error<T>).failure);
    }
  }

  /// Ejecuta una función solo si es exitoso
  Result<R> map<R>(R Function(T data) transform) {
    return when(
      success: (data) => Success(transform(data)),
      error: (failure) => Error(failure),
    );
  }

  /// Ejecuta una función asíncrona solo si es exitoso
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) transform) async {
    return when(
      success: (data) async => Success(await transform(data)),
      error: (failure) => Future.value(Error(failure)),
    );
  }

  /// Verifica si el resultado es exitoso
  bool get isSuccess => this is Success<T>;

  /// Verifica si el resultado es un error
  bool get isError => this is Error<T>;

  /// Obtiene el dato si es exitoso, null si es error
  T? get dataOrNull => when(
        success: (data) => data,
        error: (_) => null,
      );

  /// Obtiene el fallo si es error, null si es exitoso
  Failure? get failureOrNull => when(
        success: (_) => null,
        error: (failure) => failure,
      );
}

/// Resultado exitoso
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Resultado con error
class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}
