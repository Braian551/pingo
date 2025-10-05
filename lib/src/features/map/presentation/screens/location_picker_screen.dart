import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/map_provider.dart';
import '../widgets/osm_map_widget.dart';
import '../widgets/location_search_widget.dart';
import '../../../../global/services/auth/user_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final String? initialAddress;
  final LatLng? initialLocation;
  final String screenTitle;
  final bool showConfirmButton;

  const LocationPickerScreen({
    super.key,
    this.initialAddress,
    this.initialLocation,
    this.screenTitle = 'Seleccionar ubicación',
    this.showConfirmButton = true,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _editableAddressController = TextEditingController();
  VoidCallback? _providerListener;
  // Animation for center pin bounce
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  Timer? _mapMoveTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  // Do not listen for edits here; editing the address should not trigger geocoding.
  }

  // ...existing dispose is lower in file; we will dispose animationController there

  void _initializeLocation() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    
    if (widget.initialLocation != null) {
      mapProvider.selectLocation(widget.initialLocation!);
    }
    
    if (widget.initialAddress != null) {
      _searchController.text = widget.initialAddress!;
    }
    // Initialize editable controller with any existing selectedAddress
    if (mapProvider.selectedAddress != null) {
      _editableAddressController.text = mapProvider.selectedAddress!;
    }
    // If no initial data provided, try to load saved profile location from backend
    if (widget.initialAddress == null && widget.initialLocation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final session = await UserService.getSavedSession();
        if (session != null) {
          final id = session['id'] as int?;
          final email = session['email'] as String?;
          final profile = await UserService.getProfile(userId: id, email: email);
          if (profile != null && profile['success'] == true) {
            final location = profile['location'];
            if (location != null) {
              final lat = double.tryParse(location['latitud'] ?? '') ?? (location['latitud'] is num ? (location['latitud'] as num).toDouble() : null);
              final lng = double.tryParse(location['longitud'] ?? '') ?? (location['longitud'] is num ? (location['longitud'] as num).toDouble() : null);
              final dir = location['direccion'] as String?;
              if (lat != null && lng != null) {
                await mapProvider.selectLocation(LatLng(lat, lng));
              }
              if (dir != null && dir.isNotEmpty) {
                mapProvider.setSelectedAddress(dir);
                _editableAddressController.text = dir;
                _searchController.text = dir;
              }
            }
          }
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure the editable controller stays in sync with provider.selectedAddress
    final mapProvider = Provider.of<MapProvider>(context);
    // Remove previous listener if set
    if (_providerListener != null) {
      // nothing to remove - provider doesn't have removeListener per-instance here
    }
    // We use a simple post-frame callback to set current value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _editableAddressController.text = mapProvider.selectedAddress ?? _editableAddressController.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.screenTitle,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [],
      ),

      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LocationSearchWidget(
              controller: _searchController,
              onSearch: (query) {
                mapProvider.searchAddress(query);
              },
              onSubmit: (query) async {
                // When user presses Enter or the search icon, try to geocode and select
                final found = await mapProvider.geocodeAndSelect(query);
                if (!found) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dirección no encontrada'), duration: Duration(seconds: 2)),
                  );
                } else {
                  // Sync search controller with the selected address
                  _searchController.text = mapProvider.selectedAddress ?? _searchController.text;
                }
              },
            ),
          ),

          // Resultados de búsqueda
          if (mapProvider.searchResults.isNotEmpty)
            Expanded(
              flex: 1,
              child: _buildSearchResults(mapProvider),
            ),

          // Mapa
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                OSMMapWidget(
                  initialLocation: widget.initialLocation,
                  interactive: true,
                  onLocationSelected: (location) {
                    // La selección se maneja automáticamente en el provider
                  },
                  onMapMoveStart: () {
                    _mapMoveTimer?.cancel();
                    _animationController.forward();
                  },
                  onMapMoveEnd: () {
                    _mapMoveTimer?.cancel();
                    _mapMoveTimer = Timer(const Duration(milliseconds: 150), () {
                      _animationController.reverse();
                    });
                  },
                ),
                // Center marker matching AddressStepWidget style with bounce animation
                Center(
                  child: IgnorePointer(
                    ignoring: true,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _bounceAnimation.value),
                          child: child,
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 25,
                            width: 2,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Indicador de carga
                if (mapProvider.isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39FF14)),
                    ),
                  ),
                
                // Dirección seleccionada (editable)
                if (mapProvider.selectedAddress != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildEditableSelectedAddressCard(mapProvider),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(MapProvider mapProvider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        itemCount: mapProvider.searchResults.length,
        itemBuilder: (context, index) {
          final result = mapProvider.searchResults[index];
          return ListTile(
            leading: const Icon(Icons.location_on, color: Color(0xFF39FF14)),
            title: Text(
              result.getFormattedAddress(),
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              mapProvider.selectSearchResult(result);
              _searchController.text = result.getFormattedAddress();
              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
    );
  }

  

  Widget _buildEditableSelectedAddressCard(MapProvider mapProvider) {
    return Card(
      color: Colors.black.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.location_pin, color: Color(0xFF39FF14)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ubicación seleccionada:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _editableAddressController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Editar dirección...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          // Editable but DOES NOT trigger geocoding here; map moves update the field
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Save edited address button
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.save, color: Colors.black),
                          onPressed: () async {
                            // Update provider and backend with edited address
                            final newAddress = _editableAddressController.text.trim();
                            if (newAddress.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dirección vacía')));
                              return;
                            }

                            // Update provider selectedAddress only locally
                            mapProvider.setSelectedAddress(newAddress);
                            // Because _selectedAddress is private, use a fallback: set via geocodeAndSelect attempt
                            final found = await mapProvider.geocodeAndSelect(newAddress);
                            if (!found) {
                              // If geocoding didn't find a match, still set the address display by manually selecting
                              // There's no public setter, so we call selectSearchResult only when we have a NominatimResult. As a compromise,
                              // call selectLocation with current selectedLocation to update address cache (no geocode) or simply call notifyListeners via clearSelection+reselect
                              // We'll use selectLocation with existing coordinates if available
                              if (mapProvider.selectedLocation != null) {
                                await mapProvider.selectLocation(mapProvider.selectedLocation!);
                                // overwrite the address with edited text
                                // Unfortunately selectedAddress is private; we will rely on the editable field staying updated instead.
                              }
                            }

                            // Persist to backend
                            final session = await UserService.getSavedSession();
                            bool saved = false;
                            if (session != null) {
                              final uid = session['id'] as int?;
                              saved = await UserService.updateUserLocation(
                                userId: uid,
                                address: newAddress,
                                latitude: mapProvider.selectedLocation?.latitude,
                                longitude: mapProvider.selectedLocation?.longitude,
                                city: mapProvider.selectedCity,
                                state: mapProvider.selectedState,
                              );
                            }

                            if (saved) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dirección guardada')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar en el servidor')));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _editableAddressController.dispose();
    _mapMoveTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Editing the selected-address field does not trigger geocoding.
}