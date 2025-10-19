import 'package:flutter/material.dart';
import 'package:ping_go/src/features/auth/presentation/screens/home_auth.dart';
import 'package:ping_go/src/features/auth/presentation/screens/login_screen.dart';
import 'package:ping_go/src/features/auth/presentation/screens/register_screen.dart';
import 'package:ping_go/src/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:ping_go/src/features/auth/presentation/screens/email_auth_screen.dart';
import 'package:ping_go/src/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:ping_go/src/features/onboarding/presentation/screens/onboarding_screen.dart';
// import 'package:ping_go/src/features/map/presentation/screens/location_selection_screen.dart'; // COMENTADO - YA NO SE USA
// ride HomeScreen still available but the authenticated entrypoint should be HomeAuth
import 'package:ping_go/src/features/map/presentation/screens/location_picker_screen.dart';
import 'package:ping_go/src/features/auth/presentation/screens/welcome_screen.dart';
import 'package:ping_go/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:ping_go/src/routes/route_names.dart';
import 'package:ping_go/src/routes/animated_routes.dart';
import 'package:ping_go/src/widgets/auth_wrapper.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        // initial route used by Navigator(initialRoute: '/')
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case RouteNames.onboarding:
        return FadeSlidePageRoute(page: const OnboardingScreen(), settings: settings);
      case RouteNames.authWrapper:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      case RouteNames.welcome:
        return FadeSlidePageRoute(page: const WelcomeScreen(), settings: settings);
      case RouteNames.login:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return FadeSlidePageRoute(
            page: LoginScreen(
              email: args?['email'],
              prefilled: args?['prefilled'] ?? false,
            ),
            settings: settings,
          );
        }
      case RouteNames.phoneAuth:
        return FadeSlidePageRoute(page: const PhoneAuthScreen(), settings: settings);
      case RouteNames.emailAuth:
        return FadeSlidePageRoute(page: const EmailAuthScreen(), settings: settings);
      case RouteNames.emailVerification:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return FadeSlidePageRoute(
            page: EmailVerificationScreen(
              email: args?['email'] ?? '',
              userName: args?['userName'] ?? '',
            ),
            settings: settings,
          );
        }
      case RouteNames.register:
        {
          final args = settings.arguments as Map<String, dynamic>?;
          return FadeSlidePageRoute(
            page: RegisterScreen(
              email: args?['email'] ?? '',
              userName: args?['userName'] ?? '',
            ),
            settings: settings,
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
        // Cuando el usuario se autentique debe ir a la pantalla principal (HomeScreen)
        return MaterialPageRoute(builder: (_) => const HomeScreen());
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