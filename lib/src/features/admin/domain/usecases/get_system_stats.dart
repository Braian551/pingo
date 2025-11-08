import 'package:viax/src/core/error/result.dart';
import '../entities/admin.dart';
import '../repositories/admin_repository.dart';

/// Use Case: Obtener EstadÃ­sticas del Sistema
class GetSystemStats {
  final AdminRepository repository;

  GetSystemStats(this.repository);

  Future<Result<SystemStats>> call() async {
    return await repository.getSystemStats();
  }
}
