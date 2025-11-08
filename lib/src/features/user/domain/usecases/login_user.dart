import 'package:viax/src/core/error/result.dart';
import 'package:viax/src/core/error/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/user_repository.dart';

/// Use Case: Login de Usuario
/// 
/// Encapsula la lÃ³gica de negocio para autenticar un usuario.
/// 
/// RESPONSABILIDADES:
/// - Validar credenciales de entrada
/// - Invocar el repositorio para autenticar
/// - Guardar la sesiÃ³n localmente
/// - Retornar la sesiÃ³n activa o un error
class LoginUser {
  final UserRepository repository;

  LoginUser(this.repository);

  /// Ejecutar el caso de uso
  /// 
  /// [email] Email del usuario
  /// [password] ContraseÃ±a del usuario
  /// [saveSession] Si debe guardar la sesiÃ³n localmente (default: true)
  Future<Result<AuthSession>> call({
    required String email,
    required String password,
    bool saveSession = true,
  }) async {
    // Validaciones de negocio
    if (email.trim().isEmpty) {
      return Error(ValidationFailure('El email es requerido'));
    }

    if (!_isValidEmail(email)) {
      return Error(ValidationFailure('El email no es vÃ¡lido'));
    }

    if (password.isEmpty) {
      return Error(ValidationFailure('La contraseÃ±a es requerida'));
    }

    // Invocar repositorio para autenticar
    final result = await repository.login(
      email: email.trim().toLowerCase(),
      password: password,
    );

    // Si el login fue exitoso y se debe guardar la sesiÃ³n
    if (result is Success<AuthSession> && saveSession) {
      await repository.saveSession(result.data);
    }

    return result;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
