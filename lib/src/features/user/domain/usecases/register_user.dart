import 'package:viax/src/core/error/result.dart';
import 'package:viax/src/core/error/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/user_repository.dart';

/// Use Case: Registrar Usuario
/// 
/// Encapsula la lÃ³gica de negocio para registrar un nuevo usuario en el sistema.
/// 
/// RESPONSABILIDADES:
/// - Validar datos de entrada
/// - Invocar el repositorio para crear el usuario
/// - Retornar la sesiÃ³n creada o un error
/// 
/// PRINCIPIOS:
/// - Una responsabilidad: registrar usuario
/// - Sin dependencias de frameworks
/// - Testeable con unit tests
class RegisterUser {
  final UserRepository repository;

  RegisterUser(this.repository);

  /// Ejecutar el caso de uso
  /// 
  /// [nombre] Nombre del usuario (requerido, no vacÃ­o)
  /// [apellido] Apellido del usuario (requerido, no vacÃ­o)
  /// [email] Email vÃ¡lido (requerido)
  /// [telefono] TelÃ©fono (requerido, no vacÃ­o)
  /// [password] ContraseÃ±a (requerido, mÃ­nimo 6 caracteres)
  /// [direccion] DirecciÃ³n (opcional)
  /// [latitud] Latitud (opcional pero recomendado con longitud)
  /// [longitud] Longitud (opcional pero recomendado con latitud)
  /// [ciudad] Ciudad (opcional)
  /// [departamento] Departamento (opcional)
  /// [pais] PaÃ­s (opcional, default: Colombia)
  Future<Result<AuthSession>> call({
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
  }) async {
    // Validaciones de negocio
    if (nombre.trim().isEmpty) {
      return Error(ValidationFailure('El nombre es requerido'));
    }

    if (apellido.trim().isEmpty) {
      return Error(ValidationFailure('El apellido es requerido'));
    }

    if (email.trim().isEmpty) {
      return Error(ValidationFailure('El email es requerido'));
    }

    if (!_isValidEmail(email)) {
      return Error(ValidationFailure('El email no es vÃ¡lido'));
    }

    if (telefono.trim().isEmpty) {
      return Error(ValidationFailure('El telÃ©fono es requerido'));
    }

    if (password.length < 6) {
      return Error(
        ValidationFailure('La contraseÃ±a debe tener al menos 6 caracteres'),
      );
    }

    // Si se proporciona latitud, longitud tambiÃ©n es requerida (y viceversa)
    if ((latitud != null && longitud == null) ||
        (latitud == null && longitud != null)) {
      return Error(
        ValidationFailure(
          'Latitud y longitud deben proporcionarse juntas',
        ),
      );
    }

    // Validar rango de coordenadas si se proporcionan
    if (latitud != null && longitud != null) {
      if (latitud < -90 || latitud > 90) {
        return Error(
          ValidationFailure('Latitud debe estar entre -90 y 90'),
        );
      }
      if (longitud < -180 || longitud > 180) {
        return Error(
          ValidationFailure('Longitud debe estar entre -180 y 180'),
        );
      }
    }

    // Invocar repositorio para registrar
    return await repository.register(
      nombre: nombre.trim(),
      apellido: apellido.trim(),
      email: email.trim().toLowerCase(),
      telefono: telefono.trim(),
      password: password,
      direccion: direccion?.trim(),
      latitud: latitud,
      longitud: longitud,
      ciudad: ciudad?.trim(),
      departamento: departamento?.trim(),
      pais: pais?.trim() ?? 'Colombia',
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
