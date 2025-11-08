import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';

class TripRequestService {
  static String get baseUrl => AppConfig.baseUrl;

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
      final url = '$baseUrl/user/create_trip_request.php';
      print('ðŸ“ Enviando solicitud a: $url');
      
      final requestBody = {
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
      };
      
      print('ðŸ“¦ Datos enviados: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifica tu conexiÃ³n.');
        },
      );

      print('ðŸ“¥ Respuesta recibida - Status: ${response.statusCode}');
      print('ðŸ“„ Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('âœ… Solicitud creada exitosamente');
          return data;
        } else {
          final errorMsg = data['message'] ?? 'Error al crear solicitud';
          print('âŒ Error del servidor: $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Error del servidor: ${response.statusCode} - ${response.body}';
        print('âŒ $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('âŒ Error en createTripRequest: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception('No se pudo conectar al servidor. Verifica tu conexiÃ³n.');
      }
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
      print('ðŸš« Cancelando solicitud ID: $solicitudId');
      
      final url = '$baseUrl/user/cancel_trip_request.php';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'solicitud_id': solicitudId,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado al cancelar');
        },
      );

      print('ðŸ“¥ Respuesta de cancelaciÃ³n - Status: ${response.statusCode}');
      print('ðŸ“„ Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('âœ… Solicitud cancelada exitosamente');
          return true;
        } else {
          print('âŒ Error al cancelar: ${data['message']}');
          throw Exception(data['message'] ?? 'Error al cancelar la solicitud');
        }
      } else {
        print('âŒ Error del servidor: ${response.statusCode}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('âŒ Error cancelando solicitud: $e');
      rethrow;
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

  /// Obtener estado completo del viaje con info del conductor
  static Future<Map<String, dynamic>> getTripStatus({
    required int solicitudId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/get_trip_status.php?solicitud_id=$solicitudId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Error al obtener estado: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('âŒ Error obteniendo estado: $e');
      return {
        'success': false,
        'message': 'Error de conexiÃ³n: $e',
      };
    }
  }

  /// Cancelar solicitud con parÃ¡metros completos
  static Future<Map<String, dynamic>> cancelTripRequestWithReason({
    required int solicitudId,
    required int clienteId,
    String motivo = 'Cliente cancelÃ³',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/cancel_trip_request.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'solicitud_id': solicitudId,
          'cliente_id': clienteId,
          'motivo': motivo,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('âŒ Error cancelando solicitud: $e');
      return {
        'success': false,
        'message': 'Error de conexiÃ³n: $e',
      };
    }
  }
}
