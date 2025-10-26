import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../../../global/services/mapbox_service.dart';
import 'select_destination_screen.dart';

/// Modelo para cotización del viaje
class TripQuote {
  final double distanceKm;
  final int durationMinutes;
  final double basePrice;
  final double distancePrice;
  final double timePrice;
  final double surchargePrice;
  final double totalPrice;
  final String periodType; // 'normal', 'hora_pico', 'nocturno'
  final double surchargePercentage;
  
  TripQuote({
    required this.distanceKm,
    required this.durationMinutes,
    required this.basePrice,
    required this.distancePrice,
    required this.timePrice,
    required this.surchargePrice,
    required this.totalPrice,
    required this.periodType,
    required this.surchargePercentage,
  });
  
  String get formattedTotal => '\$${totalPrice.toStringAsFixed(0)}';
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
  String get formattedDuration => '$durationMinutes min';
}

/// Segunda pantalla - Preview del viaje con mapa y cotización
/// Muestra el mapa con la ruta, información del viaje y precio calculado
class TripPreviewScreen extends StatefulWidget {
  final SimpleLocation origin;
  final SimpleLocation destination;
  final String vehicleType;
  
  const TripPreviewScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.vehicleType,
  });

  @override
  State<TripPreviewScreen> createState() => _TripPreviewScreenState();
}

