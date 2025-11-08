import 'package:viax/src/core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/user_repository.dart';

/// Use Case: Obtener SesiÃ³n Guardada
/// 
/// Encapsula la lÃ³gica de negocio para obtener una sesiÃ³n guardada localmente.
/// Ãštil para "recordar sesiÃ³n" o auto-login.
/// 
/// RESPONSABILIDADES:
/// - Obtener sesiÃ³n del almacenamiento local
/// - Validar que la sesiÃ³n siga siendo vÃ¡lida
/// - Retornar la sesiÃ³n o null si no existe/expirÃ³
class GetSavedSession {
  final UserRepository repository;

  GetSavedSession(this.repository);

  /// Ejecutar el caso de uso
  Future<Result<AuthSession?>> call() async {
    final result = await repository.getSavedSession();

    // Si obtuvimos una sesiÃ³n exitosamente, validar que estÃ© activa
    if (result is Success<AuthSession?> && result.data != null) {
      final session = result.data!;
      
      // Si la sesiÃ³n expirÃ³, limpiarla y retornar null
      if (!session.isValid) {
        await repository.clearSession();
        return Success(null);
      }
    }

    return result;
  }
}
