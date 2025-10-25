import 'package:ping_go/src/core/error/result.dart';
import 'package:ping_go/src/core/error/failures.dart';
import 'package:ping_go/src/core/error/exceptions.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_remote_datasource.dart';

/// Implementación concreta del repositorio de viajes
class TripRepositoryImpl implements TripRepository {
  final TripRemoteDataSource remoteDataSource;

  TripRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<Trip>> createTrip({
    required int usuarioId,
    required TripType tipoServicio,
    required TripLocation origen,
    required TripLocation destino,
  }) async {
    try {
      final origenJson = {
        'direccion': origen.direccion,
        'latitud': origen.latitud,
        'longitud': origen.longitud,
        'referencia': origen.referencia,
      };

      final destinoJson = {
        'direccion': destino.direccion,
        'latitud': destino.latitud,
        'longitud': destino.longitud,
        'referencia': destino.referencia,
      };

      final trip = await remoteDataSource.createTrip(
        usuarioId: usuarioId,
        tipoServicio: tipoServicio.name,
        origen: origenJson,
        destino: destinoJson,
      );

      return Success(trip);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al crear viaje: $e'));
    }
  }

  @override
  Future<Result<Trip>> getTripById(int tripId) async {
    try {
      final trip = await remoteDataSource.getTripById(tripId);
      return Success(trip);
    } on NotFoundException catch (e) {
      return Error(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al obtener viaje: $e'));
    }
  }

  @override
  Future<Result<List<Trip>>> getActiveTrips(int usuarioId) async {
    try {
      final trips = await remoteDataSource.getActiveTrips(usuarioId);
      return Success(trips);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al obtener viajes activos: $e'));
    }
  }

  @override
  Future<Result<List<Trip>>> getTripHistory(int usuarioId) async {
    try {
      final trips = await remoteDataSource.getTripHistory(usuarioId);
      return Success(trips);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al obtener historial: $e'));
    }
  }

  @override
  Future<Result<List<Trip>>> getConductorActiveTrips(int conductorId) async {
    try {
      final trips = await remoteDataSource.getConductorActiveTrips(conductorId);
      return Success(trips);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al obtener viajes del conductor: $e'));
    }
  }

  @override
  Future<Result<List<Trip>>> getConductorTripHistory(int conductorId) async {
    try {
      final trips = await remoteDataSource.getConductorTripHistory(conductorId);
      return Success(trips);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al obtener historial del conductor: $e'));
    }
  }

  @override
  Future<Result<Trip>> acceptTrip(int tripId, int conductorId) async {
    try {
      final trip = await remoteDataSource.acceptTrip(tripId, conductorId);
      return Success(trip);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al aceptar viaje: $e'));
    }
  }

  @override
  Future<Result<Trip>> startTrip(int tripId) async {
    try {
      final trip = await remoteDataSource.startTrip(tripId);
      return Success(trip);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al iniciar viaje: $e'));
    }
  }

  @override
  Future<Result<Trip>> completeTrip({
    required int tripId,
    required double precioFinal,
    double? distanciaReal,
  }) async {
    try {
      final trip = await remoteDataSource.completeTrip(
        tripId,
        precioFinal,
        distanciaReal,
      );
      return Success(trip);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al completar viaje: $e'));
    }
  }

  @override
  Future<Result<Trip>> cancelTrip({
    required int tripId,
    required String motivo,
  }) async {
    try {
      final trip = await remoteDataSource.cancelTrip(tripId, motivo);
      return Success(trip);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al cancelar viaje: $e'));
    }
  }

  @override
  Future<Result<void>> rateConductor({
    required int tripId,
    required int calificacion,
    String? comentario,
  }) async {
    try {
      await remoteDataSource.rateConductor(tripId, calificacion, comentario);
      return const Success(null);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al calificar: $e'));
    }
  }

  @override
  Future<Result<void>> rateUser({
    required int tripId,
    required int calificacion,
    String? comentario,
  }) async {
    try {
      await remoteDataSource.rateUser(tripId, calificacion, comentario);
      return const Success(null);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al calificar: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> findNearbyDrivers({
    required double latitud,
    required double longitud,
    required TripType tipoServicio,
    double radiusKm = 5.0,
  }) async {
    try {
      final drivers = await remoteDataSource.findNearbyDrivers(
        latitud,
        longitud,
        tipoServicio.name,
        radiusKm,
      );
      return Success(drivers);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al buscar conductores: $e'));
    }
  }
}
