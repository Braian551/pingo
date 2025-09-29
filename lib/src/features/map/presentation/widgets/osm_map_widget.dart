import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';

class OSMMapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final bool interactive;
  final Function(LatLng)? onLocationSelected;
  final Function(LatLng)? onMapMoved; // Notifica el centro actual del mapa
  final bool showMarkers;

  const OSMMapWidget({
    super.key,
    this.initialLocation,
    this.interactive = true,
    this.onLocationSelected,
    this.onMapMoved,
    this.showMarkers = true,
  });

  @override
  State<OSMMapWidget> createState() => _OSMMapWidgetState();
}

class _OSMMapWidgetState extends State<OSMMapWidget> {
  final MapController _mapController = MapController();
  LatLng? _currentCenter;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Si el provider tiene una selectedLocation, centrar el mapa en ella
    final mapProvider = Provider.of<MapProvider>(context);
    final selected = mapProvider.selectedLocation;
    if (selected != null && (_currentCenter == null || _currentCenter != selected)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(selected, 16.0);
          _currentCenter = selected;
        } catch (_) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentCenter ?? const LatLng(4.6097, -74.0817), // Bogotá por defecto
        initialZoom: 13.0,
        maxZoom: 18.0,
        minZoom: 3.0,
        interactionOptions: InteractionOptions(
          flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onTap: widget.interactive ? _handleMapTap : null,
        onPositionChanged: (position, hasGesture) {
          if (hasGesture) {
            _currentCenter = position.center;
            if (widget.onMapMoved != null && position.center != null) {
              widget.onMapMoved!(position.center!);
            }
          }
        },
      ),
      children: [
        // Capa de tiles de OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.pingo.app',
          subdomains: const ['a', 'b', 'c'],
        ),
        
        // Marcadores opcionales (puedes ocultarlos para mostrar sólo el pin centrado)
        if (widget.showMarkers) ...[
          if (mapProvider.selectedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: mapProvider.selectedLocation!,
                  width: 40.0,
                  height: 40.0,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40.0,
                  ),
                ),
              ],
            ),

          if (mapProvider.currentLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: mapProvider.currentLocation!,
                  width: 30.0,
                  height: 30.0,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 30.0,
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    
    mapProvider.selectLocation(point);
    
    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(point);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}