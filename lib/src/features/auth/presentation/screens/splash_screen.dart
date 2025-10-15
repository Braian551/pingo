import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ping_go/src/routes/route_names.dart';
import 'package:ping_go/src/global/services/auth/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Navigate after a short delay so animation can finish
    Timer(const Duration(milliseconds: 2200), () async {
      if (!mounted) return;
      final session = await UserService.getSavedSession();
      if (session != null) {
        // If session exists, go directly to home
        if (mounted) Navigator.of(context).pushReplacementNamed(RouteNames.home);
      } else {
        if (mounted) Navigator.of(context).pushReplacementNamed(RouteNames.welcome);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing circular logo
                Container(
                  width: size.width * 0.36,
                  height: size.width * 0.36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFFF00).withOpacity(0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.9],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFFF00).withOpacity(0.12),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFFF00), Color(0xFFFFFF00)],
                        ).createShader(bounds);
                      },
                      child: const Icon(
                        Icons.sports_motorsports_outlined,
                        size: 86,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // App name with subtle gradient
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Ping',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFFFFFF00), Color(0xFFFFFF00)],
                            ).createShader(Rect.fromLTWH(0, 0, 200, 0)),
                        ),
                      ),
                      TextSpan(
                        text: '-Go',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.92),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Movilidad y entregas rápidas',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
