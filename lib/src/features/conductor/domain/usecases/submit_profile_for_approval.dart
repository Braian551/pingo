import '../../../../core/error/result.dart';
import '../../../../core/error/failures.dart';
import '../repositories/conductor_repository.dart';

/// Caso de uso: Enviar perfil para aprobaciÃ³n
/// 
/// Verifica que el perfil estÃ© completo antes de enviar para aprobaciÃ³n.
/// Este es un buen ejemplo de lÃ³gica de negocio en el dominio.
class SubmitProfileForApproval {
  final ConductorRepository repository;

  SubmitProfileForApproval(this.repository);

  Future<Result<bool>> call(int conductorId) async {
    // Primero verificamos que el perfil estÃ© completo
    final profileResult = await repository.getProfile(conductorId);

    return await profileResult.when(
      success: (profile) async {
        if (!profile.isProfileComplete) {
          return const Error(
            ValidationFailure(
              'El perfil debe estar completo antes de enviar para aprobaciÃ³n',
            ),
          );
        }

        return await repository.submitForApproval(conductorId);
      },
      error: (failure) => Error(failure),
    );
  }
}
