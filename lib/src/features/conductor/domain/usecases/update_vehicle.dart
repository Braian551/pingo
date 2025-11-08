import '../../../../core/error/result.dart';
import '../entities/conductor_profile.dart';
import '../repositories/conductor_repository.dart';

/// Caso de uso: Actualizar vehÃ­culo del conductor
class UpdateVehicle {
  final ConductorRepository repository;

  UpdateVehicle(this.repository);

  Future<Result<Vehicle>> call(
    int conductorId,
    Vehicle vehicle,
  ) async {
    // AquÃ­ podrÃ­as agregar validaciones de negocio
    // Por ejemplo: verificar que la placa sea Ãºnica, validar aÃ±o del vehÃ­culo, etc.
    
    return await repository.updateVehicle(conductorId, vehicle);
  }
}
