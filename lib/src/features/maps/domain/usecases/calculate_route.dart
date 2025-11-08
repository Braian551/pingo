import 'package:viax/src/core/error/result.dart';
import 'package:viax/src/core/error/failures.dart';
import '../entities/location.dart';
import '../repositories/map_repository.dart';

/// Use Case: Calcular Ruta
class CalculateRoute {
  final MapRepository repository;

  CalculateRoute(this.repository);

  Future<Result<Route>> call(Location origin, Location destination) async {
    if (!origin.isValid) {
      return Error(ValidationFailure('Coordenadas de origen invÃ¡lidas'));
    }

    if (!destination.isValid) {
      return Error(ValidationFailure('Coordenadas de destino invÃ¡lidas'));
    }

    return await repository.calculateRoute(origin, destination);
  }
}
