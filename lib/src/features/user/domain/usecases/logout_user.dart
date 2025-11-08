import 'package:viax/src/core/error/result.dart';
import '../repositories/user_repository.dart';

/// Use Case: Logout de Usuario
/// 
/// Encapsula la lÃ³gica de negocio para cerrar sesiÃ³n.
/// 
/// RESPONSABILIDADES:
/// - Limpiar sesiÃ³n local
/// - Notificar al servidor (si es necesario)
class LogoutUser {
  final UserRepository repository;

  LogoutUser(this.repository);

  /// Ejecutar el caso de uso
  Future<Result<void>> call() async {
    return await repository.logout();
  }
}
