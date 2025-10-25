import 'package:flutter/foundation.dart';
import '../../domain/entities/trip.dart';
import '../../domain/usecases/create_trip.dart';
import '../../domain/usecases/accept_trip.dart';
import '../../domain/usecases/start_trip.dart';
import '../../domain/usecases/complete_trip.dart';
import '../../domain/usecases/cancel_trip.dart';
import '../../domain/usecases/get_active_trips.dart';
import '../../domain/usecases/get_trip_history.dart';
import '../../domain/usecases/rate_conductor.dart';

/// Provider para gestionar el estado de los viajes
/// 
/// Conecta la UI con los casos de uso del dominio.
class TripProvider with ChangeNotifier {
  final CreateTrip createTripUseCase;
  final AcceptTrip acceptTripUseCase;
  final StartTrip startTripUseCase;
  final CompleteTrip completeTripUseCase;
  final CancelTrip cancelTripUseCase;
  final GetActiveTrips getActiveTripsUseCase;
  final GetTripHistory getTripHistoryUseCase;
  final RateConductor rateConductorUseCase;

  TripProvider({
    required this.createTripUseCase,
    required this.acceptTripUseCase,
    required this.startTripUseCase,
    required this.completeTripUseCase,
    required this.cancelTripUseCase,
    required this.getActiveTripsUseCase,
    required this.getTripHistoryUseCase,
    required this.rateConductorUseCase,
  });

  // Estado
  List<Trip> _activeTrips = [];
  List<Trip> _tripHistory = [];
  Trip? _currentTrip;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Trip> get activeTrips => _activeTrips;
  List<Trip> get tripHistory => _tripHistory;
  Trip? get currentTrip => _currentTrip;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Crear nuevo viaje
  Future<Trip?> createTrip({
    required int usuarioId,
    required TripType tipoServicio,
    required TripLocation origen,
    required TripLocation destino,
  }) async {
    _setLoading(true);

    final result = await createTripUseCase(
      usuarioId: usuarioId,
      tipoServicio: tipoServicio,
      origen: origen,
      destino: destino,
    );

    return result.when(
      success: (trip) {
        _currentTrip = trip;
        _activeTrips.insert(0, trip);
        _setLoading(false);
        return trip;
      },
      error: (failure) {
        _setError(failure.message);
        return null;
      },
    );
  }

  /// Aceptar viaje (conductor)
  Future<Trip?> acceptTrip(int tripId, int conductorId) async {
    _setLoading(true);

    final result = await acceptTripUseCase(
      tripId: tripId,
      conductorId: conductorId,
    );

    return result.when(
      success: (trip) {
        _currentTrip = trip;
        _updateTripInList(trip);
        _setLoading(false);
        return trip;
      },
      error: (failure) {
        _setError(failure.message);
        return null;
      },
    );
  }

  /// Iniciar viaje
  Future<Trip?> startTrip(int tripId) async {
    _setLoading(true);

    final result = await startTripUseCase(tripId);

    return result.when(
      success: (trip) {
        _currentTrip = trip;
        _updateTripInList(trip);
        _setLoading(false);
        return trip;
      },
      error: (failure) {
        _setError(failure.message);
        return null;
      },
    );
  }

  /// Completar viaje
  Future<Trip?> completeTrip({
    required int tripId,
    required double precioFinal,
    double? distanciaReal,
  }) async {
    _setLoading(true);

    final result = await completeTripUseCase(
      tripId: tripId,
      precioFinal: precioFinal,
      distanciaReal: distanciaReal,
    );

    return result.when(
      success: (trip) {
        _currentTrip = null;
        _activeTrips.removeWhere((t) => t.id == tripId);
        _tripHistory.insert(0, trip);
        _setLoading(false);
        return trip;
      },
      error: (failure) {
        _setError(failure.message);
        return null;
      },
    );
  }

  /// Cancelar viaje
  Future<Trip?> cancelTrip(int tripId, String motivo) async {
    _setLoading(true);

    final result = await cancelTripUseCase(
      tripId: tripId,
      motivo: motivo,
    );

    return result.when(
      success: (trip) {
        if (_currentTrip?.id == tripId) {
          _currentTrip = null;
        }
        _activeTrips.removeWhere((t) => t.id == tripId);
        _tripHistory.insert(0, trip);
        _setLoading(false);
        return trip;
      },
      error: (failure) {
        _setError(failure.message);
        return null;
      },
    );
  }

  /// Cargar viajes activos
  Future<void> loadActiveTrips(int usuarioId) async {
    _setLoading(true);

    final result = await getActiveTripsUseCase(usuarioId);

    result.when(
      success: (trips) {
        _activeTrips = trips;
        if (trips.isNotEmpty) {
          _currentTrip = trips.first;
        }
        _setLoading(false);
      },
      error: (failure) {
        _setError(failure.message);
      },
    );
  }

  /// Cargar historial de viajes
  Future<void> loadTripHistory(int usuarioId) async {
    _setLoading(true);

    final result = await getTripHistoryUseCase(usuarioId);

    result.when(
      success: (trips) {
        _tripHistory = trips;
        _setLoading(false);
      },
      error: (failure) {
        _setError(failure.message);
      },
    );
  }

  /// Calificar conductor
  Future<bool> rateConductor({
    required int tripId,
    required int calificacion,
    String? comentario,
  }) async {
    _setLoading(true);

    final result = await rateConductorUseCase(
      tripId: tripId,
      calificacion: calificacion,
      comentario: comentario,
    );

    return result.when(
      success: (_) {
        _setLoading(false);
        return true;
      },
      error: (failure) {
        _setError(failure.message);
        return false;
      },
    );
  }

  /// Helpers privados
  void _updateTripInList(Trip trip) {
    final index = _activeTrips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _activeTrips[index] = trip;
    }
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

  /// Limpiar estado
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearCurrentTrip() {
    _currentTrip = null;
    notifyListeners();
  }
}
