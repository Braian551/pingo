// lib/src/features/admin/presentation/screens/admin_home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ping_go/src/global/services/admin/admin_service.dart';
import 'package:ping_go/src/routes/route_names.dart';
import 'package:ping_go/src/widgets/snackbars/custom_snackbar.dart';
import 'package:shimmer/shimmer.dart';

class AdminHomeScreen extends StatefulWidget {
  final Map<String, dynamic> adminUser;

  AdminHomeScreen({
    super.key,
    required this.adminUser,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOutBack),
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final adminId = int.tryParse(widget.adminUser['id']?.toString() ?? '0') ?? 0;
      
      print('AdminHomeScreen: Cargando datos para adminId: $adminId');
      
      final response = await AdminService.getDashboardStats(adminId: adminId);
      
      print('AdminHomeScreen: Response recibida: $response');

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _dashboardData = response['data'];
          _isLoading = false;
        });
        _animationController.forward();
        _cardAnimationController.forward();
      } else {
        final errorMsg = response['message'] ?? 'No se pudieron cargar las estadísticas';
        _showError(errorMsg);
        // Cargar datos de prueba para testing
        setState(() {
          _dashboardData = _getDefaultDashboardData();
          _isLoading = false;
        });
        _animationController.forward();
        _cardAnimationController.forward();
      }
    } catch (e) {
      print('AdminHomeScreen Error: $e');
      _showError('Error al cargar datos: $e');
      // Cargar datos de prueba para testing
      setState(() {
        _dashboardData = _getDefaultDashboardData();
        _isLoading = false;
      });
      _animationController.forward();
      _cardAnimationController.forward();
    }
  }

  Map<String, dynamic> _getDefaultDashboardData() {
    return {
      'usuarios': {
        'total_usuarios': 0,
        'total_clientes': 0,
        'total_conductores': 0,
        'usuarios_activos': 0,
        'registros_hoy': 0,
      },
      'solicitudes': {
        'total_solicitudes': 0,
        'completadas': 0,
        'canceladas': 0,
        'en_proceso': 0,
        'solicitudes_hoy': 0,
      },
      'ingresos': {
        'ingresos_totales': 0,
        'ingresos_hoy': 0,
      },
      'reportes': {
        'reportes_pendientes': 0,
      },
      'actividades_recientes': [],
      'registros_ultimos_7_dias': [],
    };
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    CustomSnackbar.showError(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    // Usar datos del admin del widget o del dashboard como fallback
    final adminData = _dashboardData?['admin'] ?? widget.adminUser;
    final adminName = (adminData['nombre'] ?? widget.adminUser['nombre'] ?? 'Braian').toString();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(adminName),
      body: _isLoading ? _buildShimmerLoading() : _buildContent(adminName),
    );
  }

  PreferredSizeWidget _buildModernAppBar(String adminName) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFFF00).withOpacity(0.15),
              border: Border.all(
                color: const Color(0xFFFFFF00).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFFFFFF00),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Panel Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  adminName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFFF00), size: 22),
            onPressed: _loadDashboardData,
            tooltip: 'Actualizar',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 22),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.welcome,
                (route) => false,
              );
            },
            tooltip: 'Cerrar sesión',
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildShimmerBox(height: 60, width: 200),
            const SizedBox(height: 24),
            _buildShimmerBox(height: 24, width: 180),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: List.generate(4, (index) => _buildShimmerBox(height: 140)),
            ),
            const SizedBox(height: 30),
            _buildShimmerBox(height: 24, width: 150),
            const SizedBox(height: 16),
            Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildShimmerBox(height: 80, width: double.infinity),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double height, double? width}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A1A),
      highlightColor: const Color(0xFF2A2A2A),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildContent(String adminName) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          color: const Color(0xFFFFFF00),
          backgroundColor: const Color(0xFF1A1A1A),
          onRefresh: _loadDashboardData,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildWelcomeSection(adminName),
                  const SizedBox(height: 30),
                  _buildStatsGrid(),
                  const SizedBox(height: 30),
                  _buildAdminMenu(),
                  const SizedBox(height: 30),
                  _buildRecentActivity(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String adminName) {
    // Determine greeting based on time of day
    final hour = DateTime.now().hour;
    String greeting = 'Buenos días';
    IconData greetingIcon = Icons.wb_sunny_rounded;
    
    if (hour >= 12 && hour < 18) {
      greeting = 'Buenas tardes';
      greetingIcon = Icons.wb_cloudy_rounded;
    } else if (hour >= 18) {
      greeting = 'Buenas noches';
      greetingIcon = Icons.nightlight_round;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFF00).withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFFF00).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFF00).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFFF00).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(greetingIcon, color: Colors.black, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adminName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final users = _dashboardData?['usuarios'] ?? {};
    final solicitudes = _dashboardData?['solicitudes'] ?? {};
    final ingresos = _dashboardData?['ingresos'] ?? {};
    final reportes = _dashboardData?['reportes'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard en vivo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildModernStatCard(
              title: 'Usuarios',
              value: (users['total_usuarios'] ?? 0).toString(),
              subtitle: 'Activos: ${users['usuarios_activos'] ?? 0}',
              icon: Icons.people_rounded,
              gradientColors: [
                const Color(0xFF667eea).withOpacity(0.8),
                const Color(0xFF764ba2).withOpacity(0.8),
              ],
            ),
            _buildModernStatCard(
              title: 'Solicitudes',
              value: (solicitudes['total_solicitudes'] ?? 0).toString(),
              subtitle: 'Hoy: ${solicitudes['solicitudes_hoy'] ?? 0}',
              icon: Icons.assignment_rounded,
              gradientColors: [
                const Color(0xFF11998e).withOpacity(0.8),
                const Color(0xFF38ef7d).withOpacity(0.8),
              ],
            ),
            _buildModernStatCard(
              title: 'Ingresos',
              value: '\$${_formatNumber(ingresos['ingresos_totales'])}',
              subtitle: 'Hoy: \$${_formatNumber(ingresos['ingresos_hoy'])}',
              icon: Icons.attach_money_rounded,
              gradientColors: [
                const Color(0xFFFFFF00).withOpacity(0.8),
                const Color(0xFFffa726).withOpacity(0.8),
              ],
            ),
            _buildModernStatCard(
              title: 'Reportes',
              value: (reportes['reportes_pendientes'] ?? 0).toString(),
              subtitle: 'Pendientes',
              icon: Icons.report_problem_rounded,
              gradientColors: [
                const Color(0xFFf093fb).withOpacity(0.8),
                const Color(0xFFf5576c).withOpacity(0.8),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: gradientColors[0].withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: gradientColors[0].withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: gradientColors[0].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: gradientColors[0], size: 20),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminMenu() {
    final adminId = int.tryParse(widget.adminUser['id']?.toString() ?? '0') ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestión del sistema',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        _ModernMenuCard(
          title: 'Gestión de Usuarios',
          subtitle: 'Administrar y editar usuarios',
          icon: Icons.people_outline_rounded,
          accentColor: const Color(0xFF667eea),
          onTap: () {
            Navigator.pushNamed(
              context,
              RouteNames.adminUsers,
              arguments: {'admin_id': adminId, 'admin_user': widget.adminUser},
            );
          },
        ),
        const SizedBox(height: 12),
        _ModernMenuCard(
          title: 'Estadísticas Detalladas',
          subtitle: 'Gráficas y métricas avanzadas',
          icon: Icons.bar_chart_rounded,
          accentColor: const Color(0xFF11998e),
          onTap: () {
            Navigator.pushNamed(
              context,
              RouteNames.adminStatistics,
              arguments: {'admin_id': adminId},
            );
          },
        ),
        const SizedBox(height: 12),
        _ModernMenuCard(
          title: 'Logs de Auditoría',
          subtitle: 'Historial de acciones del sistema',
          icon: Icons.history_rounded,
          accentColor: const Color(0xFFf093fb),
          onTap: () {
            Navigator.pushNamed(
              context,
              RouteNames.adminAuditLogs,
              arguments: {'admin_id': adminId},
            );
          },
        ),
        const SizedBox(height: 12),
        _ModernMenuCard(
          title: 'Configuración',
          subtitle: 'Ajustes generales de la aplicación',
          icon: Icons.settings_rounded,
          accentColor: const Color(0xFFffa726),
          onTap: () {
            _showError('Función en desarrollo');
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final actividades = _dashboardData?['actividades_recientes'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad reciente',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        if (actividades.isEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white.withOpacity(0.3),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sin actividad reciente',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Las acciones del sistema aparecerán aquí',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: actividades.length > 5 ? 5 : actividades.length,
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.white.withOpacity(0.05),
                    height: 1,
                    indent: 72,
                  ),
                  itemBuilder: (context, index) {
                    final actividad = actividades[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFF00).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFFFF00).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFFFFFF00),
                          size: 22,
                        ),
                      ),
                      title: Text(
                        actividad['descripcion'] ?? 'Sin descripción',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${actividad['nombre'] ?? ''} ${actividad['apellido'] ?? ''} • ${_formatDate(actividad['fecha_creacion'])}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final num = double.tryParse(value.toString()) ?? 0;
    return num.toStringAsFixed(0);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return 'Hace ${diff.inMinutes}m';
      } else if (diff.inHours < 24) {
        return 'Hace ${diff.inHours}h';
      } else {
        return 'Hace ${diff.inDays}d';
      }
    } catch (e) {
      return dateStr;
    }
  }
}

// Modern Menu Card Widget
class _ModernMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModernMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                splashColor: accentColor.withOpacity(0.1),
                highlightColor: accentColor.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(icon, color: accentColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withOpacity(0.4),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
