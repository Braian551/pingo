import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../global/services/mapbox_service.dart';
import 'trip_preview_screen.dart';

/// Modelo simple para ubicaciones
class SimpleLocation {
  final double latitude;
  final double longitude;
  final String address;
  
  SimpleLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
  
  LatLng toLatLng() => LatLng(latitude, longitude);
}

/// Pantalla de selecciÃ³n de destino - Primera pantalla del flujo
/// Similar a DiDi: permite seleccionar origen y destino antes de ver el mapa
class SelectDestinationScreen extends StatefulWidget {
  const SelectDestinationScreen({super.key});

  @override
  State<SelectDestinationScreen> createState() => _SelectDestinationScreenState();
}

class _SelectDestinationScreenState extends State<SelectDestinationScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  
  SimpleLocation? _originLocation;
  SimpleLocation? _destinationLocation;
  Position? _currentPosition;
  
  bool _isLoadingCurrentLocation = false;
  bool _isSearchingOrigin = false;
  bool _isSearchingDestination = false;
  
  String _selectedVehicleType = 'moto';
  
  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'type': 'moto',
      'name': 'Moto',
      'icon': Icons.two_wheeler,
      'description': 'RÃ¡pido y econÃ³mico',
      'capacity': '1 pasajero',
    },
    {
      'type': 'carro',
      'name': 'Carro',
      'icon': Icons.directions_car,
      'description': 'CÃ³modo y espacioso',
      'capacity': '4 pasajeros',
    },
    {
      'type': 'moto_carga',
      'name': 'Moto Carga',
      'icon': Icons.delivery_dining,
      'description': 'Para paquetes pequeÃ±os',
      'capacity': 'Hasta 20kg',
    },
    {
      'type': 'carro_carga',
      'name': 'Carro Carga',
      'icon': Icons.local_shipping,
      'description': 'Para mudanzas y carga',
      'capacity': 'Hasta 500kg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);
    
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicaciÃ³n denegados');
        }
      }
      
      // Obtener posiciÃ³n actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Geocodificar usando Mapbox
      final place = await MapboxService.reverseGeocode(
        position: LatLng(position.latitude, position.longitude),
      );
      
      final address = place?.placeName ?? 'UbicaciÃ³n actual';
      
      setState(() {
        _currentPosition = position;
        _originLocation = SimpleLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
        );
        _originController.text = address;
        _isLoadingCurrentLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingCurrentLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicaciÃ³n: $e')),
        );
      }
    }
  }

  Future<void> _searchLocation(bool isOrigin) async {
    final controller = isOrigin ? _originController : _destinationController;
    final query = controller.text.trim();
    
    if (query.isEmpty) return;
    
    setState(() {
      if (isOrigin) {
        _isSearchingOrigin = true;
      } else {
        _isSearchingDestination = true;
      }
    });
    
    try {
      // Buscar lugares con Mapbox
      final results = await MapboxService.searchPlaces(
        query: query,
        proximity: _currentPosition != null 
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : null,
      );
      
      if (results.isEmpty) {
        throw Exception('No se encontraron resultados');
      }
      
      // Convertir a SimpleLocation
      final locations = results.map((place) => SimpleLocation(
        latitude: place.coordinates.latitude,
        longitude: place.coordinates.longitude,
        address: place.placeName,
      )).toList();
      
      // Mostrar resultados para que el usuario seleccione
      if (mounted) {
        final selected = await showModalBottomSheet<SimpleLocation>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildSearchResults(locations),
        );
        
        if (selected != null) {
          setState(() {
            if (isOrigin) {
              _originLocation = selected;
              _originController.text = selected.address;
            } else {
              _destinationLocation = selected;
              _destinationController.text = selected.address;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en bÃºsqueda: $e')),
        );
      }
    } finally {
      setState(() {
        if (isOrigin) {
          _isSearchingOrigin = false;
        } else {
          _isSearchingDestination = false;
        }
      });
    }
  }

  Widget _buildSearchResults(List<SimpleLocation> results) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Selecciona una ubicaciÃ³n',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: results.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final location = results[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(
                      location.address,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    onTap: () => Navigator.pop(context, location),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _continueToPreview() {
    if (_originLocation == null || _destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona origen y destino'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripPreviewScreen(
          origin: _originLocation!,
          destination: _destinationLocation!,
          vehicleType: _selectedVehicleType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Â¿A dÃ³nde vamos?',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SecciÃ³n de ubicaciones
                  _buildLocationSection(),
                  
                  const SizedBox(height: 32),
                  
                  // SecciÃ³n de tipo de vehÃ­culo
                  _buildVehicleTypeSection(),
                  
                  const SizedBox(height: 24),
                  
                  // InformaciÃ³n adicional
                  _buildInfoCards(),
                ],
              ),
            ),
          ),
          
          // BotÃ³n de continuar
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Origen
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _originController,
                    decoration: InputDecoration(
                      hintText: 'Punto de partida',
                      border: InputBorder.none,
                      suffixIcon: _isSearchingOrigin
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _isLoadingCurrentLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.my_location, size: 20),
                                  onPressed: _loadCurrentLocation,
                                ),
                    ),
                    onSubmitted: (_) => _searchLocation(true),
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey[300]),
          
          // Destino
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      hintText: 'Â¿A dÃ³nde vas?',
                      border: InputBorder.none,
                      suffixIcon: _isSearchingDestination
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.search, size: 20),
                    ),
                    onSubmitted: (_) => _searchLocation(false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona tu vehÃ­culo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _vehicleTypes.length,
          itemBuilder: (context, index) {
            final vehicle = _vehicleTypes[index];
            final isSelected = _selectedVehicleType == vehicle['type'];
            
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedVehicleType = vehicle['type'] as String;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      vehicle['icon'] as IconData,
                      size: 36,
                      color: isSelected ? Colors.blue : Colors.grey[700],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vehicle['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle['description'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      vehicle['capacity'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.verified_user,
          title: 'Viaja seguro',
          description: 'Todos nuestros conductores estÃ¡n verificados',
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.schedule,
          title: 'Llegada estimada',
          description: 'Te mostraremos el tiempo exacto de llegada',
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.attach_money,
          title: 'Precio justo',
          description: 'Sin tarifas ocultas, todo transparente',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final canContinue = _originLocation != null && _destinationLocation != null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canContinue ? _continueToPreview : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Ver CotizaciÃ³n',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: canContinue ? Colors.white : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
