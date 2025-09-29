import 'package:flutter/material.dart';
import 'package:ping_go/src/features/auth/presentation/screens/home_auth.dart';
import 'package:ping_go/src/features/auth/presentation/screens/login_screen.dart';
import 'package:ping_go/src/features/auth/presentation/screens/register_screen.dart';
import 'package:ping_go/src/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:ping_go/src/features/auth/presentation/screens/email_auth_screen.dart';
import 'package:ping_go/src/features/auth/presentation/screens/email_verification_screen.dart';
// import 'package:ping_go/src/features/map/presentation/screens/location_selection_screen.dart'; // COMENTADO - YA NO SE USA
// ride HomeScreen still available but the authenticated entrypoint should be HomeAuth
import 'package:ping_go/src/features/map/presentation/screens/location_picker_screen.dart';
import 'package:ping_go/src/features/auth/presentation/screens/welcome_screen.dart';
import 'package:ping_go/src/routes/route_names.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.phoneAuth:
        return MaterialPageRoute(builder: (_) => const PhoneAuthScreen());
      case RouteNames.emailAuth:
        return MaterialPageRoute(builder: (_) => const EmailAuthScreen());
      case RouteNames.emailVerification:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: args?['email'] ?? '',
              userName: args?['userName'] ?? '',
            ),
          );
        }
      case RouteNames.register:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => RegisterScreen(
              email: args?['email'] ?? '',
              userName: args?['userName'] ?? '',
            ),
          );
        }
      case RouteNames.locationPicker:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => LocationPickerScreen(
              initialAddress: args?['initialAddress'],
              initialLocation: args?['initialLocation'],
              screenTitle: args?['screenTitle'] ?? 'Seleccionar ubicación',
              showConfirmButton: args?['showConfirmButton'] ?? true,
            ),
          );
        }
      case RouteNames.home:
        // Cuando el usuario se autentique debe ir a HomeAuth (pantalla principal auth)
        return MaterialPageRoute(builder: (_) => const HomeAuth());
      // Agregar más rutas aquí
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No existe la ruta: ${settings.name}'),
            ),
          ),
        );
    }
  }
}