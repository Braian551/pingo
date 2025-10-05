import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../global/services/nominatim_service.dart';

class MapProvider with ChangeNotifier {
  LatLng? _selectedLocation;
  String? _selectedAddress;
  String? _searchQuery;
  bool _isLoading = false;
  List<NominatimResult> _searchResults = [];
  LatLng? _currentLocation;
  String? _selectedCity;
  String? _selectedState;

  // Getters
  LatLng? get selectedLocation => _selectedLocation;
  String? get selectedAddress => _selectedAddress;
  String? get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  List<NominatimResult> get searchResults => _searchResults;
  LatLng? get currentLocation => _currentLocation;
  String? get selectedCity => _selectedCity;
  String? get selectedState => _selectedState;

  /// Seleccionar ubicacin desde el mapa
  Future<void> selectLocation(LatLng location) async {
    _selectedLocation = location;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await NominatimService.reverseGeocode(
        location.latitude, 
        location.longitude
      );
      
      if (result != null) {
        _selectedAddress = result.getFormattedAddress();
        _selectedCity = result.getCity();
        _selectedState = result.getState();
      } else {
        _selectedAddress = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        _selectedCity = null;
        _selectedState = null;
      }
    } catch (e) {
      _selectedAddress = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      _selectedCity = null;
      _selectedState = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Buscar dirección por texto
  void searchAddress(String query) async {
    _searchQuery = query;

    // Si la consulta está vacía, limpiar resultados y regresar inmediatamente
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await NominatimService.searchAddress(query);
    } catch (e) {
      _searchResults = [];
      // Puedes propagar o mostrar un mensaje si lo deseas
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Seleccionar resultado de búsqueda
  void selectSearchResult(NominatimResult result) {
    _selectedLocation = LatLng(result.lat, result.lon);
    _selectedAddress = result.getFormattedAddress();
    _selectedCity = result.getCity();
    _selectedState = result.getState();
    _searchResults = [];
    _searchQuery = null;
    notifyListeners();
  }

  /// Establecer ubicación actual
  void setCurrentLocation(LatLng? location) {
    _currentLocation = location;
    notifyListeners();
  }

  /// Limpiar búsqueda
  void clearSearch() {
    _searchResults = [];
    _searchQuery = null;
    notifyListeners();
  }

  /// Limpiar selección
  void clearSelection() {
    _selectedLocation = null;
    _selectedAddress = null;
    _searchResults = [];
    _searchQuery = null;
    _selectedCity = null;
    _selectedState = null;
    notifyListeners();
  }

  /// Permite establecer la dirección seleccionada manualmente (por ejemplo, edición)
  void setSelectedAddress(String address) {
    _selectedAddress = address;
    notifyListeners();
  }

  /// Geocodificar una dirección de texto y centrar el mapa en el primer resultado.
  /// Geocode an address and select the first result. Returns true if a result
  /// was found and selected, false otherwise.
  Future<bool> geocodeAndSelect(String address) async {
    final query = address.trim();
    if (query.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final results = await NominatimService.searchAddress(query);
      if (results.isNotEmpty) {
        // Seleccionar el primer resultado
        selectSearchResult(results.first);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // No se encontraron resultados
        _searchResults = [];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _searchResults = [];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}