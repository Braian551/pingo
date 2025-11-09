import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// Proveedor de tema para la aplicación
/// Maneja el cambio entre modo claro y oscuro
/// Por defecto, detecta y usa el tema del sistema
class ThemeProvider extends ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeProvider() {
    _loadThemeMode();
  }

  /// Obtiene el modo de tema actual
  ThemeMode get themeMode => _themeMode;

  /// Obtiene el tema claro
  ThemeData get lightTheme => AppTheme.lightTheme;

  /// Obtiene el tema oscuro
  ThemeData get darkTheme => AppTheme.darkTheme;

  /// Verifica si el modo oscuro está activo
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Si está en modo sistema, detecta el brillo del sistema
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Verifica si el modo claro está activo
  bool get isLightMode {
    if (_themeMode == ThemeMode.system) {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.light;
    }
    return _themeMode == ThemeMode.light;
  }

  /// Verifica si está usando el tema del sistema
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Cambia al modo claro
  Future<void> setLightMode() async {
    _themeMode = ThemeMode.light;
    notifyListeners();
    await _saveThemeMode();
  }

  /// Cambia al modo oscuro
  Future<void> setDarkMode() async {
    _themeMode = ThemeMode.dark;
    notifyListeners();
    await _saveThemeMode();
  }

  /// Cambia al modo del sistema (por defecto)
  Future<void> setSystemMode() async {
    _themeMode = ThemeMode.system;
    notifyListeners();
    await _saveThemeMode();
  }

  /// Alterna entre modo claro y oscuro
  /// Si está en modo sistema, cambia a modo claro u oscuro según el estado actual del sistema
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.system) {
      // Si está en sistema, detectar el tema actual y cambiar al opuesto
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      _themeMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    } else {
      // Alternar entre claro y oscuro
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
    await _saveThemeMode();
  }

  /// Cambia a un modo específico
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _saveThemeMode();
  }

  /// Carga el modo de tema guardado
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePreferenceKey);
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            _themeMode = ThemeMode.system;
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      // Si hay error, usar modo sistema por defecto
      _themeMode = ThemeMode.system;
    }
  }

  /// Guarda el modo de tema
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeValue;
      
      switch (_themeMode) {
        case ThemeMode.light:
          themeValue = 'light';
        case ThemeMode.dark:
          themeValue = 'dark';
        case ThemeMode.system:
          themeValue = 'system';
      }
      
      await prefs.setString(_themePreferenceKey, themeValue);
    } catch (e) {
      // Ignorar errores de guardado
      debugPrint('Error al guardar el tema: $e');
    }
  }

  /// Obtiene el nombre legible del modo actual
  String get themeModeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Modo Claro';
      case ThemeMode.dark:
        return 'Modo Oscuro';
      case ThemeMode.system:
        return 'Tema del Sistema';
    }
  }

  /// Obtiene el icono para el modo actual
  IconData get themeModeIcon {
    if (_themeMode == ThemeMode.system) {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark ? Icons.dark_mode : Icons.light_mode;
    }
    return _themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode;
  }
}
