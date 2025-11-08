// lib/src/global/services/email_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

/// Servicio para envÃ­o de correos electrÃ³nicos
/// 
/// NOTA: email_service.php ahora estÃ¡ en el microservicio de auth
/// URL: AppConfig.authServiceUrl/email_service.php
class EmailService {
  /// URL del servicio de email
  /// Archivo movido a auth/ microservicio
  static String get _apiUrl {
    return '${AppConfig.authServiceUrl}/email_service.php';
  }

  /// Genera un cÃ³digo de verificación de 4 dígitos
  static String generateVerificationCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  /// EnvÃ­a un cÃ³digo de verificaciÃ³n por correo usando el backend PHP
  static Future<bool> sendVerificationCode({
    required String email,
    required String code,
    required String userName,
  }) async {
    try {
      print('Enviando cÃ³digo de verificaciÃ³n a: $email');
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'code': code,
          'userName': userName,
        }),
      );

      print('Respuesta del servidor: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        print('Error del servidor: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error enviando correo: $e');
      return false;
    }
  }

  /// Simula el envÃ­o de correo para desarrollo (sin API real)
  static Future<bool> sendVerificationCodeMock({
    required String email,
    required String code,
    required String userName,
  }) async {
    // Simular delay de red
    await Future.delayed(const Duration(seconds: 2));
    
    // Para desarrollo, siempre retorna true
    // En producciÃ³n, reemplaza con tu servicio real de correo
    print('ðŸ”§ MODO DESARROLLO - CÃ³digo de verificaciÃ³n para $email: $code');
    print('ðŸ“§ En producciÃ³n, este cÃ³digo se enviarÃ­a por email real');
    return true;
  }

  /// MÃ©todo de conveniencia que usa el servicio real o mock segÃºn la configuraciÃ³n
  static Future<bool> sendVerificationCodeWithFallback({
    required String email,
    required String code,
    required String userName,
    bool? useMock, // Si es null, usa mock en desarrollo
  }) async {
    final shouldUseMock = useMock ?? (AppConfig.environment == Environment.development);
    
    if (shouldUseMock) {
      return await sendVerificationCodeMock(
        email: email,
        code: code,
        userName: userName,
      );
    } else {
      return await sendVerificationCode(
        email: email,
        code: code,
        userName: userName,
      );
    }
  }
}
