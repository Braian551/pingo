import 'package:flutter_test/flutter_test.dart';
import 'package:viax/src/global/services/device_id_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceIdService', () {
    test('returns stable UUID across calls', () async {
      final first = await DeviceIdService.getOrCreateDeviceUuid();
      final second = await DeviceIdService.getOrCreateDeviceUuid();
      expect(first, isNotEmpty);
      expect(second, equals(first));
    });
  });
}
