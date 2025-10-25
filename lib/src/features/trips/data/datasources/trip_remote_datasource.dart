import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ping_go/src/core/config/app_config.dart';
import 'package:ping_go/src/core/error/exceptions.dart';
import '../models/trip_model.dart';

/// Interfaz abstracta para el datasource remoto de viajes
abstract class TripRemoteDataSource {
  Future<TripModel> createTrip({
    required int usuarioId,
    required String tipoServicio,
    required Map<String, dynamic> origen,
    required Map<String, dynamic> destino,
  });

  Future<TripModel> getTripById(int tripId);
  Future<List<TripModel>> getActiveTrips(int usuarioId);
  Future<List<TripModel>> getTripHistory(int usuarioId);
  Future<List<TripModel>> getConductorActiveTrips(int conductorId);
  Future<List<TripModel>> getConductorTripHistory(int conductorId);
  Future<TripModel> acceptTrip(int tripId, int conductorId);
  Future<TripModel> startTrip(int tripId);
  Future<TripModel> completeTrip(int tripId, double precioFinal, double? distanciaReal);
  Future<TripModel> cancelTrip(int tripId, String motivo);
  Future<void> rateConductor(int tripId, int calificacion, String? comentario);
  Future<void> rateUser(int tripId, int calificacion, String? comentario);
  Future<List<Map<String, dynamic>>> findNearbyDrivers(double lat, double lng, String tipo, double radius);
}

/// Implementación del datasource remoto usando HTTP
class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  TripRemoteDataSourceImpl({
    required this.client,
    String? baseUrl,
  }) : baseUrl = baseUrl ?? AppConfig.tripServiceUrl;

  @override
  Future<TripModel> createTrip({
    required int usuarioId,
    required String tipoServicio,
    required Map<String, dynamic> origen,
    required Map<String, dynamic> destino,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/create_trip.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'usuario_id': usuarioId,
          'tipo_servicio': tipoServicio,
          'origen': origen,
          'destino': destino,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TripModel.fromJson(data['trip']);
        } else {
          throw ServerException(data['message'] ?? 'Error al crear viaje');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<TripModel> getTripById(int tripId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/get_trip.php?trip_id=$tripId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TripModel.fromJson(data['trip']);
        } else {
          throw ServerException(data['message'] ?? 'Error al obtener viaje');
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Viaje no encontrado');
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is NotFoundException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<TripModel>> getActiveTrips(int usuarioId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/get_active_trips.php?usuario_id=$usuarioId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> trips = data['trips'] ?? [];
          return trips.map((t) => TripModel.fromJson(t)).toList();
        } else {
          throw ServerException(data['message'] ?? 'Error al obtener viajes');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<TripModel>> getTripHistory(int usuarioId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/get_trip_history.php?usuario_id=$usuarioId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> trips = data['trips'] ?? [];
          return trips.map((t) => TripModel.fromJson(t)).toList();
        } else {
          throw ServerException(data['message'] ?? 'Error al obtener historial');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<TripModel>> getConductorActiveTrips(int conductorId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/get_conductor_active_trips.php?conductor_id=$conductorId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> trips = data['trips'] ?? [];
          return trips.map((t) => TripModel.fromJson(t)).toList();
        } else {
          throw ServerException(data['message'] ?? 'Error al obtener viajes');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<TripModel>> getConductorTripHistory(int conductorId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/get_conductor_history.php?conductor_id=$conductorId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> trips = data['trips'] ?? [];
          return trips.map((t) => TripModel.fromJson(t)).toList();
        } else {
          throw ServerException(data['message'] ?? 'Error al obtener historial');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<TripModel> acceptTrip(int tripId, int conductorId) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/accept_trip.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_id': tripId,
          'conductor_id': conductorId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TripModel.fromJson(data['trip']);
        } else {
          throw ServerException(data['message'] ?? 'Error al aceptar viaje');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<TripModel> startTrip(int tripId) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/start_trip.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'trip_id': tripId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TripModel.fromJson(data['trip']);
        } else {
          throw ServerException(data['message'] ?? 'Error al iniciar viaje');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<TripModel> completeTrip(int tripId, double precioFinal, double? distanciaReal) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/complete_trip.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_id': tripId,
          'precio_final': precioFinal,
          'distancia_real': distanciaReal,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TripModel.fromJson(data['trip']);
        } else {
          throw ServerException(data['message'] ?? 'Error al completar viaje');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<TripModel> cancelTrip(int tripId, String motivo) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/cancel_trip.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_id': tripId,
          'motivo': motivo,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TripModel.fromJson(data['trip']);
        } else {
          throw ServerException(data['message'] ?? 'Error al cancelar viaje');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<void> rateConductor(int tripId, int calificacion, String? comentario) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/rate_conductor.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_id': tripId,
          'calificacion': calificacion,
          'comentario': comentario,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw ServerException(data['message'] ?? 'Error al calificar');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<void> rateUser(int tripId, int calificacion, String? comentario) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/rate_user.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_id': tripId,
          'calificacion': calificacion,
          'comentario': comentario,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw ServerException(data['message'] ?? 'Error al calificar');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> findNearbyDrivers(
    double lat,
    double lng,
    String tipo,
    double radius,
  ) async {
    try {
      final response = await client.get(
        Uri.parse(
          '$baseUrl/find_nearby_drivers.php?latitud=$lat&longitud=$lng&tipo=$tipo&radius=$radius',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['drivers'] ?? []);
        } else {
          throw ServerException(data['message'] ?? 'Error al buscar conductores');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Error de conexión: ${e.toString()}');
    }
  }
}
