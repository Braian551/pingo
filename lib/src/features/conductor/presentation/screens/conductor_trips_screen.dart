import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/conductor_trips_provider.dart';
import '../../services/conductor_trips_service.dart';
import 'package:intl/intl.dart';

class ConductorTripsScreen extends StatefulWidget {
  final int conductorId;

  const ConductorTripsScreen({
    super.key,
    required this.conductorId,
  });

  @override
  State<ConductorTripsScreen> createState() => _ConductorTripsScreenState();
}

class _ConductorTripsScreenState extends State<ConductorTripsScreen> {
  late ConductorTripsProvider _provider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    print('ConductorTripsScreen: initState called');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      print('ConductorTripsScreen: didChangeDependencies - initializing');
      _isInitialized = true;
      _provider = Provider.of<ConductorTripsProvider>(context, listen: false);
      // Usar Future.microtask para evitar problemas de sincronizaciÃ³n
      Future.microtask(() => _loadTrips());
    }
  }

  Future<void> _loadTrips() async {
    print('ConductorTripsScreen: _loadTrips called for conductor ${widget.conductorId}');
    try {
      await _provider.loadTrips(widget.conductorId);
      print('ConductorTripsScreen: loadTrips completed');
    } catch (e, stackTrace) {
      print('ConductorTripsScreen: Error loading trips: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar viajes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    print('ConductorTripsScreen: dispose called');
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
              child: Consumer<ConductorTripsProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.trips.isEmpty) {
                    return _buildShimmerLoading();
                  }

                  if (provider.errorMessage != null && provider.trips.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadTrips,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFFF00),
                            ),
                            child: const Text(
                              'Reintentar',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadTrips,
                    color: const Color(0xFFFFFF00),
                    backgroundColor: const Color(0xFF1A1A1A),
                    child: _buildTripsList(provider.trips),
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
    return Consumer<ConductorTripsProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', 'todos', Icons.list_rounded, provider),
                const SizedBox(width: 12),
                _buildFilterChip('Completados', 'completados', Icons.check_circle_rounded, provider),
                const SizedBox(width: 12),
                _buildFilterChip('Cancelados', 'cancelados', Icons.cancel_rounded, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, ConductorTripsProvider provider) {
    final isSelected = provider.filterStatus == value;
    return GestureDetector(
      onTap: () => provider.setFilter(value),
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

  Widget _buildTripsList(List<TripModel> trips) {
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
              'No hay viajes en esta categorÃ­a',
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

  Widget _buildTripCard(TripModel trip) {
    final status = trip.estado;
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'completada':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelada':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_rounded;
    }

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a', 'es');
    final dateStr = trip.fechaCompletado != null
        ? dateFormat.format(trip.fechaCompletado!)
        : dateFormat.format(trip.fechaSolicitud);

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
                            dateStr,
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
                                  trip.clienteNombreCompleto,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (trip.calificacion != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFFFFF00),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        trip.calificacionDouble.toStringAsFixed(1),
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
                        trip.origen ?? 'Punto de recogida',
                        true,
                      ),
                      _buildRouteLine(),
                      _buildRouteInfo(
                        Icons.flag_rounded,
                        trip.destino ?? 'Destino',
                        false,
                      ),
                      const SizedBox(height: 16),
                      // Stats
                      Row(
                        children: [
                          if (trip.distanciaKm != null)
                            _buildStatBadge(
                              Icons.route_rounded,
                              '${trip.distanciaKm!.toStringAsFixed(1)} km',
                            ),
                          const SizedBox(width: 12),
                          if (trip.duracionEstimada != null)
                            _buildStatBadge(
                              Icons.access_time_rounded,
                              '${trip.duracionEstimada} min',
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
                        '+\$${(trip.precioFinal ?? trip.precioEstimado ?? 0).toStringAsFixed(0)}',
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

  void _showTripDetails(TripModel trip) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a', 'es');
    final fullDate = trip.fechaCompletado != null
        ? dateFormat.format(trip.fechaCompletado!)
        : dateFormat.format(trip.fechaSolicitud);

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
                        trip.clienteNombreCompleto,
                        Icons.person_rounded,
                      ),
                      _buildDetailItem(
                        'Fecha',
                        fullDate,
                        Icons.calendar_today_rounded,
                      ),
                      if (trip.distanciaKm != null)
                        _buildDetailItem(
                          'Distancia',
                          '${trip.distanciaKm!.toStringAsFixed(1)} km',
                          Icons.route_rounded,
                        ),
                      if (trip.duracionEstimada != null)
                        _buildDetailItem(
                          'DuraciÃ³n',
                          '${trip.duracionEstimada} minutos',
                          Icons.access_time_rounded,
                        ),
                      _buildDetailItem(
                        'Ganancia',
                        '\$${(trip.precioFinal ?? trip.precioEstimado ?? 0).toStringAsFixed(0)}',
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

  Widget _buildShimmerLoading() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip cards shimmer
            ...List.generate(5, (index) => Column(
              children: [
                _buildShimmerBox(height: 300, width: double.infinity),
                if (index < 4) const SizedBox(height: 16),
              ],
            )),
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
}
