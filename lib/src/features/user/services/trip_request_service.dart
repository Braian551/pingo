import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../global/config/api_config.dart';

class TripRequestService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// Crear una nueva solicitud de viaje
  static Future<Map<String, dynamic>> createTripRequest({
    required int userId,
    required double latitudOrigen,
    required double longitudOrigen,
    required String direccionOrigen,
    required double latitudDestino,
    required double longitudDestino,
    required String direccionDestino,
    required String tipoServicio, // 'viaje' o 'paquete'
    required String tipoVehiculo, // 'moto', 'carro', 'moto_carga', 'carro_carga'
    required double distanciaKm,
    required int duracionMinutos,
    required double precioEstimado,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/create_trip_request.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': userId,
          'latitud_origen': latitudOrigen,
          'longitud_origen': longitudOrigen,
          'direccion_origen': direccionOrigen,
          'latitud_destino': latitudDestino,
          'longitud_destino': longitudDestino,
          'direccion_destino': direccionDestino,
          'tipo_servicio': tipoServicio,
          'tipo_vehiculo': tipoVehiculo,
          'distancia_km': distanciaKm,
          'duracion_minutos': duracionMinutos,
          'precio_estimado': precioEstimado,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Error al crear solicitud');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear solicitud de viaje: $e');
    }
  }

  /// Buscar conductores cercanos disponibles
  static Future<List<Map<String, dynamic>>> findNearbyDrivers({
    required double latitude,
    required double longitude,
    required String vehicleType,
    double radiusKm = 5.0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/find_nearby_drivers.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitud': latitude,
          'longitud': longitude,
          'tipo_vehiculo': vehicleType,
          'radio_km': radiusKm,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['conductores'] ?? []);
        } else {
          return [];
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error buscando conductores cercanos: $e');
      return [];
    }
  }

  /// Cancelar solicitud de viaje
  static Future<bool> cancelTripRequest(int solicitudId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/cancel_trip_request.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'solicitud_id': solicitudId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error cancelando solicitud: $e');
      return false;
    }
  }

  /// Obtener estado de la solicitud
  static Future<Map<String, dynamic>?> getTripRequestStatus(int solicitudId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/get_trip_status.php?solicitud_id=$solicitudId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['solicitud'];
        }
      }
      return null;
    } catch (e) {
      print('Error obteniendo estado de solicitud: $e');
      return null;
    }
  }
}
