class ApiConfig {
  // URL base del servidor - Railway backend
  static const String baseUrl = 'https://pinggo-backend-production.up.railway.app';
  
  // Endpoints principales
  static const String authEndpoint = '$baseUrl/auth';
  static const String userEndpoint = '$baseUrl/user';
  static const String conductorEndpoint = '$baseUrl/conductor';
  static const String adminEndpoint = '$baseUrl/admin';
  
  // Configuración de timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
