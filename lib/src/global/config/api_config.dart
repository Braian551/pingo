class ApiConfig {
  // URL base del servidor - Laragon local
  // Para desarrollo local con Laragon
  // Para emulador Android: usar 10.0.2.2
  // Para navegador: usar localhost
  static const String baseUrl = 'http://10.0.2.2/ping_go/backend-deploy';

  // Para producción Railway, cambiar a:
  // static const String baseUrl = 'https://pinggo-backend-production.up.railway.app';

  // Endpoints principales
  static const String authEndpoint = '$baseUrl/auth';
  static const String userEndpoint = '$baseUrl/user';
  static const String conductorEndpoint = '$baseUrl/conductor';
  static const String adminEndpoint = '$baseUrl/admin';

  // Configuración de timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
