import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/env_config.dart';

/// Servicio de geocoding GRATUITO usando Nominatim (OpenStreetMap)
/// No requiere API key y es completamente gratuito
/// Límite recomendado: 1 request por segundo
class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  
  /// Buscar dirección por texto
  static Future<List<NominatimResult>> searchAddress(String query) async {
    try {
      final encoded = Uri.encodeQueryComponent(query);
      final uri = Uri.parse('$_baseUrl/search?format=json&q=$encoded&addressdetails=1&limit=10');

      final response = await http
          .get(
        uri,
        headers: {
          'User-Agent': '${EnvConfig.nominatimUserAgent} (${EnvConfig.nominatimEmail})',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => NominatimResult.fromJson(item)).toList();
      } else {
        throw Exception('Error en la búsqueda: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión o timeout: $e');
    }
  }

  /// Reverse geocoding - obtener dirección desde coordenadas
  static Future<NominatimResult?> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse('$_baseUrl/reverse?format=json&lat=$lat&lon=$lon&addressdetails=1');

      final response = await http
          .get(
        uri,
        headers: {
          'User-Agent': '${EnvConfig.nominatimUserAgent} (${EnvConfig.nominatimEmail})',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return NominatimResult.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      // En caso de error (incluyendo timeout), devolver null para que el provider
      // pueda manejar mostrando coordenadas en lugar de una dirección.
      return null;
    }
  }
}

class NominatimResult {
  final double lat;
  final double lon;
  final String displayName;
  final Map<String, dynamic> address;
  final String? type;

  NominatimResult({
    required this.lat,
    required this.lon,
    required this.displayName,
    required this.address,
    this.type,
  });

  factory NominatimResult.fromJson(Map<String, dynamic> json) {
    return NominatimResult(
      lat: double.parse(json['lat'].toString()),
      lon: double.parse(json['lon'].toString()),
      displayName: json['display_name'] ?? '',
      address: json['address'] is Map ? Map<String, dynamic>.from(json['address']) : {},
      type: json['type'],
    );
  }

  /// Obtener dirección formateada
  String getFormattedAddress() {
    final addr = address;
    final components = [];
    
    if (addr['road'] != null) components.add(addr['road']);
    if (addr['house_number'] != null) components.add(addr['house_number']);
    if (addr['neighbourhood'] != null) components.add(addr['neighbourhood']);
    if (addr['suburb'] != null) components.add(addr['suburb']);
    if (addr['city'] != null) components.add(addr['city']);
    if (addr['state'] != null) components.add(addr['state']);
    if (addr['country'] != null) components.add(addr['country']);
    
    return components.isNotEmpty ? components.join(', ') : displayName;
  }

  /// Obtener ciudad
  String? getCity() {
    return address['city'] ?? 
           address['town'] ?? 
           address['village'] ?? 
           address['municipality'];
  }

  /// Obtener departamento/estado
  String? getState() {
    return address['state'] ?? address['region'];
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
      'displayName': displayName,
      'address': address,
      'type': type,
    };
  }
}