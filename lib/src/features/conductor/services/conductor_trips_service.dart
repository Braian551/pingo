import 'dart:convert';
import 'package:http/http.dart' as http;

/// Modelo para un viaje individual
class TripModel {
  final int id;
  final String tipoServicio;
  final String estado;
  final double? precioEstimado;
  final double? precioFinal;
  final double? distanciaKm;
  final int? duracionEstimada;
  final DateTime fechaSolicitud;
  final DateTime? fechaCompletado;
  final String? origen;
  final String? destino;
  final String clienteNombre;
  final String clienteApellido;
  final int? calificacion;
  final String? comentario;

  TripModel({
    required this.id,
    required this.tipoServicio,
    required this.estado,
    this.precioEstimado,
    this.precioFinal,
    this.distanciaKm,
    this.duracionEstimada,
    required this.fechaSolicitud,
    this.fechaCompletado,
    this.origen,
    this.destino,
    required this.clienteNombre,
    required this.clienteApellido,
    this.calificacion,
    this.comentario,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tipoServicio: json['tipo_servicio']?.toString() ?? 'viaje',
      estado: json['estado']?.toString() ?? 'completado',
      precioEstimado: double.tryParse(json['precio_estimado']?.toString() ?? '0'),
      precioFinal: double.tryParse(json['precio_final']?.toString() ?? '0'),
      distanciaKm: double.tryParse(json['distancia_km']?.toString() ?? '0'),
      duracionEstimada: int.tryParse(json['duracion_estimada']?.toString() ?? '0'),
      fechaSolicitud: DateTime.tryParse(json['fecha_solicitud']?.toString() ?? '') ?? DateTime.now(),
      fechaCompletado: DateTime.tryParse(json['fecha_completado']?.toString() ?? ''),
      origen: json['origen']?.toString(),
      destino: json['destino']?.toString(),
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      clienteApellido: json['cliente_apellido']?.toString() ?? '',
      calificacion: int.tryParse(json['calificacion']?.toString() ?? '0'),
      comentario: json['comentario']?.toString(),
    );
  }

  String get clienteNombreCompleto => '$clienteNombre $clienteApellido';
  
  double get calificacionDouble => (calificacion ?? 0).toDouble();
}

/// Modelo para paginación
class PaginationModel {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: int.tryParse(json['page']?.toString() ?? '1') ?? 1,
      limit: int.tryParse(json['limit']?.toString() ?? '20') ?? 20,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      totalPages: int.tryParse(json['total_pages']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Servicio para gestionar el historial de viajes del conductor
class ConductorTripsService {
  static const String _baseUrl = 'http://10.0.2.2/pingo/backend';

  /// Obtener historial de viajes
  static Future<Map<String, dynamic>> getTripsHistory({
    required int conductorId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/conductor/get_historial.php?conductor_id=$conductorId&page=$page&limit=$limit',
      );

      print('Fetching trips history: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado');
        },
      );

      print('Trips response status: ${response.statusCode}');
      print('Trips response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final viajesList = (data['viajes'] as List?)
              ?.map((item) => TripModel.fromJson(item))
              .toList() ?? [];

          final pagination = data['pagination'] != null
              ? PaginationModel.fromJson(data['pagination'])
              : PaginationModel(page: 1, limit: 20, total: 0, totalPages: 0);

          return {
            'success': true,
            'viajes': viajesList,
            'pagination': pagination,
            'message': data['message'] ?? 'Historial obtenido exitosamente',
          };
        } else {
          return {
            'success': false,
            'viajes': <TripModel>[],
            'message': data['message'] ?? 'Error al obtener historial',
          };
        }
      } else {
        return {
          'success': false,
          'viajes': <TripModel>[],
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error en getTripsHistory: $e');
      return {
        'success': false,
        'viajes': <TripModel>[],
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtener detalles de un viaje específico
  static Future<Map<String, dynamic>> getTripDetails({
    required int conductorId,
    required int tripId,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/conductor/get_viaje_detalle.php?conductor_id=$conductorId&viaje_id=$tripId',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['viaje'] != null) {
          return {
            'success': true,
            'viaje': TripModel.fromJson(data['viaje']),
            'message': 'Detalles obtenidos exitosamente',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'No se encontró el viaje',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error en getTripDetails: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}
