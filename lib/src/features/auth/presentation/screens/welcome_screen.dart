// lib/src/features/auth/presentation/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:ping_go/src/routes/route_names.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Column(
            children: [
              SizedBox(height: size.height * 0.12),
              
              // Icono de auto moderno con efecto de profundidad
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF39FF14).withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.1, 0.8],
                  ),
                ),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF39FF14),
                        Color(0xFF25C40A),
                      ],
                    ).createShader(bounds);
                  },
                  child: const Icon(
                    Icons.sports_motorsports_outlined,
                    size: 85,
                    color: Colors.white, // Este color será reemplazado por el gradiente
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Texto de bienvenida
              const Text(
                'Bienvenido a Ping-Go',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Subtítulo
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Movilidad y entregas rápidas a tu alcance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ),
              
              SizedBox(height: size.height * 0.07),
              
              // Botones de autenticación
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Iniciar con Google - Corregido
                    _buildSocialButton(
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.g_mobiledata,
                            size: 24,
                            color: Colors.black,
                          );
                        },
                      ),
                      text: 'Continuar con Google',
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                      onPressed: () {
                        // Lógica para inicio con Google
                      },
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Iniciar con Apple
                    _buildSocialButton(
                      icon: const Icon(
                        Icons.apple,
                        color: Colors.white,
                        size: 24,
                      ),
                      text: 'Continuar con Apple',
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      borderColor: Colors.white.withOpacity(0.3),
                      onPressed: () {
                        // Lógica para inicio con Apple
                      },
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Iniciar con teléfono
                    _buildSocialButton(
                      icon: const Icon(
                        Icons.phone_iphone_outlined,
                        color: Colors.black,
                        size: 24,
                      ),
                      text: 'Continuar con teléfono',
                      backgroundColor: const Color(0xFF39FF14),
                      textColor: Colors.black,
                      onPressed: () {
                        Navigator.pushNamed(context, RouteNames.phoneAuth);
                      },
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Iniciar con correo
                    _buildSocialButton(
                      icon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF39FF14),
                        size: 24,
                      ),
                      text: 'Continuar con correo',
                      backgroundColor: Colors.transparent,
                      textColor: const Color(0xFF39FF14),
                      borderColor: const Color(0xFF39FF14).withOpacity(0.5),
                      onPressed: () {
                        Navigator.pushNamed(context, RouteNames.emailAuth);
                      },
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // Términos y condiciones
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: 'Al continuar, aceptas nuestros ',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'Términos de Servicio',
                              style: TextStyle(
                                color: const Color(0xFF39FF14).withOpacity(0.8),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' y '),
                            TextSpan(
                              text: 'Política de Privacidad',
                              style: TextStyle(
                                color: const Color(0xFF39FF14).withOpacity(0.8),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    Color borderColor = Colors.transparent,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: borderColor,
              width: 1.2,
            ),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}