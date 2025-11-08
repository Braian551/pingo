import 'package:viax/src/core/error/result.dart';
import 'package:viax/src/core/error/failures.dart';
import 'package:viax/src/core/error/exceptions.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_datasource.dart';

/// ImplementaciÃ³n del repositorio de mapas
class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource remoteDataSource;

  MapRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<Location>> geocodeAddress(String address) async {
    try {
      final location = await remoteDataSource.geocodeAddress(address);
      return Success(location);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al geocodificar: $e'));
    }
  }

  @override
  Future<Result<Location>> reverseGeocode(double lat, double lng) async {
    try {
      final location = await remoteDataSource.reverseGeocode(lat, lng);
      return Success(location);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al obtener direcciÃ³n: $e'));
    }
  }

  @override
  Future<Result<Route>> calculateRoute(Location origin, Location destination) async {
    try {
      final originJson = {
        'latitud': origin.latitud,
        'longitud': origin.longitud,
      };

      final destinationJson = {
        'latitud': destination.latitud,
        'longitud': destination.longitud,
      };

      final route = await remoteDataSource.calculateRoute(originJson, destinationJson);
      return Success(route);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al calcular ruta: $e'));
    }
  }

  @override
  Future<Result<double>> calculateDistance(Location origin, Location destination) async {
    try {
      final originJson = {
        'latitud': origin.latitud,
        'longitud': origin.longitud,
      };

      final destinationJson = {
        'latitud': destination.latitud,
        'longitud': destination.longitud,
      };

      final distance = await remoteDataSource.calculateDistance(originJson, destinationJson);
      return Success(distance);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al calcular distancia: $e'));
    }
  }

  @override
  Future<Result<List<Location>>> searchNearbyPlaces({
    required double lat,
    required double lng,
    required String query,
    double radiusKm = 1.0,
  }) async {
    try {
      final places = await remoteDataSource.searchNearbyPlaces(lat, lng, query, radiusKm);
      return Success(places);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Error(ConnectionFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure('Error al buscar lugares: $e'));
    }
  }
}
