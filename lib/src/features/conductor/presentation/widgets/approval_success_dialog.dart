import 'dart:ui';
import 'package:flutter/material.dart';

/// DiÃ¡logo de Ã©xito cuando el conductor es aprobado
class ApprovalSuccessDialog extends StatefulWidget {
  const ApprovalSuccessDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const ApprovalSuccessDialog(),
    );
  }

  @override
  State<ApprovalSuccessDialog> createState() => _ApprovalSuccessDialogState();
}

class _ApprovalSuccessDialogState extends State<ApprovalSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: padding, vertical: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: size.height * 0.85,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A1A1A).withValues(alpha: 0.95),
                            const Color(0xFF0D0D0D).withValues(alpha: 0.95),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          width: 1.5,
                          color: const Color(0xFF11998e).withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF11998e).withValues(alpha: 0.25),
                            blurRadius: 40,
                            spreadRadius: 0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(isSmallScreen),
                            _buildContent(isSmallScreen),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 32 : 48,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF11998e).withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // AnimaciÃ³n de Ã©xito con efecto de pulso
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: isSmallScreen ? 100 : 130,
                  height: isSmallScreen ? 100 : 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF11998e).withValues(alpha: 0.4),
                        const Color(0xFF11998e).withValues(alpha: 0.2),
                        const Color(0xFF11998e).withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.2, 0.4, 0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF11998e).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.verified_rounded,
                      size: isSmallScreen ? 60 : 80,
                      color: const Color(0xFF11998e),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isSmallScreen ? 20 : 28),
          
          // TÃ­tulo animado
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF11998e),
                  Color(0xFF38ef7d),
                ],
              ).createShader(bounds),
              child: Text(
                'Â¡Felicidades!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 28 : 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 20 : 28,
        8,
        isSmallScreen ? 20 : 28,
        isSmallScreen ? 24 : 32,
      ),
      child: Column(
        children: [
          // Mensaje principal
          Text(
            'Tus documentos han sido aprobados',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          // Cards informativos
          _buildInfoCard(
            icon: Icons.verified_user_rounded,
            title: 'VerificaciÃ³n completa',
            description: 'Tu perfil ha sido verificado exitosamente',
            color: const Color(0xFF11998e),
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(height: 12),
          
          _buildInfoCard(
            icon: Icons.local_taxi_rounded,
            title: 'Â¡Ya puedes comenzar!',
            description: 'Activa tu disponibilidad para recibir viajes',
            color: const Color(0xFFFFFF00),
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 24 : 32),

          // BotÃ³n principal mejorado
          SizedBox(
            width: double.infinity,
            height: isSmallScreen ? 52 : 58,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11998e),
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: const Color(0xFF11998e).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Comenzar a Conducir',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: isSmallScreen ? 18 : 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmallScreen ? 26 : 30,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
