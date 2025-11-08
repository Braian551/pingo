import 'package:viax/src/core/error/result.dart';
import 'package:viax/src/core/error/failures.dart';
import '../entities/location.dart';
import '../repositories/map_repository.dart';

/// Use Case: Geocodificar DirecciÃ³n
class GeocodeAddress {
  final MapRepository repository;

  GeocodeAddress(this.repository);

  Future<Result<Location>> call(String address) async {
    if (address.trim().isEmpty) {
      return Error(ValidationFailure('La direcciÃ³n no puede estar vacÃ­a'));
    }

    return await repository.geocodeAddress(address);
  }
}
