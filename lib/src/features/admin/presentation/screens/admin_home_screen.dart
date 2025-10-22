// lib/src/features/admin/presentation/screens/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:ping_go/src/global/services/admin/admin_service.dart';
import 'package:ping_go/src/routes/route_names.dart';
import 'package:ping_go/src/widgets/snackbars/custom_snackbar.dart';

class AdminHomeScreen extends StatefulWidget {
  final Map<String, dynamic> adminUser;

  const AdminHomeScreen({
    super.key,
    required this.adminUser,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final adminId = int.tryParse(widget.adminUser['id']?.toString() ?? '0') ?? 0;
      
      final response = await AdminService.getDashboardStats(adminId: adminId);

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _dashboardData = response['data'];
          _isLoading = false;
        });
      } else {
        _showError('No se pudieron cargar las estadísticas');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Error al cargar datos: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    CustomSnackbar.showError(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final adminName = widget.adminUser['nombre'] ?? 'Admin';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Panel de Administración',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Bienvenido, $adminName',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFFF00)),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () {
              // Cerrar sesión
              Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.welcome,
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFFF00)),
            )
          : RefreshIndicator(
              color: const Color(0xFFFFFF00),
              backgroundColor: Colors.black,
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estadísticas principales
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    // Menú de opciones
                    _buildAdminMenu(),
                    const SizedBox(height: 24),

                    // Actividad reciente
                    _buildRecentActivity(),
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
          'Estadísticas Generales',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              title: 'Total Usuarios',
              value: users['total_usuarios']?.toString() ?? '0',
              subtitle: 'Activos: ${users['usuarios_activos'] ?? 0}',
              icon: Icons.people,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'Solicitudes',
              value: solicitudes['total_solicitudes']?.toString() ?? '0',
              subtitle: 'Hoy: ${solicitudes['solicitudes_hoy'] ?? 0}',
              icon: Icons.assignment,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'Ingresos Totales',
              value: '\$${_formatNumber(ingresos['ingresos_totales'])}',
              subtitle: 'Hoy: \$${_formatNumber(ingresos['ingresos_hoy'])}',
              icon: Icons.attach_money,
              color: const Color(0xFFFFFF00),
            ),
            _buildStatCard(
              title: 'Reportes',
              value: reportes['reportes_pendientes']?.toString() ?? '0',
              subtitle: 'Pendientes',
              icon: Icons.report_problem,
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenu() {
    final adminId = int.tryParse(widget.adminUser['id']?.toString() ?? '0') ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestión',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          title: 'Gestión de Usuarios',
          subtitle: 'Ver, editar y administrar usuarios',
          icon: Icons.people_outline,
          onTap: () {
            Navigator.pushNamed(
              context,
              RouteNames.adminUsers,
              arguments: {'admin_id': adminId, 'admin_user': widget.adminUser},
            );
          },
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Estadísticas Detalladas',
          subtitle: 'Gráficas y métricas del sistema',
          icon: Icons.bar_chart,
          onTap: () {
            Navigator.pushNamed(
              context,
              RouteNames.adminStatistics,
              arguments: {'admin_id': adminId},
            );
          },
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Logs de Auditoría',
          subtitle: 'Historial de acciones del sistema',
          icon: Icons.history,
          onTap: () {
            Navigator.pushNamed(
              context,
              RouteNames.adminAuditLogs,
              arguments: {'admin_id': adminId},
            );
          },
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'Configuración',
          subtitle: 'Ajustes generales de la app',
          icon: Icons.settings,
          onTap: () {
            _showError('Función en desarrollo');
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFF00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFFFFFF00), size: 24),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white30),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final actividades = _dashboardData?['actividades_recientes'] ?? [];

    if (actividades.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Reciente',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actividades.length > 5 ? 5 : actividades.length,
            separatorBuilder: (_, __) => const Divider(
              color: Colors.white10,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final actividad = actividades[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFFF00).withOpacity(0.1),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Color(0xFFFFFF00),
                    size: 20,
                  ),
                ),
                title: Text(
                  actividad['descripcion'] ?? 'Sin descripción',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  '${actividad['nombre'] ?? ''} ${actividad['apellido'] ?? ''} • ${_formatDate(actividad['fecha_creacion'])}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              );
            },
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
