import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ping_go/src/global/services/mapbox_service.dart';

class RequestTripScreen extends StatefulWidget {
  const RequestTripScreen({super.key});

  @override
  State<RequestTripScreen> createState() => _RequestTripScreenState();
}

// Efecto de pulsación suave
class PulseAnimation extends StatefulWidget {
  final Widget child;
  
  const PulseAnimation({super.key, required this.child});

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: child,
        );
      },
    );
  }
}

class _RequestTripScreenState extends State<RequestTripScreen> {
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
  String? _selectingFor;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _setupSearchListeners();
  }
  
  void _setupSearchListeners() {
    _searchController.addListener(() {
      _debounceSearch(_searchController.text);
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
      if (mounted) {
        setState(() => _searchResults = []);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
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

      // Establecer automáticamente la ubicación actual como punto de origen
      _getReverseGeocode(_pickupLocation!, true);
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
      } else if (_selectingFor == 'destination') {
        _destinationLocation = place.coordinates;
        _destinationAddress = place.placeName;
      }
      _selectingFor = null;
      _searchController.clear();
      _searchResults = [];
    });
    
    _searchFocusNode.unfocus();
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
      '/vehicle_selection',
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
    if (_isLoadingLocation) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: PulseAnimation(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFFFFD700),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Obteniendo ubicación actual...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Si está seleccionando un lugar, mostrar la vista de búsqueda
    if (_selectingFor != null) {
      return _buildSearchView();
    }

    // Vista principal con origen y destino
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: const Color(0xFF1A1A1A).withOpacity(0.8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          '¿A dónde vamos?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Campo de origen con animación - EDITABLE
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildLocationField(
                    icon: Icons.my_location,
                    iconColor: const Color(0xFFFFD700),
                    label: _pickupLocation != null ? 'Origen' : 'Seleccionar origen',
                    value: _pickupAddress,
                    isSelected: false,
                    onTap: () {
                      setState(() {
                        _selectingFor = 'pickup';
                      });
                    },
                    onClear: _pickupLocation != null
                        ? () {
                            setState(() {
                              _pickupLocation = null;
                              _pickupAddress = null;
                            });
                          }
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Campo de destino con animación
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildLocationField(
                    icon: Icons.location_on,
                    iconColor: const Color(0xFFFFD700),
                    label: '¿A dónde vamos?',
                    value: _destinationAddress,
                    isSelected: false,
                    onTap: () {
                      setState(() {
                        _selectingFor = 'destination';
                      });
                    },
                    onClear: _destinationLocation != null
                        ? () {
                            setState(() {
                              _destinationLocation = null;
                              _destinationAddress = null;
                            });
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          // Accesos rápidos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildQuickAccess(Icons.home, 'Casa'),
                const SizedBox(width: 12),
                _buildQuickAccess(Icons.work, 'Trabajo'),
                const SizedBox(width: 12),
                _buildQuickAccess(Icons.star, 'Favoritos'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Lugares sugeridos (aquí podrías agregar historial)
          Expanded(
            child: _buildSuggestedPlaces(),
          ),
        ],
      ),
      bottomNavigationBar: _pickupLocation != null && _destinationLocation != null
          ? ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.9),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: _confirmTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmar ubicaciones',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSearchView() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: const Color(0xFF1A1A1A).withOpacity(0.8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
                  onPressed: () {
                    setState(() {
                      _selectingFor = null;
                      _searchController.clear();
                      _searchResults = [];
                    });
                    _searchFocusNode.unfocus();
                  },
                ),
              ),
            ),
          ),
        ),
        title: Text(
          _selectingFor == 'pickup' ? 'Punto de origen' : 'Punto de destino',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Campo de origen (read-only) si seleccionando destino
                if (_selectingFor == 'destination' && _pickupAddress != null)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFD700),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _pickupAddress!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 15,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                // Campo de destino (read-only) si seleccionando origen
                if (_selectingFor == 'pickup' && _destinationAddress != null)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFD700),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _destinationAddress!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 15,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                // Campo de búsqueda activo
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD700),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              autofocus: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                              decoration: InputDecoration(
                                hintText: _selectingFor == 'pickup' 
                                    ? '¿Desde dónde?' 
                                    : '¿A dónde vamos?',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 18,
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
          const SizedBox(height: 16),
          // Resultados de búsqueda
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectPlace(place),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Color(0xFFFFD700),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.text,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        if (place.placeName != place.text) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            place.placeName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withOpacity(0.5),
                                              letterSpacing: -0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: _buildSearchSuggestions(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Opción para usar ubicación actual (solo cuando se selecciona origen)
        if (_selectingFor == 'pickup' && _currentPosition != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    setState(() {
                      _pickupLocation = LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      );
                    });
                    await _getReverseGeocode(_pickupLocation!, true);
                    setState(() {
                      _selectingFor = null;
                      _searchController.clear();
                      _searchResults = [];
                    });
                    _searchFocusNode.unfocus();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Color(0xFFFFD700),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Usar mi ubicación actual',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: const Color(0xFFFFD700).withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Implementar selección en mapa
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_searching,
                          color: Color(0xFFFFD700),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Señalar la ubicación en el mapa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Implementar agregar ubicación favorita
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_location,
                          color: Color(0xFFFFD700),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Agregar ubicación',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccess(IconData icon, String label) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // TODO: Implementar accesos rápidos
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: const Color(0xFFFFD700), size: 24),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
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

  Widget _buildSuggestedPlaces() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lugares recientes',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              textBaseline: TextBaseline.alphabetic,
            ).copyWith(height: 1.2),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'No hay lugares recientes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String? value,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      value ?? label,
                      style: TextStyle(
                        color: value != null ? Colors.white : Colors.white.withOpacity(0.5),
                        fontSize: 15,
                        fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (value != null && onClear != null)
                    GestureDetector(
                      onTap: onClear,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.6),
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
