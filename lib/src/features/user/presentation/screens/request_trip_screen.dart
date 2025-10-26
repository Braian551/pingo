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

// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  
  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              colors: const [
                Color(0xFF1A1A1A),
                Color(0xFFFFD700),
                Color(0xFF1A1A1A),
              ],
            ).createShader(bounds);
          },
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
          child: ShimmerLoading(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFFFFD700),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Obteniendo ubicación...',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
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
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '¿A dónde vamos?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Campo de origen
                _buildLocationField(
                  icon: Icons.my_location,
                  iconColor: const Color(0xFFFFD700),
                  label: 'Ubicación actual',
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
                const SizedBox(height: 12),
                // Campo de destino
                _buildLocationField(
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
              ],
            ),
          ),
          // Accesos rápidos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 24),
          // Lugares sugeridos (aquí podrías agregar historial)
          Expanded(
            child: _buildSuggestedPlaces(),
          ),
        ],
      ),
      bottomNavigationBar: _pickupLocation != null && _destinationLocation != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirmar ubicaciones',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
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
        title: const Text(
          'Buscar ubicación',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Campo de origen (read-only) si seleccionando destino
                if (_selectingFor == 'destination')
                  Container(
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
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD700),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _pickupAddress ?? 'Ubicación actual',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_selectingFor == 'destination') const SizedBox(height: 12),
                // Campo de búsqueda activo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
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
                              ),
                              decoration: InputDecoration(
                                hintText: '¿A dónde vamos?',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 15,
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
                              child: Icon(
                                Icons.close,
                                color: Colors.white.withOpacity(0.5),
                                size: 20,
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
          // Resultados de búsqueda
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFFFFD700),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              place.text,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: place.placeName != place.text
                                ? Text(
                                    place.placeName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () => _selectPlace(place),
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
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_searching,
                      color: Color(0xFFFFD700),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Señalar la ubicación en el mapa',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // TODO: Implementar selección en mapa
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_location,
                      color: Color(0xFFFFD700),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Agregar ubicación',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // TODO: Implementar agregar ubicación favorita
                  },
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
      child: GestureDetector(
        onTap: () {
          // TODO: Implementar accesos rápidos
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: const Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Widget _buildSuggestedPlaces() {
    // Aquí podrías mostrar lugares del historial o sugerencias
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lugares recientes',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Aquí podrías agregar una lista de lugares recientes
          Center(
            child: Text(
              'No hay lugares recientes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
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
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
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
                  width: 8,
                  height: 8,
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
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (value != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
