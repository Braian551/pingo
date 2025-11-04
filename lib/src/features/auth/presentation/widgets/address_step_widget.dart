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
    
    // Animación de pulso para el pin - solo cuando no se está moviendo
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Iniciar la animación de pulso solo si no se está moviendo inicialmente
    if (!_isMapMoving) {
      _pulseAnimationController.repeat(reverse: true);
    }
  }

  void _onSearchFocusChange() {
    final wasFocused = _isSearchFocused;
    final isFocused = _searchFocusNode.hasFocus;
    
    if (wasFocused != isFocused) {
      setState(() {
        _isSearchFocused = isFocused;
      });
      
      // Usar post frame callback para evitar conflictos con el layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _searchFocusNode.hasFocus == isFocused) { // Verificar que aún sea válido
          // Cancelar búsquedas pendientes cuando se pierde el foco
          if (!isFocused) {
            _searchDebounce?.cancel();
            // Limpiar resultados de búsqueda cuando se pierde el foco
            final prov = Provider.of<MapProvider>(context, listen: false);
            prov.clearSearch();
          }
        }
      });
    }
  }

  // Método para manejar taps fuera del campo de búsqueda
  void _onTapOutside() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _moveDebounce?.cancel();
    _searchDebounce?.cancel();
    _mapMoveTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pinAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _onSearch(String q) async {
    // Cancelar búsqueda anterior
    _searchDebounce?.cancel();
    
    if (q.trim().isEmpty) {
      final prov = Provider.of<MapProvider>(context, listen: false);
      prov.clearSearch();
      return;
    }
    
    if (q.length > 2) {
      // Aumentar debounce a 800ms para reducir llamadas
      _searchDebounce = Timer(const Duration(milliseconds: 800), () {
        if (mounted) {
          final prov = Provider.of<MapProvider>(context, listen: false);
          
          if (_mapCenterCache != null && prov.currentLocation == null) {
            prov.setCurrentLocation(_mapCenterCache);
          }
          
          prov.searchAddress(q.trim());
        }
      });
    } else {
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

    // Guardar temporalmente las coordenadas
    _tempLat = result.lat;
    _tempLon = result.lon;

    // Ocultar teclado y perder foco
    _searchFocusNode.unfocus();
  }

  bool _confirmed = false;
  Timer? _mapMoveTimer;
  
  // Variables temporales para guardar la ubicación hasta que se confirme
  double? _tempLat;
  double? _tempLon;

  void _onMapMoveStart() {
    setState(() {
      _isMapMoving = true;
    });
    _mapMoveTimer?.cancel();
    _pinAnimationController.forward();
    _pulseAnimationController.stop(); // Detener pulso durante movimiento
  }

  void _onMapMoveEnd() {
    _mapMoveTimer?.cancel();
    _mapMoveTimer = Timer(const Duration(milliseconds: 200), () {
      setState(() {
        _isMapMoving = false;
      });
      _pinAnimationController.reverse();
      _pulseAnimationController.repeat(reverse: true); // Reiniciar pulso
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

    // Mostrar indicador de carga
    setState(() {
      _confirmed = true;
    });

    // AHORA SÍ hacer el reverse geocoding al confirmar
    final location = LatLng(lat, lon);
    prov.selectLocation(location).then((_) {
      if (!mounted) return;
      
      final address = prov.selectedAddress ?? (_searchController.text.isEmpty 
          ? 'Lat: ${lat.toStringAsFixed(6)}, Lon: ${lon.toStringAsFixed(6)}'
          : _searchController.text);
      final city = prov.selectedCity;
      final state = prov.selectedState;

      final data = {
        'lat': lat,
        'lon': lon,
        'address': address,
        'city': city,
        'state': state,
      };

      widget.addressController.text = address;
      widget.onLocationSelected(data);

      _showConfirmedSnack();

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && widget.onConfirmed != null) {
          widget.onConfirmed!();
        }
      });
    }).catchError((error) {
      // Si falla el reverse geocoding, usar coordenadas
      final address = 'Lat: ${lat.toStringAsFixed(6)}, Lon: ${lon.toStringAsFixed(6)}';
      final data = {
        'lat': lat,
        'lon': lon,
        'address': address,
        'city': null,
        'state': null,
      };

      widget.addressController.text = address;
      widget.onLocationSelected(data);

      _showConfirmedSnack();

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && widget.onConfirmed != null) {
          widget.onConfirmed!();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, prov, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        final availableHeight = screenHeight - keyboardHeight;

        return SizedBox(
          height: availableHeight,
          child: GestureDetector(
            onTap: _onTapOutside,
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: [
          // Mapa a pantalla completa sin márgenes
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: _isSearchFocused, // Absorber toques cuando el teclado está abierto
              child: RepaintBoundary(
                child: OSMMapWidget(
                  initialLocation: prov.selectedLocation,
                  interactive: !_isSearchFocused, // Desactivar interacción cuando el teclado está abierto
                  onLocationSelected: (loc) async {
                    _mapCenterCache = loc;
                    prov.setCurrentLocation(loc);
                    
                    // Solo guardar coordenadas, NO hacer reverse geocoding aquí
                    _tempLat = loc.latitude;
                    _tempLon = loc.longitude;
                  },
                  onMapMoved: _isSearchFocused ? null : (center) {
                    _mapCenterCache = center;
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

          // Barra de búsqueda estilo Uber - fija arriba
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSearchFocused 
                      ? const Color(0xFFFFFF00)
                      : Colors.grey.shade300,
                    width: _isSearchFocused ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isSearchFocused ? 0.3 : 0.15),
                      blurRadius: _isSearchFocused ? 24 : 12,
                      offset: Offset(0, _isSearchFocused ? 8 : 4),
                    ),
                    if (_isSearchFocused)
                      BoxShadow(
                        color: const Color(0xFFFFFF00).withOpacity(0.3),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isSearchFocused 
                              ? const Color(0xFFFFFF00).withOpacity(0.15)
                              : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: _isSearchFocused 
                              ? const Color(0xFFFFFF00)
                              : Colors.grey.shade600,
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
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar dirección...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
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
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey.shade700,
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
          ),

          // Pin de ubicación estilo Uber mejorado
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
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Pulso animado
                            if (!_isMapMoving)
                              Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFF00).withOpacity(0.25),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            
                            // Pin principal más grande
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFFFF00).withOpacity(0.3),
                                    blurRadius: 24,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFFFFFF00),
                                        const Color(0xFFFFDD00),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFFF00).withOpacity(0.6),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Punto de referencia
                            Positioned(
                              bottom: -10,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Sombra mejorada
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isMapMoving ? 24 : 32,
                          height: _isMapMoving ? 6 : 8,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(_isMapMoving ? 0.2 : 0.3),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
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

          // Panel inferior estilo Uber - más compacto y elegante
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo de dirección mejorado estilo Uber
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFFFF00),
                                  const Color(0xFFFFDD00),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFFF00).withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tu ubicación',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.addressController.text.isEmpty 
                                    ? 'Selecciona en el mapa' 
                                    : widget.addressController.text,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Botones de acción
                    if (!_confirmed)
                      Row(
                        children: [
                          // Botón de confirmar (principal) - estilo Uber
                          Expanded(
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFFFF00),
                                    const Color(0xFFFFDD00),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFFF00).withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    LatLng? center = _mapCenterCache ?? prov.selectedLocation;
                                    if (center != null && prov.selectedAddress == null) {
                                      prov.selectLocation(center);
                                    }
                                    _onConfirm(center);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.black,
                                          size: 22,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Confirmar ubicación',
                                          style: TextStyle(
                                            color: Colors.black,
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
                            ),
                          ),
                        ],
                      )
                    else
                      // Indicador de confirmación
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFFF00).withOpacity(0.2),
                              const Color(0xFFFFDD00).withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFFF00).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFFFF00),
                                    Color(0xFFFFDD00),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                '¡Ubicación confirmada!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
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
          ),

          // Resultados de búsqueda estilo Uber con fondo blanco
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
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
                          color: Colors.grey.withOpacity(0.15),
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
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    // Icono de ubicación
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Colors.black87,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    
                                    // Texto de la dirección
                                    Expanded(
                                      child: Text(
                                        r.getFormattedAddress(),
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    
                                    // Icono de flecha
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.grey.withOpacity(0.4),
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
      ),
    );
      },
    );
  }

  void _handleMapMovedDebounced(LatLng? center) {
    // NO HACER REVERSE GEOCODING durante el movimiento
    // Solo actualizar el centro del mapa sin bloquear el UI
    if (_isSearchFocused || center == null || !mounted) return;
    
    _moveDebounce?.cancel();
    
    // Solo guardar las coordenadas, NO hacer reverse geocoding
    _moveDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      setState(() {
        _tempLat = center.latitude;
        _tempLon = center.longitude;
        // NO actualizar el texto de búsqueda durante el movimiento
      });
    });
  }
}