// lib/src/global/services/quota_monitor_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/env_config.dart';

/// Servicio para monitorear el uso de cuotas de las APIs
/// y alertar cuando se acerquen a los lÃ­mites
class QuotaMonitorService {
  static const String _mapboxTilesKey = 'mapbox_tiles_count';
  static const String _mapboxRoutingKey = 'mapbox_routing_count';
  static const String _tomtomTrafficKey = 'tomtom_traffic_count';
  static const String _lastResetKey = 'quota_last_reset';
  static const String _lastDailyResetKey = 'quota_last_daily_reset';

  /// Incrementar contador de tiles de Mapbox
  static Future<void> incrementMapboxTiles({int count = 1}) async {
    if (!EnvConfig.enableQuotaMonitoring) return;
    
    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetIfNeeded(prefs);
    
    final current = prefs.getInt(_mapboxTilesKey) ?? 0;
    await prefs.setInt(_mapboxTilesKey, current + count);
  }

  /// Incrementar contador de routing de Mapbox
  static Future<void> incrementMapboxRouting({int count = 1}) async {
    if (!EnvConfig.enableQuotaMonitoring) return;
    
    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetIfNeeded(prefs);
    
    final current = prefs.getInt(_mapboxRoutingKey) ?? 0;
    await prefs.setInt(_mapboxRoutingKey, current + count);
  }

  /// Incrementar contador de trÃ¡fico de TomTom
  static Future<void> incrementTomTomTraffic({int count = 1}) async {
    if (!EnvConfig.enableQuotaMonitoring) return;
    
    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetDailyIfNeeded(prefs);
    
    final current = prefs.getInt(_tomtomTrafficKey) ?? 0;
    await prefs.setInt(_tomtomTrafficKey, current + count);
  }

  /// Obtener el estado actual de las cuotas
  static Future<QuotaStatus> getQuotaStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetIfNeeded(prefs);
    await _checkAndResetDailyIfNeeded(prefs);
    
    final mapboxTiles = prefs.getInt(_mapboxTilesKey) ?? 0;
    final mapboxRouting = prefs.getInt(_mapboxRoutingKey) ?? 0;
    final tomtomTraffic = prefs.getInt(_tomtomTrafficKey) ?? 0;
    
    return QuotaStatus(
      mapboxTilesUsed: mapboxTiles,
      mapboxTilesLimit: EnvConfig.mapboxMonthlyRequestLimit,
      mapboxRoutingUsed: mapboxRouting,
      mapboxRoutingLimit: EnvConfig.mapboxMonthlyRoutingLimit,
      tomtomTrafficUsed: tomtomTraffic,
      tomtomTrafficLimit: EnvConfig.tomtomDailyRequestLimit,
    );
  }

  /// Verificar si se debe resetear el contador mensual
  static Future<void> _checkAndResetIfNeeded(SharedPreferences prefs) async {
    final lastReset = prefs.getString(_lastResetKey);
    final now = DateTime.now();
    
    if (lastReset == null) {
      // Primera vez, guardar la fecha actual
      await prefs.setString(_lastResetKey, now.toIso8601String());
      return;
    }
    
    final lastResetDate = DateTime.parse(lastReset);
    
    // Resetear si ha pasado un mes
    if (now.month != lastResetDate.month || now.year != lastResetDate.year) {
      await prefs.setInt(_mapboxTilesKey, 0);
      await prefs.setInt(_mapboxRoutingKey, 0);
      await prefs.setString(_lastResetKey, now.toIso8601String());
    }
  }

  /// Verificar si se debe resetear el contador diario (TomTom)
  static Future<void> _checkAndResetDailyIfNeeded(SharedPreferences prefs) async {
    final lastReset = prefs.getString(_lastDailyResetKey);
    final now = DateTime.now();
    
    if (lastReset == null) {
      await prefs.setString(_lastDailyResetKey, now.toIso8601String());
      return;
    }
    
    final lastResetDate = DateTime.parse(lastReset);
    
    // Resetear si ha pasado un dÃ­a
    if (now.day != lastResetDate.day || 
        now.month != lastResetDate.month || 
        now.year != lastResetDate.year) {
      await prefs.setInt(_tomtomTrafficKey, 0);
      await prefs.setString(_lastDailyResetKey, now.toIso8601String());
    }
  }

  /// Resetear manualmente todos los contadores (para pruebas)
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mapboxTilesKey, 0);
    await prefs.setInt(_mapboxRoutingKey, 0);
    await prefs.setInt(_tomtomTrafficKey, 0);
    await prefs.setString(_lastResetKey, DateTime.now().toIso8601String());
    await prefs.setString(_lastDailyResetKey, DateTime.now().toIso8601String());
  }
}

