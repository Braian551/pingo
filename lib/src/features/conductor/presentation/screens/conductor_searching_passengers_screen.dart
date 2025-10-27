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
  late Animation<double> _requestPanelFadeAnimation;
  
  late AnimationController _acceptButtonController;
  late Animation<double> _acceptButtonScaleAnimation;
  
  late AnimationController _topPanelController;
  late Animation<Offset> _topPanelSlideAnimation;
  late Animation<double> _topPanelFadeAnimation;
  
  late AnimationController _timerController;
  late Animation<double> _timerAnimation;
  
  bool _showingRequest = false;
  Timer? _autoRejectTimer;

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
    _acceptButtonController.dispose();
    _topPanelController.dispose();
    _timerController.dispose();
    _autoRejectTimer?.cancel();
    
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
    // Animación de pulso para el marcador del conductor (más suave)
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    // Animación del panel de solicitud (más fluida)
    _requestPanelController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _requestPanelSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _requestPanelController,
      curve: Curves.easeOutCubic,
    ));
    
    _requestPanelFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _requestPanelController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Animación del botón de aceptar (efecto de pulso)
    _acceptButtonController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _acceptButtonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _acceptButtonController,
      curve: Curves.easeInOut,
    ));

    // Animación del panel superior (entrada)
    _topPanelController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _topPanelSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _topPanelController,
      curve: Curves.easeOutCubic,
    ));
    
    _topPanelFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _topPanelController,
      curve: Curves.easeOut,
    ));

    // Iniciar animación del panel superior
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _topPanelController.forward();
      }
    });

    // Temporizador para auto-rechazar solicitud (30 segundos)
    _timerController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    
    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _timerController,
      curve: Curves.linear,
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

  Future<void> _startSearching() async {
    if (_currentLocation == null) {
      print('⚠️ Ubicación aún no disponible, reintentando en 1 segundo...');
      Future.delayed(const Duration(seconds: 1), _startSearching);
      return;
    }

    print('🔍 Iniciando búsqueda de solicitudes...');
    print('📍 Ubicación: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
    
    // Activar disponibilidad del conductor primero
    try {
      final url = Uri.parse(
        'http://10.0.2.2/pingo/backend/conductor/actualizar_disponibilidad.php',
      );
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conductor_id': widget.conductorId,
          'disponible': 1,
        }),
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        print('✅ Disponibilidad activada');
      } else {
        print('❌ Error activando disponibilidad: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error activando disponibilidad: $e');
    }
    
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
            if (_showingRequest) {
              _selectedRequest = null;
              _requestPanelController.reverse();
              _showingRequest = false;
            }
          } else {
            _searchMessage = '${requests.length} solicitud${requests.length > 1 ? "es" : ""} disponible${requests.length > 1 ? "s" : ""}';
            
            // Mostrar la primera solicitud si no hay una seleccionada
            if (_selectedRequest == null && !_showingRequest) {
              _selectedRequest = requests.first;
              _showingRequest = true;
              _requestPanelController.forward();
              
              // Iniciar temporizador de auto-rechazo
              _timerController.reset();
              _timerController.forward();
              
              _autoRejectTimer?.cancel();
              _autoRejectTimer = Timer(const Duration(seconds: 30), () {
                if (mounted && _selectedRequest != null) {
                  _rejectRequest();
                }
              });
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

    // Detener temporizador
    _autoRejectTimer?.cancel();
    _timerController.stop();

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
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

    // Detener temporizador
    _autoRejectTimer?.cancel();
    _timerController.stop();

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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () {
                // Confirmar antes de salir
                showDialog(
                  context: context,
                  builder: (context) => _buildExitConfirmDialog(),
                );
              },
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExitConfirmDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFFFD700),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                // Título
                const Text(
                  '¿Salir del modo en línea?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Descripción
                Text(
                  'Dejarás de recibir solicitudes de viaje hasta que vuelvas a conectarte',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(context),
                            child: const Center(
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Cerrar diálogo
                            Navigator.pop(context, false); // Salir de la pantalla
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Salir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
        
        // Marcador del conductor con pulso mejorado
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLocation!,
              width: 100,
              height: 100,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulso exterior suave
                      Container(
                        width: 70 * _pulseAnimation.value,
                        height: 70 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFD700).withOpacity(
                            0.2 / _pulseAnimation.value,
                          ),
                        ),
                      ),
                      // Anillo intermedio
                      Container(
                        width: 50 * _pulseAnimation.value,
                        height: 50 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFD700).withOpacity(
                            0.3 / _pulseAnimation.value,
                          ),
                        ),
                      ),
                      // Sombra del marcador
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      // Círculo principal con borde
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD700),
                            width: 3.5,
                          ),
                        ),
                      ),
                      // Ícono del conductor
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Color(0xFFFFD700),
                          size: 26,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        
        // Marcadores de solicitudes pendientes con animación mejorada
        if (_pendingRequests.isNotEmpty)
          MarkerLayer(
            markers: _pendingRequests.map((request) {
              final isSelected = _selectedRequest?['id'] == request['id'];
              return Marker(
                point: LatLng(
                  double.parse(request['latitud_origen'].toString()),
                  double.parse(request['longitud_origen'].toString()),
                ),
                width: 80,
                height: 80,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRequest = request;
                        if (!_showingRequest) {
                          _showingRequest = true;
                          _requestPanelController.forward();
                        }
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulso de fondo si está seleccionado
                        if (isSelected)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 60 * _pulseAnimation.value,
                                height: 60 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFFD700).withOpacity(
                                    0.3 / _pulseAnimation.value,
                                  ),
                                ),
                              );
                            },
                          ),
                        // Pin del pasajero
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFD700)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFFD700)
                                      : Colors.grey.shade300,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? const Color(0xFFFFD700).withOpacity(0.5)
                                        : Colors.black.withOpacity(0.3),
                                    blurRadius: isSelected ? 15 : 8,
                                    spreadRadius: isSelected ? 3 : 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_pin_circle_rounded,
                                color: isSelected ? Colors.black : const Color(0xFF2196F3),
                                size: 32,
                              ),
                            ),
                            // Sombra en el suelo
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 25,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
        child: SlideTransition(
          position: _topPanelSlideAnimation,
          child: FadeTransition(
            opacity: _topPanelFadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icono animado
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.near_me,
                                  color: Color(0xFFFFD700),
                                  size: 28,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        // Texto informativo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🟢 En línea',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: Text(
                                      _searchMessage,
                                      style: TextStyle(
                                        color: const Color(0xFFFFD700).withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Indicador de búsqueda
                        if (_pendingRequests.isEmpty)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFFFFD700).withOpacity(0.8),
                              ),
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
    
    final duracionMinutos = int.tryParse(
      _selectedRequest!['duracion_minutos']?.toString() ?? '0',
    ) ?? 0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _requestPanelSlideAnimation,
        child: FadeTransition(
          opacity: _requestPanelFadeAnimation,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Header con animación
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.black,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🎯 Nueva solicitud',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Desliza hacia arriba para más detalles',
                                      style: TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Tarjeta de ganancia destacada con animación
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  color: Colors.black,
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: precioEstimado),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    return Text(
                                      '\$${value.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -1,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'COP',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Temporizador de auto-rechazo
                        AnimatedBuilder(
                          animation: _timerAnimation,
                          builder: (context, child) {
                            final secondsLeft = (_timerAnimation.value * 30).ceil();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: secondsLeft <= 10
                                    ? Colors.red.withOpacity(0.15)
                                    : const Color(0xFF2A2A2A).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: secondsLeft <= 10
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    color: secondsLeft <= 10
                                        ? Colors.red
                                        : const Color(0xFFFFD700),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          secondsLeft <= 10
                                              ? '⚠️ Solicitud expirando'
                                              : 'Tiempo para responder',
                                          style: TextStyle(
                                            color: secondsLeft <= 10
                                                ? Colors.red
                                                : Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: _timerAnimation.value,
                                            backgroundColor: Colors.white.withOpacity(0.1),
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              secondsLeft <= 10
                                                  ? Colors.red
                                                  : const Color(0xFFFFD700),
                                            ),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: secondsLeft <= 10
                                          ? Colors.red
                                          : const Color(0xFFFFD700).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${secondsLeft}s',
                                      style: TextStyle(
                                        color: secondsLeft <= 10
                                            ? Colors.white
                                            : const Color(0xFFFFD700),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Detalles del viaje con animación escalonada
                        _buildAnimatedDetailRow(
                          delay: 200,
                          icon: Icons.straighten,
                          label: 'Distancia',
                          value: '${distanciaKm.toStringAsFixed(1)} km',
                        ),
                        const SizedBox(height: 12),
                        _buildAnimatedDetailRow(
                          delay: 300,
                          icon: Icons.access_time,
                          label: 'Tiempo estimado',
                          value: '$duracionMinutos min',
                        ),
                        const SizedBox(height: 20),
                        
                        // Direcciones con animación
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildLocationInfo(
                                  icon: Icons.my_location,
                                  iconColor: const Color(0xFF4CAF50),
                                  label: 'Recoger en',
                                  value: _selectedRequest!['direccion_origen'] ?? 'Sin dirección',
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 18),
                                      Column(
                                        children: List.generate(
                                          3,
                                          (index) => Container(
                                            margin: const EdgeInsets.only(bottom: 3),
                                            width: 3,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildLocationInfo(
                                  icon: Icons.location_on,
                                  iconColor: const Color(0xFFFFD700),
                                  label: 'Dejar en',
                                  value: _selectedRequest!['direccion_destino'] ?? 'Sin dirección',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Botones de acción con animaciones
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              // Botón de rechazar compacto
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _rejectRequest,
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Botón de aceptar expandido con animación
                              Expanded(
                                child: AnimatedBuilder(
                                  animation: _acceptButtonScaleAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _acceptButtonScaleAnimation.value,
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFD700).withOpacity(0.4),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _acceptRequest,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFD700),
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        padding: EdgeInsets.zero,
                                        elevation: 0,
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 24,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Aceptar viaje',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedDetailRow({
    required int delay,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(20 * (1 - animValue), 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
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
                color: const Color(0xFFFFD700).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFFD700),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationInfo({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
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
}
