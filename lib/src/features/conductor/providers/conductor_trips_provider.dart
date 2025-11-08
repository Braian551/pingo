import 'package:flutter/material.dart';
import '../services/conductor_trips_service.dart';

class ConductorTripsProvider with ChangeNotifier {
  List<TripModel> _trips = [];
  List<TripModel> _filteredTrips = [];
  PaginationModel? _pagination;
  bool _isLoading = false;
  String? _errorMessage;
  String _filterStatus = 'todos'; // todos, completados, cancelados

  List<TripModel> get trips => _filteredTrips;
  PaginationModel? get pagination => _pagination;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterStatus => _filterStatus;

  /// Cargar historial de viajes
  Future<void> loadTrips(int conductorId, {int page = 1}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('ConductorTripsProvider: Loading trips for conductor $conductorId, page $page');

      final response = await ConductorTripsService.getTripsHistory(
        conductorId: conductorId,
        page: page,
      );

      print('ConductorTripsProvider: Response received - success: ${response['success']}');

      if (response['success'] == true) {
        final viajes = response['viajes'];
        print('ConductorTripsProvider: Processing ${viajes?.length ?? 0} trips');
        
        _trips = List<TripModel>.from(viajes ?? []);
        _pagination = response['pagination'];
        _applyFilter();
        _errorMessage = null;
        
        print('ConductorTripsProvider: Trips loaded successfully. Total: ${_trips.length}, Filtered: ${_filteredTrips.length}');
      } else {
        _errorMessage = response['message'] ?? 'Error al cargar viajes';
        _trips = [];
        _filteredTrips = [];
        print('ConductorTripsProvider: Error loading trips - $_errorMessage');
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Error de conexiÃ³n: $e';
      _trips = [];
      _filteredTrips = [];
      print('ConductorTripsProvider: Exception in loadTrips: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      print('ConductorTripsProvider: Loading finished, notifying listeners');
      notifyListeners();
    }
  }

  /// Aplicar filtro de estado
  void _applyFilter() {
    if (_filterStatus == 'todos') {
      _filteredTrips = _trips;
    } else if (_filterStatus == 'completados') {
      _filteredTrips = _trips.where((t) => t.estado == 'completada').toList();
    } else if (_filterStatus == 'cancelados') {
      _filteredTrips = _trips.where((t) => t.estado == 'cancelada').toList();
    }
  }

  /// Cambiar filtro
  void setFilter(String filter) {
    if (_filterStatus != filter) {
      _filterStatus = filter;
      _applyFilter();
      notifyListeners();
    }
  }

  /// Cargar mÃ¡s viajes (paginaciÃ³n)
  Future<void> loadMoreTrips(int conductorId) async {
    if (_pagination != null && _pagination!.page < _pagination!.totalPages) {
      final nextPage = _pagination!.page + 1;
      await loadTrips(conductorId, page: nextPage);
    }
  }

  /// Obtener detalles de un viaje
  Future<TripModel?> getTripDetails({
    required int conductorId,
    required int tripId,
  }) async {
    try {
      final response = await ConductorTripsService.getTripDetails(
        conductorId: conductorId,
        tripId: tripId,
      );

      if (response['success'] == true) {
        return response['viaje'];
      }
      return null;
    } catch (e) {
      print('Error en getTripDetails: $e');
      return null;
    }
  }

  /// Limpiar datos
  void clear() {
    _trips = [];
    _filteredTrips = [];
    _pagination = null;
    _isLoading = false;
    _errorMessage = null;
    _filterStatus = 'todos';
    notifyListeners();
  }
}
