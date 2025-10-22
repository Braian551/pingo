// lib/src/features/admin/presentation/screens/audit_logs_screen.dart
import 'package:flutter/material.dart';
import 'package:ping_go/src/global/services/admin/admin_service.dart';

class AuditLogsScreen extends StatefulWidget {
  final int adminId;

  const AuditLogsScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    
    final response = await AdminService.getAuditLogs(
      adminId: widget.adminId,
      page: _currentPage,
      perPage: 50,
    );
    
    if (response['success'] == true && response['data'] != null) {
      setState(() {
        _logs = response['data']['logs'] ?? [];
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
        title: const Text('Logs de Auditoría', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFFF00)),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFFF00)))
          : _logs.isEmpty
              ? const Center(
                  child: Text(
                    'No hay logs disponibles',
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFFFF00),
                  backgroundColor: Colors.black,
                  onRefresh: _loadLogs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _buildLogCard(log);
                    },
                  ),
                ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final accion = log['accion'] ?? '';
    final descripcion = log['descripcion'] ?? '';
    final usuario = '${log['nombre'] ?? ''} ${log['apellido'] ?? ''}'.trim();
    final fecha = _formatDate(log['fecha_creacion']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getActionColor(accion).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  accion,
                  style: TextStyle(
                    color: _getActionColor(accion),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                fecha,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (usuario.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.white60),
                const SizedBox(width: 4),
                Text(
                  usuario,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (log['email'] != null) ...[
                  const Text(' • ', style: TextStyle(color: Colors.white30)),
                  Text(
                    log['email'],
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getActionColor(String accion) {
    if (accion.contains('login')) return Colors.green;
    if (accion.contains('crear')) return Colors.blue;
    if (accion.contains('actualizar') || accion.contains('editar')) return Colors.orange;
    if (accion.contains('eliminar') || accion.contains('desactivar')) return Colors.red;
    return const Color(0xFFFFFF00);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
