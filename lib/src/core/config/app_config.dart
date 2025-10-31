/// Configuración centralizada de la aplicación
/// 
/// Contiene constantes y configuraciones que pueden variar
/// según el entorno (dev, staging, production).
/// 
/// MIGRACIÓN A MICROSERVICIOS:
/// - Estas URLs cambiarían a endpoints de diferentes servicios
/// - Usa variables de entorno para diferentes ambientes
/// - Considera usar un API Gateway que enrute a los servicios
/// 
/// EJEMPLO CONFIGURACIÓN MICROSERVICIOS:
/// ```dart
/// // Desarrollo local
/// static const apiGateway = 'http://localhost:8080';
/// static const conductorServiceUrl = '$apiGateway/conductor-service/v1';
/// static const authServiceUrl = '$apiGateway/auth-service/v1';
/// static const paymentServiceUrl = '$apiGateway/payment-service/v1';
/// 
/// // Producción
/// static const apiGateway = 'https://api.pingo.com';
/// static const conductorServiceUrl = '$apiGateway/conductor/v1';
/// ```
class AppConfig {
  // Ambiente actual
  static const Environment environment = Environment.production;

  // URLs base según ambiente
  static String get baseUrl {
    switch (environment) {
      case Environment.development:
        // Para emulador Android usa 10.0.2.2 en lugar de localhost
        // Para dispositivo físico usa la IP de tu máquina (ej: 192.168.1.X)
        return 'http://10.0.2.2/pingo/backend'; // Laragon local desde emulador
      case Environment.staging:
        return 'https://staging-api.pingo.com';
      case Environment.production:
        // Railway backend URL - actualizada
        return 'https://pinggo-backend-production.up.railway.app';
    }
  }

  // ============================================
  // MICROSERVICIOS
  // ============================================
  // Cada servicio tiene su propia URL modular
  // En producción con servidores separados, cambiar a:
  //   - authServiceUrl: 'https://auth.pingo.com/v1'
  //   - conductorServiceUrl: 'https://conductors.pingo.com/v1'
  //   - adminServiceUrl: 'https://admin.pingo.com/v1'
  
  /// Microservicio de Autenticación y Usuarios
  /// Endpoints: login, register, profile, email_service, etc.
  static String get authServiceUrl => '$baseUrl/auth';
  
  /// Microservicio de Conductores
  /// Endpoints: profile, license, vehicle, trips, earnings, etc.
  static String get conductorServiceUrl => '$baseUrl/conductor';
  
  /// Microservicio de Administración
  /// Endpoints: dashboard, user_management, audit_logs, etc.
  static String get adminServiceUrl => '$baseUrl/admin';
  
  /// Microservicio de Viajes (futuro)
  static String get tripServiceUrl => '$baseUrl/viajes';
  
  /// Microservicio de Mapas (futuro)
  static String get mapServiceUrl => '$baseUrl/map';
  
  // Alias para compatibilidad con código legacy
  @Deprecated('Usar authServiceUrl en su lugar')
  static String get userServiceUrl => authServiceUrl;

  // Configuración de red
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Configuración de caché
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB

  // Feature flags (para habilitar/deshabilitar features)
  static const bool enableOfflineMode = false;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // Configuración de mapas
  static const String mapboxAccessToken = 'YOUR_MAPBOX_TOKEN'; // Desde env
  static const double defaultLatitude = -34.603722;
  static const double defaultLongitude = -58.381592;

  // Versión de la app
  static const String appVersion = '1.0.0';
  static const String apiVersion = 'v1';
}

/// Enumeración de ambientes
enum Environment {
  development,
  staging,
  production,
}

/// Configuración por feature (para microservicios)
/// 
/// Permite configurar cada módulo/servicio independientemente.
/// Preparado para migración a arquitectura de microservicios.
class FeatureConfig {
  // Configuración del Microservicio de Usuarios
  static const userServiceConfig = {
    'endpoint': '/auth',
    'version': 'v1',
    'timeout': Duration(seconds: 15),
    'retryAttempts': 3,
    'enableCache': false,
  };

  // Configuración del módulo Conductor
  static const conductorConfig = {
    'endpoint': '/conductor',
    'version': 'v1',
    'timeout': Duration(seconds: 15),
    'retryAttempts': 3,
  };

  // Configuración del módulo Auth (alias de userService para retrocompatibilidad)
  static const authConfig = {
    'endpoint': '/auth',
    'version': 'v1',
    'timeout': Duration(seconds: 10),
    'tokenExpiration': Duration(hours: 24),
  };

  // Configuración del módulo Map
  static const mapConfig = {
    'endpoint': '/map',
    'version': 'v1',
    'timeout': Duration(seconds: 20),
    'cacheEnabled': true,
  };
}
