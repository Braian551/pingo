import 'package:ping_go/src/core/error/result.dart';
import 'package:ping_go/src/core/error/failures.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

/// Use Case: Crear Nuevo Viaje (Solicitud)
/// 
/// Encapsula la lógica de negocio para solicitar un nuevo viaje.
class CreateTrip {
  final TripRepository repository;

  CreateTrip(this.repository);

  /// Ejecutar el caso de uso
  Future<Result<Trip>> call({
    required int usuarioId,
    required TripType tipoServicio,
    required TripLocation origen,
    required TripLocation destino,
  }) async {
    // Validaciones de negocio
    if (usuarioId <= 0) {
      return Error(ValidationFailure('ID de usuario inválido'));
    }

    // Validar coordenadas de origen
    if (origen.latitud < -90 || origen.latitud > 90) {
      return Error(
        ValidationFailure('Latitud de origen debe estar entre -90 y 90'),
      );
    }
    if (origen.longitud < -180 || origen.longitud > 180) {
      return Error(
        ValidationFailure('Longitud de origen debe estar entre -180 y 180'),
      );
    }

    // Validar coordenadas de destino
    if (destino.latitud < -90 || destino.latitud > 90) {
      return Error(
        ValidationFailure('Latitud de destino debe estar entre -90 y 90'),
      );
    }
    if (destino.longitud < -180 || destino.longitud > 180) {
      return Error(
        ValidationFailure('Longitud de destino debe estar entre -180 y 180'),
      );
    }

    // Validar que origen y destino no sean el mismo
    if (origen == destino) {
      return Error(
        ValidationFailure('El origen y destino no pueden ser iguales'),
      );
    }

    return await repository.createTrip(
      usuarioId: usuarioId,
      tipoServicio: tipoServicio,
      origen: origen,
      destino: destino,
    );
  }
}
