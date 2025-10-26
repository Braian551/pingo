class ApiConfig {
  // URL base del servidor - cambiar según tu entorno
  // Para emulador Android usa 10.0.2.2 en lugar de localhost
  // Para dispositivo físico usa la IP de tu máquina (ej: 192.168.1.X)
  static const String baseUrl = 'http://10.0.2.2/pingo/backend';
  
  // Endpoints principales
  static const String authEndpoint = '$baseUrl/auth';
  static const String userEndpoint = '$baseUrl/user';
  static const String conductorEndpoint = '$baseUrl/conductor';
  static const String adminEndpoint = '$baseUrl/admin';
  
  // Configuración de timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
