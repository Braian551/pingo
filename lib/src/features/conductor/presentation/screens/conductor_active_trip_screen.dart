import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../global/services/mapbox_service.dart';

class ConductorActiveTripScreen extends StatefulWidget {
  final int conductorId;
  final int? solicitudId;
  final int? viajeId;
  final double origenLat;
  final double origenLng;
  final double destinoLat;
  final double destinoLng;
  final String direccionOrigen;
  final String direccionDestino;
  final String? clienteNombre;

  const ConductorActiveTripScreen({
    super.key,
    required this.conductorId,
    this.solicitudId,
    this.viajeId,
    required this.origenLat,
    required this.origenLng,
    required this.destinoLat,
    required this.destinoLng,
    required this.direccionOrigen,
    required this.direccionDestino,
    this.clienteNombre,
  });

  @override
  State<ConductorActiveTripScreen> createState() => _ConductorActiveTripScreenState();
}

class _ConductorActiveTripScreenState extends State<ConductorActiveTripScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  LatLng? _driverLocation;
  late final LatLng _pickup;
  late final LatLng _dropoff;

  List<LatLng> _routePoints = [];
  bool _toPickup = true; // etapa actual: conductor->origen o origen->destino
  bool _loadingRoute = false;
  String? _error;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pickup = LatLng(widget.origenLat, widget.origenLng);
    _dropoff = LatLng(widget.destinoLat, widget.destinoLng);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _driverLocation = const LatLng(4.6097, -74.0817);
        });
        await _loadRoute();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _driverLocation = const LatLng(4.6097, -74.0817);
        });
        await _loadRoute();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
      setState(() {
        _driverLocation = LatLng(pos.latitude, pos.longitude);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_driverLocation != null) {
          _mapController.move(_driverLocation!, 15);
        }
      });
      await _loadRoute();

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        setState(() {
          _driverLocation = LatLng(pos.latitude, pos.longitude);
        });
      });
    } catch (e) {
      setState(() {
        _driverLocation = const LatLng(4.6097, -74.0817);
        _error = 'No se pudo obtener tu ubicaciÃ³n. Usando ubicaciÃ³n de prueba.';
      });
      await _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    if (_driverLocation == null) return;
    setState(() {
      _loadingRoute = true;
      _error = null;
    });

    final waypoints = _toPickup
        ? <LatLng>[_driverLocation!, _pickup]
        : <LatLng>[_pickup, _dropoff];

    final route = await MapboxService.getRoute(waypoints: waypoints);
    if (!mounted) return;
    if (route == null) {
      setState(() {
        _loadingRoute = false;
        _error = 'No se pudo calcular la ruta';
      });
      return;
    }

    setState(() {
      _routePoints = route.geometry;
      _loadingRoute = false;
    });

    // Ajustar cÃ¡mara a la ruta con padding
    if (_routePoints.length > 1) {
      double minLat = double.infinity, maxLat = -double.infinity;
      double minLng = double.infinity, maxLng = -double.infinity;
      for (final p in _routePoints) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
      _mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(top: 120, bottom: 220, left: 60, right: 60),
      ));
    }
  }

  void _onArrivedPickup() async {
    if (!_toPickup) return;
    setState(() => _toPickup = false);
    await _loadRoute();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ruta actualizada hacia el destino'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () => Navigator.pop(context, true),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
        title: Text(
          _toPickup ? 'Ir a recoger' : 'Ir al destino',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          _buildMap(),
          _buildBottomPanel(),
          if (_loadingRoute)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            ),
          if (_error != null)
            Positioned(
              top: kToolbarHeight + 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final center = _driverLocation ?? _pickup;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: MapboxService.getTileUrl(style: 'dark-v11'),
          userAgentPackageName: 'com.example.ping_go',
        ),

        if (_routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 8,
                color: const Color(0xFFFFD700),
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            // Driver marker with pulse
            if (_driverLocation != null)
              Marker(
                point: _driverLocation!,
                width: 80,
                height: 80,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50 * _pulseAnim.value,
                          height: 50 * _pulseAnim.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFD700).withOpacity(0.2 / _pulseAnim.value),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFD700), width: 3),
                          ),
                        ),
                        const Icon(Icons.navigation_rounded, color: Color(0xFFFFD700), size: 22),
                      ],
                    );
                  },
                ),
              ),

            // Pickup marker
            Marker(
              point: _pickup,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: const Icon(Icons.person_pin_circle_rounded, color: Colors.black),
              ),
            ),

            // Destination marker
            Marker(
              point: _dropoff,
              width: 46,
              height: 46,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _toPickup ? Icons.person_pin_circle : Icons.location_on,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _toPickup ? 'Recoger en' : 'Destino',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _toPickup ? widget.direccionOrigen : widget.direccionDestino,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _toPickup ? _onArrivedPickup : () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _toPickup ? 'He llegado al origen' : 'Finalizar navegaciÃ³n',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
