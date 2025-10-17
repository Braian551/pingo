// lib/src/widgets/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:ping_go/src/global/services/auth/user_service.dart';
import 'package:ping_go/src/routes/route_names.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      // Verificar si hay una sesión guardada
      final session = await UserService.getSavedSession();

      if (!mounted) return;

      if (session != null && session['email'] != null) {
        // Usuario tiene sesión activa, ir directo a home
        Navigator.of(context).pushReplacementNamed(
          RouteNames.home,
          arguments: {'email': session['email']},
        );
      } else {
        // No hay sesión, mostrar welcome
        Navigator.of(context).pushReplacementNamed(RouteNames.welcome);
      }
    } catch (e) {
      // En caso de error, mostrar welcome por defecto
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(RouteNames.welcome);
      }
    } finally {
      // No necesitamos setState aquí ya que navegamos inmediatamente
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar pantalla de carga mientras se verifica la sesión
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo pequeño mientras se verifica
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFFF00).withOpacity(0.25),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.9],
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 50,
                  height: 50,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verificando sesión...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFFFFFF00),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
