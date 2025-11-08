import 'dart:async';

import 'package:flutter/material.dart';
import 'package:viax/src/routes/route_names.dart';
import 'package:viax/src/theme/app_colors.dart';

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
      duration: const Duration(milliseconds: 3000),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Delay navigation to ensure animation is visible
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 3500));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(RouteNames.authWrapper);
    }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        AppColors.primary.withOpacity(0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.9],
                    ),
                    boxShadow: [
                      AppColors.primaryGlow(opacity: 0.12, blur: 30, spread: 8),
                    ],
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ).createShader(bounds);
                      },
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 86,
                        height: 86,
                        color: Colors.white,
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
                        text: 'Viax',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 0)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Transporte y entregas rápidas',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
