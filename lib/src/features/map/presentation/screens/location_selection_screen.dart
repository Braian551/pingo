// lib/src/features/map/presentation/screens/location_selection_screen.dart
// PANTALLA COMENTADA - YA NO SE USA GOOGLE MAPS
/*
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ping_go/src/global/services/location_service.dart';
import 'package:ping_go/src/routes/route_names.dart';

class LocationSelectionScreen extends StatefulWidget {
  final String email;
  final String userName;

  const LocationSelectionScreen({
    super.key,
    required this.email,
    required this.userName,
  });

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoading = true;
  bool _isGettingAddress = false;

  // Ubicación por defecto (Bogotá, Colombia)
  static const LatLng _defaultLocation = LatLng(4.6097, -74.0817);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    Position? position = await LocationService.getCurrentPosition();
    
    if (position != null) {
      _selectedLocation = LatLng(position.latitude, position.longitude);
      await _getAddressFromLocation(_selectedLocation!);
    } else {
      _selectedLocation = _defaultLocation;
      await _getAddressFromLocation(_selectedLocation!);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    setState(() => _isGettingAddress = true);
    
    String? address = await LocationService.getAddressFromCoordinates(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    
    setState(() {
      _selectedAddress = address ?? 'Dirección no encontrada';
      _isGettingAddress = false;
    });
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromLocation(location);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pushReplacementNamed(
        context,
        RouteNames.register,
        arguments: {
          'email': widget.email,
          'userName': widget.userName,
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'address': _selectedAddress,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Selecciona tu ubicación',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Mapa
          if (!_isLoading)
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? _defaultLocation,
                zoom: 15,
              ),
              onTap: _onMapTap,
              markers: _selectedLocation != null
                  ? {
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: _selectedLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                    }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
            ),
          
          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF39FF14),
              ),
            ),
          
          // Panel inferior con información
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador de arrastre
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Título
                  const Text(
                    'Confirma tu ubicación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Dirección seleccionada
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF39FF14),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Dirección:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_isGettingAddress)
                            const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF39FF14),
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Obteniendo dirección...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              _selectedAddress,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                        ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Botón de confirmar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _selectedLocation != null ? _confirmLocation : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39FF14),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmar ubicación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Instrucciones
                  const Text(
                    'Toca el mapa para seleccionar tu ubicación exacta',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/
