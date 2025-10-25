import 'package:ping_go/src/core/error/result.dart';
import 'package:ping_go/src/core/error/failures.dart';
import '../entities/location.dart';
import '../repositories/map_repository.dart';

/// Use Case: Geocodificar Dirección
class GeocodeAddress {
  final MapRepository repository;

  GeocodeAddress(this.repository);

  Future<Result<Location>> call(String address) async {
    if (address.trim().isEmpty) {
      return Error(ValidationFailure('La dirección no puede estar vacía'));
    }

    return await repository.geocodeAddress(address);
  }
}
