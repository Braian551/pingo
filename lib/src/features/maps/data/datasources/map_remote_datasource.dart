import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:viax/src/core/config/app_config.dart';
import 'package:viax/src/core/error/exceptions.dart';
import '../models/location_model.dart';

/// Interfaz abstracta para el datasource de mapas
abstract class MapRemoteDataSource {
  Future<LocationModel> geocodeAddress(String address);
  Future<LocationModel> reverseGeocode(double lat, double lng);
  Future<RouteModel> calculateRoute(Map<String, dynamic> origin, Map<String, dynamic> destination);
  Future<double> calculateDistance(Map<String, dynamic> origin, Map<String, dynamic> destination);
  Future<List<LocationModel>> searchNearbyPlaces(double lat, double lng, String query, double radius);
}

/// ImplementaciÃ³n del datasource de mapas
class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  MapRemoteDataSourceImpl({
    required this.client,
    String? baseUrl,
  }) : baseUrl = baseUrl ?? AppConfig.mapServiceUrl;

  @override
  Future<LocationModel> geocodeAddress(String address) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/geocode.php?address=${Uri.encodeComponent(address)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return LocationModel.fromJson(data['location']);
        } else {
          throw ServerException(data['message'] ?? 'Error al geocodificar');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexiÃ³n: ${e.toString()}');
    }
  }

  @override
  Future<LocationModel> reverseGeocode(double lat, double lng) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/reverse_geocode.php?lat=$lat&lng=$lng'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return LocationModel.fromJson(data['location']);
        } else {
          throw ServerException(data['message'] ?? 'Error al obtener direcciÃ³n');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexiÃ³n: ${e.toString()}');
    }
  }

  @override
  Future<RouteModel> calculateRoute(
    Map<String, dynamic> origin,
    Map<String, dynamic> destination,
  ) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/calculate_route.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'origin': origin,
          'destination': destination,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return RouteModel.fromJson(data['route']);
        } else {
          throw ServerException(data['message'] ?? 'Error al calcular ruta');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexiÃ³n: ${e.toString()}');
    }
  }

  @override
  Future<double> calculateDistance(
    Map<String, dynamic> origin,
    Map<String, dynamic> destination,
  ) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/calculate_distance.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'origin': origin,
          'destination': destination,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['distance'] as num).toDouble();
        } else {
          throw ServerException(data['message'] ?? 'Error al calcular distancia');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexiÃ³n: ${e.toString()}');
    }
  }

  @override
  Future<List<LocationModel>> searchNearbyPlaces(
    double lat,
    double lng,
    String query,
    double radius,
  ) async {
    try {
      final response = await client.get(
        Uri.parse(
          '$baseUrl/search_places.php?lat=$lat&lng=$lng&query=${Uri.encodeComponent(query)}&radius=$radius',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> places = data['places'] ?? [];
          return places.map((p) => LocationModel.fromJson(p)).toList();
        } else {
          throw ServerException(data['message'] ?? 'Error al buscar lugares');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexiÃ³n: ${e.toString()}');
    }
  }
}
