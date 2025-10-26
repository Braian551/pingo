import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar notificaciones de aprobación del conductor
class ApprovalNotificationService {
  static const String _keyPrefix = 'conductor_approval_shown_';
  static const String _lastStatusKey = 'conductor_last_status_';

  /// Verifica si debe mostrar la alerta de aprobación
  /// Retorna true si el conductor fue aprobado y no se ha mostrado la alerta
  static Future<bool> shouldShowApprovalAlert(
    int conductorId,
    String currentStatus,
    bool isApproved,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Claves únicas por conductor
      final shownKey = '$_keyPrefix$conductorId';
      final statusKey = '$_lastStatusKey$conductorId';

      // Verificar si ya se mostró la alerta
      final hasShownAlert = prefs.getBool(shownKey) ?? false;

      // Obtener el último estado guardado
      final lastStatus = prefs.getString(statusKey);

      print('🔔 Verificando alerta de aprobación:');
      print('   - Conductor ID: $conductorId');
      print('   - Estado actual: $currentStatus');
      print('   - Aprobado: $isApproved');
      print('   - Último estado guardado: ${lastStatus ?? "ninguno"}');
      print('   - Ya se mostró alerta: $hasShownAlert');

      // Guardar el estado actual
      await prefs.setString(statusKey, currentStatus);

      // Caso especial: Si nunca se ha guardado un estado y el conductor está aprobado
      // probablemente es la primera vez que inicia sesión después de ser aprobado
      if (lastStatus == null && (currentStatus == 'aprobado' || isApproved) && !hasShownAlert) {
        print('   ✅ Primera vez detectando estado aprobado - MOSTRARÁ ALERTA');
        return true;
      }

      // Mostrar alerta solo si:
      // 1. No se ha mostrado antes
      // 2. El estado actual es "aprobado" O el conductor está aprobado
      // 3. El estado anterior era diferente a "aprobado"
      if (!hasShownAlert &&
          (currentStatus == 'aprobado' || isApproved) &&
          lastStatus != null &&
          lastStatus != 'aprobado') {
        print('   ✅ Cambio de estado detectado - MOSTRARÁ ALERTA');
        return true;
      }

      print('   ❌ No se mostrará alerta');
      return false;
    } catch (e) {
      print('Error en shouldShowApprovalAlert: $e');
      return false;
    }
  }

  /// Marca que se mostró la alerta de aprobación
  static Future<void> markApprovalAlertAsShown(int conductorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shownKey = '$_keyPrefix$conductorId';
      await prefs.setBool(shownKey, true);
    } catch (e) {
      print('Error en markApprovalAlertAsShown: $e');
    }
  }

  /// Resetea el estado (útil para testing)
  static Future<void> resetApprovalStatus(int conductorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shownKey = '$_keyPrefix$conductorId';
      final statusKey = '$_lastStatusKey$conductorId';
      
      await prefs.remove(shownKey);
      await prefs.remove(statusKey);
    } catch (e) {
      print('Error en resetApprovalStatus: $e');
    }
  }
}
