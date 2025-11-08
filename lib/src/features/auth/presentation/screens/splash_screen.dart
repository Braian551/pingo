import 'dart:async';

import 'package:flutter/material.dart';
import 'package:viax/src/routes/route_names.dart';
import 'package:viax/src/theme/app_colors.dart';
import 'package:viax/src/features/auth/presentation/widgets/logo_transition.dart';

/// Indicador de carga minimalista inspirado en TikTok
class MinimalLoadingIndicator extends StatefulWidget {
  const MinimalLoadingIndicator({super.key});

  @override
  State<MinimalLoadingIndicator> createState() => _MinimalLoadingIndicatorState();
}

class _MinimalLoadingIndicatorState extends State<MinimalLoadingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnim.value,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(_opacityAnim.value * (isDark ? 1.0 : 0.7)),
                borderRadius: BorderRadius.circular(1),
                boxShadow: isDark ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3 * _opacityAnim.value),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ] : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _pulseController;
  late final AnimationController _rotationController;
  
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _subtitleSlideAnim;
  late final Animation<double> _textScaleAnim;
  late final Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();

    // Animación principal
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Animación de pulso continuo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Animación de rotación sutil
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Escala con efecto bounce
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Fade in suave
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Efecto de slide desde abajo para el texto principal (más natural)
    _slideAnim = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutBack),
      ),
    );

    // Efecto de slide desde abajo para el subtítulo (más suave y retrasado)
    _subtitleSlideAnim = Tween<double>(begin: 25.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOutBack),
      ),
    );

    // Efecto de escala para el texto (efecto pop natural)
    _textScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: Curves.elasticOut),
      ),
    );

    // Pulso del glow
    _pulseAnim = Tween<double>(begin: 0.15, end: 0.30).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Rotación sutil
    _rotationAnim = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
    _rotationController.forward();

    // Delay navigation to ensure animation is visible
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 3000));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(RouteNames.authWrapper);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _pulseController, _rotationController]),
        builder: (context, child) {
          return Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing circular logo con animaciones - HERO ANIMATION
                  LogoHeroTransition(
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: Transform.rotate(
                        angle: _rotationAnim.value,
                        child: AnimatedLogo(
                          size: 86,
                          glowOpacity: Theme.of(context).brightness == Brightness.dark 
                              ? _pulseAnim.value 
                              : _pulseAnim.value * 0.3,
                          scale: 1.0,
                          rotation: 0.0,
                          showGlow: true,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // App name con animación de slide y escala
                  Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Transform.scale(
                      scale: _textScaleAnim.value,
                      child: Opacity(
                        opacity: _fadeAnim.value,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Viax',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  foreground: Paint()
                                    ..shader = LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryLight,
                                        AppColors.accent,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ).createShader(const Rect.fromLTWH(0, 0, 200, 0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtítulo con fade y slide independiente
                  Transform.translate(
                    offset: Offset(0, _subtitleSlideAnim.value),
                    child: Opacity(
                      opacity: _fadeAnim.value * 0.9,
                      child: Text(
                        'Viaja fácil, llega rápido',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