class _TripPreviewScreenState extends State<TripPreviewScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  MapboxRoute? _route;
  TripQuote? _quote;
  bool _isLoadingRoute = true;
  bool _isLoadingQuote = true;
  String? _errorMessage;
  
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadRouteAndQuote();
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _loadRouteAndQuote() async {
    setState(() {
      _isLoadingRoute = true;
      _isLoadingQuote = true;
      _errorMessage = null;
    });
    
    try {
      // Obtener ruta de Mapbox
      final route = await MapboxService.getRoute(
        waypoints: [
          widget.origin.toLatLng(),
          widget.destination.toLatLng(),
        ],
      );
      
      if (route == null) {
        throw Exception('No se pudo calcular la ruta');
      }
      
      setState(() {
        _route = route;
        _isLoadingRoute = false;
      });
      
      // Ajustar el mapa para mostrar la ruta completa
      _fitMapToRoute();
      
      // Calcular cotización (por ahora localmente, luego será desde el backend)
      final quote = _calculateQuote(route);
      
      setState(() {
        _quote = quote;
        _isLoadingQuote = false;
      });
      
      // Animar la aparición del panel de detalles
      await Future.delayed(const Duration(milliseconds: 500));
      _slideAnimationController.forward();
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingRoute = false;
        _isLoadingQuote = false;
      });
    }
  }

  void _fitMapToRoute() {
    if (_route == null) return;
    
    // Encontrar los límites de la ruta
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;
    
    for (var point in _route!.geometry) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    
    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
    
    // Ajustar el mapa con padding
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  /// Calcular cotización localmente (temporal)
  /// TODO: Mover esta lógica al backend
  TripQuote _calculateQuote(MapboxRoute route) {
    final hour = DateTime.now().hour;
    final distanceKm = route.distanceKm;
    final durationMinutes = route.durationMinutes.ceil();
    
    // Configuración según tipo de vehículo (estos valores vendrán del backend)
    final config = _getVehicleConfig(widget.vehicleType);
    
    // Precios base
    final basePrice = config['tarifa_base']!;
    final distancePrice = distanceKm * config['costo_por_km']!;
    final timePrice = durationMinutes * config['costo_por_minuto']!;
    
    // Determinar período y recargo
    String periodType = 'normal';
    double surchargePercentage = 0.0;
    
    if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) {
      periodType = 'hora_pico';
      surchargePercentage = config['recargo_hora_pico']!;
    } else if (hour >= 22 || hour <= 6) {
      periodType = 'nocturno';
      surchargePercentage = config['recargo_nocturno']!;
    }
    
    final subtotal = basePrice + distancePrice + timePrice;
    final surchargePrice = subtotal * (surchargePercentage / 100);
    final total = subtotal + surchargePrice;
    
    // Aplicar tarifa mínima
    final finalTotal = total < config['tarifa_minima']! ? config['tarifa_minima']! : total;
    
    return TripQuote(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      basePrice: basePrice,
      distancePrice: distancePrice,
      timePrice: timePrice,
      surchargePrice: surchargePrice,
      totalPrice: finalTotal,
      periodType: periodType,
      surchargePercentage: surchargePercentage,
    );
  }

  Map<String, double> _getVehicleConfig(String vehicleType) {
    // Valores de ejemplo - estos vendrán de la tabla configuracion_precios
    switch (vehicleType) {
      case 'moto':
        return {
          'tarifa_base': 4000.0,
          'costo_por_km': 2000.0,
          'costo_por_minuto': 250.0,
          'tarifa_minima': 6000.0,
          'recargo_hora_pico': 15.0,
          'recargo_nocturno': 20.0,
        };
      case 'carro':
        return {
          'tarifa_base': 6000.0,
          'costo_por_km': 3000.0,
          'costo_por_minuto': 400.0,
          'tarifa_minima': 9000.0,
          'recargo_hora_pico': 20.0,
          'recargo_nocturno': 25.0,
        };
      case 'moto_carga':
        return {
          'tarifa_base': 5000.0,
          'costo_por_km': 2500.0,
          'costo_por_minuto': 300.0,
          'tarifa_minima': 7500.0,
          'recargo_hora_pico': 15.0,
          'recargo_nocturno': 20.0,
        };
      case 'carro_carga':
        return {
          'tarifa_base': 8000.0,
          'costo_por_km': 3500.0,
          'costo_por_minuto': 450.0,
          'tarifa_minima': 12000.0,
          'recargo_hora_pico': 20.0,
          'recargo_nocturno': 25.0,
        };
      default:
        return {
          'tarifa_base': 4000.0,
          'costo_por_km': 2000.0,
          'costo_por_minuto': 250.0,
          'tarifa_minima': 6000.0,
          'recargo_hora_pico': 15.0,
          'recargo_nocturno': 20.0,
        };
    }
  }

  String _getVehicleName(String type) {
    switch (type) {
      case 'moto': return 'Moto';
      case 'carro': return 'Carro';
      case 'moto_carga': return 'Moto Carga';
      case 'carro_carga': return 'Carro Carga';
      default: return 'Vehículo';
    }
  }

  IconData _getVehicleIcon(String type) {
    switch (type) {
      case 'moto': return Icons.two_wheeler;
      case 'carro': return Icons.directions_car;
      case 'moto_carga': return Icons.delivery_dining;
      case 'carro_carga': return Icons.local_shipping;
      default: return Icons.two_wheeler;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Mapa
          _buildMap(),
          
          // Overlay superior con información
          _buildTopOverlay(),
          
          // Panel inferior con detalles y precio
          if (_quote != null) _buildBottomPanel(),
          
          // Indicador de carga
          if (_isLoadingRoute || _isLoadingQuote) _buildLoadingOverlay(),
          
          // Mensaje de error
          if (_errorMessage != null) _buildErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.origin.toLatLng(),
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        // Tiles de Mapbox
        TileLayer(
          urlTemplate: MapboxService.getTileUrl(style: 'streets-v12'),
          userAgentPackageName: 'com.example.ping_go',
        ),
        
        // Línea de la ruta
        if (_route != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _route!.geometry,
                strokeWidth: 5,
                color: Colors.blue,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
              ),
            ],
          ),
        
        // Marcadores de origen y destino
        MarkerLayer(
          markers: [
            // Origen
            Marker(
              point: widget.origin.toLatLng(),
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.my_location, color: Colors.white, size: 20),
              ),
            ),
            // Destino
            Marker(
              point: widget.destination.toLatLng(),
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.place, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón de regresar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Detalle del viaje',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Información de ubicaciones
              _buildLocationInfo(
                icon: Icons.circle,
                color: Colors.blue,
                text: widget.origin.address,
              ),
              const SizedBox(height: 8),
              _buildLocationInfo(
                icon: Icons.place,
                color: Colors.red,
                text: widget.destination.address,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag indicator
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Información principal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Tipo de vehículo y precio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getVehicleIcon(widget.vehicleType),
                                size: 32,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getVehicleName(widget.vehicleType),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_quote!.formattedDistance} • ${_quote!.formattedDuration}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            _quote!.formattedTotal,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Recargo si aplica
                      if (_quote!.surchargePercentage > 0)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _quote!.periodType == 'nocturno'
                                    ? Icons.nightlight_round
                                    : Icons.trending_up,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _quote!.periodType == 'nocturno'
                                      ? 'Tarifa nocturna (+${_quote!.surchargePercentage.toInt()}%)'
                                      : 'Hora pico (+${_quote!.surchargePercentage.toInt()}%)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Botón para ver desglose
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showDetails = !_showDetails;
                          });
                        },
                        icon: Icon(
                          _showDetails ? Icons.expand_less : Icons.expand_more,
                        ),
                        label: const Text('Ver desglose de precio'),
                      ),
                      
                      // Desglose de precios
                      if (_showDetails) _buildPriceBreakdown(),
                      
                      const SizedBox(height: 16),
                      
                      // Botón de confirmar
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _confirmTrip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Solicitar viaje',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPriceRow('Tarifa base', _quote!.basePrice),
          _buildPriceRow('Distancia (${_quote!.formattedDistance})', _quote!.distancePrice),
          _buildPriceRow('Tiempo (${_quote!.formattedDuration})', _quote!.timePrice),
          if (_quote!.surchargePrice > 0)
            _buildPriceRow('Recargo', _quote!.surchargePrice, isHighlight: true),
          const Divider(height: 24),
          _buildPriceRow('Total', _quote!.totalPrice, isBold: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.orange[700] : Colors.grey[700],
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.orange[700] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Calculando ruta...',
                style: TextStyle(
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

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                  ElevatedButton(
                    onPressed: _loadRouteAndQuote,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmTrip() {
    // TODO: Implementar lógica de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Solicitando viaje de ${_quote!.formattedTotal}...'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Por ahora solo mostrar un diálogo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Viaje solicitado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehículo: ${_getVehicleName(widget.vehicleType)}'),
            Text('Distancia: ${_quote!.formattedDistance}'),
            Text('Tiempo estimado: ${_quote!.formattedDuration}'),
            Text('Costo total: ${_quote!.formattedTotal}'),
            const SizedBox(height: 16),
            const Text(
              'Buscando conductor disponible...',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver a pantalla anterior
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
