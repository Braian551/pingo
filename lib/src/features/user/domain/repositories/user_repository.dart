import 'package:viax/src/core/error/result.dart';
import '../entities/user.dart';
import '../entities/auth_session.dart';

/// Repositorio de AutenticaciÃ³n y Usuarios (Contrato del Dominio)
/// 
/// Define las operaciones disponibles para gestiÃ³n de usuarios y autenticaciÃ³n.
/// Esta es una interfaz abstracta que serÃ¡ implementada en la capa de datos.
/// 
/// PRINCIPIOS:
/// - Contrato puro (no implementa nada)
/// - Retorna Result<T> para manejo funcional de errores
/// - Sin dependencias de frameworks (HTTP, BD, etc.)
/// - Parte del microservicio de usuarios
abstract class UserRepository {
  /// Registrar un nuevo usuario en el sistema
  /// 
  /// [nombre] Nombre del usuario
  /// [apellido] Apellido del usuario
  /// [email] Email (Ãºnico en el sistema)
  /// [telefono] TelÃ©fono de contacto
  /// [password] ContraseÃ±a (serÃ¡ hasheada en el backend)
  /// [direccion] DirecciÃ³n opcional
  /// [latitud] Latitud de la ubicaciÃ³n
  /// [longitud] Longitud de la ubicaciÃ³n
  /// [ciudad] Ciudad
  /// [departamento] Departamento/Estado
  /// [pais] PaÃ­s (default: Colombia)
  /// 
  /// Retorna [Result<AuthSession>] con la sesiÃ³n creada si es exitoso
  Future<Result<AuthSession>> register({
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

  /// Iniciar sesiÃ³n con credenciales
  /// 
  /// [email] Email del usuario
  /// [password] ContraseÃ±a
  /// 
  /// Retorna [Result<AuthSession>] con la sesiÃ³n activa si es exitoso
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });

  /// Cerrar sesiÃ³n del usuario actual
  /// 
  /// Retorna [Result<void>] indicando Ã©xito o error
  Future<Result<void>> logout();

  /// Obtener perfil del usuario actual
  /// 
  /// [userId] ID del usuario (opcional si hay sesiÃ³n activa)
  /// [email] Email del usuario (alternativo a userId)
  /// 
  /// Retorna [Result<User>] con los datos del usuario
  Future<Result<User>> getProfile({int? userId, String? email});

  /// Actualizar perfil del usuario
  /// 
  /// [userId] ID del usuario
  /// [nombre] Nuevo nombre (opcional)
  /// [apellido] Nuevo apellido (opcional)
  /// [telefono] Nuevo telÃ©fono (opcional)
  /// 
  /// Retorna [Result<User>] con el perfil actualizado
  Future<Result<User>> updateProfile({
    required int userId,
    String? nombre,
    String? apellido,
    String? telefono,
  });

  /// Actualizar o crear ubicaciÃ³n principal del usuario
  /// 
  /// [userId] ID del usuario
  /// [direccion] DirecciÃ³n
  /// [latitud] Latitud
  /// [longitud] Longitud
  /// [ciudad] Ciudad
  /// [departamento] Departamento
  /// [pais] PaÃ­s
  /// 
  /// Retorna [Result<UserLocation>] con la ubicaciÃ³n actualizada
  Future<Result<UserLocation>> updateLocation({
    required int userId,
    String? direccion,
    double? latitud,
    double? longitud,
    String? ciudad,
    String? departamento,
    String? pais,
  });

  /// Verificar si un usuario existe en el sistema
  /// 
  /// [email] Email a verificar
  /// 
  /// Retorna [Result<bool>] true si el usuario existe
  Future<Result<bool>> checkUserExists(String email);

  /// Obtener la sesiÃ³n guardada localmente (si existe)
  /// 
  /// Retorna [Result<AuthSession?>] con la sesiÃ³n si estÃ¡ guardada
  Future<Result<AuthSession?>> getSavedSession();

  /// Guardar sesiÃ³n localmente
  /// 
  /// [session] SesiÃ³n a guardar
  /// 
  /// Retorna [Result<void>] indicando Ã©xito o error
  Future<Result<void>> saveSession(AuthSession session);

  /// Limpiar sesiÃ³n guardada localmente
  /// 
  /// Retorna [Result<void>] indicando Ã©xito o error
  Future<Result<void>> clearSession();
}
