// lib/src/global/services/traffic_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/config/env_config.dart';
import 'quota_monitor_service.dart';

/// Servicio de información de tráfico usando TomTom API
/// Plan gratuito: 2,500 solicitudes por día
/// Documentación: https://developer.tomtom.com/traffic-api/documentation
class TrafficService {
  static const String _baseUrl = 'https://api.tomtom.com';

  // ============================================
  // TRAFFIC FLOW API
  // ============================================
  
  /// Obtener datos de flujo de tráfico en una ubicación
  /// 
  /// Retorna información sobre:
  /// - Velocidad actual vs velocidad libre de flujo
  /// - Nivel de congestión
  /// - Confiabilidad de los datos
  static Future<TrafficFlow?> getTrafficFlow({
    required LatLng location,
    int zoom = 15, // 0-22, mayor = más detalle
  }) async {
    try {
      if (EnvConfig.tomtomApiKey == 'YOUR_TOMTOM_API_KEY_HERE' || 
          EnvConfig.tomtomApiKey.isEmpty) {
        print('TomTom API Key no configurada');
        return null;
      }

      final url = Uri.parse(
        '$_baseUrl/traffic/services/4/flowSegmentData/absolute/$zoom/json'
        '?point=${location.latitude},${location.longitude}'
        '&key=${EnvConfig.tomtomApiKey}'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Incrementar contador de uso
        await QuotaMonitorService.incrementTomTomTraffic();
        
        final data = json.decode(response.body);
        return TrafficFlow.fromJson(data);
      } else {
        print('Error en TomTom Traffic Flow: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      print('Error obteniendo tráfico: $e');
      return null;
    }
  }

  // ============================================
  // TRAFFIC INCIDENTS API
  // ============================================
  
  /// Obtener incidentes de tráfico en un área (accidentes, obras, etc.)
  /// 
  /// [boundingBox] - Área de búsqueda: [minLat, minLng, maxLat, maxLng]
  static Future<List<TrafficIncident>> getTrafficIncidents({
    required LatLng location,
    double radiusKm = 5.0,
  }) async {
    try {
      if (EnvConfig.tomtomApiKey == 'YOUR_TOMTOM_API_KEY_HERE' || 
          EnvConfig.tomtomApiKey.isEmpty) {
        print('TomTom API Key no configurada');
        return [];
      }

      // Calcular bounding box aproximado
      // 1 grado lat ≈ 111km, ajustar por radio
      final latDelta = radiusKm / 111.0;
      final lngDelta = radiusKm / (111.0 * cos(location.latitude * pi / 180));
      
      final minLat = location.latitude - latDelta;
      final maxLat = location.latitude + latDelta;
      final minLng = location.longitude - lngDelta;
      final maxLng = location.longitude + lngDelta;

      final url = Uri.parse(
        '$_baseUrl/traffic/services/5/incidentDetails'
        '?bbox=$minLng,$minLat,$maxLng,$maxLat'
        '&key=${EnvConfig.tomtomApiKey}'
        '&language=es-ES'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await QuotaMonitorService.incrementTomTomTraffic();
        
        final data = json.decode(response.body);
        
        if (data['incidents'] != null) {
          return (data['incidents'] as List)
              .map((incident) => TrafficIncident.fromJson(incident))
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error obteniendo incidentes: $e');
      return [];
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Obtener color según nivel de tráfico (para visualización)
  static String getTrafficColor(double freeFlowSpeed, double currentSpeed) {
    if (currentSpeed >= freeFlowSpeed * 0.8) {
      return '#00FF00'; // Verde - fluido
    } else if (currentSpeed >= freeFlowSpeed * 0.5) {
      return '#FFFF00'; // Amarillo - moderado
    } else if (currentSpeed >= freeFlowSpeed * 0.3) {
      return '#FFA500'; // Naranja - lento
    } else {
      return '#FF0000'; // Rojo - congestionado
    }
  }
}

// ============================================
// MODELOS DE DATOS
// ============================================

/// Información de flujo de tráfico
class TrafficFlow {
  final double currentSpeed; // km/h
  final double freeFlowSpeed; // km/h velocidad sin tráfico
  final double confidence; // 0.0 - 1.0
  final String roadName;

  TrafficFlow({
    required this.currentSpeed,
    required this.freeFlowSpeed,
    required this.confidence,
    required this.roadName,
  });

  factory TrafficFlow.fromJson(Map<String, dynamic> json) {
    final flowData = json['flowSegmentData'];
    
    return TrafficFlow(
      currentSpeed: (flowData?['currentSpeed'] as num?)?.toDouble() ?? 0.0,
      freeFlowSpeed: (flowData?['freeFlowSpeed'] as num?)?.toDouble() ?? 0.0,
      confidence: (flowData?['confidence'] as num?)?.toDouble() ?? 0.0,
      roadName: flowData?['roadName'] ?? 'Desconocido',
    );
  }

  /// Porcentaje de velocidad actual vs velocidad libre (0.0 - 1.0)
  double get speedRatio => 
      freeFlowSpeed > 0 ? currentSpeed / freeFlowSpeed : 1.0;

  /// Nivel de congestión
  TrafficLevel get trafficLevel {
    if (speedRatio >= 0.8) return TrafficLevel.free;
    if (speedRatio >= 0.5) return TrafficLevel.moderate;
    if (speedRatio >= 0.3) return TrafficLevel.slow;
    return TrafficLevel.congested;
  }

  /// Descripción del tráfico
  String get description {
    switch (trafficLevel) {
      case TrafficLevel.free:
        return 'Tráfico fluido';
      case TrafficLevel.moderate:
        return 'Tráfico moderado';
      case TrafficLevel.slow:
        return 'Tráfico lento';
      case TrafficLevel.congested:
        return 'Tráfico congestionado';
    }
  }

  /// Color para visualización
  String get color {
    switch (trafficLevel) {
      case TrafficLevel.free:
        return '#00FF00';
      case TrafficLevel.moderate:
        return '#FFFF00';
      case TrafficLevel.slow:
        return '#FFA500';
      case TrafficLevel.congested:
        return '#FF0000';
    }
  }
}

/// Incidente de tráfico
class TrafficIncident {
  final String id;
  final String type; // accident, congestion, roadWork, etc.
  final String description;
  final LatLng location;
  final int severity; // 0 (bajo) - 4 (alto)
  final DateTime? from;
  final DateTime? to;

  TrafficIncident({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    required this.severity,
    this.from,
    this.to,
  });

  factory TrafficIncident.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'];
    final geometry = json['geometry'];
    
    // Extraer coordenadas
    double lat = 0.0;
    double lng = 0.0;
    
    if (geometry?['coordinates'] != null) {
      final coords = geometry['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    }

    return TrafficIncident(
      id: json['id'] ?? '',
      type: properties?['iconCategory'] ?? 'unknown',
      description: properties?['description'] ?? 'Sin descripción',
      location: LatLng(lat, lng),
      severity: properties?['magnitudeOfDelay'] ?? 0,
      from: properties?['from'] != null 
          ? DateTime.tryParse(properties['from']) 
          : null,
      to: properties?['to'] != null 
          ? DateTime.tryParse(properties['to']) 
          : null,
    );
  }

  /// Icono según tipo de incidente
  String get icon {
    switch (type.toLowerCase()) {
      case 'accident':
        return '🚨';
      case 'roadwork':
        return '🚧';
      case 'congestion':
        return '🚗';
      case 'roadclosure':
        return '⛔';
      default:
        return '⚠️';
    }
  }

  /// Nivel de severidad como texto
  String get severityText {
    switch (severity) {
      case 0:
        return 'Bajo';
      case 1:
        return 'Menor';
      case 2:
        return 'Moderado';
      case 3:
        return 'Mayor';
      case 4:
        return 'Crítico';
      default:
        return 'Desconocido';
    }
  }
}

/// Niveles de tráfico
enum TrafficLevel {
  free,        // Verde - fluido (>80%)
  moderate,    // Amarillo - moderado (50-80%)
  slow,        // Naranja - lento (30-50%)
  congested,   // Rojo - congestionado (<30%)
}
