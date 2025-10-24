import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/conductor_provider.dart';

class ConductorTripsScreen extends StatefulWidget {
  final int conductorId;

  const ConductorTripsScreen({
    super.key,
    required this.conductorId,
  });

  @override
  State<ConductorTripsScreen> createState() => _ConductorTripsScreenState();
}

class _ConductorTripsScreenState extends State<ConductorTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterStatus = 'todos'; // todos, completados, cancelados

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrips();
    });
  }

  Future<void> _loadTrips() async {
    final provider = Provider.of<ConductorProvider>(context, listen: false);
    // In real app, load trip history from API
    await provider.loadViajesActivos(widget.conductorId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: Consumer<ConductorProvider>(
                builder: (context, provider, child) {
                  return RefreshIndicator(
                    onRefresh: _loadTrips,
                    color: const Color(0xFFFFFF00),
                    backgroundColor: const Color(0xFF1A1A1A),
                    child: _buildTripsList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
        'Historial de Viajes',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white),
          onPressed: () {
            // Show search
          },
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todos', 'todos', Icons.list_rounded),
            const SizedBox(width: 12),
            _buildFilterChip('Completados', 'completados', Icons.check_circle_rounded),
            const SizedBox(width: 12),
            _buildFilterChip('Cancelados', 'cancelados', Icons.cancel_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFFF00).withOpacity(0.2)
              : const Color(0xFF1A1A1A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFFF00)
                : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFFFF00) : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFFF00) : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsList() {
    // Mock data - in real app this would come from provider
    final trips = _getMockTrips();

    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay viajes en esta categoría',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: trips.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildTripCard(trips[index]),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final status = trip['status'] ?? 'completado';
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'completado':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelado':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_rounded;
    }

    return GestureDetector(
      onTap: () => _showTripDetails(trip),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            trip['date'] ?? 'Hoy',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Customer info
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFF00).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: Color(0xFFFFFF00),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip['customerName'] ?? 'Cliente',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFFFF00),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      trip['customerRating']?.toString() ?? '5.0',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Route
                      _buildRouteInfo(
                        Icons.location_on_rounded,
                        trip['pickup'] ?? 'Punto de recogida',
                        true,
                      ),
                      _buildRouteLine(),
                      _buildRouteInfo(
                        Icons.flag_rounded,
                        trip['destination'] ?? 'Destino',
                        false,
                      ),
                      const SizedBox(height: 16),
                      // Stats
                      Row(
                        children: [
                          _buildStatBadge(
                            Icons.route_rounded,
                            '${trip['distance'] ?? '5.2'} km',
                          ),
                          const SizedBox(width: 12),
                          _buildStatBadge(
                            Icons.access_time_rounded,
                            '${trip['duration'] ?? '15'} min',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Footer with earnings
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ganancia del viaje',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '+\$${trip['earnings'] ?? '12,500'}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfo(IconData icon, String text, bool isPickup) {
    return Row(
      children: [
        Icon(
          icon,
          color: isPickup ? const Color(0xFFFFFF00) : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteLine() {
    return Padding(
      padding: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
      child: Container(
        width: 2,
        height: 20,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFFF00).withOpacity(0.5),
              Colors.red.withOpacity(0.5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showTripDetails(Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles del Viaje',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDetailItem(
                        'Cliente',
                        trip['customerName'] ?? 'N/A',
                        Icons.person_rounded,
                      ),
                      _buildDetailItem(
                        'Fecha',
                        trip['fullDate'] ?? '24 Oct 2025, 10:30 AM',
                        Icons.calendar_today_rounded,
                      ),
                      _buildDetailItem(
                        'Distancia',
                        '${trip['distance'] ?? '5.2'} km',
                        Icons.route_rounded,
                      ),
                      _buildDetailItem(
                        'Duración',
                        '${trip['duration'] ?? '15'} minutos',
                        Icons.access_time_rounded,
                      ),
                      _buildDetailItem(
                        'Ganancia',
                        '\$${trip['earnings'] ?? '12,500'}',
                        Icons.attach_money,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          backgroundColor: const Color(0xFFFFFF00),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFF00).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFFFF00), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockTrips() {
    final allTrips = [
      {
        'status': 'completado',
        'date': 'Hoy, 10:30 AM',
        'fullDate': '24 Oct 2025, 10:30 AM',
        'customerName': 'Juan Pérez',
        'customerRating': 4.8,
        'pickup': 'Calle 123, Centro',
        'destination': 'Av. Principal 456',
        'distance': 5.2,
        'duration': 15,
        'earnings': 12500,
      },
      {
        'status': 'completado',
        'date': 'Hoy, 9:15 AM',
        'fullDate': '24 Oct 2025, 9:15 AM',
        'customerName': 'María García',
        'customerRating': 5.0,
        'pickup': 'Centro Comercial Norte',
        'destination': 'Residencial Los Pinos',
        'distance': 8.3,
        'duration': 22,
        'earnings': 18300,
      },
      {
        'status': 'cancelado',
        'date': 'Ayer, 3:45 PM',
        'fullDate': '23 Oct 2025, 3:45 PM',
        'customerName': 'Carlos Rodríguez',
        'customerRating': 4.5,
        'pickup': 'Terminal de Buses',
        'destination': 'Aeropuerto Internacional',
        'distance': 15.0,
        'duration': 35,
        'earnings': 0,
      },
      {
        'status': 'completado',
        'date': 'Ayer, 11:20 AM',
        'fullDate': '23 Oct 2025, 11:20 AM',
        'customerName': 'Ana López',
        'customerRating': 4.9,
        'pickup': 'Hospital Central',
        'destination': 'Universidad Nacional',
        'distance': 6.7,
        'duration': 18,
        'earnings': 14200,
      },
    ];

    if (_filterStatus == 'todos') {
      return allTrips;
    } else if (_filterStatus == 'completados') {
      return allTrips.where((t) => t['status'] == 'completado').toList();
    } else {
      return allTrips.where((t) => t['status'] == 'cancelado').toList();
    }
  }
}
