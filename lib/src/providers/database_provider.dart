import 'package:flutter/material.dart';
import '../data/database/mysql_connection.dart';

class DatabaseProvider with ChangeNotifier {
  final MySQLConnection _dbConnection = MySQLConnection();
  bool _isConnected = false;
  String _errorMessage = '';
  
  bool get isConnected => _isConnected;
  String get errorMessage => _errorMessage;
  
  Future<void> initializeDatabase() async {
    try {
      await _dbConnection.connect();
      _isConnected = true;
      _errorMessage = '';
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      _errorMessage = 'Error de conexión: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> closeConnection() async {
    try {
      await _dbConnection.close();
      _isConnected = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cerrar conexión: $e';
      notifyListeners();
    }
  }
}