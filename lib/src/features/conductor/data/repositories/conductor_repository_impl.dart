import '../../domain/entities/conductor_profile.dart';
import '../../domain/repositories/conductor_repository.dart';
import '../../../../core/error/result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../datasources/conductor_remote_datasource.dart';
import '../models/conductor_profile_model.dart';

/// Implementación concreta del repositorio de conductores
/// 
/// RESPONSABILIDADES:
/// 1. Coordina entre datasources (API, BD local, cache)
/// 2. Convierte excepciones técnicas en Failures de negocio
/// 3. Transforma modelos (DTOs) en entidades de dominio
/// 
/// ESTRATEGIA PARA MICROSERVICIOS:
/// - Actualmente usa solo remoteDataSource (API monolítica)
/// - En el futuro, podría combinar múltiples datasources:
///   * remoteDataSource: Para datos del microservicio de conductores
///   * paymentDataSource: Para consultar el microservicio de pagos
///   * localDataSource: Para cache offline
/// 
/// EJEMPLO DE ORQUESTACIÓN:
/// ```dart
/// // Obtener perfil del conductor-service
/// final profile = await conductorRemoteDataSource.getProfile(id);
/// // Obtener balance del payment-service
/// final balance = await paymentDataSource.getBalance(id);
/// // Combinar ambos resultados
/// return Success(profile.copyWith(balance: balance));
/// ```
class ConductorRepositoryImpl implements ConductorRepository {
  final ConductorRemoteDataSource remoteDataSource;
  // En el futuro: final ConductorLocalDataSource localDataSource;

  ConductorRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Result<ConductorProfile>> getProfile(int conductorId) async {
    try {
      final jsonData = await remoteDataSource.getProfile(conductorId);
      final model = ConductorProfileModel.fromJson(jsonData);
      return Success(model); // Model extends Entity, es compatible
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } on NotFoundException catch (e) {
      return Error(NotFoundFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Result<ConductorProfile>> updateProfile(
    int conductorId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      await remoteDataSource.updateProfile(conductorId, profileData);
      // Recargar el perfil actualizado
      return await getProfile(conductorId);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al actualizar perfil: $e'));
    }
  }

  @override
  Future<Result<DriverLicense>> updateLicense(
    int conductorId,
    DriverLicense license,
  ) async {
    try {
      final licenseModel = DriverLicenseModel.fromEntity(license);
      await remoteDataSource.updateLicense(
        conductorId,
        licenseModel.toJson(),
      );
      return Success(license);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al actualizar licencia: $e'));
    }
  }

  @override
  Future<Result<Vehicle>> updateVehicle(
    int conductorId,
    Vehicle vehicle,
  ) async {
    try {
      final vehicleModel = VehicleModel.fromEntity(vehicle);
      await remoteDataSource.updateVehicle(
        conductorId,
        vehicleModel.toJson(),
      );
      return Success(vehicle);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al actualizar vehículo: $e'));
    }
  }

  @override
  Future<Result<bool>> submitForApproval(int conductorId) async {
    try {
      final response = await remoteDataSource.submitForApproval(conductorId);
      return Success(response['success'] == true);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al enviar para aprobación: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getVerificationStatus(
    int conductorId,
  ) async {
    try {
      final data = await remoteDataSource.getVerificationStatus(conductorId);
      return Success(data);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al obtener estado: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getStatistics(int conductorId) async {
    try {
      final data = await remoteDataSource.getStatistics(conductorId);
      return Success(data);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al obtener estadísticas: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getEarnings({
    required int conductorId,
    required String periodo,
  }) async {
    try {
      final data = await remoteDataSource.getEarnings(conductorId, periodo);
      return Success(data);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al obtener ganancias: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getTripHistory(
    int conductorId,
  ) async {
    try {
      final data = await remoteDataSource.getTripHistory(conductorId);
      return Success(data);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al obtener historial: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getActiveTrips(
    int conductorId,
  ) async {
    try {
      final data = await remoteDataSource.getActiveTrips(conductorId);
      return Success(data);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al obtener viajes activos: $e'));
    }
  }

  @override
  Future<Result<void>> updateAvailability({
    required int conductorId,
    required bool disponible,
  }) async {
    try {
      await remoteDataSource.updateAvailability(conductorId, disponible);
      return const Success(null);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al actualizar disponibilidad: $e'));
    }
  }

  @override
  Future<Result<void>> updateLocation({
    required int conductorId,
    required double latitud,
    required double longitud,
  }) async {
    try {
      await remoteDataSource.updateLocation(conductorId, latitud, longitud);
      return const Success(null);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al actualizar ubicación: $e'));
    }
  }
}
