// lib/src/core/constants/app_constants.dart

class AppConstants {
  // ============================================
  // CONFIGURACIÓN DE MAPAS (MAPBOX)
  // ============================================
  // La configuración de Mapbox ahora está en EnvConfig
  // Ver: lib/src/core/config/env_config.dart
  
  // Ubicación por defecto (Bogotá, Colombia)
  static const double defaultLatitude = 4.6097;
  static const double defaultLongitude = -74.0817;
  static const double defaultZoom = 15.0;
  
  // Estilos de mapa disponibles
  static const String mapStyleStreets = 'streets-v12';
  static const String mapStyleDark = 'dark-v11';
  static const String mapStyleLight = 'light-v11';
  static const String mapStyleOutdoors = 'outdoors-v12';
  static const String mapStyleSatellite = 'satellite-streets-v12';
  
  // ============================================
  // CONFIGURACIÓN DE EMAIL
  // ============================================
  // NOTA: email_service.php YA FUE MOVIDO a auth/ microservicio
  // Usar: AppConfig.authServiceUrl + '/email_service.php'
  @Deprecated('Usar AppConfig.authServiceUrl + \'/email_service.php\' en su lugar')
  static const String emailApiUrl = 'http://10.0.2.2/pingo/backend/auth/email_service.php';
  static const bool useEmailMock = false;
  
  // ============================================
  // CONFIGURACIÓN DE BASE DE DATOS
  // ============================================
  static const String databaseHost = '10.0.2.2';
  static const String databasePort = '3306';
  static const String databaseName = 'pingo';
  static const String databaseUser = 'root';
  static const String databasePassword = 'root';
  
  // ============================================
  // CONFIGURACIÓN DE LA APLICACIÓN
  // ============================================
  static const String appName = 'PingGo';
  static const String appVersion = '1.0.0';
  static const String baseApiUrl = 'https://api.pingo.com';
  
  // ============================================
  // CONFIGURACIÓN DE VALIDACIÓN
  // ============================================
  static const int minPasswordLength = 6;
  static const int minPhoneLength = 10;
  static const int verificationCodeLength = 6;
  static const int resendCodeDelaySeconds = 60;
  
  // ============================================
  // CONFIGURACIÓN DE RUTAS Y NAVEGACIÓN
  // ============================================
  static const String defaultRoutingProfile = 'driving'; // driving, walking, cycling
  static const bool enableTrafficInfo = true;
  static const bool enableRouteOptimization = true;
  static const double trafficCheckRadiusKm = 5.0;
  
  // ============================================
  // CONFIGURACIÓN DE NOTIFICACIONES
  // ============================================
  static const bool enableQuotaNotifications = true;
  static const bool showQuotaInUI = true;
}
