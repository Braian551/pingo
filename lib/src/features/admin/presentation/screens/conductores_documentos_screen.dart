import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ping_go/src/global/services/admin/admin_service.dart';
import 'package:ping_go/src/widgets/snackbars/custom_snackbar.dart';
import 'package:shimmer/shimmer.dart';

class ConductoresDocumentosScreen extends StatefulWidget {
  final int adminId;
  final Map<String, dynamic> adminUser;

  const ConductoresDocumentosScreen({
    super.key,
    required this.adminId,
    required this.adminUser,
  });

  @override
  State<ConductoresDocumentosScreen> createState() => _ConductoresDocumentosScreenState();
}

class _ConductoresDocumentosScreenState extends State<ConductoresDocumentosScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conductores = [];
  Map<String, dynamic>? _estadisticas;
  String _filtroEstado = 'todos';
  
  final Map<String, String> _estadosLabels = {
    'todos': 'Todos',
    'pendiente': 'Pendientes',
    'en_revision': 'En Revisión',
    'aprobado': 'Aprobados',
    'rechazado': 'Rechazados',
  };

  @override
  void initState() {
    super.initState();
    _loadDocumentos();
  }

  Future<void> _loadDocumentos() async {
    setState(() => _isLoading = true);

    try {
      final response = await AdminService.getConductoresDocumentos(
        adminId: widget.adminId,
        estadoVerificacion: _filtroEstado == 'todos' ? null : _filtroEstado,
      );

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _conductores = List<Map<String, dynamic>>.from(response['data']['conductores'] ?? []);
          _estadisticas = response['data']['estadisticas'];
          _isLoading = false;
        });
      } else {
        _showError(response['message'] ?? 'Error al cargar documentos');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Error al cargar documentos: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    CustomSnackbar.showError(context, message: message);
  }

  void _showSuccess(String message) {
    CustomSnackbar.showSuccess(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildShimmerLoading() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Documentos de Conductores',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFFF00)),
          onPressed: _loadDocumentos,
          tooltip: 'Actualizar',
        ),
      ],
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      color: const Color(0xFFFFFF00),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _loadDocumentos,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildEstadisticas()),
          SliverToBoxAdapter(child: _buildFiltros()),
          _buildConductoresList(),
        ],
      ),
    );
  }

  Widget _buildEstadisticas() {
    if (_estadisticas == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen General',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
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
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                'Total',
                _estadisticas!['total_conductores'].toString(),
                Icons.people_rounded,
                const Color(0xFF667eea),
              ),
              _buildStatCard(
                'Pendientes',
                _estadisticas!['pendientes_verificacion'].toString(),
                Icons.pending_rounded,
                const Color(0xFFffa726),
              ),
              _buildStatCard(
                'Aprobados',
                _estadisticas!['aprobados'].toString(),
                Icons.check_circle_rounded,
                const Color(0xFF11998e),
              ),
              _buildStatCard(
                'Docs. Vencidos',
                _estadisticas!['con_documentos_vencidos'].toString(),
                Icons.warning_rounded,
                const Color(0xFFf5576c),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por estado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _estadosLabels.length,
              itemBuilder: (context, index) {
                final entry = _estadosLabels.entries.elementAt(index);
                final isSelected = _filtroEstado == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      entry.value,
                      style: TextStyle(
                        color: isSelected ? Colors.black : const Color.fromARGB(255, 255, 255, 255),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _filtroEstado = entry.key);
                      _loadDocumentos();
                    },
                    backgroundColor: Colors.white.withOpacity(0.1),
                    selectedColor: const Color(0xFFFFFF00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFFFF00) : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConductoresList() {
    if (_conductores.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay conductores en esta categoría',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final conductor = _conductores[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildConductorCard(conductor),
            );
          },
          childCount: _conductores.length,
        ),
      ),
    );
  }

  Widget _buildConductorCard(Map<String, dynamic> conductor) {
    final estadoVerificacion = conductor['estado_verificacion'] ?? 'pendiente';
    final Color estadoColor = _getEstadoColor(estadoVerificacion);
    final hasVencidos = conductor['tiene_documentos_vencidos'] == true;
    
    return GestureDetector(
      onTap: () => _showConductorDetails(conductor),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: estadoColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: estadoColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.drive_eta_rounded,
                        color: estadoColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conductor['nombre_completo'] ?? 'Sin nombre',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conductor['email'] ?? 'Sin email',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildEstadoBadge(estadoVerificacion, estadoColor),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withOpacity(0.1), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.badge_rounded,
                        'Licencia',
                        conductor['licencia_conduccion'] ?? 'N/A',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.local_taxi_rounded,
                        'Placa',
                        conductor['vehiculo_placa'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.star_rounded,
                        'Calificación',
                        '${conductor['calificacion_promedio'] ?? 0.0} (${conductor['total_calificaciones'] ?? 0})',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.directions_car_rounded,
                        'Viajes',
                        '${conductor['total_viajes'] ?? 0}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (conductor['porcentaje_completitud'] ?? 0) / 100,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(estadoColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Documentos: ${conductor['documentos_completos']}/${conductor['total_documentos_requeridos']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    if (hasVencidos)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFf5576c).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_rounded, color: Color(0xFFf5576c), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Docs. Vencidos',
                              style: TextStyle(
                                color: Color(0xFFf5576c),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado, Color color) {
    final Map<String, String> estadosTexto = {
      'pendiente': 'Pendiente',
      'en_revision': 'En Revisión',
      'aprobado': 'Aprobado',
      'rechazado': 'Rechazado',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Text(
        estadosTexto[estado] ?? estado,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.5), size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'aprobado':
        return const Color(0xFF11998e);
      case 'rechazado':
        return const Color(0xFFf5576c);
      case 'en_revision':
        return const Color(0xFF667eea);
      case 'pendiente':
      default:
        return const Color(0xFFffa726);
    }
  }

  void _showConductorDetails(Map<String, dynamic> conductor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildConductorDetailsSheet(conductor),
    );
  }

  Widget _buildConductorDetailsSheet(Map<String, dynamic> conductor) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: const Color(0xFF1A1A1A).withOpacity(0.95),
              child: Column(
                children: [
                  _buildSheetHandle(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailSection('Información Personal', [
                            _buildDetailRow('Nombre completo', conductor['nombre_completo']),
                            _buildDetailRow('Email', conductor['email']),
                            _buildDetailRow('Teléfono', conductor['telefono']),
                            _buildDetailRow('Usuario activo', conductor['es_activo'] == 1 ? 'Sí' : 'No'),
                            _buildDetailRow('Verificado', conductor['es_verificado'] == 1 ? 'Sí' : 'No'),
                          ]),
                          const SizedBox(height: 24),
                          _buildDetailSection('Licencia de Conducción', [
                            _buildDetailRow('Número', conductor['licencia_conduccion']),
                            _buildDetailRow('Categoría', conductor['licencia_categoria']),
                            _buildDetailRow('Expedición', _formatDate(conductor['licencia_expedicion'])),
                            _buildDetailRow('Vencimiento', _formatDate(conductor['licencia_vencimiento'])),
                          ]),
                          const SizedBox(height: 24),
                          _buildDetailSection('Vehículo', [
                            _buildDetailRow('Tipo', conductor['vehiculo_tipo']),
                            _buildDetailRow('Placa', conductor['vehiculo_placa']),
                            _buildDetailRow('Marca', conductor['vehiculo_marca']),
                            _buildDetailRow('Modelo', conductor['vehiculo_modelo']),
                            _buildDetailRow('Año', conductor['vehiculo_anio']?.toString()),
                            _buildDetailRow('Color', conductor['vehiculo_color']),
                          ]),
                          const SizedBox(height: 24),
                          _buildDetailSection('SOAT', [
                            _buildDetailRow('Número', conductor['soat_numero']),
                            _buildDetailRow('Vencimiento', _formatDate(conductor['soat_vencimiento'])),
                          ]),
                          const SizedBox(height: 24),
                          _buildDetailSection('Tecnomecánica', [
                            _buildDetailRow('Número', conductor['tecnomecanica_numero']),
                            _buildDetailRow('Vencimiento', _formatDate(conductor['tecnomecanica_vencimiento'])),
                          ]),
                          const SizedBox(height: 24),
                          _buildDetailSection('Seguro', [
                            _buildDetailRow('Aseguradora', conductor['aseguradora']),
                            _buildDetailRow('Póliza', conductor['numero_poliza_seguro']),
                            _buildDetailRow('Vencimiento', _formatDate(conductor['vencimiento_seguro'])),
                          ]),
                          const SizedBox(height: 24),
                          _buildDetailSection('Otros Documentos', [
                            _buildDetailRow('Tarjeta de propiedad', conductor['tarjeta_propiedad_numero']),
                          ]),
                          const SizedBox(height: 24),
                          _buildDetailSection('Estado de Verificación', [
                            _buildDetailRow('Estado', conductor['estado_verificacion']),
                            _buildDetailRow('Aprobado', conductor['aprobado'] == 1 ? 'Sí' : 'No'),
                            _buildDetailRow('Última verificación', _formatDate(conductor['fecha_ultima_verificacion'])),
                          ]),
                          if (conductor['documentos_vencidos'] != null && (conductor['documentos_vencidos'] as List).isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFf5576c).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFf5576c).withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.warning_rounded, color: Color(0xFFf5576c), size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Documentos Vencidos',
                                            style: TextStyle(
                                              color: Color(0xFFf5576c),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ...(conductor['documentos_vencidos'] as List).map((doc) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.circle, size: 6, color: Color(0xFFf5576c)),
                                            const SizedBox(width: 8),
                                            Text(
                                              doc.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          if (conductor['estado_verificacion'] == 'pendiente' || conductor['estado_verificacion'] == 'en_revision')
                            Column(
                              children: [
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _aprobarConductor(conductor),
                                        icon: const Icon(Icons.check_circle_rounded),
                                        label: const Text('Aprobar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF11998e),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _rechazarConductor(conductor),
                                        icon: const Icon(Icons.cancel_rounded),
                                        label: const Text('Rechazar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFf5576c),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFFFF00),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    final valueStr = value?.toString() ?? 'N/A';
    final isEmpty = value == null || valueStr == 'N/A' || valueStr.isEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              valueStr,
              style: TextStyle(
                color: isEmpty ? Colors.white.withOpacity(0.3) : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty) return 'N/A';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  Future<void> _aprobarConductor(Map<String, dynamic> conductor) async {
    Navigator.pop(context); // Cerrar el sheet

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Aprobar Conductor', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de que deseas aprobar a ${conductor['nombre_completo']}?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF11998e),
            ),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await AdminService.aprobarConductor(
        adminId: widget.adminId,
        conductorId: conductor['usuario_id'],
      );

      if (response['success'] == true) {
        _showSuccess('Conductor aprobado exitosamente');
        _loadDocumentos();
      } else {
        _showError(response['message'] ?? 'Error al aprobar conductor');
      }
    }
  }

  Future<void> _rechazarConductor(Map<String, dynamic> conductor) async {
    Navigator.pop(context); // Cerrar el sheet

    final motivoController = TextEditingController();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rechazar Conductor', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indica el motivo del rechazo para ${conductor['nombre_completo']}:',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe el motivo...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.trim().isEmpty) {
                _showError('Debes indicar el motivo del rechazo');
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf5576c),
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirm == true && motivoController.text.trim().isNotEmpty) {
      final response = await AdminService.rechazarConductor(
        adminId: widget.adminId,
        conductorId: conductor['usuario_id'],
        motivo: motivoController.text.trim(),
      );

      if (response['success'] == true) {
        _showSuccess('Conductor rechazado');
        _loadDocumentos();
      } else {
        _showError(response['message'] ?? 'Error al rechazar conductor');
      }
    }
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFF1A1A1A),
              highlightColor: const Color(0xFF2A2A2A),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
