import 'dart:ui';
import 'package:flutter/material.dart';

/// Pantalla de confirmación de viaje
/// Muestra detalles del viaje, precio estimado y opciones de vehículo
class ConfirmTripScreen extends StatefulWidget {
  const ConfirmTripScreen({super.key});

  @override
  State<ConfirmTripScreen> createState() => _ConfirmTripScreenState();
}

class _ConfirmTripScreenState extends State<ConfirmTripScreen> {
  String _selectedVehicleType = 'standard';
  String? _selectedPaymentMethod;
  double _estimatedPrice = 0.0;
  double _estimatedDistance = 0.0;
  int _estimatedTime = 0;

  final Map<String, Map<String, dynamic>> _vehicleTypes = {
    'economy': {
      'name': 'Economy',
      'description': 'Opción económica',
      'icon': Icons.directions_car,
      'multiplier': 1.0,
      'capacity': '4 pasajeros',
    },
    'standard': {
      'name': 'Standard',
      'description': 'Comodidad estándar',
      'icon': Icons.local_taxi,
      'multiplier': 1.3,
      'capacity': '4 pasajeros',
    },
    'premium': {
      'name': 'Premium',
      'description': 'Máximo confort',
      'icon': Icons.airport_shuttle,
      'multiplier': 1.8,
      'capacity': '4 pasajeros',
    },
    'xl': {
      'name': 'XL',
      'description': 'Para grupos grandes',
      'icon': Icons.rv_hookup,
      'multiplier': 2.0,
      'capacity': '6 pasajeros',
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTrip();
    });
  }

  void _calculateTrip() {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args == null) return;

    // Simular cálculo de distancia y tiempo (en producción usar Google Directions API)
    setState(() {
      _estimatedDistance = 5.2; // km
      _estimatedTime = 15; // minutos
      _estimatedPrice = _calculatePrice(_estimatedDistance, _selectedVehicleType);
    });
  }

  double _calculatePrice(double distance, String vehicleType) {
    const basePrice = 5000.0; // COP
    const pricePerKm = 2500.0; // COP
    final multiplier = _vehicleTypes[vehicleType]!['multiplier'] as double;
    
    return (basePrice + (distance * pricePerKm)) * multiplier;
  }

  void _onVehicleTypeChanged(String type) {
    setState(() {
      _selectedVehicleType = type;
      _estimatedPrice = _calculatePrice(_estimatedDistance, type);
    });
  }

  void _confirmTrip() {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un método de pago'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navegar a pantalla de seguimiento del viaje
    Navigator.pushNamed(
      context,
      '/tracking_trip',
      arguments: {
        'vehicleType': _selectedVehicleType,
        'paymentMethod': _selectedPaymentMethod,
        'estimatedPrice': _estimatedPrice,
        'estimatedTime': _estimatedTime,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final pickupAddress = args?['pickupAddress'] as String? ?? 'Origen';
    final destinationAddress = args?['destinationAddress'] as String? ?? 'Destino';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTripDetails(pickupAddress, destinationAddress),
                    const SizedBox(height: 24),
                    _buildVehicleSelection(),
                    const SizedBox(height: 24),
                    _buildPaymentMethods(),
                    const SizedBox(height: 24),
                    _buildPriceBreakdown(),
                  ],
                ),
              ),
            ),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Confirmar viaje',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetails(String pickup, String destination) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 30,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Origen',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          pickup,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Destino',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          destination,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTripStat(Icons.straighten, '${_estimatedDistance.toStringAsFixed(1)} km'),
                  _buildTripStat(Icons.access_time, '$_estimatedTime min'),
                  _buildTripStat(Icons.attach_money, '\$${_estimatedPrice.toStringAsFixed(0)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripStat(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFFF00), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona tu vehículo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...(_vehicleTypes.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildVehicleOption(entry.key, entry.value),
          );
        })),
      ],
    );
  }

  Widget _buildVehicleOption(String type, Map<String, dynamic> data) {
    final isSelected = _selectedVehicleType == type;
    final price = _calculatePrice(_estimatedDistance, type);

    return GestureDetector(
      onTap: () => _onVehicleTypeChanged(type),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFFF00).withOpacity(0.2)
                  : const Color(0xFF1A1A1A).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFFF00)
                    : Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFFF00)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    data['icon'] as IconData,
                    color: isSelected ? Colors.black : Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] as String,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFFFFF00) : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['description'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        data['capacity'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFFFF00) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de pago',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentOption('cash', 'Efectivo', Icons.money),
        const SizedBox(height: 12),
        _buildPaymentOption('card', 'Tarjeta de crédito/débito', Icons.credit_card),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/payment_methods');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFF00).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFFFFFF00), size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Agregar método de pago',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String id, String name, IconData icon) {
    final isSelected = _selectedPaymentMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFFF00).withOpacity(0.2)
              : const Color(0xFF1A1A1A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFFF00)
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFFF00)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFFFFF00) : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFFFFF00), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Desglose del precio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPriceRow('Tarifa base', '\$5,000'),
              const SizedBox(height: 8),
              _buildPriceRow('Distancia (${_estimatedDistance.toStringAsFixed(1)} km)', 
                  '\$${(_estimatedDistance * 2500).toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              _buildPriceRow('Categoría ${_vehicleTypes[_selectedVehicleType]!['name']}', 
                  'x${_vehicleTypes[_selectedVehicleType]!['multiplier']}'),
              const Divider(color: Colors.white12, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: Color(0xFFFFFF00),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${_estimatedPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFFFFFF00),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: _confirmTrip,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFF00),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFFF00).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Solicitar viaje',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
