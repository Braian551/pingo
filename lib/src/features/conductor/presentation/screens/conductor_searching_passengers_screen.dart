import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../../global/services/mapbox_service.dart';
import '../../../../global/services/sound_service.dart';
import '../../../../theme/app_colors.dart';
import '../../services/trip_request_search_service.dart';
import '../../services/conductor_service.dart';
import 'conductor_active_trip_screen.dart';

/// Pantalla para mostrar y gestionar solicitudes de viaje
/// 
/// Recibe una lista de solicitudes disponibles y permite al conductor
/// aceptar o rechazar cada una secuencialmente
class ConductorSearchingPassengersScreen extends StatefulWidget {
  final int conductorId;
  final String conductorNombre;
  final String tipoVehiculo;
  final List<Map<String, dynamic>> solicitudes; // Lista de solicitudes disponibles

  const ConductorSearchingPassengersScreen({
    super.key,
    required this.conductorId,
    required this.conductorNombre,
    required this.tipoVehiculo,
    required this.solicitudes,
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
  
  Map<String, dynamic>? _selectedRequest;
  List<Map<String, dynamic>> _pendingRequests = []; // Cola de solicitudes pendientes
  int _currentRequestIndex = 0; // Índice de la solicitud actual
  
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  
  late AnimationController _requestPanelController;
  late Animation<Offset> _requestPanelSlideAnimation;
  late Animation<double> _requestPanelFadeAnimation;
  
  late AnimationController _acceptButtonController;
  late Animation<double> _acceptButtonScaleAnimation;
  
  late AnimationController _timerController;
  late Animation<double> _timerAnimation;
  
  Timer? _autoRejectTimer;
  bool _panelExpanded = false;
  double _dragStartPosition = 0;
  double _currentDragOffset = 0;
  bool _requestProcessed = false; // Flag para evitar procesar la misma solicitud dos veces
  int? _processedRequestId; // ID de la solicitud ya procesada

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startLocationTracking();
    
    // Inicializar cola de solicitudes
    _pendingRequests = List.from(widget.solicitudes);
    _currentRequestIndex = 0;
    
    // Si hay solicitudes disponibles, mostrar la primera
    if (_pendingRequests.isNotEmpty) {
      final currentRequest = _pendingRequests[_currentRequestIndex];
      final requestId = currentRequest['id'] as int?;
      
      // Verificar si esta solicitud ya fue procesada
      if (_processedRequestId != null && _processedRequestId == requestId) {
        print('⚠️ Solicitud ya procesada anteriormente, pasando a la siguiente...');
        _showNextRequest();
        return;
      }
      
      _selectedRequest = currentRequest;
      
      // Mostrar panel de solicitud después de que se construya el widget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _requestPanelController.forward();
          
          // Iniciar temporizador de auto-rechazo
          _timerController.reset();
          _timerController.forward();
          
          _autoRejectTimer = Timer(const Duration(seconds: 30), () {
            if (mounted && _selectedRequest != null && !_requestProcessed) {
              print('⏰ Auto-rechazando solicitud por timeout');
              _rejectRequest();
            }
          });
        }
      });
    } else {
      // Si no hay solicitudes, volver al home inmediatamente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pulseAnimationController.dispose();
    _requestPanelController.dispose();
    _acceptButtonController.dispose();
    _timerController.dispose();
    _autoRejectTimer?.cancel();
    
    // Desactivar disponibilidad al salir sin aceptar viaje
    _setDriverUnavailable();
    
    super.dispose();
  }
  
  Future<void> _setDriverUnavailable() async {
    try {
      await ConductorService.actualizarDisponibilidad(
        conductorId: widget.conductorId,
        disponible: false,
      );
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
        if (mounted) {
          setState(() {
            _currentLocation = const LatLng(4.6097, -74.0817); // Bogotá
          });
        }
        // Mover mapa después de que se haya construido
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(_currentLocation!, 15);
          }
        });
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
        if (mounted) {
          setState(() {
            _currentLocation = const LatLng(4.6097, -74.0817);
          });
        }
        // Mover mapa después de que se haya construido
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(_currentLocation!, 15);
          }
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        print('❌ Permisos denegados');
        _showError('Se necesitan permisos de ubicación');
        // Usar ubicación por defecto
        if (mounted) {
          setState(() {
            _currentLocation = const LatLng(4.6097, -74.0817);
          });
        }
        // Mover mapa después de que se haya construido
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(_currentLocation!, 15);
          }
        });
        return;
      }

      print('✅ Obteniendo ubicación actual...');
      // Obtener ubicación actual con timeout más largo para emuladores
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30), // Timeout más largo
      );

      print('✅ Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }

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
          // No usar timeLimit en streams para evitar timeouts constantes
        ),
      ).listen(
        (Position position) {
          if (!mounted) return;
          
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
      if (mounted) {
        setState(() {
          _currentLocation = const LatLng(4.6097, -74.0817); // Bogotá
        });
      }
      // Mover mapa después de que se haya construido
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(_currentLocation!, 15);
        }
      });
    }
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
    if (_selectedRequest == null || _requestProcessed) return;

    // Marcar como procesada para evitar doble procesamiento
    _requestProcessed = true;
    _processedRequestId = _selectedRequest!['id'];
    
    // Guardar referencia a la solicitud antes de limpiarla
    final solicitudData = _selectedRequest!;
    
    // Limpiar la solicitud inmediatamente para evitar re-procesamiento
    setState(() {
      _selectedRequest = null;
    });

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final result = await TripRequestSearchService.acceptRequest(
      solicitudId: solicitudData['id'],
      conductorId: widget.conductorId,
    );

    if (!mounted) return;
    Navigator.pop(context); // Cerrar loading

    if (result['success'] == true) {
      // Mostrar éxito y navegar a pantalla de viaje activo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Viaje aceptado! Dirígete al punto de recogida'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navegar a la pantalla de navegación activa (ruta)
      final origenLat = double.tryParse(solicitudData['latitud_origen']?.toString() ?? '0') ?? 0;
      final origenLng = double.tryParse(solicitudData['longitud_origen']?.toString() ?? '0') ?? 0;
      final destinoLat = double.tryParse(solicitudData['latitud_destino']?.toString() ?? '0') ?? 0;
      final destinoLng = double.tryParse(solicitudData['longitud_destino']?.toString() ?? '0') ?? 0;

      // Algunos backends devuelven viaje_id al aceptar
      final viajeId = int.tryParse(result['viaje_id']?.toString() ?? '0');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConductorActiveTripScreen(
            conductorId: widget.conductorId,
            solicitudId: solicitudData['id'] as int,
            viajeId: (viajeId != null && viajeId > 0) ? viajeId : null,
            origenLat: origenLat,
            origenLng: origenLng,
            destinoLat: destinoLat,
            destinoLng: destinoLng,
            direccionOrigen: solicitudData['direccion_origen'] ?? '',
            direccionDestino: solicitudData['direccion_destino'] ?? '',
            clienteNombre: solicitudData['cliente_nombre']?.toString(),
          ),
        ),
      );
    } else {
      // Error al aceptar - volver al home
      _showError(result['message'] ?? 'Error al aceptar solicitud');
      if (mounted) {
        Navigator.pop(context); // Volver al home
      }
    }
  }

  Future<void> _rejectRequest() async {
    if (_selectedRequest == null || _requestProcessed) return;

    // Marcar como procesada para evitar doble procesamiento
    _requestProcessed = true;
    _processedRequestId = _selectedRequest!['id'];
    
    // Guardar referencia a la solicitud antes de limpiarla
    final solicitudData = _selectedRequest!;
    
    // Limpiar la solicitud inmediatamente
    setState(() {
      _selectedRequest = null;
    });

    // Detener temporizador
    _autoRejectTimer?.cancel();
    _timerController.stop();
    
    // Detener cualquier sonido que se esté reproduciendo
    SoundService.stopSound();

    final result = await TripRequestSearchService.rejectRequest(
      solicitudId: solicitudData['id'],
      conductorId: widget.conductorId,
      motivo: 'Conductor rechazó',
    );

    if (!mounted) return;

    if (result['success'] == true) {
      // Solicitud rechazada exitosamente - mostrar siguiente solicitud
      print('❌ Solicitud rechazada, mostrando siguiente...');
      _showNextRequest();
    } else {
      // Error al rechazar - mostrar error y mostrar siguiente solicitud
      _showError(result['message'] ?? 'Error al rechazar solicitud');
      _showNextRequest();
    }
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'es_CO');
    return formatter.format(price.round());
  }

  /// Muestra la siguiente solicitud en la cola
  void _showNextRequest() {
    _currentRequestIndex++;
    
    // Resetear flags de procesamiento
    _requestProcessed = false;
    _processedRequestId = null;
    
    // Si hay más solicitudes, mostrar la siguiente
    if (_currentRequestIndex < _pendingRequests.length) {
      final nextRequest = _pendingRequests[_currentRequestIndex];
      final requestId = nextRequest['id'] as int?;
      
      // Verificar si esta solicitud ya fue procesada
      if (_processedRequestId != null && _processedRequestId == requestId) {
        print('⚠️ Solicitud ya procesada, saltando...');
        _showNextRequest(); // Recursivo para saltar solicitudes procesadas
        return;
      }
      
      setState(() {
        _selectedRequest = nextRequest;
      });
      
      // Reiniciar animaciones y temporizador
      _requestPanelController.reset();
      _requestPanelController.forward();
      
      _timerController.reset();
      _timerController.forward();
      
      // Reiniciar temporizador de auto-rechazo
      _autoRejectTimer?.cancel();
      _autoRejectTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && _selectedRequest != null && !_requestProcessed) {
          print('⏰ Auto-rechazando solicitud por timeout');
          _rejectRequest();
        }
      });
      
      print('🎯 Mostrando siguiente solicitud (${_currentRequestIndex + 1}/${_pendingRequests.length})');
    } else {
      // No hay más solicitudes, volver al home
      print('🏠 No hay más solicitudes, regresando al home');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Mapa
          _buildMap(),
          
          // Panel inferior con solicitud (si hay)
          if (_selectedRequest != null) _buildRequestPanel(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: _rejectRequest,
              child: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Buscando pasajeros',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMap() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
          urlTemplate: MapboxService.getTileUrl(isDarkMode: isDark),
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
                          color: AppColors.primary.withValues(alpha:
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
                          color: AppColors.primary.withValues(alpha:
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
                              color: Colors.black.withValues(alpha: 0.4),
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
                          color: AppColors.darkCard,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
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
                          Icons.directions_car,
                          color: AppColors.primary,
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
        
        // Marcador de solicitud actual (si hay)
        if (_selectedRequest != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  double.parse(_selectedRequest!['latitud_origen'].toString()),
                  double.parse(_selectedRequest!['longitud_origen'].toString()),
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulso de fondo
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 60 * _pulseAnimation.value,
                            height: 60 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha:
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
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_pin_circle_rounded,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                          // Sombra en el suelo
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 25,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRequestPanel() {
    if (_selectedRequest == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final distanciaKm = double.tryParse(
      _selectedRequest!['distancia_km']?.toString() ?? '0',
    ) ?? 0;
    
    final precioEstimado = double.tryParse(
      _selectedRequest!['precio_estimado']?.toString() ?? '0',
    ) ?? 0;
    
    final duracionMinutos = int.tryParse(
      _selectedRequest!['duracion_minutos']?.toString() ?? '0',
    ) ?? 0;

    // Calcular distancia del conductor al punto de recogida del cliente
    double distanciaConductorCliente = 0;
    if (_currentLocation != null) {
      final clienteLat = double.parse(_selectedRequest!['latitud_origen'].toString());
      final clienteLng = double.parse(_selectedRequest!['longitud_origen'].toString());
      
      const Distance distance = Distance();
      distanciaConductorCliente = distance.as(
        LengthUnit.Kilometer,
        LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        LatLng(clienteLat, clienteLng),
      );
    }

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
              child: GestureDetector(
                onVerticalDragStart: (details) {
                  if (!mounted) return;
                  
                  setState(() {
                    _dragStartPosition = details.localPosition.dy;
                  });
                },
                onVerticalDragUpdate: (details) {
                  if (!mounted) return;
                  
                  setState(() {
                    _currentDragOffset = details.localPosition.dy - _dragStartPosition;
                  });
                },
                onVerticalDragEnd: (details) {
                  if (!mounted) return;
                  
                  // Si el usuario arrastra hacia arriba (velocidad negativa) o el offset es significativo
                  if (details.primaryVelocity != null) {
                    final v = details.primaryVelocity!;
                    if (v < -300 || _currentDragOffset < -50) {
                      // Expandir
                      setState(() {
                        _panelExpanded = true;
                        _currentDragOffset = 0;
                      });
                    } else if (v > 300 || _currentDragOffset > 50) {
                      // Contraer
                      setState(() {
                        _panelExpanded = false;
                        _currentDragOffset = 0;
                      });
                    } else {
                      // Reset si no hay suficiente movimiento
                      setState(() {
                        _currentDragOffset = 0;
                      });
                    }
                  } else {
                    setState(() {
                      _currentDragOffset = 0;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: isDark 
                      ? AppColors.darkCard.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                child: SafeArea(
                  top: false, // No aplicar SafeArea arriba para evitar espacio extra
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
                            margin: const EdgeInsets.only(top: 8, bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        
                        // Contenido contraído (SIEMPRE VISIBLE)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: 1.0,
                          child: Column(
                            children: [
                              // Precio destacado estilo compacto
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.2),
                                      AppColors.primary.withValues(alpha: 0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Precio
                                    Row(
                                      children: [
                                        Text(
                                          '\$',
                                          style: TextStyle(
                                            color: AppColors.primary.withValues(alpha: 0.8),
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _formatPrice(precioEstimado),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'COP',
                                          style: TextStyle(
                                            color: AppColors.primary.withValues(alpha: 0.7),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Info rápida: distancia y tiempo
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.straighten,
                                              color: AppColors.primary,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${distanciaKm.toStringAsFixed(1)} km',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              color: AppColors.primary,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$duracionMinutos min',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Botones de acción (siempre visibles)
                              Row(
                                children: [
                                  // Botón de rechazar compacto
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
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
                                              color: AppColors.primary.withValues(alpha: 0.4),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _acceptRequest,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
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
                            ],
                          ),
                        ),
                        
                        // Contenido expandido (SOLO CUANDO _panelExpanded = true)
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: _panelExpanded 
                              ? CrossFadeState.showSecond 
                              : CrossFadeState.showFirst,
                          firstChild: const SizedBox.shrink(),
                          secondChild: Column(
                            children: [
                              const SizedBox(height: 16),
                              
                              // Ubicaciones: Conductor y Cliente
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A).withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Tu ubicación (conductor)
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.navigation_rounded,
                                              color: AppColors.primary,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Tu ubicación',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.6),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Conductor',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.9),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Separador con distancia
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.arrow_forward,
                                                  color: Color(0xFF4CAF50),
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${distanciaConductorCliente.toStringAsFixed(1)} km',
                                                  style: const TextStyle(
                                                    color: Color(0xFF4CAF50),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Ubicación del cliente
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.person_pin_circle,
                                              color: Color(0xFF2196F3),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Cliente',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.6),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Recoger aquí',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.9),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
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
                                          ? Colors.red.withValues(alpha: 0.15)
                                          : const Color(0xFF2A2A2A).withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: secondsLeft <= 10
                                            ? Colors.red.withValues(alpha: 0.3)
                                            : Colors.white.withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          color: secondsLeft <= 10
                                              ? Colors.red
                                              : AppColors.primary,
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
                                                      : Colors.white.withValues(alpha: 0.7),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: LinearProgressIndicator(
                                                  value: _timerAnimation.value,
                                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    secondsLeft <= 10
                                                        ? Colors.red
                                                        : AppColors.primary,
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
                                                : AppColors.primary.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${secondsLeft}s',
                                            style: TextStyle(
                                              color: secondsLeft <= 10
                                                  ? Colors.white
                                                  : AppColors.primary,
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
                              const SizedBox(height: 16),
                              
                              // Direcciones
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A).withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
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
                                                  color: Colors.white.withValues(alpha: 0.3),
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
                                      iconColor: AppColors.primary,
                                      label: 'Dejar en',
                                      value: _selectedRequest!['direccion_destino'] ?? 'Sin dirección',
                                    ),
                                  ],
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
            color: iconColor.withValues(alpha: 0.15),
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
                  color: Colors.white.withValues(alpha: 0.5),
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
