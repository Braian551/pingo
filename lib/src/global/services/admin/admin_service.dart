import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminService {
  static const String _baseUrl = 'http://10.0.2.2/pingo/backend/admin';

  /// Obtiene estadísticas del dashboard
  static Future<Map<String, dynamic>> getDashboardStats({
    required int adminId,
  }) async {
    try {
      print('AdminService: Obteniendo estadísticas para admin_id: $adminId');
      
      final uri = Uri.parse('$_baseUrl/dashboard_stats.php').replace(
        queryParameters: {'admin_id': adminId.toString()},
      );
      
      print('AdminService: URL completa: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado');
        },
      );

      print('AdminService: Status Code: ${response.statusCode}');
      print('AdminService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Acceso denegado. Solo administradores pueden acceder.'
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': 'Solicitud inválida'
        };
      }

      return {
        'success': false,
        'message': 'Error del servidor: ${response.statusCode}'
      };
    } catch (e) {
      print('AdminService Error en getDashboardStats: $e');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
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
      // Primero intentar con el endpoint simple para debug
      final simpleUri = Uri.parse('$_baseUrl/test_users_simple.php')
          .replace(queryParameters: {'admin_id': adminId.toString()});

      print('AdminService.getUsers - Intentando endpoint simple: $simpleUri');

      var response = await http.get(
        simpleUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: No se pudo conectar con el servidor');
        },
      );

      print('AdminService.getUsers - Status (simple): ${response.statusCode}');
      print('AdminService.getUsers - Body (simple): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['success'] == true) {
          // Aplicar filtros del lado del cliente si es necesario
          var usuarios = data['data']['usuarios'] as List;
          
          if (tipoUsuario != null) {
            usuarios = usuarios.where((u) => u['tipo_usuario'] == tipoUsuario).toList();
          }
          
          if (esActivo != null) {
            usuarios = usuarios.where((u) => u['es_activo'] == (esActivo ? 1 : 0)).toList();
          }
          
          if (search != null && search.isNotEmpty) {
            final searchLower = search.toLowerCase();
            usuarios = usuarios.where((u) {
              final nombre = (u['nombre'] ?? '').toLowerCase();
              final apellido = (u['apellido'] ?? '').toLowerCase();
              final email = (u['email'] ?? '').toLowerCase();
              final telefono = (u['telefono'] ?? '').toLowerCase();
              return nombre.contains(searchLower) || 
                     apellido.contains(searchLower) || 
                     email.contains(searchLower) || 
                     telefono.contains(searchLower);
            }).toList();
          }
          
          return {
            'success': true,
            'message': 'Usuarios obtenidos',
            'data': {
              'usuarios': usuarios,
              'pagination': {
                'total': usuarios.length,
                'page': page,
                'per_page': perPage,
                'total_pages': 1
              }
            }
          };
        }
        
        return data;
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}'
        };
      }
    } catch (e, stackTrace) {
      print('AdminService.getUsers - Exception: $e');
      print('AdminService.getUsers - StackTrace: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
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

  /// Obtiene documentos de conductores con todos los campos
  static Future<Map<String, dynamic>> getConductoresDocumentos({
    required int adminId,
    int? conductorId,
    String? estadoVerificacion,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = {
        'admin_id': adminId.toString(),
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (conductorId != null) queryParams['conductor_id'] = conductorId.toString();
      if (estadoVerificacion != null) queryParams['estado_verificacion'] = estadoVerificacion;

      final uri = Uri.parse('$_baseUrl/get_conductores_documentos.php')
          .replace(queryParameters: queryParams);

      print('AdminService.getConductoresDocumentos - URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: No se pudo conectar con el servidor');
        },
      );

      print('AdminService.getConductoresDocumentos - Status: ${response.statusCode}');
      print('AdminService.getConductoresDocumentos - Body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return data;
        } catch (e) {
          print('AdminService.getConductoresDocumentos - JSON Parse Error: $e');
          print('AdminService.getConductoresDocumentos - Full Response Body: ${response.body}');
          return {
            'success': false,
            'message': 'Error al procesar la respuesta del servidor'
          };
        }
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Acceso denegado. Solo administradores pueden ver documentos.'
        };
      }

      return {'success': false, 'message': 'Error al obtener documentos'};
    } catch (e) {
      print('Error en getConductoresDocumentos: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Aprobar documentos de conductor
  static Future<Map<String, dynamic>> aprobarConductor({
    required int adminId,
    required int conductorId,
    String? notas,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/aprobar_conductor.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'admin_id': adminId,
          'conductor_id': conductorId,
          'notas': notas,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }

      return {'success': false, 'message': 'Error al aprobar conductor'};
    } catch (e) {
      print('Error en aprobarConductor: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Rechazar documentos de conductor
  static Future<Map<String, dynamic>> rechazarConductor({
    required int adminId,
    required int conductorId,
    required String motivo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rechazar_conductor.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'admin_id': adminId,
          'conductor_id': conductorId,
          'motivo': motivo,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }

      return {'success': false, 'message': 'Error al rechazar conductor'};
    } catch (e) {
      print('Error en rechazarConductor: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
