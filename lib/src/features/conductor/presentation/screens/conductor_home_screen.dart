import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../providers/conductor_provider.dart';

/// Estados del mapa para manejo robusto de fallos
enum MapState {
  loading,
  mapboxReady,
  mapboxFailed,
  staticMap,
  disabled,
}

/// Pantalla principal del conductor - Diseño profesional y minimalista
/// Inspirado en Uber/Didi pero con identidad propia
class ConductorHomeScreen extends StatefulWidget {
  final Map<String, dynamic> conductorUser;

  const ConductorHomeScreen({
    super.key,
    required this.conductorUser,
  });

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  geo.Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isMapReady = false;
  bool _isOnline = false;
  bool _isAppInBackground = false;
  StreamSubscription<geo.Position>? _positionStream;
  
  late AnimationController _pulseController;
  late AnimationController _connectionController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  // Sistema robusto de manejo de mapa
  MapState _mapState = MapState.loading;
  int _mapboxFailureCount = 0;
  static const int _maxMapboxFailures = 3;
  Timer? _mapRecoveryTimer;
  bool _isMapboxDisabled = false;

  // Sistema de cola para operaciones del mapa
  final Queue<Future<void> Function()> _mapOperationQueue = Queue<Future<void> Function()>();
  bool _isProcessingMapOperation = false;
  Timer? _mapUpdateDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeMapSystem();
    _requestLocationPermission();
  }

  void _initializeMapSystem() {
    // Intentar inicializar Mapbox
    if (!_isMapboxDisabled) {
      _mapState = MapState.loading;
      debugPrint('🗺️ Inicializando sistema de mapas...');
    } else {
      _mapState = MapState.staticMap;
      debugPrint('🗺️ Usando mapa estático (Mapbox deshabilitado)');
    }
  }

  void _handleMapboxFailure(String error) {
    _mapboxFailureCount++;
    debugPrint('❌ Fallo de Mapbox #$_mapboxFailureCount: $error');

    if (_mapboxFailureCount >= _maxMapboxFailures) {
      _isMapboxDisabled = true;
      _mapState = MapState.disabled;
      debugPrint('🚫 Mapbox deshabilitado permanentemente');

      // Programar recuperación en 5 minutos
      _mapRecoveryTimer?.cancel();
      _mapRecoveryTimer = Timer(const Duration(minutes: 5), () {
        if (mounted) {
          _mapboxFailureCount = 0;
          _isMapboxDisabled = false;
          _mapState = MapState.loading;
          setState(() {});
          debugPrint('🔄 Intentando recuperar Mapbox...');
        }
      });
    } else {
      _mapState = MapState.mapboxFailed;
      debugPrint('⚠️ Cambiando a mapa estático temporalmente');
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _handleMapboxSuccess() {
    _mapboxFailureCount = 0;
    _mapState = MapState.mapboxReady;
    _isMapReady = true;
    debugPrint('✅ Mapbox funcionando correctamente');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInBackground = true;
        _cleanupMapResources();
        debugPrint('� App en background - recursos del mapa limpiados');
        break;
      case AppLifecycleState.resumed:
        _isAppInBackground = false;
        // Forzar reconstrucción del mapa si es necesario
        if (mounted) {
          setState(() {});
        }
        debugPrint('✅ App en foreground - mapa listo');
        break;
      case AppLifecycleState.hidden:
        debugPrint('📱 App hidden');
        break;
    }
  }



  void _initializeAnimations() {
    // Animación de pulso para el botón de conexión
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animación de escala para transiciones
    _connectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _connectionController,
      curve: Curves.elasticOut,
    );
  }

  Future<void> _requestLocationPermission() async {
    try {
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.deniedForever) {
        _showPermissionDeniedDialog();
        return;
      }

      if (permission == geo.LocationPermission.whileInUse ||
          permission == geo.LocationPermission.always) {
        await _getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error al solicitar permisos de ubicación: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Iniciar seguimiento de ubicación en tiempo real
      _startLocationTracking();
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  void _startLocationTracking() {
    final locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros
    );

    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((geo.Position position) {
      setState(() => _currentPosition = position);
      
      // Usar debounce para evitar actualizaciones demasiado frecuentes
      _debouncedUpdateLocation(position);
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso de ubicación requerido'),
        content: const Text(
          'La aplicación necesita acceso a tu ubicación para funcionar correctamente. '
          'Por favor, habilita los permisos de ubicación en la configuración.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              geo.Geolocator.openAppSettings();
            },
            child: const Text('Abrir configuración'),
          ),
        ],
      ),
    );
  }

  void _addCurrentLocationMarker() {
    // Solo intentar si Mapbox está funcionando
    if (_mapState != MapState.mapboxReady || _mapboxMap == null || _currentPosition == null || _isAppInBackground) {
      return;
    }
    
    _enqueueMapOperation(() async {
      try {
        // Crear o reutilizar el annotation manager
        _pointAnnotationManager ??= await _mapboxMap!.annotations.createPointAnnotationManager();
        
        // Limpiar marcadores anteriores
        await _pointAnnotationManager!.deleteAll();
        
        final pointAnnotationOptions = PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              _currentPosition!.longitude,
              _currentPosition!.latitude,
            ),
          ),
          iconSize: 1.5,
          iconColor: AppColors.primary.value,
        );

        await _pointAnnotationManager!.create(pointAnnotationOptions);
        debugPrint('✅ Marcador de ubicación agregado');
      } catch (e) {
        debugPrint('❌ Error al agregar marcador: $e');
        _handleMapboxFailure('Error en marcador: $e');
      }
    });
  }

  void _toggleOnlineStatus() {
    setState(() => _isOnline = !_isOnline);
    
    if (_isOnline) {
      _connectionController.forward();
      HapticFeedback.mediumImpact();
      _showStatusSnackbar('Estás en línea', AppColors.success);
    } else {
      _connectionController.reverse();
      HapticFeedback.lightImpact();
      _showStatusSnackbar('Estás fuera de línea', Colors.grey);
    }
  }

  void _showStatusSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isOnline ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _connectionController.dispose();
    _positionStream?.cancel();
    _mapUpdateDebounceTimer?.cancel();
    _mapRecoveryTimer?.cancel();
    
    // Limpiar recursos del mapa
    _cleanupMapResources();
    
    super.dispose();
  }

  void _cleanupMapResources() {
    try {
      // Limpiar annotation manager
      _pointAnnotationManager?.deleteAll();
      // No destruir el manager aquí, solo limpiar
      debugPrint('🧹 Recursos del mapa limpiados');
    } catch (e) {
      debugPrint('❌ Error limpiando recursos del mapa: $e');
    }
  }

  // Sistema de cola para operaciones del mapa
  void _enqueueMapOperation(Future<void> Function() operation) {
    _mapOperationQueue.add(operation);
    _processMapOperationQueue();
  }

  Future<void> _processMapOperationQueue() async {
    if (_isProcessingMapOperation || _mapOperationQueue.isEmpty || _mapState != MapState.mapboxReady) {
      return;
    }
    
    _isProcessingMapOperation = true;
    
    try {
      while (_mapOperationQueue.isNotEmpty && _mapState == MapState.mapboxReady) {
        final operation = _mapOperationQueue.removeFirst();
        
        try {
          await Future.any([
            operation(),
            Future.delayed(const Duration(seconds: 3), () {
              throw TimeoutException('Timeout en operación del mapa');
            }),
          ]);
        } catch (e) {
          debugPrint('❌ Error en operación de mapa: $e');
          _handleMapboxFailure('Error en operación: $e');
          break; // Salir del loop si hay error
        }
        
        // Pequeño delay entre operaciones para evitar sobrecarga
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint('❌ Error procesando cola de operaciones del mapa: $e');
      _handleMapboxFailure('Error en cola: $e');
    } finally {
      _isProcessingMapOperation = false;
    }
  }

  // Método para actualizar la ubicación con debounce
  void _debouncedUpdateLocation(geo.Position position) {
    _mapUpdateDebounceTimer?.cancel();
    _mapUpdateDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Solo actualizar si Mapbox está funcionando
      if (mounted && !_isAppInBackground && _mapState == MapState.mapboxReady) {
        _enqueueMapOperation(() => _updateMapCameraAndMarker(position));
      }
    });
  }

  Future<void> _updateMapCameraAndMarker(geo.Position position) async {
    // Si Mapbox no está listo o está fallando, no hacer nada
    if (_mapState != MapState.mapboxReady || _mapboxMap == null || !mounted || _isAppInBackground) {
      return;
    }

    try {
      // Actualizar cámara con timeout
      await Future.any([
        _mapboxMap!.setCamera(
          CameraOptions(
            center: Point(
              coordinates: Position(position.longitude, position.latitude),
            ),
            zoom: 16.0,
            pitch: 0.0,
          ),
        ),
        Future.delayed(const Duration(seconds: 2), () {
          throw TimeoutException('Timeout al actualizar cámara');
        }),
      ]);

      // Agregar marcador de forma segura
      _addCurrentLocationMarker();
      
      debugPrint('✅ Cámara y marcador actualizados');
    } catch (e) {
      debugPrint('❌ Error actualizando mapa: $e');
      _handleMapboxFailure('Error en actualización: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Mapa de fondo
          _buildMap(),
          
          // Overlay con controles
          _buildOverlay(),
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
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
            'Viax Driver',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        // Botón de menú
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: Colors.grey[800],
            ),
            onPressed: () {
              // TODO: Abrir drawer o menú
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    // Si no hay ubicación, mostrar pantalla de carga
    if (_isLoadingLocation) {
      return Container(
        color: AppColors.lightBackground,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
      );
    }

    // Si no hay posición, mostrar error
    if (_currentPosition == null) {
      return Container(
        color: AppColors.lightBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudo obtener tu ubicación',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _requestLocationPermission,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Sistema robusto de mapas basado en estado
    switch (_mapState) {
      case MapState.loading:
        return _buildLoadingMap();
      case MapState.mapboxReady:
        return _buildMapboxMap();
      case MapState.mapboxFailed:
      case MapState.staticMap:
        return _buildStaticMap();
      case MapState.disabled:
        return _buildDisabledMap();
    }
  }

  Widget _buildLoadingMap() {
    return Container(
      color: AppColors.lightBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando mapa...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapboxMap() {
    return Stack(
      children: [
        MapWidget(
          key: ValueKey('mapbox_${_currentPosition!.latitude}_${_currentPosition!.longitude}'),
          cameraOptions: CameraOptions(
            center: Point(
              coordinates: Position(
                _currentPosition!.longitude,
                _currentPosition!.latitude,
              ),
            ),
            zoom: 16.0,
            pitch: 0.0,
          ),
          styleUri: MapboxStyles.MAPBOX_STREETS,
          textureView: false, // Importante: false para evitar SurfaceView issues
          onMapCreated: (MapboxMap mapboxMap) {
            try {
              _mapboxMap = mapboxMap;
              debugPrint('✅ Mapa de Mapbox creado correctamente');
              _handleMapboxSuccess();
              
              // Agregar marcador inicial si ya tenemos posición
              if (_currentPosition != null) {
                _addCurrentLocationMarker();
              }
            } catch (e) {
              debugPrint('❌ Error en onMapCreated: $e');
              _handleMapboxFailure('Error en inicialización: $e');
            }
          },
          onMapLoadErrorListener: (eventData) {
            debugPrint('❌ Error al cargar Mapbox: ${eventData.message}');
            _handleMapboxFailure('Error de carga: ${eventData.message}');
          },
        ),

        // Overlay de carga mientras Mapbox se inicializa
        if (!_isMapReady || _isAppInBackground)
          Container(
            color: AppColors.lightBackground.withOpacity(0.9),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isAppInBackground ? 'Aplicación en segundo plano...' : 'Inicializando mapa...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStaticMap() {
    return Container(
      color: AppColors.lightBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Mapa no disponible temporalmente',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Usando modo seguro',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _mapboxFailureCount = 0;
                _isMapboxDisabled = false;
                _mapState = MapState.loading;
                setState(() {});
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar mapa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledMap() {
    return Container(
      color: AppColors.lightBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_rounded,
              size: 64,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Mapa deshabilitado',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Se recuperará automáticamente en unos minutos',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildOverlay() {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
          
          // Panel inferior con controles
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status y estadísticas
          _buildStatusSection(),
          
          // Divisor
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor.withOpacity(0.1),
          ),
          
          // Botón de conexión
          _buildConnectionButton(),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Estado actual
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? AppColors.success.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: _isOnline ? AppColors.success : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnline ? 'En línea' : 'Desconectado',
                      style: TextStyle(
                        color: theme.textTheme.titleLarge?.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isOnline
                          ? 'Buscando pasajeros cerca...'
                          : 'Conéctate para recibir viajes',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Indicador de batería o señal
              if (_isOnline)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Estadísticas rápidas
          Consumer<ConductorProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  _buildStatItem(
                    icon: Icons.access_time_rounded,
                    label: 'Hoy',
                    value: '0h',
                    color: AppColors.primary,
                  ),
                  _buildStatItem(
                    icon: Icons.directions_car_rounded,
                    label: 'Viajes',
                    value: '0',
                    color: AppColors.accent,
                  ),
                  _buildStatItem(
                    icon: Icons.payments_rounded,
                    label: 'Ganado',
                    value: '\$0',
                    color: AppColors.success,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isOnline ? 1.0 : 0.98,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleOnlineStatus,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: _isOnline
                        ? LinearGradient(
                            colors: [
                              Colors.grey[300]!,
                              Colors.grey[400]!,
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_isOnline
                                ? Colors.grey[400]!
                                : AppColors.primary)
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isOnline
                            ? Icons.power_settings_new_rounded
                            : Icons.flash_on_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isOnline ? 'Desconectar' : 'Conectarse',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
