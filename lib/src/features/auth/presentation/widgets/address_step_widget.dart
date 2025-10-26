import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:ping_go/src/features/map/presentation/widgets/osm_map_widget.dart';
import 'package:ping_go/src/features/map/providers/map_provider.dart';
import 'package:ping_go/src/global/services/nominatim_service.dart';
import 'package:ping_go/src/widgets/snackbars/custom_snackbar.dart';

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

class _AddressStepWidgetState extends State<AddressStepWidget> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  LatLng? _mapCenterCache;
  Timer? _moveDebounce;
  Timer? _searchDebounce; // Debounce para búsqueda
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  
  // Controladores de animación mejorados
  late AnimationController _pinAnimationController;
  late AnimationController _pulseAnimationController;
  
  late Animation<double> _pinBounceAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isMapMoving = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.addressController.text;
    _searchFocusNode.addListener(_onSearchFocusChange);
    
    // Animación del pin al mover el mapa
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
    
    // Animación de pulso para el pin
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

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _moveDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pinAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _onSearch(String q) async {
    // Cancelar búsqueda anterior
    _searchDebounce?.cancel();
    
    if (q.length > 2) {
      // Esperar 500ms antes de buscar (debounce)
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        final prov = Provider.of<MapProvider>(context, listen: false);
        
        // Asegurarse de que el provider tenga la ubicación actual
        if (_mapCenterCache != null && prov.currentLocation == null) {
          prov.setCurrentLocation(_mapCenterCache);
        }
        
        // Buscar con el query
        prov.searchAddress(q);
      });
    } else {
      // Si el query es muy corto, limpiar resultados
      final prov = Provider.of<MapProvider>(context, listen: false);
      prov.clearSearch();
    }
  }

  void _onResultTap(NominatimResult result) {
    final prov = Provider.of<MapProvider>(context, listen: false);
    prov.selectSearchResult(result);

    // Actualizar solo el campo de búsqueda visualmente
    final formatted = result.getFormattedAddress();
    _searchController.text = formatted;

    // Guardar temporalmente hasta confirmar
    _tempLat = result.lat;
    _tempLon = result.lon;
    _tempAddress = formatted;
    _tempCity = result.getCity();
    _tempState = result.getState();

    // Ocultar teclado y perder foco
    _searchFocusNode.unfocus();
  }

  bool _confirmed = false;
  Timer? _mapMoveTimer;
  
  // Variables temporales para guardar la ubicación hasta que se confirme
  double? _tempLat;
  double? _tempLon;
  String? _tempAddress;
  String? _tempCity;
  String? _tempState;

  void _onMapMoveStart() {
    setState(() {
      _isMapMoving = true;
    });
    _mapMoveTimer?.cancel();
    _pinAnimationController.forward();
  }

  void _onMapMoveEnd() {
    _mapMoveTimer?.cancel();
    _mapMoveTimer = Timer(const Duration(milliseconds: 200), () {
      setState(() {
        _isMapMoving = false;
      });
      _pinAnimationController.reverse();
    });
  }

  void _showConfirmedSnack() {
    CustomSnackbar.showSuccess(
      context,
      message: 'Ubicación seleccionada correctamente',
      duration: const Duration(milliseconds: 900),
    );
  }

  void _onConfirm(LatLng? center) {
    final prov = Provider.of<MapProvider>(context, listen: false);

    // Usar datos temporales si existen, sino usar el centro del mapa
    final lat = _tempLat ?? center?.latitude ?? prov.selectedLocation?.latitude;
    final lon = _tempLon ?? center?.longitude ?? prov.selectedLocation?.longitude;

    if (lat == null || lon == null) {
      CustomSnackbar.showWarning(
        context,
        message: 'Por favor, selecciona una ubicación antes de confirmar',
      );
      return;
    }

    // Preparar los datos finales
    final address = _tempAddress ?? prov.selectedAddress ?? _searchController.text;
    final city = _tempCity ?? prov.selectedCity;
    final state = _tempState ?? prov.selectedState;

    final data = {
      'lat': lat,
      'lon': lon,
      'address': address,
      'city': city,
      'state': state,
    };

    // SOLO AHORA notificar al padre con los datos confirmados
    widget.addressController.text = address;
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
                      // Actualizar la ubicación actual en el provider
                      prov.setCurrentLocation(loc);
                      await prov.selectLocation(loc);
                      // Solo actualizar el campo de búsqueda visualmente, NO el addressController del padre
                      _searchController.text = prov.selectedAddress ?? _searchController.text;
                      // Guardar temporalmente hasta confirmar
                      _tempLat = loc.latitude;
                      _tempLon = loc.longitude;
                      _tempAddress = prov.selectedAddress;
                      _tempCity = prov.selectedCity;
                      _tempState = prov.selectedState;
                    },
                    onMapMoved: (center) {
                      _mapCenterCache = center;
                      // Actualizar la ubicación actual en el provider
                      prov.setCurrentLocation(center);
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

          // Barra de búsqueda moderna con efecto glass y animaciones suaves
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSearchFocused 
                    ? const Color(0xFFFFFF00).withOpacity(0.8)
                    : Colors.white.withOpacity(0.15),
                  width: _isSearchFocused ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: _isSearchFocused ? 24 : 16,
                    offset: const Offset(0, 8),
                    spreadRadius: _isSearchFocused ? 2 : 0,
                  ),
                  if (_isSearchFocused)
                    BoxShadow(
                      color: const Color(0xFFFFFF00).withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.search_rounded,
                          color: _isSearchFocused 
                            ? const Color(0xFFFFFF00)
                            : Colors.white.withOpacity(0.6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearch,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar dirección...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: 1.0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withOpacity(0.7),
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                Provider.of<MapProvider>(context, listen: false).clearSearch();
                                _searchFocusNode.unfocus();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Pin de ubicación profesional estilo Uber con animaciones suaves
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
                        // Pin moderno inspirado en Uber
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Pulso animado de fondo (solo cuando no se mueve el mapa)
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
                            
                            // Indicador de punta (punto de referencia exacto)
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

          // Tarjeta inferior profesional con efecto glass
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _confirmed 
                    ? const Color(0xFFFFFF00).withOpacity(0.4)
                    : Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                    spreadRadius: 2,
                  ),
                  if (_confirmed)
                    BoxShadow(
                      color: const Color(0xFFFFFF00).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de dirección mejorado
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: TextField(
                      controller: widget.addressController,
                      readOnly: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      minLines: 1,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: const Color(0xFFFFFF00),
                            size: 22,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        hintText: 'Dirección seleccionada...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        filled: false,
                      ),
                    ),
                  ),
                  
                  // Indicador de estado confirmado
                  if (_confirmed)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFF00).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFFF00).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFF00),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Ubicación confirmada',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Botones de acción
                  if (!_confirmed)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          // Botón de confirmar (principal)
                          Expanded(
                            flex: 3,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: 1.0,
                              child: ElevatedButton(
                                onPressed: () {
                                  LatLng? center = _mapCenterCache ?? prov.selectedLocation;
                                  // Si hay una ubicación en el centro pero no se ha seleccionado dirección, hacerlo
                                  if (center != null && prov.selectedAddress == null) {
                                    prov.selectLocation(center);
                                  }
                                  // El _onConfirm se encargará de actualizar el addressController
                                  _onConfirm(center);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFFF00),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                  shadowColor: const Color(0xFFFFFF00).withOpacity(0.4),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Confirmar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Botón de limpiar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Provider.of<MapProvider>(context, listen: false).clearSelection();
                                widget.addressController.clear();
                                _searchController.clear();
                                setState(() {
                                  _confirmed = false;
                                });
                              },
                              icon: Icon(
                                Icons.refresh_rounded,
                                color: Colors.white.withOpacity(0.8),
                                size: 24,
                              ),
                              style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Resultados de búsqueda con diseño profesional
          if (prov.searchResults.isNotEmpty && _isSearchFocused)
            Positioned(
              top: 84,
              left: 20,
              right: 20,
              child: Material(
                color: Colors.transparent,
                elevation: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: prov.searchResults.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.08),
                          indent: 60,
                          endIndent: 20,
                        ),
                        itemBuilder: (context, i) {
                          final r = prov.searchResults[i];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _onResultTap(r),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    // Icono de ubicación
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
                                    
                                    // Texto de la dirección
                                    Expanded(
                                      child: Text(
                                        r.getFormattedAddress(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    
                                    // Icono de flecha
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.white.withOpacity(0.4),
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
          // Solo actualizar el campo de búsqueda visualmente, NO el addressController del padre
          _searchController.text = prov.selectedAddress ?? _searchController.text;
          // Guardar temporalmente hasta confirmar
          _tempLat = center.latitude;
          _tempLon = center.longitude;
          _tempAddress = prov.selectedAddress;
          _tempCity = prov.selectedCity;
          _tempState = prov.selectedState;
        });
      } catch (_) {
        // ignore errors silently for now
      }
    });
  }
}