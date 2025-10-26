import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../../global/services/mapbox_service.dart';
import '../../services/trip_request_search_service.dart';

/// Pantalla de búsqueda de pasajeros (lógica Uber/DiDi)
/// 
/// Muestra el mapa con la ubicación del conductor y busca solicitudes cercanas
/// Cuando encuentra solicitudes, muestra un panel para aceptar o rechazar
class ConductorSearchingPassengersScreen extends StatefulWidget {
  final int conductorId;
  final String conductorNombre;
  final String tipoVehiculo;

  const ConductorSearchingPassengersScreen({
    super.key,
    required this.conductorId,
    required this.conductorNombre,
    required this.tipoVehiculo,
  });

  @override
  State<ConductorSearchingPassengersScreen> createState() =>
      _ConductorSearchingPassengersScreenState();
}

class _ConductorSearchingPassengersScreenState
    extends State<ConductorSearchingPassengersScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  
  List<Map<String, dynamic>> _pendingRequests = [];
  Map<String, dynamic>? _selectedRequest;
  
  String _searchMessage = 'Buscando solicitudes cercanas...';
  
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  
  late AnimationController _requestPanelController;
  late Animation<Offset> _requestPanelSlideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startLocationTracking();
    _startSearching();
  }

  @override
  void dispose() {
    _stopSearching();
    _positionStream?.cancel();
    _pulseAnimationController.dispose();
    _requestPanelController.dispose();
    
    // Desactivar disponibilidad al salir sin aceptar viaje
    _setDriverUnavailable();
    
    super.dispose();
  }
  
  Future<void> _setDriverUnavailable() async {
    try {
      final url = Uri.parse(
        'http://10.0.2.2/pingo/backend/conductor/actualizar_disponibilidad.php',
      );
      
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conductor_id': widget.conductorId,
          'disponible': 0,
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      print('Error desactivando disponibilidad: $e');
    }
  }

  void _setupAnimations() {
    // Animación de pulso para el marcador del conductor
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    // Animación del panel de solicitud
    _requestPanelController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _requestPanelSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _requestPanelController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _startLocationTracking() async {
    try {
      print('📍 Iniciando tracking de ubicación...');
      
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Servicio de ubicación deshabilitado');
        _showError('Por favor activa el GPS en tu dispositivo');
        // Usar ubicación por defecto para pruebas
        setState(() {
          _currentLocation = const LatLng(4.6097, -74.0817); // Bogotá
        });
        // Mover mapa después de que se haya construido
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(_currentLocation!, 15);
          }
        });
        _startSearching();
        return;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Permiso actual: $permission');
      
      if (permission == LocationPermission.denied) {
        print('📍 Solicitando permisos...');
        permission = await Geolocator.requestPermission();
        print('📍 Permiso otorgado: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permisos denegados permanentemente');
        _showError('Permisos de ubicación denegados. Habilítalos en configuración.');
        // Usar ubicación por defecto
        setState(() {
          _currentLocation = const LatLng(4.6097, -74.0817);
        });
        // Mover mapa después de que se haya construido
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(_currentLocation!, 15);
          }
        });
        _startSearching();
        return;
      }

      if (permission == LocationPermission.denied) {
        print('❌ Permisos denegados');
        _showError('Se necesitan permisos de ubicación');
        // Usar ubicación por defecto
        setState(() {
          _currentLocation = const LatLng(4.6097, -74.0817);
        });
        // Mover mapa después de que se haya construido
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(_currentLocation!, 15);
          }
        });
        _startSearching();
        return;
      }

      print('✅ Obteniendo ubicación actual...');
      // Obtener ubicación actual con timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Centrar mapa en ubicación actual después de que se haya construido
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(_currentLocation!, 15);
        }
      });

      // Escuchar cambios de ubicación
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Actualizar cada 10 metros
          timeLimit: Duration(seconds: 10),
        ),
      ).listen(
        (Position position) {
          print('📍 Ubicación actualizada: ${position.latitude}, ${position.longitude}');
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });

          // Actualizar ubicación en el servidor
          TripRequestSearchService.updateLocation(
            conductorId: widget.conductorId,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        },
        onError: (error) {
          print('❌ Error en stream de ubicación: $error');
        },
      );
    } catch (e) {
      print('❌ Error crítico obteniendo ubicación: $e');
      _showError('Error obteniendo ubicación. Usando ubicación de prueba.');
      // Usar ubicación por defecto para que la app siga funcionando
      setState(() {
        _currentLocation = const LatLng(4.6097, -74.0817); // Bogotá
      });
      // Mover mapa después de que se haya construido
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(_currentLocation!, 15);
        }
      });
      _startSearching();
    }
  }

  void _startSearching() {
    if (_currentLocation == null) {
      print('⚠️ Ubicación aún no disponible, reintentando en 1 segundo...');
      Future.delayed(const Duration(seconds: 1), _startSearching);
      return;
    }

    print('🔍 Iniciando búsqueda de solicitudes...');
    print('📍 Ubicación: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
    
    TripRequestSearchService.startSearching(
      conductorId: widget.conductorId,
      currentLat: _currentLocation!.latitude,
      currentLng: _currentLocation!.longitude,
      onRequestsFound: (requests) {
        if (!mounted) return;
        
        print('✅ Solicitudes encontradas: ${requests.length}');
        
        setState(() {
          _pendingRequests = requests;
          
          if (requests.isEmpty) {
            _searchMessage = 'Buscando solicitudes cercanas...';
            _selectedRequest = null;
            _requestPanelController.reverse();
          } else {
            _searchMessage = '${requests.length} solicitud${requests.length > 1 ? "es" : ""} disponible${requests.length > 1 ? "s" : ""}';
            
            // Mostrar la primera solicitud si no hay una seleccionada
            if (_selectedRequest == null) {
              _selectedRequest = requests.first;
              _requestPanelController.forward();
            }
          }
        });
      },
      onError: (error) {
        if (!mounted) return;
        print('❌ Error en búsqueda: $error');
        _showError(error);
      },
    );
  }

  void _stopSearching() {
    TripRequestSearchService.stopSearching();
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _acceptRequest() async {
    if (_selectedRequest == null) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFFF00)),
      ),
    );

    final result = await TripRequestSearchService.acceptRequest(
      solicitudId: _selectedRequest!['id'],
      conductorId: widget.conductorId,
    );

    if (!mounted) return;
    Navigator.pop(context); // Cerrar loading

    if (result['success'] == true) {
      // Detener búsqueda
      _stopSearching();
      
      // Mostrar éxito y navegar a pantalla de viaje activo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Viaje aceptado! Dirígete al punto de recogida'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // TODO: Navegar a pantalla de viaje activo
      // Por ahora, volver atrás
      Navigator.pop(context, true);
    } else {
      _showError(result['message'] ?? 'Error al aceptar solicitud');
    }
  }

  Future<void> _rejectRequest() async {
    if (_selectedRequest == null) return;

    final result = await TripRequestSearchService.rejectRequest(
      solicitudId: _selectedRequest!['id'],
      conductorId: widget.conductorId,
      motivo: 'Conductor rechazó',
    );

    if (!mounted) return;

    if (result['success'] == true) {
      // Remover de la lista
      setState(() {
        _pendingRequests.removeWhere((r) => r['id'] == _selectedRequest!['id']);
        
        if (_pendingRequests.isEmpty) {
          _selectedRequest = null;
          _requestPanelController.reverse();
          _searchMessage = 'Buscando solicitudes cercanas...';
        } else {
          _selectedRequest = _pendingRequests.first;
        }
      });
    } else {
      _showError(result['message'] ?? 'Error al rechazar solicitud');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Mapa
          _buildMap(),
          
          // Panel superior con estado
          _buildTopPanel(),
          
          // Panel inferior con solicitud (si hay)
          if (_selectedRequest != null) _buildRequestPanel(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () {
          // Confirmar antes de salir
          showDialog(
            context: context,
            builder: (context) => _buildExitConfirmDialog(),
          );
        },
      ),
    );
  }

  Widget _buildExitConfirmDialog() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A).withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFFFFFF00).withOpacity(0.3),
              width: 1,
            ),
          ),
          title: const Text(
            '¿Dejar de buscar?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Si sales, dejarás de recibir solicitudes de viaje',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context, false); // Salir de la pantalla
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFF00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Salir'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_currentLocation == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFFF00)),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation!,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        // Tiles oscuros
        TileLayer(
          urlTemplate: MapboxService.getTileUrl(style: 'dark-v11'),
          userAgentPackageName: 'com.example.ping_go',
        ),
        
        // Marcador del conductor con pulso
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLocation!,
              width: 80,
              height: 80,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulso exterior
                      Container(
                        width: 60 * _pulseAnimation.value,
                        height: 60 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFFF00).withOpacity(
                            0.3 / _pulseAnimation.value,
                          ),
                        ),
                      ),
                      // Círculo principal
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFFF00),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFFF00).withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Color(0xFFFFFF00),
                          size: 20,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        
        // Marcadores de solicitudes pendientes
        if (_pendingRequests.isNotEmpty)
          MarkerLayer(
            markers: _pendingRequests.map((request) {
              final isSelected = _selectedRequest?['id'] == request['id'];
              return Marker(
                point: LatLng(
                  double.parse(request['latitud_origen'].toString()),
                  double.parse(request['longitud_origen'].toString()),
                ),
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRequest = request;
                      _requestPanelController.forward();
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFFF00)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFFF00)
                                : Colors.grey,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_pin_circle,
                          color: isSelected ? Colors.black : Colors.blue,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTopPanel() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFFF00).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFF00).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Color(0xFFFFFF00),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estás disponible',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _searchMessage,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
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
        ),
      ),
    );
  }

  Widget _buildRequestPanel() {
    if (_selectedRequest == null) return const SizedBox.shrink();

    final distanciaKm = double.tryParse(
      _selectedRequest!['distancia_km']?.toString() ?? '0',
    ) ?? 0;
    
    final precioEstimado = double.tryParse(
      _selectedRequest!['precio_estimado']?.toString() ?? '0',
    ) ?? 0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _requestPanelSlideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Título
                  const Text(
                    'Nueva solicitud de viaje',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Información del viaje
                  _buildTripInfo(
                    icon: Icons.circle,
                    iconColor: const Color(0xFFFFFF00),
                    label: 'Origen',
                    value: _selectedRequest!['direccion_origen'] ?? 'Sin dirección',
                  ),
                  const SizedBox(height: 12),
                  _buildTripInfo(
                    icon: Icons.location_on,
                    iconColor: const Color(0xFFFFFF00),
                    label: 'Destino',
                    value: _selectedRequest!['direccion_destino'] ?? 'Sin dirección',
                  ),
                  const SizedBox(height: 20),
                  
                  // Detalles del viaje
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem(
                          icon: Icons.straighten,
                          label: 'Distancia',
                          value: '${distanciaKm.toStringAsFixed(1)} km',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        _buildDetailItem(
                          icon: Icons.attach_money,
                          label: 'Ganancia',
                          value: '\$${precioEstimado.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _rejectRequest,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Rechazar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _acceptRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFF00),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Aceptar viaje',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripInfo({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFFF00), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
