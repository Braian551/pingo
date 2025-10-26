import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ping_go/src/global/services/mapbox_service.dart';
import 'package:ping_go/src/core/config/env_config.dart';

class RequestTripScreen extends StatefulWidget {
  const RequestTripScreen({super.key});

  @override
  State<RequestTripScreen> createState() => _RequestTripScreenState();
}

class _RequestTripScreenState extends State<RequestTripScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  String? _pickupAddress;
  String? _destinationAddress;
  bool _isLoadingLocation = true;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<MapboxPlace> _searchResults = [];
  Timer? _debounceTimer;
  
  // Estado de selección: 'pickup' o 'destination'
  String? _selectingFor; // null = ninguno, 'pickup' = origen, 'destination' = destino
  
  // Controladores de animación para el pin
  late AnimationController _pinAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pinBounceAnimation;
  late Animation<double> _pulseAnimation;
  bool _isMapMoving = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _setupSearchListeners();
    _setupPinAnimations();
  }
  
  void _setupPinAnimations() {
    _pinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _pinBounceAnimation = Tween<double>(
      begin: 0.0,
      end: -12.0,
    ).animate(CurvedAnimation(
      parent: _pinAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupSearchListeners() {
    _searchController.addListener(() {
      _debounceSearch(_searchController.text);
    });

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        // Si pierde el foco, cerrar el panel de búsqueda
        setState(() {
          _selectingFor = null;
          _searchResults = [];
        });
      }
    });
  }

  void _debounceSearch(String query) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final results = await MapboxService.searchPlaces(
        query: query,
        proximity: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : null,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      print('Error buscando lugares: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _pinAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _pickupLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _getReverseGeocode(_pickupLocation!, true);

      _mapController.move(_pickupLocation!, 15);
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getReverseGeocode(LatLng position, bool isPickup) async {
    try {
      final place = await MapboxService.reverseGeocode(position: position);
      
      if (place != null && mounted) {
        setState(() {
          if (isPickup) {
            _pickupAddress = place.placeName;
          } else {
            _destinationAddress = place.placeName;
          }
        });
      }
    } catch (e) {
      print('Error en geocodificación inversa: $e');
    }
  }

  void _selectPlace(MapboxPlace place) {
    setState(() {
      if (_selectingFor == 'pickup') {
        _pickupLocation = place.coordinates;
        _pickupAddress = place.placeName;
        _selectingFor = null;
        _searchFocusNode.unfocus();
        _searchController.clear();
      } else if (_selectingFor == 'destination') {
        _destinationLocation = place.coordinates;
        _destinationAddress = place.placeName;
        _selectingFor = null;
        _searchFocusNode.unfocus();
        _searchController.clear();
      }
      _searchResults = [];
    });

    _mapController.move(place.coordinates, 15);
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    if (_selectingFor == null) return;

    final isPickup = _selectingFor == 'pickup';

    setState(() {
      if (isPickup) {
        _pickupLocation = position;
      } else {
        _destinationLocation = position;
      }
      _selectingFor = null;
      _searchFocusNode.unfocus();
      _searchController.clear();
      _searchResults = [];
    });

    _mapController.move(position, 15);
    _getReverseGeocode(position, isPickup);
  }

  void _confirmTrip() {
    if (_pickupLocation == null) {
      _showSnackBar('Selecciona un punto de origen');
      return;
    }
    if (_destinationLocation == null) {
      _showSnackBar('Selecciona un punto de destino');
      return;
    }

    Navigator.pushNamed(
      context,
      '/confirm_trip',
      arguments: {
        'pickup': _pickupLocation,
        'destination': _destinationLocation,
        'pickupAddress': _pickupAddress,
        'destinationAddress': _destinationAddress,
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Mapa de Mapbox
          _isLoadingLocation
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFF00)),
                  ),
                )
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pickupLocation ?? const LatLng(4.7110, -74.0721),
                    initialZoom: 15,
                    minZoom: 3,
                    maxZoom: 18,
                    onTap: _onMapTap,
                    onMapEvent: (event) {
                      if (event is MapEventMoveStart) {
                        setState(() => _isMapMoving = true);
                        _pinAnimationController.forward();
                      } else if (event is MapEventMoveEnd) {
                        setState(() => _isMapMoving = false);
                        _pinAnimationController.reverse();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapboxService.getTileUrl(style: 'streets-v12'),
                      userAgentPackageName: 'com.example.ping_go',
                      additionalOptions: const {
                        'access_token': EnvConfig.mapboxPublicToken,
                      },
                    ),
                  ],
                ),

          // Pin central estilo Uber (igual que address_step_widget)
          if (_selectingFor == null)
            Center(
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pinAnimationController, _pulseAnimationController]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _pinBounceAnimation.value),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Pulso animado de fondo
                              if (!_isMapMoving)
                                Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFF00).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              
                              // Pin principal
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                      spreadRadius: 1,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFFFFF00).withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 2),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFF00),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFFF00).withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Punto de referencia exacto
                              Positioned(
                                bottom: -8,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Sombra debajo del pin
                          const SizedBox(height: 4),
                          Transform.scale(
                            scale: _isMapMoving ? 0.8 : 1.0,
                            child: Container(
                              width: 24,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          // Panel de búsqueda (arriba)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildSearchPanel(),
          ),

          // Resultados de búsqueda (debajo del panel, sin solapar)
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 240,
              left: 16,
              right: 16,
              bottom: 120,
              child: _buildSearchResults(),
            ),

          // Botón de confirmar (abajo)
          if (_selectingFor == null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: _buildConfirmButton(),
            ),

          // Botón de mi ubicación
          if (_selectingFor == null)
            Positioned(
              bottom: 110,
              right: 20,
              child: _buildMyLocationButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF000000).withOpacity(0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFFFFF).withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
                        onPressed: () {
                          if (_selectingFor != null) {
                            setState(() {
                              _selectingFor = null;
                              _searchResults = [];
                              _searchFocusNode.unfocus();
                              _searchController.clear();
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const Expanded(
                        child: Text(
                          '¿A dónde vamos?',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Campos compactos de origen y destino (estilo DiDi)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectingFor = 'pickup';
                        _searchFocusNode.requestFocus();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectingFor == 'pickup' 
                            ? const Color(0xFFFFFF00).withOpacity(0.15)
                            : const Color(0xFFFFFFFF).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectingFor == 'pickup' 
                              ? const Color(0xFFFFFF00)
                              : const Color(0xFFFFFFFF).withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF00).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.my_location, color: Color(0xFF00FF00), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _pickupAddress != null && _pickupAddress!.isNotEmpty
                                  ? _pickupAddress!
                                  : 'Seleccionar origen',
                              style: TextStyle(
                                color: _pickupAddress != null && _pickupAddress!.isNotEmpty
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFFFFFFFF).withOpacity(0.4),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_pickupLocation != null)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: const Color(0xFFFFFFFF).withOpacity(0.54),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _pickupLocation = null;
                                  _pickupAddress = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectingFor = 'destination';
                        _searchFocusNode.requestFocus();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectingFor == 'destination' 
                            ? const Color(0xFFFFFF00).withOpacity(0.15)
                            : const Color(0xFFFFFFFF).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectingFor == 'destination' 
                              ? const Color(0xFFFFFF00)
                              : const Color(0xFFFFFFFF).withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF0000).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on, color: Color(0xFFFF0000), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _destinationAddress != null && _destinationAddress!.isNotEmpty
                                  ? _destinationAddress!
                                  : 'Seleccionar destino',
                              style: TextStyle(
                                color: _destinationAddress != null && _destinationAddress!.isNotEmpty
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFFFFFFFF).withOpacity(0.4),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_destinationLocation != null)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: const Color(0xFFFFFFFF).withOpacity(0.54),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _destinationLocation = null;
                                  _destinationAddress = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Campo de búsqueda dinámico (aparece cuando se selecciona origen o destino)
                  if (_selectingFor != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFF00).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFFF00),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Color(0xFFFFFF00), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: _selectingFor == 'pickup' 
                                    ? 'Buscar origen...' 
                                    : 'Buscar destino...',
                                hintStyle: TextStyle(
                                  color: const Color(0xFFFFFFFF).withOpacity(0.4),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: const Color(0xFFFFFFFF).withOpacity(0.54),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchResults = [];
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: const Color(0xFF000000).withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFFFFF).withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => Divider(
              color: const Color(0xFFFFFFFF).withOpacity(0.08),
              height: 1,
              indent: 60,
              endIndent: 20,
            ),
            itemBuilder: (context, index) {
              final place = _searchResults[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectPlace(place),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFF00).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFFFFFF00),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.text,
                                style: const TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (place.placeName != place.text)
                                Text(
                                  place.placeName,
                                  style: TextStyle(
                                    color: const Color(0xFFFFFFFF).withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: const Color(0xFFFFFFFF).withOpacity(0.4),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final bool canConfirm = _pickupLocation != null && _destinationLocation != null;

    return GestureDetector(
      onTap: canConfirm ? _confirmTrip : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: canConfirm ? const Color(0xFFFFFF00) : const Color(0xFF808080).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: canConfirm
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFFF00).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: const Center(
          child: Text(
            'Continuar',
            style: TextStyle(
              color: Color(0xFF000000),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF000000).withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFFFFF).withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.my_location, color: Color(0xFFFFFF00)),
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.move(
                  LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  15,
                );
              } else {
                _getCurrentLocation();
              }
            },
          ),
        ),
      ),
    );
  }
}
