import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/map_provider.dart';
import '../widgets/osm_map_widget.dart';
import '../widgets/location_search_widget.dart';

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

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _editableAddressController = TextEditingController();
  VoidCallback? _providerListener;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  // Do not listen for edits here; editing the address should not trigger geocoding.
  }

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
        actions: [
          if (widget.showConfirmButton)
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFF39FF14)),
              onPressed: mapProvider.selectedLocation != null
                  ? () {
                      Navigator.pop(context, {
                        'location': mapProvider.selectedLocation,
                        'address': mapProvider.selectedAddress,
                      });
                    }
                  : null,
            ),
        ],
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
    super.dispose();
  }

  // Editing the selected-address field does not trigger geocoding.
}