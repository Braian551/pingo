// lib/src/global/services/device_id_service.dart
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const _prefsKey = 'viax_device_uuid';
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final Uuid _uuid = const Uuid();

  /// Returns a stable device installation UUID for this app.
  /// It prefers platform identifiers (Android ID, iOS identifierForVendor) but
  /// stores the resulting value into SharedPreferences to remain stable across runs.
  static Future<String> getOrCreateDeviceUuid() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) return existing;

    String candidate;
    try {
      if (kIsWeb) {
        // Web: generate random once per install
        candidate = _uuid.v4();
      } else {
        // Best-effort per platform
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final info = await _deviceInfo.androidInfo;
            // info.id is non-null in recent SDKs, but keep safe fallback
            final androidId = info.id.isNotEmpty ? info.id : (info.fingerprint.isNotEmpty ? info.fingerprint : _uuid.v4());
            candidate = _namespaceUuid(androidId);
            break;
          case TargetPlatform.iOS:
            final info = await _deviceInfo.iosInfo;
            final idfv = info.identifierForVendor ?? _uuid.v4();
            candidate = _namespaceUuid(idfv);
            break;
          case TargetPlatform.windows:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.fuchsia:
            // Desktop: fall back to random UUID persisted
            candidate = _uuid.v4();
            break;
        }
      }
    } catch (_) {
      // Any failure -> random stable UUID
      candidate = _uuid.v4();
    }

    await prefs.setString(_prefsKey, candidate);
    return candidate;
  }

  /// Resets the stored uuid (for debugging/testing only)
  static Future<void> resetForDebug() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  static String _namespaceUuid(String seed) {
    // Deterministically hash into a UUID v5 (namespace URL here arbitrary)
    // Using Uuid's v5 implementation
    return _uuid.v5(Uuid.NAMESPACE_URL, seed);
  }
}
