// lib/src/features/admin/presentation/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:ping_go/src/global/services/admin/admin_service.dart';

class StatisticsScreen extends StatefulWidget {
  final int adminId;

  const StatisticsScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    final response = await AdminService.getDashboardStats(adminId: widget.adminId);
    
    if (response['success'] == true && response['data'] != null) {
      setState(() {
        _stats = response['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text('Estadísticas', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFFF00)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registros Últimos 7 Días',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRegistrosChart(),
                  const SizedBox(height: 24),
                  _buildStatsDetails(),
                ],
              ),
            ),
    );
  }

  Widget _buildRegistrosChart() {
    final registros = _stats?['registros_ultimos_7_dias'] ?? [];
    
    if (registros.isEmpty) {
      return const Card(
        color: Color(0xFF1A1A1A),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No hay datos disponibles',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: registros.map<Widget>((registro) {
          final fecha = registro['fecha']?.toString() ?? '';
          final cantidad = int.tryParse(registro['cantidad']?.toString() ?? '0') ?? 0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    fecha,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: cantidad / 10, // Normalizado, ajustar según necesidad
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFFF00)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  cantidad.toString(),
                  style: const TextStyle(
                    color: Color(0xFFFFFF00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsDetails() {
    final users = _stats?['usuarios'] ?? {};
    final solicitudes = _stats?['solicitudes'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailCard('Total Usuarios', users['total_usuarios']?.toString() ?? '0'),
        _buildDetailCard('Clientes', users['total_clientes']?.toString() ?? '0'),
        _buildDetailCard('Conductores', users['total_conductores']?.toString() ?? '0'),
        _buildDetailCard('Solicitudes Totales', solicitudes['total_solicitudes']?.toString() ?? '0'),
        _buildDetailCard('Completadas', solicitudes['completadas']?.toString() ?? '0'),
        _buildDetailCard('Canceladas', solicitudes['canceladas']?.toString() ?? '0'),
      ],
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFFF00),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
