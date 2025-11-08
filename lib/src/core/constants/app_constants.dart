// lib/src/core/constants/app_constants.dart
import 'package:viax/src/core/config/app_config.dart';

class AppConstants {
  // ============================================
  // CONFIGURACIÃ“N DE MAPAS (MAPBOX)
  // ============================================
  // La configuraciÃ³n de Mapbox ahora estÃ¡ en EnvConfig
  // Ver: lib/src/core/config/env_config.dart
  
  // UbicaciÃ³n por defecto (BogotÃ¡, Colombia)
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
  // CONFIGURACIÃ“N DE EMAIL
  // ============================================
  // NOTA: email_service.php YA FUE MOVIDO a auth/ microservicio
  // Usar: AppConfig.authServiceUrl + '/email_service.php'
  @Deprecated('Usar AppConfig.authServiceUrl + \'/email_service.php\' en su lugar')
  static String get emailApiUrl => '${AppConfig.authServiceUrl}/email_service.php';
  static const bool useEmailMock = false;
  
  // ============================================
  // CONFIGURACIÃ“N DE BASE DE DATOS
  // ============================================
  // NOTA: La app ahora usa API REST, no conexiÃ³n directa a MySQL
  // La base de datos se maneja a travÃ©s del backend de Railway
  // Ver: lib/src/global/config/api_config.dart para URLs de API

  // ConfiguraciÃ³n legacy (ya no se usa - mantener por compatibilidad)
  @Deprecated('La app ahora usa API REST. Ver ApiConfig para URLs')
  static const String databaseHost = 'sql10.freesqldatabase.com';
  @Deprecated('La app ahora usa API REST. Ver ApiConfig para URLs')
  static const String databasePort = '3306';
  @Deprecated('La app ahora usa API REST. Ver ApiConfig para URLs')
  static const String databaseName = 'sql10805022';
  @Deprecated('La app ahora usa API REST. Ver ApiConfig para URLs')
  static const String databaseUser = 'sql10805022';
  @Deprecated('La app ahora usa API REST. Ver ApiConfig para URLs')
  static const String databasePassword = 'BVeitwKy1q';
  
  // ============================================
  // CONFIGURACIÃ“N DE LA APLICACIÃ“N
  // ============================================
  static const String appName = 'Viax';
  static const String appVersion = '1.0.0';
  static const String baseApiUrl = 'https://api.viax.com'; // TODO: actualizar cuando exista dominio real
  
  // ============================================
  // CONFIGURACIÃ“N DE VALIDACIÃ“N
  // ============================================
  static const int minPasswordLength = 6;
  static const int minPhoneLength = 10;
  static const int verificationCodeLength = 6;
  static const int resendCodeDelaySeconds = 60;
  
  // ============================================
  // CONFIGURACIÃ“N DE RUTAS Y NAVEGACIÃ“N
  // ============================================
  static const String defaultRoutingProfile = 'driving'; // driving, walking, cycling
  static const bool enableTrafficInfo = true;
  static const bool enableRouteOptimization = true;
  static const double trafficCheckRadiusKm = 5.0;
  
  // ============================================
  // CONFIGURACIÃ“N DE NOTIFICACIONES
  // ============================================
  static const bool enableQuotaNotifications = true;
  static const bool showQuotaInUI = true;
}
