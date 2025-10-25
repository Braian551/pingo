import 'package:flutter/foundation.dart';
import '../../domain/entities/location.dart';
import '../../domain/usecases/geocode_address.dart';
import '../../domain/usecases/calculate_route.dart';

/// Provider para gestionar el estado de mapas
class MapProvider with ChangeNotifier {
  final GeocodeAddress geocodeAddressUseCase;
  final CalculateRoute calculateRouteUseCase;

  MapProvider({
    required this.geocodeAddressUseCase,
    required this.calculateRouteUseCase,
  });

  Location? _currentLocation;
  Route? _currentRoute;
  bool _isLoading = false;
  String? _errorMessage;

  Location? get currentLocation => _currentLocation;
  Route? get currentRoute => _currentRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Geocodificar dirección
  Future<Location?> geocodeAddress(String address) async {
    _setLoading(true);

    final result = await geocodeAddressUseCase(address);

    return result.when(
      success: (location) {
        _currentLocation = location;
        _setLoading(false);
        return location;
      },
      error: (failure) {
        _setError(failure.message);
        return null;
      },
    );
  }

  /// Calcular ruta
  Future<Route?> calculateRoute(Location origin, Location destination) async {
    _setLoading(true);

    final result = await calculateRouteUseCase(origin, destination);

    return result.when(
      success: (route) {
        _currentRoute = route;
        _setLoading(false);
        return route;
      },
      error: (failure) {
        _setError(failure.message);
        return null;
      },
    );
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _isLoading = false;
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
