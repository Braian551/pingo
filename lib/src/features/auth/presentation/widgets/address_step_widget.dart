import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:ping_go/src/features/map/presentation/widgets/osm_map_widget.dart';
import 'package:ping_go/src/features/map/providers/map_provider.dart';
import 'package:ping_go/src/global/services/nominatim_service.dart';

/// Widget independiente para seleccionar dirección durante el registro.
/// Expone callbacks para devolver la dirección seleccionada al padre.
class AddressStepWidget extends StatefulWidget {
  final TextEditingController addressController;
  final ValueChanged<Map<String, dynamic>> onLocationSelected; // {'lat','lon','address','city','state'}
  final VoidCallback? onConfirmed; // Notifica al padre que avance al siguiente paso

  const AddressStepWidget({
    super.key,
    required this.addressController,
    required this.onLocationSelected,
    this.onConfirmed,
  });

  @override
  State<AddressStepWidget> createState() => _AddressStepWidgetState();
}

class _AddressStepWidgetState extends State<AddressStepWidget> {
  final TextEditingController _searchController = TextEditingController();
  LatLng? _mapCenterCache;
  Timer? _moveDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.addressController.text;
  // No automatic geocoding on manual edits: map pin movement will update the field.
  }

  @override
  void dispose() {
  _moveDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Manual edits to the address field do not trigger geocoding. The map/pin movement
  // will update this field via the OSMMapWidget callbacks instead.

  void _onSearch(String q) async {
    final prov = Provider.of<MapProvider>(context, listen: false);
    prov.searchAddress(q);
  }

  void _onResultTap(NominatimResult result) {
    final prov = Provider.of<MapProvider>(context, listen: false);
    prov.selectSearchResult(result);

    // Actualizar el campo de dirección local
    final formatted = result.getFormattedAddress();
    widget.addressController.text = formatted;

    // Notificar al padre (no confirmar aún, solo preselección)
    widget.onLocationSelected({
      'lat': result.lat,
      'lon': result.lon,
      'address': formatted,
      'city': result.getCity(),
      'state': result.getState(),
    });
  }

  // removed unused _onMapTap - map taps are handled by OSMMapWidget.onLocationSelected

  bool _confirmed = false;

  void _showConfirmedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Ubicación seleccionada', style: TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 900),
      ),
    );
  }

  void _onConfirm(LatLng? center) {
    final prov = Provider.of<MapProvider>(context, listen: false);

    final lat = center?.latitude ?? prov.selectedLocation?.latitude;
    final lon = center?.longitude ?? prov.selectedLocation?.longitude;

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una ubicación antes de confirmar')));
      return;
    }

    final data = {
      'lat': lat,
      'lon': lon,
      'address': widget.addressController.text,
      'city': prov.selectedCity,
      'state': prov.selectedState,
    };

    widget.onLocationSelected(data);

    // Mostrar feedback visual y avanzar al siguiente paso si se provee callback
    setState(() {
      _confirmed = true;
    });
    _showConfirmedSnack();

    // Ligeramente esperar la animación/feedback y notificar al padre para avanzar
    Future.delayed(const Duration(milliseconds: 600), () {
      if (widget.onConfirmed != null) widget.onConfirmed!();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<MapProvider>(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.84,
      child: Stack(
        children: [
          // Mapa a pantalla completa dentro del contenedor
          // Mapa con bordes redondeados
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8, offset: const Offset(0,4))],
                  ),
                  child: OSMMapWidget(
                    initialLocation: prov.selectedLocation,
                    interactive: true,
                    onLocationSelected: (loc) async {
                      // Actualizar caché del centro y realizar reverse
                      _mapCenterCache = loc;
                      await prov.selectLocation(loc);
                      // rellenar input con la dirección obtenida
                      widget.addressController.text = prov.selectedAddress ?? widget.addressController.text;
                    },
                    onMapMoved: (center) {
                      _mapCenterCache = center;
                      // Debounce reverse geocoding while the user moves the map
                      _handleMapMovedDebounced(center);
                    },
                    showMarkers: false,
                  ),
                ),
              ),
            ),
          ),

          // Floating search at top
          // Dark search bar
          Positioned(
            top: 16,
            left: 24,
            right: 24,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => _onSearch(v),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Buscar dirección',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: Colors.white54),
                        ),
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<MapProvider>(context, listen: false).clearSearch();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center pin (Uber style motorcycle)
          Center(
            child: IgnorePointer(
              ignoring: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.motorcycle, size: 64, color: Colors.redAccent, shadows: [const Shadow(color: Colors.black45, blurRadius: 8)]),
                  const SizedBox(height: 6),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating bottom card (dark style) with address preview and confirm
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Address text field (editable) - allows manual entry and geocoding
                  TextField(
                    controller: widget.addressController,
                    readOnly: false,
                    // Editable but DOES NOT trigger geocoding here. The top search bar is used for geocoding.
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent),
                      hintText: 'Selecciona una ubicación',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[850],
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_confirmed)
                    Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.greenAccent),
                        SizedBox(width: 8),
                        Expanded(child: Text('Ha sido seleccionada la ubicación', style: TextStyle(color: Colors.white))),
                      ],
                    ),

                  if (!_confirmed)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Confirm using the cached map center or provider selection
                              LatLng? center = _mapCenterCache ?? prov.selectedLocation;
                              // If we have a center but no reverse address, try reverse now
                              if (center != null && prov.selectedAddress == null) {
                                prov.selectLocation(center);
                                widget.addressController.text = prov.selectedAddress ?? widget.addressController.text;
                              }
                              // Fill address field and notify parent
                              if (prov.selectedAddress != null) {
                                widget.addressController.text = prov.selectedAddress!;
                              }
                              _onConfirm(center);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF39FF14),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Confirmar ubicación'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: OutlinedButton(
                              onPressed: () {
                                // Reset selection
                                Provider.of<MapProvider>(context, listen: false).clearSelection();
                                widget.addressController.clear();
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: BorderSide(color: Colors.white12),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Icon(Icons.close, color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Search results dropdown (if any)
          if (prov.searchResults.isNotEmpty)
            Positioned(
              top: 72,
              left: 24,
              right: 24,
              child: Material(
                color: Colors.transparent,
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: prov.searchResults.length,
                      itemBuilder: (context, i) {
                        final r = prov.searchResults[i];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.white70),
                          title: Text(r.getFormattedAddress(), style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            _onResultTap(r);
                            // After tap, hide results (provider already clears)
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleMapMovedDebounced(LatLng? center) {
    if (center == null) return;
    // Cancel previous
    _moveDebounce?.cancel();
    final prov = Provider.of<MapProvider>(context, listen: false);
    _moveDebounce = Timer(const Duration(milliseconds: 700), () async {
      try {
        await prov.selectLocation(center);
        // Update input with the reverse geocoded address
        setState(() {
          widget.addressController.text = prov.selectedAddress ?? widget.addressController.text;
        });
      } catch (_) {
        // ignore errors silently for now
      }
    });
  }
}