/// Modelo para el estado de las cuotas
class QuotaStatus {
  final int mapboxTilesUsed;
  final int mapboxTilesLimit;
  final int mapboxRoutingUsed;
  final int mapboxRoutingLimit;
  final int tomtomTrafficUsed;
  final int tomtomTrafficLimit;

  QuotaStatus({
    required this.mapboxTilesUsed,
    required this.mapboxTilesLimit,
    required this.mapboxRoutingUsed,
    required this.mapboxRoutingLimit,
    required this.tomtomTrafficUsed,
    required this.tomtomTrafficLimit,
  });

  /// Porcentaje de uso de tiles de Mapbox (0.0 a 1.0)
  double get mapboxTilesPercentage => 
      mapboxTilesLimit > 0 ? mapboxTilesUsed / mapboxTilesLimit : 0.0;

  /// Porcentaje de uso de routing de Mapbox (0.0 a 1.0)
  double get mapboxRoutingPercentage => 
      mapboxRoutingLimit > 0 ? mapboxRoutingUsed / mapboxRoutingLimit : 0.0;

  /// Porcentaje de uso de trÃ¡fico de TomTom (0.0 a 1.0)
  double get tomtomTrafficPercentage => 
      tomtomTrafficLimit > 0 ? tomtomTrafficUsed / tomtomTrafficLimit : 0.0;

  /// Nivel de alerta para Mapbox Tiles
  QuotaAlertLevel get mapboxTilesAlertLevel {
    if (mapboxTilesPercentage >= EnvConfig.criticalThreshold) {
      return QuotaAlertLevel.critical;
    } else if (mapboxTilesPercentage >= EnvConfig.dangerThreshold) {
      return QuotaAlertLevel.danger;
    } else if (mapboxTilesPercentage >= EnvConfig.warningThreshold) {
      return QuotaAlertLevel.warning;
    }
    return QuotaAlertLevel.normal;
  }

  /// Nivel de alerta para Mapbox Routing
  QuotaAlertLevel get mapboxRoutingAlertLevel {
    if (mapboxRoutingPercentage >= EnvConfig.criticalThreshold) {
      return QuotaAlertLevel.critical;
    } else if (mapboxRoutingPercentage >= EnvConfig.dangerThreshold) {
      return QuotaAlertLevel.danger;
    } else if (mapboxRoutingPercentage >= EnvConfig.warningThreshold) {
      return QuotaAlertLevel.warning;
    }
    return QuotaAlertLevel.normal;
  }

  /// Nivel de alerta para TomTom Traffic
  QuotaAlertLevel get tomtomTrafficAlertLevel {
    if (tomtomTrafficPercentage >= EnvConfig.criticalThreshold) {
      return QuotaAlertLevel.critical;
    } else if (tomtomTrafficPercentage >= EnvConfig.dangerThreshold) {
      return QuotaAlertLevel.danger;
    } else if (tomtomTrafficPercentage >= EnvConfig.warningThreshold) {
      return QuotaAlertLevel.warning;
    }
    return QuotaAlertLevel.normal;
  }

  /// Nivel de alerta general (el mÃ¡s alto de todos)
  QuotaAlertLevel get overallAlertLevel {
    final levels = [
      mapboxTilesAlertLevel,
      mapboxRoutingAlertLevel,
      tomtomTrafficAlertLevel,
    ];
    
    if (levels.contains(QuotaAlertLevel.critical)) return QuotaAlertLevel.critical;
    if (levels.contains(QuotaAlertLevel.danger)) return QuotaAlertLevel.danger;
    if (levels.contains(QuotaAlertLevel.warning)) return QuotaAlertLevel.warning;
    return QuotaAlertLevel.normal;
  }

  /// Hay alguna alerta activa?
  bool get hasAlert => overallAlertLevel != QuotaAlertLevel.normal;

  /// Mensaje de alerta
  String get alertMessage {
    switch (overallAlertLevel) {
      case QuotaAlertLevel.critical:
        return 'âš ï¸ CRÃTICO: Has superado el 90% de tus solicitudes gratuitas';
      case QuotaAlertLevel.danger:
        return 'âš ï¸ ALERTA: Has superado el 75% de tus solicitudes gratuitas';
      case QuotaAlertLevel.warning:
        return 'âš ï¸ ADVERTENCIA: Has superado el 50% de tus solicitudes gratuitas';
      default:
        return '';
    }
  }
}

/// Niveles de alerta
enum QuotaAlertLevel {
  normal,    // < 50%
  warning,   // >= 50%
  danger,    // >= 75%
  critical,  // >= 90%
}
