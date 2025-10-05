import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/map_provider.dart';
import '../widgets/osm_map_widget.dart';
// import '../widgets/location_search_widget.dart'; // not used here
import '../../../../global/services/auth/user_service.dart';
import 'package:ping_go/src/global/services/nominatim_service.dart';

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

class _LocationPickerScreenState extends State<LocationPickerScreen> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _editableAddressController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  Timer? _mapMoveTimer;
  Timer? _moveDebounce;
  bool _isSearchFocused = false;
  bool _confirmed = false;
  // ignore: unused_field
  LatLng? _mapCenterCache;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _setupAnimations();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
    );
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  void _initializeLocation() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    
    if (widget.initialLocation != null) {
      mapProvider.selectLocation(widget.initialLocation!);
    }
    
    if (widget.initialAddress != null) {
      _searchController.text = widget.initialAddress!;
      _editableAddressController.text = widget.initialAddress!;
    }
    
    if (mapProvider.selectedAddress != null) {
      _editableAddressController.text = mapProvider.selectedAddress!;
    }

    if (widget.initialAddress == null && widget.initialLocation == null) {
      _loadSavedProfileLocation();
    }
  }

  void _loadSavedProfileLocation() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final session = await UserService.getSavedSession();
      if (session != null && mounted) {
        final id = session['id'] as int?;
        final email = session['email'] as String?;
        final profile = await UserService.getProfile(userId: id, email: email);
        if (profile != null && profile['success'] == true) {
          final location = profile['location'];
          if (location != null) {
            final lat = double.tryParse(location['latitud'] ?? '') ?? 
                (location['latitud'] is num ? (location['latitud'] as num).toDouble() : null);
            final lng = double.tryParse(location['longitud'] ?? '') ?? 
                (location['longitud'] is num ? (location['longitud'] as num).toDouble() : null);
            final dir = location['direccion'] as String?;
            
            final mapProvider = Provider.of<MapProvider>(context, listen: false);
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

  void _onSearch(String query) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    if (query.length >= 3) {
      mapProvider.searchAddress(query);
    }
  }

  void _onSearchResultTap(NominatimResult result) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    mapProvider.selectSearchResult(result);
    _searchController.text = result.getFormattedAddress();
    _editableAddressController.text = result.getFormattedAddress();
    _searchFocusNode.unfocus();
  }

  void _onMapMoveStart() {
    _mapMoveTimer?.cancel();
    _animationController.forward();
  }

  void _onMapMoveEnd() {
    _mapMoveTimer?.cancel();
    _mapMoveTimer = Timer(const Duration(milliseconds: 150), () {
      _animationController.reverse();
    });
  }

  void _handleMapMovedDebounced(LatLng center) {
    _moveDebounce?.cancel();
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    _moveDebounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        await mapProvider.selectLocation(center);
        if (mounted) {
          setState(() {
            _editableAddressController.text = mapProvider.selectedAddress ?? _editableAddressController.text;
            _searchController.text = _editableAddressController.text;
          });
        }
      } catch (_) {}
    });
  }

  void _saveLocation() async {
    final newAddress = _editableAddressController.text.trim();
    if (newAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dirección vacía'))
      );
      return;
    }

    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    
    final found = await mapProvider.geocodeAndSelect(newAddress);
    if (!found && mapProvider.selectedLocation != null) {
      await mapProvider.selectLocation(mapProvider.selectedLocation!);
    }

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
      setState(() {
        _confirmed = true;
      });
      _showConfirmedSnack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar en el servidor'))
      );
    }
  }

  void _showConfirmedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ubicación guardada exitosamente',
                style: TextStyle(color: Colors.white)
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Mapa con bordes redondeados
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: OSMMapWidget(
                      initialLocation: widget.initialLocation,
                      interactive: true,
                      onLocationSelected: (location) async {
                        _mapCenterCache = location;
                        await mapProvider.selectLocation(location);
                        _editableAddressController.text = mapProvider.selectedAddress ?? _editableAddressController.text;
                        _searchController.text = _editableAddressController.text;
                      },
                      onMapMoved: (center) {
                        _mapCenterCache = center;
                        _handleMapMovedDebounced(center);
                      },
                      onMapMoveStart: _onMapMoveStart,
                      onMapMoveEnd: _onMapMoveEnd,
                      showMarkers: false,
                    ),
                  ),
                ),
              ),
            ),

            // Barra de búsqueda con glass effect
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: Colors.grey[850]!.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                    color: _isSearchFocused 
                      ? Color(0xFF39FF14).withOpacity(0.6)
                      : Colors.white12,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: _isSearchFocused 
                            ? const Color(0xFF39FF14)
                            : Colors.white54,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _onSearch,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Buscar dirección...',
                              hintStyle: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Colors.white54,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                mapProvider.clearSearch();
                                _searchFocusNode.unfocus();
                              },
                              splashRadius: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Marcador central con animación
            Center(
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Círculo decorativo superior
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
                          
                          // Línea vertical
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
                          
                          // Punto de selección exacto
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
                    );
                  },
                ),
              ),
            ),

            // Tarjeta inferior con efecto glass
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo de dirección editable
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[850]!.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        controller: _editableAddressController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Color(0xFF39FF14),
                          ),
                          hintText: 'Dirección seleccionada...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Estado de confirmación
                    if (_confirmed)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.greenAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ubicación guardada exitosamente',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Botones de acción
                    if (!_confirmed)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF39FF14),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                shadowColor: Color(0xFF39FF14).withOpacity(0.3),
                              ),
                              child: const Text(
                                'Guardar ubicación',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.grey[800]!.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: IconButton(
                              onPressed: () {
                                mapProvider.clearSelection();
                                _editableAddressController.clear();
                                _searchController.clear();
                                setState(() {
                                  _confirmed = false;
                                });
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 22,
                              ),
                              style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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

            // Resultados de búsqueda con diseño glass
            if (mapProvider.searchResults.isNotEmpty)
              Positioned(
                top: 80,
                left: 20,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850]!.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: mapProvider.searchResults.length,
                          itemBuilder: (context, index) {
                            final result = mapProvider.searchResults[index];
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800]!.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: const Color(0xFF39FF14),
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  result.getFormattedAddress(),
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                                onTap: () => _onSearchResultTap(result),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _editableAddressController.dispose();
    _searchFocusNode.dispose();
    _mapMoveTimer?.cancel();
    _moveDebounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}