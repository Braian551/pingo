import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';

/// Servicio para buscar y gestionar solicitudes de viaje (lÃ³gica Uber/DiDi)
/// 
/// Este servicio implementa la lÃ³gica de bÃºsqueda continua de solicitudes
/// cuando el conductor estÃ¡ disponible, similar a Uber/DiDi
class TripRequestSearchService {
  static Timer? _searchTimer;
  static bool _isSearching = false;
  
  /// Radio de bÃºsqueda en kilÃ³metros
  static const double searchRadiusKm = 5.0;
  
  /// Intervalo de bÃºsqueda en segundos
  static const int searchIntervalSeconds = 5;

  /// Inicia la bÃºsqueda continua de solicitudes
  /// 
  /// Busca solicitudes cada X segundos mientras el conductor estÃ© disponible
  static void startSearching({
    required int conductorId,
    required double currentLat,
    required double currentLng,
    required Function(List<Map<String, dynamic>>) onRequestsFound,
    required Function(String) onError,
  }) {
    if (_isSearching) {
      print('âš ï¸ Ya hay una bÃºsqueda activa');
      return;
    }

    print('ðŸ” Iniciando bÃºsqueda de solicitudes...');
    _isSearching = true;

    // Buscar inmediatamente
    _searchRequests(
      conductorId: conductorId,
      currentLat: currentLat,
      currentLng: currentLng,
      onRequestsFound: onRequestsFound,
      onError: onError,
    );

    // Luego buscar cada X segundos
    _searchTimer = Timer.periodic(
      const Duration(seconds: searchIntervalSeconds),
      (timer) {
        _searchRequests(
          conductorId: conductorId,
          currentLat: currentLat,
          currentLng: currentLng,
          onRequestsFound: onRequestsFound,
          onError: onError,
        );
      },
    );
  }

  /// Detiene la bÃºsqueda continua
  static void stopSearching() {
    print('ðŸ›‘ Deteniendo bÃºsqueda de solicitudes');
    _searchTimer?.cancel();
    _searchTimer = null;
    _isSearching = false;
  }

  /// Busca solicitudes pendientes cerca del conductor
  static Future<void> _searchRequests({
    required int conductorId,
    required double currentLat,
    required double currentLng,
    required Function(List<Map<String, dynamic>>) onRequestsFound,
    required Function(String) onError,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.conductorServiceUrl}/get_solicitudes_pendientes.php',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conductor_id': conductorId,
          'latitud_actual': currentLat,
          'longitud_actual': currentLng,
          'radio_km': searchRadiusKm,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final solicitudes = List<Map<String, dynamic>>.from(
            data['solicitudes'] ?? [],
          );
          
          print('âœ… Encontradas ${solicitudes.length} solicitudes');
          onRequestsFound(solicitudes);
        } else {
          print('âš ï¸ Sin solicitudes: ${data['message']}');
          onRequestsFound([]);
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('âŒ Error buscando solicitudes: $e');
      onError(e.toString());
    }
  }

  /// Actualiza la ubicaciÃ³n del conductor (para bÃºsquedas mÃ¡s precisas)
  static Future<void> updateLocation({
    required int conductorId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.conductorServiceUrl}/update_location.php',
      );

      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conductor_id': conductorId,
          'latitud': latitude,
          'longitud': longitude,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Error actualizando ubicaciÃ³n: $e');
    }
  }

  /// Acepta una solicitud de viaje
  static Future<Map<String, dynamic>> acceptRequest({
    required int solicitudId,
    required int conductorId,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.conductorServiceUrl}/accept_trip_request.php',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'solicitud_id': solicitudId,
          'conductor_id': conductorId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al aceptar solicitud: $e',
      };
    }
  }

  /// Rechaza una solicitud de viaje
  static Future<Map<String, dynamic>> rejectRequest({
    required int solicitudId,
    required int conductorId,
    String? motivo,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.conductorServiceUrl}/reject_trip_request.php',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'solicitud_id': solicitudId,
          'conductor_id': conductorId,
          'motivo': motivo ?? 'No disponible',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al rechazar solicitud: $e',
      };
    }
  }

  /// Verifica si hay una bÃºsqueda activa
  static bool get isSearching => _isSearching;
}
