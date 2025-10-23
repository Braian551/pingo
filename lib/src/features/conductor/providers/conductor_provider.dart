import 'package:flutter/material.dart';
import '../models/conductor_model.dart';
import '../services/conductor_service.dart';

class ConductorProvider with ChangeNotifier {
  ConductorModel? _conductor;
  bool _disponible = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _estadisticas = {};
  List<Map<String, dynamic>> _viajesActivos = [];

  ConductorModel? get conductor => _conductor;
  bool get disponible => _disponible;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get estadisticas => _estadisticas;
  List<Map<String, dynamic>> get viajesActivos => _viajesActivos;

  /// Cargar información del conductor
  Future<void> loadConductorInfo(int conductorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ConductorService.getConductorInfo(conductorId);
      if (response != null && response['success'] == true) {
        final conductorData = response['conductor'];
        if (conductorData != null) {
          _conductor = ConductorModel.fromJson(conductorData);
          _disponible = _conductor?.disponible ?? false;
          _errorMessage = null;
        }
      } else {
        _errorMessage = 'No se pudo cargar la información del conductor';
      }
    } catch (e) {
      _errorMessage = 'Error al cargar información: $e';
      print('Error en loadConductorInfo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar estadísticas del conductor
  Future<void> loadEstadisticas(int conductorId) async {
    try {
      final stats = await ConductorService.getEstadisticas(conductorId);
      _estadisticas = stats;
      notifyListeners();
    } catch (e) {
      print('Error cargando estadísticas: $e');
    }
  }

  /// Cargar viajes activos
  Future<void> loadViajesActivos(int conductorId) async {
    try {
      final viajes = await ConductorService.getViajesActivos(conductorId);
      _viajesActivos = viajes;
      notifyListeners();
    } catch (e) {
      print('Error cargando viajes activos: $e');
    }
  }

  /// Cambiar disponibilidad del conductor
  Future<bool> toggleDisponibilidad({
    required int conductorId,
    double? latitud,
    double? longitud,
  }) async {
    final nuevaDisponibilidad = !_disponible;

    try {
      final success = await ConductorService.actualizarDisponibilidad(
        conductorId: conductorId,
        disponible: nuevaDisponibilidad,
        latitud: latitud,
        longitud: longitud,
      );

      if (success) {
        _disponible = nuevaDisponibilidad;
        if (_conductor != null) {
          // Actualizar el modelo también
          _conductor = ConductorModel(
            id: _conductor!.id,
            nombre: _conductor!.nombre,
            apellido: _conductor!.apellido,
            email: _conductor!.email,
            telefono: _conductor!.telefono,
            fotoPerfil: _conductor!.fotoPerfil,
            calificacionPromedio: _conductor!.calificacionPromedio,
            totalViajes: _conductor!.totalViajes,
            disponible: nuevaDisponibilidad,
            vehiculoModelo: _conductor!.vehiculoModelo,
            vehiculoPlaca: _conductor!.vehiculoPlaca,
            vehiculoColor: _conductor!.vehiculoColor,
            licenciaNumero: _conductor!.licenciaNumero,
            licenciaVencimiento: _conductor!.licenciaVencimiento,
            latitud: latitud ?? _conductor!.latitud,
            longitud: longitud ?? _conductor!.longitud,
          );
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error cambiando disponibilidad: $e');
      return false;
    }
  }

  /// Actualizar ubicación del conductor
  Future<bool> updateUbicacion({
    required int conductorId,
    required double latitud,
    required double longitud,
  }) async {
    try {
      final success = await ConductorService.actualizarUbicacion(
        conductorId: conductorId,
        latitud: latitud,
        longitud: longitud,
      );

      if (success && _conductor != null) {
        _conductor = ConductorModel(
          id: _conductor!.id,
          nombre: _conductor!.nombre,
          apellido: _conductor!.apellido,
          email: _conductor!.email,
          telefono: _conductor!.telefono,
          fotoPerfil: _conductor!.fotoPerfil,
          calificacionPromedio: _conductor!.calificacionPromedio,
          totalViajes: _conductor!.totalViajes,
          disponible: _conductor!.disponible,
          vehiculoModelo: _conductor!.vehiculoModelo,
          vehiculoPlaca: _conductor!.vehiculoPlaca,
          vehiculoColor: _conductor!.vehiculoColor,
          licenciaNumero: _conductor!.licenciaNumero,
          licenciaVencimiento: _conductor!.licenciaVencimiento,
          latitud: latitud,
          longitud: longitud,
        );
        notifyListeners();
      }

      return success;
    } catch (e) {
      print('Error actualizando ubicación: $e');
      return false;
    }
  }

  /// Limpiar datos del provider
  void clear() {
    _conductor = null;
    _disponible = false;
    _isLoading = false;
    _errorMessage = null;
    _estadisticas = {};
    _viajesActivos = [];
    notifyListeners();
  }
}
