import 'package:shared_preferences/shared_preferences.dart';

/// Utilidad para resetear el estado de notificación de aprobación
/// Ejecutar con: dart run debug_approval_reset.dart [conductor_id]
void main(List<String> args) async {
  print('🔄 Reseteando estado de notificación de aprobación...');

  final prefs = await SharedPreferences.getInstance();

  if (args.isNotEmpty) {
    // Resetear conductor específico
    final conductorId = int.tryParse(args[0]);
    if (conductorId != null) {
      final shownKey = 'conductor_approval_shown_$conductorId';
      final statusKey = 'conductor_last_status_$conductorId';

      await prefs.remove(shownKey);
      await prefs.remove(statusKey);

      print('✅ Estado reseteado para conductor ID: $conductorId');
    } else {
      print('❌ ID de conductor inválido: ${args[0]}');
    }
  } else {
    // Resetear todos los conductores (útil para testing)
    final keys = prefs.getKeys();
    int resetCount = 0;

    for (final key in keys) {
      if (key.startsWith('conductor_approval_shown_') || key.startsWith('conductor_last_status_')) {
        await prefs.remove(key);
        resetCount++;
      }
    }

    print('✅ Reseteados $resetCount estados de notificación');
  }

  print('🎉 Proceso completado. La próxima vez que inicies la app, verás la alerta de aprobación.');
}