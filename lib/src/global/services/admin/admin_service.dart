import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminService {
  static const String _baseUrl = 'http://10.0.2.2/pingo/backend/admin';

  /// Obtiene estadísticas del dashboard
  static Future<Map<String, dynamic>> getDashboardStats({
    required int adminId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard_stats.php?admin_id=$adminId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }

      return {'success': false, 'message': 'Error al obtener estadísticas'};
    } catch (e) {
      print('Error en getDashboardStats: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Obtiene lista de usuarios con filtros y paginación
  static Future<Map<String, dynamic>> getUsers({
    required int adminId,
    int page = 1,
    int perPage = 20,
    String? search,
    String? tipoUsuario,
    bool? esActivo,
  }) async {
    try {
      final queryParams = {
        'admin_id': adminId.toString(),
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (tipoUsuario != null) {
        queryParams['tipo_usuario'] = tipoUsuario;
      }
      if (esActivo != null) {
        queryParams['es_activo'] = esActivo ? '1' : '0';
      }

      final uri = Uri.parse('$_baseUrl/user_management.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }

      return {'success': false, 'message': 'Error al obtener usuarios'};
    } catch (e) {
      print('Error en getUsers: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Actualiza un usuario
  static Future<Map<String, dynamic>> updateUser({
    required int adminId,
    required int userId,
    String? nombre,
    String? apellido,
    String? telefono,
    String? tipoUsuario,
    bool? esActivo,
    bool? esVerificado,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'admin_id': adminId,
        'user_id': userId,
      };

      if (nombre != null) requestData['nombre'] = nombre;
      if (apellido != null) requestData['apellido'] = apellido;
      if (telefono != null) requestData['telefono'] = telefono;
      if (tipoUsuario != null) requestData['tipo_usuario'] = tipoUsuario;
      if (esActivo != null) requestData['es_activo'] = esActivo ? 1 : 0;
      if (esVerificado != null) requestData['es_verificado'] = esVerificado ? 1 : 0;

      final response = await http.put(
        Uri.parse('$_baseUrl/user_management.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }

      return {'success': false, 'message': 'Error al actualizar usuario'};
    } catch (e) {
      print('Error en updateUser: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Desactiva un usuario
  static Future<Map<String, dynamic>> deleteUser({
    required int adminId,
    required int userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/user_management.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'admin_id': adminId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }

      return {'success': false, 'message': 'Error al eliminar usuario'};
    } catch (e) {
      print('Error en deleteUser: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Obtiene logs de auditoría
  static Future<Map<String, dynamic>> getAuditLogs({
    required int adminId,
    int page = 1,
    int perPage = 50,
    String? accion,
    int? usuarioId,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    try {
      final queryParams = {
        'admin_id': adminId.toString(),
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (accion != null) queryParams['accion'] = accion;
      if (usuarioId != null) queryParams['usuario_id'] = usuarioId.toString();
      if (fechaDesde != null) queryParams['fecha_desde'] = fechaDesde;
      if (fechaHasta != null) queryParams['fecha_hasta'] = fechaHasta;

      final uri = Uri.parse('$_baseUrl/audit_logs.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }

      return {'success': false, 'message': 'Error al obtener logs'};
    } catch (e) {
      print('Error en getAuditLogs: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Obtiene configuraciones de la app
  static Future<Map<String, dynamic>> getAppConfig({
    int? adminId,
    bool publicOnly = false,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (publicOnly) {
        queryParams['public'] = '1';
      } else if (adminId != null) {
        queryParams['admin_id'] = adminId.toString();
      }

      final uri = Uri.parse('$_baseUrl/app_config.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }

      return {'success': false, 'message': 'Error al obtener configuración'};
    } catch (e) {
      print('Error en getAppConfig: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Actualiza una configuración de la app
  static Future<Map<String, dynamic>> updateAppConfig({
    required int adminId,
    required String clave,
    required String valor,
    String? tipo,
    String? categoria,
    String? descripcion,
    bool? esPublica,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'admin_id': adminId,
        'clave': clave,
        'valor': valor,
      };

      if (tipo != null) requestData['tipo'] = tipo;
      if (categoria != null) requestData['categoria'] = categoria;
      if (descripcion != null) requestData['descripcion'] = descripcion;
      if (esPublica != null) requestData['es_publica'] = esPublica ? '1' : '0';

      final response = await http.put(
        Uri.parse('$_baseUrl/app_config.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }

      return {'success': false, 'message': 'Error al actualizar configuración'};
    } catch (e) {
      print('Error en updateAppConfig: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
