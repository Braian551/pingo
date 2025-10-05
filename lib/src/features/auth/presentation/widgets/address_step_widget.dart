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

class _AddressStepWidgetState extends State<AddressStepWidget> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  LatLng? _mapCenterCache;
  Timer? _moveDebounce;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  
  // Animación solo para cuando el mapa se mueve
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.addressController.text;
    _searchFocusNode.addListener(_onSearchFocusChange);
    
    // Configurar controlador de animaciones solo para rebote
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Animación de rebote solo durante el movimiento
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: -6.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _moveDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearch(String q) async {
    if (q.length > 2) {
      final prov = Provider.of<MapProvider>(context, listen: false);
      prov.searchAddress(q);
    }
  }

  void _onResultTap(NominatimResult result) {
    final prov = Provider.of<MapProvider>(context, listen: false);
    prov.selectSearchResult(result);

    // Actualizar el campo de dirección local
    final formatted = result.getFormattedAddress();
    widget.addressController.text = formatted;
    _searchController.text = formatted;

    // Notificar al padre (no confirmar aún, solo preselección)
    widget.onLocationSelected({
      'lat': result.lat,
      'lon': result.lon,
      'address': formatted,
      'city': result.getCity(),
      'state': result.getState(),
    });

    // Ocultar teclado y perder foco
    _searchFocusNode.unfocus();
  }

  bool _confirmed = false;
  bool _isMapMoving = false;
  Timer? _mapMoveTimer;

  void _onMapMoveStart() {
    setState(() {
      _isMapMoving = true;
    });
    _mapMoveTimer?.cancel();
    // Iniciar animación de rebote
    _animationController.forward();
  }

  void _onMapMoveEnd() {
    _mapMoveTimer?.cancel();
    _mapMoveTimer = Timer(const Duration(milliseconds: 150), () {
      setState(() {
        _isMapMoving = false;
      });
      // Revertir animación de rebote
      _animationController.reverse();
    });
  }

  void _showConfirmedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Ubicación seleccionada', style: TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _onConfirm(LatLng? center) {
    final prov = Provider.of<MapProvider>(context, listen: false);

    final lat = center?.latitude ?? prov.selectedLocation?.latitude;
    final lon = center?.longitude ?? prov.selectedLocation?.longitude;

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona una ubicación antes de confirmar'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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
          // Mapa con bordes redondeados y efecto de profundidad mejorado
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
                    initialLocation: prov.selectedLocation,
                    interactive: true,
                    onLocationSelected: (loc) async {
                      _mapCenterCache = loc;
                      await prov.selectLocation(loc);
                      widget.addressController.text = prov.selectedAddress ?? widget.addressController.text;
                      _searchController.text = widget.addressController.text;
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

          // Search bar moderna con efectos de glassmorphism
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
                          ? Color(0xFF39FF14)
                          : Colors.white54,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearch,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Buscar dirección...',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              Provider.of<MapProvider>(context, listen: false).clearSearch();
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

          // Marcador simple y limpio con animación solo al mover el mapa
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
                        // Círculo decorativo en la parte superior
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black,
                              width: 2,
                            ),
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
                        
                        // Punto de selección (la punta es el punto exacto)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
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

          // Tarjeta inferior moderna con efecto glass
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
                border: Border.all(
                  color: Colors.white12,
                ),
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
                  // Campo de dirección con icono
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850]!.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: widget.addressController,
                      readOnly: false,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.location_on,
                          color: const Color.fromARGB(255, 91, 255, 82),
                        ),
                        hintText: 'Dirección seleccionada...',
                        hintStyle: TextStyle(
                          color: Colors.white54,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                          Icon(Icons.check_circle, color: Colors.greenAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ubicación confirmada',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!_confirmed)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              LatLng? center = _mapCenterCache ?? prov.selectedLocation;
                              if (center != null && prov.selectedAddress == null) {
                                prov.selectLocation(center);
                                widget.addressController.text = prov.selectedAddress ?? widget.addressController.text;
                              }
                              if (prov.selectedAddress != null) {
                                widget.addressController.text = prov.selectedAddress!;
                              }
                              _onConfirm(center);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF39FF14),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: Color(0xFF39FF14).withOpacity(0.3),
                            ),
                            child: Text(
                              'Confirmar ubicación',
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
                            border: Border.all(
                              color: Colors.white12,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Provider.of<MapProvider>(context, listen: false).clearSelection();
                              widget.addressController.clear();
                              _searchController.clear();
                            },
                            icon: Icon(
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
          if (prov.searchResults.isNotEmpty)
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
                    border: Border.all(
                      color: Colors.white12,
                    ),
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
                        itemCount: prov.searchResults.length,
                        itemBuilder: (context, i) {
                          final r = prov.searchResults[i];
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
                                  color: const Color.fromARGB(255, 31, 221, 6),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                r.getFormattedAddress(),
                                style: TextStyle(color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white54,
                                size: 16,
                              ),
                              onTap: () => _onResultTap(r),
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
        ],
      ),
    );
  }

  void _handleMapMovedDebounced(LatLng? center) {
    if (center == null) return;
    _moveDebounce?.cancel();
    final prov = Provider.of<MapProvider>(context, listen: false);
    _moveDebounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        await prov.selectLocation(center);
        setState(() {
          widget.addressController.text = prov.selectedAddress ?? widget.addressController.text;
          _searchController.text = widget.addressController.text;
        });
      } catch (_) {
        // ignore errors silently for now
      }
    });
  }
}