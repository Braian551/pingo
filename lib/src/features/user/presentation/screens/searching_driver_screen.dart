import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/trip_request_service.dart';
import '../../../../global/services/mapbox_service.dart';
import 'dart:ui';

class SearchingDriverScreen extends StatefulWidget {
  final int solicitudId;
  final double latitudOrigen;
  final double longitudOrigen;
  final String direccionOrigen;
  final double latitudDestino;
  final double longitudDestino;
  final String direccionDestino;
  final String tipoVehiculo;

  const SearchingDriverScreen({
    super.key,
    required this.solicitudId,
    required this.latitudOrigen,
    required this.longitudOrigen,
    required this.direccionOrigen,
    required this.latitudDestino,
    required this.longitudDestino,
    required this.direccionDestino,
    required this.tipoVehiculo,
  });

  @override
  State<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen> with TickerProviderStateMixin {
  Timer? _searchTimer;
  List<Map<String, dynamic>> _nearbyDrivers = [];
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSearching();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  void _startSearching() {
    // Buscar conductores cada 3 segundos
    _searchTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _searchDrivers();
    });
    // Búsqueda inicial
    _searchDrivers();
  }

  Future<void> _searchDrivers() async {
    if (!mounted) return;

    final drivers = await TripRequestService.findNearbyDrivers(
      latitude: widget.latitudOrigen,
      longitude: widget.longitudOrigen,
      vehicleType: widget.tipoVehiculo,
      radiusKm: 5.0,
    );

    if (mounted) {
      setState(() {
        _nearbyDrivers = drivers;
      });

      // Si no hay conductores después de 30 segundos, mostrar mensaje
      if (_nearbyDrivers.isEmpty) {
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted && _nearbyDrivers.isEmpty) {
            _showNoDriversDialog();
          }
        });
      }
    }
  }

  void _showNoDriversDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'No hay conductores disponibles',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Lo sentimos, no hay conductores disponibles en este momento. ¿Deseas seguir esperando?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelTrip();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Seguir esperando',
              style: TextStyle(color: Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelTrip() async {
    final success = await TripRequestService.cancelTripRequest(widget.solicitudId);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viaje cancelado')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Mapa de fondo
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(widget.latitudOrigen, widget.longitudOrigen),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: MapboxService.getTileUrl(style: 'dark-v11'),
                userAgentPackageName: 'com.example.ping_go',
              ),
              // Marcador de origen
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(widget.latitudOrigen, widget.longitudOrigen),
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Overlay con información
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            _showCancelDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Panel de búsqueda
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A).withOpacity(0.95),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animación de búsqueda
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 0.9 + (_pulseController.value * 0.2),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFFD700).withOpacity(0.2),
                                  ),
                                  child: Center(
                                    child: RotationTransition(
                                      turns: _rotationController,
                                      child: const Icon(
                                        Icons.search,
                                        size: 50,
                                        color: Color(0xFFFFD700),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          const Text(
                            'Buscando conductor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          Text(
                            _nearbyDrivers.isEmpty 
                                ? 'Buscando conductores disponibles cerca de ti...'
                                : '${_nearbyDrivers.length} ${_nearbyDrivers.length == 1 ? "conductor encontrado" : "conductores encontrados"}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Información del viaje
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  Icons.radio_button_checked,
                                  'Origen',
                                  widget.direccionOrigen,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.location_on,
                                  'Destino',
                                  widget.direccionDestino,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Botón cancelar
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _showCancelDialog,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.red, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancelar búsqueda',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFFD700), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '¿Cancelar búsqueda?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cancelar la búsqueda de conductor?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelTrip();
            },
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
