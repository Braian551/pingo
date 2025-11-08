// lib/src/core/constants/app_constants.example.dart
// 
// ARCHIVO DE EJEMPLO - COPIA ESTE ARCHIVO A app_constants.dart
// Y REEMPLAZA LOS VALORES CON TUS CONFIGURACIONES REALES

class AppConstants {
  // ConfiguraciÃ³n de Google Maps
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
  
  // ConfiguraciÃ³n del servicio de email (Backend PHP con Google SMTP)
  static const String emailApiUrl = 'https://tu-servidor.com/backend/email_service.php';
  static const String emailLocalUrl = 'http://localhost/backend/email_service.php';
  
  // ConfiguraciÃ³n para desarrollo
  static const bool useEmailMock = false; // Cambia a true para usar mock en desarrollo
  
  // ConfiguraciÃ³n de la base de datos
  static const String databaseHost = 'localhost';
  static const String databasePort = '3306';
  static const String databaseName = 'pingo';
  static const String databaseUser = 'root';
  static const String databasePassword = '';
  
  // ConfiguraciÃ³n de la aplicaciÃ³n
  static const String appName = 'PingGo';
  static const String appVersion = '1.0.0';
  
  // URLs de la API
  static const String baseApiUrl = 'https://api.pingo.com';
  
  // ConfiguraciÃ³n de mapas
  static const double defaultLatitude = 4.6097; // BogotÃ¡, Colombia
  static const double defaultLongitude = -74.0817;
  static const double defaultZoom = 15.0;
  
  // ConfiguraciÃ³n de validaciÃ³n
  static const int minPasswordLength = 6;
  static const int minPhoneLength = 10;
  static const int verificationCodeLength = 6;
  static const int resendCodeDelaySeconds = 60;
}
