import 'package:shared_preferences/shared_preferences.dart';

/// Script simple para resetear la notificación de aprobación del conductor
void main() async {
  print('🔄 Reseteando notificación de aprobación...');

  final prefs = await SharedPreferences.getInstance();

  // Resetear para conductor ID 7 (basado en los logs)
  const conductorId = 7;
  final shownKey = 'conductor_approval_shown_$conductorId';
  final statusKey = 'conductor_last_status_$conductorId';

  await prefs.remove(shownKey);
  await prefs.remove(statusKey);

  print('✅ Estado reseteado para conductor ID: $conductorId');
  print('🎉 Ahora la alerta de aprobación se mostrará nuevamente.');
}